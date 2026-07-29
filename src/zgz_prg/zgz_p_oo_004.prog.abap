*&---------------------------------------------------------------------*
*& Report ZGZ_P_OO_004
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p_oo_004.

INCLUDE zgz_p_oo_004_top.
INCLUDE zgz_p_oo_004_sub.
INCLUDE zgz_p_oo_004_cls.

INITIALIZATION.
  go_obj = cl_controller=>create_instance( ).
  go_obj->initialization( ).

START-OF-SELECTION.
  "go_obj->get_data( it_belgen = s_belgen[] ). "tablonun tüm içeriği

  CALL SCREEN 0100.
