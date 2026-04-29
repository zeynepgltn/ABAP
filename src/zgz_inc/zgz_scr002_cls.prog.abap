*&---------------------------------------------------------------------*
*& Include          ZGZ_SCR002_CLS
*&---------------------------------------------------------------------*

CLASS lcl_controller IMPLEMENTATION.
  METHOD get_user_info.
    "bakım tablosu user var mı
    SELECT SINGLE @abap_true
    FROM zgz_t_users
    INTO @DATA(lv_var)
    WHERE users = @sy-uname.

    IF sy-subrc = 0.
      me->gv_user_exists = abap_true.
    ELSE.
      me->gv_user_exists = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD get_user_status.
    " bakım tablosunda aktif mi
    SELECT SINGLE situation
      FROM zgz_t_users
      INTO me->gv_user_status
      WHERE users = sy-uname.
  ENDMETHOD.

  METHOD check_company.
    "Şirket kodu var ve aktif (bakım da)
    SELECT SINGLE situation
      FROM zgz_tb_company
      INTO @gv_company_status
      WHERE company_code = @gv_bukrs.

    IF sy-subrc <> 0.
      MESSAGE 'Şirket kodu bakım tablosunda bulunamadı!' TYPE 'W'.
      gv_check_ok = abap_false.
    ELSEIF gv_company_status <> 'X'.
      MESSAGE 'Şirket kodu pasif durumdadır!' TYPE 'W'.
      gv_check_ok = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD  check_user_existence.
    "Kayıt daha önce var mı
    SELECT SINGLE @abap_true
         FROM zgz_t_user_log
         INTO @DATA(lv_mevcut)
         WHERE user_id = @gv_user_id.

    IF sy-subrc = 0.
      MESSAGE 'Bu kullanıcı zaten kayıtlıdır!' TYPE 'W'.
      gv_check_ok = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD  check_birth_date.
    "goğum tarihi
    DATA lv_yas TYPE i.

    IF gv_birth_date IS NOT INITIAL.
      CALL FUNCTION 'COMPUTE_YEARS_BETWEEN_DATES'
        EXPORTING
          first_date                  = gv_birth_date
