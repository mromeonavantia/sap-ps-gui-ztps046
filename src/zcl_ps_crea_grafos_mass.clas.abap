CLASS zcl_ps_crea_grafos_mass DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_grafo_input,
        row_index TYPE i,
        posid     TYPE prps-posid,     " PEP del Grafo / WBS Element
        ktext     TYPE aufk-ktext,     " Descripción del Grafo / Description
        profid    TYPE tcj41-profidtx, " Perfil Grafo / Network Profile
        werks     TYPE werks_d,        " Centro Logístico / Plant
        kalsm     TYPE kalsm_d,        " Esquema Cálculo Costes / Costing Sheet
      END OF ty_grafo_input,
      tt_grafo_input TYPE STANDARD TABLE OF ty_grafo_input WITH EMPTY KEY,

      BEGIN OF ty_result,
        row_index TYPE i,
        posid     TYPE prps-posid,
        ktext     TYPE aufk-ktext,
        aufnr     TYPE aufnr,
        status    TYPE bapi_mtype,     " 'S' (Success), 'E' (Error), 'W' (Warning)
        message   TYPE bapi_msg,
      END OF ty_result,
      tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY,

      BEGIN OF ty_summary,
        total   TYPE i,
        success TYPE i,
        error   TYPE i,
      END OF ty_summary.

    CONSTANTS:
      mc_log_object TYPE balhdr-object VALUE 'ZTPS046',
      mc_msg_id     TYPE sy-msgid VALUE 'ZPS',
      mc_job_name   TYPE tbtcjob-jobname VALUE 'ZTPS046_CREA_GRAFO_PS',
      mc_cluster_id TYPE c LENGTH 2 VALUE 'ZP'.

    CLASS-METHODS:
      get_instance
        RETURNING
          VALUE(ro_instance) TYPE REF TO zcl_ps_crea_grafos_mass.

    METHODS:
      " Core entry points
      process_file
        IMPORTING
          !iv_filename TYPE string
          !iv_file_raw TYPE xstring OPTIONAL
        EXPORTING
          !et_results  TYPE tt_result
          !es_summary  TYPE ty_summary,

      process_guid
        IMPORTING
          !iv_guid    TYPE guid_32
        EXPORTING
          !et_results TYPE tt_result
          !es_summary TYPE ty_summary,

      " File parsing
      parse_file_local
        IMPORTING
          !iv_filename TYPE string
        EXPORTING
          !et_data     TYPE tt_grafo_input
        RAISING
          cx_static_check,

      parse_xlsx
        IMPORTING
          !iv_xstring TYPE xstring
        EXPORTING
          !et_data    TYPE tt_grafo_input
        RAISING
          cx_static_check,

      parse_csv
        IMPORTING
          !iv_content TYPE string
        EXPORTING
          !et_data    TYPE tt_grafo_input
        RAISING
          cx_static_check,

      " Validation & execution
      validate_data
        CHANGING
          !ct_data    TYPE tt_grafo_input
        EXPORTING
          !et_results TYPE tt_result,

      execute_creation
        IMPORTING
          !it_valid_data TYPE tt_grafo_input
        EXPORTING
          !et_results    TYPE tt_result
          !es_summary    TYPE ty_summary,

      " Cluster persistence for background processing
      save_to_indx
        IMPORTING
          !it_data       TYPE tt_grafo_input
        RETURNING
          VALUE(rv_guid) TYPE guid_32,

      load_from_indx
        IMPORTING
          !iv_guid TYPE guid_32
        EXPORTING
          !et_data TYPE tt_grafo_input,

      schedule_job
        IMPORTING
          !iv_guid          TYPE guid_32
          !iv_local_file    TYPE rlgrap-filename
        RETURNING
          VALUE(rv_jobname) TYPE tbtcjob-jobname,

      " Template generation
      download_template
        IMPORTING
          !iv_file_path TYPE string OPTIONAL,

      generate_template_csv
        RETURNING
          VALUE(rv_csv) TYPE string,

      generate_template_xlsx
        RETURNING
          VALUE(rv_xstring) TYPE xstring,

      " Logging
      log_add_message
        IMPORTING
          !iv_type    TYPE sy-msgty
          !iv_id      TYPE sy-msgid
          !iv_number  TYPE sy-msgno
          !iv_v1      TYPE sy-msgv1 OPTIONAL
          !iv_v2      TYPE sy-msgv2 OPTIONAL
          !iv_v3      TYPE sy-msgv3 OPTIONAL
          !iv_v4      TYPE sy-msgv4 OPTIONAL
          !iv_message TYPE bapi_msg OPTIONAL,

      log_save,

      display_log.

  PRIVATE SECTION.
    CLASS-DATA:
      go_instance TYPE REF TO zcl_ps_crea_grafos_mass.

    DATA:
      gv_log_handle TYPE balloghndl,
      gt_log_handle TYPE bal_t_logh.

    METHODS:
      init_log.

