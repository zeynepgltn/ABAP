*&---------------------------------------------------------------------*
*& Report ZGZ_MALZDEPO
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_malzdepo.

TABLES: mard,mara.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS s_malz FOR mard-matnr.
  PARAMETERS p_urt TYPE mard-werks ."OBLIGATORY.
  SELECT-OPTIONS: s_depo FOR mard-lgort,
                  s_malzt FOR mara-mtart.
  PARAMETERS: c_sbs  AS CHECKBOX,
              c_malt AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b1.

*7.40 öncesi
TYPES: BEGIN OF ty_malzeme,
         matnr   TYPE mard-matnr,
         meins   TYPE mara-meins,
         maktx   TYPE makt-maktx,
         werks   TYPE mard-werks,
         name1   TYPE t001w-name1,
         lgort   TYPE mard-lgort,
         lgobe   TYPE t001l-lgobe,
         Labst   TYPE mard-labst,
         umlme   TYPE mard-umlme,
         ınsme   TYPE mard-insme,
         eınme   TYPE mard-einme,
         speme   TYPE mard-speme,
         retme   TYPE mard-retme,
         vmlab   TYPE mard-vmlab,
         vmuml   TYPE mard-vmuml,
         vmıns   TYPE mard-vmıns,
         vmeın   TYPE mard-vmeın,
         vmspe   TYPE mard-vmspe,
         vmret   TYPE mard-vmret,
         t_color TYPE lvc_t_scol,
       END OF ty_malzeme.

*DATA: BEGIN OF ty_malzeme3,
*      END OF ty_malzeme3.

DATA: ls_malzeme TYPE ty_malzeme,
      lt_malzeme TYPE TABLE OF ty_malzeme,
      lr_labst   TYPE RANGE OF mard-labst,
      ls_labst   LIKE LINE OF lr_labst.
"ls_malzeme3 LIKE ty_malzeme3.

* Range doldurma 7.40 öncesi
IF c_sbs = 'X'.
  CLEAR ls_malzeme.
  ls_labst-sign   = 'I'.
  ls_labst-option = 'GT'.
  ls_labst-low    = 0.
  APPEND ls_labst TO lr_labst.
ENDIF.

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
*    AND m~werks = @p_urt
    AND m~lgort IN @s_depo
    AND ma~mtart IN @s_malzt
*    AND ( @c_sbs = @space OR m~labst > 0 )
    AND m~labst IN @lr_labst
*    INTO TABLE @DATA(lv_data01). 7.40
    INTO TABLE @lt_malzeme.


  DATA: lt_toplam TYPE TABLE OF ty_malzeme,
        ls_toplam TYPE ty_malzeme.

  IF c_malt = 'X'.
*    LOOP AT lt_malzeme INTO DATA(ls_malz).
*
*      READ TABLE lt_toplam INTO ls_toplam
*           WITH KEY matnr = ls_malz-matnr.
*
*      IF sy-subrc = 0.
*        ls_toplam-labst = ls_toplam-labst + ls_malz-labst.
*        MODIFY lt_toplam FROM ls_toplam INDEX sy-tabix.
*
*      ELSE.
*        CLEAR ls_toplam.
*        ls_toplam = ls_malz.
*        APPEND ls_toplam TO lt_toplam.
*      ENDIF.
*    ENDLOOP.
*  ELSE.
*    lt_toplam = lt_malzeme.

    LOOP AT lt_malzeme INTO DATA(ls_group)
         GROUP BY ( matnr = ls_group-matnr ).
*         INTO DATA(ls_group)."Grupları tutuyor
      ls_toplam = ls_group.
      "APPEND LINES OF ls_group TO ls_toplam.
      "ls_toplam = CORRESPONDING #( ls_group ).

      "APPEND LINES OF CORRESPONDING #( ls_group ) TO ls_toplam.

      CLEAR: ls_toplam-labst.
      LOOP AT GROUP ls_group INTO DATA(ls_memb).
        ls_toplam-labst = ls_toplam-labst + ls_memb-labst.
      ENDLOOP.
      APPEND ls_toplam TO lt_toplam.
      CLEAR ls_toplam.
    ENDLOOP.

    gt_alv = gt_toplam.

  ENDIF.
