*&---------------------------------------------------------------------*
*& Report ZGZ_P001
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p001.

*Comment satırı ctrl+<
DATA: gv_deg1  TYPE p DECIMALS 2,
      gv_deg2  TYPE int4,
      gv_deg3  TYPE n LENGTH 4,
      gv_deg4  TYPE c VALUE ' A',
      gv_mes   TYPE String,
      gv_sonuc TYPE i.

gv_deg1 = '12.45'.
gv_deg2 = 345.
gv_deg3 = 1.
gv_mes = 'Farkı'.


IF  gv_deg2 > gv_deg3.
  WRITE 'Birinci sayı büyüktür.'.
ELSEIF gv_deg2 < gv_deg3.
  WRITE 'İkinci sayı büyüktür'.
ELSEIF gv_deg2 = gv_deg3.
  WRITE 'İki sayı eşittir.'.
ELSE.
  WRITE 'Geçerli değerler giriniz.'.
ENDIF.


CASE gv_deg3.
  WHEN 1.
    WRITE / 'Sayı bir.'.
  WHEN 2.
    WRITE / 'Sayı iki.'.
  WHEN 3.
    WRITE / 'Sayı üç.'.
  WHEN 4.
    WRITE / 'Sayı dört.'.
  WHEN 5.
    WRITE / 'Sayı beş.'.
  WHEN OTHERS.
ENDCASE.


DO 10 TIMES.
  WRITE: / gv_deg3 , 'DO'.
  gv_deg3 += 1.
ENDDO.

WHILE gv_deg3 LT 20.
  WRITE / gv_deg3.
ENDWHILE.


DATA: gv_num1 TYPE i VALUE 0.

DO 101 TIMES.
  IF gv_num1 MOD 2 = 0.
    WRITE: / 'Çift sayı=' , gv_num1.
  ELSE.
    WRITE: / 'Tek sayı= ' , gv_num1.
  ENDIF.
  gv_num1 += 1.
ENDDO.


DATA: gv_num2 TYPE i VALUE 1.

WRITE: 'İkiye tam bölünen sayılar:'.
DO 100 TIMES.
  IF gv_num2 MOD 2 = 0.
    WRITE: gv_num2 NO-GAP.
  ENDIF.

  gv_num2 += 1.
ENDDO.

gv_num2 = 1.
WRITE: / 'Üçe tam bölünen sayılar:'.
DO 100 TIMES.
  IF gv_num2 MOD 3 = 0.
    WRITE: gv_num2.
  ENDIF.

  gv_num2 += 1.
ENDDO.

gv_num2 = 1.
WRITE: / 'Beşe tam bölünen sayılar:'.
DO 100 TIMES.
  IF gv_num2 MOD 5 = 0.
    WRITE: gv_num2.
  ENDIF.

  gv_num2 += 1.
ENDDO.

****************************************************
DATA: gv_ogrid   TYPE zgz_e_001,
      gv_ograd   TYPE zgz_e_002,
      gv_ogrsa   TYPE zgz_e_003,
      gv_ogrders TYPE zgz_e_004,
      gv_ogrpuan TYPE zgz_e_005,

      gs_ogr_t   TYPE zgz_t_001,

      gt_ogr_t   TYPE TABLE OF zgz_t_001.


*SELECT
SELECT * FROM zgz_t_001
  INTO TABLE gt_ogr_t
  WHERE ogr_id EQ 1.

SELECT SINGLE * FROM zgz_t_001
  INTO gs_ogr_t.

SELECT SINGLE ogr_id FROM zgz_t_001
  INTO gv_ogrid.


*UPDATE
UPDATE zgz_t_001 SET ogr_ad = 'N'
  WHERE ogr_id EQ 1.


gs_ogr_t-ogr_ıd = 3.
gs_ogr_t-ogr_ad = 'H'.
gs_ogr_t-ogr_soyad = 'G'.
gs_ogr_t-ders_ıd = 3.
gs_ogr_t-puan = 3.

*INSERT
INSERT zgz_t_001 FROM gs_ogr_t.


*DELETE
DELETE FROM zgz_t_001 WHERE ogr_id EQ 2.


gs_ogr_t-ogr_ıd = 3.
gs_ogr_t-ogr_ad = 'R'.
gs_ogr_t-ogr_soyad = 'G'.
gs_ogr_t-ders_ıd = 3.
gs_ogr_t-puan = 7.

*MODIFY
MODIFY zgz_t_001 FROM gs_ogr_t.
