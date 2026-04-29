CLASS lcl_controller IMPLEMENTATION.
  METHOD create_instance.
    IF mo_instance IS INITIAL.
      mo_instance = NEW lcl_controller( ).
    ENDIF.
    r_obj = mo_instance.
  ENDMETHOD.

  METHOD initialization.
    " Radio buton ikonları ve açıklamaları
    ic1    = '@04@'.
    txt_r1 = 'Satış Siparişi (VBAK)'.
    ic2    = '@05@'.
    txt_r2 = 'Satınalma Siparişi (EKPO)'.

    " Dosya alanı
    txt_file = 'Dosya adı:'.

    gv_btn1 = 'Şablon indir'.
*  gv_btn2 = 'Şablon yükle'.

    " sscrfields-functxt_01 ifadesi SELECTION-SCREEN FUNCTION KEY 1'e denk gelir.
    sscrfields-functxt_01 = VALUE smp_dyntxt(
                              text      = 'Şablon İndir'
                              icon_id   = '@30@' " Excel/Dosya ikonu
                              quickinfo = 'Şablon İndir' ).
  ENDMETHOD.

  METHOD at_selection_screen_valreq.
    DATA: lv_rc    TYPE i,
          lt_files TYPE filetable.

    cl_gui_frontend_services=>file_open_dialog(
   EXPORTING
     window_title      = 'Excel Seç'
     default_extension = 'xlsx'
     file_filter       = 'Excel Files (*.xlsx)|*.xlsx'
   CHANGING
     file_table        = lt_files
     rc                = lv_rc ).

    IF lv_rc = 1.
      p_file = lt_files[ 1 ]-filename.
    ENDIF.
  ENDMETHOD.

  METHOD at_selection_screen.
    IF rb_1 = 'X'.
      go_controller->gv_rb = '1'.
    ELSE.
      go_controller->gv_rb = '2'.
    ENDIF.

    " dosya uzantı kontrolü
    IF p_file IS NOT INITIAL.
      IF p_file NS '.xlsx' AND p_file NS '.XLSX'. "Bir metnin içinde, belirtilen başka bir metin parçasının bulunmadığını kontrol eder.
        MESSAGE 'Lütfen .xlsx formatında dosya yükleyiniz.' TYPE 'E'.
      ENDIF.
    ENDIF.

    CASE sscrfields-ucomm.

      WHEN 'FC01' OR 'SABLOND'.
        DATA: bos_table     TYPE TABLE OF vbak,
              lv_boyut      TYPE i,
              lr_header_ref TYPE REF TO data.

        GET REFERENCE OF bos_table INTO lr_header_ref.

        go_controller->set_fcat( ).

        IF  go_controller->gv_rb = '1'.
          go_controller->get_excell(
          EXPORTING
           it_data     = lr_header_ref " importinge gönder,Metodun içine veri gönderiyorum
           it_fcat     = gt_fcat
          IMPORTING
            ev_file_size    = lv_boyut
        ).
        ELSE.
          go_controller->get_excell(
          EXPORTING
           it_data     = lr_header_ref " importinge gönder,Metodun içine veri gönderiyorum
           it_fcat     = gt_fcatt
          IMPORTING
            ev_file_size    = lv_boyut
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

  METHOD pbo.

  ENDMETHOD.

  METHOD pai.

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
    DATA: ls_formoutput TYPE fpformoutput,
          lt_pdfs       TYPE tty_pdfs.

    me->get_header( ).

    CLEAR gs_outputparams.

    IF iv_mail = abap_true.
      gs_outputparams-getpdf = abap_true.
    ENDIF. "PDF'i bir değişkenin içine "hapsetmek" ve sonra o değişkeni maile eklemek


    gs_outputparams-nodialog = abap_true.  " Yazıcı seçimi sorma
    gs_outputparams-dest   = 'LP01'.

    "maile giderken preview olmasn
    IF iv_mail = abap_true.
      gs_outputparams-preview = abap_false.
    ELSE.
      gs_outputparams-preview = abap_true.
    ENDIF.

    CALL FUNCTION 'FP_JOB_OPEN'
      CHANGING
        ie_outputparams = gs_outputparams
      EXCEPTIONS
        cancel          = 1
        usage_error     = 2
        system_error    = 3
        internal_error  = 4
        OTHERS          = 5.

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
          /1bcdwb/docparams  = gs_docparams
          is_header          = gs_header
          it_items           = gt_sf
        IMPORTING
          /1bcdwb/formoutput = ls_formoutput
        EXCEPTIONS
          usage_error        = 1
          system_error       = 2
          internal_error     = 3
          OTHERS             = 4.

      " Her belgenin PDF'ini sakla
      APPEND ls_formoutput-pdf TO lt_pdfs.
    ENDLOOP.

    CALL FUNCTION 'FP_JOB_CLOSE'
*   IMPORTING
*     E_RESULT             =
      EXCEPTIONS
        usage_error    = 1
        system_error   = 2
        internal_error = 3
        OTHERS         = 4.

    " Mail modu ise gönder
    IF iv_mail = abap_true AND lt_pdfs IS NOT INITIAL.
      me->send_mail_pdf(
        iv_subject = iv_subject
        iv_receiver = iv_receiver
        it_pdfs = lt_pdfs ).
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

    IF lt_bin_tab IS INITIAL.
      RETURN.
    ENDIF.
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

  METHOD validate_excel.
    "dönecek değer
    rv_valid = abap_false.

    "gelen değer okunuyor mu kontrolü
    FIELD-SYMBOLS: <lt_data> TYPE ANY TABLE,
                   <ls_row>  TYPE any.

    ASSIGN it_excel_data->* TO <lt_data>.

    IF <lt_data> IS NOT ASSIGNED.
      MESSAGE 'Excel verisi okunamadı.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN. "methoddan çık
    ENDIF.

    " satır sayısı kontrolü
    DATA(lv_lines) = lines( <lt_data> ).

    IF lv_lines < 2.
      MESSAGE 'Excel boş veya sadece başlık satırı var.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.


    " Başlık satırı
    LOOP AT <lt_data> ASSIGNING <ls_row>.
      EXIT. " İlk satırı al ve çık
    ENDLOOP.
    " Sütun sayısı kontrolü
    DATA: lv_excel_cols TYPE i,
          lv_expected   TYPE i.

    DO. "belirli bir sayı sınırı koymadan sonsuz bir döngü
      ASSIGN COMPONENT sy-index OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<fs_col>).

      IF sy-subrc <> 0. "o satırda artık bir sütun bulunmadı
        EXIT.
      ENDIF.

      lv_excel_cols = sy-index.

      UNASSIGN <fs_col>. "temiz başlangıç
    ENDDO.

    " Beklenen sütun sayısı
    IF me->gv_rb = '1'.
      lv_expected = 11.
    ELSE.
      lv_expected = 2.
    ENDIF.

    IF lv_excel_cols <> lv_expected.
      MESSAGE |Sütun sayısı uyumsuz. Beklenen: { lv_expected }, Gelen: { lv_excel_cols }|
        TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    rv_valid = abap_true.
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

    IF lv_bin_data IS INITIAL.
      RETURN.
    ENDIF.

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

    " Doğrulama
    IF me->validate_excel( it_excel_data = lo_data_ref ) = abap_false.
      RETURN.
    ENDIF.


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
          lv_xstring     TYPE xstring,
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
        " get_xstring metodu
        IF me->gv_rb = '1'.
          GET REFERENCE OF gt_alv INTO lr_data_ref.

          me->get_xstring(
            EXPORTING
              it_data    = lr_data_ref
              it_fcat    = gt_fcat
            IMPORTING
              ev_xstring = lv_xstring ).
        ELSE.
          GET REFERENCE OF gt_alvv INTO lr_data_ref.

          me->get_xstring(
            EXPORTING
              it_data    = lr_data_ref
              it_fcat    = gt_fcatt
            IMPORTING
              ev_xstring = lv_xstring ).
        ENDIF.

        IF lv_xstring IS INITIAL.
          MESSAGE 'Excel oluşturulamadı.' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        " Mail için SOLIX
        lt_excel_solix = cl_bcs_convert=>xstring_to_solix( iv_xstring = lv_xstring ).

        "SAP'nin e-posta sınıfları (BCS) bizden dosyanın boyutunu bildirmemizi ister
        lv_excel_size = xstrlen( lv_xstring ).

        " Mail oluştur
        DATA(lo_request) = cl_bcs=>create_persistent( ).
        DATA(lo_doc) = cl_document_bcs=>create_document(
                         i_type          =  'RAW'       " Code for Document Class
                         i_subject       =  iv_subject  " Short Description of Contents
                         i_text          =  lt_mail_text" Content (Text-Like)
                       ).

        " Excel ekle
        lo_doc->add_attachment(
          i_attachment_type     =  'BIN'            " Document Class for Attachment
          i_attachment_subject  =  'Rapor.xlsx'     " Attachment Title
          i_attachment_size     =  lv_excel_size    " Size of Document Content
          i_att_content_hex     =  lt_excel_solix   " Content (Binary)
        ).
        "CATCH cx_document_bcs. " BCS: Document Exceptions

        " Gönder
        lo_request->set_document( lo_doc ).
