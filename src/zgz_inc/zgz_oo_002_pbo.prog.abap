*&---------------------------------------------------------------------*
*& Include          ZGZ_OO_002_PBO
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '0100'.
  SET TITLEBAR '0100'.

  go_controller->display_alv( ).
ENDMODULE.


*&---------------------------------------------------------------------*
*& Module status_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS '0200'.
  SET TITLEBAR '0200'.

  IF go_popup IS INITIAL.
    CREATE OBJECT go_pop_cont
      EXPORTING
*       parent         =                  " Parent container
        container_name = 'CC_MAIL'               " Name of the Screen CustCtrl Name to Link Container To
*       style          =                  " Windows Style Attributes Applied to this Container
*       lifetime       = lifetime_default " Lifetime
*       repid          =                  " Screen to Which this Container is Linked
*       dynnr          =                  " Report To Which this Container is Linked
*       no_autodef_progid_dynnr     =                  " Don't Autodefined Progid and Dynnr?
*      EXCEPTIONS
*       cntl_error     = 1                " CNTL_ERROR
*       cntl_system_error           = 2                " CNTL_SYSTEM_ERROR
*       create_error   = 3                " CREATE_ERROR
*       lifetime_error = 4                " LIFETIME_ERROR
*       lifetime_dynpro_dynpro_link = 5                " LIFETIME_DYNPRO_DYNPRO_LINK
*       others         = 6
      .
    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

    CREATE OBJECT go_popup
      EXPORTING
*       i_shellstyle            = 0                " Control Style
*       i_lifetime              =                  " Lifetime
        i_parent = go_pop_cont.                 " Parent Container
*        i_appl_events           = space            " Register Events as Application Events
*        i_parentdbg             =                  " Internal, Do not Use
*        i_applogparent          =                  " Container for Application Log
*        i_graphicsparent        =                  " Container for Graphics
*        i_name                  =                  " Name
*        i_fcat_complete         = space            " Boolean Variable (X=True, Space=False)
*        o_previous_sral_handler =
*        i_use_one_ux_appearance = abap_false
*      EXCEPTIONS
*        error_cntl_create       = 1                " Error when creating the control
*        error_cntl_init         = 2                " Error While Initializing Control
*        error_cntl_link         = 3                " Error While Linking Control
*        error_dp_create         = 4                " Error While Creating DataProvider Control
*        others                  = 5
    .
    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

    " Field catalog
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
