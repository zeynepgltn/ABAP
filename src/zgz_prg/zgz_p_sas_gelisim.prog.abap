*&---------------------------------------------------------------------*
*& Report ZGZ_P_SAS_GELISIM
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZGZ_P_SAS_GELISIM.

INCLUDE ZGZ_I_SAS_GELISIM_TOP.
INCLUDE ZGZ_I_SAS_GELISIM_CLS.
INCLUDE ZGZ_I_SAS_GELISIM_SUB.

INITIALIZATION.
  go_obj = cl_controller=>create_instance( ).
  go_obj->initialization( ).

START-OF-SELECTION.
