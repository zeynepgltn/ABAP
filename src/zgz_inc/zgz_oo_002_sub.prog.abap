*&---------------------------------------------------------------------*
*& Include          ZGZ_OO_002_SUB
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Include ZGZ_OO_002_SUB
*&---------------------------------------------------------------------*

MODULE status_0100 OUTPUT.
  SET PF-STATUS '0100'.
  SET TITLEBAR '0100'.
  go_controller->display_alv( ).
ENDMODULE.

MODULE status_0200 OUTPUT.
  SET PF-STATUS '0200'.
  SET TITLEBAR '0200'.

  IF go_popup IS INITIAL.
    CREATE OBJECT go_pop_cont
      EXPORTING
        container_name = 'CC_MAIL'.

    CREATE OBJECT go_popup
      EXPORTING
        i_parent = go_pop_cont.

    DATA: ls_mfcat TYPE lvc_s_fcat.
    CLEAR: gt_mail_fcat.

    ls_mfcat-fieldname = 'ID'.
    ls_mfcat-coltext   = 'ID'.
    ls_mfcat-outputlen = 10.
    APPEND ls_mfcat TO gt_mail_fcat.
    CLEAR ls_mfcat.

    ls_mfcat-fieldname = 'CC'.
    ls_mfcat-coltext   = 'CC'.
    ls_mfcat-checkbox  = abap_true.
    ls_mfcat-edit      = abap_true.
    ls_mfcat-outputlen = 1.
    APPEND ls_mfcat TO gt_mail_fcat.
    CLEAR ls_mfcat.

    ls_mfcat-fieldname = 'SMTP_ADDR'.
    ls_mfcat-coltext   = 'Mail Adresi'.
    ls_mfcat-edit      = abap_true.
    ls_mfcat-outputlen = 40.
    APPEND ls_mfcat TO gt_mail_fcat.
    CLEAR ls_mfcat.

    DATA: ls_layout TYPE lvc_s_layo.
    ls_layout-cwidth_opt = abap_true.
    ls_layout-zebra      = abap_true.
    ls_layout-sel_mode   = 'A'.

    go_popup->set_table_for_first_display(
      EXPORTING
        is_layout       = ls_layout
      CHANGING
        it_outtab       = gt_mail
        it_fieldcatalog = gt_mail_fcat ).
  ELSE.
    go_popup->refresh_table_display( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN '&BACK' OR '&EXIT' OR '&CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.

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
