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

      CALL METHOD go_alv->set_table_for_first_display
        EXPORTING
          is_layout       = gs_layout                " Layout
        CHANGING
          it_outtab       = gt_alv                " Output Table
          it_fieldcatalog = gt_fcat.                " Field Catalo

      " Edit moda al
      CALL METHOD go_alv->set_ready_for_input
        EXPORTING
          i_ready_for_input = 1.
    ENDIF.
  ENDMETHOD. "pbo en son güncel veri neyse, onu tek seferde basar

  METHOD pai.
    CASE sy-ucomm.
      WHEN '&BTN_ONAY'.
        IF gv_satir_sayisi IS INITIAL OR gv_satir_sayisi <= 0.
          MESSAGE 'Satir sayisi giriniz!'  TYPE 'S' DISPLAY LIKE 'W' .
          RETURN.
        ELSE.
          me->add_rows( ).
          CLEAR gv_satir_sayisi.   "temizl
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
      IF <gfs_fc>-fieldname = 'SELKZ'.
        <gfs_fc>-key = <gfs_fc>-checkbox = <gfs_fc>-edit = abap_true.
        <gfs_fc>-scrtext_s = 'Seçim'.
        <gfs_fc>-scrtext_m = 'Seçim'.
      ELSEIF <gfs_fc>-fieldname = 'ICON'.
        <gfs_fc>-scrtext_s = 'Ikon'.
        <gfs_fc>-scrtext_m = 'Ikon'.
      ELSEIF <gfs_fc>-fieldname = 'MSG'.
        <gfs_fc>-scrtext_s = 'Msg'.
        <gfs_fc>-scrtext_m = 'Mesaj'.
        <gfs_fc>-scrtext_l = 'Durum Mesajı'.
      ELSEIF <gfs_fc>-fieldname = 'ROW_COLOR'.
        <gfs_fc>-no_out = 'X'.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_layout.
    CLEAR gs_layout.

    gs_layout-zebra      = abap_true.
    gs_layout-cwidth_opt = abap_true.
    gs_layout-sel_mode   = 'A'. "Çoklu Seçim İmkanı,Seçim Sütunu
    gs_layout-edit       = abap_true.
    gs_layout-info_fname = 'ROW_COLOR'.
  ENDMETHOD.

  METHOD add_rows. "default değerler ekle
    DATA: ls_alv      TYPE zgz_s_malzeme,
          lv_last_row TYPE i.

    DESCRIBE TABLE gt_alv LINES lv_last_row. "satır sayısı alma

    DO gv_satir_sayisi TIMES.
      CLEAR ls_alv.
      ls_alv-mrp_group         = 'ZDIS'.
      ls_alv-mrp_type          = 'PD'.
      ls_alv-mrp_ctrler        = '001'.
      ls_alv-lotsizekey        = 'EX'.
      ls_alv-proc_type         = 'X'.
      ls_alv-backflush         = '1'.
      ls_alv-planning_strategy = '10'.
      ls_alv-availcheck        = '02'.
      ls_alv-dep_req_id        = '2'.
      ls_alv-repmanprof        = 'X'.
      ls_alv-serno_prof        = 'Z001'.
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

        " kontrol
        me->validate_row( CHANGING cs_alv = ls_alv ).

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

      " Kayıt öncesi son kontrol
      IF me->validate_row( CHANGING cs_alv = ls_alv ) = abap_false.
        MODIFY gt_alv FROM ls_alv INDEX lv_index.
        CONTINUE.
      ENDIF.

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
      ls_plantdata-serno_prof        = ls_alv-serno_prof.
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
      ls_plantdatax-serno_prof        = 'X'.
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

    CLEAR ls_toolbar.
    ls_toolbar-butn_type = 3. "3Seperatör (ayraç) ekliyoruz.
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
      WHEN '&IC1'.  " ←ALV satırına çift tık
        DATA: ls_alv TYPE zgz_s_malzeme,
              ls_row TYPE i.

        " Tıklanan satırı al
        CALL METHOD go_alv->get_current_cell
          IMPORTING
            e_row = ls_row                " Row on Grid
*           e_value   =                  " Value
"           e_col = ls_col                " Column on Grid
*           es_row_id =                  " Row ID
*           es_col_id =                  " Column ID
*           es_row_no =                  " Numeric Row ID
          .

        READ TABLE gt_alv INTO ls_alv INDEX ls_row.
        IF sy-subrc = 0 AND ls_alv-msg IS NOT INITIAL.
          MESSAGE ls_alv-msg TYPE 'I'.  " popup mesaj
        ENDIF.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
