*&---------------------------------------------------------------------*
*& Include          ZGZ_OO_001_FORM
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data .
  SELECT *
    FROM scarr
    INTO CORRESPONDING FIELDS OF TABLE gt_scarr. " SCARR tablosundaki tüm veriyi çek

  SELECT *
    FROM sflight
    INTO CORRESPONDING FIELDS OF TABLE gt_sflight. " SCARR tablosundaki tüm veriyi çek

  LOOP AT gt_scarr ASSIGNING <gfs_scarr>." Tablo satırını <gfs_scarr>'e bağlar

    <gfs_scarr>-delete = '@33@'.

    CASE <gfs_scarr>-currcode. " Tablo satırı anında değişir
      WHEN 'EUR'.
        <gfs_scarr>-line_color = 'C600'.
        <gfs_scarr>-dd_handle = '3'.

        CLEAR: gs_cell_style.

        gs_cell_style-fieldname = 'LOCATION'.
        gs_cell_style-style = cl_gui_alv_grid=>mc_style_disabled.
        gs_cell_style-style = '000000001'.

        APPEND  gs_cell_style TO <gfs_scarr>-cell_style.

      WHEN 'CAD'.
        CLEAR gs_cell_color.

        gs_cell_color-fname = 'URL'.
        gs_cell_color-color-col = '7'.
        gs_cell_color-color-int = '1'.
        gs_cell_color-color-inv = '0'.

        APPEND gs_cell_color TO <gfs_scarr>-cell_color.

        CLEAR gs_cell_color.

        gs_cell_color-fname = 'CURRCODE'.
        gs_cell_color-color-col = '5'.
        gs_cell_color-color-int = '0'.
        gs_cell_color-color-inv = '0'.

        APPEND gs_cell_color TO <gfs_scarr>-cell_color.

        <gfs_scarr>-dd_handle = '4'.

        CLEAR: gs_cell_style.

        gs_cell_style-fieldname = 'LOCATION'.
        gs_cell_style-style = cl_gui_alv_grid=>mc_style_disabled.
        gs_cell_style-style = '00000000'.

        APPEND  gs_cell_style TO <gfs_scarr>-cell_style.
    ENDCASE.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_layout
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_layout .
  CLEAR: gs_layout.

  gs_layout-cwidth_opt = abap_true.
*  gs_layout-edit = abap_true.
*  gs_layout-no_toolbar = abap_true.
*  gs_layout-zebra = abap_true.
  gs_layout-info_fname = 'LINE_COLOR'.
  gs_layout-ctab_fname = 'CELL_COLOR'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_fcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_fcat .
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE        = ' '
      i_structure_name       = 'ZGZ_OO_SSCARR'
*     I_CLIENT_NEVER_DISPLAY = 'X'
      i_bypassing_buffer     = 'X'
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = gt_fcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
  "Eğer tip tanımlamazsam ve structure daha fazla alanlıysa fonksiyon son alanları dolu alanları çiftleyerek doldurur

  LOOP AT gt_fcat ASSIGNING <gfs_fc>.
    CASE <gfs_fc>-fieldname.
      WHEN 'SITUATION'.
        <gfs_fc>-reptext   = 'Durum'.
        <gfs_fc>-scrtext_s = 'Durum'.

      WHEN 'CARRID'.
        <gfs_fc>-hotspot   = abap_true.

      WHEN 'CARRNAME'.
        <gfs_fc>-edit      = abap_true.
*        <gfs_fc>-f4availabl  = abap_true.
        <gfs_fc>-style  = cl_gui_alv_grid=>mc_style_f4.

      WHEN 'AMOUNT'.
        <gfs_fc>-scrtext_s = 'Miktar'.
        <gfs_fc>-edit      = abap_true.

      WHEN 'LOCATION'.
        <gfs_fc>-scrtext_s = 'Lokasyon'.
        <gfs_fc>-edit      = abap_true.
        <gfs_fc>-drdn_hndl = 1.

      WHEN 'SEATS'.
        <gfs_fc>-scrtext_s = 'Koltuk'.
        <gfs_fc>-edit      = abap_true.
        <gfs_fc>-drdn_hndl = 2.

      WHEN 'SEATP'.
        <gfs_fc>-scrtext_s = 'Koltuk P'.
        <gfs_fc>-edit      = abap_true.
        <gfs_fc>-drdn_field = 'DD_HANDLE'.

      WHEN 'DELETE'. "pushbuttın cell
        <gfs_fc>-scrtext_s = 'Sil'.
        <gfs_fc>-style = cl_gui_alv_grid=>mc_style_button.
        <gfs_fc>-ıcon = abap_true.
    ENDCASE.
  ENDLOOP.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