*         MODIFY_INTERVAL             = ' '
          second_date                 = sy-datum
        IMPORTING
          years_between_dates         = lv_yas
        EXCEPTIONS
          sequence_of_dates_not_valid = 1
          OTHERS                      = 2.

      IF lv_yas < 18.
        MESSAGE 'Kullanıcının yaşı 18 den küçük olamaz!' TYPE 'W'.
        gv_check_ok = abap_false.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD check_salary.
    " Maaş kontrolü
    IF  gv_salary  <= 0.
      MESSAGE 'Maaş sıfır veya negatif olamaz!' TYPE 'W'.
      gv_check_ok = abap_false.
    ELSEIF me->gv_mode = 'U' AND gv_salary  < 50.
      MESSAGE 'Maaş 50den küçük olamaz!' TYPE 'W'.
      gv_check_ok = abap_false.
    ENDIF.
  ENDMETHOD.

  METHOD create_log_entry.
    "Log Tablosuna kullanıcı kaydı at
    DATA: ls_log TYPE zgz_t_user_log .

    "ls_log-mandt        = sy-mandt.
    ls_log-company_code  = gv_bukrs.
    ls_log-user_id = gv_user_id.
    ls_log-name     = gv_name.
    ls_log-surname = gv_surname.
    ls_log-birth_date  = gv_birth_date.
    ls_log-salary   = gv_salary.

    INSERT zgz_t_user_log FROM ls_log.

    IF sy-subrc <> 0.
      MESSAGE 'Kayıt eklenirken hata oluştu!' TYPE 'W'.
      gv_check_ok = abap_false.

      CLEAR: gv_bukrs,
             gv_user_id,
             gv_name,
             gv_surname,
             gv_birth_date,
             gv_salary.

    ELSE.
      me->update_company_status( ).

      SET SCREEN 0.
    ENDIF.
  ENDMETHOD.

  METHOD update_company_status.
    "  Şirket tablosunu güncelle Çalışan sayısını 1 arttır Aylık maaş hacmine maaşı ekle
    " Önce mevcut değeri oku "SET f = f + 1 sözdizimi sadece sayısal tiplerle (P, F, I) çalış
    SELECT SINGLE workers
      FROM zgz_t_company
      INTO @DATA(lv_workers)
      WHERE company_code = @gv_bukrs.

    lv_workers = lv_workers + 1.

    " Sonra güncelle
    UPDATE zgz_t_company
      SET workers = @lv_workers,
          salaries = salaries + @gv_salary
      WHERE company_code = @gv_bukrs.

    IF sy-subrc <> 0.
      MESSAGE 'Şirket tablosu güncellenirken hata oluştu!' TYPE 'W'.
    ELSE.
      MESSAGE 'Kayıt başarıyla eklendi ve çalışan,maaş değerleri başarı ile güncellendi.' TYPE 'S'.
    ENDIF.

    COMMIT WORK AND WAIT.
  ENDMETHOD.

  METHOD fetch_log_entry.
    " Önce kilitle
    CALL FUNCTION 'ENQUEUE_EZGZ_LN_USER'
      EXPORTING
        user_id      = gv_user_id
      EXCEPTIONS
        foreign_lock = 1
        OTHERS       = 2.

    IF sy-subrc = 1.
      MESSAGE 'Bu kayıt başka bir kullanıcı tarafından güncelleniyor!' TYPE 'W'.
      RETURN.
    ENDIF.

    "kullanıcı getir
    SELECT SINGLE name surname birth_date salary
      FROM zgz_t_user_log
      INTO (gv_name, gv_surname, gv_birth_date, gv_salary)
      WHERE company_code   = gv_bukrs
        AND user_id = gv_user_id.

    IF sy-subrc <> 0.
      " Kayıt bulunamadıysa kilidi aç
      CALL FUNCTION 'DEQUEUE_EZGZ_LN_USER'
        EXPORTING
          user_id = gv_user_id.
      MESSAGE 'Kayıt bulunamadı!' TYPE 'W'.
      RETURN.
    ELSE.

      " Eski değerleri sakla (güncelleme karşılaştırması için)
      me->gv_old_name       = gv_name.
      me->gv_old_surname    = gv_surname.
      me->gv_old_birth_date = gv_birth_date.
      me->gv_old_salary     = gv_salary.

      gv_veri_geldi = abap_true.
      MESSAGE 'Kayıt bulundu.' TYPE 'S'.
    ENDIF.
  ENDMETHOD.

  METHOD delete_log_entry.
    "kullanıci sil
    DATA: lv_maas    TYPE dmbtr,
          lv_workers TYPE char10.

    " Silinecek kaydın maaşı
    lv_maas = gv_salary.

    " Log tablosundan sil
    DELETE FROM zgz_t_user_log
      WHERE company_code   = gv_bukrs
        AND user_id = gv_user_id.

    IF sy-subrc <> 0.
      MESSAGE 'Silme hatası!' TYPE 'W'.
    ENDIF.

    " Şirket tablosunu güncelle
    SELECT SINGLE workers
      FROM zgz_t_company
      INTO lv_workers
      WHERE company_code = gv_bukrs.

    lv_workers = lv_workers - 1.

    UPDATE zgz_t_company
      SET workers    = lv_workers
          salaries = salaries - lv_maas
      WHERE company_code = gv_bukrs.

    COMMIT WORK AND WAIT.

    MESSAGE 'Kayıt başarıyla silindi.' TYPE 'S'.
    LEAVE TO SCREEN 0100.
  ENDMETHOD.

  METHOD update_log_entry.
    "kayıt güncelle
    IF gv_name       = me->gv_old_name
       AND gv_surname    = me->gv_old_surname
       AND gv_birth_date = me->gv_old_birth_date
       AND gv_salary     = me->gv_old_salary.
      MESSAGE 'Herhangi bir değişiklik yapılmadı!' TYPE 'W'.
    ELSE.
      DATA: lv_maas_fark TYPE dmbtr.

      " Maaş farkını hesapla
      lv_maas_fark = gv_salary - me->gv_old_salary.

      " Log tablosunu güncelle
      UPDATE zgz_t_user_log
        SET name       = gv_name
            surname    = gv_surname
            birth_date = gv_birth_date
            salary     = gv_salary
        WHERE company_code = gv_bukrs
          AND user_id     = gv_user_id.

      IF sy-subrc <> 0.
        MESSAGE 'Güncelleme hatası!' TYPE 'W'.
      ELSE.
        " Şirket tablosunu güncelle
        SELECT SINGLE workers
          FROM zgz_t_company
          INTO @DATA(lv_workers)
          WHERE company_code = @gv_bukrs.

        UPDATE zgz_t_company
          SET salaries = salaries + @lv_maas_fark
          WHERE company_code = @gv_bukrs.

        COMMIT WORK AND WAIT.

        MESSAGE 'Kayıt başarıyla güncellendi.' TYPE 'S'.

        " Kilidi aç
        CALL FUNCTION 'DEQUEUE_EZGZ_LN_USER'
          EXPORTING
            user_id = gv_user_id.

        MESSAGE 'Kayıt başarıyla güncellendi.' TYPE 'S'.

        " Ekranı ilk haline getir
        gv_veri_geldi = abap_false.

        CLEAR: gv_bukrs, gv_user_id, gv_name, gv_surname,
               gv_birth_date, gv_salary,
               me->gv_old_name, me->gv_old_surname,
               me->gv_old_birth_date, me->gv_old_salary.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD show_report.
    DATA: lt_fcat TYPE lvc_t_fcat.

    SELECT *
      FROM zgz_t_user_log
      INTO TABLE gt_log
      WHERE company_code = gv_bukrs.

    IF go_docking IS NOT INITIAL.
      go_docking->free( ).
      FREE go_docking.
      FREE go_alv.
    ENDIF.

    IF sy-subrc <> 0.
      MESSAGE 'Bu şirkete ait kayıt bulunamadı!' TYPE 'W'.

      RETURN.
    ENDIF.

    IF go_docking IS INITIAL.
      CREATE OBJECT go_docking
        EXPORTING
          side      = cl_gui_docking_container=>dock_at_bottom
          extension = 200.

      CREATE OBJECT go_alv
        EXPORTING
          i_parent = go_docking.

      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name = 'ZGZ_T_USER_LOG'
        CHANGING
          ct_fieldcat      = lt_fcat.

      go_alv->set_table_for_first_display(
        EXPORTING
          i_structure_name = 'ZGZ_T_USER_LOG'
        CHANGING
          it_outtab        = gt_log
          it_fieldcatalog  = lt_fcat ).
    ELSE.
      " zaten varsa
      go_alv->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.

  METHOD search_help_user_id.
    DATA: lt_return TYPE TABLE OF ddshretval,
          lt_users  TYPE TABLE OF ty_user,
          lt_dynp   TYPE TABLE OF dynpread,    "DYNP_VALUES_READ için
          ls_dynp   TYPE dynpread.
    "lt_dynpupdate TYPE TABLE OF dynpread.    "DYNP_VALUES_UPDATE için

    CHECK me->gv_mode = 'U' OR gv_mode = 'D'.

