*&---------------------------------------------------------------------*
*& Report ZGZ_P_SAT_EXCEL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p_sat_excel.

INCLUDE zgz_i_sat_excel_top.
INCLUDE zgz_i_sat_excel_cls.
INCLUDE zgz_i_sat_excel_sub.

INITIALIZATION.
  go_obj = cl_main=>create_instance( ).
  go_obj->initialization( ).

AT SELECTION-SCREEN.
  go_obj->at_selection_screen( ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  go_obj->at_selection_screen_valreq( iv_field = 'P_FILE' ).

START-OF-SELECTION.
  go_obj->run( ).
