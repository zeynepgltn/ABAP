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
  ENDIF.
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
  CLEAR gt_header.

  LOOP AT gt_alv_display INTO DATA(ls_disp) WHERE selkz = 'X'.
    APPEND ls_disp-vbeln TO lt_keys.
  ENDLOOP.

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

  LOOP AT gt_alv_display INTO DATA(ls_row)
    WHERE selkz = 'X'
    GROUP BY ( vbeln = ls_row-vbeln ).

    CLEAR: gs_sf, gs_header, gt_sf, gs_toplam.

    READ TABLE gt_header INTO gs_header
      WITH KEY vbeln = ls_row-vbeln.


    LOOP AT GROUP ls_row INTO DATA(ls_item).
      gs_toplam-toplam_netwr = gs_toplam-toplam_netwr + ls_item-netwr.

      MOVE-CORRESPONDING ls_item TO gs_sf.
      APPEND gs_sf TO gt_sf.
    ENDLOOP.

    gs_header-toplam_netwr = gs_toplam-toplam_netwr.

    " Smartform'u çağırma
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

  " Job Parametreleri
  gs_outputparams-nodialog = abap_true.
  gs_outputparams-preview  = abap_true.
  gs_outputparams-dest     = 'LP01'.

  " Adobe Job
  CALL FUNCTION 'FP_JOB_OPEN'
    CHANGING
      ie_outputparams = gs_outputparams.

  " Fonksiyon Adı
  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name     = 'ZGZ_F_SIPARIS'
    IMPORTING
      e_funcname = gv_funcname.

  LOOP AT gt_alv_display INTO DATA(ls_row)
    WHERE selkz = 'X'
    GROUP BY ( vbeln = ls_row-vbeln ).

    CLEAR: gs_sf, gs_header, gt_sf, gs_toplam.

    READ TABLE gt_header INTO gs_header WITH KEY vbeln = ls_row-vbeln.

    LOOP AT GROUP ls_row INTO DATA(ls_r).
      gs_toplam-toplam_netwr = gs_toplam-toplam_netwr + ls_r-netwr.
      MOVE-CORRESPONDING ls_r TO gs_sf.
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
        OTHERS            = 1.
  ENDLOOP.

  CALL FUNCTION 'FP_JOB_CLOSE'.
ENDFORM.
