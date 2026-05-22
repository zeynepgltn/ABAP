*&---------------------------------------------------------------------*
*& Include          ZGZ_P_TEKLIF_SIPARIS_TOP
*&---------------------------------------------------------------------*
CLASS cl_main DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_vbak,
             vbeln TYPE vbak-vbeln,
             kunnr TYPE vbak-kunnr,
             vkorg TYPE vbak-vkorg,
             vtweg TYPE vbak-vtweg,
             spart TYPE vbak-spart,
             netwr TYPE vbak-netwr,
             waerk TYPE vbak-waerk,
             angdt TYPE vbak-angdt,
             bnddt TYPE vbak-bnddt,
           END OF ty_vbak.

    DATA:
      mt_alv       TYPE ty_vbak,
      ms_layout    TYPE lvc_s_layo,
      mt_fcat      TYPE lvc_t_fcat,
      mo_container TYPE REF TO cl_gui_docking_container,
      mo_splitter  TYPE REF TO cl_gui_splitter_container,
      mo_sub_left  TYPE REF TO cl_gui_container,
      mo_sub_right TYPE REF TO cl_gui_container.


    CLASS-METHODS:
      create_instance RETURNING VALUE(r_obj) TYPE REF TO cl_main.

  PRIVATE SECTION.
    CLASS-DATA: mo_instance TYPE REF TO cl_main.
ENDCLASS.

DATA go_obj TYPE REF TO cl_main.

TABLES: vbak.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_vbeln TYPE vbak-vbeln,
              p_kunnr TYPE vbak-kunnr.

  SELECT-OPTIONS: s_tarih FOR vbak-angdt. " Tek bir aralık alanı

  PARAMETERS: p_vkorg TYPE vbak-vkorg,
              p_vtweg TYPE vbak-vtweg,
              p_spart TYPE vbak-spart.

  PARAMETERS p_waerk TYPE vbak-waerk AS LISTBOX VISIBLE LENGTH 20 DEFAULT 'TRY'.
SELECTION-SCREEN  END OF BLOCK b1.
