*&---------------------------------------------------------------------*
*& Include ZGZ_I_SAT_EXCEL_CLS
*&---------------------------------------------------------------------*

CLASS cl_main IMPLEMENTATION.
  METHOD create_instance.
    IF mo_instance IS INITIAL.
      mo_instance = NEW cl_main( ).
    ENDIF.
    r_obj = mo_instance.
  ENDMETHOD.

  METHOD initialization.
  ENDMETHOD.

  METHOD at_selection_screen.
    CASE sy-ucomm.
      WHEN 'SABLOND'.
        me->excel_download( EXCEPTIONS download_error = 1 ).
    ENDCASE.
  ENDMETHOD.

  METHOD at_selection_screen_valreq.
    DATA: lv_rc        TYPE i,
          lt_filetable TYPE filetable.

    cl_gui_frontend_services=>file_open_dialog(
      EXPORTING  initial_directory = '&DESKTOP&'
                 file_filter       = 'Excel (*.xlsx)|*.xlsx'
      CHANGING   file_table        = lt_filetable
                 rc                = lv_rc
      EXCEPTIONS OTHERS            = 5 ).

    IF lv_rc = 1.
      p_file = lt_filetable[ 1 ]-filename.
    ENDIF.
  ENDMETHOD.

  METHOD run.
    IF p_file IS INITIAL .
      MESSAGE 'Dosya seçin.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    me->excel_upload_cl( ).

    IF mt_alv_data IS INITIAL.
      MESSAGE 'Excelde veri bulunamadı.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CALL SCREEN 0100.
  ENDMETHOD.

  METHOD pbo.
    SET PF-STATUS 'PF100'.
    SET TITLEBAR  'T100'.

    IF mo_grid IS INITIAL.
      "contanier
      mo_container = NEW cl_gui_docking_container(
        repid = sy-repid
         dynnr = '0100'
          side  = cl_gui_docking_container=>dock_at_bottom
           ratio = 95 ).

      mo_grid = NEW cl_gui_alv_grid( i_parent = mo_container ).

      ms_layout-cwidth_opt = ms_layout-zebra = abap_true.
      ms_variant-report = sy-repid.

      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name   = 'ZGZ_S_SAT_ALV'
          i_bypassing_buffer = 'X'
        CHANGING
          ct_fieldcat        = mt_fieldcat
        EXCEPTIONS
          OTHERS             = 3.

      LOOP AT mt_fieldcat ASSIGNING FIELD-SYMBOL(<fc>).
        CASE <fc>-fieldname.
          WHEN 'LIGHT'.
            <fc>-icon    = gc_yellow.
            <fc>-coltext = 'Durum'.
            <fc>-just    = 'C'. "hizalama
            <fc>-hotspot    = abap_true. " Üzerine tıklanabilir
          WHEN 'SELKZ'.
            <fc>-just     = 'C'.
            <fc>-key      = abap_true.
            <fc>-checkbox = abap_true.
            <fc>-edit     = abap_true.
            <fc>-scrtext_s = 'S'.
            <fc>-scrtext_m = 'Seçim'.
        ENDCASE.
      ENDLOOP.

      SET HANDLER me->handler_hotspot_click FOR mo_grid.
      SET HANDLER me->handler_toolbar      FOR mo_grid.
      SET HANDLER me->handler_user_command FOR mo_grid.

      mo_grid->set_table_for_first_display(
        EXPORTING
          is_variant = ms_variant
          i_save     = ' '
          is_layout  = ms_layout
        CHANGING
          it_outtab       = mt_alv_data
          it_fieldcatalog = mt_fieldcat ).
    ENDIF.
  ENDMETHOD.

  METHOD pai.
    DATA(lv_ucomm) = sy-ucomm.
    CLEAR sy-ucomm.

    CASE lv_ucomm.
      WHEN '&BACK'.
        IF mo_container IS NOT INITIAL.
          mo_container->free( ).
          FREE: mo_container, mo_grid.
        ENDIF.

        SET SCREEN 0.
        LEAVE SCREEN.
    ENDCASE.
  ENDMETHOD.

  METHOD excel_upload_cl.
    DATA: lv_bin_data TYPE xstring,
          ls_alv      TYPE ty_alv_data,
          lv_value    TYPE string,
          lv_idx      TYPE i,
          lv_type     TYPE c LENGTH 1,
          lv_date_str TYPE string,
          lv_date_int TYPE datum.

    me->read_xstring(
      EXPORTING iv_filename = CONV string( p_file )
      IMPORTING ev_xstring  = lv_bin_data ).

    IF lv_bin_data IS INITIAL. RETURN. ENDIF.

    DATA(lo_excel) = NEW cl_fdt_xl_spreadsheet(
      document_name = 'upload.xlsx'
      xdocument     = lv_bin_data ).

    lo_excel->if_fdt_doc_spreadsheet~get_worksheet_names(
      IMPORTING worksheet_names = DATA(lt_sheets) ).

    IF lt_sheets IS INITIAL. RETURN. ENDIF.

    DATA(lo_data_ref) = lo_excel->if_fdt_doc_spreadsheet~get_itab_from_worksheet(
      worksheet_name = lt_sheets[ 1 ] ).

    ASSIGN lo_data_ref->* TO FIELD-SYMBOL(<lt_data>).
    IF <lt_data> IS NOT ASSIGNED. RETURN. ENDIF.

    CLEAR mt_alv_data.

    LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
      IF sy-tabix = 1. CONTINUE. ENDIF.
      CLEAR ls_alv.

      DO.
        ASSIGN COMPONENT sy-index OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<fs_cell>).
        IF sy-subrc <> 0. EXIT. ENDIF. " Excel'de kolon bittiyse çık

        lv_idx = sy-index + 2. " LIGHT ve Selkz alanını atlamak için +1
        ASSIGN COMPONENT lv_idx OF STRUCTURE ls_alv TO FIELD-SYMBOL(<fs_target>).
        IF sy-subrc <> 0. CONTINUE. ENDIF. " Hedefte kolon yoksa durma, sıradakine bak

        IF <fs_cell> IS NOT INITIAL.
          DESCRIBE FIELD <fs_target> TYPE lv_type.

          CASE lv_type.
            WHEN 'D'. " TARİH İŞLEMLERİ
              lv_date_str = CONV string( <fs_cell> ). "string çevir
              CONDENSE lv_date_str NO-GAPS. "boşluk sil

              " SAP Standart Dönüştürme Denemesi
              CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
                EXPORTING
                  date_external            = lv_date_str