*
        " POP UPTAN GELEN
        LOOP AT gt_mail INTO gs_mail WHERE cc = 'X'.
          DATA(lo_recipient) = cl_cam_address_bcs=>create_internet_address( gs_mail-smtp_addr ).

          IF gs_mail-cc = 'X'.
            lo_request->add_recipient(
              i_recipient = lo_recipient
              i_copy      = abap_true ).
          ELSE.
            lo_request->add_recipient(
              i_recipient = lo_recipient ).
          ENDIF.
        ENDLOOP.

        IF sy-subrc <> 0.
          MESSAGE 'Alıcı seçilmedi.' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        lo_request->set_send_immediately( i_send_immediately = ' ' ).

        "Hazırladığımız e-posta paketini gönderim sırasına sokar.
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

  METHOD build_html_table.
    DATA: lv_color TYPE string,
          lv_idx   TYPE i VALUE 0.

    rv_html = '<html><head><meta charset="UTF-8"></head><body>'.
    rv_html = rv_html && '<p>Sayın İlgili,</p>'.
    rv_html = rv_html && '<p>Rapor aşağıdadır.</p>'.

    " Tablo başlangıcı
    rv_html = rv_html && '<table border="1" cellpadding="5" cellspacing="0" '
                      && 'style="border-collapse:collapse; font-family:Arial; font-size:12px;">'.

    " Başlık satırı
    rv_html = rv_html && '<tr style="background-color:#4472C4; color:white; font-weight:bold;">'.

    IF me->gv_rb = '1'.
      rv_html = rv_html && '<td>SD Belgesi</td>'.
      rv_html = rv_html && '<td>Kalem</td>'.
      rv_html = rv_html && '<td>Müşteri Malzemesi</td>'.
      rv_html = rv_html && '<td>Malzeme</td>'.
      rv_html = rv_html && '<td>Tanım</td>'.
      rv_html = rv_html && '<td>Müşteri</td>'.
      rv_html = rv_html && '<td>Miktar</td>'.
      rv_html = rv_html && '<td>Tutar</td>'.
      rv_html = rv_html && '<td>Birim</td>'.
      rv_html = rv_html && '<td>Net Değer</td>'.
      rv_html = rv_html && '<td>PB</td>'.
      rv_html = rv_html && '</tr>'.

      LOOP AT gt_alv INTO gs_alv.
        lv_idx = lv_idx + 1.
        IF lv_idx MOD 2 = 0.
          lv_color = 'background-color:#D9E2F3;'.
        ELSE.
          lv_color = ''.
        ENDIF.

        rv_html = rv_html && |<tr style="{ lv_color }">|.
        rv_html = rv_html && |<td>{ gs_alv-vbeln }</td>|.
        rv_html = rv_html && |<td>{ gs_alv-posnr }</td>|.
        rv_html = rv_html && |<td>{ gs_alv-kdmat }</td>|.
        rv_html = rv_html && |<td>{ gs_alv-matnr }</td>|.
        rv_html = rv_html && |<td>{ gs_alv-maktx }</td>|.
        rv_html = rv_html && |<td>{ gs_alv-kunnr }</td>|.
        rv_html = rv_html && |<td>{ gs_alv-kwmeng }</td>|.
        rv_html = rv_html && |<td>{ gs_alv-kbetr }</td>|.
        rv_html = rv_html && |<td>{ gs_alv-meins }</td>|.
        rv_html = rv_html && |<td>{ gs_alv-netwr }</td>|.
        rv_html = rv_html && |<td>{ gs_alv-waerk }</td>|.
        rv_html = rv_html && '</tr>'.
      ENDLOOP.

    ELSE.
      rv_html = rv_html && '<td>Satınalma Belgesi</td>'.
      rv_html = rv_html && '<td>Kalem</td>'.
      rv_html = rv_html && '</tr>'.

      LOOP AT gt_alvv INTO gs_alvv.
        lv_idx = lv_idx + 1.
        IF lv_idx MOD 2 = 0.
          lv_color = 'background-color:#D9E2F3;'.
        ELSE.
          lv_color = ''.
        ENDIF.

        rv_html = rv_html && |<tr style="{ lv_color }">|.
        rv_html = rv_html && |<td>{ gs_alvv-ebeln }</td>|.
        rv_html = rv_html && |<td>{ gs_alvv-ebelp }</td>|.
        rv_html = rv_html && '</tr>'.
      ENDLOOP.
    ENDIF.

    rv_html = rv_html && '</table>'.
    rv_html = rv_html && '<p>İyi çalışmalar.</p>'.
    rv_html = rv_html && '</body></html>'.
  ENDMETHOD.

  METHOD send_mail_html.
    TRY.
        " HTML tabloyu oluştur
        DATA(lv_html) = me->build_html_table( ).

        " HTML'i SOLIX'e çevir
        DATA(lv_xstring) = cl_bcs_convert=>string_to_xstring( lv_html ).
        DATA(lt_solix) = cl_bcs_convert=>xstring_to_solix( iv_xstring = lv_xstring ).
        DATA(lv_size) = CONV so_obj_len( xstrlen( lv_xstring ) ).

        " Mail oluştur
        DATA(lo_request) = cl_bcs=>create_persistent( ).
        DATA(lo_doc) = cl_document_bcs=>create_document(
          i_type    = 'HTM'
          i_subject = iv_subject
          i_hex     = lt_solix
          i_length  = lv_size ).

        lo_request->set_document( lo_doc ).
        lo_request->add_recipient(
          i_recipient = cl_cam_address_bcs=>create_internet_address( iv_receiver ) ).
        lo_request->set_send_immediately( ' ' ).

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

  METHOD send_mail_pdf.
    DATA: lt_mail_text TYPE bcsy_text,
          lv_count     TYPE i.

    lt_mail_text = VALUE #(
      ( line = 'Sayın İlgili,' )
      ( line = '' )
      ( line = 'Rapor ekte PDF olarak sunulmuştur.' )
      ( line = '' )
      ( line = 'İyi çalışmalar.' ) ).

    TRY.
        DATA(lo_request) = cl_bcs=>create_persistent( ).
        DATA(lo_doc) = cl_document_bcs=>create_document(
          i_type    = 'RAW'
          i_subject = iv_subject
          i_text    = lt_mail_text ).

        " Her PDF'i ayrı attachment olarak ekleme
        LOOP AT it_pdfs INTO DATA(lv_pdf).
          lv_count += 1.
          DATA(lt_solix) = cl_bcs_convert=>xstring_to_solix( iv_xstring = lv_pdf ).
          DATA(lv_size)  = CONV so_obj_len( xstrlen( lv_pdf ) ).

          lo_doc->add_attachment(
            i_attachment_type    = 'PDF'
            i_attachment_subject = |Rapor_{ lv_count }.pdf|
            i_attachment_size    = lv_size
            i_att_content_hex    = lt_solix ).
        ENDLOOP.

        lo_request->set_document( lo_doc ).
        lo_request->add_recipient(
        i_recipient = cl_cam_address_bcs=>create_internet_address( iv_receiver ) ).
        lo_request->set_send_immediately( ' ' ).

        DATA(lv_result) = lo_request->send( i_with_error_screen = 'X' ).

        IF lv_result = abap_true.
          COMMIT WORK AND WAIT.
          MESSAGE |{ lv_count } adet PDF mail gönderildi.| TYPE 'S'.
        ELSE.
          MESSAGE 'Mail gönderilemedi.' TYPE 'S' DISPLAY LIKE 'E'.
        ENDIF.

      CATCH cx_bcs INTO DATA(lx_bcs).
        MESSAGE lx_bcs->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD get_excel_abap2xlsx.
    DATA: lt_solix TYPE solix_tab,
          lv_size  TYPE i.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        window_title = 'Excel (abap2xlsx)'
        file_filter  = 'Excel Dosyası (*.xlsx)|*.xlsx'
      CHANGING
        filename    = gv_filename
        path        = gv_path
        fullpath    = gv_fullpath
        user_action = gv_user_action ).

    CHECK gv_user_action = cl_gui_frontend_services=>action_ok.

    DATA(lo_excel)     = NEW zcl_excel( ). "Boş bir Excel çalışma kitabı (Workbook)
    DATA(lo_worksheet) = lo_excel->get_active_worksheet( ). "Kitabın içindeki ilk boş sayfayı yakalar ve adını 'Rapor'
    lo_worksheet->set_title( 'Rapor' ).

    DATA: lv_col TYPE i,
          lv_row TYPE i VALUE 1.

    " Başlık stili
    DATA(lo_style_header) = lo_excel->add_new_style( ). "bir stil referansı
    lo_style_header->font->bold = abap_true. "
    lo_style_header->fill->filltype = zcl_excel_style_fill=>c_fill_solid. "arka planını tamamen sabit bir renk
    lo_style_header->fill->fgcolor-rgb = 'FFC7CE'. "dolgu
    lo_style_header->font->color-rgb = '9C0006'. "font color

    DATA(lv_style_guid) = lo_style_header->get_guid( ). "benzersiz bir kimlik

    " Başlık satırı
    LOOP AT it_fcat INTO DATA(ls_fcat) WHERE tech <> abap_true
                                         AND fieldname <> 'SELKZ'
                                         AND fieldname <> 'LINE_COLOR'.
      lv_col += 1.
      DATA(lv_header) = COND string( WHEN ls_fcat-coltext IS NOT INITIAL
                                      THEN ls_fcat-coltext "1.ihtimal
                                      ELSE ls_fcat-fieldname ). "2.ihtimal

      lo_worksheet->set_cell( ip_row = lv_row ip_column = lv_col ip_value = lv_header ). "verileri celle ver
      lo_worksheet->set_cell_style( ip_row = lv_row ip_column = lv_col ip_style = lv_style_guid ). "stili celle ver
    ENDLOOP.

    " Veri satırları
    FIELD-SYMBOLS: <lt_data> TYPE ANY TABLE. "Hangi yapıda olduğunu bilmediğimiz (Generic) bir tablo
    ASSIGN it_data->* TO <lt_data>.

    LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
      lv_row += 1.
      lv_col = 0. "yazmaya en baştan

      LOOP AT it_fcat INTO ls_fcat WHERE tech <> abap_true
                                     AND fieldname <> 'SELKZ'
                                     AND fieldname <> 'LINE_COLOR'. "bu sutunları dışta tut
        lv_col += 1.
        ASSIGN COMPONENT ls_fcat-fieldname OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<fs_val>). "fcatten hangi kolonun geleceği belli değil
        IF sy-subrc = 0.
          lo_worksheet->set_cell( ip_row = lv_row ip_column = lv_col ip_value = <fs_val> ). "cell doldur
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    lo_worksheet->calculate_column_widths( ). "sütun genişliklerini otomatik

    " xstring'e çevir ve indir
    DATA(lo_writer) = CAST zif_excel_writer( NEW zcl_excel_writer_2007( ) ). "writer nesnesi
    DATA(lv_xstring) = lo_writer->write_file( lo_excel ). "verilerini, stilleri ve sayfaları tek bir uzun xstring

    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = lv_xstring
      IMPORTING
        output_length = lv_size
      TABLES
        binary_tab    = lt_solix.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        bin_filesize = lv_size
        filename     = gv_fullpath
        filetype     = 'BIN'
      TABLES
        data_tab     = lt_solix
      EXCEPTIONS
        OTHERS       = 1.

    IF sy-subrc = 0.
      MESSAGE 'Excel indirildi.' TYPE 'S'.
    ENDIF.
  ENDMETHOD.

  METHOD get_excel_from_adobe.
    DATA: lt_solix TYPE solix_tab,
          lv_size  TYPE i.

    DATA: lv_mime_url  TYPE string,
          lv_logo_data TYPE xstring.

    " Seçili satır kontrolü
    IF lt_keys IS INITIAL.
      MESSAGE 'Lütfen satır seçiniz.' TYPE 'I'.
      RETURN.
    ENDIF.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        window_title = 'Adobe -> Excel'
        file_filter  = 'Excel Dosyası (*.xlsx)|*.xlsx'
      CHANGING
        filename    = gv_filename
        path        = gv_path
        fullpath    = gv_fullpath
        user_action = gv_user_action ).

    CHECK gv_user_action = cl_gui_frontend_services=>action_ok.

    " Adobe Form verilerini topla
    me->get_header( ).

    DATA(lo_excel)     = NEW zcl_excel( ). "Hafızada boş bir Excel dosyası (Workbook)
    DATA(lo_worksheet) = lo_excel->get_active_worksheet( ). "aktif olan (ilk) sayfayı
    lo_worksheet->set_title( 'Sipariş Raporu' ). "alt kısmında görünen sayfa ismini

    " Başlık stili
    DATA(lo_style_h) = lo_excel->add_new_style( ). "boş bir stil şablonu
    lo_style_h->font->bold = abap_true.
    lo_style_h->fill->filltype = zcl_excel_style_fill=>c_fill_solid.
    lo_style_h->fill->fgcolor-rgb = '92D050'.
    DATA(lv_style_h) = lo_style_h->get_guid( ). "benzersiz kimliğini al

    " Bilgi stili (kalın)
    DATA(lo_style_b) = lo_excel->add_new_style( ).
    lo_style_b->font->bold = abap_true.
    DATA(lv_style_b) = lo_style_b->get_guid( ).

    "Satırlar
    DATA: lv_row TYPE i VALUE 1.

    " Sadece ilk belgede başlık
    lo_worksheet->set_cell( ip_row = lv_row ip_column = 1 ip_value = 'ORDER CONFIRMATION' ).

    "(A1:G1)
    lo_worksheet->set_merge(
      ip_column_start = 1
      ip_column_end   = 5
      ip_row          = lv_row
      ip_row_to       = lv_row  ).

    " Büyük font ve ortalama stili
    DATA(lo_style_title) = lo_excel->add_new_style( ).
    lo_style_title->font->bold = abap_true.
    lo_style_title->font->size = 16.
    lo_style_title->alignment->horizontal = zcl_excel_style_alignment=>c_horizontal_center.
    lo_worksheet->set_cell_style( ip_row = lv_row ip_column = 1 ip_style = lo_style_title->get_guid( ) ).

    " MIME'den logo
    lv_mime_url = '/sap/public/fiks.jpg'.

    CALL METHOD cl_mime_repository_api=>get_api( )->get(
      EXPORTING
        i_url                  = lv_mime_url              " Object URL
      IMPORTING
        e_content              = lv_logo_data                  " Object Contents
      EXCEPTIONS
        parameter_missing      = 1                " Parameter missing or is initial
        error_occured          = 2                " Unspecified Error Occurred
        not_found              = 3                " Object not found
        permission_failure     = 4                " Missing Authorization
        OTHERS                 = 5
    ).

    " Logo  - MIME Repository'den
    IF lv_logo_data IS NOT INITIAL.
      DATA(lo_drawing) = lo_excel->add_new_drawing( ). ""çizim (drawing) nesnesi
      lo_drawing->set_media(
        ip_media      = lv_logo_data
        ip_media_type = 'JPG'
        ip_width      = 180
        ip_height     = 180
      ).
      lo_drawing->set_position( "nerede duracağı
        ip_from_row    = lv_row
        ip_from_col    = 'F' "sütun harfi
        ip_rowoff = 0 "offsetler
        ip_coloff = 60 ).

      lo_worksheet->add_drawing( lo_drawing ).
    ENDIF.

    lv_row += 6.

    " Sayısal alanlar için stil
    DATA(lo_style_num) = lo_excel->add_new_style( ).
    lo_style_num->number_format->format_code = '#,##0.00'.
    DATA(lv_style_num) = lo_style_num->get_guid( ).

    "kalem no için
    DATA(lo_style_kalem) = lo_excel->add_new_style( ).
    lo_style_kalem->alignment->horizontal = zcl_excel_style_alignment=>c_horizontal_right.
    DATA(lv_style_kalem) = lo_style_kalem->get_guid( ).

    LOOP AT lt_keys INTO DATA(ls_key).
      CLEAR: gs_header, gt_sf, gs_toplam.

      READ TABLE gt_header INTO gs_header WITH KEY vbeln = ls_key.

      lo_worksheet->set_cell( ip_row = lv_row ip_column = 1 ip_value = 'Purchase Order No:' ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 2 ip_value = gs_header-bstnk ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 4 ip_value = 'Prof.Invoice No:' ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 5 ip_value = gs_header-vbeln ).
      lv_row += 1.

      " Date satırı
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 1 ip_value = 'Date:' ).
      IF gs_header-bstdk IS NOT INITIAL AND gs_header-bstdk <> '00000000'.
        lo_worksheet->set_cell( ip_row = lv_row ip_column = 2
          ip_value = |{ gs_header-bstdk DATE = USER }| ).
      ENDIF.

      lo_worksheet->set_cell( ip_row = lv_row ip_column = 4 ip_value = 'Delivery Date:' ).
      IF gs_header-vdatu IS NOT INITIAL AND gs_header-vdatu <> '00000000'.
        lo_worksheet->set_cell( ip_row = lv_row ip_column = 5
          ip_value = |{ gs_header-vdatu DATE = USER }| ).
      ENDIF.

      lo_worksheet->set_cell( ip_row = lv_row ip_column = 1 ip_value = 'Müşteri Adı:' ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 2 ip_value = gs_header-name1 ).
      lv_row += 1.

      lo_worksheet->set_cell( ip_row = lv_row ip_column = 1 ip_value = 'Adres:' ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 2 ip_value = gs_header-street ).
      lv_row += 2.

      " Tablo başlıkları
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 1 ip_value = 'Kalem' ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 2 ip_value = 'Müşteri Malzemesi' ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 3 ip_value = 'Malzeme' ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 4 ip_value = 'Malzeme Kısa Metni' ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 5 ip_value = 'Sipariş Miktarı' ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 6 ip_value = 'Tutar' ).
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 7 ip_value = 'Net Değer' ).

      DO 7 TIMES.
        lo_worksheet->set_cell_style( ip_row = lv_row ip_column = sy-index ip_style = lv_style_h ).
      ENDDO.
      lv_row += 1.

      " Kalem verileri
      LOOP AT gt_alv INTO DATA(ls_all) WHERE vbeln = ls_key.
        gs_toplam-toplam_netwr += ls_all-netwr.

        lo_worksheet->set_cell( ip_row = lv_row ip_column = 1 ip_value = |{ ls_all-posnr ALPHA = OUT }| ).
        lo_worksheet->set_cell_style( ip_row = lv_row ip_column = 1 ip_style = lv_style_kalem ).
        lo_worksheet->set_cell( ip_row = lv_row ip_column = 2 ip_value = ls_all-kdmat ).
        lo_worksheet->set_cell( ip_row = lv_row ip_column = 3 ip_value = ls_all-matnr ).
        lo_worksheet->set_cell( ip_row = lv_row ip_column = 4 ip_value = ls_all-maktx ).
        "style
        lo_worksheet->set_cell( ip_row = lv_row ip_column = 5 ip_value = ls_all-kwmeng ).
        lo_worksheet->set_cell_style( ip_row = lv_row ip_column = 5 ip_style = lv_style_num ).

        lo_worksheet->set_cell( ip_row = lv_row ip_column = 6 ip_value = ls_all-kbetr ).
        lo_worksheet->set_cell_style( ip_row = lv_row ip_column = 6 ip_style = lv_style_num ).

        lo_worksheet->set_cell( ip_row = lv_row ip_column = 7 ip_value = ls_all-netwr ).
        lo_worksheet->set_cell_style( ip_row = lv_row ip_column = 7 ip_style = lv_style_num ).
        lv_row += 1.
      ENDLOOP.

      " Toplam
      lo_worksheet->set_cell( ip_row = lv_row ip_column = 6 ip_value = 'Toplam Amount:' ).
      lo_worksheet->set_cell_style( ip_row = lv_row ip_column = 6 ip_style = lv_style_b ).

      lo_worksheet->set_cell( ip_row = lv_row ip_column = 7 ip_value = gs_toplam-toplam_netwr ).
      lo_worksheet->set_cell_style( ip_row = lv_row ip_column = 7 ip_style = lv_style_num ).
      lv_row += 6.
    ENDLOOP.

    lo_worksheet->set_column_width( ip_column = 1 ip_width_fix = 20 ).
    lo_worksheet->set_column_width( ip_column = 2 ip_width_fix = 20 ).
    lo_worksheet->set_column_width( ip_column = 3 ip_width_fix = 15 ).
    lo_worksheet->set_column_width( ip_column = 4 ip_width_fix = 22 ).
    lo_worksheet->set_column_width( ip_column = 5 ip_width_fix = 18 ).
    lo_worksheet->set_column_width( ip_column = 6 ip_width_fix = 15 ).
    lo_worksheet->set_column_width( ip_column = 7 ip_width_fix = 15 ).
    "optimize büyüklük
