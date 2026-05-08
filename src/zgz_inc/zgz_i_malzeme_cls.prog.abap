*&---------------------------------------------------------------------*
*& Include          ZGZ_I_MALZEME_CLS
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

    IF go_docker IS INITIAL.
      " Docking Container
      CREATE OBJECT go_docker
        EXPORTING
          repid     = sy-repid
          dynnr     = sy-dynnr
          side      = cl_gui_docking_container=>dock_at_bottom
          extension = 300.

      " ALV Grid oluştur
      CREATE OBJECT go_alv
        EXPORTING
          i_parent = go_docker.

      SET HANDLER me->handler_toolbar FOR go_alv.
      SET HANDLER me->handler_user_command FOR go_alv.
      SET HANDLER me->handler_data_changed FOR go_alv.

      " Layout ayarla
      me->set_layout( ).
      me->set_fieldcat( ).

      DATA: lt_exclude TYPE ui_functions.

      " standart butonları kaldır
      APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row  TO lt_exclude. " yeni satır ekle
      APPEND cl_gui_alv_grid=>mc_fc_loc_append_row  TO lt_exclude. " sona satır ekle

      CALL METHOD go_alv->set_table_for_first_display
        EXPORTING
          is_layout            = gs_layout             " Layout
          it_toolbar_excluding = lt_exclude
        CHANGING
          it_outtab            = gt_alv                " Output Table
          it_fieldcatalog      = gt_fcat.                " Field Catalo

      " Edit moda al
      CALL METHOD go_alv->set_ready_for_input
        EXPORTING
          i_ready_for_input = 1.
    ENDIF.
  ENDMETHOD. "pbo en son güncel veri neyse, onu tek seferde basar

  METHOD pai.
    CASE ok_code.
      WHEN 'ENTER' OR ' '.  "  ENTER komutu
        IF gv_satir_sayisi IS INITIAL OR gv_satir_sayisi <= 0.
          MESSAGE 'Satir sayisi giriniz!' TYPE 'S' DISPLAY LIKE 'W'.
          RETURN.
        ELSE.
          me->add_rows( ).
          CLEAR gv_satir_sayisi.
        ENDIF.
      WHEN '&BACK'.
        LEAVE TO SCREEN 0.
    ENDCASE.
  ENDMETHOD.

  METHOD set_fieldcat.
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name   = 'ZGZ_S_MALZEME'
        i_bypassing_buffer = 'X'
      CHANGING
        ct_fieldcat        = gt_fcat.

    LOOP AT gt_fcat ASSIGNING <gfs_fc>.
      CASE <gfs_fc>-fieldname.
        WHEN 'SELKZ'.
          <gfs_fc>-key       = abap_true.
          <gfs_fc>-checkbox  = abap_true.
          <gfs_fc>-edit      = abap_true.
          <gfs_fc>-outputlen = 3.
          <gfs_fc>-scrtext_s = 'Sçm'.
          <gfs_fc>-scrtext_m = 'Seçim'.
        WHEN 'ICON'.
          <gfs_fc>-outputlen = 5.
          <gfs_fc>-scrtext_s = 'Ikon'.
          <gfs_fc>-scrtext_m = 'Ikon'.
          <gfs_fc>-icon      = abap_true.
          <gfs_fc>-edit      = abap_false.
        WHEN 'MATNR'.
          <gfs_fc>-outputlen = 20.
          <gfs_fc>-scrtext_m = 'Malzeme'.
        WHEN 'WERKS'.
          <gfs_fc>-outputlen = 10.
          <gfs_fc>-scrtext_m = 'Üretim Yeri'.
        WHEN 'MRP_GROUP'.
          <gfs_fc>-outputlen = 8.
          <gfs_fc>-scrtext_m = 'MRP Grup'.
        WHEN 'MRP_TYPE'.
          <gfs_fc>-outputlen = 6.
          <gfs_fc>-scrtext_m = 'MRP Tip'.
        WHEN 'MRP_CTRLER'.
          <gfs_fc>-outputlen = 8.
          <gfs_fc>-scrtext_m = 'MRP Kont'.
        WHEN 'LOTSIZEKEY'.
          <gfs_fc>-outputlen = 8.
          <gfs_fc>-scrtext_m = 'Lot Boy'.
        WHEN 'PROC_TYPE'.
          <gfs_fc>-outputlen = 6.
          <gfs_fc>-scrtext_m = 'Temin'.
        WHEN 'BACKFLUSH'.
          <gfs_fc>-outputlen = 6.
          <gfs_fc>-scrtext_m = 'Geri Yık'.
        WHEN 'PLANNING_STRATEGY'.
          <gfs_fc>-outputlen = 8.
          <gfs_fc>-scrtext_m = 'Strateji'.
        WHEN 'AVAILCHECK'.
          <gfs_fc>-outputlen = 6.
          <gfs_fc>-scrtext_m = 'Kont'.
        WHEN 'DEP_REQ_ID'.
          <gfs_fc>-outputlen = 6.
          <gfs_fc>-scrtext_m = 'Bag Grksnm'.
        WHEN 'REPMANPROF'.
          <gfs_fc>-outputlen = 8.
          <gfs_fc>-scrtext_m = 'Rep Prof'.
        WHEN 'REP_MANUF'.
          <gfs_fc>-outputlen = 6.
          <gfs_fc>-scrtext_m = 'Rep Ürt'.
        WHEN 'BATCH_MGMT'.
          <gfs_fc>-outputlen = 6.
          <gfs_fc>-scrtext_m = 'Parti'.
        WHEN 'MSG'.
          <gfs_fc>-outputlen = 50.
          <gfs_fc>-scrtext_s = 'Msg'.
          <gfs_fc>-scrtext_m = 'Mesaj'.
          <gfs_fc>-scrtext_l = 'Durum Mesajı'.
          <gfs_fc>-edit      = abap_false.
        WHEN 'ROW_COLOR'.
          <gfs_fc>-no_out = 'X'.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_layout.
    CLEAR gs_layout.

    gs_layout-zebra      = abap_true.
    gs_layout-sel_mode   = 'A'. "Çoklu Seçim İmkanı,Seçim Sütunu
    gs_layout-edit       = abap_true.
    gs_layout-info_fname = 'ROW_COLOR'.
  ENDMETHOD.

  METHOD add_rows. "default değerler ekle
    DATA: ls_alv      TYPE zgz_s_malzeme,
          lv_last_row TYPE i.

    DO gv_satir_sayisi TIMES.
      CLEAR ls_alv.
      ls_alv-mrp_group         = ' '.
      ls_alv-mrp_type          = 'PD'.
      ls_alv-mrp_ctrler        = '001'.
      ls_alv-lotsizekey        = 'EX'.
      ls_alv-proc_type         = 'X'.
      ls_alv-backflush         = '1'.
      ls_alv-planning_strategy = '10'.
      ls_alv-availcheck        = '02'.
      ls_alv-dep_req_id        = '1'.
      ls_alv-repmanprof        = ' '.
      ls_alv-rep_manuf        = ' '.
      ls_alv-batch_mgmt        = 'X'.
      APPEND ls_alv TO gt_alv.
    ENDDO.

    CALL METHOD go_alv->refresh_table_display.
  ENDMETHOD.

  METHOD handler_data_changed. "f4 de çalışmaz
    DATA: ls_modi  TYPE lvc_s_modi,
          ls_alv   TYPE zgz_s_malzeme,
          lv_index TYPE i.

    LOOP AT er_data_changed->mt_good_cells INTO ls_modi. "değiştirilen ve hata içermeyen tüm hücreleri mt_good_cells tablosunda tutar
      READ TABLE gt_alv INTO ls_alv INDEX ls_modi-row_id. "Değişiklik yapılan satır numarası
      IF sy-subrc = 0.
        lv_index = ls_modi-row_id.

        " Değişen alanı satıra yaz
        CASE ls_modi-fieldname.
          WHEN 'MATNR'.
            ls_alv-matnr = ls_modi-value.
          WHEN 'WERKS'.
            ls_alv-werks = ls_modi-value.
          WHEN OTHERS. "diğer alanlarda validate yok
            CONTINUE.
        ENDCASE.

        MODIFY gt_alv FROM ls_alv INDEX lv_index.
      ENDIF.
    ENDLOOP.

    " soft_refresh seçimleri korur
    CALL METHOD go_alv->refresh_table_display
      EXPORTING
        i_soft_refresh = abap_true.
  ENDMETHOD.

  METHOD validate_row.
    rv_ok = abap_false.

    "iki alan boş
    IF cs_alv-matnr IS INITIAL OR cs_alv-werks IS INITIAL.
      cs_alv-icon      = '@0A@'.
      cs_alv-msg       = 'Malzeme no veya üretim yeri boş!'.
      cs_alv-row_color = 'C610'.
      RETURN.
    ENDIF.

    "malzeme yok
    IF cs_alv-matnr IS NOT INITIAL.
      SELECT SINGLE @abap_true FROM mara
        INTO @DATA(lv_mara)
        WHERE matnr = @cs_alv-matnr.
      IF lv_mara <> abap_true.
        cs_alv-icon      = '@0A@'.
        cs_alv-msg       = 'Malzemenin temel verileri yoktur!'.
        cs_alv-row_color = 'C610'.
        RETURN.
      ENDIF.
    ENDIF.

    "iki alan da dolu
    IF cs_alv-matnr IS NOT INITIAL AND cs_alv-werks IS NOT INITIAL.
      SELECT SINGLE @abap_true FROM t001w
        INTO @DATA(lv_werks)
        WHERE werks = @cs_alv-werks.
      IF lv_werks <> abap_true.
        cs_alv-icon      = '@0A@'.
        cs_alv-msg       = 'Üretim yeri geçersiz!'.
        cs_alv-row_color = 'C610'.
        RETURN.
      ENDIF. "üretim yeri yok

      SELECT SINGLE @abap_true FROM marc
        INTO @DATA(lv_marc)
        WHERE matnr = @cs_alv-matnr
          AND werks = @cs_alv-werks.
      IF lv_marc = abap_true.
        cs_alv-icon      = '@0A@'.
        cs_alv-msg       = 'Malzeme bu üretim yerinde zaten genişletilmiştir!'.
        cs_alv-row_color = 'C610'.
        RETURN.
      ENDIF. "zaten genişletilmiş
    ENDIF.

    rv_ok = abap_true.
  ENDMETHOD.

  METHOD bapi_kaydet.
    DATA: ls_alv        TYPE zgz_s_malzeme,
          ls_headdata   TYPE bapimathead,
          ls_plantdata  TYPE bapi_marc,
          ls_plantdatax TYPE bapi_marcx,
          lt_return     TYPE TABLE OF bapi_matreturn2,
          ls_return     TYPE bapi_matreturn2,
          lv_index      TYPE i.

    CALL METHOD go_alv->check_changed_data.

    IF NOT line_exists( gt_alv[ selkz = 'X' ] ). "bu değere sahip tabloda veri yok
      MESSAGE 'Lütfen kaydedilecek satırları seçiniz.' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    " SEL = 'X' olan satırları işle
    LOOP AT gt_alv INTO ls_alv WHERE selkz = 'X'.
      lv_index = sy-tabix.

      READ TABLE gt_alv INTO ls_alv INDEX lv_index. "alvde var mı
      IF sy-subrc <> 0. CONTINUE. ENDIF.

      " Kayıt öncesi son kontrol
      IF me->validate_row( CHANGING cs_alv = ls_alv ) = abap_false.
        MODIFY gt_alv FROM ls_alv INDEX lv_index.
        CONTINUE.
      ENDIF.

      CLEAR ls_headdata.
      ls_headdata-material        = ls_alv-matnr.
      ls_headdata-mrp_view        = 'X'.
      ls_headdata-work_sched_view = 'X'.

      CLEAR ls_plantdata.
      ls_plantdata-plant             = ls_alv-werks.
      ls_plantdata-mrp_group         = ls_alv-mrp_group.
      ls_plantdata-mrp_type          = ls_alv-mrp_type.
      ls_plantdata-mrp_ctrler        = ls_alv-mrp_ctrler.
      ls_plantdata-lotsizekey        = ls_alv-lotsizekey.
      ls_plantdata-proc_type         = ls_alv-proc_type.
      ls_plantdata-backflush         = ls_alv-backflush.
      ls_plantdata-planning_strategy = ls_alv-planning_strategy.
      ls_plantdata-availcheck        = ls_alv-availcheck.
      ls_plantdata-dep_req_id        = ls_alv-dep_req_id.
      ls_plantdata-repmanprof        = ls_alv-repmanprof.
      ls_plantdata-rep_manuf        = ls_alv-rep_manuf.
      ls_plantdata-batch_mgmt        = ls_alv-batch_mgmt.

      CLEAR ls_plantdatax.
      ls_plantdatax-plant             = ls_alv-werks.
      ls_plantdatax-mrp_group         = 'X'.
      ls_plantdatax-mrp_type          = 'X'.
      ls_plantdatax-mrp_ctrler        = 'X'.
      ls_plantdatax-lotsizekey        = 'X'.
      ls_plantdatax-proc_type         = 'X'.
      ls_plantdatax-backflush         = 'X'.
      ls_plantdatax-planning_strategy = 'X'.
      ls_plantdatax-availcheck        = 'X'.
      ls_plantdatax-dep_req_id        = 'X'.
      ls_plantdatax-repmanprof        = 'X'.
      ls_plantdatax-rep_manuf        = 'X'.
      ls_plantdatax-batch_mgmt        = 'X'.

      CLEAR lt_return.
      "bapiye gitti
      CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
        EXPORTING
          headdata       = ls_headdata
          plantdata      = ls_plantdata
          plantdatax     = ls_plantdatax
        TABLES
          returnmessages = lt_return.

      "mesajlarda e varsa işlemi geri al
      READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
      IF sy-subrc = 0.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        ls_alv-icon = '@0A@'.
        ls_alv-msg  = ls_return-message.
        ls_alv-row_color   = 'C610'.
      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = 'X'.
        ls_alv-icon = '@08@'.
        ls_alv-msg  = 'Başarıyla kaydedildi.'.
        ls_alv-row_color   = 'C510'.
      ENDIF.

      MODIFY gt_alv FROM ls_alv INDEX lv_index.
    ENDLOOP.

    CALL METHOD go_alv->refresh_table_display.
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
    ls_toolbar-function  = 'BAPI_SAVE'.
    ls_toolbar-icon      = '@2L@'.
    ls_toolbar-text      = 'Kaydet'.
    ls_toolbar-quickinfo = 'BAPI ile Kaydet'.
    APPEND ls_toolbar TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD handler_user_command.
    CASE e_ucomm.
      WHEN 'BAPI_SAVE'.
        me->bapi_kaydet( ).
      WHEN 'SEL_ALL'.
        LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<fs_alv>).
          <fs_alv>-selkz = 'X'.
        ENDLOOP.

        CALL METHOD go_alv->refresh_table_display.
      WHEN 'DESEL_ALL'.
        LOOP AT gt_alv ASSIGNING <fs_alv>.
          <fs_alv>-selkz = ''.
        ENDLOOP.

        CALL METHOD go_alv->refresh_table_display.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
