*&---------------------------------------------------------------------*
*& Include          ZGZ_RA_FRM
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data .
  SELECT v~vbeln,
         va~posnr,
         va~kdmat,
         va~matnr,
         m~maktx,
         k~kunnr,
         va~kwmeng,
         p~kbetr,
         p~waers,
         va~netwr,
         va~waerk,
         v~vkorg
      FROM vbak AS v
      INNER JOIN vbap AS va ON v~vbeln = va~vbeln
      LEFT JOIN makt AS m ON m~matnr = va~matnr
                          AND m~spras = @sy-langu
      LEFT JOIN kna1 AS k ON v~kunnr = k~kunnr
      LEFT JOIN prcd_elements AS p ON p~knumv = v~knumv
                                   AND kschl EQ 'ZF01'
      INTO TABLE @gt_alv.

  " ALV Sıralaması
  SORT gt_alv BY vbeln DESCENDING posnr ASCENDING.

  LOOP AT gt_alv INTO DATA(gs_alv).

    CLEAR: gs_alv_display.

    MOVE-CORRESPONDING gs_alv TO gs_alv_display.

    " Eğer yeni bir VBELN
    IF lv_last_vbeln IS NOT INITIAL AND lv_last_vbeln <> gs_alv-vbeln.
      IF lv_current_color = 'C301'.
        lv_current_color = 'C410'.
      ELSE.
        lv_current_color = 'C301'.
      ENDIF.
    ENDIF.

    gs_alv_display-rowcolor = lv_current_color.
    lv_last_vbeln = gs_alv-vbeln.

    APPEND gs_alv_display TO gt_alv_display.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_fc
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_fc .
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name   = sy-repid
*     I_INTERNAL_TABNAME           =
      i_structure_name = 'ZGZ_RALV_02'
*     I_CLIENT_NEVER_DISPLAY       = 'X'
      i_inclname       = sy-repid
*     I_BYPASSING_BUFFER           =
*     I_BUFFER_ACTIVE  =
    CHANGING
      ct_fieldcat      = gt_fcat.
* EXCEPTIONS
*     INCONSISTENT_INTERFACE       = 1
*     PROGRAM_ERROR    = 2
*     OTHERS           = 3
  .
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  LOOP AT gt_fcat ASSIGNING FIELD-SYMBOL(<fs_fcat>).
    IF <fs_fcat>-fieldname = 'VKORG' OR <fs_fcat>-fieldname = 'WAERS' OR <fs_fcat>-fieldname = 'MEINS'.
      <fs_fcat>-no_out = 'X'.
    ENDIF.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout .
  gs_layout-window_titlebar = 'SATIŞ BİLGİSİ'.
  gs_layout-colwidth_optimize = abap_true.
  gs_layout-zebra = abap_true .
  gs_layout-info_fieldname    = 'ROWCOLOR'.
  gs_layout-box_fieldname = 'SELKZ'.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form status
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_status USING pt_extab TYPE slis_t_extab.
  SET PF-STATUS 'Z100' EXCLUDING pt_extab.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form USER_COMMAND
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM user_command USING p_ucomm  LIKE sy-ucomm
                        ps_selfield TYPE slis_selfield.
  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      e_grid = ref_grid.
  IF ref_grid IS BOUND.
    ref_grid->check_changed_data( ).
  ENDIF.

  IF p_ucomm = '&CKT'.
    PERFORM get_smartform.
  ELSEIF p_ucomm = '&CKTA'.
    PERFORM get_adobeform.
  ELSEIF p_ucomm = '&EXC'.
    PERFORM get_guı_download.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_gt_excel
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_guı_download .
  PERFORM get_gt_excel.

  cl_gui_frontend_services=>file_save_dialog(
   EXPORTING
     window_title              = 'Excel indirme'   " Window Title
*      default_extension         =                  " Default Extension
*      default_file_name         =                  " Default File Name
*      with_encoding             =
     file_filter               = 'Excel Dosyası (*.xlsx)|*.xlsx' " File Type Filter Table
*      initial_directory         =                  " Initial Directory
*      prompt_on_overwrite       = 'X'
   CHANGING
     filename                  = gv_filename    " File Name to Save
     path                      = gv_path        " Path to File
     fullpath                  = gv_fullpath    " Path + File Name
     user_action               = gv_user_action " User Action (C Class Const ACTION_OK, ACTION_OVERWRITE etc)
*      file_encoding             =
*    EXCEPTIONS
*      cntl_error                = 1                " Control error
*      error_no_gui              = 2                " No GUI available
*      not_supported_by_gui      = 3                " GUI does not support this
*      invalid_default_file_name = 4                " Invalid default file name
*      others                    = 5
 ).
  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*     WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CHECK gv_user_action = cl_gui_frontend_services=>action_ok. "sadece kaydete basıldıysa devam yoksa kodun geri kalanı çalışmaz

  "DATA(lt_fcat) = gt_fcat.

  CALL FUNCTION 'LVC_TRANSFER_FROM_SLIS'
    EXPORTING
      it_fieldcat_alv = gt_fcat
