*&---------------------------------------------------------------------*
*& Report ZGZ_P_SAS_GELISIM
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p_sas_gelisim.

INCLUDE zgz_i_sas_gelisim_top.
INCLUDE zgz_i_sas_gelisim_cls.
INCLUDE zgz_i_sas_gelisim_sub.

INITIALIZATION.
  go_obj = cl_controller=>create_instance( ).

START-OF-SELECTION.
  go_obj->run( ).
