*&---------------------------------------------------------------------*
*& Include          ZGZ_RA_TOP
*&---------------------------------------------------------------------*
TYPE-POOLS: truxs.

TYPES: BEGIN OF ty_alv,
         vbeln  TYPE vbak-vbeln,
         posnr  TYPE vbap-posnr,
         kdmat  TYPE vbap-kdmat,
         matnr  TYPE vbap-matnr,
         maktx  TYPE makt-maktx,
         kunnr  TYPE kna1-kunnr,
         kwmeng TYPE vbap-kwmeng,
         kbetr  TYPE prcd_elements-kbetr,
         waers  TYPE prcd_elements-waers,
         netwr  TYPE vbap-netwr,
         waerk  TYPE vbap-waerk,
         vkorg  TYPE vbak-vkorg,
       END OF ty_alv.

TYPES: BEGIN OF ty_alv_display,
         selkz    TYPE xfeld,
         vbeln    TYPE vbak-vbeln,
         posnr    TYPE vbap-posnr,
         kdmat    TYPE vbap-kdmat,
         matnr    TYPE vbap-matnr,
         maktx    TYPE makt-maktx,
         kunnr    TYPE kna1-kunnr,
         kwmeng   TYPE vbap-kwmeng,
         kbetr    TYPE prcd_elements-kbetr,
         netwr    TYPE vbap-netwr,
         rowcolor TYPE c LENGTH 4,
       END OF ty_alv_display.

DATA: gt_alv         TYPE TABLE OF ty_alv,
      gs_alv         TYPE ty_alv,
      gt_alv_display TYPE TABLE OF ty_alv_display,  " ALV için
      gs_alv_display TYPE ty_alv_display.

DATA: gt_fcat TYPE slis_t_fieldcat_alv,
      gs_fcat TYPE slis_fieldcat_alv.

DATA: gs_layout TYPE slis_layout_alv.

DATA: fm_name TYPE rs38l_fnam.

DATA: ls_control_param  TYPE ssfctrlop,
      ls_composer_param TYPE ssfcompop.

DATA: gt_sf TYPE zgz_ralvv, "Tablo tipi
      gs_sf TYPE zgz_ralv.

DATA: lv_current_color TYPE char4 VALUE 'C301',
      lv_last_vbeln    TYPE vbeln.

DATA: gt_header TYPE TABLE OF  zgz_s_sf2,
      gs_header TYPE  zgz_s_sf2.

DATA: gt_toplam TYPE TABLE OF  zgz_s_sf2,
      gs_toplam TYPE  zgz_s_sf2.

DATA: gs_outputparams TYPE  sfpoutputparams,
      gv_name         TYPE  fpname,
      gv_funcname     TYPE  funcname,
      gs_docparams    TYPE  sfpdocparams,
      gs_formoutput   TYPE  fpformoutput,
      gv_barcode      TYPE char10.

DATA: ref_grid          TYPE REF TO cl_gui_alv_grid.

DATA: lt_keys TYPE TABLE OF vbeln_va.


DATA: gv_filename    TYPE string, "dosya
      gv_path        TYPE string, "klasör
      gv_fullpath    TYPE string, "full yol
      gv_user_action TYPE i. "action.

DATA: BEGIN OF ty_excel,
        name TYPE c LENGTH 30,
      END OF ty_excel.

DATA: gt_header_e LIKE TABLE OF ty_excel.

TYPES: BEGIN OF ty_excel_download,
         vbeln  TYPE vbak-vbeln,
         posnr  TYPE vbap-posnr,
         kdmat  TYPE vbap-kdmat,
         matnr  TYPE vbap-matnr,
         maktx  TYPE makt-maktx,
         kunnr  TYPE vbak-kunnr,
         kwmeng TYPE vbap-kwmeng,
         kbetr  TYPE prcd_elements-kbetr,
         netwr  TYPE vbap-netwr,
       END OF ty_excel_download.

DATA: gt_excel TYPE TABLE OF ty_excel_download,
      gs_excel TYPE ty_excel_download.

DATA: BEGIN OF wa_header,
        name TYPE c LENGTH 30,
      END OF wa_header.

DATA: t_header LIKE TABLE OF wa_header.

DATA: gt_header_s   TYPE TABLE OF ty_excel_download.


DATA: gv_xstring TYPE xstring,
      gt_solix   TYPE solix_tab,
      gv_length  TYPE i.

"tablo için bir data referansı tanımla
DATA: lr_data_ref TYPE REF TO data.

" Tablonun adresini (referansını) değişkenine
GET REFERENCE OF gt_excel INTO lr_data_ref.

"Metodun beklediği tipte yeni bir tablo
DATA: gt_fcat_lvc TYPE lvc_t_fcat.