*     IT_SORT_ALV     =
*     IT_FILTER_ALV   =
*     IS_LAYOUT_ALV   =
    IMPORTING
      et_fieldcat_lvc = gt_fcat_lvc
*     ET_SORT_LVC     =
*     ET_FILTER_LVC   =
*     ES_LAYOUT_LVC   =
    TABLES
      it_data         = gt_excel
* EXCEPTIONS
*     IT_DATA_MISSING = 1
*     OTHERS          = 2
  .
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

 "Alternatif
 "DATA(gt_fcat_lvc) = CORRESPONDING lvc_t_fcat( gt_fcat ).

*  DATA: ls_layout TYPE lvc_s_layo.
*  ls_layout-cwidth_opt = 'X'.
*
*  ls_layout-zebra      = 'X'.
*  ls_layout-box_fname = 'A'.
*
*  READ TABLE lt_fcat_lvc ASSIGNING FIELD-SYMBOL(<fs_fcat>) WITH KEY fieldname = 'NETWR'.
*  IF sy-subrc = 0.
*    <fs_fcat>-do_sum = 'X'. " Excel'de bu sütun otomatik toplanır
*  ENDIF.

  " Excel dosyasının içeriği
  DATA(lr_xls_data) = cl_salv_ex_util=>factory_result_data_table(
*                        t_selected_rows        =                  " ALV Control: Table Rows
*                        t_selected_columns     =                  " ALV Control: Table with Rows of Type LVC_S_COL
*                        t_selected_cells       =                  " ALV control: Table with cell descriptions
                        r_data                 =  lr_data_ref               " Data table
*                        s_layout               = ls_layout                 " ALV Control: Layout Structure
                        t_fieldcatalog         =  gt_fcat_lvc           " Field Catalog for List Viewer Control
*                        t_sort                 =                  " ALV Control: Table of Sort Criteria
*                        t_filter               =                  " ALV Control: Table of Filter Conditions
*                        t_hyperlinks           =                  " ALV Control: Hyperlinks
*                        s_current_cell         =                  " ALV Control: Cell Description
*                        hyperlink_entry_column =
*                        dropdown_entry_column  =
*                        t_dropdown_values      =                  " ALV Control: Dropdown List Boxes
*                        r_top_of_list          =                  " Set and Get Design Object Content
*                        r_end_of_list          =                  " Set and Get Design Object Content
                      ).

  "XSTRING
  cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform(
    EXPORTING
*      xml_version   = if_salv_bs_xml=>version                " XML Version to be Selected
      r_result_data = lr_xls_data
      xml_type      = if_salv_bs_xml=>c_type_xlsx                                         " XML Type as SALV Constant
*      xml_flavour   = if_salv_bs_c_tt=>c_tt_xml_flavour_full
*      gui_type      =                                        " Constant
    IMPORTING
      xml           = gv_xstring
*      filename      =
*      mimetype      =
*      t_msg         =                                        " Messages
  ).

  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = gv_xstring
*     APPEND_TO_TABLE       = ' '
    IMPORTING
      output_length = gv_length
    TABLES
      binary_tab    = gt_solix.


  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      bin_filesize = gv_length
      filename     = gv_fullpath
      filetype     = 'BIN'
*     APPEND       = ' '
*     WRITE_FIELD_SEPARATOR           = ' '
*     HEADER       = '00'
*     TRUNC_TRAILING_BLANKS           = ' '
*     WRITE_LF     = 'X'
*     COL_SELECT   = ' '
*     COL_SELECT_MASK                 = ' '
*     DAT_MODE     = ' '
*     CONFIRM_OVERWRITE               = ' '
*     NO_AUTH_CHECK                   = ' '
*     CODEPAGE     = ' '
*     IGNORE_CERR  = ABAP_TRUE
*     REPLACEMENT  = '#'
*     WRITE_BOM    = ' '
*     TRUNC_TRAILING_BLANKS_EOL       = 'X'
*     WK1_N_FORMAT = ' '
*     WK1_N_SIZE   = ' '
*     WK1_T_FORMAT = ' '
*     WK1_T_SIZE   = ' '
*     WRITE_LF_AFTER_LAST_LINE        = ABAP_TRUE
*     SHOW_TRANSFER_STATUS            = ABAP_TRUE
*     VIRUS_SCAN_PROFILE              = '/SCET/GUI_DOWNLOAD'
*    IMPORTING
*     FILELENGTH   =
    TABLES
      data_tab     = gt_solix
