*&---------------------------------------------------------------------*
*& Report ZGZ_P_FONKSIYONLAR
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p_fonksiyonlar.

INCLUDE zgz_i_fonksiyonlar_top.
INCLUDE zgz_i_fonksiyonlar_cls.

START-OF-SELECTION.

*  gv_belgen = 1.
*
*  CALL FUNCTION 'ZGZ_FM_001'
*    EXPORTING
*      iv_belnr = gv_belgen
** TABLES
**     ETT_BELGE              =
* EXCEPTIONS
*     KAYIT_BULUNAMADI       = 1
*     OTHERS   = 2
*    .
*  IF sy-subrc <> 0  .
*    WRITE: 'Kayıt bulunamadı.'.
*  ENDIF.

*  CALL FUNCTION 'NUMERIC_CHECK'
*    EXPORTING
*      string_in = p_val
*    IMPORTING
*      htype     = gv_htype.
*
*  IF gv_htype EQ 'CHAR'.
*    WRITE: 'Sayısal olmayan bir değer girdiniz!'.
*  ELSEIF gv_htype EQ 'NUMC'.
*    WRITE: 'Sayısal bir değer girdiniz!'.
*  ENDIF.
*
*  REPORT zbk_egt_0007.


  CREATE OBJECT go_class.

*  gv_num1 = 12.
*  gv_num2 = 12.
*
*  go_class->sum_numbers(
*    EXPORTING
*      iv_num1   = gv_num1     " Doğal sayı
*      iv_num2   = gv_num2     " Doğal sayı
*    IMPORTING
*      ev_result = gv_result   " Doğal sayı
*  ).
*
*  WRITE: gv_result.