*    " Ekrandan GV_BUKRS değeri
    ls_dynp-fieldname = 'GV_BUKRS'.
    APPEND ls_dynp TO lt_dynp.

    CALL FUNCTION 'DYNP_VALUES_READ'
      EXPORTING
        dyname               = sy-repid
        dynumb               = '0200'
*       TRANSLATE_TO_UPPER   = ' '
*       REQUEST              = ' '
*       PERFORM_CONVERSION_EXITS             = ' '
*       PERFORM_INPUT_CONVERSION             = ' '
*       DETERMINE_LOOP_INDEX = ' '
*       START_SEARCH_IN_CURRENT_SCREEN       = ' '
*       START_SEARCH_IN_MAIN_SCREEN          = ' '
*       START_SEARCH_IN_STACKED_SCREEN       = ' '
*       START_SEARCH_ON_SCR_STACKPOS         = ' '
*       SEARCH_OWN_SUBSCREENS_FIRST          = ' '
*       SEARCHPATH_OF_SUBSCREEN_AREAS        = ' '
      TABLES
        dynpfields           = lt_dynp
      EXCEPTIONS
        invalid_abapworkarea = 1
        invalid_dynprofield  = 2
        invalid_dynproname   = 3
        invalid_dynpronummer = 4
        invalid_request      = 5
        no_fielddescription  = 6
        invalid_parameter    = 7
        undefind_error       = 8
        double_conversion    = 9
        stepl_not_found      = 10
        OTHERS               = 11.
    IF sy-subrc <> 0.
      MESSAGE 'Parametreler okunamadı.' TYPE 'W' DISPLAY LIKE 'E'.
    ENDIF.

    READ TABLE lt_dynp INTO ls_dynp INDEX 1.
    DATA(lv_bukrs) = ls_dynp-fieldvalue.

    " Şirket kodu doluysa filtrele
    IF lv_bukrs IS NOT INITIAL.
      SELECT user_id,
        company_code
        FROM zgz_t_user_log
        INTO TABLE @lt_users
        WHERE company_code = @lv_bukrs.
    ELSE.
      SELECT user_id,
        company_code
        FROM zgz_t_user_log
        INTO TABLE @lt_users.
    ENDIF.

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'USER_ID'
        dynpprog        = sy-repid
        dynpnr          = sy-dynnr
        dynprofield     = 'GV_USER_ID'
        value_org       = 'S'
      TABLES
        value_tab       = lt_users
        return_tab      = lt_return
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      MESSAGE 'F4 yardımında problem.' TYPE 'W' DISPLAY LIKE 'E'.
    ENDIF.

    "tablo dolduysa
    IF lt_return IS NOT INITIAL.
      " Seçilen user_id'yi bul
      READ TABLE lt_return INTO DATA(ls_return) INDEX 1.
      gv_user_id = ls_return-fieldval.

      " Seçilen kullanıcının company_code'unu bul
      READ TABLE lt_users INTO DATA(ls_user)
        WITH KEY user_id = gv_user_id.
      IF sy-subrc = 0.
        gv_bukrs = ls_user-company_code.

        CLEAR lt_dynp.
        " Önce tablo
        lt_dynp = VALUE #(
          ( fieldname = 'GV_USER_ID' fieldvalue = |{ gv_user_id }| )
          ( fieldname = 'GV_BUKRS'   fieldvalue = |{ gv_bukrs }| )
        ).

        " Ekran alanlarını güncelle
        CALL FUNCTION 'DYNP_VALUES_UPDATE'
          EXPORTING
            dyname               = sy-repid
            dynumb               = '0200'
          TABLES
            dynpfields           = lt_dynp
          EXCEPTIONS
            invalid_abapworkarea = 1
            invalid_dynprofield  = 2
            invalid_dynproname   = 3
            invalid_dynpronummer = 4
            invalid_request      = 5
            no_fielddescription  = 6
            undefind_error       = 7
            OTHERS               = 8.
        IF sy-subrc <> 0.
          MESSAGE 'Güncelleme yapılamadı.' TYPE 'W' DISPLAY LIKE 'E'.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
