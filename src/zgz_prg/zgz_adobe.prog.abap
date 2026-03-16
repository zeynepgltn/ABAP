*&---------------------------------------------------------------------*
*& Report ZGZ_ADOBE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_adobe.

DATA: gs_outputparams TYPE  sfpoutputparams,
      gv_name         TYPE  fpname,
      gv_funcname     TYPE  funcname,
      gs_docparams    TYPE  sfpdocparams,
      gs_formoutput   TYPE  fpformoutput,
      gv_barcode      TYPE char10.

START-OF-SELECTION.

  gv_barcode = '1232344543'.

  gs_outputparams-nodialog = abap_true.
  gs_outputparams-preview = abap_true.
  gs_outputparams-dest = 'LP01'.

  CALL FUNCTION 'FP_JOB_OPEN'
    CHANGING
      ie_outputparams = gs_outputparams
    EXCEPTIONS
      cancel          = 1
      usage_error     = 2
      system_error    = 3
      internal_error  = 4
      OTHERS          = 5.

  gv_name = 'ZGZ_F_ADOBE'.

  CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
    EXPORTING
      i_name     = gv_name
    IMPORTING
      e_funcname = gv_funcname.
*     E_INTERFACE_TYPE           =
*     EV_FUNCNAME_INBOUND        =


  CALL FUNCTION gv_funcname
    EXPORTING
      /1bcdwb/docparams  = gs_docparams
      iv_barcode         = gv_barcode
      "iv_header_t1       =
    IMPORTING
      /1bcdwb/formoutput = gs_formoutput
    EXCEPTIONS
      usage_error        = 1
      system_error       = 2
      internal_error     = 3
      OTHERS             = 4.

  CALL FUNCTION 'FP_JOB_CLOSE'
*   IMPORTING
*     E_RESULT             =
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.
