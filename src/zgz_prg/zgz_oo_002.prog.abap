*&---------------------------------------------------------------------*
*& Report ZGZ_OO_002
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_oo_002.

INCLUDE zgz_oo_002_top.
INCLUDE zgz_oo_002_cls.
INCLUDE zgz_oo_002_sub.


INITIALIZATION.
  go_controller = lcl_controller=>create_instance( ).
  go_controller->initialization( ).


AT SELECTION-SCREEN.
  go_controller->at_selection_screen( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  go_controller->at_selection_screen_valreq( EXPORTING iv_field = 'P_FILE' ).

START-OF-SELECTION.
  IF rb_1 = 'X'.
    go_controller->gv_rb = '1'.
  ELSE.
    go_controller->gv_rb = '2'.
  ENDIF.

  IF p_file IS NOT INITIAL.
    gv_filename = p_file.
    go_controller->set_fcat( ). "şablona uygun gt_fcat
    go_controller->set_layout( ).
    go_controller->excel_upload_cl( ).
  ELSE.
    go_controller->start( ).
  ENDIF.

  IF go_alv IS NOT INITIAL. " f8e birden fazla kez basabilir
    go_alv->free( ).
    FREE go_alv.
  ENDIF.
  IF go_cont IS NOT INITIAL.
    go_cont->free( ).
    FREE go_cont.
  ENDIF.

  CALL SCREEN '0100'.
