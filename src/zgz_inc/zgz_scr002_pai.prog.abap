*&---------------------------------------------------------------------*
*& Include          ZGZ_SCR002_PAI
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  go_controller->get_user_status( ).
  gv_title_dynamic = 'Genel Ana Ekran'.

  CASE sy-ucomm.
      DATA: gv_mode TYPE c LENGTH 1.

    WHEN '&INSERT' OR '&DELETE' OR '&UPDATE' OR '&REPORT'.
      IF  go_controller->gv_user_exists  = abap_false.
        " Kayıt yok,uyarı
        MESSAGE 'Bakım tablosunda kaydınız bulunmamaktadır!' TYPE 'E'.

      ELSEIF go_controller->gv_user_status <> 'X'.
        " Kayıt var ama aktif değil,uyarı
        MESSAGE 'Kaydınız mevcut ancak aktif değildir!' TYPE 'E'.
      ELSE.
        " Kayıt var ve aktif,ilgili
        CASE sy-ucomm.
          WHEN '&INSERT'.
            " Kayıt ekleme işlemi
            go_controller->gv_mode = 'I'.

            gv_title_dynamic = 'Kayıt Ekleme Paneli'.

            CLEAR: gv_bukrs, gv_user_id, gv_name,
             gv_surname, gv_birth_date, gv_salary.

            " Ekranı ilk haline getir
            go_controller->gv_veri_geldi = abap_false.

            CALL SCREEN 0200.

          WHEN '&DELETE'.
            " Kayıt silme işlemi
            go_controller->gv_mode = 'D'.

            gv_title_dynamic = 'Kayıt Silme Paneli'.

            CLEAR: gv_bukrs, gv_user_id, gv_name,
             gv_surname, gv_birth_date, gv_salary.

            " Ekranı ilk haline getir
            go_controller->gv_veri_geldi = abap_false.

            CALL SCREEN 0200.

          WHEN '&UPDATE'.
            " Kayıt güncelleme işlemi
            go_controller->gv_mode = 'U'.

            gv_title_dynamic = 'Update Ekranı'.

            CLEAR: gv_bukrs, gv_user_id, gv_name,
              gv_surname, gv_birth_date, gv_salary.

            " Ekranı ilk haline getir
            go_controller->gv_veri_geldi = abap_false.

            CALL SCREEN 0200.

          WHEN '&REPORT'.
            " Rapor işlemi
            gv_title_dynamic = 'Rapor Ekranı'.

            CALL SCREEN 0300.
        ENDCASE.
      ENDIF.

    WHEN '&MNT'.
      DATA: lv_viewcluster TYPE vcldir-vclname VALUE 'ZGZ_CV_SCREEN002'.

      gv_title_dynamic = 'Bakım Tabloları'.

      CALL FUNCTION 'VIEWCLUSTER_MAINTENANCE_CALL'
        EXPORTING
          viewcluster_name   = lv_viewcluster
          maintenance_action = 'U'
        EXCEPTIONS
          OTHERS             = 16.
      IF sy-subrc <> 0.
        MESSAGE 'Çağırılamadı!' TYPE 'E'.
      ENDIF.

    WHEN '&BACK' OR '&EXIT' OR '&CANCEL'.
      "SET SCREEN 0.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  CASE sy-ucomm.
    WHEN '&USER_INSERT'.
      " Zorunlu alan
      IF gv_bukrs  IS INITIAL OR gv_user_id IS INITIAL OR gv_user_id IS INITIAL OR gv_salary  IS INITIAL.
        MESSAGE 'Şirket kodu,Kullanıcı Id,Ad ve Maaş alanı zorunludur!' TYPE 'W'.
      ELSE.

        gv_check_ok = abap_true.

        "hiçbir boşluk kalmadı
        CONDENSE gv_user_id NO-GAPS.

        go_controller->check_company( ).
        IF gv_check_ok = abap_false.
          RETURN.
        ENDIF.

        go_controller->check_user_existence( ).
        IF gv_check_ok = abap_false.
          RETURN.
        ENDIF.

        go_controller->check_birth_date( ).
        IF gv_check_ok = abap_false.
          RETURN.
        ENDIF.

        go_controller->check_salary( ).
        IF gv_check_ok = abap_false.
          RETURN.
        ENDIF.

        go_controller->create_log_entry( ).
        IF gv_check_ok = abap_false.
          RETURN.
        ENDIF.
      ENDIF.

      " get,Kayıt Sil için veri getir
    WHEN '&GET'.
      IF go_controller->gv_mode = 'I'.
        IF gv_bukrs IS NOT INITIAL OR gv_user_id IS NOT INITIAL OR gv_name IS NOT INITIAL.

          CONDENSE gv_user_id NO-GAPS.

          go_controller->fetch_log_entry( ).
        ELSE.
          MESSAGE 'Şirket Kodu,Kullanıcı Id ve Kullanıcı Adı zorunludur!' TYPE 'W'.
          RETURN.
        ENDIF.

      ELSEIF go_controller->gv_mode = 'U'.
        IF gv_bukrs IS NOT INITIAL OR gv_user_id IS  NOT INITIAL.

          CONDENSE gv_user_id NO-GAPS.

          go_controller->fetch_log_entry( ).
        ELSE.
          MESSAGE 'Şirket kodu ve Kullanıcı Id zorunludur!' TYPE 'W'.
          RETURN.
        ENDIF.

      ELSEIF go_controller->gv_mode = 'D'.
        IF gv_bukrs IS NOT INITIAL OR gv_user_id IS  NOT INITIAL.

          CONDENSE gv_user_id NO-GAPS.

          go_controller->fetch_log_entry( ).
        ELSE.
          MESSAGE 'Şirket kodu ve Kullanıcı Id zorunludur!' TYPE 'W'.
          RETURN.
        ENDIF.
      ENDIF.

      "Kayıt sil
    WHEN '&UDELETE'.
      go_controller->delete_log_entry( ).

      " Yenile
    WHEN '&REGISTER'.
      IF go_controller->gv_mode = 'U'.
        IF screen-group1 EQ 'COM' OR screen-group1 EQ 'USR'.
          screen-input = 1.
          MODIFY SCREEN.
        ENDIF.
        go_controller->gv_veri_geldi = abap_false.
      ENDIF.

      IF go_controller->gv_mode = 'D'.
        go_controller->gv_veri_geldi = abap_false.
      ENDIF.

