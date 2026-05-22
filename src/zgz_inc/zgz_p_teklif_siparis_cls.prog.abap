*&---------------------------------------------------------------------*
*& Include          ZGZ_P_TEKLIF_SIPARIS_CLS
*&---------------------------------------------------------------------*
CLASS cl_main IMPLEMENTATION.
  METHOD create_instance.
    IF mo_instance IS INITIAL.
      mo_instance = NEW cl_main( ).
    ENDIF.
    r_obj = mo_instance.
  ENDMETHOD.

  METHOD read_data.
   SELECT vbeln, kunnr, vkorg, vtweg, spart, netwr, waerk, angdt, bnddt
   FROM vbak
   INTO TABLE @gt_teklif_baslik
   WHERE angdt >= @s_tarih-low   " İlk girilen tarih başlangıca gider
     AND bnddt <= @s_tarih-high  " İkinci girilen tarih sona gider
     AND vkorg IN @s_vkorg       " Diğer filtrelerimiz...
     AND vtweg IN @s_vtweg.
  ENDMETHOD.






ENDCLASS.
