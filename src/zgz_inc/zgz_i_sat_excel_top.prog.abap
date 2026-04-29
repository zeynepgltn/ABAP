*&---------------------------------------------------------------------*
*& Include          ZGZ_I_SAT_EXCEL_TOP
*&---------------------------------------------------------------------*
TABLES: sscrfields.

CLASS cl_main DEFINITION.
  PUBLIC SECTION.
    CONSTANTS: gc_green  TYPE icon_d VALUE '@5B@',
               gc_yellow TYPE i_status VALUE '@09@',
               gc_red    TYPE icon_d VALUE '@5C@'.

    CLASS-METHODS:  "static methods
      create_instance RETURNING VALUE(r_obj) TYPE REF TO cl_main.

    TYPES:
      BEGIN OF ty_alv_data,
        selkz        TYPE char1,
        light        TYPE icon_d,
        bsart        TYPE bsart,
        header_text  TYPE text50,
        knttp        TYPE knttp,
        matnr        TYPE matnr,
        txz01        TYPE txz01,
        menge        TYPE bamng,
        lfdat        TYPE lfdat,
        afnam        TYPE afnam,
        werks        TYPE werks,
        lgort        TYPE lgort_d,
        item_text    TYPE text50,
        ekgrp        TYPE ekgrp,
        anln1        TYPE anln1,
        kostl        TYPE kostl,
        sakto        TYPE sakto,
        zzbeden      TYPE text50,
        zzplaka      TYPE text50,
        zzmasrafyeri TYPE text50,
        zzpyp        TYPE text50,
        ps_psp_pnr   TYPE ps_psp_pnr,
        banfn        TYPE banfn,
        messages     TYPE bapiret2_t,
      END OF ty_alv_data,
      tty_data TYPE TABLE OF ty_alv_data.

    DATA: mo_container TYPE REF TO cl_gui_docking_container,
          mo_grid      TYPE REF TO cl_gui_alv_grid,
          mt_alv_data  TYPE TABLE OF ty_alv_data,
          mt_fieldcat  TYPE lvc_t_fcat,
          ms_layout    TYPE lvc_s_layo,
          ms_variant   TYPE disvariant.

    METHODS:
      initialization,
      at_selection_screen,
      at_selection_screen_valreq IMPORTING iv_field TYPE clike,
      run,
      pbo,
      pai,
      excel_upload_cl,
      read_xstring IMPORTING iv_filename TYPE string
                   EXPORTING ev_xstring  TYPE xstring,
      excel_download EXCEPTIONS download_error,
      get_xstring IMPORTING it_data    TYPE REF TO data
                            it_fcat    TYPE lvc_t_fcat
                  EXPORTING ev_xstring TYPE xstring,
      call_pr_bapi.

    METHODS:
      handler_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_column_id es_row_no,
      handler_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object,
      handler_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.
    "show_messages IMPORTING it_messages TYPE bapiret2_t.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA: mo_instance TYPE REF TO cl_main.
ENDCLASS.

DATA go_obj TYPE REF TO cl_main.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(12) TEXT-002 .
    PARAMETERS: p_file TYPE rlgrap-filename VISIBLE LENGTH 20.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN SKIP 1.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN PUSHBUTTON 1(25) TEXT-003  USER-COMMAND sablond VISIBLE LENGTH 15.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.
