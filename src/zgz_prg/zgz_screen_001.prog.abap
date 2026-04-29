*&---------------------------------------------------------------------*
*& Report ZGZ_SCREEN_001
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_screen_001.

INCLUDE zgz_screen_top.
INCLUDE zgz_screen_cls.
INCLUDE zgz_screen_pbo.
INCLUDE zgz_screen_pai.

INITIALIZATION.
  DATA lv_yas TYPE i VALUE 18.
  DATA lv_ind TYPE i VALUE 18.

  DO 32 TIMES.
    CLEAR gs_value.

    gs_value-text = lv_yas.
    gs_value-key = lv_ind.
    APPEND gs_value TO gt_values.

    lv_yas += 1.
    lv_ind += 1.
  ENDDO.

  CREATE OBJECT go_controller.


AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF r_rad1 EQ abap_true.
      IF screen-group1 EQ 'GR1'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group1 EQ 'GR2'.
        screen-active = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    IF r_rad2 EQ abap_true.
      IF screen-group1 EQ 'GR1'.
        screen-active = 1.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group1 EQ 'GR2'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.



START-OF-SELECTION.

  gv_cbox = 'X'.

  go_controller->get_data( ).

  CALL SCREEN 0100.
