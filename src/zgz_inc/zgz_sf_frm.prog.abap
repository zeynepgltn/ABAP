*&---------------------------------------------------------------------*
*& Include          ZGZ_SF_FRM
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form modify_screen
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM modify_screen .
  LOOP AT SCREEN.
    IF screen-group1 = 'M1'.
      IF rb_1 = 'X'.
        screen-active = 1.
      ELSE.
        screen-active = 0.
      ENDIF.
    ENDIF.

    IF screen-group1 = 'M2'.
      IF rb_2 = 'X'.
        screen-active = 1.
      ELSE.
        screen-active = 0.
      ENDIF.
    ENDIF.

    IF screen-name = 'P_SIRK' OR screen-name = 'P_BELGET'.
      screen-input = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.
ENDFORM.

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
    SELECT b~bukrs AS sirketk,
           b~belnr AS belgeno,
           b~gjahr AS maliyil,
           k~kunnr AS musteriad,
           bs~buzei AS kalem,
           bs~wrbtr AS tutar,
           b~waers AS parab,
           bs~sgtxt AS aciklama,
           t~butxt AS sirketad,
           a~street AS sokak,
           a~city1 AS yerlesim,
           a~city2 AS mahalle
     FROM bkpf AS b
     INNER JOIN bseg AS bs
      ON  b~bukrs = bs~bukrs
      AND   b~belnr = bs~belnr
      AND   b~gjahr = bs~gjahr
     LEFT JOIN kna1 AS k
      ON k~kunnr = bs~kunnr
     LEFT JOIN t001 AS t
      ON  t~bukrs = bs~bukrs
   LEFT JOIN adrc AS a
   ON a~addrnumber = k~adrnr
     WHERE b~bukrs = @p_sirk
     AND b~belnr IN @s_belgen
     AND b~gjahr IN @s_malıy
     INTO CORRESPONDING FIELDS OF TABLE @gt_detay.


  ELSEIF rb_2 = 'X'.
    SELECT b~bukrs AS sirketk,
           b~belnr AS belgeno,
           b~gjahr AS maliyil,
           l~kunnr AS musteriad,
           bs~buzei AS kalem,
           bs~wrbtr AS tutar,
           b~waers AS parab,
           bs~sgtxt AS aciklama,
           t~butxt AS sirketad,
           a~street AS sokak,
           a~city1 AS yerlesim,
           a~city2 AS mahalle
     FROM bkpf AS b
     INNER JOIN bseg AS bs ON  b~bukrs = bs~bukrs
      AND   b~belnr = bs~belnr
      AND   b~gjahr = bs~gjahr
     LEFT JOIN lfa1 AS l ON l~lıfnr = bs~lıfnr
     LEFT JOIN t001 AS t ON  t~bukrs = bs~bukrs
     LEFT JOIN adrc AS a ON a~addrnumber = l~adrnr
     WHERE b~bukrs = @p_sirk
     AND b~belnr IN @s_belgen
     AND b~gjahr IN @s_malıy
     INTO CORRESPONDING FIELDS OF TABLE @gt_detay.
  ENDIF.

  REFRESH gt_alv.

  LOOP AT gt_detay INTO DATA(ls_group)
        GROUP BY ( belgeno = ls_group-belgeno
                  sirketk = ls_group-sirketk
                  maliyil = ls_group-maliyil ).

    gs_toplam = ls_group.
    CLEAR: gs_toplam-tutar.

    LOOP AT GROUP ls_group INTO DATA(ls_memb).
      gs_toplam-tutar = gs_toplam-tutar + ls_memb-tutar.

      "gs_toplam'daki metin boşsa ve o anki kalemde dolu bir metin
      IF gs_toplam-aciklama IS INITIAL AND ls_memb-aciklama IS NOT INITIAL.
        gs_toplam-aciklama = ls_memb-aciklama.
      ENDIF.
    ENDLOOP.

    " tüm kalemler dönüldü metin hala boş
    IF gs_toplam-aciklama IS INITIAL.
      gs_toplam-aciklama = |{ gs_toplam-sirketk }-{ gs_toplam-belgeno }-{ gs_toplam-maliyil }|.
    ENDIF.

    APPEND gs_toplam TO gt_toplam.
    CLEAR gs_toplam.
  ENDLOOP.

  gt_alv = gt_toplam.
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
  SET PF-STATUS 'Z200' EXCLUDING pt_extab.
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
  IF p_ucomm = '&CKT'.
    PERFORM get_smartform.
  ENDIF.
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
      i_program_name         = sy-repid
