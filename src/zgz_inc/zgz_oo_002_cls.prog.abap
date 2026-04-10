CLASS lcl_controller IMPLEMENTATION.
  METHOD handle_toolbar. "toolbar button ekleme
    DATA: ls_toolbar TYPE stb_button.

    CLEAR: ls_toolbar.

    ls_toolbar-function = 'ADOBE_PRINT'.
    ls_toolbar-icon = '@03@'.
    ls_toolbar-quickinfo = 'Adobe Form Bas'.

    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR: ls_toolbar.

    ls_toolbar-function = 'EXCELD'.
    ls_toolbar-icon = '@2S@'.
    ls_toolbar-quickinfo = 'Excel Indir'.

    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR: ls_toolbar.

    ls_toolbar-function  = 'SEND_MAIL'.
    ls_toolbar-icon      = '@1S@'.
    ls_toolbar-quickinfo = 'Mail Gönder'.

    APPEND ls_toolbar TO e_object->mt_toolbar.
  ENDMETHOD.


  METHOD handle_user_command.
    DATA: lt_rows TYPE lvc_t_row,
          ls_row  TYPE lvc_s_row.

    CALL METHOD go_alv->check_changed_data.

    CASE e_ucomm.
      WHEN 'ADOBE_PRINT'.

        CLEAR lt_keys.

        LOOP AT gt_alv INTO gs_alv WHERE selkz = 'X'.
          APPEND gs_alv-vbeln TO lt_keys.
        ENDLOOP.

        SORT lt_keys.
        DELETE ADJACENT DUPLICATES FROM lt_keys.

        IF lt_keys IS NOT INITIAL.
          me->get_adobeform( ).
        ELSE.
          MESSAGE 'Lütfen satır seçiniz.' TYPE 'I'.
        ENDIF.

      WHEN 'EXCELD'.
        DATA: lr_data_ref TYPE REF TO data.

        IF  me->gv_rb = '1'.

          GET REFERENCE OF gt_alv INTO lr_data_ref.

          me->get_excell(
         EXPORTING
          it_data     = lr_data_ref " importinge gönder,Metodun içine veri gönderiyorum
          it_fcat     = gt_fcat ).

        ELSE.

          GET REFERENCE OF gt_alvv INTO lr_data_ref.

          me->get_excell(
          EXPORTING
           it_data     = lr_data_ref " importinge gönder,Metodun içine veri gönderiyorum
           it_fcat     = gt_fcatt
        ).

        ENDIF.

    ENDCASE.
  ENDMETHOD.

  METHOD start.
    " Metodu EXCEPTIONS ile çağırma
    me->get_data( EXCEPTIONS no_data_found = 1 ).

    " Dönüş değerine (sy-subrc) göre karar
    IF sy-subrc = 0.
      IF me->gv_rb = '1'.

      ENDIF.
      me->set_fcat( ).
      me->set_layout( ).

    ELSEIF sy-subrc = 1.
      MESSAGE 'Veri bulunamadı.' TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.
  ENDMETHOD.

  METHOD get_data.
    IF me->gv_rb = '1'.
      SELECT v~vbeln,
               va~posnr,
               va~kdmat,
               va~matnr,
               m~maktx,
               k~kunnr,
               va~kwmeng,
               p~kbetr,
               va~meins,
               va~netwr,
               va~waerk,
               p~waers,
               v~vkorg
            FROM vbak AS v
            INNER JOIN vbap AS va ON v~vbeln = va~vbeln
            LEFT JOIN makt AS m ON m~matnr = va~matnr
                                AND m~spras = @sy-langu
            LEFT JOIN kna1 AS k ON v~kunnr = k~kunnr
            LEFT JOIN prcd_elements AS p ON p~knumv = v~knumv
                                         AND kschl EQ 'ZF01'
            INTO CORRESPONDING FIELDS OF TABLE @gt_alv.


      " Veri bulunamadıysa hata fırlatma
      IF sy-subrc <> 0.
        RAISE no_data_found.
      ENDIF.

      SORT gt_alv BY vbeln DESCENDING posnr ASCENDING.

      DATA: lv_current_color TYPE char4 VALUE 'C710',
            lv_last_vbeln    TYPE vbeln.

      LOOP AT gt_alv ASSIGNING <gfs_alv>." Tablo satırını <gfs_scarr>'e bağlar

        IF lv_last_vbeln IS NOT INITIAL AND lv_last_vbeln <> <gfs_alv>-vbeln.
          IF lv_current_color = 'C710'.
            lv_current_color = 'C300'.
          ELSE.
            lv_current_color = 'C710'.
          ENDIF.
        ENDIF.
