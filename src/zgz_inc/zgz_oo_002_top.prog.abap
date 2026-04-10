*&---------------------------------------------------------------------*
*& Include          ZGZ_OO_002_TOP
*&---------------------------------------------------------------------*
TABLES: sscrfields.  " Standart seçim ekranı alanları için

TYPES: BEGIN OF ty_alv,
         selkz      TYPE char1,          " Seçim (Excel'de yok)
         vbeln      TYPE vbak-vbeln,     " Belge
         posnr      TYPE vbap-posnr,     " Kalem
         kdmat      TYPE vbap-kdmat,     " Müşteri malzemesi
         matnr      TYPE vbap-matnr,     " Malzeme
         maktx      TYPE makt-maktx,     " Malzeme kısa metni
         kunnr      TYPE kna1-kunnr,     " Müşteri
         kwmeng     TYPE vbap-kwmeng,    " Sipariş miktarı
         kbetr      TYPE prcd_elements-kbetr, " Tutar
         meins      TYPE char3,    " vbap-meins yerine
         "meins      TYPE vbap-meins, " Birim
         netwr      TYPE vbap-netwr,     " Net değer
         waerk      TYPE vbap-waerk,     " TÖB
         waers      TYPE prcd_elements-waers, " PB
         vkorg      TYPE vbak-vkorg,     " Satış org
         line_color TYPE char4,          " Renk (Excel'de yok)
       END OF ty_alv.

TYPES: BEGIN OF ty_alvv,
         ebeln TYPE ebeln,
         ebelp TYPE ebelp,
       END OF ty_alvv.

DATA: gt_alv  TYPE TABLE OF ty_alv,
      gs_alv  TYPE ty_alv,
      gt_alvv TYPE TABLE OF ty_alvv,
      gs_alvv TYPE ty_alvv.


FIELD-SYMBOLS:<gfs_alv> TYPE ty_alv,
              <gfs_fc>  TYPE lvc_s_fcat.

DATA: gt_fcat   TYPE lvc_t_fcat,
      gt_fcatt  TYPE lvc_t_fcat,
      gs_fcat   TYPE lvc_s_fcat,
      gs_fcatt  TYPE lvc_s_fcat,
      gs_layout TYPE lvc_s_layo.

DATA: go_cont     TYPE REF TO cl_gui_docking_container.

DATA: go_alv  TYPE REF TO cl_gui_alv_grid.

DATA: gs_variant TYPE disvariant.

DATA: go_title TYPE REF TO cl_dd_document.

DATA: gs_outputparams TYPE  sfpoutputparams,
      gv_funcname     TYPE  funcname,
      gs_docparams    TYPE  sfpdocparams,
      lt_keys         TYPE TABLE OF vbeln_va.

DATA: gt_sf TYPE zgz_ralvv, "Tablo tipi
      gs_sf TYPE zgz_ralv.

DATA: gt_header TYPE TABLE OF  zgz_s_sf2,
      gs_header TYPE  zgz_s_sf2.

DATA: gt_toplam TYPE TABLE OF  zgz_s_sf2,
      gs_toplam TYPE  zgz_s_sf2.

DATA: gv_filename    TYPE string, "dosya
      gv_path        TYPE string, "klasör
      gv_fullpath    TYPE string, "full yol
      gv_user_action TYPE i. "action.

DATA: gt_files TYPE filetable, "upload için
      gv_rc    TYPE i.


CLASS lcl_controller DEFINITION.
  PUBLIC SECTION.
    DATA gv_rb TYPE char1.

    " Ana Akış
    METHODS:
      start,
      get_data EXCEPTIONS no_data_found,
      set_fcat,
      set_layout,
      display_alv,
      get_adobeform,
      get_header.

    " Event Handler
    METHODS:
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,

      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.

    "Xstring methods
    METHODS:
      get_xstring
        IMPORTING
          it_data    TYPE REF TO data
          it_fcat    TYPE lvc_t_fcat
        EXPORTING
          ev_xstring TYPE xstring,

      read_xstring
        IMPORTING
          iv_filename TYPE string
        EXPORTING
          ev_xstring  TYPE xstring.

    " Excel Metotları
    METHODS:
      "get_excel,
      get_excell " parametreli
        IMPORTING  it_data      TYPE REF TO data OPTIONAL
                   it_fcat      TYPE lvc_t_fcat "VALUE(iv_filename) TYPE string OPTIONAL
        EXPORTING  "ev_file_path  TYPE string
                   ev_file_size TYPE i "VALUE(ev_xml)      TYPE xstring
                   "CHANGING   cv_filename   TYPE string
                   "RETURNING  VALUE(gt_alv) TYPE ty_alv
        EXCEPTIONS download_error.

    " Metod tanımı
    METHODS:
      excel_upload_cl.
*      IMPORTING
*        iv_rb TYPE char1.

    METHODS:
      send_mail
        IMPORTING
          iv_receiver TYPE ad_smtpadr
          iv_subject  TYPE so_obj_des.
ENDCLASS.


"CLASS lcl_controller DEFINITION DEFERRED.
DATA: go_controller TYPE REF TO lcl_controller.


SELECTION-SCREEN BEGIN OF BLOCK r1 WITH FRAME TITLE TEXT-004.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(3) ic1 FOR FIELD rb_1. "ikon 1
    PARAMETERS: rb_1 RADIOBUTTON GROUP grp1 USER-COMMAND rad.
    SELECTION-SCREEN COMMENT 9(25) txt_r1 FOR FIELD rb_1. "text 1
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(3) ic2 FOR FIELD rb_2. "ikon 2
    PARAMETERS: rb_2 RADIOBUTTON GROUP grp1 DEFAULT 'X'.
    SELECTION-SCREEN COMMENT 9(25) txt_r2 FOR FIELD rb_2. "text 2
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK r1.

SELECTION-SCREEN BEGIN OF BLOCK r2 WITH FRAME TITLE TEXT-005.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(12) txt_file.
    PARAMETERS: p_file TYPE rlgrap-filename VISIBLE LENGTH 20.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN SKIP 1.

  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN PUSHBUTTON 1(25) gv_btn1 USER-COMMAND sablond VISIBLE LENGTH 15.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK r2.