*     I_BUFFER_ACTIVE        = ' '
      i_structure_name       = 'SFLIGHT'
*     I_CLIENT_NEVER_DISPLAY = 'X'
      i_bypassing_buffer     = 'X'
*     I_INTERNAL_TABNAME     =
    CHANGING
      ct_fieldcat            = gt_fcat2
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_total_sum
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_total_sum .
  DATA: lv_ttl_sum   TYPE int4,
        lv_ttl_sum_c TYPE char10,
        lv_mess      TYPE char200,
        lv_lines     TYPE int4,
        lv_avr       TYPE int4.

  LOOP AT gt_scarr INTO gs_scarr.
    lv_ttl_sum = lv_ttl_sum + gs_scarr-amount.
  ENDLOOP.

  DESCRIBE TABLE gt_scarr LINES lv_lines.

  lv_avr = lv_ttl_sum / lv_lines.


  LOOP AT gt_scarr ASSIGNING <gfs_scarr>.
    IF <gfs_scarr>-amount > lv_avr.
      <gfs_scarr>-situation = '@08@'. " Yeşil/Yüksek
    ELSEIF <gfs_scarr>-amount < lv_avr.
      <gfs_scarr>-situation = '@0A@'. " Kırmızı/Düşük
    ELSE.
      <gfs_scarr>-situation = '@09@'. " Sarı/Eşit
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_dropdown
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_dropdown .
  DATA: lt_dropdown TYPE lvc_t_drop,
        ls_dropdown TYPE lvc_s_drop.

  DATA: lt_dropdown_alias TYPE lvc_t_dral,
        ls_dropdown_alias TYPE lvc_s_dral.

*  CLEAR ls_dropdown_alias.
*  ls_dropdown_alias-handle = 2.
*  ls_dropdown_alias-value  = 'A_CLS'.
*  ls_dropdown_alias-alias  = 'A Sınıfı Kalite'.
*  APPEND ls_dropdown_alias TO lt_dropdown_alias.

  CLEAR: ls_dropdown.
  ls_dropdown-handle = 1.
  ls_dropdown-value = 'Yurt İçi'.
  APPEND ls_dropdown TO lt_dropdown.


  CLEAR: ls_dropdown.
  ls_dropdown-handle = 1.
  ls_dropdown-value = 'Yurt Dışı'.
  APPEND ls_dropdown TO lt_dropdown.

  CLEAR: ls_dropdown.
  ls_dropdown-handle = 2.
  ls_dropdown-value = 'A'.
  APPEND ls_dropdown TO lt_dropdown.

  CLEAR: ls_dropdown.
  ls_dropdown-handle = 2.
  ls_dropdown-value = 'B'.
  APPEND ls_dropdown TO lt_dropdown.

  CLEAR: ls_dropdown.
  ls_dropdown-handle = 2.
  ls_dropdown-value = 'C'.
  APPEND ls_dropdown TO lt_dropdown.

  CLEAR: ls_dropdown.
  ls_dropdown-handle = 3.
  ls_dropdown-value = 'Ön'.
  APPEND ls_dropdown TO lt_dropdown.

  CLEAR: ls_dropdown.
  ls_dropdown-handle = 3.
  ls_dropdown-value = 'Arka'.
  APPEND ls_dropdown TO lt_dropdown.

  CLEAR: ls_dropdown.
  ls_dropdown-handle = 3.
  ls_dropdown-value = 'Kanat'.
  APPEND ls_dropdown TO lt_dropdown.

  CLEAR: ls_dropdown.
  ls_dropdown-handle = 4.
  ls_dropdown-value = 'Ön'.
  APPEND ls_dropdown TO lt_dropdown.

  CLEAR: ls_dropdown.
  ls_dropdown-handle = 4.
  ls_dropdown-value = 'Kanat'.
  APPEND ls_dropdown TO lt_dropdown.

  go_grid->set_drop_down_table(
    it_drop_down       = lt_dropdown                 " Dropdown Table
    "it_drop_down_alias =  ls_dropdown_alias               " ALV Control: Dropdown List Boxes
  ).