*    lo_worksheet->calculate_column_widths( ).

    " İndir
    DATA(lo_writer) = CAST zif_excel_writer( NEW zcl_excel_writer_2007( ) ). "yazıcı nesnesini
    DATA(lv_xstring) = lo_writer->write_file( lo_excel ). "tek parça,stiller veriler vs

    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = lv_xstring
      IMPORTING
        output_length = lv_size
      TABLES
        binary_tab    = lt_solix.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        bin_filesize = lv_size
        filename     = gv_fullpath
        filetype     = 'BIN'
      TABLES
        data_tab     = lt_solix
      EXCEPTIONS
        OTHERS       = 1.

    IF sy-subrc = 0.
      MESSAGE 'Excel çıktısı indirildi.' TYPE 'S'.
    ENDIF.
  ENDMETHOD.

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


    CLEAR: ls_toolbar.

    ls_toolbar-function  = 'SEND_ML_HTML'.
    ls_toolbar-icon      = '@0T@'.
    ls_toolbar-quickinfo = 'Mail Gönder (HTML)'.

    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR: ls_toolbar.
    ls_toolbar-function  = 'SEND_ML_PDF'.
    ls_toolbar-icon      = '@0J@'.
    ls_toolbar-quickinfo = 'Mail Gönder (PDF)'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR: ls_toolbar.
    ls_toolbar-function  = 'EXCEL_CIKTI'.
    ls_toolbar-icon      = '@22@'.
    ls_toolbar-quickinfo = 'Excel Çıktı(abap2xlsx)'.
    APPEND ls_toolbar TO e_object->mt_toolbar.

    CLEAR: ls_toolbar.
    ls_toolbar-function  = 'EXCEL_ADOBE'.
    ls_toolbar-icon      = '@49@'.
    ls_toolbar-quickinfo = 'Adobe -> Excel Çıktı'.
    APPEND ls_toolbar TO e_object->mt_toolbar.
  ENDMETHOD.


  METHOD handle_user_command.
    DATA: lt_rows TYPE lvc_t_row,
          ls_row  TYPE lvc_s_row.
    DATA: lv_subject   TYPE so_obj_des.

    CALL METHOD go_alv->check_changed_data.

    CLEAR lt_keys.

    LOOP AT gt_alv INTO gs_alv WHERE selkz = 'X'.
      APPEND gs_alv-vbeln TO lt_keys.
    ENDLOOP.

    "SORT lt_keys.
    DELETE ADJACENT DUPLICATES FROM lt_keys.

    CASE e_ucomm.
      WHEN 'ADOBE_PRINT'.
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

      WHEN 'SEND_MAIL'.
        " Tablodan alıcıları oku
        SELECT smtp_addr, cc
          FROM zgz_mail_list
          INTO CORRESPONDING FIELDS OF TABLE @gt_mail.

        IF gt_mail IS INITIAL.
          MESSAGE 'Aktif alıcı bulunamadı.' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        " Hepsini seçili yap
        LOOP AT gt_mail ASSIGNING FIELD-SYMBOL(<fs_m>).
          <fs_m>-cc = 'X'.
        ENDLOOP.

        " Popup aç
        gv_mail_confirmed = abap_false.
        CALL SCREEN 0200 STARTING AT 5 5 ENDING AT 100 20. "soldan sağa

        " Onaylandıysa gönder
        IF gv_mail_confirmed = abap_true.

          lv_subject = 'Sipariş Raporu - ' && sy-datum.

          me->send_mail( iv_subject  = lv_subject ).
        ENDIF.

      WHEN 'SEND_ML_HTML'.
        DATA: lv_receiver TYPE ad_smtpadr.

        CALL FUNCTION 'POPUP_TO_GET_VALUE'
          EXPORTING
            tabname             = 'ADR6'
            fieldname           = 'SMTP_ADDR'
            titel               = 'Mail Gönder'
            valuein             = ''
          IMPORTING
