*&---------------------------------------------------------------------*
*& Report ZGZ_SCREEN
*&---------------------------------------------------------------------*
REPORT zgz_screen.

TABLES: zgz_t_001.

"Blok 1
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-003.
  "Parameters
  PARAMETERS: p_id TYPE zgz_t_001-ogr_id OBLIGATORY.

  "Yan yana parameters
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(10) TEXT-001.
    PARAMETERS: p_ad(10) TYPE c.
    SELECTION-SCREEN COMMENT 25(10) TEXT-002.
    PARAMETERS: p_soyad(10) TYPE c.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.


SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-004.
  PARAMETERS: rb_1 RADIOBUTTON GROUP grp1 USER-COMMAND rad,
              rb_2 RADIOBUTTON GROUP grp1 DEFAULT 'X'.

  PARAMETERS: p_ogid   TYPE zgz_t_001-ogr_id VISIBLE LENGTH 5,
              p_ogr_ad TYPE zgz_t_001-ogr_ad VISIBLE LENGTH 5 MODIF ID m1,
              p_ders_i TYPE zgz_t_001-ders_id VISIBLE LENGTH 5,
              p_ders_n TYPE zgz_t_001-ders_notu AS LISTBOX VISIBLE LENGTH 5 MODIF ID m1.
SELECTION-SCREEN END OF BLOCK b2.


SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-005.
  SELECT-OPTIONS: s_id FOR zgz_t_001-ogr_id.
  SELECT-OPTIONS: s_id2 FOR zgz_t_001-ders_id NO INTERVALS.
  SELECT-OPTIONS: s_ad FOR zgz_t_001-ogr_ad NO INTERVALS NO-EXTENSION.
SELECTION-SCREEN END OF BLOCK b4.

*DATA: gv_btn TYPE string.
*SELECTION-SCREEN PUSHBUTTON 10(20) gv_btn USER-COMMAND btn1.

"Listbox Doldurma

INITIALIZATION.
  DATA: lt_liste TYPE vrm_values,
        ls_liste TYPE vrm_value.

  ls_liste-key = 'BB'.
  ls_liste-text = 'BB'.
  APPEND ls_liste TO lt_liste.

  ls_liste-key = 'CC'.
  ls_liste-text = 'CC'.
  APPEND ls_liste TO lt_liste.

  ls_liste-key = 'DD'.
  ls_liste-text = 'DD'.
  APPEND ls_liste TO lt_liste.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_DERS_N'
      values = lt_liste.




AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.

    IF screen-group1 = 'M1'.

      IF rb_1 = 'X'.
        screen-active = 1.
      ELSE.
        screen-active = 0.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.



START-OF-SELECTION.
  DATA: gs_ogr_t TYPE zgz_t_001,

        gt_ogr_t TYPE TABLE OF zgz_t_001.



  SELECT * FROM zgz_t_001
  WHERE ogr_id EQ @p_id
  INTO TABLE @DATA(lt_data01).

  "Not kısmı - select options
  SELECT * FROM zgz_t_001
  WHERE ogr_id IN @s_id
  INTO TABLE @DATA(lt_data02).


  SELECT * FROM zgz_t_001
  WHERE ders_id IN @s_id2
  AND ogr_ad IN @s_ad
  INTO TABLE @DATA(lt_data03).


  SELECT * FROM zgz_t_001
  WHERE ders_notu = @p_ders_n
  INTO TABLE @DATA(lt_data04).

  SELECT *
  FROM zgz_t_001
  WHERE ogr_ad LIKE 'A%'
  INTO TABLE @DATA(lt_data06).


  SELECT *
  FROM zgz_t_001
  WHERE ogr_ad IN ( 'ZEYNEP', 'KEMAL' )
  INTO TABLE @DATA(lt_data7).

  SELECT SINGLE * FROM zgz_t_001
   INTO @DATA(ls_01).

  SELECT SINGLE ogr_id FROM zgz_t_001
   INTO @DATA(ls_02).



  gs_ogr_t-ogr_id = p_id.
  gs_ogr_t-ogr_ad = p_ad.
  gs_ogr_t-ogr_soyad = p_soyad.
  gs_ogr_t-ders_id = p_ders_i.
  gs_ogr_t-ders_notu = p_ders_n.

  INSERT zgz_t_001 FROM gs_ogr_t.



*UPDATE zgz_t_001 SET ogr_ad = 'Merve Nur'
*WHERE ogr_id EQ 9.

**DELETE
*DELETE FROM zgz_t_001 WHERE ogr_id EQ 2.

*gs_ogr_t-ogr_ıd = 3.
*gs_ogr_t-ogr_ad = 'R'.
*gs_ogr_t-ogr_soyad = 'G'.
*gs_ogr_t-ders_ıd = 3.
*gs_ogr_t-puan = 7.
**MODIFY
*MODIFY zgz_t_001 FROM gs_ogr_t.


  BREAK-POINT.



*  SELECT *
*  FROM zgz_t_001
*  INTO gs_ogr_t
*  WHERE ogr_id BETWEEN 1 AND 3.
*
*    APPEND gs_ogr_t TO gt_ogr_t.
*  ENDSELECT.
