*&---------------------------------------------------------------------*
*& Include          ZGZ_I_BOMCOPY_CLS
*&---------------------------------------------------------------------*
CLASS cl_controller IMPLEMENTATION.
  METHOD create_instance.
    IF mo_instance IS INITIAL.
      mo_instance = NEW cl_controller( ).
    ENDIF.
    r_obj = mo_instance.
  ENDMETHOD.

  METHOD pbo.
    SET PF-STATUS '0100'.
    SET TITLEBAR  '0100'.

    IF mo_cont IS INITIAL.
      " Docking Container
      CREATE OBJECT mo_cont
        EXPORTING
          repid     = sy-repid
          dynnr     = sy-dynnr
          side      = cl_gui_docking_container=>dock_at_bottom
          extension = 300.

      " ALV Grid oluştur
      CREATE OBJECT mo_alv
        EXPORTING
          i_parent = mo_cont.

      SET HANDLER me->handler_toolbar FOR mo_alv.
      SET HANDLER me->handler_user_command FOR mo_alv.
      SET HANDLER me->handler_data_changed FOR mo_alv.

      " Layout ayarla
      me->set_layout( ).
      me->set_fcat( ).

      CALL METHOD mo_alv->set_table_for_first_display
        EXPORTING
          is_layout       = ms_layout             " Layout
          "it_toolbar_excluding = lt_exclude
        CHANGING
          it_outtab       = mt_alv                " Output Table
          it_fieldcatalog = mt_fcat.                " Field Catalo
    ENDIF.
  ENDMETHOD.

  METHOD pai.
    CASE ok_code.
      WHEN 'ENTER' OR ' '.
        IF gv_satir_sayisi IS INITIAL OR gv_satir_sayisi <= 0.
          MESSAGE 'Satir sayisi giriniz!' TYPE 'S' DISPLAY LIKE 'W'.
          RETURN.
        ELSE.
          me->add_rows( ).
          CLEAR gv_satir_sayisi.
        ENDIF.

      WHEN '&BACK' OR '&RES'.
        LEAVE TO SCREEN 0.

      WHEN '&EXIT' OR '&CANC'.
        LEAVE PROGRAM.
    ENDCASE.

    CLEAR ok_code.
  ENDMETHOD.

  METHOD set_fcat.
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name   = 'ZGZ_S_URUNA'
        i_bypassing_buffer = 'X'
      CHANGING
        ct_fieldcat        = me->mt_fcat.

    LOOP AT mt_fcat ASSIGNING <gfs_fc>.
      IF <gfs_fc>-fieldname = 'SELKZ'.
        <gfs_fc>-key = <gfs_fc>-checkbox = <gfs_fc>-edit = abap_true.
        <gfs_fc>-scrtext_s = 'Sçm'.
        <gfs_fc>-outputlen = 2.
        <gfs_fc>-scrtext_m = 'Seçim'.
        <gfs_fc>-edit      = abap_true.
      ELSEIF <gfs_fc>-fieldname = 'TABIX'.
        <gfs_fc>-no_out = 'X'.
      ELSEIF <gfs_fc>-fieldname = 'MALZEME'.
        <gfs_fc>-outputlen = 15.
        <gfs_fc>-scrtext_m = 'Malzeme'.
        <gfs_fc>-edit      = abap_true.
      ELSEIF <gfs_fc>-fieldname = 'KURETIMYERI'.
        <gfs_fc>-outputlen = 15.
        <gfs_fc>-scrtext_m = 'Üretim Yeri'.
        <gfs_fc>-edit      = abap_true.
      ELSEIF <gfs_fc>-fieldname = 'AURUNAGACI'.
        <gfs_fc>-outputlen = 15.
        <gfs_fc>-scrtext_m = 'Alt. ÜA'.
        <gfs_fc>-edit      = abap_true.
      ELSEIF <gfs_fc>-fieldname = 'YURETIMYERI'.
        <gfs_fc>-outputlen = 20.
        <gfs_fc>-scrtext_m = 'Yeni Üretim Yeri'.
        <gfs_fc>-edit      = abap_true.
      ELSEIF <gfs_fc>-fieldname =  'MSG'.
        <gfs_fc>-outputlen = 70.
        <gfs_fc>-scrtext_s = 'Msj'.
        <gfs_fc>-scrtext_m = 'Mesaj'.
        <gfs_fc>-scrtext_l = 'Mesaj'.
        <gfs_fc>-edit      = abap_false.
      ELSEIF <gfs_fc>-fieldname = 'ICON'.
        <gfs_fc>-outputlen = 5.
        <gfs_fc>-scrtext_s = 'Ikn'.
        <gfs_fc>-scrtext_m = 'Ikon'.
        <gfs_fc>-icon      = abap_true.
        <gfs_fc>-edit      = abap_false.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_layout.
    ms_layout-zebra = abap_true.
    ms_layout-sel_mode   = 'A'.
    ms_layout-info_fname = 'ROW_COLOR'.  " satır rengi
  ENDMETHOD.

  METHOD add_rows. "default değerler
    DATA: ls_alv      TYPE zgz_s_uruna.

    " Mevcut değişiklikleri kaydet — üzerine yazma
    CALL METHOD mo_alv->check_changed_data.

    DO gv_satir_sayisi TIMES.
      CLEAR ls_alv.
      ls_alv-aurunagaci = '01'.
      ls_alv-icon       = '@09@'.   " sarı uyarı ikonu
      APPEND ls_alv TO mt_alv.
    ENDDO.

    CALL METHOD mo_alv->refresh_table_display( ).
  ENDMETHOD.

  METHOD handler_data_changed.
    DATA: ls_modi  TYPE lvc_s_modi,
          ls_alv   TYPE zgz_s_uruna,
          lv_index TYPE i.

    " mt_good_cells boşsa hiçbir şey yapma
    IF er_data_changed->mt_good_cells IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT er_data_changed->mt_good_cells INTO ls_modi. "değişen satırların tablosu
      READ TABLE mt_alv INTO ls_alv INDEX ls_modi-row_id.
      IF sy-subrc = 0.
        lv_index = ls_modi-row_id.

        CASE ls_modi-fieldname.
          WHEN 'MALZEME'.
            ls_alv-malzeme = ls_modi-value.
          WHEN 'KURETIMYERI'.
            ls_alv-kuretimyeri = ls_modi-value.
          WHEN 'AURUNAGACI'.
            ls_alv-aurunagaci = ls_modi-value.
          WHEN 'YURETIMYERI'.
            ls_alv-yuretimyeri = ls_modi-value.
          WHEN OTHERS.
            CONTINUE.
        ENDCASE.

        " Veri değişince sarıya dönsün
        ls_alv-icon      = '@09@'.  " sarı uyarı
        CLEAR ls_alv-msg.

        MODIFY mt_alv FROM ls_alv INDEX lv_index.
      ENDIF.
    ENDLOOP.

    " Refresh , validate yok
    CALL METHOD mo_alv->refresh_table_display
      EXPORTING
        i_soft_refresh = abap_true.
  ENDMETHOD.

  METHOD load_check_data.
    DATA: lt_selected  TYPE tt_uruna,
          lt_sel_mara  TYPE tt_mara,
          lt_sel_werkk TYPE tt_t001w,
          lt_sel_werky TYPE tt_t001w,
          lt_sel_mastk TYPE tt_mast,
          lt_sel_masty TYPE tt_mast,
          lt_sel_marcy TYPE tt_marc,   " ana malzeme MARC kontrolü için
          lt_mara      TYPE tt_mara,
          lt_t001w_k   TYPE tt_t001w,
          lt_t001w_y   TYPE tt_t001w,
          lt_mast_k    TYPE tt_mast,
          lt_mast_y    TYPE tt_mast,
          lt_marc_y    TYPE tt_marc.

    CALL METHOD mo_alv->check_changed_data.

    " Seçili satırları al ve minimal tablolara doldur
    LOOP AT mt_alv INTO DATA(ls_alv) WHERE selkz = 'X'.
      ls_alv-tabix = sy-tabix.
      APPEND ls_alv TO lt_selected.

      " MARA kontrolü için
      APPEND VALUE #( matnr = ls_alv-malzeme ) TO lt_sel_mara.

      " T001W kontrolü için
      APPEND VALUE #( werks = ls_alv-kuretimyeri ) TO lt_sel_werkk.
      APPEND VALUE #( werks = ls_alv-yuretimyeri ) TO lt_sel_werky.

      " MAST kontrolü için
      APPEND VALUE #( matnr = ls_alv-malzeme
                      werks = ls_alv-kuretimyeri
                      stlal = ls_alv-aurunagaci ) TO lt_sel_mastk.

      " MAST kontrolü için, yeni yerde BOM zaten var mı"
      APPEND VALUE #( matnr = ls_alv-malzeme
                      werks = ls_alv-yuretimyeri
                      stlal = ls_alv-aurunagaci ) TO lt_sel_masty.

      " Ana malzeme MARC kontrolü için , yeni üretim yerinde malzeme var mı
      APPEND VALUE #( matnr = ls_alv-malzeme
                      werks = ls_alv-yuretimyeri ) TO lt_sel_marcy.
    ENDLOOP.

    IF lt_selected IS INITIAL.
      MESSAGE 'Lütfen satır seçiniz!' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    " tüm seçili malzemeleri tek seferde çek
    SELECT matnr FROM mara
      INTO CORRESPONDING FIELDS OF TABLE @lt_mara
      FOR ALL ENTRIES IN @lt_sel_mara
      WHERE matnr = @lt_sel_mara-matnr.
    SORT lt_mara BY matnr.

    " Kopyalanan üretim yeri T001W'de var mı
    SELECT werks FROM t001w
      INTO CORRESPONDING FIELDS OF TABLE @lt_t001w_k
      FOR ALL ENTRIES IN @lt_sel_werkk
      WHERE werks = @lt_sel_werkk-werks.
    SORT lt_t001w_k BY werks.

    " Yeni üretim yeri T001W'de var mı
    SELECT werks FROM t001w
      INTO CORRESPONDING FIELDS OF TABLE @lt_t001w_y
      FOR ALL ENTRIES IN @lt_sel_werky
      WHERE werks = @lt_sel_werky-werks.
    SORT lt_t001w_y BY werks.

    " Kopyalanan üretim yerinde BOM var mı
    SELECT matnr, werks, stlal FROM mast
      INTO CORRESPONDING FIELDS OF TABLE @lt_mast_k
      FOR ALL ENTRIES IN @lt_sel_mastk
      WHERE matnr = @lt_sel_mastk-matnr
        AND werks = @lt_sel_mastk-werks
        AND stlal = @lt_sel_mastk-stlal.
    SORT lt_mast_k BY matnr werks stlal.

    " Yeni üretim yerinde BOM zaten var mı — varsa kopyalamaya gerek yok
    SELECT matnr, werks, stlal FROM mast
      INTO CORRESPONDING FIELDS OF TABLE @lt_mast_y
      FOR ALL ENTRIES IN @lt_sel_masty
      WHERE matnr = @lt_sel_masty-matnr
        AND werks = @lt_sel_masty-werks
        AND stlal = @lt_sel_masty-stlal.
    SORT lt_mast_y BY matnr werks stlal.

    " Ana malzeme yeni üretim yerinde MARC kaydı var mı
    SELECT matnr, werks FROM marc
      INTO CORRESPONDING FIELDS OF TABLE @lt_marc_y
      FOR ALL ENTRIES IN @lt_sel_marcy
      WHERE matnr = @lt_sel_marcy-matnr
        AND werks = @lt_sel_marcy-werks.
    SORT lt_marc_y BY matnr werks.

    " Çekilen verileri validate_all'a gönder
    rv_error = me->validate_all(
      EXPORTING
        it_selected = lt_selected
        it_mara     = lt_mara
        it_t001w_k  = lt_t001w_k
        it_t001w_y  = lt_t001w_y
        it_mast_k   = lt_mast_k
        it_mast_y   = lt_mast_y
        it_marc_y   = lt_marc_y ).
  ENDMETHOD.

  METHOD validate_all.
    DATA: ls_alv   TYPE zgz_s_uruna,
          lv_index TYPE i,
          lv_rc    TYPE sy-subrc.

    DATA lv_has_error TYPE abap_bool VALUE abap_false.

    LOOP AT it_selected INTO ls_alv.
      lv_index = ls_alv-tabix."her mesaj ilgili satıra
      CLEAR ls_alv-msg.

      " boş alan kontrolü
      IF ls_alv-malzeme IS INITIAL OR ls_alv-kuretimyeri IS INITIAL OR ls_alv-yuretimyeri IS INITIAL.
        ls_alv-msg = 'Malzeme, kopyalanan veya yeni üretim yeri boş!'.
        ls_alv-icon     = '@0A@'.    " kırmızı X
        ls_alv-row_color = 'C610'.    " kırmızı satır
        lv_has_error = abap_true.
        MODIFY mt_alv FROM ls_alv INDEX lv_index.
        CONTINUE.
      ENDIF.

      " MARA kontrolü
      READ TABLE it_mara WITH KEY matnr = ls_alv-malzeme
        BINARY SEARCH TRANSPORTING NO FIELDS. "notlarda
      lv_rc = sy-subrc.  " hemen kaydet"
      IF lv_rc <> 0.
        ls_alv-msg = 'Malzemenin temel verileri yoktur!'.
        ls_alv-icon     = '@0A@'.    " kırmızı X
        ls_alv-row_color = 'C610'.    " kırmızı satır
        lv_has_error = abap_true.
        MODIFY mt_alv FROM ls_alv INDEX lv_index.
        CONTINUE.  "  gerisini çalıştırma
      ENDIF.

      " Kopyalanan üretim yeri
      READ TABLE it_t001w_k WITH KEY werks = ls_alv-kuretimyeri
        BINARY SEARCH TRANSPORTING NO FIELDS.
      lv_rc = sy-subrc.
      IF lv_rc <> 0.
        ls_alv-msg = |{ ls_alv-kuretimyeri } üretim yeri bulunamaktadır!|.
        ls_alv-icon     = '@0A@'.    " kırmızı X
        ls_alv-row_color = 'C610'.    " kırmızı satır
        lv_has_error = abap_true.
        MODIFY mt_alv FROM ls_alv INDEX lv_index.
        CONTINUE.
      ENDIF.

      " Kopyalanan yerde BOM var mı
      READ TABLE it_mast_k WITH KEY matnr = ls_alv-malzeme
                                    werks = ls_alv-kuretimyeri
                                    stlal = ls_alv-aurunagaci
        BINARY SEARCH TRANSPORTING NO FIELDS.
      lv_rc = sy-subrc.
      IF lv_rc <> 0.
        ls_alv-msg = |{ ls_alv-malzeme } - { ls_alv-kuretimyeri } üretim yerinde ürün ağacı bulunmamaktadır!|.
        ls_alv-icon     = '@0A@'.    " kırmızı X
        ls_alv-row_color = 'C610'.    " kırmızı satır
        lv_has_error = abap_true.
        MODIFY mt_alv FROM ls_alv INDEX lv_index.
        CONTINUE.
      ENDIF.

      " Yeni üretim yeri
      READ TABLE it_t001w_y WITH KEY werks = ls_alv-yuretimyeri
        BINARY SEARCH TRANSPORTING NO FIELDS.
      lv_rc = sy-subrc.
      IF lv_rc <> 0.
        ls_alv-msg = |{ ls_alv-yuretimyeri } yeni üretim yeri bulunamaktadır!|.
        ls_alv-icon     = '@0A@'.    " kırmızı X
        ls_alv-row_color = 'C610'.    " kırmızı satır
        lv_has_error = abap_true.
        MODIFY mt_alv FROM ls_alv INDEX lv_index.
        CONTINUE.
      ENDIF.

      " Yeni yerde BOM zaten var mı
      READ TABLE it_mast_y WITH KEY matnr = ls_alv-malzeme
                                    werks = ls_alv-yuretimyeri
                                    stlal = ls_alv-aurunagaci
        BINARY SEARCH TRANSPORTING NO FIELDS.
      lv_rc = sy-subrc.
      IF lv_rc = 0.
        ls_alv-msg = |{ ls_alv-malzeme } yeni üretim yerinde zaten mevcut!|.
        ls_alv-icon     = '@0A@'.    " kırmızı X
        ls_alv-row_color = 'C610'.    " kırmızı satır
        lv_has_error = abap_true.
        MODIFY mt_alv FROM ls_alv INDEX lv_index.
        CONTINUE.
      ENDIF.

      "Hedef Üretim Yerinde Malzeme Mevcut mu (MARC Kontrolü)
      READ TABLE it_marc_y WITH KEY matnr = ls_alv-malzeme
                                    werks = ls_alv-yuretimyeri
        BINARY SEARCH TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.
        ls_alv-msg = |{ ls_alv-malzeme } malzemesi { ls_alv-yuretimyeri } üretim yerinde bulunmamaktadır!|.
        ls_alv-icon     = '@0A@'.    " kırmızı X
        ls_alv-row_color = 'C610'.    " kırmızı satır
        lv_has_error = abap_true.
        MODIFY mt_alv FROM ls_alv INDEX lv_index.
        CONTINUE.
      ENDIF.

      " tüm kontroller geçti
      ls_alv-icon      = '@08@'.  " yeşil tik
      ls_alv-row_color = 'C510'.  " yeşil
      MODIFY mt_alv FROM ls_alv INDEX lv_index.
    ENDLOOP.

    " hata flagini döndür
    rv_error = lv_has_error.

    CALL METHOD mo_alv->refresh_table_display
      EXPORTING
        i_soft_refresh = abap_true.
  ENDMETHOD.

  METHOD cs_bom.
    DATA: ls_selected TYPE zgz_s_uruna,
          lt_selected TYPE tt_uruna,
          lt_stb      TYPE TABLE OF stpox,
          ls_stb      TYPE stpox,
          lv_index    TYPE i,
          lv_hata     TYPE abap_bool,
          ls_stko_hdr TYPE stko_api01,
          "ls_stko_hdr TYPE stko,
          lt_stpo     TYPE TABLE OF stpo_api01,
          ls_stpo     TYPE stpo_api01.

    " MAST,STKO için"
    DATA: BEGIN OF ls_mast_stlnr,
            matnr TYPE mast-matnr,
            werks TYPE mast-werks,
            stlal TYPE mast-stlal,
            stlnr TYPE mast-stlnr,
          END OF ls_mast_stlnr.
    DATA lt_mast_stlnr LIKE TABLE OF ls_mast_stlnr.

    DATA: BEGIN OF ls_stko_bmeng,
            stlnr TYPE stko-stlnr,
            bmeng TYPE stko-bmeng,
            bmein TYPE stko-bmein,
          END OF ls_stko_bmeng.
    DATA lt_stko LIKE TABLE OF ls_stko_bmeng.

    " Bileşen toplama için
    DATA: BEGIN OF ls_bom_item,
            matnr TYPE mast-matnr,
            werks TYPE mast-werks,
            idnrk TYPE stpox-idnrk,
            postp TYPE stpox-postp,
            mnglg TYPE stpox-mnglg,
            meins TYPE stpox-meins,
          END OF ls_bom_item.
    DATA: lt_bom_items LIKE TABLE OF ls_bom_item,
          lt_all_idnrk TYPE tt_mara,
          lt_all_marc  TYPE tt_marc.

    " Seçili satırları al
    LOOP AT mt_alv INTO ls_selected WHERE selkz = 'X'.
      ls_selected-tabix = sy-tabix.
      APPEND ls_selected TO lt_selected.
    ENDLOOP.

    IF lt_selected IS INITIAL.
      RETURN.
    ENDIF.

    " Toplu SELECT,MAST stlnr ve STKO bmeng
    DATA lt_mast_src TYPE TABLE OF ty_mast.
    LOOP AT lt_selected INTO ls_selected.
      APPEND VALUE #( matnr = ls_selected-malzeme
                      werks = ls_selected-kuretimyeri
                      stlal = ls_selected-aurunagaci ) TO lt_mast_src.
    ENDLOOP.

    SELECT matnr, werks, stlal, stlnr FROM mast
      INTO CORRESPONDING FIELDS OF TABLE @lt_mast_stlnr
      FOR ALL ENTRIES IN @lt_mast_src
      WHERE matnr = @lt_mast_src-matnr
        AND werks = @lt_mast_src-werks
        AND stlal = @lt_mast_src-stlal.
    SORT lt_mast_stlnr BY matnr werks stlal.

    IF lt_mast_stlnr IS NOT INITIAL.
      DATA lt_sel_stlnr TYPE TABLE OF ty_sel_stlnr.
      LOOP AT lt_mast_stlnr INTO ls_mast_stlnr.
        APPEND VALUE #( stlnr = ls_mast_stlnr-stlnr ) TO lt_sel_stlnr.
      ENDLOOP.

      SELECT stlnr, bmeng, bmein FROM stko
        INTO CORRESPONDING FIELDS OF TABLE @lt_stko
        FOR ALL ENTRIES IN @lt_sel_stlnr
        WHERE stlnr = @lt_sel_stlnr-stlnr.
      SORT lt_stko BY stlnr.
    ENDIF.

    " BOM'ları patlat, bileşenleri topla
    LOOP AT lt_selected INTO ls_selected.
      CLEAR lt_stb.
      lv_index = ls_selected-tabix.

      CALL FUNCTION 'CS_BOM_EXPL_MAT_V2'
        EXPORTING
          aumgb                 = 'X'
          capid                 = 'PP01'
          datuv                 = sy-datum
          ehndl                 = '1'
          mktls                 = 'X'
          mmory                 = '0'
          mtnrv                 = ls_selected-malzeme
          stlal                 = ls_selected-aurunagaci
          stlan                 = '1'
          svwvo                 = 'X'
          werks                 = ls_selected-kuretimyeri
          vrsvo                 = 'X'
        TABLES
          stb                   = lt_stb
        EXCEPTIONS
          alt_not_found         = 1
          call_invalid          = 2
          material_not_found    = 3
          missing_authorization = 4
          no_bom_found          = 5
          no_plant_data         = 6
          no_suitable_bom_found = 7
          conversion_error      = 8
          OTHERS                = 9.

      IF sy-subrc <> 0.
        ls_selected-msg       = 'BOM bulunamadı!'.
        ls_selected-icon      = '@0A@'.
        ls_selected-row_color = 'C610'.
        MODIFY mt_alv FROM ls_selected INDEX lv_index.
        DELETE lt_selected WHERE malzeme     = ls_selected-malzeme
                             AND kuretimyeri = ls_selected-kuretimyeri
                             AND aurunagaci  = ls_selected-aurunagaci
                             AND yuretimyeri = ls_selected-yuretimyeri.
        CONTINUE.
      ENDIF.

      " BOM kalemlerini sakla,MARC için bileşenleri topla
      LOOP AT lt_stb INTO ls_stb.
        ls_bom_item-matnr = ls_selected-malzeme.
        ls_bom_item-werks = ls_selected-kuretimyeri.
        ls_bom_item-idnrk = ls_stb-idnrk.
        ls_bom_item-postp = ls_stb-postp.
        ls_bom_item-mnglg = ls_stb-mnglg.
        ls_bom_item-meins = ls_stb-meins.
        APPEND ls_bom_item TO lt_bom_items.
        APPEND VALUE #( matnr = ls_stb-idnrk ) TO lt_all_idnrk.
      ENDLOOP.
    ENDLOOP.

    " Tek SELECT  tüm bileşenlerin MARC kaydı
    IF lt_all_idnrk IS NOT INITIAL.
      SORT lt_all_idnrk BY matnr.
      DELETE ADJACENT DUPLICATES FROM lt_all_idnrk COMPARING matnr.

      SELECT matnr, werks FROM marc
        INTO CORRESPONDING FIELDS OF TABLE @lt_all_marc
        FOR ALL ENTRIES IN @lt_all_idnrk
        WHERE matnr = @lt_all_idnrk-matnr.
      SORT lt_all_marc BY matnr werks.
    ENDIF.

    " Her seçili satır için BOM yarat
    LOOP AT lt_selected INTO ls_selected.
      CLEAR: lt_stpo, lv_hata.
      lv_index = ls_selected-tabix.

      " Kalemleri doldur MARC kontrolü ile
      LOOP AT lt_bom_items INTO ls_bom_item
        WHERE matnr = ls_selected-malzeme
          AND werks = ls_selected-kuretimyeri.

        READ TABLE lt_all_marc WITH KEY matnr = ls_bom_item-idnrk
                                        werks = ls_selected-yuretimyeri
          BINARY SEARCH TRANSPORTING NO FIELDS.

        IF sy-subrc <> 0.
          ls_selected-msg       = |{ ls_bom_item-idnrk } bileşeni { ls_selected-yuretimyeri } üretim yerinde bulunmamaktadır!|.
          ls_selected-icon      = '@0A@'.
          ls_selected-row_color = 'C610'.
          lv_hata               = abap_true.
          CONTINUE.
        ENDIF.

        CLEAR ls_stpo.
        ls_stpo-item_categ = ls_bom_item-postp.
        ls_stpo-component  = ls_bom_item-idnrk.
        ls_stpo-comp_qty   = ls_bom_item-mnglg.
        ls_stpo-comp_unit  = ls_bom_item-meins.
        APPEND ls_stpo TO lt_stpo.
      ENDLOOP.

      IF lv_hata = abap_true.
        MODIFY mt_alv FROM ls_selected INDEX lv_index.
        CONTINUE.
      ENDIF.

      " Memory'den header bilgilerini al
      CLEAR ls_stko_hdr.
      READ TABLE lt_mast_stlnr INTO ls_mast_stlnr
        WITH KEY matnr = ls_selected-malzeme
                 werks = ls_selected-kuretimyeri
                 stlal = ls_selected-aurunagaci
        BINARY SEARCH.

      IF sy-subrc = 0.
        READ TABLE lt_stko INTO ls_stko_bmeng
          WITH KEY stlnr = ls_mast_stlnr-stlnr
          BINARY SEARCH.

        IF sy-subrc = 0.
          ls_stko_hdr-base_quan = ls_stko_bmeng-bmeng.  " temel miktar
          REPLACE ALL OCCURRENCES OF '.' IN ls_stko_hdr-base_quan WITH ','.
          ls_stko_hdr-base_unit = ls_stko_bmeng-bmein.  " ölçü birimi
        ENDIF.
      ENDIF.

      " fonks char 10a uygun
      DATA(lv_date) = CONV csap_mbom-datuv( |{ sy-datum+6(2) }{ sy-datum+4(2) }{ sy-datum(4) }| ).

      " BOM yarat
      CALL FUNCTION 'CSAP_MAT_BOM_CREATE'
        EXPORTING
          material          = ls_selected-malzeme
          plant             = ls_selected-yuretimyeri
          bom_usage         = '1'
          valid_from        = lv_date
          i_stko            = ls_stko_hdr
          fl_default_values = 'X'
        TABLES
          t_stpo            = lt_stpo
        EXCEPTIONS
          error             = 1
          OTHERS            = 2.

      IF sy-subrc <> 0.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        ls_selected-msg       = 'BOM yaratılamadı!'.
        ls_selected-icon      = '@0A@'.
        ls_selected-row_color = 'C610'.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
        ls_selected-msg       = |{ ls_selected-malzeme } - { ls_selected-yuretimyeri } BOM başarıyla yaratıldı!|.
        ls_selected-icon      = '@08@'.
        ls_selected-row_color = 'C510'.
      ENDIF.

      MODIFY mt_alv FROM ls_selected INDEX lv_index.
    ENDLOOP.

    " ALV yenile
    CALL METHOD mo_alv->refresh_table_display( ).
  ENDMETHOD.

  METHOD handler_toolbar.
    DATA: ls_toolbar TYPE stb_button.

    " Tüm Satırları Seç
    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 0.
    ls_toolbar-function  = 'SEL_ALL'.
    ls_toolbar-icon      = '@9L@'.
    ls_toolbar-text      = 'Tümünü Seç'.
    ls_toolbar-quickinfo = 'Tüm satırları seç'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    " Seçimi Kaldır
    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 0.
    ls_toolbar-function  = 'DESEL_ALL'.
    ls_toolbar-icon      = '@9M@'.
    ls_toolbar-text      = 'Seçimi Kaldır'.
    ls_toolbar-quickinfo = 'Tüm seçimleri kaldır'.
    APPEND ls_toolbar TO e_object->mt_toolbar.


    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3. "3Seperatör (ayraç)
    APPEND ls_toolbar TO e_object->mt_toolbar.

    " BAPI Kaydet
    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 0.
    ls_toolbar-function  = 'BAPI_BOM'.
    ls_toolbar-icon      = '@2L@'.
    ls_toolbar-text      = 'Kaydet'.
    ls_toolbar-quickinfo = 'Kaydet'.
    APPEND ls_toolbar TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD handler_user_command.
    CASE e_ucomm.
      WHEN 'BAPI_BOM'.
        IF me->load_check_data( ) = abap_true. " Hata varsa cs_bom çalıştırma
          RETURN.
        ENDIF.

        me->cs_bom( ).
      WHEN 'SEL_ALL'.
        LOOP AT mt_alv ASSIGNING FIELD-SYMBOL(<fs_alv>).
          <fs_alv>-selkz = 'X'.
        ENDLOOP.
        CALL METHOD mo_alv->refresh_table_display.

      WHEN 'DESEL_ALL'.
        LOOP AT mt_alv ASSIGNING <fs_alv>.
          <fs_alv>-selkz = ''.  " MODIFY yok — direkt değişiyor
        ENDLOOP.
        CALL METHOD mo_alv->refresh_table_display.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
