*&---------------------------------------------------------------------*
*& Include          ZGZ_OO_001_TOP
*&---------------------------------------------------------------------*
TYPE-POOLS icon.

TYPES: BEGIN OF gty_scarr,
         situation  TYPE icon_d,
         carrid     TYPE s_carr_id,
         carrname   TYPE s_carrname,
         currcode   TYPE s_currcode,
         url        TYPE s_carrurl,
         mess       TYPE char200,
         line_color TYPE char4, "variable-her satır tek değer alır
         cell_color TYPE lvc_t_scol, "table-her cell için değer
         amount     TYPE int4,
         location   TYPE char20,
         seats      TYPE char1,
         seatp      TYPE char10,
         dd_handle  TYPE int4,
         cell_style TYPE lvc_t_styl,
         delete     TYPE char10,
       END OF gty_scarr.

DATA: go_cont TYPE REF TO cl_gui_custom_container.
*DATA: go_cont TYPE REF TO cl_gui_docking_container.

DATA: go_grid  TYPE REF TO cl_gui_alv_grid,
      go_grid2 TYPE REF TO cl_gui_alv_grid.

DATA: gt_scarr   TYPE TABLE OF gty_scarr,
      gs_scarr   TYPE gty_scarr,
      gt_sflight TYPE TABLE OF sflight,
      gt_fcat    TYPE lvc_t_fcat,
      gt_fcat2   TYPE lvc_t_fcat,
      gs_fcat    TYPE lvc_s_fcat,
      gs_layout  TYPE lvc_s_layo.

FIELD-SYMBOLS: <gfs_fc>    TYPE lvc_s_fcat,
               <gfs_scarr> TYPE gty_scarr.

DATA: gs_cell_color TYPE lvc_s_scol.

DATA: gs_cell_style TYPE lvc_s_styl.

DATA: go_splitter TYPE REF TO cl_gui_splitter_container,
      go_sub1     TYPE REF TO cl_gui_container,
      go_sub2     TYPE REF TO cl_gui_container,
      go_sub3     TYPE REF TO cl_gui_container.

CLASS cl_event_receiver DEFINITION DEFERRED.
DATA: go_event_receiver TYPE REF TO cl_event_receiver.

DATA: go_title TYPE REF TO cl_dd_document.

DATA: gt_excluding TYPE ui_functions,
      gv_excluding TYPE ui_func,
      gt_sort      TYPE lvc_t_sort,
      gs_sort      TYPE lvc_s_sort,
      gt_filt      TYPE lvc_t_filt,
      gs_filt      TYPE lvc_s_filt.

DATA: gs_variant TYPE disvariant,
      gs_variant_tmp TYPE disvariant.

PARAMETERS: p_vari TYPE disvariant.
