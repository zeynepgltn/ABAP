*&---------------------------------------------------------------------*
*& Include          ZGZ_OO_002_PAI
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN '&BACK' OR '&EXIT' OR '&CANCEL'.
      SET SCREEN 0. " Seçim ekranına geri döner
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMANDS_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  CASE sy-ucomm.
    WHEN '&SEND'.
      go_popup->check_changed_data( ).
      gv_mail_confirmed = abap_true.
      LEAVE TO SCREEN 0.

    WHEN '&CANCEL' OR '&BACK' OR '&EXIT'.
      gv_mail_confirmed = abap_false.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
