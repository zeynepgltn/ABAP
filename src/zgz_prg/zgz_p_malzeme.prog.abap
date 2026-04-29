*&---------------------------------------------------------------------*
*& Report ZGZ_P_MALZEME
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p_malzeme.

INCLUDE zgz_i_malzeme_top.
INCLUDE zgz_i_malzeme_sub.
INCLUDE zgz_i_malzeme_cls.

INITIALIZATION.
  go_obj = cl_controller=>create_instance( ).

START-OF-SELECTION.
  CALL SCREEN 100.
