*--------------------------------------------------------------------*
*& Include          ZGZ_RALV_FRM
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data.
  IF rb_1 = 'X'.
    SELECT ek~ebeln,
           e~ebelp,
           ek~bstyp,
           ek~bsart,
           e~matnr,
           z~menge,
           e~meins
      FROM ekpo AS e
      INNER JOIN ekko AS ek ON e~ebeln = ek~ebeln
      LEFT JOIN zgz_t_ekpo AS z ON e~ebeln = z~ebeln AND z~matnr = e~matnr
      INTO TABLE @gt_alv.

  ELSEIF rb_2 = 'X'.
    SELECT zk~ebeln,
           z~ebelp,
           zk~bstyp,
           zk~bsart,
           z~matnr,
           z~menge,
           z~meins
      FROM zgz_t_ekpo AS z
      INNER JOIN zgz_t_ekko AS zk ON z~ebeln = zk~ebeln
      INTO TABLE @gt_alv.
  ENDIF.

  LOOP AT gt_alv INTO DATA(gs_alv).
    CLEAR: gs_alv_display, ls_color, lt_color.

    MOVE-CORRESPONDING gs_alv TO gs_alv_display.

    " Satır rengi
    IF gs_alv_display-menge = 0.
      gs_alv_display-rowcolor = 'C610'.
      gs_alv_display-zicon    = icon_led_red.
    ELSEIF gs_alv_display-menge < 500.
      gs_alv_display-rowcolor = 'C310'.
      gs_alv_display-zicon    = icon_led_yellow.
    ELSE.
      gs_alv_display-rowcolor = 'C500'.
      gs_alv_display-zicon    = icon_led_green.
    ENDIF.

    IF ( gs_alv_display-menge = 0 OR  gs_alv_display-menge = 400 OR gs_alv_display-menge = 600 ).
      ls_color-fname     = 'MENGE'.
      ls_color-color-col = 7.
      APPEND ls_color TO lt_color.
    ENDIF.

    gs_alv_display-cellcolor = lt_color.
    APPEND gs_alv_display TO gt_alv_display.
  ENDLOOP.
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
  IF rb_1 = 'X'.
    SET PF-STATUS 'Z100' EXCLUDING pt_extab.

  ELSEIF rb_2 = 'X'.
    CLEAR gs_extab.
    gs_extab-fcode = '  &ZKAYDET'.
    APPEND gs_extab TO pt_extab.

    SET PF-STATUS 'Z100' EXCLUDING pt_extab.
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form USER_COMMAND
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM user_command USING p_ucomm    TYPE syucomm
                        p_selfield TYPE slis_selfield.
  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      e_grid = gr_grid.
  IF gr_grid IS BOUND.
    gr_grid->check_changed_data( ).
  ENDIF.

  CASE p_ucomm.
    WHEN '&ZKAYDET'.
      LOOP AT gt_alv_display INTO gs_alv_display.
        CLEAR lv_error.

        UPDATE zgz_t_ekpo SET menge = gs_alv_display-menge
          WHERE ebeln = gs_alv_display-ebeln
          AND matnr = gs_alv_display-matnr.

        IF sy-subrc <> 0.
          lv_error = abap_true.
        ENDIF.
      ENDLOOP.

      IF lv_error = abap_false.
        COMMIT WORK.
        MESSAGE 'Kayıt başarılı!' TYPE 'S'.
      ELSE.
        ROLLBACK WORK.
        MESSAGE 'Hata oluştu!' TYPE 'E'.
      ENDIF.
      " Kayıt sonrası ALV grid'in yenilenmesi için:
      p_selfield-refresh = 'X'.

    WHEN '&IC1'.
      IF p_selfield-fieldname = 'EBELN' OR p_selfield-fieldname = 'MATNR'.
*        MESSAGE |Şu kolona tıklandı: { p_selfield-fieldname }| TYPE 'I'.
        CONCATENATE  p_selfield-value
                     'TIKLANDI'
                     INTO gv_mes
                     SEPARATED BY space.
        MESSAGE gv_mes TYPE 'I'.
      ELSE.
        MESSAGE |Şu kolona çift tıklandı: { p_selfield-fieldname }| TYPE 'I'.
      ENDIF.

    WHEN '&SELECT' OR '&SLC'.
      CLEAR: gv_count, gv_ind.

      LOOP AT gt_alv_display INTO gs_alv_display WHERE selkz EQ 'X'.
        gv_count += 1.
        IF gv_ind IS INITIAL.
          gv_ind = |{ sy-tabix }|.
        ELSE.
          gv_ind = |{ gv_ind }, { sy-tabix }|.
        ENDIF.
      ENDLOOP.

      MESSAGE |{ gv_count } satır seçildi. Seçilen İndexler: { gv_ind }| TYPE 'I'.
  ENDCASE.