ENDFORM.

*&---------------------------------------------------------------------*
*& Form register_f4
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM register_f4 .
  DATA: lt_f4 TYPE lvc_t_f4,
        ls_f4 TYPE lvc_s_f4.

  CLEAR: ls_f4.

  ls_f4-fieldname = 'CARRNAME'.
  ls_f4-register = abap_true.

  APPEND ls_f4 TO lt_f4.

  CALL METHOD go_grid->register_f4_for_fields
    EXPORTING
      it_f4 = lt_f4.                  " F4 Fields
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_excluding
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_excluding .
  CLEAR: gv_excluding.
  gv_excluding = cl_gui_alv_grid=>mc_fc_pc_file.
  APPEND gv_excluding TO gt_excluding.

  CLEAR: gv_excluding.
  gv_excluding = cl_gui_alv_grid=>mc_fc_sort_dsc.
  APPEND gv_excluding TO gt_excluding.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_sort
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_sort .
  CLEAR: gs_sort.
  gs_sort-spos = 1.
  gs_sort-fieldname = 'CURRCODE'.
  gs_sort-down = abap_true.
  APPEND gs_sort TO gt_sort.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form set_filter
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_filter .
  CLEAR: gs_filt.
  gs_filt-tabname = 'GS_SCARR'.
  gs_filt-fieldname = 'CURRCODE'.
  gs_filt-sign = 'I'.
  gs_filt-option = 'EQ'.
  gs_filt-low = 'EUR'.
  APPEND gs_filt TO gt_filt.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  IF go_grid IS INITIAL.

    CREATE OBJECT go_cont
      EXPORTING
*       parent                      =                  " Parent container
        container_name              = 'CC_ALV'                 " Name of the Screen CustCtrl Name to Link Container To
*       style                       =                  " Windows Style Attributes Applied to this Container
*       lifetime                    = lifetime_default " Lifetime
*       repid                       =                  " Screen to Which this Container is Linked
*       dynnr                       =                  " Report To Which this Container is Linked
*       no_autodef_progid_dynnr     =                  " Don't Autodefined Progid and Dynnr?
      EXCEPTIONS
        cntl_error                  = 1                " CNTL_ERROR
        cntl_system_error           = 2                " CNTL_SYSTEM_ERROR
        create_error                = 3                " CREATE_ERROR
        lifetime_error              = 4                " LIFETIME_ERROR
        lifetime_dynpro_dynpro_link = 5                " LIFETIME_DYNPRO_DYNPRO_LINK
        OTHERS                      = 6.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.


    CREATE OBJECT go_splitter
      EXPORTING
*       link_dynnr        =                    " Screen Number
*       link_repid        =                    " Report Name
*       shellstyle        =                    " Window Style
*       left              =                    " Left-aligned
*       top               =                    " Top
*       width             =                    " NPlWidth
*       height            =                    " Hght
*       metric            = cntl_metric_dynpro " Metric
*       align             = 15                 " Alignment
        parent            = go_cont                  " Parent Container
        rows              = 2                   " Number of Rows to be displayed
        columns           = 2                  " Number of Columns to be Displayed
*       no_autodef_progid_dynnr =                    " Don't Autodefined Progid and Dynnr?
*       name              =                    " Name
      EXCEPTIONS
        cntl_error        = 1                  " See Superclass
        cntl_system_error = 2                  " See Superclass
        OTHERS            = 3.
    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.


    CALL METHOD go_splitter->set_row_height
      EXPORTING
        id     = 1                " Row ID
        height = 15                " Height
