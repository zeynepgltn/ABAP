*&---------------------------------------------------------------------*
*& Include          ZGZ_I_TEKLIF_SIPARIS_CLS
*&---------------------------------------------------------------------*
CLASS cl_main IMPLEMENTATION.
  METHOD create_instance.
    IF mo_instance IS INITIAL.
      mo_instance = NEW cl_main( ).
    ENDIF.
    r_obj = mo_instance.
  ENDMETHOD.

  METHOD run.
    me->check_selection( ).
    CHECK sy-subrc EQ 0.

    me->read_data( EXCEPTIONS no_data_found = 1 ).
    CHECK sy-subrc EQ 0.

    CALL SCREEN 100.
  ENDMETHOD.  "run

  METHOD check_selection.
    DATA: lv_low  TYPE dats,
          lv_high TYPE dats.

    lv_low  = s_tarih-low.
    lv_high = s_tarih-high.

    CLEAR s_tarih[].

    IF lv_high IS INITIAL OR lv_high = '00000000'.
      lv_high = '99991231'.
    ENDIF.

    APPEND VALUE #( sign   = 'I'
                    option = 'BT'
                    low    = lv_low
                    high   = lv_high ) TO s_tarih[].
  ENDMETHOD.

  METHOD read_data.
    CLEAR me->mt_alv.

    "koşullara göre ana alv verilerini çek
    SELECT teklif~vbeln,
           teklif~kunnr,
           teklif~vkorg,
           teklif~vtweg,
           teklif~spart,
           teklif~netwr,
           teklif~waerk,
           teklif~angdt,
           teklif~bnddt,
           teklif~gbstk,
           siparis~vbeln AS siparis_no
      FROM vbak AS teklif
      LEFT OUTER JOIN vbak AS siparis ON siparis~vgbel = teklif~vbeln
      WHERE teklif~kunnr = @p_kunnr
        AND teklif~angdt IN @s_tarih
        AND teklif~vbtyp = 'B'
        AND teklif~abstk = 'A'
      INTO CORRESPONDING FIELDS OF TABLE @me->mt_alv.

    IF sy-subrc <> 0.
      MESSAGE 'Kriterlere uygun açık teklif bulunamadı!' TYPE 'S' DISPLAY LIKE 'E'.
      RAISE no_data_found.
    ENDIF.

    " her teklif için sipariş_nosu boş satır
    DATA lt_yeni LIKE me->mt_alv.
    DATA lt_teklif_listesi TYPE TABLE OF vbeln.

    LOOP AT me->mt_alv INTO DATA(ls_chk).
      APPEND ls_chk-vbeln TO lt_teklif_listesi.
    ENDLOOP.
    SORT lt_teklif_listesi.
    DELETE ADJACENT DUPLICATES FROM lt_teklif_listesi. "vbelnleri topla sırala

    "sipariş no boş satırlar
    LOOP AT lt_teklif_listesi INTO DATA(lv_teklif).
      READ TABLE me->mt_alv INTO DATA(ls_ref) WITH KEY vbeln = lv_teklif.
      IF sy-subrc = 0.
        CLEAR ls_ref-siparis_no.
        APPEND ls_ref TO lt_yeni.
      ENDIF.
    ENDLOOP.

    "sipariş nosu olanlar
    LOOP AT me->mt_alv INTO ls_chk WHERE siparis_no IS NOT INITIAL.
      APPEND ls_chk TO lt_yeni.
    ENDLOOP.

    me->mt_alv = lt_yeni.

    "STXH'den notu olan belgeleri bul,
    "İki farklı görev için iki ayrı tipte tablo
    DATA lt_not_listesi   TYPE TABLE OF tdobname. " STXH için char70 (TDOBNAME)
    DATA lt_belge_listesi TYPE TABLE OF vbeln.    " VBAP için char10 (VBELN)

    " Tek bir döngüde iki tabloyu da
    LOOP AT me->mt_alv INTO ls_chk.
      APPEND CONV tdobname( ls_chk-vbeln ) TO lt_not_listesi.
      APPEND ls_chk-vbeln                  TO lt_belge_listesi.

      IF ls_chk-siparis_no IS NOT INITIAL.
        APPEND CONV tdobname( ls_chk-siparis_no ) TO lt_not_listesi.
        APPEND ls_chk-siparis_no                  TO lt_belge_listesi.
      ENDIF.
    ENDLOOP.

    "Tekilleştirme işlemleri
    IF lt_not_listesi IS NOT INITIAL.
      SORT lt_not_listesi.
      DELETE ADJACENT DUPLICATES FROM lt_not_listesi.

      SORT lt_belge_listesi.
      DELETE ADJACENT DUPLICATES FROM lt_belge_listesi.

      " STXH Sorgusu
      SELECT tdname
        FROM stxh
        INTO TABLE @DATA(lt_stxh)
*        BYPASSING BUFFER
        FOR ALL ENTRIES IN @lt_not_listesi
        WHERE tdobject = 'VBBK'
          AND tdname   = @lt_not_listesi-table_line
          AND tdspras  = @sy-langu
          AND tdid     = '0001'.

      SORT lt_stxh BY tdname.
    ENDIF.

    "sum
    TYPES: BEGIN OF ty_netwr_sum,
             vbeln TYPE vbeln_va,
             netwr TYPE netwr_ap,
           END OF ty_netwr_sum.

    DATA: lt_netwr_sum TYPE TABLE OF ty_netwr_sum,
          ls_netwr_sum TYPE ty_netwr_sum.

    " VBAP sorgusu
    IF lt_belge_listesi IS NOT INITIAL.
      " VBAP Sorgusu - lt_belge_listesi
      SELECT vbeln, netwr
        FROM vbap
        INTO TABLE @DATA(lt_vbap_netwr)
        FOR ALL ENTRIES IN @lt_belge_listesi
        WHERE vbeln = @lt_belge_listesi-table_line.

      " VBELN bazında topla
      LOOP AT lt_vbap_netwr INTO DATA(ls_vbap).
        ls_netwr_sum-vbeln = ls_vbap-vbeln.
        ls_netwr_sum-netwr = ls_vbap-netwr.
        COLLECT ls_netwr_sum INTO lt_netwr_sum.
      ENDLOOP.

      SORT lt_netwr_sum BY vbeln.
    ENDIF.

    " Renk  NETWR  Style  Notlar
    LOOP AT me->mt_alv ASSIGNING FIELD-SYMBOL(<fs_alv>).
      CLEAR: <fs_alv>-line_color, <fs_alv>-style.

      " Renk + SELKZ disabled
      IF ( sy-datum > <fs_alv>-bnddt ) OR ( <fs_alv>-gbstk = 'C' ).
        <fs_alv>-line_color = 'C500'.
        INSERT VALUE #( fieldname = 'SELKZ'
                        style     = cl_gui_alv_grid=>mc_style_disabled )
              INTO TABLE <fs_alv>-style.
      ELSE.
        <fs_alv>-line_color = 'C000'.
      ENDIF.

      " NETWRi kalem toplamından al sipariş varsa siparişten, yoksa teklifin
      DATA(lv_lookup_vbeln) = COND vbeln(
        WHEN <fs_alv>-siparis_no IS NOT INITIAL
        THEN <fs_alv>-siparis_no
        ELSE <fs_alv>-vbeln ).

      READ TABLE lt_netwr_sum INTO DATA(ls_sum)
        WITH KEY vbeln = lv_lookup_vbeln BINARY SEARCH.
      IF sy-subrc = 0.
        <fs_alv>-netwr = ls_sum-netwr.
      ENDIF.

      " Sipariş no doluysa SIPARIS_NOTU disabled
      IF <fs_alv>-siparis_no IS NOT INITIAL.
        INSERT VALUE #( fieldname = 'SIPARIS_NOTU'
                       style     = cl_gui_alv_grid=>mc_style_disabled )
              INTO TABLE <fs_alv>-style.
      ENDIF.

      " Teklif notu STXHde varsa READ_TEXT
      DATA(lv_name_chk) = CONV tdobname( <fs_alv>-vbeln ).
      READ TABLE lt_stxh TRANSPORTING NO FIELDS
        WITH KEY tdname = lv_name_chk BINARY SEARCH.
      IF sy-subrc = 0.
        <fs_alv>-teklif_notu = me->read_text_short(
                                iv_vbeln = <fs_alv>-vbeln ).
      ENDIF.

      " Sipariş notu
      IF <fs_alv>-siparis_no IS NOT INITIAL.
        lv_name_chk = <fs_alv>-siparis_no.
        READ TABLE lt_stxh TRANSPORTING NO FIELDS
          WITH KEY tdname = lv_name_chk BINARY SEARCH.
        IF sy-subrc = 0.
          <fs_alv>-siparis_notu = me->read_text_short(
                                    iv_vbeln = <fs_alv>-siparis_no ).
        ENDIF.
      ENDIF.
    ENDLOOP.

    SORT me->mt_alv BY vbeln ASCENDING siparis_no ASCENDING.
  ENDMETHOD.

  METHOD pbo.
    CASE iv_dynnr.
      WHEN '100' OR '0100'.
        " Mevcut ana ekran
        SET PF-STATUS 'PF100'.
        SET TITLEBAR  'T100'.

        IF me->mo_alv IS INITIAL.
          "contanier
          CREATE OBJECT me->mo_container
            EXPORTING
              repid     = sy-repid          " Report to Which This Docking Control is Linked
              dynnr     = iv_dynnr
              side      = cl_gui_docking_container=>dock_at_bottom
              extension = cl_gui_docking_container=>ws_maximizebox.
         " ratio                       = 95

          IF sy-subrc <> 0.
            MESSAGE 'Hata.' TYPE 'S' DISPLAY LIKE 'E'.
            RETURN.
          ENDIF.

          "splitter
          CREATE OBJECT me->mo_splitter
            EXPORTING
              parent  = me->mo_container                  " Parent Container
              rows    = 2                   " Number of Rows to be displayed
              columns = 1.            " Number of Columns to be Displayed

          IF sy-subrc <> 0.
            MESSAGE 'Hata.' TYPE 'S' DISPLAY LIKE 'E'.
