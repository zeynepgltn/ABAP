*&---------------------------------------------------------------------*
*& Report ZGZ_SCREEN_002
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_screen_002.

INCLUDE zgz_scr002_top.
INCLUDE zgz_scr002_cls.
INCLUDE zgz_scr002_pbo.
INCLUDE zgz_scr002_pai.

INITIALIZATION.

  CREATE OBJECT go_controller.

START-OF-SELECTION.

  CALL SCREEN 0100.
