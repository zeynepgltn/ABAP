*&---------------------------------------------------------------------*
*& Report ZGZ_RALV_002
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_ralv_002.

INCLUDE zgz_ra_top.
INCLUDE zgz_ra_frm.
*
*INITIALIZATION.
*  gs_variant_get-report = sy-repid.
*  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
*    EXPORTING
*      i_save        = 'A'
*    CHANGING
*      cs_variant    = gs_variant_get
*    EXCEPTIONS
*      wrong_input   = 1
*      not_found     = 2
*      program_error = 3
*      OTHERS        = 4.
*  IF sy-subrc EQ 0.
*    p_var = gs_variant_get-variant.
*  ENDIF.
*
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_var.
*  BREAK-POINT.
*  CLEAR: gs_variant_get.
*  gs_variant_get-report = sy-repid.
*  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
*    EXPORTING
*      is_variant    = gs_variant_get
**     I_TABNAME_HEADER          =
**     I_TABNAME_ITEM            =
**     IT_DEFAULT_FIELDCAT       =
*      i_save        = 'A'
**     I_DISPLAY_VIA_GRID        = ' '
*    IMPORTING
*      e_exit        = gv_exit
*      es_variant    = gs_variant_get
*    EXCEPTIONS
*      not_found     = 1
*      program_error = 2
*      OTHERS        = 3.
*  IF sy-subrc EQ 0.
*    IF gv_exit IS INITIAL.
*      p_var = gs_variant_get-variant.
*    ENDIF.
*  ENDIF.



START-OF-SELECTION.
  PERFORM get_data.
  PERFORM set_fc.
  PERFORM set_layout.
  PERFORM display_alv.