*  IF p_selfield-fieldname = 'EBELN' OR p_selfield-fieldname = 'MATNR'.
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
      "i_internal_tabname = 'GT_ALV_DISPLAY'
      i_structure_name = 'ZGZ_ALV_MERGE' "tırnak içinde büyük harfle olmalı
      i_inclname       = sy-repid
    CHANGING
      ct_fieldcat      = gt_fcat.

  CLEAR gs_fcat.
  gs_fcat-fieldname = 'SELKZ'.
  gs_fcat-seltext_m = 'Seçim'.
  gs_fcat-checkbox  = abap_true.
  gs_fcat-edit      = abap_true.
  gs_fcat-outputlen = 3.
  APPEND gs_fcat TO gt_fcat.

  LOOP AT gt_fcat INTO gs_fcat.
    CASE gs_fcat-fieldname.
      WHEN 'EBELN' OR 'MATNR'. "hotspot
        gs_fcat-hotspot = abap_true.
        gs_fcat-key =  abap_true.
        gs_fcat-outputlen = 35.

      WHEN 'MENGE'.
        gs_fcat-do_sum = abap_true.
        IF rb_1 = 'X'.
          gs_fcat-edit = abap_true.
        ELSE.
          gs_fcat-edit = abap_false.
        ENDIF.
      WHEN 'ZICON'.
        gs_fcat-icon      = abap_true.  " ikon olarak göster
        gs_fcat-seltext_m = 'Durum'.
*        gs_fcat-outputlen = 5.
      WHEN 'MEINS'.
        gs_fcat-outputlen = 15.
    ENDCASE.
    MODIFY gt_fcat FROM gs_fcat.
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
  gs_layout-window_titlebar = 'SATIN ALMA'.
  gs_layout-zebra = abap_true .
  "gs_layout-colwidth_optimize = abap_true .
  "gs_layout-edit = abap_true .
  gs_layout-info_fieldname    = 'ROWCOLOR'. " satır rengi,Renk bilgisini tablomun içinde ara, adı ROWCOLOR olan kolona bak
  gs_layout-coltab_fieldname = 'CELLCOLOR'." hücre rengi
  "gs_layout-box_fieldname = 'SELKZ'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form top_of_page
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM top_of_page .
  CLEAR: ls_header,lt_header.
  ls_header-typ = 'H'.   "H S A
  ls_header-info = 'SATIN ALMA SİPARİŞ'.
  APPEND ls_header TO lt_header.

  CLEAR ls_header.
  ls_header-typ = 'A'.
  ls_header-info = |{ lines( gt_alv ) } satır bulunuyor|.
  APPEND ls_header TO lt_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
*    I_LOGO                   =
*    I_END_OF_LIST_GRID       =
*    I_ALV_FORM               =
  .

ENDFORM.

*&---------------------------------------------------------------------*
*& Form END_OF_PAGE
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM end_of_page .

  CLEAR: ls_header,lt_header.
  ls_header-typ = 'S'.
  ls_header-key = 'Tarih:'.
  " ls_header-info = '23.02.2026'.
  CONCATENATE sy-datum+6(2)
              '.'
              sy-datum+4(2)
              '.'
              sy-datum+0(4)
              INTO gv_date.
  ls_header-info = gv_date.
  APPEND ls_header TO lt_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
*     I_LOGO             =
*      i_end_of_list_grid =
*     I_ALV_FORM         =
  .

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
  gs_event-name = slis_ev_top_of_page.
  gs_event-form = 'TOP_OF_PAGE'.
  APPEND gs_event TO gt_events.

  gs_event-name = slis_ev_end_of_list.
  gs_event-form = 'END_OF_PAGE'.
  APPEND gs_event TO gt_events.

  "field catalog kolon bazında yapısı bir table,layout genel özellikler yapısı bir structure
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK        = ' '
      i_bypassing_buffer       = abap_true
*     I_BUFFER_ACTIVE          = ' '
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'SET_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
*     I_CALLBACK_TOP_OF_PAGE   = ' '
*     i_callback_html_top_of_page = 'TOP_OF_PAGE'
*     I_CALLBACK_HTML_END_OF_LIST = ' '
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
      it_events                = gt_events
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
*     IR_SALV_FULLSCREEN_ADAPTER  =
*     O_PREVIOUS_SRAL_HANDLER  =
*   IMPORTING
*     E_EXIT_CAUSED_BY_CALLER  =
*     ES_EXIT_CAUSED_BY_USER   =
    TABLES
      t_outtab                 = gt_alv_display
*   EXCEPTIONS
*     PROGRAM_ERROR            = 1
*     OTHERS                   = 2
    .
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.
