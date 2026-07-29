*&---------------------------------------------------------------------*
*& Report ZGZ_P_MESSAGE_CLASS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p_message_class MESSAGE-ID zgz_mc_001.

INCLUDE zgz_p_message_class_sub.
INCLUDE zgz_p_message_class_top.
INCLUDE zgz_p_message_class_cls.

START-OF-SELECTION.

*MESSAGE 'Hello Abap World!' TYPE 'S'.
*MESSAGE 'Hello Abap World!' TYPE 'I'.
*MESSAGE 'Hello Abap World!' TYPE 'W'.
*MESSAGE 'Hello Abap World!' TYPE 'E'.
*MESSAGE 'Hello Abap World!' TYPE 'A'.
*MESSAGE 'Hello Abap World!' TYPE 'X'.

*  MESSAGE 'Hello Abap World!' TYPE 'I' DISPLAY LIKE 'W'.
*  MESSAGE TEXT-000 TYPE 'I'.
*  MESSAGE i000. "(zgz_mc_001).

  DATA lv_num TYPE int4.
  MESSAGE i000 WITH  lv_num 'Class'.

  WRITE: 'Message Egitim Videosu'.