*                 ACCEPT_INITIAL_DATE      =
                IMPORTING
                  date_internal            = lv_date_int
                EXCEPTIONS
                  date_external_is_invalid = 1
                  OTHERS                   = 2.
              IF sy-subrc = 0.
                <fs_target> = lv_date_int.
              ELSE.
                " Manuel temizlik (Nokta, tire, bölü kaldır)
                REPLACE ALL OCCURRENCES OF '.' IN lv_date_str WITH ''.
                REPLACE ALL OCCURRENCES OF '/' IN lv_date_str WITH ''.
                REPLACE ALL OCCURRENCES OF '-' IN lv_date_str WITH ''.
                IF strlen( lv_date_str ) = 8.
                  <fs_target> = lv_date_str.
                ENDIF.
              ENDIF.

            WHEN OTHERS. " TARİH DIŞINDAKİ TÜM VERİLER (Metin, Sayı vb.)
              TRY.
                  <fs_target> = <fs_cell>.
                CATCH cx_root.
              ENDTRY.
          ENDCASE.
        ENDIF.
      ENDDO.

      ls_alv-light = '@5D@'.
      APPEND ls_alv TO mt_alv_data.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_xstring.
    DATA: lt_bin_tab TYPE solix_tab,
          lv_length  TYPE i.

    cl_gui_frontend_services=>gui_upload(
      EXPORTING filename = iv_filename filetype = 'BIN'
      IMPORTING filelength = lv_length
      CHANGING  data_tab = lt_bin_tab ).

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = lv_length
      IMPORTING
        buffer       = ev_xstring
      TABLES
        binary_tab   = lt_bin_tab.
  ENDMETHOD.

  METHOD excel_download.
    DATA: lv_xstring  TYPE xstring, lt_solix TYPE solix_tab, lv_size TYPE i,
          lv_filename TYPE string, lv_path TYPE string,
          lv_fullpath TYPE string, lv_action TYPE i,
          lr_data     TYPE REF TO data.

    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING default_file_name = 'SAT_Sablon'
                file_filter = 'Excel (*.xlsx)|*.xlsx'
      CHANGING  filename = lv_filename path = lv_path
                fullpath = lv_fullpath user_action = lv_action
      EXCEPTIONS OTHERS = 5 ).

    CHECK lv_action = cl_gui_frontend_services=>action_ok.

    " Fieldcat oluştur
    IF mt_fieldcat IS INITIAL.
      CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name   = 'ZGZ_S_SAT_ALV'
          i_bypassing_buffer = 'X'
        CHANGING
          ct_fieldcat        = mt_fieldcat
        EXCEPTIONS
          OTHERS             = 3.
    ENDIF.

    GET REFERENCE OF mt_alv_data INTO lr_data.

    DATA(lt_fcat_download) = mt_fieldcat.
    DELETE lt_fcat_download WHERE fieldname = 'LIGHT'
                                  OR fieldname = 'SELKZ'.


    me->get_xstring(
      EXPORTING it_data = lr_data it_fcat = lt_fcat_download
      IMPORTING ev_xstring = lv_xstring ).

    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer        = lv_xstring
      IMPORTING
        output_length = lv_size
      TABLES
        binary_tab    = lt_solix.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        bin_filesize = lv_size
        filename     = lv_fullpath
        filetype     = 'BIN'
      TABLES
        data_tab     = lt_solix
      EXCEPTIONS
        OTHERS       = 1.
  ENDMETHOD.

  METHOD get_xstring.
    DATA(lo_result) = cl_salv_ex_util=>factory_result_data_table(
      r_data = it_data t_fieldcatalog = it_fcat ).

    cl_salv_bs_tt_util=>if_salv_bs_tt_util~transform(
      EXPORTING r_result_data = lo_result
                xml_type = if_salv_bs_xml=>c_type_xlsx
      IMPORTING xml = ev_xstring ).
  ENDMETHOD.

  METHOD call_pr_bapi.
    DATA: ls_header   TYPE bapimereqheader,
          ls_headerx  TYPE bapimereqheaderx,
          lt_item     TYPE TABLE OF bapimereqitemimp,
          lt_itemx    TYPE TABLE OF bapimereqitemx,
          lt_account  TYPE TABLE OF bapimereqaccount,
          lt_accountx TYPE TABLE OF bapimereqaccountx,
          lt_text     TYPE TABLE OF bapimereqheadtext,
          lt_itemtext TYPE TABLE OF bapimereqitemtext,
          "lt_extension TYPE TABLE OF bapi_te_mereqitem,
          lt_return   TYPE TABLE OF bapiret2,
          lv_number   TYPE banfn,
          lv_item_no  TYPE bnfpo.

    mo_grid->check_changed_data( ).

    " Header (ilk seçili satırdan)
    READ TABLE mt_alv_data INTO DATA(ls_first) WITH KEY selkz = 'X'.
    IF sy-subrc <> 0.
      MESSAGE 'Lütfen satır seçiniz.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

