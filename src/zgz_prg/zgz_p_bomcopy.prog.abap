*&---------------------------------------------------------------------*
*& Report ZGZ_P_BOMCOPY
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZGZ_P_BOMCOPY.

INCLUDE zgz_i_bomcopy_top.
INCLUDE zgz_i_bomcopy_cls.
INCLUDE zgz_i_bomcopy_sub.

INITIALIZATION.
  go_obj = cl_controller=>create_instance( ).

START-OF-SELECTION.
  CALL SCREEN 100.
