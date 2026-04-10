*&---------------------------------------------------------------------*
*& Report ZGZ_OO_002
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zgz_oo_002.

INCLUDE zgz_oo_002_top.
INCLUDE zgz_oo_002_cls.
INCLUDE zgz_oo_002_pbo.
INCLUDE zgz_oo_002_pai.

INITIALIZATION.

  " Radio buton ikonları ve açıklamaları
  ic1    = '@04@'.
  txt_r1 = 'Satış Siparişi (VBAK)'.
  ic2    = '@05@'.
  txt_r2 = 'Satınalma Siparişi (EKPO)'.

  " Dosya alanı
  txt_file = 'Dosya adı:'.

  gv_btn1 = 'Şablon indir'.
*  gv_btn2 = 'Şablon yükle'.

  " sscrfields-functxt_01 ifadesi SELECTION-SCREEN FUNCTION KEY 1'e denk gelir.
  sscrfields-functxt_01 = VALUE smp_dyntxt(
                            text      = 'Şablon İndir'
                            icon_id   = '@30@' " Excel/Dosya ikonu
                            quickinfo = 'Şablon İndir' ).

  CREATE OBJECT go_controller.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      window_title      = 'Excel Seç'
      default_extension = 'xlsx'
      file_filter       = 'Excel Files (*.xlsx)|*.xlsx'
    CHANGING
      file_table        = gt_files
      rc                = gv_rc ).

  IF gv_rc = 1.
    p_file = gt_files[ 1 ]-filename.
  ENDIF.


AT SELECTION-SCREEN.

  IF rb_1 = 'X'.
    go_controller->gv_rb = '1'.
  ELSE.
    go_controller->gv_rb = '2'.
  ENDIF.

  CASE sscrfields-ucomm.

    WHEN 'FC01' OR 'SABLOND'.
      DATA: bos_table     TYPE TABLE OF vbak,
            lv_boyut      TYPE i,
            lr_header_ref TYPE REF TO data.

      GET REFERENCE OF bos_table INTO lr_header_ref.

      go_controller->set_fcat( ).

      IF  go_controller->gv_rb = '1'.
        go_controller->get_excell(
        EXPORTING
         it_data     = lr_header_ref " importinge gönder,Metodun içine veri gönderiyorum
         it_fcat     = gt_fcat
        IMPORTING
          ev_file_size    = lv_boyut
      ).
      ELSE.
        go_controller->get_excell(
        EXPORTING
         it_data     = lr_header_ref " importinge gönder,Metodun içine veri gönderiyorum
         it_fcat     = gt_fcatt
        IMPORTING
          ev_file_size    = lv_boyut
      ).
      ENDIF.

*    WHEN 'SABLONU'.
*      IF rb_1 = 'X'.
*        go_controller->gv_rb = '1'.
*      ELSE.
*        go_controller->gv_rb = '2'.
*      ENDIF.
*
*      IF gt_fcat IS INITIAL OR gt_fcatt IS INITIAL.
*        go_controller->set_fcat( ).
*      ENDIF.
*
*      go_controller->set_layout( ). "layout da gelmeli
*      "Kullanıcı F8'e basmadan, doğrudan butona basarsa
*      "Bu durumda start() hiç çalışmadığı için set_layout() da çağrılmamış olur.
*
*      go_controller->excel_upload_cl( ).
*
*      " ALV'yi sıfırla
*      IF go_alv IS NOT INITIAL.
*        go_alv->free( ). "alv grid nesnesinin guı kaynaklarını serbest bırakır
*        FREE go_alv. "abap tarafındaki referansı initial yapar.
*      ENDIF.
*      IF go_cont IS NOT INITIAL.
*        go_cont->free( ).
*        FREE go_cont.
*      ENDIF.
*
*      CALL SCREEN '0100'.

  ENDCASE.


START-OF-SELECTION.
  " go_controller->start( ).

  IF rb_1 = 'X'.
    go_controller->gv_rb = '1'.
  ELSE.
    go_controller->gv_rb = '2'.
  ENDIF.

  IF p_file IS NOT INITIAL.
    gv_filename = p_file.
    go_controller->set_fcat( ). "şablona uygun gt_fcat
    go_controller->set_layout( ).
    go_controller->excel_upload_cl( ).
  ELSE.
    go_controller->start( ).
  ENDIF.

  IF go_alv IS NOT INITIAL. " f8e birden fazla kez basabilir
    go_alv->free( ).
    FREE go_alv.
  ENDIF.
  IF go_cont IS NOT INITIAL.
    go_cont->free( ).
    FREE go_cont.
  ENDIF.

  CALL SCREEN '0100'.
