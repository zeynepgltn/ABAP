*&---------------------------------------------------------------------*
*& Include          ZGZ_SCR002_TOP
*&---------------------------------------------------------------------*

"Title
DATA: gv_title_dynamic TYPE string.

"f4 type
TYPES: BEGIN OF ty_user,
         user_id      TYPE uname,
*             name         TYPE zgz_t_user_log-name,
*             surname      TYPE zgz_t_user_log-surname,
         company_code TYPE zgz_t_user_log-company_code,
       END OF ty_user.


CLASS lcl_controller DEFINITION.
  PUBLIC SECTION.
    " Mantıksal Kontrol Değişkenleri
    DATA: gv_user_exists    TYPE boolean VALUE abap_false,
          gv_user_status    TYPE c1,
          gv_company_exists TYPE boolean VALUE abap_false,
          gv_company_status TYPE c1.

    DATA: gv_veri_geldi TYPE abap_bool VALUE abap_false,
          gv_mode       TYPE c LENGTH 1.

    " Değişiklik var mı kontrol
    DATA: gv_old_name       TYPE char20,    "Eski değerleri sakla
          gv_old_surname    TYPE char20,
          gv_old_birth_date TYPE datum,
          gv_old_salary     TYPE dmbtr,
          gv_veri_geldi_upd TYPE abap_bool.

    " Ana Akış
    METHODS:
      get_user_info,
      get_user_status,
      check_company,
      check_user_existence,
      check_birth_date,
      check_salary,
      create_log_entry,
      update_company_status,
      fetch_log_entry,
      delete_log_entry,
      update_log_entry,
      search_help_user_id.

    METHODS: show_report.
ENDCLASS.

"nesnem
DATA: go_controller TYPE REF TO lcl_controller.

" Ekran Giriş Parametreleri
DATA: gv_bukrs      TYPE bukrs,
      gv_user_id    TYPE uname,
      gv_name       TYPE char20,
      gv_surname    TYPE char20,
      gv_birth_date TYPE datum,
      gv_salary     TYPE dmbtr.

DATA gv_check_ok TYPE boolean.

DATA: go_docking TYPE REF TO cl_gui_docking_container,
      go_alv     TYPE REF TO cl_gui_alv_grid,
      gt_log     TYPE TABLE OF zgz_t_user_log.
