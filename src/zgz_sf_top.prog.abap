*&---------------------------------------------------------------------*
*& Include          ZGZ_SF_TOP
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_alv,
         selkz     TYPE xfeld,
         sirketk   TYPE zgz_t_belgeb-sirketk,
         belgeno   TYPE  zgz_t_belgeb-belgeno,
         maliyil   TYPE  zgz_t_belgeb-maliyil,
         musteriad TYPE  zgz_t_belgeb-musteriad,
         kalem     TYPE  zgz_t_belgeb-kalem,
         tutar     TYPE  zgz_t_belgeb-tutar,
         parab     TYPE  zgz_t_belgeb-parab,
         aciklama  TYPE  zgz_t_belgeb-aciklama,
         sirketad  TYPE  zgz_t_belgeb-sirketad,
         yerlesim  TYPE  zgz_t_belgeb-yerlesim,
         mahalle   TYPE  zgz_t_belgeb-mahalle,
         sokak     TYPE  zgz_t_belgeb-sokak,
         vergıno   TYPE zgz_t_belgeb-vergıno,
         vergınn   TYPE zgz_t_belgeb-vergınn,
       END OF ty_alv.

TYPES: BEGIN OF ty_header,
         sirketk   TYPE zgz_t_belgeb-sirketk,
         belgeno   TYPE zgz_t_belgeb-belgeno,
         maliyil   TYPE  zgz_t_belgeb-maliyil,
         musteriad TYPE  zgz_t_belgeb-musteriad,
         sokak     TYPE  zgz_t_belgeb-sokak,
         yerlesim  TYPE  zgz_t_belgeb-yerlesim,
         mahalle   TYPE  zgz_t_belgeb-mahalle,
         vergıno   TYPE zgz_t_belgeb-vergıno,
         vergınn   TYPE zgz_t_belgeb-vergınn,
         s_lira    TYPE char100,
       END OF ty_header.

DATA s_parabb TYPE char10.
DATA: ls_spell TYPE spell. "yazıya çevirme sonucu

DATA: gt_alv TYPE TABLE OF ty_alv,
      gs_alv TYPE ty_alv.

DATA: gt_toplam TYPE TABLE OF ty_alv,
      gs_toplam TYPE ty_alv.

DATA: gt_fcat TYPE slis_t_fieldcat_alv,
      gs_fcat TYPE slis_fieldcat_alv.

DATA: gs_layout TYPE slis_layout_alv.

DATA: fm_name TYPE rs38l_fnam.

DATA: gt_alv_for_sf TYPE zgz_tt_belgeb.
DATA: gs_sf LIKE LINE OF gt_alv_for_sf. "zgz_tt_belgeb tablo tipi onu veremem
"DATA: gs_sf type zgz_t_belgeb.

DATA: gt_header TYPE TABLE OF ty_header,
      gs_header TYPE ty_header.

DATA: ref_grid TYPE REF TO cl_gui_alv_grid.

DATA: ls_control_param  TYPE ssfctrlop,
      ls_composer_param TYPE ssfcompop.

TYPES: BEGIN OF ty_key,
         belnr     TYPE zgz_t_belgeb-belgeno,
         bukrs     TYPE zgz_t_belgeb-sirketk,
         gjahr     TYPE zgz_t_belgeb-maliyil,
         musteriad TYPE zgz_t_belgeb-musteriad,
         sokak     TYPE zgz_t_belgeb-sokak,
         yerlesim  TYPE zgz_t_belgeb-yerlesim,
         mahalle   TYPE zgz_t_belgeb-mahalle,
         vergino   TYPE zgz_t_belgeb-vergino,
         verginn   TYPE zgz_t_belgeb-verginn,

       END OF ty_key.

DATA: lt_keys TYPE TABLE OF ty_key,
      ls_key  TYPE ty_key.

DATA: gt_detay TYPE TABLE OF ty_alv. " Tüm kalemler