*    ls_header-preq_no = ls_first-bsart.
*    ls_headerx-preq_no = abap_true.
    ls_header-pr_type = ls_first-bsart.
    ls_headerx-pr_type = abap_true.

    " Başlık Metni PRHEADERTEXT tablosuna
    IF ls_first-header_text IS NOT INITIAL.
      APPEND VALUE #(
        text_id   = 'B01' "Kalem metni (Item text)
        text_line = ls_first-header_text
      ) TO lt_text.
    ENDIF.

    " Items
    LOOP AT mt_alv_data ASSIGNING FIELD-SYMBOL(<d>) WHERE selkz IS NOT INITIAL.
      lv_item_no += 10. "kafama göre

      "item
      APPEND VALUE #(
        preq_item = lv_item_no
        acctasscat = <d>-knttp
       material = |{ <d>-matnr ALPHA = IN }|
        short_text = <d>-txz01
        quantity = <d>-menge
        deliv_date = <d>-lfdat
        plant = <d>-werks
        store_loc = <d>-lgort
        pur_group = |{ <d>-ekgrp ALPHA = IN }|
        preq_name  = <d>-afnam  ) TO lt_item.

      "xlisi
      APPEND VALUE #(
        preq_item = lv_item_no
        preq_itemx = abap_true
        acctasscat = abap_true
        material = abap_true
        short_text = abap_true
        quantity = abap_true
        deliv_date = abap_true
        plant = abap_true
        store_loc = abap_true
        pur_group = abap_true
        preq_name  = abap_true ) TO lt_itemx.

      " Kalem Metni PRITEMTEXT tablosuna
      IF <d>-item_text IS NOT INITIAL.
        APPEND VALUE #(
          preq_item = lv_item_no
          text_id   = 'B01' "Kalem metni (Item text)
          text_line = <d>-item_text
        ) TO lt_itemtext.
      ENDIF.

      "account
      IF <d>-knttp IS NOT INITIAL.
        DATA(ls_acc) = VALUE bapimereqaccount( preq_item = lv_item_no
        serial_no = '01' ).
        DATA(ls_accx) = VALUE bapimereqaccountx( preq_item = lv_item_no
        serial_no = '01'
        preq_itemx = abap_true ).

        CASE <d>-knttp.
          WHEN 'A'.  " Duran Varlık
            ls_acc-asset_no    = <d>-anln1.
            ls_accx-asset_no   = abap_true.

          WHEN 'K'.  " Masraf Yeri
            ls_acc-costcenter  = <d>-kostl.
            ls_accx-costcenter = abap_true.
            ls_acc-gl_account  = <d>-sakto.
            ls_accx-gl_account = abap_true.

          WHEN 'P'.  " Proje
            ls_acc-wbs_element  = <d>-ps_psp_pnr.
            ls_accx-wbs_element = abap_true.
        ENDCASE.

        APPEND ls_acc TO lt_account.
        APPEND ls_accx TO lt_accountx.
      ENDIF.

      "extension
