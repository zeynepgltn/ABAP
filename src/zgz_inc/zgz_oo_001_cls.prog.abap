*&---------------------------------------------------------------------*
*& Include          ZGZ_OO_001_CLS
*&---------------------------------------------------------------------*

CLASS cl_event_receiver DEFINITION .

  PUBLIC SECTION.
    METHODS handle_top_of_page
      FOR EVENT top_of_page OF cl_gui_alv_grid
      IMPORTING
        e_dyndoc_id "go_title
        table_index.

    METHODS handle_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING
        e_row_id
        e_column_id.

    METHODS handle_double_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING
        e_row
        e_column
        es_row_no.

    METHODS handle_data_changed
      FOR EVENT data_changed OF cl_gui_alv_grid
      IMPORTING
        er_data_changed "Değişen tüm veriye bu nesne üzerinden
        e_onf4        "Değişiklik bir F4 yardımıyla mı yapıldı
        e_onf4_before " Veri değişmeden hemen önce F4'ün tetiklenip tetiklenmediğini belirtir.
        e_onf4_after  "f4 işlemi bittikten ve veri hücreye yazıldıktan sonra tetiklendiğini belirtir.
        e_ucomm. "User Command

    METHODS handle_onf4
      FOR EVENT onf4 OF cl_gui_alv_grid
      IMPORTING
        e_fieldname
        e_fieldvalue
        es_row_no
        er_event_data "Seçilen değeri hücreye geri yazmanızı ve standart F4'ü iptal etmemizi sağlayan kontrol nesnesidir.
        et_bad_cells "F4 işlemi sırasında oluşan hatalı veya geçersiz veri girişlerinin listesini barındırır.
        e_display. "Hücrenin o an sadece izleme (X) mi yoksa düzenleme (boş) modunda mı olduğunu belirtir.


    METHODS handle_button_click
      FOR EVENT button_click OF cl_gui_alv_grid
      IMPORTING
        es_col_id
        es_row_no.

    METHODS handle_toolbar "ALV ekranı ilk açıldığında veya refresh_table_display dendiğinde tetiklenir,buton ekleme
      FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING
        e_object
        e_interactive.

    METHODS handle_user_command
      FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING
        e_ucomm.


  PRIVATE SECTION.
    DATA: mv_mess   TYPE string,           " Ortak mesaj değişkeni,member
          ms_stable TYPE lvc_s_stbl.       " Ortak refresh ayarı

ENDCLASS.



CLASS cl_event_receiver IMPLEMENTATION.

  METHOD handle_top_of_page.
    DATA: lv_text TYPE sdydo_text_element.

    lv_text = 'FLIGHT'.

    CALL METHOD go_title->add_text
      EXPORTING
        text         = lv_text                " Single Text, Up To 255 Characters Long
*       text_table   =                  " Table With Single Texts
*       fix_lines    =                  " If 'X': TEXT_TABLE Display in Lines, Otherwise Continuous
*       sap_style    = cl_dd_document=>heading              " Recommended Styles
        sap_color    = cl_dd_document=>list_positive                " Not Release 99
*       sap_fontsize =                  " Recommended Font Sizes
*       sap_fontstyle =                  " Not Release 99
        sap_emphasis = cl_dd_document=>strong                 " Text Highlighting
*       style_class  =                  " Not Release 99
*       a11y_tooltip =                  " A11Y: Additional Explanation
*      CHANGING
*       document     =                  " x
      .

    CALL METHOD go_title->new_line
*      EXPORTING
*        repeat =                  " Method Executed REPEAT+1 Times
      .

    CLEAR: lv_text.

    CONCATENATE 'User:' sy-uname INTO lv_text SEPARATED BY space.

    CALL METHOD go_title->add_text
      EXPORTING
        text      = lv_text               " Single Text, Up To 255 Characters Long
*       text_table   =                  " Table With Single Texts
*       fix_lines =                  " If 'X': TEXT_TABLE Display in Lines, Otherwise Continuous
*       sap_style = cl_dd_document=>heading                 " Recommended Styles
        sap_color = cl_dd_document=>list_negative                     " Not Release 99
*       sap_fontsize =                  " Recommended Font Sizes
*       sap_fontstyle =                  " Not Release 99
*       sap_emphasis = cl_dd_document=>strong                   " Text Highlighting
*       style_class  =                  " Not Release 99
*       a11y_tooltip =                  " A11Y: Additional Explanation
*      CHANGING
*       document  =                  " x
      .

    CALL METHOD go_title->display_document
      EXPORTING
*       reuse_control      =                  " HTML Control Reused
*       reuse_registration =                  " Event Registration Reused
*       container          =                  " Name of Container (New Container Object Generated)
        parent = go_sub1           " Contain Object Already Exists