*
        <gfs_alv>-line_color = lv_current_color.
        lv_last_vbeln = <gfs_alv>-vbeln.

      ENDLOOP.
    ELSE.
      SELECT e~ebeln,
               ep~ebelp
            FROM ekko AS e
            INNER JOIN ekpo AS ep ON e~ebeln = ep~ebeln
            INTO CORRESPONDING FIELDS OF TABLE @gt_alvv.
    ENDIF.

  ENDMETHOD.

  METHOD set_fcat.
    IF me->gv_rb = '1'.
      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name   = 'ZGZ_RALV_02'
          i_bypassing_buffer = 'X'
        CHANGING
          ct_fieldcat        = gt_fcat.

      LOOP AT gt_fcat ASSIGNING <gfs_fc>.
        IF <gfs_fc>-fieldname = 'VKORG' OR <gfs_fc>-fieldname = 'WAERS'.
          <gfs_fc>-no_out = 'X'.
          "<gfs_fc>-mark       = abap_true.
        ELSEIF <gfs_fc>-fieldname = 'SELKZ'.
          <gfs_fc>-key = <gfs_fc>-checkbox = <gfs_fc>-edit = abap_true.
*           <gfs_fc>-tech = 'X'.
        ELSEIF <gfs_fc>-fieldname = 'LINE_COLOR'.
          <gfs_fc>-no_out = 'X'.
*
        ELSEIF <gfs_fc>-fieldname = 'MEINS'.
          <gfs_fc>-convexit  = ''.
          <gfs_fc>-ref_table = ''.
          <gfs_fc>-ref_field = ''.
          <gfs_fc>-scrtext_s = 'ÖB'.
          <gfs_fc>-scrtext_m = 'Ölçü B'.
          <gfs_fc>-scrtext_l = 'Ölçü Birimi'.
        ENDIF.
      ENDLOOP.

    ELSE.
      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING
*         I_BUFFER_ACTIVE        =
          i_structure_name       = 'ZGZ_EKPO'
*         I_CLIENT_NEVER_DISPLAY = 'X'
          i_bypassing_buffer     = 'X'
*         I_INTERNAL_TABNAME     =
        CHANGING
          ct_fieldcat            = gt_fcatt
        EXCEPTIONS
          inconsistent_interface = 1
          program_error          = 2
          OTHERS                 = 3.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD set_layout.
    gs_layout-cwidth_opt = gs_layout-zebra = abap_true.
    gs_layout-info_fname = 'LINE_COLOR'.
    gs_layout-sel_mode   = 'A'.
  ENDMETHOD.

  METHOD display_alv.
    IF go_alv IS INITIAL.
      CREATE OBJECT go_cont
        EXPORTING
          repid                       = sy-repid
          dynnr                       = sy-dynnr
          side                        = cl_gui_docking_container=>dock_at_bottom
          ratio                       = 95
        EXCEPTIONS
          cntl_error                  = 1                " Invalid Parent Control
          cntl_system_error           = 2                " System Error
          create_error                = 3                " Create Error
          lifetime_error              = 4                " Lifetime Error
          lifetime_dynpro_dynpro_link = 5                " LIFETIME_DYNPRO_DYNPRO_LINK
          OTHERS                      = 6.

      CREATE OBJECT go_alv
        EXPORTING
          i_parent = go_cont.

      SET HANDLER go_controller->handle_toolbar FOR go_alv.
      SET HANDLER go_controller->handle_user_command FOR go_alv.

      gs_variant-report = sy-repid.

      IF me->gv_rb = '1'.
        go_alv->set_table_for_first_display(
                EXPORTING
                  is_variant = gs_variant
                  i_save     = 'A'
                  is_layout  = gs_layout
                CHANGING
                  it_outtab       = gt_alv
                  it_fieldcatalog = gt_fcat ).
      ELSE.
        go_alv->set_table_for_first_display(
             EXPORTING
               is_variant = gs_variant
               i_save     = 'A'
               is_layout  = gs_layout
             CHANGING
               it_outtab       = gt_alvv
               it_fieldcatalog = gt_fcatt ).
      ENDIF.

    ELSE.
      go_alv->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_adobeform.
    me->get_header( ).

    CLEAR gs_outputparams.

    gs_outputparams-nodialog = abap_true.  " Yazıcı seçimi sorma
    gs_outputparams-preview  = abap_true.  " önizleme aç
    " gs_outputparams-dest   = 'LP01'.

    CALL FUNCTION 'FP_JOB_OPEN'
      CHANGING
        ie_outputparams = gs_outputparams
      EXCEPTIONS
        cancel          = 1
        usage_error     = 2
        system_error    = 3
        internal_error  = 4
        OTHERS          = 5.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    " Fonksiyon Adı
    CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
      EXPORTING
        i_name     = 'ZGZ_F_SIPARIS'
      IMPORTING
        e_funcname = gv_funcname.
