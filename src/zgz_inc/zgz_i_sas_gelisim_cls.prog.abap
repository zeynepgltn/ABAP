*&---------------------------------------------------------------------*
*& Include          ZGZ_I_SAS_GELISIM_CLS
*&---------------------------------------------------------------------*
CLASS cl_controller IMPLEMENTATION.
  METHOD create_instance.
    IF mo_instance IS INITIAL.
      mo_instance = NEW cl_controller( ).
    ENDIF.
    r_obj = mo_instance.
  ENDMETHOD.

  METHOD run.
    me->read_data( EXCEPTIONS no_data_found = 1 ).
    CHECK sy-subrc EQ 0.

    CALL SCREEN 100.
  ENDMETHOD.  "run

  METHOD read_data.
    CLEAR me->mt_alv.

    DATA: lt_eban      TYPE TABLE OF eban,
          ls_eban      TYPE eban,
          ls_out       TYPE ty_output,
          ls_ekko_sel  TYPE ekko,
          ls_t16fs     TYPE t16fs,
          ls_t16fs_sas TYPE t16fs,
          lv_changenr1 TYPE cdpos-changenr,
          lv_changenr2 TYPE cdpos-changenr,
          lv_changenr3 TYPE cdpos-changenr,
          lv_changenr4 TYPE cdpos-changenr,
          lv_sas_cn1   TYPE cdpos-changenr,
          lv_sas_cn2   TYPE cdpos-changenr,
          lv_sas_cn3   TYPE cdpos-changenr,
          lt_ekbe_mg   TYPE TABLE OF ekbe,
          lt_ekbe_onay TYPE TABLE OF ekbe,
          lt_ekbe_fat  TYPE TABLE OF ekbe,
            lt_ekbe_all  TYPE TABLE OF ekbe.

    " ----  EBAN filtrele ----
    SELECT * FROM eban
      INTO TABLE lt_eban
      WHERE banfn IN s_banfn
        AND bsart IN s_bsart.

    IF sy-subrc <> 0 OR lt_eban IS INITIAL.
      MESSAGE 'Kriterlere uygun kayıt bulunamadı!' TYPE 'S' DISPLAY LIKE 'E'.
      RAISE no_data_found.
    ENDIF.

    " ---- EKKO filtrele ve EBAN ile kesişim al ----
    DATA: lt_ekko   TYPE TABLE OF ekko,
          lt_ekko_f TYPE TABLE OF ekko.

    " Önce EBAN'daki ebeln'leri topla
    TYPES: ty_ebeln TYPE ekko-ebeln.
    DATA: lt_ebeln TYPE TABLE OF ty_ebeln.
    LOOP AT lt_eban INTO DATA(ls_tmp).
      APPEND ls_tmp-ebeln TO lt_ebeln.
    ENDLOOP.
    SORT lt_ebeln.
    DELETE ADJACENT DUPLICATES FROM lt_ebeln.
    DELETE lt_ebeln WHERE table_line IS INITIAL.

    IF lt_ebeln IS NOT INITIAL.
      SELECT * FROM ekko INTO TABLE lt_ekko
        FOR ALL ENTRIES IN lt_ebeln
        WHERE ebeln    = lt_ebeln-table_line
          AND ekgrp   IN s_ekgrp
          AND bsart   IN s_ebsart
          AND aedat   IN s_aedat
          AND ebeln   IN s_ebeln
          AND ernam   IN s_ernam
          AND procstat IN s_procst.
    ENDIF.

    " EKKO filtresi sonrası EBAN'ı daralt
    IF lt_ekko IS NOT INITIAL.
      DATA: lt_eban_f TYPE TABLE OF eban.
      LOOP AT lt_eban INTO ls_eban.
        READ TABLE lt_ekko INTO ls_ekko_sel WITH KEY ebeln = ls_eban-ebeln.
        IF sy-subrc = 0.
          APPEND ls_eban TO lt_eban_f.
        ENDIF.
      ENDLOOP.
      lt_eban = lt_eban_f.
    ELSE.
      " EKKO filtresi doluysa ve sonuç yoksa dur
      IF s_ekgrp[] IS NOT INITIAL OR s_ebsart[] IS NOT INITIAL OR s_aedat[]  IS NOT INITIAL OR s_ebeln[]  IS NOT INITIAL OR s_ernam[]  IS NOT INITIAL OR s_procst[] IS NOT INITIAL.
        MESSAGE 'Kriterlere uygun kayıt bulunamadı!' TYPE 'S' DISPLAY LIKE 'E'.
        RAISE no_data_found.
      ENDIF.
    ENDIF.

    " ---- EKPO filtrele ve EBAN ile kesişim al ----
    DATA: lt_ekpo TYPE TABLE OF ekpo.
    IF lt_eban IS NOT INITIAL.
      SELECT * FROM ekpo INTO TABLE lt_ekpo
        FOR ALL ENTRIES IN lt_eban
        WHERE banfn  =  lt_eban-banfn
          AND bnfpo  =  lt_eban-bnfpo
          AND knttp  IN s_knttp
          AND matnr  IN s_matnr
          AND lgort  IN s_lgort
          AND matkl  IN s_matkl.

      " EKPO filtresi sonrası EBAN'ı daralt
      IF lt_ekpo IS NOT INITIAL.
        CLEAR lt_eban_f.
        LOOP AT lt_eban INTO ls_eban.
          READ TABLE lt_ekpo INTO DATA(ls_ekpo_tmp) WITH KEY banfn = ls_eban-banfn bnfpo = ls_eban-bnfpo.
          IF sy-subrc = 0.
            APPEND ls_eban TO lt_eban_f.
          ENDIF.
        ENDLOOP.
        lt_eban = lt_eban_f.
      ELSE.
        IF s_knttp[] IS NOT INITIAL OR s_matnr[] IS NOT INITIAL OR s_lifnr[] IS NOT INITIAL OR s_lgort[] IS NOT INITIAL OR s_matkl[] IS NOT INITIAL.
          MESSAGE 'Kriterlere uygun kayıt bulunamadı!' TYPE 'S' DISPLAY LIKE 'E'.
          RAISE no_data_found.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lt_eban IS INITIAL.
      MESSAGE 'Kriterlere uygun kayıt bulunamadı!' TYPE 'S' DISPLAY LIKE 'E'.
      RAISE no_data_found.
    ENDIF.

    " ---- LOOP ----
    LOOP AT lt_eban INTO ls_eban.
      " Silme işareti kontrolü — EBAN'ın kendi alanı
      IF p_loekz = abap_true AND ls_eban-loekz = abap_true.
        CONTINUE.
      ENDIF.

      CLEAR ls_out.
      " EBAN direkt alanlar
      ls_out-banfn = ls_eban-banfn.
      ls_out-bnfpo = ls_eban-bnfpo.
      ls_out-bsart = ls_eban-bsart.
      ls_out-knttp = ls_eban-knttp.
      ls_out-ekgrp = ls_eban-ekgrp.
      ls_out-matnr = ls_eban-matnr.
      ls_out-txz01 = ls_eban-txz01.
      ls_out-menge = ls_eban-menge.
      ls_out-meins = ls_eban-meins.
      ls_out-matkl = ls_eban-matkl.
      ls_out-badat = ls_eban-badat.
      ls_out-afnam = ls_eban-afnam.
      ls_out-frgkz = ls_eban-frgkz.
      ls_out-frgzu = ls_eban-frgzu.
      ls_out-banpr = ls_eban-banpr.
      ls_out-bedat = ls_eban-bedat.
      ls_out-ebeln = ls_eban-ebeln.
      ls_out-ebelp = ls_eban-ebelp.
      ls_out-bsmng = ls_eban-bsmng.
      ls_out-rlwrt = ls_eban-rlwrt.
      ls_out-bpueb = ls_eban-bpueb.

      " T023T - Mal Grubu Tanımı
      SELECT SINGLE wgbez FROM t023t
        INTO ls_out-wgbez
        WHERE matkl = ls_eban-matkl.

      " T161U - SAT Onay Göstergesi Tanımı
      SELECT SINGLE fkztx FROM t161u
        INTO ls_out-fkztx
        WHERE frgkz = ls_eban-frgkz
          AND spras = sy-langu.

      " ---- SAT ONAYCILAR ----
      SELECT SINGLE frgc1, frgc2, frgc3, frgc4
        FROM t16fs INTO @ls_t16fs
        WHERE frggr = @ls_eban-frggr
          AND frgsx = @ls_eban-frgst.

      SELECT SINGLE objid FROM t16fw INTO ls_out-onayci1
        WHERE frgco = ls_t16fs-frgc1 AND frggr = ls_eban-frggr.
      SELECT SINGLE objid FROM t16fw INTO ls_out-onayci2
        WHERE frgco = ls_t16fs-frgc2 AND frggr = ls_eban-frggr.
      SELECT SINGLE objid FROM t16fw INTO ls_out-onayci3
        WHERE frgco = ls_t16fs-frgc3 AND frggr = ls_eban-frggr.
      SELECT SINGLE objid FROM t16fw INTO ls_out-onayci4
        WHERE frgco = ls_t16fs-frgc4 AND frggr = ls_eban-frggr.

      " ---- SAT ONAY TARİHLERİ ----
      SELECT MAX( changenr ) FROM cdpos INTO lv_changenr1
        WHERE objectclas = 'BANF' AND objectid = ls_eban-banfn
          AND tabkey = ls_eban-purchasereqnitemuniqueid
          AND fname = 'FRGZU' AND value_new = 'X'.
      SELECT SINGLE udate FROM cdhdr INTO ls_out-onay_t1
        WHERE objectclas = 'BANF' AND objectid = ls_eban-banfn
          AND changenr = lv_changenr1.

      SELECT MAX( changenr ) FROM cdpos INTO lv_changenr2
        WHERE objectclas = 'BANF' AND objectid = ls_eban-banfn
          AND tabkey = ls_eban-purchasereqnitemuniqueid
          AND fname = 'FRGZU' AND value_new = 'XX'.
      SELECT SINGLE udate FROM cdhdr INTO ls_out-onay_t2
        WHERE objectclas = 'BANF' AND objectid = ls_eban-banfn
          AND changenr = lv_changenr2.

      SELECT MAX( changenr ) FROM cdpos INTO lv_changenr3
        WHERE objectclas = 'BANF' AND objectid = ls_eban-banfn
          AND tabkey = ls_eban-purchasereqnitemuniqueid
          AND fname = 'FRGZU' AND value_new = 'XXX'.
      SELECT SINGLE udate FROM cdhdr INTO ls_out-onay_t3
        WHERE objectclas = 'BANF' AND objectid = ls_eban-banfn
          AND changenr = lv_changenr3.

      SELECT MAX( changenr ) FROM cdpos INTO lv_changenr4
        WHERE objectclas = 'BANF' AND objectid = ls_eban-banfn
          AND tabkey = ls_eban-purchasereqnitemuniqueid
          AND fname = 'FRGZU' AND value_new = 'XXXX'.
      SELECT SINGLE udate FROM cdhdr INTO ls_out-onay_t4
        WHERE objectclas = 'BANF' AND objectid = ls_eban-banfn
          AND changenr = lv_changenr4.

      " ---- EKKO - iç tablodan oku ----
      READ TABLE lt_ekko INTO ls_ekko_sel WITH KEY ebeln = ls_eban-ebeln.
      IF sy-subrc = 0.
        ls_out-sas_bsart = ls_ekko_sel-bsart.
        ls_out-sas_bedat = ls_ekko_sel-bedat.
        ls_out-aedat     = ls_ekko_sel-aedat.
        ls_out-ernam     = ls_ekko_sel-ernam.
        ls_out-lifnr     = ls_ekko_sel-lifnr.
        ls_out-submi     = ls_ekko_sel-submi.
        ls_out-sas_frgke = ls_ekko_sel-frgke.
        ls_out-sas_frgzu = ls_ekko_sel-frgzu.
        ls_out-procstat  = ls_ekko_sel-procstat.
        ls_out-sas_ekgrp = ls_ekko_sel-ekgrp.

        " LFA1-tedarikçi tanımı
        IF ls_ekko_sel-lifnr IS NOT INITIAL.
          SELECT SINGLE name1 FROM lfa1
            INTO ls_out-name1
            WHERE lifnr = ls_ekko_sel-lifnr.
        ENDIF.

        " T161U - SAS Onay Göstergesi Tanımı
        SELECT SINGLE fkztx FROM t161u
          INTO ls_out-sas_fkztx
          WHERE frgkz = ls_ekko_sel-frgke
            AND spras = sy-langu.

        " ---- SAS ONAYCILAR ----
        SELECT SINGLE frgc1, frgc2, frgc3
          FROM t16fs INTO @ls_t16fs_sas
          WHERE frggr = @ls_ekko_sel-frggr
            AND frgsx = @ls_ekko_sel-frgsx.

        SELECT SINGLE objid FROM t16fw INTO ls_out-sas_onayci1
          WHERE frgco = ls_t16fs_sas-frgc1 AND frggr = ls_ekko_sel-frggr.
        SELECT SINGLE objid FROM t16fw INTO ls_out-sas_onayci2
          WHERE frgco = ls_t16fs_sas-frgc2 AND frggr = ls_ekko_sel-frggr.
        SELECT SINGLE objid FROM t16fw INTO ls_out-sas_onayci3
          WHERE frgco = ls_t16fs_sas-frgc3 AND frggr = ls_ekko_sel-frggr.

        " ---- SAS ONAY TARİHLERİ ----
        SELECT MAX( changenr ) FROM cdpos INTO lv_sas_cn1
          WHERE objectclas = 'EINKBELEG' AND objectid = ls_eban-ebeln
            AND tabname = 'EKKO' AND fname = 'FRGZU' AND value_new = 'X'.
        SELECT SINGLE udate FROM cdhdr INTO ls_out-sas_onay_t1
          WHERE objectclas = 'EINKBELEG' AND objectid = ls_eban-ebeln
            AND changenr = lv_sas_cn1.

        SELECT MAX( changenr ) FROM cdpos INTO lv_sas_cn2
          WHERE objectclas = 'EINKBELEG' AND objectid = ls_eban-ebeln
            AND tabname = 'EKKO' AND fname = 'FRGZU' AND value_new = 'XX'.
        SELECT SINGLE udate FROM cdhdr INTO ls_out-sas_onay_t2
          WHERE objectclas = 'EINKBELEG' AND objectid = ls_eban-ebeln
            AND changenr = lv_sas_cn2.

        SELECT MAX( changenr ) FROM cdpos INTO lv_sas_cn3
          WHERE objectclas = 'EINKBELEG' AND objectid = ls_eban-ebeln
            AND tabname = 'EKKO' AND fname = 'FRGZU' AND value_new = 'XXX'.
        SELECT SINGLE udate FROM cdhdr INTO ls_out-sas_onay_t3
          WHERE objectclas = 'EINKBELEG' AND objectid = ls_eban-ebeln
            AND changenr = lv_sas_cn3.

        " Satın Alma Grubu Tanımı
        SELECT SINGLE eknam FROM t024
          INTO ls_out-sas_eknam
          WHERE ekgrp = ls_ekko_sel-ekgrp.
      ENDIF.

      " ---- EKPO - iç tablodan oku ----
      READ TABLE lt_ekpo INTO DATA(ls_ekpo_sel) WITH KEY banfn = ls_eban-banfn bnfpo = ls_eban-bnfpo.
      IF sy-subrc = 0.
        ls_out-netpr = ls_ekpo_sel-netpr.
        ls_out-konnr = ls_ekpo_sel-konnr.
        ls_out-ktpnr = ls_ekpo_sel-ktpnr.
        ls_out-netwr = ls_ekpo_sel-netwr.

        " Depo Yeri
        ls_out-lgort = ls_ekpo_sel-lgort.

        " T001L - Depo Yeri Tanımı
        SELECT SINGLE lgobe FROM t001l INTO ls_out-lgobe
          WHERE lgort = ls_ekpo_sel-lgort.

        " ---- DK Hesabı / Kar Merkezi ----
        IF ls_ekpo_sel-knttp = ''.
          ls_out-dk_hesabi   = ls_ekpo_sel-sakto.
          ls_out-kar_merkezi = ls_ekpo_sel-ko_prctr.
        ELSEIF ls_ekpo_sel-knttp = 'K' OR ls_ekpo_sel-knttp = 'P' OR ls_ekpo_sel-knttp = 'A'.
          SELECT SINGLE sakto, ps_psp_pnr, kostl, prctr FROM ekkn
            INTO @DATA(ls_ekkn)
            WHERE ebeln = @ls_ekpo_sel-ebeln
              AND ebelp = @ls_ekpo_sel-ebelp.
          IF sy-subrc = 0.
            ls_out-ekkn_sakto  = ls_ekkn-sakto.
            ls_out-pyp         = ls_ekkn-ps_psp_pnr.
            ls_out-masraf_yeri = ls_ekkn-kostl.
            ls_out-ekkn_prctr  = ls_ekkn-prctr.
          ENDIF.
        ENDIF.

        " ---- Duran Varlık ----
        SELECT SINGLE anln1 FROM bseg INTO ls_out-duran_varlik
          WHERE ebeln = ls_ekpo_sel-ebeln
            AND ebelp = ls_ekpo_sel-ebelp.

        " ---- EKBE tüm satırları çek ----
        CLEAR: lt_ekbe_mg, lt_ekbe_onay, lt_ekbe_fat, lt_ekbe_all.

        SELECT * FROM ekbe INTO TABLE lt_ekbe_all
          WHERE ebeln = ls_ekpo_sel-ebeln
            AND ebelp = ls_ekpo_sel-ebelp.

        " mal girişi
        lt_ekbe_mg = VALUE #( FOR ls IN lt_ekbe_all
                      WHERE ( vgabe = '1' AND bwart = '103' ) ( ls ) ).

        " VGABE=1, BWART=105 → onaycı
        lt_ekbe_onay = VALUE #( FOR ls IN lt_ekbe_all
                                WHERE ( vgabe = '1' AND bwart = '105' ) ( ls ) ).

        " VGABE=2 → fatura
        lt_ekbe_fat = VALUE #( FOR ls IN lt_ekbe_all
                       WHERE ( vgabe = '2' AND bwart = '' ) ( ls ) ).

        " ---- APPEND mantığı ----
        IF lt_ekbe_mg IS INITIAL AND lt_ekbe_fat IS INITIAL.
          " İkisi de yok - tek satır
          APPEND ls_out TO me->mt_alv.

        ELSEIF lt_ekbe_mg IS INITIAL AND lt_ekbe_fat IS NOT INITIAL.
          " Sadece fatura var
          LOOP AT lt_ekbe_fat INTO DATA(ls_fat_only).
            ls_out-fatura_no  = ls_fat_only-xblnr.
            ls_out-sas_no_fat = ls_fat_only-ebeln.
            ls_out-sap_belge  = ls_fat_only-belnr.
            ls_out-fat_ernam  = ls_fat_only-ernam.
            ls_out-fat_bldat  = ls_fat_only-bldat.
            ls_out-fat_cpudt  = ls_fat_only-cpudt.
            ls_out-fat_wrbtr  = ls_fat_only-wrbtr.
            ls_out-kdv_goster = ls_fat_only-mwskz.
            APPEND ls_out TO me->mt_alv.
          ENDLOOP.

        ELSE.
          " Mal girişi var
          LOOP AT lt_ekbe_mg INTO DATA(ls_mg).
            ls_out-mg_ernam = ls_mg-ernam.
            ls_out-mg_cpudt = ls_mg-cpudt.
            ls_out-mg_belnr = ls_mg-belnr.
            ls_out-irsaliye = ls_mg-xblnr.

            " Onaycı eşleştir
            READ TABLE lt_ekbe_onay INTO DATA(ls_onay) WITH KEY lfbnr = ls_mg-belnr.
            IF sy-subrc = 0.
              ls_out-mgo_ernam = ls_onay-ernam.
              ls_out-mgo_cpudt = ls_onay-cpudt.
            ELSE.
              CLEAR: ls_out-mgo_ernam, ls_out-mgo_cpudt.
            ENDIF.

            IF lt_ekbe_fat IS INITIAL.
              " Fatura yok
              APPEND ls_out TO me->mt_alv.
            ELSE.
              " Her fatura için ayrı satır
              LOOP AT lt_ekbe_fat INTO DATA(ls_fat).
                ls_out-fatura_no  = ls_fat-xblnr.
                ls_out-sas_no_fat = ls_fat-ebeln.
                ls_out-sap_belge  = ls_fat-belnr.
                ls_out-fat_ernam  = ls_fat-ernam.
                ls_out-fat_bldat  = ls_fat-bldat.
                ls_out-fat_cpudt  = ls_fat-cpudt.
                ls_out-fat_wrbtr  = ls_fat-wrbtr.
                ls_out-kdv_goster = ls_fat-mwskz.
                APPEND ls_out TO me->mt_alv.
              ENDLOOP.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD pbo.
    CASE iv_dynnr.
      WHEN  '100' OR '0100'.
        SET PF-STATUS 'STATUS'.
        SET TITLEBAR  '100'.

        IF me->mo_alv IS INITIAL.
          " Ana
          go_cont = NEW cl_gui_docking_container(
            repid = sy-repid
            dynnr = sy-dynnr
            side  = cl_gui_docking_container=>dock_at_bottom
            ratio = 95 ).

          me->mo_alv = NEW cl_gui_alv_grid( i_parent = go_cont ).

          "layout
          CLEAR me->ms_layout.
          me->ms_layout-zebra = 'X'.
          me->ms_layout-no_rowmark = 'X'.   " sol kenardaki işaret sütunu kaldırır

          "fcat
          me->set_fieldcat( ).


          me->mo_alv->set_table_for_first_display(
            EXPORTING i_bypassing_buffer   = 'X'
                      is_layout            = me->ms_layout
            CHANGING  it_fieldcatalog      = me->mt_fcat
                      it_outtab            = me->mt_alv ).
        ELSE.
          me->mo_alv->refresh_table_display( ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD pai.
    CASE sy-ucomm.
      WHEN '&BACK'.
        SET SCREEN 0.
        LEAVE SCREEN.
    ENDCASE.
  ENDMETHOD.

  METHOD set_fieldcat.
  DATA: ls_fc TYPE lvc_s_fcat.

  DEFINE m_fc.
    CLEAR ls_fc.
    ls_fc-fieldname = &1.
    ls_fc-ref_table = &2.
    ls_fc-ref_field = &3.
    ls_fc-coltext   = &4.
    APPEND ls_fc TO me->mt_fcat.
  END-OF-DEFINITION.

  " ref_table + ref_field verince:
  " - outputlen otomatik gelir
  " - data element'ten tip gelir
  " - coltext vermezsek DD'den alır, verirsek override eder

  m_fc 'BANFN'  'EBAN'  'BANFN'  'SAT No'.
  m_fc 'BNFPO'  'EBAN'  'BNFPO'  'Kalem'.
  m_fc 'BSART'  'EBAN'  'BSART'  'Belge Türü'.
  m_fc 'KNTTP'  'EBAN'  'KNTTP'  'Hesap Tayin Tipi'.
  m_fc 'EKGRP'  'EBAN'  'EKGRP'  'Satın Alma Grubu'.
  m_fc 'EKNAM'  'T024'  'EKNAM'  'Satın Alma Grubu Tanımı'.
  m_fc 'MATNR'  'EBAN'  'MATNR'  'Malzeme'.
  m_fc 'TXZ01'  'EBAN'  'TXZ01'  'Malzeme Tanımı'.
  m_fc 'MENGE'  'EBAN'  'MENGE'  'Miktar'.
  m_fc 'MEINS'  'EBAN'  'MEINS'  'Ölçü Birimi'.
  m_fc 'MATKL'  'EBAN'  'MATKL'  'Mal Grubu'.
  m_fc 'WGBEZ'  'T023T' 'WGBEZ'  'Mal Grubu Tanımı'.
  m_fc 'BADAT'  'EBAN'  'BADAT'  'Talep Tarihi'.
  m_fc 'AFNAM'  'EBAN'  'AFNAM'  'Yaratan'.
  m_fc 'FRGKZ'  'EBAN'  'FRGKZ'  'Onay Göstergesi'.
  m_fc 'FKZTX'  'T161U' 'FKZTX'  'Onay Gös. Tanımı'.
  m_fc 'FRGZU'  'EBAN'  'FRGZU'  'Onay Durumu'.
  m_fc 'BANPR'  'EBAN'  'BANPR'  'İşlem Durumu'.

  m_fc 'ONAYCI1'  'T16FW' 'OBJID'  'SAT 1. Onaycı'.
  m_fc 'ONAY_T1'  'CDHDR' 'UDATE'  'SAT 1. Onay Tarihi'.
  m_fc 'ONAYCI2'  'T16FW' 'OBJID'  'SAT 2. Onaycı'.
  m_fc 'ONAY_T2'  'CDHDR' 'UDATE'  'SAT 2. Onay Tarihi'.
  m_fc 'ONAYCI3'  'T16FW' 'OBJID'  'SAT 3. Onaycı'.
  m_fc 'ONAY_T3'  'CDHDR' 'UDATE'  'SAT 3. Onay Tarihi'.
  m_fc 'ONAYCI4'  'T16FW' 'OBJID'  'SAT 4. Onaycı'.
  m_fc 'ONAY_T4'  'CDHDR' 'UDATE'  'SAT 4. Onay Tarihi'.

  m_fc 'BEDAT'     'EBAN'  'BEDAT'    'SAS''a Çevrilme Tarihi'.
  m_fc 'SAS_BSART' 'EKKO'  'BSART'    'SAS Belge Türü'.
  m_fc 'SAS_BEDAT' 'EKKO'  'BEDAT'    'Belge Tarihi'.
  m_fc 'AEDAT'     'EKKO'  'AEDAT'    'Yaratma Tarihi'.
  m_fc 'ERNAM'     'EKKO'  'ERNAM'    'SAS Yaratan'.
  m_fc 'EBELN'     'EBAN'  'EBELN'    'SAS No'.
  m_fc 'EBELP'     'EBAN'  'EBELP'    'SAS Kalem No'.
  m_fc 'LIFNR'     'EKKO'  'LIFNR'    'Tedarikçi'.
  m_fc 'NAME1'     'LFA1'  'NAME1'    'Tedarikçi Tanımı'.
  m_fc 'BSMNG'     'EBAN'  'BSMNG'    'SAS Miktarı'.
  m_fc 'NETPR'     'EKPO'  'NETPR'    'SAS Net Fiyat'.
  m_fc 'RLWRT'     'EBAN'  'RLWRT'    'SAS Net Değer'.
  m_fc 'BPUEB'     'EBAN'  'BPUEB'    'SAS Net Fiyat (EBAN)'.
  m_fc 'SUBMI'     'EKKO'  'SUBMI'    'TT Grup No'.
  m_fc 'KONNR'     'EKPO'  'KONNR'    'Sözleşme No'.
  m_fc 'KTPNR'     'EKPO'  'KTPNR'    'Sözleşme Kalem'.
  m_fc 'SAS_FRGKE' 'EKKO'  'FRGKE'    'SAS Onay Göstergesi'.
  m_fc 'SAS_FKZTX' 'T161U' 'FKZTX'   'SAS Onay Göstergesi Tanım'.
  m_fc 'SAS_FRGZU' 'EKKO'  'FRGZU'    'SAS Onay Durumu'.
  m_fc 'PROCSTAT'  'EKKO'  'PROCSTAT' 'İşleme Durumu'.

  m_fc 'SAS_ONAYCI1' 'T16FW' 'OBJID'  'SAS 1. Onaycı'.
  m_fc 'SAS_ONAY_T1' 'CDHDR' 'UDATE'  'SAS 1. Onay Tarihi'.
  m_fc 'SAS_ONAYCI2' 'T16FW' 'OBJID'  'SAS 2. Onaycı'.
  m_fc 'SAS_ONAY_T2' 'CDHDR' 'UDATE'  'SAS 2. Onay Tarihi'.
  m_fc 'SAS_ONAYCI3' 'T16FW' 'OBJID'  'SAS 3. Onaycı'.
  m_fc 'SAS_ONAY_T3' 'CDHDR' 'UDATE'  'SAS 3. Onay Tarihi'.
  m_fc 'NETWR'       'EKPO'  'NETWR'  'SAS Toplam Tutar'.
  m_fc 'SAS_EKGRP'   'EKKO'  'EKGRP'  'SAS Satın Alma Grubu'.
  m_fc 'SAS_EKNAM'   'T024'  'EKNAM'  'SAS Satın Alma Grubu Tanımı'.

  m_fc 'LGORT'      'EKPO'  'LGORT'   'Depo Yeri'.
  m_fc 'LGOBE'      'T001L' 'LGOBE'   'Depo Yeri Tanım'.
  m_fc 'MG_ERNAM'   'EKBE'  'ERNAM'   'Malzeme Girişi Yapan Kişi'.
  m_fc 'MG_CPUDT'   'EKBE'  'CPUDT'   'Malzeme Girişi Yapılan Tarih'.
  m_fc 'MG_BELNR'   'EKBE'  'BELNR'   'Malzeme Belgesi'.
  m_fc 'IRSALIYE'   'EKBE'  'XBLNR'   'İrsaliye / Fatura No'.
  m_fc 'MGO_ERNAM'  'EKBE'  'ERNAM'   'Malzeme Girişi Onaycısı 1'.
  m_fc 'MGO_CPUDT'  'EKBE'  'CPUDT'   'Malzeme Girişi Onaycısı 1 Tarih'.

  m_fc 'FATURA_NO'    'EKBE'  'XBLNR'  'Fatura No'.
  m_fc 'SAS_NO_FAT'   'EKBE'  'EBELN'  'Fatura Üzerinde Yazan SAS No'.
  m_fc 'SAP_BELGE'    'EKBE'  'BELNR'  'SAP Belge No'.
  m_fc 'FAT_ERNAM'    'EKBE'  'ERNAM'  'Fatura Giren Kişi'.
  m_fc 'FAT_BLDAT'    'EKBE'  'BLDAT'  'Fatura Tarihi'.
  m_fc 'FAT_CPUDT'    'EKBE'  'CPUDT'  'Fatura Giriş Tarihi'.
  m_fc 'FAT_WRBTR'    'EKBE'  'WRBTR'  'Fatura KDV Hariç Toplam'.
  m_fc 'KDV_GOSTER'   'EKBE'  'MWSKZ'  'KDV Göstergesi'.
  m_fc 'DK_HESABI'    'EKPO'  'SAKTO'  'DK Hesabı'.
  m_fc 'EKKN_SAKTO'   'EKKN'  'SAKTO'  'DK Hesabı (EKKN)'.
  m_fc 'PYP'          'EKKN'  'PS_PSP_PNR' 'PYP'.
  m_fc 'MASRAF_YERI'  'EKKN'  'KOSTL'  'Masraf Yeri'.
  m_fc 'KAR_MERKEZI'  'EKPO'  'KO_PRCTR' 'Kar Merkezi'.
  m_fc 'EKKN_PRCTR'   'EKKN'  'PRCTR'  'Kar Merkezi (EKKN)'.
  m_fc 'DURAN_VARLIK' 'BSEG'  'ANLN1'  'Duran Varlık'.

ENDMETHOD.
ENDCLASS.