*     I_INTERNAL_TABNAME     =
      i_structure_name       = 'ZGZ_S_BELGE'
*     I_CLIENT_NEVER_DISPLAY = 'X'
      i_inclname             = sy-repid
*     I_BYPASSING_BUFFER     =
*     I_BUFFER_ACTIVE        =
    CHANGING
      ct_fieldcat            = gt_fcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout.
  gs_layout-window_titlebar = 'BELGE'.
  gs_layout-zebra = abap_true .
  gs_layout-colwidth_optimize = abap_true .
  gs_layout-box_fieldname = 'SELKZ'.
ENDFORM.

**&---------------------------------------------------------------------*
**& Form display_alv
**&---------------------------------------------------------------------*
**& text
**&---------------------------------------------------------------------*
**& -->  p1        text
**& <--  p2        text
**&---------------------------------------------------------------------*
FORM display_alv .
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK        = ' '
*     i_bypassing_buffer       = abap_true
*     I_BUFFER_ACTIVE          = ' '
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'SET_STATUS'
      i_callback_user_command  = 'USER_COMMAND'
*     I_CALLBACK_TOP_OF_PAGE   = ' '
*     i_callback_html_top_of_page = ''
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
*     it_events                =
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
      t_outtab                 = gt_alv
*   EXCEPTIONS
*     PROGRAM_ERROR            = 1
*     OTHERS                   = 2
    .
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_smartform
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_smartform.
  CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
    IMPORTING
      e_grid = ref_grid.
  IF ref_grid IS BOUND.
    ref_grid->check_changed_data( ).
  ENDIF.

  LOOP AT gt_alv INTO DATA(ls_alv) WHERE selkz = 'X'.
    ls_key-belnr    = ls_alv-belgeno.
    ls_key-bukrs    = ls_alv-sirketk.
    ls_key-gjahr    = ls_alv-maliyil.
    ls_key-musteriad = ls_alv-musteriad.
    ls_key-sokak    = ls_alv-sokak.
    ls_key-yerlesim = ls_alv-yerlesim.
    ls_key-mahalle  = ls_alv-mahalle.
    ls_key-vergino  = ls_alv-vergino.
    ls_key-verginn  = ls_alv-verginn.
    COLLECT ls_key INTO lt_keys.
  ENDLOOP.

  IF rb_1 = 'X'. " Müşteri
    SELECT b~bukrs AS sirketk,
           b~belnr AS belgeno,
           b~gjahr AS maliyil,
           k~name1 AS musteriad,
           a~street AS sokak,
           a~city1 AS yerlesim,
           a~city2 AS mahalle,
           k~stcd1 AS vergino,
           k~stcd2 AS verginn,
           b~waers AS parab
      FROM bkpf AS b
      INNER JOIN bseg AS bs ON bs~bukrs = b~bukrs
                           AND bs~belnr = b~belnr
                           AND bs~gjahr = b~gjahr
      LEFT JOIN kna1 AS k   ON k~kunnr = bs~kunnr
      LEFT JOIN adrc AS a   ON a~addrnumber = k~adrnr
      FOR ALL ENTRIES IN @lt_keys
      WHERE b~bukrs = @lt_keys-bukrs
        AND b~belnr = @lt_keys-belnr
        AND b~gjahr = @lt_keys-gjahr
      INTO CORRESPONDING FIELDS OF TABLE @gt_header.

  ELSEIF rb_2 = 'X'. " Satıcı
    SELECT b~bukrs AS sirketk,
           b~belnr AS belgeno,
           b~gjahr AS maliyil,
           l~name1 AS musteriad,
           a~street AS sokak,
           a~city1 AS yerlesim,
           a~city2 AS mahalle,
           l~stcd1 AS vergino,
           l~stcd2 AS verginn,
           b~waers AS parab
      FROM bkpf AS b
      INNER JOIN bseg AS bs ON bs~bukrs = b~bukrs
                           AND bs~belnr = b~belnr
                           AND bs~gjahr = b~gjahr
      LEFT JOIN lfa1 AS l   ON l~lifnr = bs~lifnr
      LEFT JOIN adrc AS a   ON a~addrnumber = l~adrnr
      FOR ALL ENTRIES IN @lt_keys
      WHERE b~bukrs = @lt_keys-bukrs
        AND b~belnr = @lt_keys-belnr
        AND b~gjahr = @lt_keys-gjahr
      INTO CORRESPONDING FIELDS OF TABLE @gt_header.
  ENDIF.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname = 'ZGZ_SF_002'
    IMPORTING
      fm_name  = fm_name.

  ls_control_param-no_dialog = 'X'.
  ls_control_param-preview   = 'X'.
  ls_control_param-getotf    = ' '.
  ls_composer_param-tddest  = 'LP01'.
  " yazdırmayı döngüden önce bir kere açma
  CALL FUNCTION 'SSF_OPEN'
    EXPORTING
      control_parameters = ls_control_param
      output_options     = ls_composer_param
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.

  ls_control_param-no_open  = 'X'.
  ls_control_param-no_close = 'X'.

  "Yazdırma
  LOOP AT gt_alv INTO DATA(ls_row) WHERE selkz = 'X'
       GROUP BY ( sirketk = ls_row-sirketk
                  belgeno = ls_row-belgeno
                  maliyil = ls_row-maliyil ).

    CLEAR: gs_header, gt_alv_for_sf, ls_spell, s_parabb.

    READ TABLE gt_header INTO gs_header
          WITH KEY sirketk = ls_row-sirketk
                   belgeno = ls_row-belgeno
                   maliyil = ls_row-maliyil.

    "Tutar Yazı
    CALL FUNCTION 'SPELL_AMOUNT'
      EXPORTING
        amount   = ls_row-tutar
        currency = ls_row-parab
        language = sy-langu
      IMPORTING
        in_words = ls_spell
      EXCEPTIONS
        OTHERS   = 3.

    IF ls_spell-decword IS INITIAL.
      ls_spell-decword = 'SIFIR'.
    ENDIF.

    CASE ls_row-parab.
      WHEN 'TRY'.
        s_parabb = 'KR'.
      WHEN 'USD'.
        s_parabb = '¢'.
      WHEN 'EUR'.
        s_parabb = 'C'.
      WHEN OTHERS.
        s_parabb = ' '.
    ENDCASE.

