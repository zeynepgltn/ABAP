*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_0100'.

  " 1. Ekran Dinamikliği (Hızlı Çalışır)
  LOOP AT SCREEN.
    IF ( gv_num = 1 AND screen-group1 = 'X' ) OR
       ( gv_num = 2 AND screen-group2 = 'X' ).
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  " 2. Listbox Kontrolü (Sadece 1 kez çalışır)
  IF gt_values IS INITIAL. " Veya bir gv_init flag'

    gv_id = 'GV_YAS'.
    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id     = gv_id
        values = gt_values.
  ENDIF.
ENDMODULE.


*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS 'STATUS_0200'.
  SET TITLEBAR 'TITLE_0100'.
ENDMODULE.
