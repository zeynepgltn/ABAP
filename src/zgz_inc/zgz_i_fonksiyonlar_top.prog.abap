*&---------------------------------------------------------------------*
*& Include          ZGZ_I_FONKSIYONLAR_TOP
*&---------------------------------------------------------------------*

 "DATA: gv_belgen TYPE belnr_d.
*
* PARAMETERS: p_val TYPE char20.
*
* DATA: gv_htype LIKE dd01v-datatype.

*DATA: gv_num1   TYPE int4,
*      gv_num2   TYPE int4,
*      gv_result TYPE int4.

CLASS math_op DEFINITION.
  PUBLIC SECTION.
    DATA: lv_num1   TYPE i,
          lv_num2   TYPE i,
          lv_result TYPE i.

    METHODS: sum_numbers.
ENDCLASS.

CLASS math_op_diff DEFINITION INHERITING FROM math_op.
  PUBLIC SECTION.
    METHODS numb_diff.
ENDCLASS.



DATA: go_class TYPE REF TO math_op.
DATA: go_class_v2 TYPE REF TO math_op_diff.