*     E_INTERFACE_TYPE           =
*     EV_FUNCNAME_INBOUND        =

    LOOP AT lt_keys INTO DATA(ls_key).
      CLEAR: gs_header, gt_sf ,gs_toplam.

      " Başlık
      READ TABLE gt_header INTO gs_header WITH KEY vbeln = ls_key.

      LOOP AT gt_alv INTO DATA(ls_all) WHERE vbeln = ls_key.

        gs_toplam-toplam_netwr = gs_toplam-toplam_netwr + ls_all-netwr.

        MOVE-CORRESPONDING ls_all TO gs_sf.
        APPEND gs_sf TO gt_sf.
      ENDLOOP.

      gs_header-toplam_netwr = gs_toplam-toplam_netwr.
      gs_docparams-dynamic = abap_true.


      CALL FUNCTION gv_funcname
        EXPORTING
          /1bcdwb/docparams = gs_docparams
          is_header         = gs_header
          it_items          = gt_sf
* IMPORTING
*         /1BCDWB/FORMOUTPUT       =
        EXCEPTIONS
          usage_error       = 1
          system_error      = 2
          internal_error    = 3
          OTHERS            = 4.
      IF sy-subrc <> 0.
* Implement suitable error handling here
      ENDIF.

    ENDLOOP.

    CALL FUNCTION 'FP_JOB_CLOSE'
