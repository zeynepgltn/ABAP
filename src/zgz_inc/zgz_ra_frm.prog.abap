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

  " *** DÜZELTME: LVC değil, SLIS tipleri kullanın ***
  DATA: lt_cell_color TYPE slis_t_specialcol_alv,
        ls_cell_color TYPE slis_specialcol_alv.

  LOOP AT gt_alv INTO DATA(gs_alv).
    CLEAR: gs_alv_display,gs_cell_color-color.
    MOVE-CORRESPONDING gs_alv TO gs_alv_display.

    " Eğer yeni bir VBELN
    IF lv_last_vbeln IS NOT INITIAL AND lv_last_vbeln <> gs_alv-vbeln.
      IF lv_current_color = 'C301'.
        lv_current_color = 'C710'.
      ELSE.
        lv_current_color = 'C301'.
      ENDIF.
    ENDIF.

    IF gs_alv-vbeln EQ 53.
      gs_cell_color-fieldname = 'MATNR'.
      gs_cell_color-color-col = 5.
      gs_cell_color-color-int = 1.
      gs_cell_color-color-inv = 0.

      APPEND gs_cell_color TO lt_cell_color.
      gs_alv_display-cell_color = lt_cell_color.
    ENDIF.

    gs_alv_display-line_color = lv_current_color.
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
      i_structure_name = 'ZGZ_RALV_02'
      i_inclname       = sy-repid
    CHANGING
      ct_fieldcat      = gt_fcat.

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
  gs_layout-info_fieldname    = 'LINE_COLOR'.
  gs_layout-coltab_fieldname   = 'CELL_COLOR'.
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
     file_filter               = 'Excel Dosyası (*.xlsx)|*.xlsx' " File Type Filter Table
   CHANGING
     filename                  = gv_filename    " File Name to Save
     path                      = gv_path        " Path to File
     fullpath                  = gv_fullpath    " Path + File Name
     user_action               = gv_user_action " User Action (C Class Const ACTION_OK, ACTION_OVERWRITE etc)
 ).

  CHECK gv_user_action = cl_gui_frontend_services=>action_ok. "sadece kaydete basıldıysa devam yoksa kodun geri kalanı çalışmaz

  CALL FUNCTION 'LVC_TRANSFER_FROM_SLIS'
    EXPORTING
      it_fieldcat_alv = gt_fcat
    IMPORTING
      et_fieldcat_lvc = gt_fcat_lvc
    TABLES
      it_data         = gt_excel.

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

  " Excel dosyasının içeriği,xlsx
  DATA(lr_xls_data) = cl_salv_ex_util=>factory_result_data_table(
                        r_data                 =  lr_data_ref               " Data table
                        t_fieldcatalog         =  gt_fcat_lvc
                      ).

  "XSTRING,xstring
  cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform(
    EXPORTING
      r_result_data = lr_xls_data
      xml_type      = if_salv_bs_xml=>c_type_xlsx
    IMPORTING
      xml           = gv_xstring ).

  "solix
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = gv_xstring
    IMPORTING
      output_length = gv_length
    TABLES
      binary_tab    = gt_solix.


  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      bin_filesize = gv_length
      filename     = gv_fullpath
      filetype     = 'BIN'
      data_tab     = gt_solix.

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
      file_filter               = 'Excel Dosyası (*.xls)|*.xls' " File Type Filter Table
    CHANGING
      filename                  = gv_filename    " File Name to Save
      path                      = gv_path        " Path to File
      fullpath                  = gv_fullpath    " Path + File Name
      user_action               = gv_user_action " User Action (C Class Const ACTION_OK, ACTION_OVERWRITE etc).
      ).

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
      filename              = gv_fullpath
      filetype              = 'DAT'
      write_field_separator = 'X'
      codepage              = '4110'  "Türkçe karakter desteği
      show_transfer_status  = abap_true
    TABLES
      data_tab              = gt_excel
      fieldnames            = t_header.

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
FORM display_alv.
*  gs_exclude-fcode = '&AQW'.
*  APPEND gs_exclude TO gt_exclude.
*
*  gs_exclude-fcode = '%PC'.
*  APPEND gs_exclude TO gt_exclude.
*
*  gs_exclude-fcode = '%SL'.
*  APPEND gs_exclude TO gt_exclude.
*
*  CLEAR: gs_sort.
*  gs_sort-spos = 1.
*  gs_sort-tabname = 'GT_ALV_DISPLAY'.
*  gs_sort-fieldname = 'VBELN'.
*  gs_sort-down = abap_true.
*  APPEND gs_sort TO gt_sort.
*
*  CLEAR: gs_sort.
*  gs_sort-spos = 2.
*  gs_sort-tabname = 'GT_ALV_DISPLAY'.
*  gs_sort-fieldname = 'POSNR'.
*  gs_sort-up = abap_true.
*  APPEND gs_sort TO gt_sort.
*
*  gs_filter-tabname = 'GT_ALV_DISPLAY'.
*  gs_filter-fieldname = 'POSNR'.
*  gs_filter-sign0 = 'I'.
*  gs_filter-optio = 'EQ'.
*  gs_filter-valuf_int = 20.
*  APPEND gs_filter TO gt_filter.
*
*  CLEAR: gs_variant.
*  gs_variant-report = sy-repid.
*  "gs_variant = '/ZEYNEP2'.

  CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK  = ' '