*      EXCEPTIONS
*       html_display_error = 1                " Error Displaying the Document in the HTML Control
*       others = 2
      .
    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

  ENDMETHOD.                    "handle top of page

  METHOD handle_hotspot_click. "genelde kolon

    READ TABLE gt_scarr INTO gs_scarr INDEX e_row_id-index.

    IF sy-subrc EQ 0.
      CASE e_column_id-fieldname.
        WHEN 'CARRID' .
          CONCATENATE 'Tıklanan kolon:'
                       e_column_id-fieldname
                       'değeri:'
                       gs_scarr-carrid
                       INTO mv_mess
                       SEPARATED BY space.
      ENDCASE.

      MESSAGE mv_mess TYPE 'I'.
    ENDIF.
  ENDMETHOD.                    "handle hotspot click

  METHOD handle_double_click. "genelde satır

    READ TABLE gt_scarr INTO gs_scarr INDEX e_row-index.

    IF sy-subrc EQ 0.

      CONCATENATE 'Çitf tıklanan satır:'
                   e_row-index
                   INTO mv_mess
                   SEPARATED BY space.

      MESSAGE mv_mess TYPE 'I'.
    ENDIF.
  ENDMETHOD.                    "handle double click

  METHOD handle_data_changed.
    DATA: ls_modi TYPE lvc_s_modi.

    " Kullanıcının değiştirdiği hücreler arasında
    LOOP AT er_data_changed->mt_mod_cells INTO ls_modi. "kullanıcının gdeğiştirdiği hücrelerin listesini tutan dahili bir tablosu.

      " Eski değer
      READ TABLE gt_scarr INTO gs_scarr INDEX ls_modi-row_id.

      IF sy-subrc = 0.
        mv_mess = |Alan: { ls_modi-fieldname } | &&
                  |Yeni Değer: { ls_modi-value }|.        " Kullanıcının girdiği değer

        MESSAGE mv_mess TYPE 'I'.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.                    "handle data changed

  METHOD handle_onf4.
    TYPES: BEGIN OF lty_value_tab,
             carrname TYPE s_carrname,
             carrdeff TYPE char20,
           END OF lty_value_tab.

    DATA: lt_value_tab TYPE TABLE OF lty_value_tab,
          ls_value_tab TYPE lty_value_tab.

    DATA: lt_return_tab TYPE TABLE OF ddshretval,
          ls_return_tab TYPE ddshretval.

    ms_stable-row = 'X'.
    ms_stable-col = 'X'.

    CLEAR: ls_value_tab.
    ls_value_tab-carrname = 'Uçuş 1'.
    ls_value_tab-carrdeff = '1'.
    APPEND ls_value_tab TO lt_value_tab.

    CLEAR: ls_value_tab.
    ls_value_tab-carrname = 'Uçuş 2'.
    ls_value_tab-carrdeff = '2'.
    APPEND ls_value_tab TO lt_value_tab.


    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
*       ddic_structure  = ' '
        retfield        = 'CARRDEFF'
*       pvalkey         = ' '
*       dynpprog        = ' '
*       dynpnr          = ' '
*       dynprofield     = ' '
*       stepl           = 0
        window_title    = 'CARRNAME F4'
*       VALUE           = ' '
        value_org       = 'S'
        multiple_choice = ' '
*       DISPLAY         = ' '
*       callback_program = ' '
*       callback_form   = ' '
*       callback_method =
*       mark_tab        =
*      IMPORTING
*       user_reset      =
      TABLES
        value_tab       = lt_value_tab
*       field_tab       =
        return_tab      = lt_return_tab
*       dynpfld_mapping =
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.

    READ TABLE lt_return_tab INTO ls_return_tab WITH KEY fieldname = 'F0002'. "returnden oku

    IF sy-subrc EQ 0.
      READ TABLE gt_scarr ASSIGNING <gfs_scarr> INDEX es_row_no-row_id. "eski değeri oku

      IF sy-subrc EQ 0.
        <gfs_scarr>-carrname = ls_return_tab-fieldval. "yenile
      ENDIF.
    ENDIF.

    er_event_data->m_event_handled = 'X'. "standardı devre dışı bırakma

    go_grid->refresh_table_display(
      EXPORTING
        is_stable      =   ms_stable               " With Stable Rows/Columns
*        i_soft_refresh =                  " Without Sort, Filter, etc.
*      EXCEPTIONS
*        finished       = 1                " Display was Ended (by Export)
*        others         = 2
    ).

    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ENDMETHOD.                    "handle onf4

  METHOD handle_button_click.

    READ TABLE gt_scarr INTO gs_scarr INDEX es_row_no-row_id.

    IF sy-subrc EQ 0.
      CONCATENATE 'Tıklanan button'
                   es_col_id-fieldname
                   ','
                   INTO mv_mess
                   SEPARATED BY space.
    ENDIF.

    MESSAGE mv_mess TYPE 'I'.

  ENDMETHOD.

  METHOD handle_toolbar. "toolbar button ekleme
    DATA: ls_toolbar TYPE stb_button.

    CLEAR: ls_toolbar.

    ls_toolbar-function = '&DEL'.
    ls_toolbar-text = 'Sil'.
    ls_toolbar-icon = '@11@'.
    ls_toolbar-quickinfo = 'Silme İşlemi'.
    "ls_toolbar-disabled = abap_true.

    APPEND ls_toolbar TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD handle_user_command. "toolbar button tıklanınca olacak işlem
    CASE e_ucomm.
      WHEN '&DEL'.
        MESSAGE 'DELETE' TYPE 'I'.
    ENDCASE.
  ENDMETHOD.


ENDCLASS.