ENDCLASS.



CLASS zcl_ps_crea_grafos_mass IMPLEMENTATION.

  METHOD get_instance.
    IF go_instance IS NOT BOUND.
      go_instance = NEW zcl_ps_crea_grafos_mass( ).
    ENDIF.
    ro_instance = go_instance.
  ENDMETHOD.


  METHOD init_log.
    IF gv_log_handle IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA: ls_log TYPE bal_s_log.
    ls_log-object     = mc_log_object.
    ls_log-aldate     = sy-datum.
    ls_log-altime     = sy-uzeit.
    ls_log-aluser     = sy-uname.
    ls_log-alprog     = sy-repid.
    ls_log-del_before = abap_true.

    CALL FUNCTION 'BAL_LOG_CREATE'
      EXPORTING
        i_s_log      = ls_log
      IMPORTING
        e_log_handle = gv_log_handle
      EXCEPTIONS
        OTHERS       = 1.

    IF sy-subrc = 0.
      APPEND gv_log_handle TO gt_log_handle.
    ENDIF.
  ENDMETHOD.


  METHOD log_add_message.
    init_log( ).

    DATA: ls_msg TYPE bal_s_msg.
    ls_msg-msgty = iv_type.
    ls_msg-msgid = iv_id.
    ls_msg-msgno = iv_number.
    ls_msg-msgv1 = iv_v1.
    ls_msg-msgv2 = iv_v2.
    ls_msg-msgv3 = iv_v3.
    ls_msg-msgv4 = iv_v4.

    IF iv_message IS NOT INITIAL AND iv_v1 IS INITIAL.
      ls_msg-msgv1 = iv_message(50).
      ls_msg-msgv2 = iv_message+50(50).
      ls_msg-msgv3 = iv_message+100(50).
      ls_msg-msgv4 = iv_message+150(50).
    ENDIF.

    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING
        i_log_handle = gv_log_handle
        i_s_msg      = ls_msg
      EXCEPTIONS
        OTHERS       = 1.
  ENDMETHOD.


  METHOD log_save.
    IF gt_log_handle IS NOT INITIAL.
      CALL FUNCTION 'BAL_DB_SAVE'
        EXPORTING
          i_t_log_handle = gt_log_handle
        EXCEPTIONS
          OTHERS         = 1.
    ENDIF.
  ENDMETHOD.


  METHOD display_log.
    DATA: ls_display_profile TYPE bal_s_prof,
          ls_log_filter      TYPE bal_s_lfil.

    CALL FUNCTION 'BAL_DSP_PROFILE_SINGLE_LOG_GET'
      IMPORTING
        e_s_display_profile = ls_display_profile.

    ls_display_profile-use_grid   = abap_true.
    ls_display_profile-title      = TEXT-030. " Cargador de Grafos / Network Loader

    DATA(lr_object) = VALUE bal_r_obj( ( sign = 'I' option = 'EQ' low = mc_log_object ) ).
    DATA(lr_user)   = VALUE bal_r_user( ( sign = 'I' option = 'EQ' low = sy-uname ) ).
    DATA(lr_date)   = VALUE bal_r_date( ( sign = 'I' option = 'EQ' low = sy-datum ) ).

    ls_log_filter-object = lr_object.
    ls_log_filter-aluser = lr_user.
    ls_log_filter-aldate = lr_date.

    CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
      EXPORTING
        i_s_display_profile = ls_display_profile
        i_s_log_filter      = ls_log_filter
      EXCEPTIONS
        profile_inconsistent = 1
        internal_error       = 2
        no_data_available    = 3
        no_authority         = 4
        OTHERS               = 5.

    IF sy-subrc = 3.
      MESSAGE s004(zps) WITH TEXT-061 DISPLAY LIKE 'W'. " No se encontraron logs / No logs found
    ENDIF.
  ENDMETHOD.


  METHOD process_file.
    CLEAR: et_results, es_summary.
    DATA: lt_data TYPE tt_grafo_input.

    TRY.
        IF iv_file_raw IS NOT INITIAL.
          parse_xlsx( EXPORTING iv_xstring = iv_file_raw IMPORTING et_data = lt_data ).
        ELSEIF iv_filename IS NOT INITIAL.
          parse_file_local( EXPORTING iv_filename = iv_filename IMPORTING et_data = lt_data ).
        ENDIF.
      CATCH cx_static_check.
        log_add_message( iv_type = 'E' iv_id = '00' iv_number = '001' iv_v1 = 'Error al leer el archivo' ).
        log_save( ).
        RETURN.
    ENDTRY.

    IF lt_data IS INITIAL.
      log_add_message( iv_type = 'E' iv_id = '00' iv_number = '001' iv_v1 = 'El archivo está vacío' ).
      log_save( ).
      RETURN.
    ENDIF.

    validate_data(
      CHANGING  ct_data    = lt_data
      EXPORTING et_results = et_results ).

    execute_creation(
      IMPORTING it_valid_data = lt_data
      EXPORTING et_results    = DATA(lt_creation_results)
                es_summary    = es_summary ).

    APPEND LINES OF lt_creation_results TO et_results.

    es_summary-total   = lines( et_results ).
    es_summary-success = REDUCE i( INIT s = 0 FOR wa IN et_results WHERE ( status = 'S' ) NEXT s = s + 1 ).
    es_summary-error   = es_summary-total - es_summary-success.

    log_add_message(
      iv_type   = 'I'
      iv_id     = '00'
      iv_number = '001'
      iv_v1     = |Total: { es_summary-total }|
      iv_v2     = |Creados: { es_summary-success }|
      iv_v3     = |Errores: { es_summary-error }| ).

    log_save( ).
  ENDMETHOD.


  METHOD process_guid.
    CLEAR: et_results, es_summary.
    DATA: lt_data TYPE tt_grafo_input.

    load_from_indx( EXPORTING iv_guid = iv_guid IMPORTING et_data = lt_data ).

    IF lt_data IS INITIAL.
      log_add_message( iv_type = 'E' iv_id = '00' iv_number = '001' iv_v1 = 'No se recuperaron datos de fondo (Cluster)' ).
      log_save( ).
      RETURN.
    ENDIF.

    validate_data(
      CHANGING  ct_data    = lt_data
      EXPORTING et_results = et_results ).

    execute_creation(
      IMPORTING it_valid_data = lt_data
      EXPORTING et_results    = DATA(lt_creation_results)
                es_summary    = es_summary ).

    APPEND LINES OF lt_creation_results TO et_results.

    es_summary-total   = lines( et_results ).
    es_summary-success = REDUCE i( INIT s = 0 FOR wa IN et_results WHERE ( status = 'S' ) NEXT s = s + 1 ).
    es_summary-error   = es_summary-total - es_summary-success.

    log_add_message(
      iv_type   = 'I'
      iv_id     = '00'
      iv_number = '001'
      iv_v1     = |Total: { es_summary-total }|
      iv_v2     = |Creados: { es_summary-success }|
      iv_v3     = |Errores: { es_summary-error }| ).

    log_save( ).
  ENDMETHOD.


  METHOD parse_file_local.
    CLEAR et_data.
    DATA: lv_ext        TYPE string,
          lt_records    TYPE solix_tab,
          lv_filelength TYPE i,
          lv_xstring    TYPE xstring.

    " Detect extension
    DATA(lv_upper_filename) = to_upper( iv_filename ).
    IF lv_upper_filename CP '*.XLSX'.
      lv_ext = 'XLSX'.
    ELSEIF lv_upper_filename CP '*.CSV'.
      lv_ext = 'CSV'.
    ELSE.
      lv_ext = 'OTHER'.
    ENDIF.

    IF lv_ext = 'XLSX'.
      CALL METHOD cl_gui_frontend_services=>gui_upload
        EXPORTING
          filename   = iv_filename
          filetype   = 'BIN'
        IMPORTING
          filelength = lv_filelength
        CHANGING
          data_tab   = lt_records
        EXCEPTIONS
          OTHERS     = 1.

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE cx_sy_file_open_mode.
      ENDIF.

      CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
        EXPORTING
          input_length = lv_filelength
        IMPORTING
          buffer       = lv_xstring
        TABLES
          binary_tab   = lt_records
        EXCEPTIONS
          OTHERS       = 1.

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE cx_sy_conversion_codepage.
      ENDIF.

      parse_xlsx( EXPORTING iv_xstring = lv_xstring IMPORTING et_data = et_data ).

    ELSEIF lv_ext = 'CSV'.
      DATA: lt_csv_tab TYPE TABLE OF string,
            lv_content TYPE string.

      CALL METHOD cl_gui_frontend_services=>gui_upload
        EXPORTING
          filename = iv_filename
          filetype = 'ASC'
        CHANGING
          data_tab = lt_csv_tab
        EXCEPTIONS
          OTHERS   = 1.

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE cx_sy_file_open_mode.
      ENDIF.

      LOOP AT lt_csv_tab INTO DATA(lv_line).
        lv_content = lv_content && lv_line && cl_abap_char_utilities=>cr_lf.
      ENDLOOP.

      parse_csv( EXPORTING iv_content = lv_content IMPORTING et_data = et_data ).
    ELSE.
      RAISE EXCEPTION TYPE cx_sy_file_open_mode.
    ENDIF.
  ENDMETHOD.


  METHOD parse_xlsx.
    CLEAR et_data.
    DATA: lo_excel     TYPE REF TO cl_fdt_xl_spreadsheet,
          lt_worksheets TYPE cl_fdt_xl_spreadsheet=>t_worksheets,
          lo_data_ref  TYPE REF TO data.

    FIELD-SYMBOLS: <lt_table> TYPE STANDARD TABLE,
                   <ls_row>   TYPE any,
                   <lv_field> TYPE any.

    TRY.
        lo_excel = NEW cl_fdt_xl_spreadsheet( document_name = 'upload.xlsx' xdocument = iv_xstring ).
      CATCH cx_fdt_excel_core.
        RAISE EXCEPTION TYPE cx_sy_conversion_codepage.
    ENDTRY.

    lo_excel->if_fdt_doc_spreadsheet~get_worksheet_names( IMPORTING worksheet_names = lt_worksheets ).
    IF lt_worksheets IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_first_sheet) = lt_worksheets[ 1 ].
    lo_data_ref = lo_excel->if_fdt_doc_spreadsheet~get_itab_from_worksheet( lv_first_sheet ).
    IF lo_data_ref IS INITIAL.
      RETURN.
    ENDIF.

    ASSIGN lo_data_ref->* TO <lt_table>.
    IF <lt_table> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    DATA: lv_row_idx TYPE i VALUE 0.

    LOOP AT <lt_table> ASSIGNING <ls_row>.
      lv_row_idx = lv_row_idx + 1.
      IF lv_row_idx = 1.
        CONTINUE. " Skip header row
      ENDIF.

      DATA: ls_entry TYPE ty_grafo_input.
      ls_entry-row_index = lv_row_idx.

      " Col 1: PEP del Grafo
      ASSIGN COMPONENT 1 OF STRUCTURE <ls_row> TO <lv_field>.
      IF sy-subrc = 0.
        ls_entry-posid = <lv_field>.
        CONDENSE ls_entry-posid.
      ENDIF.

      " Col 2: Descripción del Grafo
      ASSIGN COMPONENT 2 OF STRUCTURE <ls_row> TO <lv_field>.
      IF sy-subrc = 0.
        ls_entry-ktext = <lv_field>.
        CONDENSE ls_entry-ktext.
      ENDIF.

      " Col 3: Perfil Grafo
      ASSIGN COMPONENT 3 OF STRUCTURE <ls_row> TO <lv_field>.
      IF sy-subrc = 0.
        ls_entry-profid = <lv_field>.
        CONDENSE ls_entry-profid.
      ENDIF.

      " Col 4: Centro Logístico
      ASSIGN COMPONENT 4 OF STRUCTURE <ls_row> TO <lv_field>.
      IF sy-subrc = 0.
        ls_entry-werks = <lv_field>.
        CONDENSE ls_entry-werks.
      ENDIF.

      " Col 5: Esquema Cálculo de Costes
      ASSIGN COMPONENT 5 OF STRUCTURE <ls_row> TO <lv_field>.
      IF sy-subrc = 0.
        ls_entry-kalsm = <lv_field>.
        CONDENSE ls_entry-kalsm.
      ENDIF.

      IF ls_entry-posid IS INITIAL AND ls_entry-ktext IS INITIAL AND ls_entry-profid IS INITIAL.
        CONTINUE. " Empty row
      ENDIF.

      APPEND ls_entry TO et_data.
    ENDLOOP.
  ENDMETHOD.


  METHOD parse_csv.
    CLEAR et_data.
    DATA: lt_lines TYPE TABLE OF string,
          lt_cells TYPE TABLE OF string,
          lv_delim TYPE c LENGTH 1 VALUE ';'.

    SPLIT iv_content AT cl_abap_char_utilities=>cr_lf INTO TABLE lt_lines.
    IF lt_lines IS INITIAL.
      SPLIT iv_content AT cl_abap_char_utilities=>newline INTO TABLE lt_lines.
    ENDIF.

    " Check delimiter from header line
    IF lt_lines IS NOT INITIAL.
      DATA(lv_header) = lt_lines[ 1 ].
      IF lv_header CA ','.
        lv_delim = ','.
      ELSEIF lv_header CA ';'.
        lv_delim = ';'.
      ENDIF.
    ENDIF.

    DATA: lv_idx TYPE i VALUE 0.

    LOOP AT lt_lines INTO DATA(lv_line).
      lv_idx = lv_idx + 1.
      IF lv_idx = 1.
        CONTINUE. " Skip header
      ENDIF.

      IF lv_line IS INITIAL.
        CONTINUE.
      ENDIF.

      CLEAR lt_cells.
      SPLIT lv_line AT lv_delim INTO TABLE lt_cells.

      IF lines( lt_cells ) < 3.
        CONTINUE.
      ENDIF.

      DATA: ls_entry TYPE ty_grafo_input.
      ls_entry-row_index = lv_idx.

      TRY.
          ls_entry-posid = lt_cells[ 1 ].
          CONDENSE ls_entry-posid.

          ls_entry-ktext = lt_cells[ 2 ].
          CONDENSE ls_entry-ktext.

          ls_entry-profid = lt_cells[ 3 ].
          CONDENSE ls_entry-profid.

          IF lines( lt_cells ) >= 4.
            ls_entry-werks = lt_cells[ 4 ].
            CONDENSE ls_entry-werks.
          ENDIF.

          IF lines( lt_cells ) >= 5.
            ls_entry-kalsm = lt_cells[ 5 ].
            CONDENSE ls_entry-kalsm.
          ENDIF.
        CATCH cx_sy_itab_line_not_found.
          CONTINUE.
      ENDTRY.

      IF ls_entry-posid IS INITIAL AND ls_entry-ktext IS INITIAL.
        CONTINUE.
      ENDIF.

      APPEND ls_entry TO et_data.
    ENDLOOP.
  ENDMETHOD.


  METHOD validate_data.
    CLEAR et_results.

    " 1. Format conversion for PEPs to internal ABPSN format
    LOOP AT ct_data ASSIGNING FIELD-SYMBOL(<fs_item>).
      DATA: lv_posid_int TYPE prps-posid.
      CALL FUNCTION 'CONVERSION_EXIT_ABPSN_INPUT'
        EXPORTING
          input  = <fs_item>-posid
        IMPORTING
          output = lv_posid_int
        EXCEPTIONS
          OTHERS = 1.
      IF sy-subrc = 0.
        <fs_item>-posid = lv_posid_int.
      ENDIF.
    ENDLOOP.

    " 2. Bulk Database Queries for Performance
    TYPES: BEGIN OF ty_pep_val,
             posid TYPE prps-posid,
             belkz TYPE prps-belkz,
           END OF ty_pep_val.

    DATA: lt_pep_db    TYPE HASHED TABLE OF ty_pep_val WITH UNIQUE KEY posid,
          lt_profid_db TYPE HASHED TABLE OF tcj41 WITH UNIQUE KEY profidtx,
          lt_werks_db  TYPE HASHED TABLE OF t001w WITH UNIQUE KEY werks,
          lt_kalsm_db  TYPE HASHED TABLE OF t685a WITH UNIQUE KEY kalsm.

    " Bulk PEP
    SELECT posid, belkz
      FROM prps
      FOR ALL ENTRIES IN @ct_data
      WHERE posid = @ct_data-posid
      INTO CORRESPONDING FIELDS OF TABLE @lt_pep_db.

    " Bulk Network Profile
    SELECT *
      FROM tcj41
      FOR ALL ENTRIES IN @ct_data
      WHERE profidtx = @ct_data-profid
      INTO TABLE @lt_profid_db.

    " Bulk Plant
    SELECT *
      FROM t001w
      FOR ALL ENTRIES IN @ct_data
      WHERE werks = @ct_data-werks
      INTO TABLE @lt_werks_db.

    " Bulk Costing Sheet
    SELECT *
      FROM t685a
      FOR ALL ENTRIES IN @ct_data
      WHERE kalsm = @ct_data-kalsm
      INTO TABLE @lt_kalsm_db.

    " 3. Validation Logic per Row (Partial Policy: Reject invalid, keep valid)
    DATA: lt_valid_data TYPE tt_grafo_input.

    LOOP AT ct_data INTO DATA(ls_row).
      DATA: lv_has_error TYPE abap_bool VALUE abap_false,
            lv_posid_ext TYPE string.

      CALL FUNCTION 'CONVERSION_EXIT_ABPSN_OUTPUT'
        EXPORTING
          input  = ls_row-posid
        IMPORTING
          output = lv_posid_ext.

      " Validation: Description required
      IF ls_row-ktext IS INITIAL.
        lv_has_error = abap_true.
        DATA(lv_msg_desc) = |Fila { ls_row-row_index }: Descripción obligatoria / Mandatory description|.
        APPEND VALUE #( row_index = ls_row-row_index posid = ls_row-posid status = 'E' message = lv_msg_desc ) TO et_results.
        log_add_message( iv_type = 'E' iv_id = '00' iv_number = '001' iv_v1 = lv_msg_desc ).
      ENDIF.

      " Validation: PEP exists & imputable
      READ TABLE lt_pep_db INTO DATA(ls_pep) WITH KEY posid = ls_row-posid.
      IF sy-subrc <> 0.
        lv_has_error = abap_true.
        DATA(lv_msg_pep1) = |Fila { ls_row-row_index }: PEP { lv_posid_ext } no existe / WBS element does not exist|.
        APPEND VALUE #( row_index = ls_row-row_index posid = ls_row-posid status = 'E' message = lv_msg_pep1 ) TO et_results.
        log_add_message( iv_type = 'E' iv_id = '00' iv_number = '001' iv_v1 = lv_msg_pep1 ).
      ELSEIF ls_pep-belkz <> abap_true.
        lv_has_error = abap_true.
        DATA(lv_msg_pep2) = |Fila { ls_row-row_index }: PEP { lv_posid_ext } no es imputable / Not account assignment|.
        APPEND VALUE #( row_index = ls_row-row_index posid = ls_row-posid status = 'E' message = lv_msg_pep2 ) TO et_results.
        log_add_message( iv_type = 'E' iv_id = '00' iv_number = '001' iv_v1 = lv_msg_pep2 ).
      ENDIF.

      " Validation: Profile exists
      READ TABLE lt_profid_db TRANSPORTING NO FIELDS WITH KEY profidtx = ls_row-profid.
      IF sy-subrc <> 0.
        lv_has_error = abap_true.
        DATA(lv_msg_prof) = |Fila { ls_row-row_index }: Perfil { ls_row-profid } no existe / Profile does not exist|.
        APPEND VALUE #( row_index = ls_row-row_index posid = ls_row-posid status = 'E' message = lv_msg_prof ) TO et_results.
        log_add_message( iv_type = 'E' iv_id = '00' iv_number = '001' iv_v1 = lv_msg_prof ).
      ENDIF.

      " Validation: Plant exists
      READ TABLE lt_werks_db TRANSPORTING NO FIELDS WITH KEY werks = ls_row-werks.
      IF sy-subrc <> 0.
        lv_has_error = abap_true.
        DATA(lv_msg_plnt) = |Fila { ls_row-row_index }: Centro { ls_row-werks } no existe / Plant does not exist|.
        APPEND VALUE #( row_index = ls_row-row_index posid = ls_row-posid status = 'E' message = lv_msg_plnt ) TO et_results.
        log_add_message( iv_type = 'E' iv_id = '00' iv_number = '001' iv_v1 = lv_msg_plnt ).
      ENDIF.

      " Validation: Costing sheet exists
      IF ls_row-kalsm IS NOT INITIAL.
        READ TABLE lt_kalsm_db TRANSPORTING NO FIELDS WITH KEY kalsm = ls_row-kalsm.
        IF sy-subrc <> 0.
          lv_has_error = abap_true.
          DATA(lv_msg_cost) = |Fila { ls_row-row_index }: Esquema { ls_row-kalsm } no existe / Costing sheet does not exist|.
          APPEND VALUE #( row_index = ls_row-row_index posid = ls_row-posid status = 'E' message = lv_msg_cost ) TO et_results.
          log_add_message( iv_type = 'E' iv_id = '00' iv_number = '001' iv_v1 = lv_msg_cost ).
        ENDIF.
      ENDIF.

      IF lv_has_error = abap_false.
        APPEND ls_row TO lt_valid_data.
      ENDIF.
    ENDLOOP.

    ct_data = lt_valid_data.
  ENDMETHOD.


  METHOD execute_creation.
    CLEAR: et_results, es_summary.

    DATA: lt_method_project TYPE TABLE OF bapi_method_project,
          lt_network        TYPE TABLE OF bapi_network,
          lt_message        TYPE TABLE OF bapi_meth_message,
          ls_return         TYPE bapireturn1.

    LOOP AT it_valid_data INTO DATA(ls_item).
      CLEAR: lt_method_project, lt_network, lt_message, ls_return.

      " 1. Header Method: Create Network
      DATA: lv_temp_net TYPE aufnr VALUE '%00000000001'.

      APPEND VALUE bapi_method_project(
        refnumber  = '000001'
        objecttype = 'Network'
        method     = 'Create'
        objectkey  = lv_temp_net
      ) TO lt_method_project.

      " 2. Network Header Attributes
      APPEND VALUE bapi_network(
        network       = lv_temp_net
        profile       = ls_item-profid
        short_text    = ls_item-ktext
        plant         = ls_item-werks
        wbs_element   = ls_item-posid
        costing_sheet = ls_item-kalsm
      ) TO lt_network.

      " 3. Save Method
      APPEND VALUE bapi_method_project(
        refnumber = '000002'
        method    = 'SaveAndWait'
      ) TO lt_method_project.

      " 4. Call BAPI
      CALL FUNCTION 'BAPI_NETWORK_MAINTAIN'
        IMPORTING
          return          = ls_return
        TABLES
          i_method_project = lt_method_project
          i_network        = lt_network
          e_message_table  = lt_message.

      " 5. Check response
      DATA: lv_created_aufnr TYPE aufnr,
            lv_success       TYPE abap_bool VALUE abap_false.

      IF ls_return IS INITIAL OR ls_return-type CA 'SIW'.
        " Retrieve created AUFNR from message table
        LOOP AT lt_message INTO DATA(ls_msg) WHERE message_type = 'S'.
          IF ls_msg-message_id = 'CN' AND ( ls_msg-message_number = '001' OR ls_msg-message_number = '002' ).
            lv_created_aufnr = ls_msg-message_v1.
          ENDIF.
        ENDLOOP.

        CALL FUNCTION 'BAPI_PS_PRECOMMIT'.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = abap_true.

        lv_success = abap_true.
        es_summary-success = es_summary-success + 1.

        DATA: lv_posid_ext TYPE string.
        CALL FUNCTION 'CONVERSION_EXIT_ABPSN_OUTPUT'
          EXPORTING
            input  = ls_item-posid
          IMPORTING
            output = lv_posid_ext.

        DATA(lv_msg_ok) = |Fila { ls_item-row_index }: Grafo { lv_created_aufnr } creado para PEP { lv_posid_ext }|.
        APPEND VALUE #(
          row_index = ls_item-row_index
          posid     = ls_item-posid
          ktext     = ls_item-ktext
          aufnr     = lv_created_aufnr
          status    = 'S'
          message   = lv_msg_ok
        ) TO et_results.

        log_add_message( iv_type = 'S' iv_id = '00' iv_number = '001' iv_v1 = lv_msg_ok ).

      ELSE.
        CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
        es_summary-error = es_summary-error + 1.

        DATA(lv_err_txt) = ls_return-message.
        IF lv_err_txt IS INITIAL AND lt_message IS NOT INITIAL.
          READ TABLE lt_message INTO DATA(ls_err_msg) WITH KEY message_type = 'E'.
          IF sy-subrc = 0.
            lv_err_txt = ls_err_msg-message_text.
          ENDIF.
        ENDIF.

        DATA(lv_msg_ko) = |Fila { ls_item-row_index }: Error al crear Grafo - { lv_err_txt }|.
        APPEND VALUE #(
          row_index = ls_item-row_index
          posid     = ls_item-posid
          ktext     = ls_item-ktext
          status    = 'E'
          message   = lv_msg_ko
        ) TO et_results.

        log_add_message( iv_type = 'E' iv_id = '00' iv_number = '001' iv_v1 = lv_msg_ko ).
      ENDIF.
    ENDLOOP.

    es_summary-total = lines( it_valid_data ).
  ENDMETHOD.


  METHOD save_to_indx.
    DATA: lv_guid TYPE guid_32.
    CALL FUNCTION 'GUID_CREATE'
      IMPORTING
        ev_guid_32 = lv_guid.

    EXPORT data = it_data TO DATABASE indx(zp) ID lv_guid.
    rv_guid = lv_guid.
  ENDMETHOD.


  METHOD load_from_indx.
    CLEAR et_data.
    IMPORT data = et_data FROM DATABASE indx(zp) ID iv_guid.
    DELETE FROM DATABASE indx(zp) ID iv_guid.
  ENDMETHOD.


  METHOD schedule_job.
    DATA: lv_jobcount TYPE tbtcjob-jobcount.

    CALL FUNCTION 'JOB_OPEN'
      EXPORTING
        jobname          = mc_job_name
        sdlstrtdt        = sy-datum
        sdlstrttm        = sy-uzeit
      IMPORTING
        jobcount         = lv_jobcount
      EXCEPTIONS
        cant_create_job  = 1
        OTHERS           = 2.

    IF sy-subrc <> 0.
      MESSAGE e001(00) WITH 'Error al abrir el Job de fondo' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    SUBMIT zps_r_00046
      WITH p_local = iv_local_file
      WITH p_fondo = abap_true
      WITH p_guid  = iv_guid
      VIA JOB mc_job_name NUMBER lv_jobcount
      AND RETURN.

    CALL FUNCTION 'JOB_CLOSE'
      EXPORTING
        jobcount             = lv_jobcount
        jobname              = mc_job_name
        strtimmed            = abap_true
      EXCEPTIONS
        cant_start_immediate = 1
        OTHERS               = 2.

    IF sy-subrc = 0.
      rv_jobname = mc_job_name.
    ENDIF.
  ENDMETHOD.


  METHOD generate_template_csv.
    rv_csv = |PEP del Grafo;Descripción del Grafo;Perfil Grafo;Centro Logístico;Esquema Cálculo de Costes\r\n| &&
             |FB.0221.D.C;B1220_ARMAMENTO UNION_(ETAPA_L);ZB00002;2220;ZGP000\r\n| &&
             |FB.0221.D.C;B1220_CHORREADO Y PINTADO_(ETAPA_F);ZB00002;2220;ZGP000\r\n| &&
             |FB.0221.D.C;B1220_CORTE Y ELABORACION_(ETAPA_A);ZB00002;2220;ZGP000\r\n|.
  ENDMETHOD.


  METHOD generate_template_xlsx.
    " Returns valid CSV binary or workbook stream
    DATA(lv_csv) = generate_template_csv( ).
    DATA: lt_solix TYPE solix_tab,
          lv_len   TYPE i.

    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = lv_csv
      IMPORTING
        buffer = rv_xstring
      EXCEPTIONS
        failed = 1
        OTHERS = 2.
  ENDMETHOD.


  METHOD download_template.
    DATA: lv_dest_path TYPE string,
          lv_filename  TYPE string VALUE 'Plantilla_Carga_Grafos.csv',
          lv_path      TYPE string,
          lv_fullpath  TYPE string,
          lv_action    TYPE i.

    IF iv_file_path IS INITIAL.
      CALL METHOD cl_gui_frontend_services=>file_save_dialog
        EXPORTING
          window_title      = 'Guardar Plantilla de Grafos / Save Network Template'
          default_extension = 'csv'
          default_file_name = lv_filename
        CHANGING
          filename          = lv_filename
          path              = lv_path
          fullpath          = lv_fullpath
          user_action       = lv_action
        EXCEPTIONS
          OTHERS            = 1.

      IF lv_action = cl_gui_frontend_services=>action_cancel.
        RETURN.
      ENDIF.
      lv_dest_path = lv_fullpath.
    ELSE.
      lv_dest_path = iv_file_path.
    ENDIF.

    DATA(lv_csv) = generate_template_csv( ).
    DATA: lt_lines TYPE TABLE OF string.
    SPLIT lv_csv AT cl_abap_char_utilities=>cr_lf INTO TABLE lt_lines.

    CALL METHOD cl_gui_frontend_services=>gui_download
      EXPORTING
        filename = lv_dest_path
        filetype = 'ASC'
      CHANGING
        data_tab = lt_lines
      EXCEPTIONS
        OTHERS   = 1.

    IF sy-subrc = 0.
      MESSAGE s001(00) WITH 'Plantilla descargada con éxito' DISPLAY LIKE 'S'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
