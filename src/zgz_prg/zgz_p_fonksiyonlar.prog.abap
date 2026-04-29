*&---------------------------------------------------------------------*
*& Report ZGZ_P_FONKSIYONLAR
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p_fonksiyonlar.

INCLUDE zgz_i_fonksiyonlar_top.

START-OF-SELECTION.

  gv_belgen = 1.

  CALL FUNCTION 'ZGZ_FM_001'
    EXPORTING
      iv_belnr = gv_belgen
* TABLES
*     ETT_BELGE              =
 EXCEPTIONS
     KAYIT_BULUNAMADI       = 1
     OTHERS   = 2
    .
  IF sy-subrc <> 0  .
    WRITE: 'Kayıt bulunamadı.'.
  ENDIF.