*     I_BYPASSING_BUFFER =
*     I_BUFFER_ACTIVE    = ' '
      i_callback_program = sy-repid
*     I_CALLBACK_PF_STATUS_SET       = ' '
*     I_CALLBACK_USER_COMMAND        = 'USER_COMMAND'
*     I_STRUCTURE_NAME   =
      is_layout          = gs_layout
      it_fieldcat        = gt_fcat
*      it_excluding       = gt_exclude
*     IT_SPECIAL_GROUPS  =
*      it_sort            = gt_sort          " Sort criteria for first list display
*     it_filter          = gt_filter        " Filter criteria for first list output
*     IS_SEL_HIDE        =
*     I_DEFAULT          = 'X'
*      i_save             = 'A'           " Variants can be saved
*      is_variant         = gs_variant
*     IT_EVENTS          =
*     IT_EVENT_EXIT      =
*     IS_PRINT           =
*     IS_REPREP_ID       =
*     I_SCREEN_START_COLUMN          = 0
*     I_SCREEN_START_LINE            = 0
*     I_SCREEN_END_COLUMN            = 0
*     I_SCREEN_END_LINE  = 0
*     IR_SALV_LIST_ADAPTER           =
*     IT_EXCEPT_QINFO    =
*     I_SUPPRESS_EMPTY_DATA          = ABAP_FALSE
*     IO_SALV_ADAPTER    =
* IMPORTING
*     E_EXIT_CAUSED_BY_CALLER        =
*     ES_EXIT_CAUSED_BY_USER         =
    TABLES
      t_outtab           = gt_alv_display
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

*  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
*    EXPORTING
*      i_callback_program = sy-repid          " Name of the calling program
*      is_layout          = gs_layout        " List layout specifications
*      it_fieldcat        = gt_fcat          " Field catalog with field descriptions
*      it_excluding       = gt_exclude       " Table of inactive function codes
*      it_sort            = gt_sort          " Sort criteria for first list display
*      it_filter          = gt_filter        " Filter criteria for first list output
*      i_save             = 'A'           " Variants can be saved
*      is_variant         = gs_variant                  " Variant information
*     i_screen_start_column       = 40                " Coordinates for list in dialog box
*     i_screen_start_line         = 5                " Coordinates for list in dialog box
*     i_screen_end_column         = 100                " Coordinates for list in dialog box
*     i_screen_end_line  = 20                " Coordinates for list in dialog box
*    TABLES
*      t_outtab           = gt_alv_display   " Table with data to be displayed
*    EXCEPTIONS
*      program_error      = 1                " Program errors
*      OTHERS             = 2.
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

  " Fonksiyon Adı
  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name     = 'ZGZ_F_SIPARIS'
    IMPORTING
      e_funcname = gv_funcname.

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
      EXCEPTIONS
        usage_error       = 1
        system_error      = 2
        internal_error    = 3
        OTHERS            = 4.

  ENDLOOP.

  CALL FUNCTION 'FP_JOB_CLOSE'
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.
ENDFORM.
