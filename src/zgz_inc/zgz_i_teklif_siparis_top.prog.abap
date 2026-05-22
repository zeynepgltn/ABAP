*&---------------------------------------------------------------------*
*& Include          ZGZ_I_TEKLIF_SIPARIS_TOP
*&---------------------------------------------------------------------*
CLASS cl_main DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_vbak,
             selkz        TYPE char1,
             vbeln        TYPE vbak-vbeln,
             kunnr        TYPE vbak-kunnr,
             vkorg        TYPE vbak-vkorg,
             vtweg        TYPE vbak-vtweg,
             spart        TYPE vbak-spart,
             netwr        TYPE vbak-netwr,
             waerk        TYPE vbak-waerk,
             angdt        TYPE vbak-angdt,
             bnddt        TYPE vbak-bnddt,
             gbstk        TYPE vbak-gbstk,
             teklif_notu  TYPE tdline,
             siparis_no   TYPE vbak-vbeln,
             siparis_notu TYPE tdline,
             line_color   TYPE char4,
             style        TYPE lvc_t_styl,
           END OF ty_vbak.

    "alvler
    DATA: "mt_alv        TYPE TABLE OF zgz_s_teklif_siparis,
      mt_alv        TYPE TABLE OF ty_vbak,
      ms_layout     TYPE lvc_s_layo,
      mt_fcat       TYPE lvc_t_fcat,
      mo_alv        TYPE REF TO cl_gui_alv_grid,
      mo_container  TYPE REF TO cl_gui_docking_container,
      mo_splitter   TYPE REF TO cl_gui_splitter_container,
      mo_sub_top    TYPE REF TO cl_gui_container,
      mo_sub_bottom TYPE REF TO cl_gui_container.

    DATA: mt_kalem         TYPE TABLE OF zgz_s_kalem,
          mt_fcat2         TYPE lvc_t_fcat,
          mo_alv2          TYPE REF TO cl_gui_alv_grid,
          mv_current_vbeln TYPE vbeln_va,
          mv_bottom_open   TYPE abap_bool.

    "pop uplar
    DATA: mo_popup_container TYPE REF TO cl_gui_custom_container,
          mo_alv_popup       TYPE REF TO cl_gui_alv_grid,
          mt_popup           TYPE TABLE OF zgz_s_popup,
          mt_fcat_popup      TYPE lvc_t_fcat,
          mv_popup_mode      TYPE char1.   " 'C' = create, 'U' = update

    CLASS-METHODS:
      create_instance RETURNING VALUE(r_obj) TYPE REF TO cl_main.

    "alvler
    METHODS:
      run,
      check_selection,
      read_data EXCEPTIONS no_data_found,
      pbo  IMPORTING VALUE(iv_dynnr) TYPE syst_dynnr,
      pai,
      fcat
        IMPORTING iv_struct TYPE tabname,
      load_kalem_data,

      "pop up
      open_popup,
      handle_data_changed_popup
        FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING er_data_changed,

      calc_siparis_miktar
        IMPORTING iv_vbeln         TYPE vbeln
                  iv_posnr         TYPE posnr
        RETURNING VALUE(rv_miktar) TYPE kwmeng,

      calc_acik_miktar
        IMPORTING iv_kwmeng         TYPE kwmeng
                  iv_siparis_miktar TYPE kwmeng
        RETURNING VALUE(rv_miktar)  TYPE kwmeng,
      "sipariş oluşturma
      create_orders,
      update_orders,

      "TEXTLER
      read_text_short
        IMPORTING iv_vbeln       TYPE vbeln
        RETURNING VALUE(rv_text) TYPE tdline,
      transfer_text
        IMPORTING iv_teklif_vbeln  TYPE vbeln
                  iv_siparis_vbeln TYPE vbeln,
      save_siparis_notu
        IMPORTING iv_siparis_vbeln TYPE vbeln
                  iv_not           TYPE tdline,

      "mail
      send_mail
        IMPORTING iv_teklif_vbeln  TYPE vbeln
                  iv_siparis_vbeln TYPE vbeln,

      "Event Handler
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,

      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,

      handle_data_changed_main FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING er_data_changed.

*      handle_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
*        IMPORTING e_row_id e_column_id.

  PRIVATE SECTION.
    CLASS-DATA: mo_instance TYPE REF TO cl_main.
ENDCLASS.

DATA go_obj TYPE REF TO cl_main.

TABLES: vbak.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_vbeln TYPE vbak-vbeln,
              p_kunnr TYPE vbak-kunnr OBLIGATORY.

  SELECT-OPTIONS: s_tarih FOR vbak-angdt OBLIGATORY. " Tek bir aralık alanı

  PARAMETERS: p_vkorg TYPE vbak-vkorg,
              p_vtweg TYPE vbak-vtweg,
              p_spart TYPE vbak-spart.
SELECTION-SCREEN  END OF BLOCK b1.
