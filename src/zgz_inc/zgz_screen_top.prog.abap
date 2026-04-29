*&---------------------------------------------------------------------*
*& Include          ZGZ_SCREEN_TOP
*&---------------------------------------------------------------------*

DATA: gv_text TYPE char100,
      gv_cins TYPE char6,
      gv_onay TYPE char1.

DATA: gv_ad    TYPE char20,
      gv_soyad TYPE char30,
      gv_rad1  TYPE char1,
      gv_rad2  TYPE xfeld,
      gv_cbox  TYPE xfeld.

DATA: gv_yas    TYPE i,
      gv_id     TYPE vrm_id,
      gt_values TYPE vrm_values,
      gs_value  TYPE vrm_value.

DATA: ok_code TYPE sy-ucomm.

DATA: gv_date TYPE datum.

"tek alan
DATA: gs_log TYPE zgz_t_screen.

"field sayısı
DATA: gv_field TYPE i.

CONTROLS tb_ıd TYPE TABSTRIP.

"subscreen
DATA: gs_sflight TYPE sflight.

DATA: gv_flag TYPE xfeld VALUE abap_true.

"field sayısı
DATA: gv_num TYPE i.

CLASS lcl_controller DEFINITION.
  PUBLIC SECTION.
    " Ana Akış
    METHODS:
      get_data.
ENDCLASS.

"nesnem
DATA: go_controller TYPE REF TO lcl_controller.


SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:p_carrid	TYPE s_carr_id,
             p_connid	TYPE s_conn_id,
             p_fldate	TYPE s_date.
SELECTION-SCREEN END OF BLOCK b1.
*SELECT-OPTIONS s_num FOR gv_num MODIF ID gr1.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: r_rad1 RADIOBUTTON GROUP zgr1 DEFAULT 'X' USER-COMMAND usr1,
              r_Rad2 RADIOBUTTON GROUP zgr1.

  SELECTION-SCREEN SKIP 1.

  PARAMETERS: p_lifnr  TYPE lifnr MODIF ID gr1,
              p_lifnrn TYPE name1_gp MODIF ID gr1,
              p_kunnr  TYPE kunnr MODIF ID gr2,
              p_kunnrn TYPE name1_gp MODIF ID gr2.
SELECTION-SCREEN END OF BLOCK b2.
