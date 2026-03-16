*&---------------------------------------------------------------------*
*& Report ZGZ_ALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_alv.

TABLES: mard,mara.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS s_malz FOR mard-matnr.
  PARAMETERS p_urt TYPE mard-werks ."OBLIGATORY.
  SELECT-OPTIONS: s_depo FOR mard-lgort,
                  s_malzt FOR mara-mtart.
  PARAMETERS: c_sbs  AS CHECKBOX,
              c_malt AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b1.

TYPES: BEGIN OF ty_alv,
         durum   TYPE icon_d,
         matnr   LIKE mard-matnr,
         meins   LIKE mara-meins,
         maktx   LIKE makt-maktx,
         werks   LIKE mard-werks,
         name1   LIKE t001w-name1,
         lgort   LIKE mard-lgort,
         lgobe   LIKE t001l-lgobe,
         labst   LIKE mard-labst,
         umlme   LIKE mard-umlme,
         insme   LIKE mard-insme,
         einme   LIKE mard-einme,
         speme   LIKE mard-speme,
         retme   LIKE mard-retme,
         vmlab   LIKE mard-vmlab,
         vmuml   LIKE mard-vmuml,
         vmins   LIKE mard-vmins,
         vmein   LIKE mard-vmein,
         vmspe   LIKE mard-vmspe,
         vmret   LIKE mard-vmret,
         t_color TYPE lvc_t_scol,
       END OF ty_alv.


DATA: lt_alv   TYPE TABLE OF ty_alv,
      ls_alv   TYPE ty_alv,
      ls_color TYPE lvc_s_scol.

CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    METHODS: on_link_click
      FOR EVENT link_click
      OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_link_click.

    " Tıklanan satırı oku
    DATA: ls_alv TYPE ty_alv.
    READ TABLE lt_alv INTO ls_alv INDEX row.
    CHECK sy-subrc = 0.

    MESSAGE |{ ls_alv-matnr } numarasına tıklandı. | TYPE 'I'.

  ENDMETHOD.
ENDCLASS.


START-OF-SELECTION.

  SELECT m~matnr,
         ma~meins,
         mak~maktx,
         m~werks,
         t~name1,
         m~lgort,
         tl~lgobe,
         m~labst,
         m~umlme,
         m~insme,
         m~einme,
         m~speme,
         m~retme,
         m~vmlab,
         m~vmuml,
         m~vmins,
         m~vmein,
         m~vmspe,
         m~vmret
    FROM mard AS m
    INNER JOIN mara AS ma ON m~matnr = ma~matnr
    LEFT JOIN makt AS mak ON m~matnr = mak~matnr AND mak~spras = @sy-langu
    LEFT JOIN t001w AS t ON m~werks = t~werks
    LEFT JOIN t001l AS tl ON m~werks = tl~werks AND m~lgort = tl~lgort
    WHERE  m~matnr IN @s_malz
    AND m~lgort IN @s_depo
    AND ma~mtart IN @s_malzt
  INTO TABLE @DATA(lt_temp).



  LOOP AT lt_temp INTO DATA(ls_temp).
    CLEAR: ls_alv, ls_color.

    "kaynak hedef, Tablodaki satırın KENDİSİ
    MOVE-CORRESPONDING ls_temp TO ls_alv.

    IF ls_alv-labst = 0.
      ls_color-color-col       = '6'.
      ls_color-color-inv       = '0'.

    ELSEIF ls_alv-labst < 500.
      ls_color-color-col       = '3'.
      ls_color-color-inv       = '0'.

    ELSEIF ls_alv-labst > 500.
      ls_color-color-col       = '5'.
      ls_color-color-inv       = '0'.
    ENDIF.
    APPEND ls_color TO ls_alv-t_color.

    IF  ls_alv-werks = '1000'.
      ls_alv-durum = icon_pdir_back.
      ls_color-fname           = 'NAME1'.
      ls_color-color-col       = '1'.
      ls_color-color-inv       = '0'.
      APPEND ls_color TO ls_alv-t_color.
    ELSEIF ls_alv-werks = '3000'.
      ls_alv-durum  = icon_pdir_foreward  .
    ENDIF.

    APPEND ls_alv TO lt_alv.
  ENDLOOP.


  DATA: go_salv TYPE REF TO cl_salv_table.

  cl_salv_table=>factory(
    IMPORTING
      r_salv_table = go_salv
    CHANGING
      t_table      = lt_alv
  ).

  DATA: lo_display TYPE REF TO cl_salv_display_settings.

  lo_display = go_salv->get_display_settings( ).
  lo_display->set_list_header( value = 'SALV').
  lo_display->set_striped_pattern( value = 'X').



  DATA: lo_cols TYPE REF TO cl_salv_columns.

  lo_cols = go_salv->get_columns( ).
  lo_cols->set_optimize( value = 'X').



  DATA: lo_col TYPE REF TO cl_salv_column.

  TRY.
      lo_col = lo_cols->get_column( columnname = 'NAME1').
      lo_col->set_long_text('AD').
      lo_col->set_medium_text('AD').
      lo_col->set_short_text('AD').
    CATCH cx_salv_not_found.
  ENDTRY.


  DATA: lo_func TYPE REF TO cl_salv_functions.

  lo_func = go_salv->get_functions( ).
  lo_func->set_all( abap_true ).

