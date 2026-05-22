*&---------------------------------------------------------------------*
*& Include          ZGZ_I_SAS_GELISIM_CLS
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

  ENDMETHOD.

  METHOD pbo.
    CASE iv_dynnr.
      WHEN '1000'.
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

  ENDMETHOD.
ENDCLASS.