*           ANSWER              =
            valueout            = lv_receiver
          EXCEPTIONS
            fieldname_not_found = 1
            OTHERS              = 2.

        lv_subject = 'Sipariş Raporu - ' && sy-datum.

        me->send_mail_html(  EXPORTING
           iv_subject = lv_subject
           iv_receiver = lv_receiver ).

      WHEN 'SEND_ML_PDF'.
        IF lt_keys IS INITIAL.
          MESSAGE 'Lütfen satır seçiniz.' TYPE 'I'.
          RETURN.
        ENDIF.

        DATA: lv_receiver_pdf TYPE ad_smtpadr.

        CALL FUNCTION 'POPUP_TO_GET_VALUE'
          EXPORTING
            tabname   = 'ADR6'
            fieldname = 'SMTP_ADDR'
            titel     = 'PDF Mail Gönder'
            valuein   = ''
          IMPORTING
            valueout  = lv_receiver_pdf
          EXCEPTIONS
            OTHERS    = 2.

        IF lv_receiver_pdf IS NOT INITIAL.
          me->get_adobeform(
            iv_mail     = abap_true
            iv_subject  = CONV #( 'Sipariş Raporu - ' && sy-datum )
            iv_receiver = lv_receiver_pdf ).
        ENDIF.

      WHEN 'EXCEL_CIKTI'.
        IF me->gv_rb = '1'.
          GET REFERENCE OF gt_alv INTO lr_data_ref.
          me->get_excel_abap2xlsx( it_data = lr_data_ref it_fcat = gt_fcat ).
        ELSE.
          GET REFERENCE OF gt_alvv INTO lr_data_ref.
          me->get_excel_abap2xlsx( it_data = lr_data_ref it_fcat = gt_fcatt ).
        ENDIF.

      WHEN 'EXCEL_ADOBE'.
        me->get_excel_from_adobe( ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