*     FIELDNAMES   =
*    EXCEPTIONS
*     FILE_WRITE_ERROR                = 1
*     NO_BATCH     = 2
*     GUI_REFUSE_FILETRANSFER         = 3
*     INVALID_TYPE = 4
*     NO_AUTHORITY = 5
*     UNKNOWN_ERROR                   = 6
*     HEADER_NOT_ALLOWED              = 7
*     SEPARATOR_NOT_ALLOWED           = 8
*     FILESIZE_NOT_ALLOWED            = 9
*     HEADER_TOO_LONG                 = 10
*     DP_ERROR_CREATE                 = 11
*     DP_ERROR_SEND                   = 12
*     DP_ERROR_WRITE                  = 13
*     UNKNOWN_DP_ERROR                = 14
*     ACCESS_DENIED                   = 15
*     DP_OUT_OF_MEMORY                = 16
*     DISK_FULL    = 17
*     DP_TIMEOUT   = 18
*     FILE_NOT_FOUND                  = 19
*     DATAPROVIDER_EXCEPTION          = 20
*     CONTROL_FLUSH_ERROR             = 21
*     OTHERS       = 22
    .
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_excel
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_excel .
  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      window_title              = 'Excel indirme'   " Window Title
*      default_extension         =                  " Default Extension
*      default_file_name         =                  " Default File Name
*      with_encoding             =
      file_filter               = 'Excel Dosyası (*.xls)|*.xls' " File Type Filter Table
*      initial_directory         =                  " Initial Directory
*      prompt_on_overwrite       = 'X'
    CHANGING
      filename                  = gv_filename    " File Name to Save
      path                      = gv_path        " Path to File
      fullpath                  = gv_fullpath    " Path + File Name
      user_action               = gv_user_action " User Action (C Class Const ACTION_OK, ACTION_OVERWRITE etc)
*      file_encoding             =
*    EXCEPTIONS
*      cntl_error                = 1                " Control error
*      error_no_gui              = 2                " No GUI available
*      not_supported_by_gui      = 3                " GUI does not support this
*      invalid_default_file_name = 4                " Invalid default file name
*      others                    = 5
  ).
  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*     WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CHECK gv_user_action = cl_gui_frontend_services=>action_ok. "sadece kaydete basıldıysa devam yoksa kodun geri kalanı çalışmaz

  APPEND 'Satis Bel'  TO t_header.
  APPEND 'Kalem'   TO t_header.
  APPEND 'Must.Malz' TO t_header.
  APPEND 'Malzeme No' TO t_header.
  APPEND 'Malzeme Tanimi'  TO t_header.
  APPEND 'Must.No'  TO t_header.
  APPEND 'Miktar'  TO t_header.
  APPEND 'Birim Fiyat'  TO t_header.
  APPEND 'Net Deger'  TO t_header.

  PERFORM get_gt_excel.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
*     BIN_FILESIZE            =
      filename                = gv_fullpath
      filetype                = 'DAT'
*     APPEND                  = ' '
      write_field_separator   = 'X'
*     HEADER                  = '00'
*     TRUNC_TRAILING_BLANKS   = ' '
*     WRITE_LF                = 'X'
*     COL_SELECT              = ' '
*     COL_SELECT_MASK         = ' '
*     DAT_MODE                = ' '
*     CONFIRM_OVERWRITE       = ' '
*     NO_AUTH_CHECK           = ' '
      codepage                = '4110'  "Türkçe karakter desteği
*     IGNORE_CERR             = ABAP_TRUE
*     REPLACEMENT             = '#'
*     WRITE_BOM               = ' '
*     TRUNC_TRAILING_BLANKS_EOL       = 'X'
*     WK1_N_FORMAT            = ' '
*     WK1_N_SIZE              = ' '
*     WK1_T_FORMAT            = ' '
*     WK1_T_SIZE              = ' '
*     WRITE_LF_AFTER_LAST_LINE        = ABAP_TRUE
      show_transfer_status    = abap_true
*     VIRUS_SCAN_PROFILE      = '/SCET/GUI_DOWNLOAD'
* IMPORTING
*     FILELENGTH              =
    TABLES
      data_tab                = gt_excel
      fieldnames              = t_header
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      OTHERS                  = 22.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_gt_excel
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_gt_excel .
  REFRESH gt_excel.
  LOOP AT gt_alv_display INTO DATA(ls_alv).
    CLEAR gs_excel.
    MOVE-CORRESPONDING ls_alv TO gs_excel.
    APPEND gs_excel TO gt_excel.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK        = ' '
