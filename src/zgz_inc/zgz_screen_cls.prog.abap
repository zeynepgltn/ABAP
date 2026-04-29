*&---------------------------------------------------------------------*
*& Include          ZGZ_SCREEN_CLS
*&---------------------------------------------------------------------*
CLASS lcl_controller IMPLEMENTATION.
  METHOD get_data.

    SELECT SINGLE * FROM sflight
      INTO gs_sflight
      WHERE carrid EQ p_carrid
         AND connid EQ p_connid
         AND fldate EQ p_fldate.

  ENDMETHOD.

ENDCLASS.
