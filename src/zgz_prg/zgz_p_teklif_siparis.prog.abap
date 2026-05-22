*&---------------------------------------------------------------------*
*& Report ZGZ_P_TEKLIF_SIPARIS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p_teklif_siparis.

INCLUDE zgz_i_teklif_siparis_top.
INCLUDE zgz_i_teklif_siparis_sub.
INCLUDE zgz_i_teklif_siparis_cls.

INITIALIZATION.
  go_obj = cl_main=>create_instance( ).

START-OF-SELECTION.
go_obj->run( ).
