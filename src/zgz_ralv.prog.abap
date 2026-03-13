*&---------------------------------------------------------------------*
*& Report ZGZ_RALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_ralv.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME.
  PARAMETERS: rb_1 RADIOBUTTON GROUP grp1 DEFAULT 'X',
              rb_2 RADIOBUTTON GROUP grp1.
SELECTION-SCREEN END OF BLOCK b2.


INCLUDE zgz_ralv_top.
INCLUDE zgz_ralv_frm.


START-OF-SELECTION.
  PERFORM get_data.
  PERFORM set_fc.
  PERFORM set_layout.
  PERFORM display_alv.
