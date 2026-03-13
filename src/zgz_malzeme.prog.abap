*&---------------------------------------------------------------------*
*& Report ZGZ_MALZEME
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_malzeme.

TABLES: vbak,vbap.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_vbeln  FOR vbak-vbeln NO INTERVALS NO-EXTENSION,
                  s_matnr FOR vbap-matnr,
                  s_kunnr FOR vbak-kunnr.

  PARAMETERS: p_auart TYPE vbak-auart OBLIGATORY.

  SELECT-OPTIONS: s_vkorg FOR vbak-vkorg.

SELECTION-SCREEN END OF BLOCK b1.

DATA lv_id TYPE vbak-vbeln.
lv_id = s_vbeln-low.


START-OF-SELECTION.

  SELECT v~vbeln,
         v~kunnr,
         v~auart,
         va~posnr,
         va~matnr,
         va~kwmeng,
         va~vrkme,
         k~name1,
         t~bezei,
         m~maktx
    FROM vbak AS v
    INNER JOIN vbap AS va ON v~vbeln = va~vbeln
    LEFT JOIN kna1 AS k ON k~kunnr = v~kunnr
    LEFT JOIN tvakt AS t ON t~auart = v~auart AND t~spras = @sy-langu
    LEFT JOIN makt AS m ON m~matnr = va~matnr AND m~spras = @sy-langu
    WHERE v~vbeln IN @s_vbeln
    AND va~matnr IN @s_matnr
    AND v~kunnr IN @s_kunnr
    AND v~auart = @p_auart
    AND v~vkorg IN @s_vkorg
    INTO TABLE @DATA(lt_data01).


  "İkinci yol
  IF s_vbeln[] IS NOT INITIAL.
    READ TABLE s_vbeln INDEX 1.
    IF sy-subrc = 0.
      lv_id = s_vbeln-low.
    ENDIF.
  ENDIF.

  "Selection-option tek değer ise(genelde doğru bir kullanım değil)
  "WHERE id = s_id-low.

  cl_demo_output=>display_data( lt_data01 ).
  " BREAK-POINT.