*      IF <d>-zzbeden IS NOT INITIAL OR <d>-zzplaka IS NOT INITIAL OR <d>-zzmasrafyeri IS NOT INITIAL OR <d>-zzpyp IS NOT INITIAL.
*        APPEND VALUE bapi_te_mereqitem( preq_item = lv_item_no
*        zzbeden = <d>-zzbeden
*          zzplaka = <d>-zzplaka
*          zzmasrafyeri = <d>-zzmasrafyeri
*            zzpyp = <d>-zzpyp ) TO lt_extension.
*      ENDIF.
    ENDLOOP.

    " BAPI
    CALL FUNCTION 'BAPI_PR_CREATE'
      EXPORTING
        prheader     = ls_header
        prheaderx    = ls_headerx
      IMPORTING
        number       = lv_number "sat belgesi no
      TABLES
        pritem       = lt_item
        pritemx      = lt_itemx
        praccount    = lt_account
        praccountx   = lt_accountx
        prheadertext = lt_text
        pritemtext   = lt_itemtext
        "extensionin  = lt_extension
        return       = lt_return.

    " Sonuç
    "Eğer tablonun içinde en az bir tane bile hata ('E') veya kritik durdurma ('A') mesajı varsa, lv_error değişkenini 'X' (yani doğru/true) yap.
    DATA(lv_error) = xsdbool( line_exists( lt_return[ type = 'E' ] ) OR line_exists( lt_return[ type = 'A' ] ) ).

    IF lv_error = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
    ENDIF.

    " ALV güncelle
    LOOP AT mt_alv_data ASSIGNING <d> WHERE selkz IS NOT INITIAL.
      "BAPI'den dönen tüm hata veya başarı mesajlarını, o satıra kaydediyorum
      <d>-messages = lt_return.

      IF lv_error = abap_true.
        <d>-light = gc_red.
      ELSE.
        <d>-light = gc_green.
        "SAP'nin oluşturduğu yeni Satınalma Talebi numarası
        <d>-banfn = lv_number.
      ENDIF.
    ENDLOOP.

    " SAT  NUMVER
    IF lv_error = abap_false.
      MESSAGE |SAT belgesi { lv_number } başarıyla oluşturuldu.| TYPE 'S'.
    ELSE.
      MESSAGE 'Belge oluşturulamadı.' TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.

    mo_grid->refresh_table_display( EXPORTING is_stable =
      VALUE #( row = 'X' col = 'X' )
      i_soft_refresh = 'X' ).
  ENDMETHOD.

  METHOD handler_hotspot_click.
    READ TABLE mt_alv_data INTO DATA(ls_alv) INDEX es_row_no-row_id.
    CHECK sy-subrc IS INITIAL.

    CASE e_column_id.
      WHEN 'LIGHT'.
        IF ls_alv-messages IS NOT INITIAL.
          CALL FUNCTION 'C14ALD_BAPIRET2_SHOW'
            TABLES
              i_bapiret2_tab = ls_alv-messages.
        ELSE.
          MESSAGE | Mesaj yok.| TYPE 'I'.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD handler_toolbar.
    DATA: ls_btn TYPE stb_button.

    CLEAR ls_btn.
    ls_btn-function  = '&SC'.
*    ls_btn-icon      = '@39@'.
    ls_btn-icon      = '@4D@'.
    ls_btn-quickinfo = 'SAT Oluştur'.
    APPEND ls_btn TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD handler_user_command.
    CASE e_ucomm.
      WHEN '&SC'.
        me->call_pr_bapi( ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
