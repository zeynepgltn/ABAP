*&---------------------------------------------------------------------*
*& Report ZGZ_P002
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_p002.

TABLES: zgz_t_001.
DATA: gv_dersid TYPE zgz_e_004.
PARAMETERS: p_num1  TYPE i,
            p_ograd TYPE zgz_e_002.
SELECT-OPTIONS: s_dersid FOR gv_dersid.
"s_ogrpn FOR zgz_t_001-puan.
PARAMETERS: p_metin AS CHECKBOX.
SELECTION-SCREEN BEGIN OF BLOCK b11 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_rad1 RADIOBUTTON GROUP gr1,
              p_rad2 RADIOBUTTON GROUP gr1,
              p_rad3 RADIOBUTTON GROUP gr1.
SELECTION-SCREEN END OF BLOCK b11.
SELECTION-SCREEN BEGIN OF BLOCK b12 WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_rad4 RADIOBUTTON GROUP gr2,
              p_rad5 RADIOBUTTON GROUP gr2.
SELECTION-SCREEN END OF BLOCK b12.


*PARAMETERS p_num2 TYPE i.
*IF p_num2 > 0 AND p_num2 < 25.
*  WRITE '0 ve 25 arasında'.
*  ELSEIF p_num2 >= 25 AND p_num2 < 50.
*    WRITE '50 ve 25 arasında'.
*  ELSEIF p_num2 >= 50 AND p_num2 < 75.
*    WRITE '50 ve 75 arasında'.
*  ELSEIF p_num2 >= 75 AND p_num2 < 100.
*    WRITE '100 ve 75 arasında'.
*  ELSE.
*    WRITE '100 den büyük'.
*ENDIF.

*PARAMETERS p_not TYPE i.
*IF p_not > 0 AND p_not < 20.
*  WRITE 'FF'.
*  ELSEIF p_not > 20 AND p_not <= 40.
*    WRITE 'DD'.
*  ELSEIF p_not > 40 AND p_not <= 60.
*    WRITE 'CC'.
*  ELSEIF p_not > 60 AND p_not <= 80.
*    WRITE 'BB'.
*  ELSEIF p_not > 80 AND p_not <= 100.
*    WRITE 'AA'.
*  ELSE.
*    WRITE 'Geçerli değer giriniz.'.
*ENDIF.


*PARAMETERS: p_sayi  TYPE i,
*            p_sayi2 TYPE i,
*            p_sayi3 TYPE i.
*IF ( p_sayi < p_sayi2 AND p_sayi > p_sayi3 ) OR ( p_sayi > p_sayi2 AND p_sayi < p_sayi3 ).
*  WRITE: 'Birinci sayı ortanca'.
*ELSEIF ( p_sayi2 < p_sayi AND p_sayi2 > p_sayi3 ) OR ( p_sayi2 > p_sayi AND p_sayi2 < p_sayi3 ).
*  WRITE: 'İkinci sayı ortanca'.
*ELSEIF  ( p_sayi3 < p_sayi AND p_sayi3 > p_sayi2 ) OR ( p_sayi3 > p_sayi AND p_sayi3 < p_sayi2 ).
*  WRITE: 'Üçüncü sayı ortanca'.
*ELSE.
*  WRITE: 'Eşitlik olabilir.'.
*ENDIF.


*PARAMETERS: p_numm  TYPE i,
*            p_numm2 TYPE i,
*            p_islem TYPE c.
*DATA gv_sonuc TYPE i.
*CASE p_islem.
*  WHEN '+'.
*    gv_sonuc = p_numm + p_numm2.
*  WHEN '-'.
*    gv_sonuc = p_numm - p_numm2.
*  WHEN '/'.
*    gv_sonuc = p_numm / p_numm2.
*  WHEN '*'.
*    gv_sonuc = p_numm * p_numm2.
*  WHEN OTHERS.
*    WRITE 'Geçerli değerler giriniz.'.
*ENDCASE.
*
*WRITE gv_sonuc.


*PARAMETERS: c_1 AS CHECKBOX,
*            c_2 AS CHECKBOX,
*            c_3 AS CHECKBOX.
*DATA: gv_1 TYPE i VALUE 10.
*START-OF-SELECTION.
*IF c_1 EQ abap_true.
*  gv_1 += 2.
*ENDIF.
*IF c_2 EQ abap_true.
*  gv_1 += 3.
*ENDIF.
*IF c_3 EQ abap_true.
*  gv_1 += 5.
*ENDIF.
*WRITE gv_1.


*PARAMETERS: p_n1 TYPE i,
*            p_n2 TYPE i,
*            r_1 RADIOBUTTON GROUP gr1,
*            r_2 RADIOBUTTON GROUP gr1,
*            r_3 RADIOBUTTON GROUP gr1,
*            r_4 RADIOBUTTON GROUP gr1,
*            c_c1 AS CHECKBOX,
*            c_c2 AS CHECKBOX.
*DATA gv_result TYPE i.
*IF r_1 EQ abap_true.
*  PERFORM toplama.
*  ELSEIF r_2 EQ abap_true.
*    PERFORM cikarma.
*  ELSEIF r_3 EQ abap_true.
*    PERFORM carpma.
*  ELSEIF r_4 EQ abap_true.
*    PERFORM bolme.
*ENDIF.
*IF c_c1 EQ abap_true.
*  gv_result *= 10.
*ENDIF.
*IF c_c2 EQ abap_true.
*  gv_result /= 2.
*ENDIF.
*WRITE gv_result.
*FORM toplama .
*  gv_result = p_n1 + p_n2.
*ENDFORM.
*FORM cikarma .
*  gv_result = p_n1 - p_n2.
*ENDFORM.
*FORM carpma .
*  gv_result = p_n1 * p_n2.
*ENDFORM.
*FORM bolme .
*  gv_result = p_n1 / p_n2.
*ENDFORM.
