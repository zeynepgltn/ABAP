*&---------------------------------------------------------------------*
*& Include          ZGZ_RALV_TOP
*&---------------------------------------------------------------------*

*DATA: BEGIN OF gtt_alv OCCURS 0, "Header line oluşturur
*        ebeln LIKE ekko-ebeln,
*        ebelp LIKE ekpo-ebelp,
*        bstyp LIKE ekko-bstyp,
*        bsart LIKE ekko-bsart,
*        matnr LIKE ekpo-matnr,
*        menge LIKE ekpo-menge,
*        meins LIKE ekpo-meins,
*      END OF gtt_alv.

TYPES: BEGIN OF ty_alv,
         ebeln    TYPE zgz_t_ekko-ebeln,
         ebelp    TYPE zgz_t_ekpo-ebelp,
         bstyp    TYPE zgz_t_ekko-bstyp,
         bsart    TYPE zgz_t_ekko-bsart,
         matnr    TYPE zgz_t_ekpo-matnr,
         menge    TYPE zgz_t_ekpo-menge,
         meins    TYPE zgz_t_ekpo-meins,
         rowcolor TYPE c LENGTH 4,
       END OF ty_alv.

TYPES: BEGIN OF ty_alv_display,
         selkz     TYPE xfeld, "char1
         zıcon     TYPE zgz_de_icon,
         ebeln     TYPE zgz_t_ekko-ebeln,
         ebelp     TYPE zgz_t_ekpo-ebelp,
         bstyp     TYPE zgz_t_ekko-bstyp,
         bsart     TYPE zgz_t_ekko-bsart,
         matnr     TYPE zgz_t_ekpo-matnr,
         menge     TYPE zgz_t_ekpo-menge,
         meins     TYPE zgz_t_ekpo-meins,
         rowcolor  TYPE c LENGTH 4,
         cellcolor TYPE lvc_t_scol,
       END OF ty_alv_display.

DATA: gt_alv         TYPE TABLE OF ty_alv,
      gs_alv         TYPE ty_alv,
      gt_alv_display TYPE TABLE OF ty_alv_display,  " ALV için
      gs_alv_display TYPE ty_alv_display.


DATA: ls_color TYPE lvc_s_scol,
      lt_color TYPE lvc_t_scol.

DATA: gs_layout TYPE slis_layout_alv.

DATA: gt_fcat TYPE slis_t_fieldcat_alv,
      gs_fcat TYPE slis_fieldcat_alv.

DATA: lv_error TYPE abap_bool.

DATA: gt_events TYPE slis_t_event,
      gs_event  TYPE slis_alv_event.

DATA: lt_header TYPE slis_t_listheader,
      ls_header TYPE slis_listheader.

DATA: gv_date TYPE char10.

DATA: gv_mes TYPE char30.

DATA: gv_ind   TYPE string,
      gv_count TYPE i.

DATA: gs_extab TYPE slis_extab.

DATA: gr_grid TYPE REF TO cl_gui_alv_grid.