*      IMPORTING
*       result =                  " Result Code
*      EXCEPTIONS
*       cntl_error        = 1                " See CL_GUI_CONTROL
*       cntl_system_error = 2                " See CL_GUI_CONTROL
*       others = 3
      .

    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*       WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.


    go_splitter->set_row_sash(
      EXPORTING
        id                =  1                " Row Splitter Bar ID
        type              = cl_gui_splitter_container=>type_sashvisible               " Attribute
        value             = cl_gui_splitter_container=>false                 " Value
*      IMPORTING
*        result            =                  " Result Code
*      exceptions
*        cntl_error        = 1                " See CL_GUI_CONTROL
*        cntl_system_error = 2                " See CL_GUI_CONTROL
*        others            = 3
    ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.



    CREATE OBJECT go_title
      EXPORTING
        style            = 'ALV_GRID'                " Adjusting to the Style of a Particular GUI Environment
        background_color = cl_gui_resources=>list_col_group           " Color ID
*       bds_stylesheet   =                  " Use BDS Style Sheet
*       no_margins       =                  " 'X': Document Created Without Free Margins
      .


    CALL METHOD go_splitter->get_container
      EXPORTING
        row       = 1               " Row
        column    = 1               " Column
      RECEIVING
        container = go_sub1.


    CALL METHOD go_splitter->get_container
      EXPORTING
        row       = 2               " Row
        column    = 1               " Column
      RECEIVING
        container = go_sub2.                 " Container

    CALL METHOD go_splitter->get_container
      EXPORTING
        row       = 2               " Row
        column    = 2              " Column
      RECEIVING
        container = go_sub3.


    CREATE OBJECT go_grid
      EXPORTING
*       i_shellstyle      = 0                " Control Style
*       i_lifetime        =                  " Lifetime
        i_parent          = go_sub2  " Parent Container-FULL SCREEN
*       i_appl_events     = space            " Register Events as Application Events
*       i_parentdbg       =                  " Internal, Do not Use
*       i_applogparent    =                  " Container for Application Log
*       i_graphicsparent  =                  " Container for Graphics
*       i_name            =                  " Name
*       i_fcat_complete   = space            " Boolean Variable (X=True, Space=False)
*       o_previous_sral_handler =
*       i_use_one_ux_appearance = abap_false
      EXCEPTIONS
        error_cntl_create = 1                " Error when creating the control
        error_cntl_init   = 2                " Error While Initializing Control
        error_cntl_link   = 3                " Error While Linking Control
        error_dp_create   = 4                " Error While Creating DataProvider Control
        OTHERS            = 5.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    PERFORM set_dropdown.

    CREATE OBJECT go_event_receiver.
    SET HANDLER go_event_receiver->handle_top_of_page FOR go_grid.
    SET HANDLER go_event_receiver->handle_hotspot_click FOR go_grid.
    SET HANDLER go_event_receiver->handle_double_click FOR go_grid.
    SET HANDLER go_event_receiver->handle_data_changed FOR go_grid.
    SET HANDLER go_event_receiver->handle_onf4 FOR go_grid.
    SET HANDLER go_event_receiver->handle_button_click FOR go_grid.
    SET HANDLER go_event_receiver->handle_toolbar FOR go_grid.
    SET HANDLER go_event_receiver->handle_user_command FOR go_grid.

    PERFORM register_f4.
    PERFORM set_excluding.
    PERFORM set_sort.
    PERFORM set_filter.

    gs_variant-report = sy-repid.
    gs_variant-variant = p_vari.

    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING
*       i_buffer_active               =                  " Buffering Active
*       i_bypassing_buffer            =                  " Switch Off Buffer
*       i_consistency_check           =                  " Starting Consistency Check for Interface Error Recognition
*       i_structure_name              = 'SCARR'                " Internal Output Table Structure Name
        is_variant                    = gs_variant                " Layout
        i_save                        = 'A'                " Save Layout
*       i_default                     = 'X'              " Default Display Variant DEFAULT DÜZEN
        is_layout                     = gs_layout                " Layout
*       is_print                      =                  " Print Control
*       it_special_groups             =                  " Field Groups
        it_toolbar_excluding          = gt_excluding                 " Excluded Toolbar Standard Functions
*       it_hyperlink                  =                  " Hyperlinks
*       it_alv_graphics               =                  " Table of Structure DTC_S_TC
*       it_except_qinfo               =                  " Table for Exception Quickinfo
*       ir_salv_adapter               =                  " Interface ALV Adapter
      CHANGING
        it_outtab                     = gt_scarr                 " Output Table
        it_fieldcatalog               = gt_fcat                 " Field Catalog
        it_sort                       = gt_sort                " Sort Criteria
*       it_filter                     = gt_filt                 " Filter Criteria
      EXCEPTIONS
        invalid_parameter_combination = 1                " Wrong Parameter
        program_error                 = 2                " Program Errors
        too_many_lines                = 3                " Too many Rows in Ready for Input Grid
        OTHERS                        = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.


    CALL METHOD go_grid->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified   " Event ID
      EXCEPTIONS
        error      = 1                " Error
        OTHERS     = 2.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.


    CREATE OBJECT go_grid2
      EXPORTING
*       i_shellstyle      = 0                " Control Style
*       i_lifetime        =                  " Lifetime
        i_parent          = go_sub3  " Parent Container-FULL SCREEN
*       i_appl_events     = space            " Register Events as Application Events
*       i_parentdbg       =                  " Internal, Do not Use
*       i_applogparent    =                  " Container for Application Log
*       i_graphicsparent  =                  " Container for Graphics
*       i_name            =                  " Name
*       i_fcat_complete   = space            " Boolean Variable (X=True, Space=False)
*       o_previous_sral_handler =
*       i_use_one_ux_appearance = abap_false
      EXCEPTIONS
        error_cntl_create = 1                " Error when creating the control
        error_cntl_init   = 2                " Error While Initializing Control
        error_cntl_link   = 3                " Error While Linking Control
        error_dp_create   = 4                " Error While Creating DataProvider Control
        OTHERS            = 5.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.


    CALL METHOD go_grid2->set_table_for_first_display
      EXPORTING
*       i_buffer_active               =                  " Buffering Active
*       i_bypassing_buffer            =                  " Switch Off Buffer
*       i_consistency_check           =                  " Starting Consistency Check for Interface Error Recognition
*       i_structure_name              = 'SCARR'                " Internal Output Table Structure Name
*       is_variant                    =                  " Layout
*       i_save                        =                  " Save Layout
*       i_default                     = 'X'              " Default Display Variant
        is_layout                     = gs_layout                " Layout
*       is_print                      =                  " Print Control
*       it_special_groups             =                  " Field Groups
*       it_toolbar_excluding          =                  " Excluded Toolbar Standard Functions
*       it_hyperlink                  =                  " Hyperlinks
*       it_alv_graphics               =                  " Table of Structure DTC_S_TC
*       it_except_qinfo               =                  " Table for Exception Quickinfo
*       ir_salv_adapter               =                  " Interface ALV Adapter
      CHANGING
        it_outtab                     = gt_sflight                 " Output Table
        it_fieldcatalog               = gt_fcat2                 " Field Catalog
*       it_sort                       =                  " Sort Criteria
*       it_filter                     =                  " Filter Criteria
      EXCEPTIONS
        invalid_parameter_combination = 1                " Wrong Parameter
        program_error                 = 2                " Program Errors
        too_many_lines                = 3                " Too many Rows in Ready for Input Grid
        OTHERS                        = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.


    CALL METHOD go_grid->list_processing_events
      EXPORTING
        i_event_name = 'TOP_OF_PAGE'              " Event Name List Processing
        i_dyndoc_id  = go_title               " Dynamic Document
*       is_subtottxt_info =                  " Subtotal Text Information
*       ip_subtot_line    =                  " Subtotal Line
*       i_table_index     =                  " Loops, Current Loop Pass
*      CHANGING
*       c_subtottxt  =                  " Subtotal Text
      .

  ELSE.
    CALL METHOD go_grid->refresh_table_display
*      EXPORTING
*        is_stable      =                  " With Stable Rows/Columns
*        i_soft_refresh =                  " Without Sort, Filter, etc.
      EXCEPTIONS
        finished = 1                " Display was Ended (by Export)
        OTHERS   = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
ENDFORM.