*      " Kilidi aç
      CALL FUNCTION 'DEQUEUE_EZGZ_LN_USER'
        EXPORTING
          user_id = gv_user_id.

      CLEAR: gv_bukrs, gv_user_id, gv_name,
            gv_surname, gv_birth_date, gv_salary.

      " KAYIT GÜNCELLE
    WHEN '&UUPDATE'.
      " Kayıt ekle ekranındaki kontroller
      gv_check_ok = abap_true.

      go_controller->check_company( ).
      IF gv_check_ok = abap_false.
        RETURN.
      ENDIF.

      go_controller->check_birth_date( ).
      IF gv_check_ok = abap_false.
        RETURN.
      ENDIF.

      go_controller->check_salary( ).
      IF gv_check_ok = abap_false.
        RETURN.
      ENDIF.

      go_controller->update_log_entry( ).

      "50 arttır
    WHEN '&INCREASE'.
      gv_salary = gv_salary + 50.

      "50 azalt
    WHEN '&DECREASE'.
      IF gv_salary - 50 < 50.
        MESSAGE 'Maaş 50 den az olamaz!' TYPE 'W'.
      ELSE.
        gv_salary = gv_salary - 50.
      ENDIF.

    WHEN '&RPR'.
      go_controller->gv_mode = 'R'.

      CALL SCREEN 0300.

    WHEN '&BACK' OR '&EXIT' OR '&CANCEL'.
      " Kilidi aç
      CALL FUNCTION 'DEQUEUE_EZGZ_LN_USER'
        EXPORTING
          user_id = gv_user_id.

      LEAVE TO SCREEN 0100.


  ENDCASE.
ENDMODULE.


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.
  CASE sy-ucomm.
    WHEN '&REFRESH'.
      CLEAR gv_bukrs.

      IF go_docking IS NOT INITIAL.
        go_docking->free( ).
        FREE go_docking.
        FREE go_alv.
      ENDIF.

    WHEN '&GET'.
      IF gv_bukrs IS INITIAL.
        MESSAGE 'Şirket kodu zorunludur!' TYPE 'W'.
        RETURN.
      ENDIF.

      " Şirket kodu bakım tablosunda var mı
      SELECT SINGLE situation
        FROM zgz_tb_company
        INTO @DATA(lv_status)
        WHERE company_code = @gv_bukrs.

      IF sy-subrc <> 0.
        IF go_docking IS NOT INITIAL.
          go_docking->free( ).
          FREE go_docking.
          FREE go_alv.
        ENDIF.

        MESSAGE 'Şirket kodu bulunamadı!' TYPE 'W'.
        RETURN.
      ENDIF.

      go_controller->show_report( ).

    WHEN '&BACK' OR '&EXIT' OR '&CANCEL'.
      LEAVE TO SCREEN 0100.
  ENDCASE.
ENDMODULE.

MODULE f4_user_id INPUT.
  go_controller->search_help_user_id( ).
ENDMODULE.
