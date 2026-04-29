*&---------------------------------------------------------------------*
*& Include          ZGZ_SCR002_PBO
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '0100'.

*  IF gv_title_dynamic IS INITIAL.
  gv_title_dynamic = 'Ana Ekran'.
*  ENDIF.

  SET TITLEBAR 'T100' WITH gv_title_dynamic.
  go_controller->get_user_info( ).

  IF go_controller->gv_user_exists  = abap_true.
    "Kayıt var
    LOOP AT SCREEN.
      IF screen-group1 EQ 'X'.
        screen-active = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
    "Kayıt yok
    LOOP AT SCREEN.
      IF screen-group1 EQ 'X'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDMODULE.



*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  SET PF-STATUS '0100'.

  IF gv_title_dynamic IS INITIAL.
    gv_title_dynamic = 'Ana Ekran'.
  ENDIF.

  SET TITLEBAR 'T100' WITH gv_title_dynamic.

  " Tarih alanına günün tarihi
  IF gv_birth_date IS INITIAL.
    gv_birth_date = sy-datum.
  ENDIF.

  LOOP AT SCREEN.
    IF go_controller->gv_mode = 'I'.
      " INSERT moduyla geldiyse Getir ve Kayıt Sil gizle
      IF screen-group1 = 'GET' OR screen-group1 = 'DEL'  OR screen-group1 = 'REF' OR screen-group1 = 'DEC'  OR screen-group1 = 'INC'
        OR screen-group1 = 'UPD'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-group1 = 'INS'.
        screen-active = 1.
        MODIFY SCREEN.
      ENDIF.

    ELSEIF go_controller->gv_mode = 'D'.
      " DELETE moduyla geldiyse  Kayıt Ekle gizle
      IF screen-group1 = 'INS'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF screen-group1 = 'DEC'  OR screen-group1 = 'INC'  OR screen-group1 = 'UPD'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      "ıd ve sirket kodu dışındaki alanları değiştirmeye kapatma
      IF screen-group1 = 'NAM' OR screen-group1 = 'SUR'  OR screen-group1 = 'BIR'  OR screen-group1 = 'SAL'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      " Veri gelmeden Kayıt Sil gizli
      IF screen-group1 = 'DEL' OR screen-group1 = 'REF'.
        IF go_controller->gv_veri_geldi = abap_false.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

      " Veri gelince Getir gizli
      IF screen-group1 = 'GET'.
        IF go_controller->gv_veri_geldi = abap_true.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

    ELSEIF go_controller->gv_mode = 'U'.
      " Kayıt Ekle, Kayıt Sil gizle
      IF screen-group1 = 'INS' OR screen-group1 = 'DEL'  OR screen-group1 = 'UPD'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF  go_controller->gv_veri_geldi = abap_false.
        " Veri gelmedi: Güncelle, 50arttır, 50azalt pasif
        IF screen-group1 = 'REF' OR screen-group1 = 'INC' OR screen-group1 = 'DEC' OR screen-group1 = 'NAM' OR screen-group1 = 'SUR'
        OR screen-group1 = 'BIR' OR screen-group1 = 'SAL'..
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.

      ELSE.
        " Veri geldi: Getir pasif, Güncelle/50arttır/50azalt aktif
        IF screen-group1 = 'GET'.
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.

        IF screen-group1 = 'REF' OR screen-group1 = 'INC' OR screen-group1 = 'DEC'  OR screen-group1 = 'UPD' OR screen-group1 = 'NAM'
        OR screen-group1 = 'SUR' OR screen-group1 = 'BIR' OR screen-group1 = 'SAL'..
          screen-input = 1.
          MODIFY SCREEN.
        ENDIF.

        " Şirket kodu ve Kullanıcı Id output olacak
        IF screen-group1 = 'COM' OR screen-group1 = 'USR'.
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module STATUS_0300 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS '0100'.

  IF gv_title_dynamic IS INITIAL.
    gv_title_dynamic = 'Ana Ekran'.
  ENDIF.

  SET TITLEBAR 'T100' WITH gv_title_dynamic.
ENDMODULE.
