*&---------------------------------------------------------------------*
*& Include          ZGZ_I_SAS_GELISIM_TOP
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* TABLES DEFINITIONS
*----------------------------------------------------------------------*
TABLES: eban, ekko, ekpo, lfa1.

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


*----------------------------------------------------------------------*
* SELECTION SCREEN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  " EBAN Alanları
  SELECT-OPTIONS: s_banfn  FOR eban-banfn,               " SAT no
                  s_bsart  FOR eban-bsart.               " SAT Belge Türü (EBAN-BSART)

  " EKKO Alanları
  SELECT-OPTIONS: s_ekgrp  FOR ekko-ekgrp,               " Satın alma Grubu
                  s_ebsart FOR ekko-bsart,               " SAS Belge Türü
                  s_aedat  FOR ekko-aedat,               " SAS Yaratma Tarihi
                  s_ebeln  FOR ekko-ebeln,               " Satınalma Siparişi
                  s_ernam  FOR ekko-ernam,               " SAS Yaratan
                  s_procst FOR ekko-procstat.           " SAS Onay Durumu

  " EKPO Alanları
  SELECT-OPTIONS: s_knttp  FOR ekpo-knttp,               " Hesap Tayin Tipi
                  s_matnr  FOR ekpo-matnr,               " Malzeme
                  s_lifnr  FOR lfa1-lifnr,               " Satıcı (EKPO-LIFNR / LFA1-LIFNR)
                  s_lgort  FOR ekpo-lgort,               " Depo Yeri
                  s_matkl  FOR ekpo-matkl.               " Mal Grubu

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  " Checkbox Alanı
  PARAMETERS: p_loekz AS CHECKBOX DEFAULT 'X'.           " Silme İşareti Olanları Gizle

SELECTION-SCREEN END OF BLOCK b2.
