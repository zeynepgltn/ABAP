*&---------------------------------------------------------------------*
*& Include          ZGZ_OO_001_PAI
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN '&BACK'.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN '&EXT' OR '&CANC'.
      LEAVE PROGRAM.

    WHEN '&SAVE'.
      PERFORM get_total_sum.

    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
