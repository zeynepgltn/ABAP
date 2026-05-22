*&---------------------------------------------------------------------*
*& Include          ZGZ_I_BOMCOPY_TOP
*&---------------------------------------------------------------------*
DATA: gv_satir_sayisi TYPE i,
      ok_code         TYPE sy-ucomm. "enter yakalama

FIELD-SYMBOLS: <gfs_fc>  TYPE lvc_s_fcat.

" SELECT için minimal tipler,sadece gerekli field'lar,for all entries için
TYPES: BEGIN OF ty_mara,
         matnr TYPE mara-matnr,
       END OF ty_mara.

TYPES: BEGIN OF ty_t001w,
         werks TYPE t001w-werks,
       END OF ty_t001w.

TYPES: BEGIN OF ty_mast,
         matnr TYPE mast-matnr,
         werks TYPE mast-werks,
         stlal TYPE mast-stlal,
       END OF ty_mast.

TYPES: BEGIN OF ty_marc,
         matnr TYPE marc-matnr,
         werks TYPE marc-werks,
       END OF ty_marc.

TYPES: BEGIN OF ty_sel_stlnr,
         stlnr TYPE stko-stlnr,
       END OF ty_sel_stlnr.

" Tablo tipleri
TYPES: tt_marc  TYPE STANDARD TABLE OF ty_marc  WITH DEFAULT KEY,
       tt_mara  TYPE STANDARD TABLE OF ty_mara  WITH DEFAULT KEY,
       tt_t001w TYPE STANDARD TABLE OF ty_t001w WITH DEFAULT KEY,
       tt_mast  TYPE STANDARD TABLE OF ty_mast  WITH DEFAULT KEY,
       tt_uruna TYPE STANDARD TABLE OF zgz_s_uruna  WITH DEFAULT KEY.

CLASS cl_controller DEFINITION.
  PUBLIC SECTION.
    DATA: mt_alv    TYPE TABLE OF zgz_s_uruna,
          mo_alv    TYPE REF TO cl_gui_alv_grid,
          mo_cont   TYPE REF TO cl_gui_docking_container,
          ms_layout TYPE lvc_s_layo,
          mt_fcat   TYPE lvc_t_fcat.

    CLASS-METHODS:
      create_instance RETURNING VALUE(r_obj) TYPE REF TO cl_controller.

    METHODS:
      pbo,
      pai,
      set_fcat,
      set_layout,
      add_rows,
      load_check_data
        RETURNING VALUE(rv_error) TYPE abap_bool,
      validate_all
        IMPORTING
                  it_selected     TYPE tt_uruna
                  it_mara         TYPE tt_mara
                  it_t001w_k      TYPE tt_t001w
                  it_t001w_y      TYPE tt_t001w
                  it_mast_k       TYPE tt_mast
                  it_mast_y       TYPE tt_mast
                  it_marc_y       TYPE tt_marc
        RETURNING VALUE(rv_error) TYPE abap_bool,
      cs_bom.

    METHODS:
      handler_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,

      handler_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,

      handler_data_changed FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING er_data_changed.

  PRIVATE SECTION.
    CLASS-DATA: mo_instance TYPE REF TO cl_controller.
ENDCLASS.

DATA: go_obj TYPE REF TO cl_controller.
