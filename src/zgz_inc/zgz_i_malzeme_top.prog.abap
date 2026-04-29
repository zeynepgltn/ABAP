*&---------------------------------------------------------------------*
*& Include          ZGZ_I_MALZEME_TOP
*&---------------------------------------------------------------------*
DATA: gt_alv          TYPE TABLE OF zgz_s_malzeme,
      go_alv          TYPE REF TO cl_gui_alv_grid,
      go_docker       TYPE REF TO cl_gui_docking_container,
      gs_layout       TYPE lvc_s_layo,
      gv_satir_sayisi TYPE i.


FIELD-SYMBOLS: <gfs_fc>  TYPE lvc_s_fcat.

DATA: gt_fcat   TYPE lvc_t_fcat.

CLASS cl_controller DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      create_instance RETURNING VALUE(r_obj) TYPE REF TO cl_controller.

    METHODS:
      pbo,
      pai,
      set_fieldcat,
      set_layout,
      add_rows,
      bapi_kaydet.

    METHODS validate_row
      CHANGING  cs_alv       TYPE zgz_s_malzeme
      RETURNING VALUE(rv_ok) TYPE abap_bool.

    METHODS:
      handler_data_changed
        FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING er_data_changed,

      handler_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,

      handler_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.

  PRIVATE SECTION.
    CLASS-DATA: mo_instance TYPE REF TO cl_controller.
ENDCLASS.

DATA: go_obj TYPE REF TO cl_controller.