*   IMPORTING
*     E_RESULT             =
      EXCEPTIONS
        usage_error    = 1
        system_error   = 2
        internal_error = 3
        OTHERS         = 4.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
  ENDMETHOD.

  METHOD get_header.
    CLEAR: gt_header,gs_header.

    SELECT v~bstnk,
               v~bstdk,
               v~vkorg,
               k~name1,
               k~name2,
               a~name1,
               a~name2,
               a~street,
               a~location,
               a~city2,
               a~city1,
               tt~bezei,
               v~vbeln,
               tt~land1,
               v~vdatu
          FROM vbak AS v
          INNER JOIN kna1 AS k ON k~kunnr = v~kunnr
          INNER JOIN tvko AS t ON t~vkorg = v~vkorg
          INNER JOIN adrc AS a ON a~addrnumber = t~adrnr
          INNER JOIN t005u AS tt ON tt~spras = @sy-langu
                                AND tt~land1 = a~country
                                AND tt~bland = a~region
          FOR ALL ENTRIES IN @lt_keys
          WHERE v~vbeln = @lt_keys-table_line
          INTO CORRESPONDING FIELDS OF TABLE @gt_header.
  ENDMETHOD.

  METHOD get_xstring.
    DATA: lt_fcat_exp TYPE lvc_t_fcat.
    lt_fcat_exp = it_fcat.

    DELETE lt_fcat_exp WHERE fieldname = 'SELKZ'.
    DELETE lt_fcat_exp WHERE fieldname = 'LINE_COLOR'.

    DATA(lo_result) = cl_salv_ex_util=>factory_result_data_table(
      r_data         = it_data
      t_fieldcatalog = lt_fcat_exp ).

    cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform(
      EXPORTING
        r_result_data = lo_result
        xml_type      = if_salv_bs_xml=>c_type_xlsx
      IMPORTING
        xml           = ev_xstring ).
  ENDMETHOD.


  METHOD read_xstring.
    DATA: lt_bin_tab TYPE solix_tab,
          lv_length  TYPE i.

    cl_gui_frontend_services=>gui_upload(
      EXPORTING
        filename   = iv_filename
        filetype   = 'BIN'
      IMPORTING
        filelength = lv_length
      CHANGING
        data_tab   = lt_bin_tab ).

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_length
      IMPORTING
        buffer       = ev_xstring
      TABLES
        binary_tab   = lt_bin_tab.
  ENDMETHOD.

  METHOD get_excell.
    DATA: lv_xstring TYPE xstring,
          lt_solix   TYPE solix_tab.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        window_title      = 'Excel'
        file_filter       = 'Excel Dosyası (*.xlsx)|*.xlsx'
      CHANGING
        filename          = gv_filename     " changing
        path              = gv_path
        fullpath          = gv_fullpath    " exporting
        user_action       = gv_user_action ).

    CHECK gv_user_action = cl_gui_frontend_services=>action_ok.

    me->get_xstring(
    EXPORTING
      it_data    = it_data
      it_fcat    = it_fcat
    IMPORTING
      ev_xstring = lv_xstring ).

    " Binary
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = lv_xstring
      IMPORTING
        output_length = ev_file_size " exporting
      TABLES
        binary_tab    = lt_solix.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        bin_filesize = ev_file_size
        filename     = gv_fullpath
        filetype     = 'BIN'
      TABLES
        data_tab     = lt_solix
      EXCEPTIONS
        OTHERS       = 1.

  ENDMETHOD.

  METHOD excel_upload_cl.
    " Dosya adı dışarıdan geldiyse dialog açma
    IF gv_filename IS INITIAL.
      DATA: lt_files TYPE filetable,
            lv_rc    TYPE i.

      cl_gui_frontend_services=>file_open_dialog(
        EXPORTING
          window_title      = 'Excel Seç'
          default_extension = 'xlsx'
          file_filter       = 'Excel Files (*.xlsx)|*.xlsx'
        CHANGING
          file_table        = lt_files
          rc                = lv_rc ).

      IF sy-subrc <> 0 OR lv_rc <> 1.
        MESSAGE 'Dosya seçilmedi.' TYPE 'W'.
        RETURN.
      ENDIF.

      gv_filename = lt_files[ 1 ]-filename.
    ENDIF.

    " Dosyayı Binary (XSTRING) olarak oku
    DATA: lv_bin_data TYPE xstring.

    me->read_xstring(
     EXPORTING
       iv_filename = gv_filename
     IMPORTING
       ev_xstring  = lv_bin_data ).

    " Excel Motorunu Çalıştır (Nesne Oluşturma) Burası 'NEW' yerine statik metot
    DATA(lo_excel) = NEW cl_fdt_xl_spreadsheet(
      document_name = 'test.xlsx'
      xdocument     =  lv_bin_data
*      mime_type     =
    ).

    " Sayfa (Sheet) isimlerini al (Genelde ilk sayfayı okuruz veriyi IMPORTING ile alıyoruz
    lo_excel->if_fdt_doc_spreadsheet~get_worksheet_names(
      IMPORTING
        worksheet_names = DATA(lt_sheets)
    ).

    " İlk sayfayı çekiyoruz
    IF lt_sheets IS NOT INITIAL.
      DATA(lo_data_ref) = lo_excel->if_fdt_doc_spreadsheet~get_itab_from_worksheet(
                            worksheet_name  = lt_sheets[ 1 ]
*                            iv_caller       =
*                            iv_get_language =
  ).
    ENDIF.

    " Veriyi serbest bırak
    ASSIGN lo_data_ref->* TO FIELD-SYMBOL(<lt_excel_data>).

    CLEAR: gt_alv , gt_alvv.

    DATA: lv_target_idx TYPE i.


    LOOP AT <lt_excel_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
      " Her kolonu dinamik olarak ls_alv içine
      IF sy-tabix = 1.
        CONTINUE.
      ENDIF.

      CLEAR: gs_alv , gs_alvv.

      DO.

        ASSIGN COMPONENT sy-index OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<fs_excel_cell>).
        IF sy-subrc <> 0. EXIT. ENDIF. " Satırdaki kolonlar bittiyse

        IF me->gv_rb = '1'.
          lv_target_idx = sy-index + 1.  "SELKZ'yi atla
          ASSIGN COMPONENT lv_target_idx OF STRUCTURE gs_alv TO FIELD-SYMBOL(<fs_target>).
        ELSE.
          ASSIGN COMPONENT sy-index OF STRUCTURE gs_alvv TO <fs_target>.  "offset yok
        ENDIF.
        " Hedef tablodaki kolonlar bittiyse çık

        IF <fs_excel_cell> IS ASSIGNED.
          "veri doğrudan burada
          DATA(lv_value) = CONV string( <fs_excel_cell> ).
        ELSE.
          lv_value = ''.
        ENDIF.

        TRY.
            <fs_target> = lv_value.
          CATCH cx_root.
            CONTINUE.
        ENDTRY.
      ENDDO.

      IF me->gv_rb = '1'.
        APPEND gs_alv TO gt_alv.
      ELSE.
        APPEND gs_alvv TO gt_alvv.
      ENDIF.

    ENDLOOP.

    IF go_alv IS NOT INITIAL.
      go_alv->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.



  METHOD send_mail.
    DATA: lt_mail_text   TYPE bcsy_text,
          lv_xml_xstring TYPE xstring,
          lt_excel_solix TYPE solix_tab,
          lv_excel_size  TYPE so_obj_len,
          lr_data_ref    TYPE REF TO data.

    " Mail gövdesi
    lt_mail_text = VALUE #(
      ( line = 'Sayın İlgili,' )
      ( line = '' )
      ( line = 'Rapor ekte sunulmuştur.' )
      ( line = '' )
      ( line = 'İyi çalışmalar.' ) ).

    TRY.
        " Tüm ALV verisini al
        GET REFERENCE OF gt_alv INTO lr_data_ref.

        " Excel oluştur
        DATA(lo_result) = cl_salv_ex_util=>factory_result_data_table(
          r_data         = lr_data_ref
          t_fieldcatalog = gt_fcat ).

        cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform(
          EXPORTING
            r_result_data = lo_result
            xml_type      = if_salv_bs_xml=>c_type_xlsx
          IMPORTING
            xml           = lv_xml_xstring ).

        " Binary çevir
        lt_excel_solix = cl_bcs_convert=>xstring_to_solix(
          iv_xstring = lv_xml_xstring ).
        lv_excel_size = xstrlen( lv_xml_xstring ).

        " Mail oluştur
        DATA(lo_request) = cl_bcs=>create_persistent( ).
        DATA(lo_doc) = cl_document_bcs=>create_document(
          i_type    = 'RAW'
          i_subject = iv_subject
          i_text    = lt_mail_text ).

        " Excel ekle
        lo_doc->add_attachment(
          i_attachment_type    = 'BIN'
          i_attachment_subject = 'Rapor.xlsx'
          i_attachment_size    = lv_excel_size
          i_att_content_hex    = lt_excel_solix ).

        " Gönder
        lo_request->set_document( lo_doc ).
        lo_request->add_recipient(
          i_recipient = cl_cam_address_bcs=>create_internet_address( iv_receiver ) ).
        lo_request->set_send_immediately( 'X' ).

        DATA(lv_result) = lo_request->send( i_with_error_screen = 'X' ).

        IF lv_result = abap_true.
          COMMIT WORK AND WAIT.
          MESSAGE 'Mail gönderildi.' TYPE 'S'.
        ELSE.
          MESSAGE 'Mail gönderilemedi.' TYPE 'S' DISPLAY LIKE 'E'.
        ENDIF.

      CATCH cx_bcs INTO DATA(lx_bcs).
        MESSAGE lx_bcs->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
