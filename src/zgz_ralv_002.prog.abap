*&---------------------------------------------------------------------*
*& Report ZGZ_RALV_002
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_ralv_002.

INCLUDE zgz_ra_top.
INCLUDE zgz_ra_frm.


START-OF-SELECTION.
  PERFORM get_data.
  PERFORM set_fc.
  PERFORM set_layout.
  PERFORM display_alv.
