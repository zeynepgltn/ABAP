*&---------------------------------------------------------------------*
*& Report ZGZ_JOINS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_joins.

TABLES: zgz_t_001.

SELECTION-SCREEN BEGIN OF BLOCK b11 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_id FOR zgz_t_001-ogr_id.
SELECTION-SCREEN END OF BLOCK b11.



START-OF-SELECTION.

  SELECT a~ogr_ad,
         b~klup_ad
    FROM zgz_t_001 AS a
    INNER JOIN zgz_t_002 AS b
      ON a~ogr_id = b~ogrencı_ıd
    INTO TABLE @DATA(lt_data).



  SELECT a~ogr_id,
         a~ogr_ad,
         b~klup_ad
    FROM zgz_t_001 AS a
    INNER JOIN zgz_t_002 AS b
    ON a~ogr_ıd = b~ogrencı_ıd
    WHERE a~ogr_ıd IN @s_id
    INTO TABLE @DATA(lt_data01).


  SELECT a~ogr_id,
         a~ogr_ad,
         b~klup_ad
    FROM zgz_t_001 AS a
    LEFT OUTER JOIN zgz_t_002 AS b
    ON a~ogr_ıd = b~ogrencı_ıd
    WHERE a~ogr_ıd IN @s_id
    INTO TABLE @DATA(lt_data02).


  SELECT a~ogr_id,
        a~ogr_ad,
        b~klup_ad
   FROM zgz_t_001 AS a
   RIGHT OUTER JOIN zgz_t_002 AS b
   ON a~ogr_ıd = b~ogrencı_ıd
   WHERE a~ogr_ıd IN @s_id
   INTO TABLE @DATA(lt_data03).


  BREAK-POINT.
