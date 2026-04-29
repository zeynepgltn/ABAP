*&---------------------------------------------------------------------*
*& Include          ZGZ_SCREEN_PAI
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE ok_code.
    WHEN '&BCK'.
      LEAVE TO SCREEN 0.

    WHEN '&EXT'.

    WHEN '&CLEAR'.
      CLEAR: gv_ad,
             gv_soyad,
             gv_yas,
             gv_cbox,
             gv_date,
             gv_rad2.

      gv_rad1 = abap_true.

    WHEN '&SAVE'.
      CLEAR gs_log.

      gs_log-ad = gv_ad.
      gs_log-soyad = gv_soyad.
      gs_log-cbox = gv_cbox.
      gs_log-yas = gv_yas.
      gs_log-ddate = gv_date.

      IF gv_rad1 = 'X'.
        gs_log-cinsiyet = 'K'.
      ELSE.
        gs_log-cinsiyet = 'E'.
      ENDIF.

      INSERT zgz_t_screen FROM gs_log.
      COMMIT WORK AND WAIT. "Cache de tutma ilerlet

      IF sy-subrc = 0.
        MESSAGE 'Başarılı' TYPE 'S'.
      ENDIF.

    WHEN '&TAB1'.
      tb_id-activetab = '&TAB1'.

    WHEN '&TAB2'.
      tb_id-activetab = '&TAB2'.

    WHEN '&ENABLE'.
      gv_flag = abap_true.

      CALL SCREEN 0200 STARTING AT 10 10
                        ENDING AT  50 20.

    WHEN '&DISABLE'.
      gv_flag = abap_false.

    WHEN OTHERS.
  ENDCASE.
ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  CASE sy-ucomm.
    WHEN '&OK'.
    WHEN '&CANCEL'.
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
