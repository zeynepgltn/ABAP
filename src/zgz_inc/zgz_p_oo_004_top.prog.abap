*&---------------------------------------------------------------------*
*& Include          ZGZ_P_OO_004_TOP
*&---------------------------------------------------------------------*
TABLES: vbak.

TYPES: BEGIN OF gty_vbak,
         vbeln TYPE vbeln,
         datum TYPE datum,
         usnam TYPE usnam,
       END OF gty_vbak.

TYPES: ty_belgen TYPE RANGE OF vbak-vbeln. "parametre için type

DATA: gt_vbak   TYPE TABLE OF gty_vbak,
      gt_fcat   TYPE lvc_t_fcat,
      gs_layout TYPE lvc_s_layo,
      gt_vbap   TYPE TABLE OF vbap,
      gt_fcatt  TYPE lvc_t_fcat.

FIELD-SYMBOLS: <gfs_fc> TYPE lvc_s_fcat.

DATA: go_cont          TYPE REF TO cl_gui_docking_container,
      go_splitter      TYPE REF TO cl_gui_splitter_container,
      go_sub_left      TYPE REF TO cl_gui_container,
      go_sub_right     TYPE REF TO cl_gui_container,
      go_alv           TYPE REF TO cl_gui_alv_grid,
      go_alvv          TYPE REF TO cl_gui_alv_grid,
      gv_right_open    TYPE abap_bool,
      gv_current_vbeln TYPE vbeln_va.

CLASS cl_controller DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      create_instance RETURNING VALUE(r_obj) TYPE REF TO cl_controller.

    METHODS:
      get_data   IMPORTING it_belgen TYPE ty_belgen,
      initialization,
      pbo IMPORTING VALUE(iv_dynnr) TYPE syst_dynnr,
      pai,
      set_fieldcat,
      set_layout,
      display_alv.

    METHODS:
      handle_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_column_id es_row_no.
  PRIVATE SECTION.
    CLASS-DATA: mo_instance TYPE REF TO cl_controller.
ENDCLASS.


DATA go_obj TYPE REF TO cl_controller.

TABLES: mara.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_matnr FOR mara-matnr NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b1.
