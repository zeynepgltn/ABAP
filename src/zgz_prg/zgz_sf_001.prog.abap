*&---------------------------------------------------------------------*
*& Report ZGZ_SF_001
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_sf_001.

TABLES: kna1,lfa1,bkpf.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: rb_1 RADIOBUTTON GROUP grp1 USER-COMMAND rad DEFAULT 'X',
              rb_2 RADIOBUTTON GROUP grp1.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002  .
  PARAMETERS: p_sirk   TYPE bkpf-bukrs DEFAULT '1000',
              p_belget TYPE bkpf-blart DEFAULT 'SA'.

  SELECT-OPTIONS: s_belgen FOR bkpf-belnr,
                  s_mustn FOR kna1-kunnr MODIF ID m1,
                  s_satın FOR lfa1-lifnr MODIF ID m2,
                  s_malıy FOR bkpf-gjahr,
                  s_belget FOR bkpf-bldat.
SELECTION-SCREEN END OF BLOCK b2.

INCLUDE zgz_sf_top.
INCLUDE zgz_sf_frm.


AT SELECTION-SCREEN OUTPUT.
  PERFORM modify_screen.


START-OF-SELECTION.
  PERFORM get_data.
  PERFORM set_fc.
  PERFORM set_layout.
  PERFORM display_alv.
