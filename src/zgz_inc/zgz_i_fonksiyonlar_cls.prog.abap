*&---------------------------------------------------------------------*
*& Include          ZGZ_I_FONKSIYONLAR_CLS
*&---------------------------------------------------------------------*

CLASS math_op IMPLEMENTATION.
  METHOD sum_numbers.
    lv_result = lv_num1 + lv_num2.
  ENDMETHOD.
ENDCLASS.

CLASS math_op_diff IMPLEMENTATION.
  METHOD numb_diff.
     lv_result = lv_num1 - lv_num2.
  ENDMETHOD.
ENDCLASS.