*  lo_col = lo_cols->get_column( columnname = 'MANDT').
*  lo_cols->set_visible( value = if_salv_c_bool_sap=>false ).


  DATA: lo_header  TYPE REF TO cl_salv_form_layout_grid,
        lo_h_label TYPE REF TO cl_salv_form_label.
        "lo_h_flow  TYPE REF TO cl_salv_form_layout_flow.

  CREATE OBJECT lo_header.
  " 1. satır
  lo_h_label = lo_header->create_label( row = 1 column = 1 ).
  lo_h_label->set_text( |Kullanıcı: { sy-uname }| ). "Kullanıcı adı

  " 2. satır
  lo_h_label = lo_header->create_label( row = 2 column = 1 ).
  lo_h_label->set_text( |Toplam Kayıt: { lines( lt_alv ) }| ). "Satır sayısı

  go_salv->set_top_of_list( lo_header ).


*  ""POP UP
*  go_salv->set_screen_popup(
*    start_column = 10
*    end_column   = 100
*    start_line   = 5
*    end_line     = 25
*  ).


  ""COLOR-Uzun yazım
  go_salv->get_columns( )->set_color_column( 'T_COLOR' ).


  ""İKONLAR-kısa yazım
  TRY.
      lo_col = lo_cols->get_column( columnname = 'DURUM' ).
      lo_col->set_medium_text( 'Durum' ).
    CATCH cx_salv_not_found.
  ENDTRY.


  DATA: lo_cols_tab TYPE REF TO cl_salv_columns_table,
        lo_col_tab  TYPE REF TO cl_salv_column_table.
  " Kolonları al
  lo_cols_tab = go_salv->get_columns( ).

  " MATNR kolonunu al
  TRY.
      lo_col_tab ?= lo_cols_tab->get_column( 'MATNR' )." get_column() → cl_salv_column döndürür ama biz cl_salv_column_table istiyoruz ?= ile
    CATCH cx_salv_not_found.
  ENDTRY.

  " Hotspot ekle
  TRY.
      lo_col_tab->set_cell_type(
    value = if_salv_c_cell_type=>hotspot ).
    CATCH cx_salv_data_error.
  ENDTRY.


  "lcl_handler nesnesine referans tutacak değişken.
  DATA: lo_handler TYPE REF TO lcl_handler.
  lo_handler = NEW lcl_handler( ).

  SET HANDLER lo_handler->on_link_click "Bu SALV’de link_click olursa on_link_click çalıştır
      FOR go_salv->get_event( ). "SALV’in event nesnesini alır

  go_salv->display( ).