*     I_BYPASSING_BUFFER       = ' '
*     I_BUFFER_ACTIVE          = ' '
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'SET_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
*     I_CALLBACK_TOP_OF_PAGE   = ' '
*     I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*     I_CALLBACK_HTML_END_OF_LIST       = ' '
*     I_STRUCTURE_NAME         =
*     I_BACKGROUND_ID          = ' '
*     I_GRID_TITLE             =
*     I_GRID_SETTINGS          =
      is_layout                = gs_layout
      it_fieldcat              = gt_fcat
*     IT_EXCLUDING             =
*     IT_SPECIAL_GROUPS        =
*     IT_SORT                  =
*     IT_FILTER                =
*     IS_SEL_HIDE              =
*     I_DEFAULT                = 'X'
*     I_SAVE                   = ' '
*     IS_VARIANT               =
*     IT_EVENTS                =
*     IT_EVENT_EXIT            =
*     IS_PRINT                 =
*     IS_REPREP_ID             =
*     I_SCREEN_START_COLUMN    = 0
*     I_SCREEN_START_LINE      = 0
*     I_SCREEN_END_COLUMN      = 0
*     I_SCREEN_END_LINE        = 0
*     I_HTML_HEIGHT_TOP        = 0
*     I_HTML_HEIGHT_END        = 0
*     IT_ALV_GRAPHICS          =
*     IT_HYPERLINK             =
*     IT_ADD_FIELDCAT          =
*     IT_EXCEPT_QINFO          =
*     IR_SALV_FULLSCREEN_ADAPTER        =
*     O_PREVIOUS_SRAL_HANDLER  =
* IMPORTING
*     E_EXIT_CAUSED_BY_CALLER  =
*     ES_EXIT_CAUSED_BY_USER   =
    TABLES
      t_outtab                 = gt_alv_display
* EXCEPTIONS
*     PROGRAM_ERROR            = 1
*     OTHERS                   = 2
    .
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_header
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_header .
  CLEAR: gt_header, lt_keys.

  LOOP AT gt_alv_display INTO DATA(ls_disp) WHERE selkz = 'X'.
    APPEND ls_disp-vbeln TO lt_keys.
  ENDLOOP.

  SORT lt_keys.
  DELETE ADJACENT DUPLICATES FROM lt_keys.

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
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_smartform
*&---------------------------------------------------------------------*
FORM get_smartform.

  PERFORM get_header.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname = 'ZGZ_RALV_02'
    IMPORTING
      fm_name  = fm_name.

  ls_control_param-no_dialog = 'X'.
  ls_control_param-preview   = 'X'.
  ls_control_param-getotf    = ' '.
  ls_composer_param-tddest   = 'LP01'.

  CALL FUNCTION 'SSF_OPEN'
    EXPORTING
      control_parameters = ls_control_param
      output_options     = ls_composer_param
      user_settings      = ' '
    EXCEPTIONS
      OTHERS             = 1.

  ls_control_param-no_open  = 'X'.
  ls_control_param-no_close = 'X'.

  LOOP AT lt_keys INTO DATA(ls_key).
    CLEAR: gs_sf, gs_header, gt_sf, gs_toplam.

    " Header
    READ TABLE gt_header INTO gs_header WITH KEY vbeln = ls_key.

    " (selkz) yok
    LOOP AT gt_alv_display INTO DATA(ls_all) WHERE vbeln = ls_key.

      gs_toplam-toplam_netwr = gs_toplam-toplam_netwr + ls_all-netwr.

      MOVE-CORRESPONDING ls_all TO gs_sf.
      APPEND gs_sf TO gt_sf.
    ENDLOOP.

    gs_header-toplam_netwr = gs_toplam-toplam_netwr.

    " Smartform çağrısı
    CALL FUNCTION fm_name
      EXPORTING
        control_parameters = ls_control_param
        output_options     = ls_composer_param
        user_settings      = ' '
        gs_header          = gs_header
      TABLES
        alv_data           = gt_sf
      EXCEPTIONS
        OTHERS             = 1.
  ENDLOOP.

  CALL FUNCTION 'SSF_CLOSE'
    EXCEPTIONS
      OTHERS = 1.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form get_adobeform
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_adobeform.

  PERFORM get_header.

  gs_outputparams-nodialog    = abap_true.  " Yazıcı seçim diyaloğunu kapat
  gs_outputparams-preview     = abap_false. " Önizlemeyi kapat
  gs_outputparams-dest        = 'LP01'.

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
    CLEAR: gs_sf, gs_header, gt_sf, gs_toplam.

    " Başlık
    READ TABLE gt_header INTO gs_header WITH KEY vbeln = ls_key.

    LOOP AT gt_alv_display INTO DATA(ls_all) WHERE vbeln = ls_key.

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
*       /1BCDWB/FORMOUTPUT       =
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

ENDFORM.
