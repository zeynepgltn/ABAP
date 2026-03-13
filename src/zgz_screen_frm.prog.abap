*&---------------------------------------------------------------------*
*& Include          ZGZ_SCREEN_FRM
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
 SET PF-STATUS 'STATUS_0100'.
 SET TITLEBAR 'TITLE_0100'.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
*  IF sy-ucomm EQ '&BCK'.
*    LEAVE TO SCREEN 0.
*  ENDIF.
  CONCATENATE sy-ucomm
              'butonuna basılmıştır'
              INTO gv_text
              SEPARATED BY space.

  MESSAGE gv_text TYPE 'I'.

  CASE sy-ucomm.
    WHEN '&BCK'.
      IF gv_rad1 EQ 'X'.
        gv_cins = 'KADIN'.
      ELSE.
        gv_cins = 'ERKEK'.
      ENDIF.
      MESSAGE gv_ad TYPE 'I'.
      LEAVE TO SCREEN 0.
    WHEN '&EXT'.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