*            MESSAGE text-e01 TYPE 'S' DISPLAY LIKE 'E'.
          ENDIF.

          "yükseklik
          me->mo_splitter->set_row_height( id = 1 height = 75 ).   " %75
          me->mo_splitter->set_row_height( id = 2 height = 0 ).   " %25

          "birinci cont
          CALL METHOD me->mo_splitter->get_container
            EXPORTING
              row       = 1               " Row
              column    = 1               " Column
            RECEIVING
              container = me->mo_sub_top.

          "ikinci
          CALL METHOD me->mo_splitter->get_container
            EXPORTING
              row       = 2               " Row
              column    = 1              " Column
            RECEIVING
              container = me->mo_sub_bottom.

          "alv grid
          CREATE OBJECT me->mo_alv
            EXPORTING
              i_parent = me->mo_sub_top.

          "handler
          SET HANDLER: me->handle_toolbar       FOR me->mo_alv,
                       me->handle_user_command  FOR me->mo_alv,
                       me->handle_data_changed_main  FOR me->mo_alv,
                       me->handle_hotspot_click    FOR me->mo_alv.

          "layout
          CLEAR me->ms_layout.
          me->ms_layout-info_fname = 'LINE_COLOR'.
          me->ms_layout-sel_mode   = 'B'. "tek satır
          me->ms_layout-stylefname = 'STYLE'.
          me->ms_layout-no_rowmark = 'X'.   " sol kenardaki işaret sütunu kaldırır

          "fcat
          me->fcat( iv_struct = 'ZGZ_S_TEKLIF_SIPARIS' ).

          " Edit eventleri aktif et
          me->mo_alv->register_edit_event(
            i_event_id = cl_gui_alv_grid=>mc_evt_modified ).

          me->mo_alv->set_table_for_first_display(
            EXPORTING i_bypassing_buffer   = 'X'
                      is_layout            = me->ms_layout
            CHANGING  it_fieldcatalog      = me->mt_fcat
                      it_outtab            = me->mt_alv ).

        ELSE.
          me->mo_alv->refresh_table_display( ).
        ENDIF.

      WHEN '200' OR '0200'.
        "nesneleri freele
        IF me->mo_alv_popup IS BOUND.
          me->mo_alv_popup->free( ).      " ALV Nesnesini serbest bırak
          FREE me->mo_alv_popup.          " Referansı temizle
        ENDIF.

        IF me->mo_popup_container IS BOUND.
          me->mo_popup_container->free( ). " Container'ı serbest bırak
          FREE me->mo_popup_container.     " Referansı temizle
        ENDIF.

        IF me->mv_popup_mode = 'C'.
          SET TITLEBAR  'T200'.
        ELSEIF me->mv_popup_mode = 'U'.
          SET TITLEBAR  'T300'.
        ENDIF.
        SET PF-STATUS 'PF200'.

        IF me->mo_alv_popup IS INITIAL.
          CREATE OBJECT me->mo_popup_container
            EXPORTING
              container_name = 'CCONTAINER_POPUP'.

          CREATE OBJECT me->mo_alv_popup
            EXPORTING
              i_parent = me->mo_popup_container.

          SET HANDLER me->handle_data_changed_popup FOR me->mo_alv_popup.

          me->mo_alv_popup->register_edit_event(
            i_event_id = cl_gui_alv_grid=>mc_evt_modified ).

          CLEAR ms_layout .
          me->ms_layout-zebra      = 'X'.
          me->ms_layout-cwidth_opt = 'X'.   " sütun genişliklerini optimize et

          CLEAR me->mt_fcat_popup.
          me->fcat( iv_struct = 'ZGZ_S_POPUP' ).

          me->mo_alv_popup->set_table_for_first_display(
            EXPORTING is_layout       = me->ms_layout
            CHANGING  it_outtab       = me->mt_popup
                      it_fieldcatalog = me->mt_fcat_popup ).
        ELSE.
          me->mo_alv_popup->refresh_table_display( ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD pai.
    DATA(lv_ucomm) = sy-ucomm.
    CLEAR sy-ucomm.

    CASE sy-dynnr.
      WHEN '100' OR '0100'.
        CASE lv_ucomm.
          WHEN '&BACK'.
            SET SCREEN 0.
            LEAVE SCREEN.
        ENDCASE.

      WHEN '200' OR '0200'.
        CASE lv_ucomm.
          WHEN '&OK'.
            me->mo_alv_popup->check_changed_data( ).

            IF me->mv_popup_mode = 'C'.
              me->create_orders( ).
            ELSEIF me->mv_popup_mode = 'U'.
              me->update_orders( ).
            ENDIF.

            LEAVE TO SCREEN 0.
          WHEN '&CANCEL'.
            LEAVE TO SCREEN 0.
        ENDCASE.
    ENDCASE.
  ENDMETHOD.

  METHOD fcat.
    CASE iv_struct.   " parametre
      WHEN 'ZGZ_S_TEKLIF_SIPARIS'.
        CLEAR me->mt_fcat.
        CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
          EXPORTING
            i_structure_name       = 'ZGZ_S_TEKLIF_SIPARIS'
            i_bypassing_buffer     = 'X'
          CHANGING
            ct_fieldcat            = me->mt_fcat
          EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
        IF sy-subrc <> 0.
          MESSAGE 'HATA!' TYPE 'S' DISPLAY LIKE 'E'.
        ENDIF.

        LOOP AT me->mt_fcat ASSIGNING FIELD-SYMBOL(<f>).
          <f>-just = 'C'.

          CASE <f>-fieldname.
            WHEN 'SELKZ'.
              <f>-checkbox = <f>-edit = abap_true.  <f>-outputlen = 2.
            WHEN 'VBELN'.
              <f>-hotspot = abap_true.
              <f>-outputlen = 10.
              <f>-scrtext_s =  'Teklif No'.
              <f>-scrtext_m = 'Teklif No'.
              <f>-scrtext_l = 'Teklif No'.
            WHEN 'KUNNR'.
              <f>-outputlen = 10.
              <f>-scrtext_s ='Müşteri No'.
            WHEN 'VKORG'.
              <f>-outputlen = 8.
              <f>-scrtext_l = 'Satış Organizasyonu'.
            WHEN 'VTWEG'.
              <f>-outputlen = 8.
              <f>-scrtext_l = 'Dağıtım Kanalı'.
            WHEN 'SPART'.
              <f>-outputlen = 4.
              <f>-scrtext_l = 'Bölüm'.
            WHEN 'NETWR'.
              <f>-outputlen = 8.
              <f>-scrtext_l = 'Net Değeri'.
            WHEN 'WAERK'.
              <f>-outputlen = 3.
              <f>-scrtext_l = 'Para Birimi'.
            WHEN 'ANGDT'.
              <f>-outputlen = 10.
              <f>-scrtext_m = 'Geç. Başl.'.
            WHEN 'BNDDT'.
              <f>-outputlen = 10.
              <f>-scrtext_m = 'Geç. Sonu'.
            WHEN 'SIPARIS_NO'.
              <f>-hotspot = abap_true.
              <f>-outputlen = 5.
              <f>-scrtext_s = 'No'.
              <f>-scrtext_m = 'Sprş No'.
              <f>-scrtext_l = 'Sipariş No'.
            WHEN 'TEKLIF_NOTU'.
              <f>-outputlen = 20.
              <f>-scrtext_s = 'Tklf'.
              <f>-scrtext_m = 'Tklf Notu'.
              <f>-scrtext_l = 'Teklif Notu'.
            WHEN 'SIPARIS_NOTU'.
              <f>-outputlen = 20.
              <f>-scrtext_s = 'Sprs'.
              <f>-scrtext_m = 'Sipariş Notu'.
              <f>-scrtext_l = 'Sipariş Notu'.
              <f>-edit      = abap_true.
            WHEN 'LINE_COLOR' OR 'GBSTK' OR 'STYLE'.
              <f>-no_out = 'X'.
          ENDCASE.
        ENDLOOP.

      WHEN 'ZGZ_S_KALEM'.
        CLEAR me->mt_fcat2.
        CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
          EXPORTING
            i_structure_name   = 'ZGZ_S_KALEM'
            i_bypassing_buffer = 'X'
          CHANGING
            ct_fieldcat        = me->mt_fcat2.

        LOOP AT me->mt_fcat2 ASSIGNING <f>.
          <f>-just = 'C'.
          CASE <f>-fieldname.
            WHEN 'POSNR'.
              <f>-coltext = 'Kalem'.              <f>-outputlen = 12.
            WHEN 'MATNR'.
              <f>-coltext = 'Malzeme'.            <f>-outputlen = 12.
            WHEN 'MAKTX'.
              <f>-coltext = 'Tanım'.              <f>-outputlen = 8.
            WHEN 'KWMENG'.
              <f>-coltext = 'Teklif Miktarı'.     <f>-outputlen = 8.
            WHEN 'ACIK_MIKTAR'.
              <f>-coltext = 'Açık Miktar'.        <f>-outputlen = 8.
            WHEN 'SIPARIS_MIKTAR'.
              <f>-coltext = 'Sipariş Miktarı'.    <f>-outputlen = 8.
            WHEN 'NETWR'.
              <f>-coltext = 'Net Değer'.          <f>-outputlen = 8.
            WHEN 'BIRIM_FIYAT'.
              <f>-coltext = 'Birim Fiyat'.        <f>-outputlen = 8.
            WHEN 'WAERK'.
              <f>-coltext = 'PB'.
            WHEN 'BRGEW'.
              <f>-coltext = 'Brüt'.       <f>-outputlen = 4.
            WHEN 'NTGEW'.
              <f>-coltext = 'Net'.        <f>-outputlen = 4.
            WHEN 'GEWEI'.
              <f>-coltext = 'AB'.
          ENDCASE.
        ENDLOOP.

      WHEN 'ZGZ_S_POPUP'.
        CLEAR me->mt_fcat_popup.

        CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
          EXPORTING
            i_structure_name   = 'ZGZ_S_POPUP'
            i_bypassing_buffer = 'X'
          CHANGING
            ct_fieldcat        = me->mt_fcat_popup.

        LOOP AT me->mt_fcat_popup ASSIGNING <f>.
          <f>-just = 'C'.

          " Ortak gizlenecek teknik alanlar
          CASE <f>-fieldname.
            WHEN 'VBELN' OR 'KWMENG' OR 'NETWR' OR 'BIRIM_FIYAT' OR 'SIPARIS_VBELN'.
              <f>-no_out = abap_true.
            WHEN 'POSNR'.
              <f>-coltext = 'Kalem No'.     <f>-outputlen = 6.
            WHEN 'MATNR'.
              <f>-coltext = 'Malzeme No'.   <f>-outputlen = 12.
            WHEN 'MAKTX'.
              <f>-coltext = 'Tanım'.        <f>-outputlen = 25.
            WHEN 'ACIK_MIKTAR'.
              <f>-coltext = 'Açık Miktar'.  <f>-outputlen = 10.
            WHEN 'HEDEF_MIKTAR'.
              <f>-coltext = 'Hedef Miktar'.
              <f>-outputlen = 10.
              <f>-edit    = abap_true.
          ENDCASE.

          " Moda göre kolon yönetimi
          IF me->mv_popup_mode = 'C'.
            CASE <f>-fieldname.
              WHEN 'KULLANILAN_MIKTAR'.
                <f>-no_out  = abap_false.
                <f>-coltext = 'Kullanılan'.
              WHEN 'SIPARIS_MIKTAR'.
                <f>-no_out  = abap_true.
            ENDCASE.

          ELSEIF me->mv_popup_mode = 'U'.
            CASE <f>-fieldname.
              WHEN 'KULLANILAN_MIKTAR'.
                <f>-no_out  = abap_true.
              WHEN 'SIPARIS_MIKTAR'.
                <f>-no_out  = abap_false.
                <f>-coltext = 'Sipariş Miktarı'.
                <f>-outputlen = 15.
            ENDCASE.
          ENDIF.
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.

  METHOD calc_acik_miktar.
    " İŞLEM 1, Açık miktar = KWMENG - sipariş miktarı
    rv_miktar = iv_kwmeng - iv_siparis_miktar.

    IF rv_miktar < 0.
      rv_miktar = 0.
    ENDIF.
  ENDMETHOD.

  METHOD load_kalem_data.
    CLEAR me->mt_kalem.

    " Bu vbeln teklif mi sipariş mi
    SELECT SINGLE vbtyp
      FROM vbak
      INTO @DATA(lv_vbtyp)
      WHERE vbeln = @me->mv_current_vbeln. "eklif mi (B) yoksa Sipariş mi (C)

    IF lv_vbtyp = 'B'.
      " VBAPtan teklif kalemleri,teklif satırı
      SELECT vbap~posnr,
             vbap~matnr,
             makt~maktx,
             vbap~kwmeng,        " Teklif KWMENG
             vbap~netwr,
             vbap~waerk,
             vbap~brgew,
             vbap~ntgew,
             vbap~gewei
        FROM vbap
        LEFT OUTER JOIN makt ON makt~matnr = vbap~matnr
                            AND makt~spras = @sy-langu
        INTO CORRESPONDING FIELDS OF TABLE @me->mt_kalem
        WHERE vbap~vbeln = @me->mv_current_vbeln.

      IF me->mt_kalem IS INITIAL. RETURN. ENDIF.

      " VBFA , siparişe giden miktar VBELV, POSNV
      SELECT posnv AS posnr,
        rfmng
        FROM vbfa
        INTO TABLE @DATA(lt_flow_teklif)
        WHERE vbelv   = @me->mv_current_vbeln
          AND vbtyp_n = 'C'.

      LOOP AT me->mt_kalem ASSIGNING FIELD-SYMBOL(<fs_kalem>).
        <fs_kalem>-siparis_miktar = REDUCE kwmeng(
          INIT s = 0
          FOR ls IN lt_flow_teklif
          WHERE ( posnr = <fs_kalem>-posnr )
          NEXT s = s + ls-rfmng ).

        <fs_kalem>-acik_miktar = me->calc_acik_miktar(
                                  iv_kwmeng         = <fs_kalem>-kwmeng
                                  iv_siparis_miktar = <fs_kalem>-siparis_miktar ).

        IF <fs_kalem>-kwmeng <> 0.
          <fs_kalem>-birim_fiyat = <fs_kalem>-netwr / <fs_kalem>-kwmeng.
        ENDIF.
      ENDLOOP.

    ELSEIF lv_vbtyp = 'C'.
      " VBAPtan sipariş kalemleri
      SELECT vbap~posnr,
             vbap~matnr,
             makt~maktx,
             vbap~kwmeng,
             vbap~netwr,
             vbap~waerk,
             vbap~brgew,
             vbap~ntgew,
             vbap~gewei,
             vbap~vgbel,
             vbap~vgpos
        FROM vbap
        LEFT OUTER JOIN makt ON makt~matnr = vbap~matnr
                            AND makt~spras = @sy-langu
        INTO TABLE @DATA(lt_siparis_kalem)
        WHERE vbap~vbeln = @me->mv_current_vbeln.

      IF lt_siparis_kalem IS INITIAL. RETURN. ENDIF.

      " 1. Kaynak teklif listesini topla
      DATA lt_teklif_listesi TYPE TABLE OF vbeln.
      LOOP AT lt_siparis_kalem INTO DATA(ls_sk).
        IF ls_sk-vgbel IS NOT INITIAL.
          APPEND ls_sk-vgbel TO lt_teklif_listesi.
        ENDIF.
      ENDLOOP.
      SORT lt_teklif_listesi.
      DELETE ADJACENT DUPLICATES FROM lt_teklif_listesi.

      " 2. Kaynak teklif KWMENGleri
      DATA lt_teklif_kwmeng TYPE TABLE OF vbap.
      IF lt_teklif_listesi IS NOT INITIAL.
        SELECT vbeln, posnr, kwmeng
          FROM vbap
          INTO CORRESPONDING FIELDS OF TABLE @lt_teklif_kwmeng
          FOR ALL ENTRIES IN @lt_teklif_listesi
          WHERE vbeln = @lt_teklif_listesi-table_line.
        SORT lt_teklif_kwmeng BY vbeln posnr.
      ENDIF.

      " 3. VBFAdan kaynak tekliflerin TÜM siparişlere giden RFMNG
      DATA lt_vbfa_teklif TYPE TABLE OF vbfa.
      IF lt_teklif_listesi IS NOT INITIAL.
        SELECT vbelv, posnv, vbeln, posnn, rfmng
          FROM vbfa
          INTO CORRESPONDING FIELDS OF TABLE @lt_vbfa_teklif
          FOR ALL ENTRIES IN @lt_teklif_listesi
          WHERE vbelv   = @lt_teklif_listesi-table_line
            AND vbtyp_n = 'C'.
        SORT lt_vbfa_teklif BY vbelv posnv vbeln.
      ENDIF.

      " 4. mt_kalemi doldur
      LOOP AT lt_siparis_kalem INTO ls_sk.
        DATA lv_teklif_kwmeng TYPE kwmeng.
        DATA lv_vbfa_toplam   TYPE kwmeng.
        CLEAR: lv_teklif_kwmeng, lv_vbfa_toplam.

        IF ls_sk-vgbel IS NOT INITIAL.
          " Tekliften gelen kalem
          READ TABLE lt_teklif_kwmeng INTO DATA(ls_tk)
            WITH KEY vbeln = ls_sk-vgbel
                     posnr = ls_sk-vgpos BINARY SEARCH.
          IF sy-subrc = 0.
            lv_teklif_kwmeng = ls_tk-kwmeng.
          ENDIF.

          lv_vbfa_toplam = REDUCE kwmeng(
            INIT s = 0
            FOR ls_vbfa IN lt_vbfa_teklif
            WHERE ( vbelv = ls_sk-vgbel AND posnv = ls_sk-vgpos )
            NEXT s = s + ls_vbfa-rfmng ).
        ELSE.
          " Doğrudan siparişe girilen kalem, teklif referansı yok
          lv_teklif_kwmeng = 0.
          lv_vbfa_toplam   = 0.
        ENDIF.

        DATA(lv_bf) = COND netwr_ap(
              WHEN lv_teklif_kwmeng <> 0
              THEN ls_sk-netwr / lv_teklif_kwmeng
              WHEN ls_sk-kwmeng <> 0              "  teklif yoksa sipariş miktarından hesapla
              THEN ls_sk-netwr / ls_sk-kwmeng
              ELSE 0 ).

        APPEND VALUE #(
          posnr          = ls_sk-posnr
          matnr          = ls_sk-matnr
          maktx          = ls_sk-maktx
          kwmeng         = lv_teklif_kwmeng
          siparis_miktar = ls_sk-kwmeng
          acik_miktar    = me->calc_acik_miktar(
                             iv_kwmeng         = lv_teklif_kwmeng
                             iv_siparis_miktar = lv_vbfa_toplam )
          netwr          = ls_sk-netwr
          birim_fiyat    = lv_bf
          waerk          = ls_sk-waerk
          brgew          = ls_sk-brgew
          ntgew          = ls_sk-ntgew
          gewei          = ls_sk-gewei
        ) TO me->mt_kalem.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  "olustura veya güncelleye basıldı,pop up gelcek
  METHOD open_popup.
    CLEAR me->mt_popup.

    " Seçilen teklif , sipariş çiftlerini topla
    DATA: BEGIN OF ls_secim,
            vbeln         TYPE vbeln,  " Teklif
            siparis_vbeln TYPE vbeln,  " Sipariş
          END OF ls_secim,
          lt_secim   LIKE TABLE OF ls_secim,
          lt_secilen TYPE TABLE OF vbeln.

    LOOP AT me->mt_alv INTO DATA(ls_alv) WHERE selkz = abap_true.
      " Create modunda,sadece sipariş_no boş olanlar
      IF me->mv_popup_mode = 'C' AND ls_alv-siparis_no IS NOT INITIAL.
        MESSAGE 'CREATE için sadece sipariş numarası olmayan satırları seçin!' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      " Update modunda,sadece sipariş_no dolu olanlar
      IF me->mv_popup_mode = 'U' AND ls_alv-siparis_no IS INITIAL.
        MESSAGE 'UPDATE için sipariş numarası olan satırları seçin!' TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      ls_secim-vbeln         = ls_alv-vbeln.
      ls_secim-siparis_vbeln = ls_alv-siparis_no.     " ALV'deki sipariş
      APPEND ls_secim TO lt_secim.

      APPEND ls_alv-vbeln TO lt_secilen.   " teklif listes,duplicate olabilir
    ENDLOOP.

    " tek satır kontrolü
    IF lines( lt_secim ) > 1.
      MESSAGE 'Sadece bir teklif seçebilirsiniz!'
              TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ELSEIF lt_secim IS INITIAL.
      MESSAGE 'Lütfen en az bir teklif seçin!' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    " UPDATE modunda sipariş zorunlu
    IF me->mv_popup_mode = 'U'.
      LOOP AT lt_secim INTO ls_secim WHERE siparis_vbeln IS INITIAL.
        MESSAGE 'Siparişi olmayan teklif seçildi! Önce sipariş oluşturun.'
                TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
      ENDLOOP.
    ENDIF.

    " Duplicate teklifleri temizle,SELECT için
    SORT lt_secilen.
    DELETE ADJACENT DUPLICATES FROM lt_secilen.

    " Seçilen tekliflerin kalemleri
    SELECT vbap~vbeln,
           vbap~posnr,
           vbap~matnr,
           makt~maktx,
           vbap~kwmeng,
           vbap~netwr
      FROM vbap
      LEFT OUTER JOIN makt ON makt~matnr = vbap~matnr
                          AND makt~spras = @sy-langu
      INTO CORRESPONDING FIELDS OF TABLE @me->mt_popup
      FOR ALL ENTRIES IN @lt_secilen
      WHERE vbap~vbeln = @lt_secilen-table_line. "her satırı al

    IF me->mt_popup IS INITIAL.
      MESSAGE 'Kalem bulunamadı!' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    "  Eski IF me->mv_popup_mode = 'C' ve ELSEIF bloklarını silip

    " Tekliflerin TÜM sipariş akışlarını VBFA tek seferde
    SELECT vbelv,
      vbeln,
      posnv,
      rfmng
      FROM vbfa
      INTO TABLE @DATA(lt_vbfa_all)
      FOR ALL ENTRIES IN @lt_secilen
      WHERE vbelv   = @lt_secilen-table_line
        AND vbtyp_n = 'C'.

    SORT lt_vbfa_all BY vbelv posnv vbeln.

    DATA lt_popup_yeni LIKE me->mt_popup.

    LOOP AT lt_secim INTO ls_secim.
      LOOP AT me->mt_popup INTO DATA(ls_p) WHERE vbeln = ls_secim-vbeln.
        ls_p-siparis_vbeln = ls_secim-siparis_vbeln.

        " Orijinal Teklif Miktarını koruyoruz KWMENG her zaman
        " Teklif kaleminin TÜM siparişlere giden TOPLAM miktarı
        DATA(lv_toplam_giden) = REDUCE kwmeng(
          INIT s = 0
          FOR ls_vb IN lt_vbfa_all
          WHERE ( vbelv = ls_p-vbeln AND posnv = ls_p-posnr )
          NEXT s = s + ls_vb-rfmng ).

        " Doğru Açık Miktar Hesabı Teklif Miktarı - Toplam Giden
        ls_p-acik_miktar = me->calc_acik_miktar(
                             iv_kwmeng         = ls_p-kwmeng
                             iv_siparis_miktar = lv_toplam_giden ).

        " Moda göre pop-up kolon değerlerini eşliyoruz
        IF me->mv_popup_mode = 'C'.
          ls_p-kullanilan_miktar = lv_toplam_giden.
        ELSEIF me->mv_popup_mode = 'U'.
          " Bu spesifik siparişe gitmiş miktarı buluyoruz
          ls_p-siparis_miktar = REDUCE kwmeng(
            INIT s = 0
            FOR ls_v IN lt_vbfa_all
            WHERE ( vbelv = ls_p-vbeln
                AND vbeln = ls_secim-siparis_vbeln
                AND posnv = ls_p-posnr )
            NEXT s = s + ls_v-rfmng ).
        ENDIF.

        APPEND ls_p TO lt_popup_yeni.
      ENDLOOP.
    ENDLOOP.

    me->mt_popup = lt_popup_yeni.

    CALL SCREEN 200 STARTING AT 5 5
                    ENDING   AT 100 18.
  ENDMETHOD.

  "sipariş oluşturma
  METHOD create_orders.
    " BAPI tabloları
    DATA: ls_header       TYPE bapisdhd1,
          ls_header_x     TYPE bapisdhd1x,
          lt_items        TYPE TABLE OF bapisditm,
          lt_items_x      TYPE TABLE OF bapisditmx,
          lt_partners     TYPE TABLE OF bapiparnr,
          lt_schedules    TYPE TABLE OF bapischdl,
          lt_schedules_x  TYPE TABLE OF bapischdlx,
          lt_conditions   TYPE TABLE OF bapicond,
          lt_conditions_x TYPE TABLE OF bapicondx,
          lt_return       TYPE TABLE OF bapiret2,
          lv_salesdoc     TYPE bapivbeln-vbeln.

    DATA lt_islenecek LIKE me->mt_popup.
    "Hhedf miktar > 0 olan satırları topla
    LOOP AT me->mt_popup INTO DATA(ls_popup) WHERE hedef_miktar > 0.
      APPEND ls_popup TO lt_islenecek.
    ENDLOOP.

    IF lt_islenecek IS INITIAL.
      MESSAGE 'Hedef miktar girilmedi!' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    " toplu selectler,loop öncesi
    " tüm vbeln listesi
    DATA lt_vbeln_listesi TYPE TABLE OF vbeln.

    LOOP AT lt_islenecek INTO DATA(ls_islenecek).
      APPEND ls_islenecek-vbeln TO lt_vbeln_listesi.
    ENDLOOP.

    SORT lt_vbeln_listesi.
    DELETE ADJACENT DUPLICATES FROM lt_vbeln_listesi.

    " VBAK,VBKD tüm header bilgileri tek seferde
    SELECT vbak~vbeln,
           vbak~vkorg,
           vbak~vtweg,
           vbak~spart,
           vbak~vbtyp,
           vbak~kunnr,
           vbkd~zterm
      FROM vbak
      LEFT OUTER JOIN vbkd ON vbkd~vbeln = vbak~vbeln
      INTO TABLE @DATA(lt_vbak)
      FOR ALL ENTRIES IN @lt_vbeln_listesi
      WHERE vbak~vbeln = @lt_vbeln_listesi-table_line.

    " VBAP,birim fiyat hesabı için
    SELECT vbeln,
      posnr,
      netwr,
      kwmeng,
      waerk
      FROM vbap
      INTO TABLE @DATA(lt_vbap)
      FOR ALL ENTRIES IN @lt_islenecek
      WHERE vbeln = @lt_islenecek-vbeln
        AND posnr = @lt_islenecek-posnr.

    " VBPA , partners (AG, WE rolleri)
    SELECT vbeln,
      parvw,
      kunnr
      FROM vbpa
      INTO TABLE @DATA(lt_vbpa)
      FOR ALL ENTRIES IN @lt_vbeln_listesi
      WHERE vbpa~vbeln = @lt_vbeln_listesi-table_line
        AND parvw IN ( 'AG', 'WE' ). "sadece bu değerler için


    SORT lt_vbak BY vbeln.
    SORT lt_vbap BY vbeln posnr.
    SORT lt_vbpa BY vbeln.

    " HER TEKLİF İÇİN AYRI SİPARİŞ
    LOOP AT lt_vbeln_listesi INTO DATA(lv_vbeln).

      CLEAR: ls_header, ls_header_x, lt_items,
             lt_partners, lt_schedules,
             lt_conditions, lt_conditions_x, lt_return, lv_salesdoc.

      " HEADER
      READ TABLE lt_vbak INTO DATA(ls_vbak)
  WITH KEY vbeln = lv_vbeln BINARY SEARCH.

      ls_header-doc_type    = 'Z001'.
      ls_header-sales_org   = ls_vbak-vkorg.
      ls_header-distr_chan  = ls_vbak-vtweg.
      ls_header-division    = ls_vbak-spart.
      ls_header-req_date_h  = sy-datum.
      ls_header-pmnttrms    = ls_vbak-zterm.
      ls_header-ref_1 = CONV char12( lv_vbeln ).
      ls_header-purch_no_c  = lv_vbeln.
      ls_header-ref_doc     = lv_vbeln.
      ls_header-refdoc_cat  = ls_vbak-vbtyp.

      " HEADER_X
      ls_header_x-updateflag = 'I'.
      ls_header_x-doc_type   = 'X'.
      ls_header_x-sales_org  = 'X'.
      ls_header_x-distr_chan = 'X'.
      ls_header_x-pmnttrms   = 'X'.
      ls_header_x-division   = 'X'.
      ls_header_x-req_date_h = 'X'.
      ls_header_x-purch_no_c = 'X'.
      ls_header_x-ref_doc    = 'X'.
      ls_header_x-refdoc_cat = 'X'.

      " ITEMS, SCHEDULES, CONDITIONS
      LOOP AT lt_islenecek INTO DATA(ls_kalem) WHERE vbeln = lv_vbeln.

        " ITEMS
        APPEND VALUE #( itm_number = ls_kalem-posnr
                        ref_doc = ls_kalem-vbeln
                        ref_doc_it = ls_kalem-posnr
                        ref_doc_ca = 'B'
                        material   = ls_kalem-matnr
                        target_qty = ls_kalem-hedef_miktar
                        "target_qu   = lt_item-vrkme
                         ) TO lt_items.

        APPEND VALUE #( itm_number = ls_kalem-posnr
                        req_qty    = ls_kalem-hedef_miktar ) TO lt_schedules.

        " CONDITIONS , lt_vbaptan birim fiyat,DB yok
        READ TABLE lt_vbap INTO DATA(ls_vbap)
   WITH KEY vbeln = ls_kalem-vbeln
            posnr = ls_kalem-posnr BINARY SEARCH.

        DATA(lv_birim_fiyat) = COND netwr(  "7.40 sonrası kısaltılmış if else
          WHEN ls_vbap-kwmeng <> 0
          THEN ls_vbap-netwr / ls_vbap-kwmeng
          ELSE 0 ).

        APPEND VALUE #( itm_number = ls_kalem-posnr
                        cond_type  = 'ZLST'
                        cond_value = lv_birim_fiyat
                        currency   = ls_vbap-waerk ) TO lt_conditions.

        APPEND VALUE #( updateflag = 'U' ) TO lt_conditions_x.
      ENDLOOP.

      " PARTNERS,lt_vbpa'dan filtreleme
      LOOP AT lt_vbpa INTO DATA(ls_vbpa) WHERE vbeln = lv_vbeln.
        APPEND VALUE #( partn_role = ls_vbpa-parvw
                        partn_numb = ls_vbak-kunnr
                        itm_number = '000000' ) TO lt_partners.
      ENDLOOP.


      " BAPI Çağrısı
      CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
        EXPORTING
          order_header_in      = ls_header
          order_header_inx     = ls_header_x
        IMPORTING
          salesdocument        = lv_salesdoc
        TABLES
          return               = lt_return
          order_items_in       = lt_items
          order_items_inx      = lt_items_x
          order_partners       = lt_partners
          order_schedules_in   = lt_schedules
          order_schedules_inx  = lt_schedules_x
          order_conditions_in  = lt_conditions
          order_conditions_inx = lt_conditions_x.

      "Hata kontrolü
      READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'. "sadece kontrol bir yere atama
      IF sy-subrc = 0.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

        LOOP AT lt_return INTO DATA(ls_return) WHERE type CA 'EAX'. "mesajı errr abort veya exit olanları seç,type kolon adı
          MESSAGE ls_return-message TYPE 'S' DISPLAY LIKE 'E'.
        ENDLOOP.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'. "işlem bitip kaydedene kadar bekle

        " Kullanıcı ALVde Sipariş Notu yazdı mı
        READ TABLE me->mt_alv INTO DATA(ls_alv_chk)
          WITH KEY vbeln      = lv_vbeln
                   siparis_no = ''.       " Sipariş no boş satır

        IF sy-subrc = 0 AND ls_alv_chk-siparis_notu IS NOT INITIAL.
          " Kullanıcı not yazdı
          me->save_siparis_notu(
            iv_siparis_vbeln = lv_salesdoc
            iv_not           = ls_alv_chk-siparis_notu ).
        ELSE.
          " Kullanıcı yazmadı teklif notunu aktar
          me->transfer_text(
            iv_teklif_vbeln  = lv_vbeln
            iv_siparis_vbeln = lv_salesdoc ).
        ENDIF.

        " Mail gönder
        me->send_mail(
          iv_teklif_vbeln  = lv_vbeln
          iv_siparis_vbeln = lv_salesdoc ).

        MESSAGE |Sipariş { lv_salesdoc } başarıyla oluşturuldu!| TYPE 'S'.
      ENDIF.

    ENDLOOP.

    " Üst ALV'yi yenile
    me->read_data( EXCEPTIONS no_data_found = 1 ).
    me->mo_alv->refresh_table_display( ).

    " Alt ALV açıksa onu da yenile
    IF me->mv_bottom_open = abap_true
       AND me->mv_current_vbeln IS NOT INITIAL
       AND me->mo_alv2 IS BOUND.
      me->load_kalem_data( ).
      me->mo_alv2->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.

  METHOD send_mail.
    DATA: lt_recipients TYPE TABLE OF zgz_t_mail_user,
          lo_send_req   TYPE REF TO cl_bcs,
          lo_document   TYPE REF TO cl_document_bcs,
          lo_recipient  TYPE REF TO if_recipient_bcs,
          lt_body       TYPE bcsy_text,
          ls_body       TYPE soli,
          lv_subject    TYPE so_obj_des,
          lv_body_line  TYPE bcsy_text,
          lv_sent       TYPE os_boolean.

    " Bakım tablosundan mail listesini al
    SELECT * FROM zgz_t_mail_user
      INTO TABLE @lt_recipients.

    " boşsa uyarı
    IF lt_recipients IS INITIAL.
      MESSAGE '! Mail göndericisi belirtilmedi.' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    TRY.
        " mail nesnesi oluştur
        lo_send_req = cl_bcs=>create_persistent( ).

        " mail başlığı
        lv_subject = 'Sipariş oluşturuldu!'.

        " mail içeriği
        " teklif VBELNleading zero yok
        DATA(lv_teklif_disp) = |{ iv_teklif_vbeln ALPHA = OUT }|. "7.40

        ls_body-line = |{ lv_teklif_disp } numaralı teklif siparişe dönüştürülmüştür.|.
        APPEND ls_body TO lt_body.

        " Document oluştur
        lo_document = cl_document_bcs=>create_document(
          i_type    = 'RAW'
          i_text    = lt_body
          i_subject = lv_subject ).

        "document bağla
        lo_send_req->set_document( lo_document ).

        "alıcıları ekle
        LOOP AT lt_recipients INTO DATA(ls_recipient).
          "düz metni> nesne yap
          lo_recipient = cl_cam_address_bcs=>create_internet_address(
            i_address_string = ls_recipient-smtp_addr ).

          "nesneyi zarfa ekle
          lo_send_req->add_recipient(
            i_recipient = lo_recipient
            i_express   = 'X' ).
        ENDLOOP.

        " Mail gönderme sırasına
        lv_sent = lo_send_req->send( i_with_error_screen = 'X' ). "hata varsa hata ekranı göster

        IF lv_sent = abap_true.
          COMMIT WORK.
          MESSAGE 'Mail başarıyla gönderildi.' TYPE 'S'.
        ELSE.
          MESSAGE 'Mail gönderilemedi.' TYPE 'S' DISPLAY LIKE 'W'.
        ENDIF.

      CATCH cx_bcs INTO DATA(lo_ex).
        MESSAGE |Mail hatası: { lo_ex->get_text( ) }| TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  "update belge
  METHOD update_orders.
    DATA: ls_header_x    TYPE bapisdh1x,
          lt_items       TYPE TABLE OF bapisditm,
          lt_items_x     TYPE TABLE OF bapisditmx,
          lt_schedules   TYPE TABLE OF bapischdl,
          lt_schedules_x TYPE TABLE OF bapischdlx,
          lt_conditions  TYPE TABLE OF bapicond,
          lt_return      TYPE TABLE OF bapiret2,
          lv_salesdoc    TYPE bapivbeln-vbeln.

    " Hedef miktar > 0 olanları topla
    DATA lt_islenecek LIKE me->mt_popup.
    LOOP AT me->mt_popup INTO DATA(ls_popup) WHERE hedef_miktar > 0.
      APPEND ls_popup TO lt_islenecek.
    ENDLOOP.

    IF lt_islenecek IS INITIAL.
      MESSAGE 'Hedef miktar girilmedi!' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    " Benzersiz SİPARİŞ no
    " mt_popup'ta siparis_vbeln zaten var,siparis_no
    DATA lt_siparis_listesi TYPE TABLE OF vbeln.
    LOOP AT lt_islenecek INTO DATA(ls_isl).
      IF ls_isl-siparis_vbeln IS NOT INITIAL.
        APPEND ls_isl-siparis_vbeln TO lt_siparis_listesi.
      ENDIF.
    ENDLOOP.
    SORT lt_siparis_listesi.
    DELETE ADJACENT DUPLICATES FROM lt_siparis_listesi.

    IF lt_siparis_listesi IS INITIAL.
      MESSAGE 'Güncellenecek sipariş bulunamadı!' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " Mevcut sipariş kalemleri
    SELECT vbeln, posnr, vgbel, vgpos
      FROM vbap
      INTO TABLE @DATA(lt_siparis_kalem)
      FOR ALL ENTRIES IN @lt_siparis_listesi
      WHERE vbeln = @lt_siparis_listesi-table_line.

    SORT lt_siparis_kalem BY vbeln vgbel vgpos.

    " VBEP  schedule line
    SELECT vbeln, posnr, etenr
      FROM vbep
      INTO TABLE @DATA(lt_vbep)
      FOR ALL ENTRIES IN @lt_siparis_listesi
      WHERE vbeln = @lt_siparis_listesi-table_line.

    SORT lt_vbep BY vbeln posnr.

    "HER SİPARİŞ İÇİN
    LOOP AT lt_siparis_listesi INTO DATA(lv_siparis_vbeln).

      lv_salesdoc = lv_siparis_vbeln.

      CLEAR: ls_header_x, lt_items, lt_items_x,
             lt_schedules, lt_schedules_x,
             lt_conditions, lt_return.

      ls_header_x-updateflag = 'U'.

      LOOP AT lt_islenecek INTO DATA(ls_kalem)
        WHERE siparis_vbeln = lv_siparis_vbeln.

        " Bu kalem siparişte zaten var mı
        READ TABLE lt_siparis_kalem INTO DATA(ls_sip_kalem)
         WITH KEY vbeln = lv_siparis_vbeln
            vgbel = ls_kalem-vbeln
            vgpos = ls_kalem-posnr BINARY SEARCH.

        "YOKSA KALEM EKLENCEK
        DATA(lv_flag)  = COND char1( WHEN sy-subrc = 0 THEN 'U' ELSE 'I' ).
        DATA(lv_posnr) = COND posnr_va( WHEN sy-subrc = 0
                                         THEN ls_sip_kalem-posnr
                                         ELSE ls_kalem-posnr ).

        " Schedule line  mevcut kalem için VBEPten
        DATA lv_sched_line TYPE bapischdl-sched_line.
        IF lv_flag = 'U'.
          READ TABLE lt_vbep INTO DATA(ls_vbep)
            WITH KEY vbeln = lv_siparis_vbeln
                     posnr = lv_posnr BINARY SEARCH.
          lv_sched_line = COND #( WHEN sy-subrc = 0 THEN ls_vbep-etenr ELSE '0001' ).
        ELSE.
          lv_sched_line = '0001'.
        ENDIF.

        " ITEMS
        APPEND VALUE #( itm_number = lv_posnr
                        material   = ls_kalem-matnr
                        target_qty = ls_kalem-hedef_miktar ) TO lt_items.

        APPEND VALUE #( updateflag = lv_flag
                        itm_number = lv_posnr
                        material   = 'X'
                        target_qty = 'X' ) TO lt_items_x.

        " SCHEDULES
        APPEND VALUE #( itm_number = lv_posnr
                        sched_line = lv_sched_line
                        req_qty    = ls_kalem-hedef_miktar ) TO lt_schedules.

        APPEND VALUE #( updateflag = lv_flag
                        itm_number = lv_posnr
                sched_line = lv_sched_line
                        req_qty    = 'X' ) TO lt_schedules_x.

        " CONDITIONS - sadece yeni kalemler için
        IF lv_flag = 'I'.
          DATA(lv_birim_fiyat) = COND netwr_ap(
            WHEN ls_kalem-kwmeng <> 0
            THEN ls_kalem-netwr / ls_kalem-kwmeng
            ELSE 0 ).

          APPEND VALUE #( itm_number = lv_posnr
                          cond_type  = 'ZLST'
                          cond_value = lv_birim_fiyat ) TO lt_conditions.
        ENDIF.

      ENDLOOP.

      " BAPI çağrısı
      CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
        EXPORTING
          salesdocument    = lv_salesdoc
          order_header_inx = ls_header_x
        TABLES
          return           = lt_return
          order_item_in    = lt_items
          order_item_inx   = lt_items_x
          schedule_lines   = lt_schedules
          schedule_linesx  = lt_schedules_x
          conditions_in    = lt_conditions.

      READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
      IF sy-subrc = 0.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        LOOP AT lt_return INTO DATA(ls_return) WHERE type CA 'EAX'.
          MESSAGE ls_return-message TYPE 'S' DISPLAY LIKE 'E'.
        ENDLOOP.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.

        MESSAGE |Sipariş { lv_salesdoc } başarıyla güncellendi!| TYPE 'S'.
      ENDIF.

    ENDLOOP.

    " Üst ALV'yi yenile
    me->read_data( EXCEPTIONS no_data_found = 1 ).
    me->mo_alv->refresh_table_display( ).

    " Alt ALV açıksa onu da yenile
    IF me->mv_bottom_open = abap_true
       AND me->mv_current_vbeln IS NOT INITIAL
       AND me->mo_alv2 IS BOUND.
      me->load_kalem_data( ).
      me->mo_alv2->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_text_short.
    DATA: lt_lines TYPE TABLE OF tline,
          lv_name  TYPE thead-tdname.

    " vbelni,10 karakter formatına çevir,leading zero
    lv_name = iv_vbeln.

    " read text,Excel parametreleri
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        "client                  = sy-mandt         " Client
        id                      = '0001'                " Text ID of text to be read
        language                = sy-langu                 " Language of text to be read
        name                    = lv_name                " Name of text to be read
        object                  = 'VBBK'                  " Object of text to be read
      TABLES
        lines                   = lt_lines                 " Lines of text read
      EXCEPTIONS
        id                      = 1                " Text ID invalid
        language                = 2                " Invalid language
        name                    = 3                " Invalid text name
        not_found               = 4                " Text not found
        object                  = 5                " Invalid text object
        reference_check         = 6                " Reference chain interrupted
        wrong_access_to_archive = 7                " Archive handle invalid for access
        OTHERS                  = 8.

    " İlk satırı al,ALV'de göstermek için
    IF sy-subrc = 0 AND lt_lines IS NOT INITIAL.
      LOOP AT lt_lines INTO DATA(ls_line).
        rv_text = rv_text && ls_line-tdline.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD transfer_text.
    DATA: lt_lines  TYPE TABLE OF tline,
          ls_header TYPE thead,
          lv_name   TYPE thead-tdname.

    "SAVE_TEXT , Siparişe yaz , Sipariş VBELN'i 10 karakter formatına çevir
    lv_name = iv_teklif_vbeln.

    "READ_TEXT - Teklif notunu oku
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        id        = '0001'
        language  = sy-langu
        name      = lv_name
        object    = 'VBBK'
      TABLES
        lines     = lt_lines
      EXCEPTIONS
        not_found = 1
        OTHERS    = 2.

    " Not yoksa çık
    IF sy-subrc <> 0 OR lt_lines IS INITIAL.
      RETURN.
    ENDIF.

    lv_name = iv_siparis_vbeln.
    " HEADER doldur,Excel parametreleri
    ls_header-tdobject = 'VBBK'.
    ls_header-tdname   = lv_name.
    ls_header-tdid     = '0001'.
    ls_header-tdspras  = sy-langu.

    CALL FUNCTION 'SAVE_TEXT'
      EXPORTING
        header = ls_header
      TABLES
        lines  = lt_lines
      EXCEPTIONS
        OTHERS = 1.

    IF sy-subrc <> 0.
      MESSAGE |Not kaydedilemedi: { iv_siparis_vbeln }|
              TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    "COMMIT_TEXT , DB'ye yaz,Excel parametreleri
    CALL FUNCTION 'COMMIT_TEXT'
      EXPORTING
        object          = 'VBBK'
        name            = lv_name
        id              = '0001'
        language        = sy-langu
        savemode_direct = 'X'.
  ENDMETHOD.

  METHOD save_siparis_notu.
    DATA: lt_lines  TYPE TABLE OF tline,
          ls_header TYPE thead,
          ls_line   TYPE tline,
          lv_name   TYPE thead-tdname,
          lv_langu  TYPE sy-langu.

    IF iv_not IS INITIAL.
      RETURN.    " Not yoksa hiçbir şey yapma
    ENDIF.

    lv_langu = 'TR'.

    " Sipariş VBELNi 10 karakter formatına çevir
    lv_name = iv_siparis_vbeln.

    " HEADER
    ls_header-tdobject = 'VBBK'.
    ls_header-tdname   = lv_name.
    ls_header-tdid     = '0001'.
    ls_header-tdspras  = sy-langu.

    " LINES , kullanıcının yazdığı not
    ls_line-tdformat = '*'.
    ls_line-tdline   = iv_not.
    APPEND ls_line TO lt_lines.

    " SAVE_TEXT
    CALL FUNCTION 'SAVE_TEXT'
      EXPORTING
        header = ls_header
      TABLES
        lines  = lt_lines
      EXCEPTIONS
        OTHERS = 1.

    IF sy-subrc <> 0.
      MESSAGE |Sipariş notu kaydedilemedi: { iv_siparis_vbeln }|
              TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    " COMMIT_TEXT
    CALL FUNCTION 'COMMIT_TEXT'
      EXPORTING
        object          = 'VBBK'
        name            = lv_name
        id              = '0001'
        language        = lv_langu
        savemode_direct = 'X'.
  ENDMETHOD.

  METHOD handle_data_changed_popup.
    LOOP AT er_data_changed->mt_mod_cells ASSIGNING FIELD-SYMBOL(<fs_mod>)
      WHERE fieldname = 'HEDEF_MIKTAR'.

      READ TABLE me->mt_popup INDEX <fs_mod>-row_id ASSIGNING FIELD-SYMBOL(<fs_p>).
      IF sy-subrc <> 0. CONTINUE. ENDIF.

      " Türkçe sayı formatından dönüştür
      DATA(lv_value) = <fs_mod>-value.
      REPLACE ALL OCCURRENCES OF ',' IN lv_value WITH '.'.
      DATA(lv_yeni) = CONV kwmeng( lv_value ).

      " Moda göre izin verilen maksimum
      DATA: lv_max TYPE kwmeng,
            lv_msg TYPE string.

      IF me->mv_popup_mode = 'C'.
        " CREATE hedef sadece açık miktar kadar olabilir
        lv_max = <fs_p>-acik_miktar.
        lv_msg = 'Hedef miktar açık miktardan büyük olamaz!'.
      ELSE.
        " UPDATE mevcut sipariş + açık miktar kadar olabilir
        lv_max = <fs_p>-siparis_miktar + <fs_p>-acik_miktar.
        lv_msg = 'Hedef miktar, sipariş ve açık miktar toplamından büyük olamaz!'.
      ENDIF.

      " UPDATE modunda eşitlik de geçersiz
      IF me->mv_popup_mode = 'U'.
        IF lv_yeni = <fs_p>-siparis_miktar.   " ← eşit veya büyükse uyarı
          CALL METHOD er_data_changed->add_protocol_entry
            EXPORTING
              i_msgid     = '00'
              i_msgno     = '001'
              i_msgty     = 'E'
              i_msgv1     = 'Hedef miktar mevcut sipariş miktarına eşit olamaz!'
              i_fieldname = <fs_mod>-fieldname
              i_row_id    = <fs_mod>-row_id.
        ELSEIF lv_yeni > lv_max.
          CALL METHOD er_data_changed->add_protocol_entry
            EXPORTING
              i_msgid     = '00'
              i_msgno     = '001'
              i_msgty     = 'E'
              i_msgv1     = 'Hedef miktar, sipariş ve açık miktar toplamından büyük olamaz!'
              i_fieldname = <fs_mod>-fieldname
              i_row_id    = <fs_mod>-row_id.
        ENDIF.
      ELSEIF lv_yeni > lv_max.
        CALL METHOD er_data_changed->add_protocol_entry
          EXPORTING
            i_msgid     = '00'
            i_msgno     = '001'
            i_msgty     = 'E'
            i_msgv1     = lv_msg
            i_fieldname = <fs_mod>-fieldname
            i_row_id    = <fs_mod>-row_id.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD handle_toolbar.
    "BREAK ZGULTEN.
    " CLEAR e_object->mt_toolbar.
    DELETE e_object->mt_toolbar FROM 3 TO 14.

    APPEND VALUE #( butn_type = 3 ) TO e_object->mt_toolbar.

    APPEND VALUE #( function  = '&RFRSH'
                    icon      = '@5D@'
                    text      = 'Yenile'
                    quickinfo = 'Veritabanından yenile' ) TO e_object->mt_toolbar.

    APPEND VALUE #( function  = '&CREATE'
                    icon      = '@1G@'
                    text      = 'Sipariş Oluştur'
                    quickinfo = 'OLUŞTUR' ) TO e_object->mt_toolbar.

    APPEND VALUE #( function  = '&UPDATE'
                 icon      = '@5G@'
                 text      = 'Sipariş Güncelle'
                 quickinfo = 'Sipariş Güncelle' ) TO e_object->mt_toolbar.

  ENDMETHOD.

  METHOD handle_user_command.
    CASE e_ucomm.
      WHEN '&RFRSH'.
        "me->mo_alv->check_changed_data( ).
        me->read_data( EXCEPTIONS no_data_found = 1 ).
        CHECK sy-subrc EQ 0.
        me->mo_alv->refresh_table_display( ).

        " Alt ALV açıksa onu da yenile
        IF me->mv_bottom_open = abap_true
           AND me->mv_current_vbeln IS NOT INITIAL
           AND me->mo_alv2 IS BOUND.
          me->load_kalem_data( ).
          me->mo_alv2->refresh_table_display( ).
        ENDIF.
      WHEN '&CREATE'.
        me->mo_alv->check_changed_data( ).
        CLEAR me->mv_popup_mode.
        me->mv_popup_mode = 'C'.
        me->open_popup( ).
      WHEN '&UPDATE'.
        me->mo_alv->check_changed_data( ).
        CLEAR me->mv_popup_mode.
        me->mv_popup_mode = 'U'.
        me->open_popup( ).
    ENDCASE.
  ENDMETHOD.

  METHOD handle_hotspot_click.

    DATA lv_tcode   TYPE tcode.
    DATA lv_vbeln   TYPE vbeln_va.
    DATA lt_bdcdata TYPE TABLE OF bdcdata.
    DATA ls_bdcdata TYPE bdcdata.

    READ TABLE me->mt_alv INDEX e_row_id-index
      ASSIGNING FIELD-SYMBOL(<fs_alv>).
    IF sy-subrc <> 0. RETURN. ENDIF.

    CASE e_column_id-fieldname.
      WHEN 'VBELN'.
        lv_tcode = 'VA23'.
        lv_vbeln = <fs_alv>-vbeln.
      WHEN 'SIPARIS_NO'.
        IF <fs_alv>-siparis_no IS INITIAL. RETURN. ENDIF.
        lv_tcode = 'VA03'.
        lv_vbeln = <fs_alv>-siparis_no.
      WHEN OTHERS.
        RETURN.
    ENDCASE.

    " BDC ile ilk ekrana vbeln yaz ve enter bas
    ls_bdcdata-program  = 'SAPMV45A'.
    ls_bdcdata-dynpro   = '0102'.
    ls_bdcdata-dynbegin = 'X'.
    APPEND ls_bdcdata TO lt_bdcdata.
    CLEAR ls_bdcdata.

    ls_bdcdata-fnam = 'VBAK-VBELN'.
    ls_bdcdata-fval = lv_vbeln.
    APPEND ls_bdcdata TO lt_bdcdata.
    CLEAR ls_bdcdata.

    ls_bdcdata-fnam = 'BDC_OKCODE'.
    ls_bdcdata-fval = '/00'.
    APPEND ls_bdcdata TO lt_bdcdata.
    CLEAR ls_bdcdata.

    CALL TRANSACTION lv_tcode USING lt_bdcdata MODE 'E'.
  ENDMETHOD.

  METHOD handle_data_changed_main.
    DATA: lv_yeni_index   TYPE i,
          lv_target_vbeln TYPE vbeln_va.

    " Yeni işaretlenen satırı bul
    LOOP AT er_data_changed->mt_mod_cells ASSIGNING FIELD-SYMBOL(<fs_mod>) WHERE fieldname = 'SELKZ' AND value = 'X'.
      lv_yeni_index = <fs_mod>-row_id.
      EXIT.
    ENDLOOP.

    IF lv_yeni_index > 0.
      " Diğer tüm satırların SELKZ'ini temizle, sadece yeni seçili
      LOOP AT me->mt_alv ASSIGNING FIELD-SYMBOL(<fs_alv>).
        " Disabled satırlara dokunma
        IF ( sy-datum > <fs_alv>-bnddt ) OR ( <fs_alv>-gbstk = 'C' ).
          CONTINUE.
        ENDIF.

        IF sy-tabix = lv_yeni_index.
          <fs_alv>-selkz = abap_true.
        ELSE.
          CLEAR <fs_alv>-selkz.
        ENDIF.
      ENDLOOP.

      " Alt ALV'yi aç
      READ TABLE me->mt_alv INDEX lv_yeni_index ASSIGNING <fs_alv>.
      IF sy-subrc = 0.
        lv_target_vbeln = COND vbeln_va(
          WHEN <fs_alv>-siparis_no IS NOT INITIAL THEN <fs_alv>-siparis_no
          ELSE <fs_alv>-vbeln ).

        me->open_bottom_alv( lv_target_vbeln ).
      ENDIF.

    ELSE.
      " İşaret kaldırıldı alt ALVyi kapat
      LOOP AT er_data_changed->mt_mod_cells ASSIGNING <fs_mod> WHERE fieldname = 'SELKZ'.
        me->close_bottom_alv( ).
        EXIT.
      ENDLOOP.
    ENDIF.

    " Checkbox değişikliklerini ALVye yansıt
    me->mo_alv->refresh_table_display(
      is_stable = VALUE #( row = abap_true col = abap_true ) ).
  ENDMETHOD.

  METHOD open_bottom_alv.
    IF me->mv_current_vbeln = iv_vbeln AND me->mv_bottom_open = abap_true.
      me->close_bottom_alv( ).
      RETURN.
    ENDIF.

    me->mv_current_vbeln = iv_vbeln.
    me->mv_bottom_open   = abap_true.

    me->load_kalem_data( ).
    me->mo_splitter->set_row_height( id = 2 height = 25 ).

    IF me->mo_alv2 IS INITIAL.
      CREATE OBJECT me->mo_alv2
        EXPORTING
          i_parent = me->mo_sub_bottom.

      me->fcat( iv_struct = 'ZGZ_S_KALEM' ).
      CLEAR me->ms_layout.
      me->ms_layout-col_opt = 'X'.

      me->mo_alv2->set_table_for_first_display(
        EXPORTING is_layout       = me->ms_layout
        CHANGING  it_outtab       = me->mt_kalem
                  it_fieldcatalog = me->mt_fcat2 ).
    ELSE.
      me->mo_alv2->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.

  METHOD close_bottom_alv.
    me->mo_splitter->set_row_height( id = 2 height = 0 ).
    me->mv_bottom_open = abap_false.
    CLEAR me->mv_current_vbeln.
  ENDMETHOD.
ENDCLASS.