*    CONCATENATE ls_spell-word ls_row-parab ls_spell-decword s_parabb INTO gs_header-s_lira
*                                                                     SEPARATED BY ' '.
    gs_header-s_lira = |{ ls_spell-word } { ls_row-parab } { ls_spell-decword } { s_parabb }|.

    APPEND gs_header TO gt_header.

    LOOP AT gt_detay INTO DATA(ls_gercek)
         WHERE sirketk = ls_row-sirketk
           AND belgeno = ls_row-belgeno
           AND maliyil = ls_row-maliyil.

      CLEAR gs_sf.
      MOVE-CORRESPONDING ls_gercek TO gs_sf.
      APPEND gs_sf TO gt_alv_for_sf. " Smartform'a detaylar gidiyor
    ENDLOOP.

    CALL FUNCTION fm_name
      EXPORTING
        control_parameters = ls_control_param
        output_options     = ls_composer_param
        user_settings      = ' '
        gs_header          = gs_header
      TABLES
        it_alv_data        = gt_alv_for_sf
      EXCEPTIONS
        OTHERS             = 1.
  ENDLOOP.

  " tüm belgeler bitti, paketi kapat
  CALL FUNCTION 'SSF_CLOSE'
    EXCEPTIONS
      formatting_error = 1
      internal_error   = 2
      send_error       = 3
      OTHERS           = 4.

ENDFORM.
