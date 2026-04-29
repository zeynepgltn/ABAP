*&---------------------------------------------------------------------*
*& Include          ZGZ_P_OO_004_CLS
*&---------------------------------------------------------------------*
CLASS cl_controller IMPLEMENTATION.
  METHOD create_instance.
    IF mo_instance IS INITIAL.
      mo_instance = NEW cl_controller( ).
    ENDIF.
    r_obj = mo_instance.
  ENDMETHOD.

  METHOD initialization.
    "txt_p1 = 'Belge No'.
  ENDMETHOD.

  METHOD get_data.
    IF it_belgen IS INITIAL.
      SELECT vbeln, erdat, ernam
         FROM vbak
         INTO TABLE @gt_vbak.
    ELSE.
      SELECT vbeln, erdat, ernam
       FROM vbak
       INTO TABLE @gt_vbak
       WHERE vbeln IN @it_belgen.
    ENDIF.

    SORT gt_vbak.
  ENDMETHOD.

  METHOD pbo.
    CASE iv_dynnr.
      WHEN '0100'.
        SET PF-STATUS 'STATUS'.
        SET TITLEBAR  '100'.

        IF go_alv IS INITIAL.
          me->set_fieldcat( ).
          me->set_layout( ).
        ENDIF.
        me->display_alv( ).

    ENDCASE.
  ENDMETHOD.

  METHOD pai.
    CASE sy-ucomm.
      WHEN '&BACK'.
        SET SCREEN 0.
        LEAVE SCREEN.
    ENDCASE.
  ENDMETHOD.

  METHOD set_fieldcat.
    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name       = 'ZGZ_S_VBAK'
        i_client_never_display = 'X'
      CHANGING
        ct_fieldcat            = gt_fcat
      EXCEPTIONS
        inconsistent_interface = 1
        program_error          = 2
        OTHERS                 = 3.

    LOOP AT gt_fcat ASSIGNING <gfs_fc>.
      IF <gfs_fc>-fieldname = 'VBELN'.
        <gfs_fc>-hotspot = 'X'.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD set_layout.
    CLEAR: gs_layout.

    gs_layout-cwidth_opt = abap_true.
    gs_layout-zebra = abap_true.
  ENDMETHOD.


  METHOD display_alv.
    IF go_alv IS INITIAL.
      " Ana
      go_cont = NEW cl_gui_docking_container(
        repid = sy-repid
        dynnr = sy-dynnr
        side  = cl_gui_docking_container=>dock_at_bottom
        ratio = 95 ).

      " Splitter
      go_splitter = NEW cl_gui_splitter_container(
        parent  = go_cont
        rows    = 2
        columns = 1 ).

      " üst
      go_splitter->get_container(
      EXPORTING
        row = 1
        column = 1
      RECEIVING
       container = go_sub_left ).

      " alt
      go_splitter->get_container(
      EXPORTING
        row = 2
        column = 1
      RECEIVING
        container = go_sub_right ).

      " alt yok
      go_splitter->set_row_height(
      EXPORTING
        id = 2
         height = 0 ).

      " üst ALV
      go_alv = NEW cl_gui_alv_grid(
       i_parent = go_sub_left ).

      SET HANDLER me->handle_hotspot_click FOR go_alv.

      go_alv->set_table_for_first_display(
        EXPORTING
          is_layout = gs_layout
        CHANGING
          it_outtab = gt_vbak
          it_fieldcatalog = gt_fcat ).
    ELSE.
      go_alv->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.

  METHOD handle_hotspot_click.
    DATA: ls_vbak TYPE gty_vbak.

    READ TABLE gt_vbak INTO ls_vbak INDEX es_row_no-row_id.
    CHECK sy-subrc = 0.

    CASE e_column_id.
      WHEN 'VBELN'.
        IF gv_current_vbeln = ls_vbak-vbeln AND gv_right_open = abap_true.
          " Aynı vbeln'e tekrar tıklandı,id iki olanı sıfırla
          go_splitter->set_row_height(
          EXPORTING
            id = 2
             height = 0 ).

          gv_right_open = abap_false.
          CLEAR gv_current_vbeln.
        ELSE.
          " Farklı vbeln
          gv_current_vbeln = ls_vbak-vbeln.
          gv_right_open    = abap_true.

          " Kalemler
          CLEAR gt_vbap.
          SELECT * FROM vbap INTO TABLE gt_vbap
            WHERE vbeln = gv_current_vbeln.

          " Fieldcat oluştur
          IF gt_fcatt IS INITIAL.
            CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
              EXPORTING
                i_structure_name   = 'VBAP'
                i_bypassing_buffer = 'X'
              CHANGING
                ct_fieldcat        = gt_fcatt.
          ENDIF.

          " Alt ALV ac
          go_splitter->set_row_height(
          EXPORTING
            id = 2
             height = 50 ).

          " Nesne daha önce yaratıldı mı
          IF go_alvv IS INITIAL.
            go_alvv = NEW cl_gui_alv_grid(
            i_parent = go_sub_right ).

            go_alvv->set_table_for_first_display(
              EXPORTING
                is_layout       = gs_layout
              CHANGING
                it_outtab       = gt_vbap
                it_fieldcatalog = gt_fcatt ).
          ELSE.
            go_alvv->refresh_table_display(
             EXPORTING i_soft_refresh = space ).
          ENDIF.
        ENDIF.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
