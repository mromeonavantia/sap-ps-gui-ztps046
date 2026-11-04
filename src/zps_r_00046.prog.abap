*&---------------------------------------------------------------------*
*& Report ZPS_R_00046
*&---------------------------------------------------------------------*
*& Transacción.: ZTPS046
*& Módulo......: PS - Project System
*& Descripción.: Creación en masa de Grafos desde fichero Excel/CSV
*&               (Mass Creation of Project Networks from Excel/CSV)
*& Arquitectura: Clean ABAP OO / Fiori-Ready / Multi-idioma (ES / EN)
*&---------------------------------------------------------------------*
REPORT zps_r_00046.

TABLES: sscrfields.

*----------------------------------------------------------------------*
* Selection Screen Definition (Misma interfaz gráfica que ZTPS047)
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK sbl_1 WITH FRAME TITLE TEXT-001.

  PARAMETERS: p_local TYPE rlgrap-filename.
  SELECTION-SCREEN SKIP 1.

  PARAMETERS: c_fondo AS CHECKBOX. " Procesar datos en segundo plano / Process in background

  SELECTION-SCREEN SKIP 1.
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN PUSHBUTTON 5(30) template USER-COMMAND xls.
  SELECTION-SCREEN END OF LINE.

  " Parámetros técnicos para proceso de fondo (No visibles)
  PARAMETERS: p_fondo TYPE flag    NO-DISPLAY,
              p_guid  TYPE guid_32 NO-DISPLAY.

SELECTION-SCREEN END OF BLOCK sbl_1.

SELECTION-SCREEN FUNCTION KEY 1.

*----------------------------------------------------------------------*
* INITIALIZATION
*----------------------------------------------------------------------*
INITIALIZATION.
  " Configurar botón de Application Log (SLG1) en la barra de herramientas
  DATA: ls_functxt TYPE smp_dyntxt.
  ls_functxt-text      = 'SLG1'(021).
  ls_functxt-icon_id   = '@DH@'.   " Icono estándar de Log
  ls_functxt-icon_text = 'SLG1'(021).
  ls_functxt-quickinfo = 'Visualizar Log de Aplicación'(022).
  sscrfields-functxt_01 = ls_functxt.

  " Configurar texto del botón de descarga de plantilla
  template = 'Descargar Plantilla Excel'(002).

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_local
*----------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_local.
  DATA: lt_filetable TYPE filetable,
        lv_rc        TYPE i.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = CONV string( 'Seleccione Fichero de Grafos'(010) )
      default_extension       = 'xlsx'
      file_filter             = 'Excel (*.xlsx;*.xls)|*.xlsx;*.xls|CSV (*.csv)|*.csv|Todos (*.*)|*.*'
    CHANGING
      file_table              = lt_filetable
      rc                      = lv_rc
    EXCEPTIONS
      OTHERS                  = 1.

  IF sy-subrc = 0 AND lt_filetable IS NOT INITIAL.
    p_local = lt_filetable[ 1 ]-filename.
  ENDIF.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN
*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'FC01'.
      " Apertura nativa del log SLG1 para el objeto ZTPS046
      zcl_ps_crea_grafos_mass=>get_instance( )->display_log( ).

    WHEN 'XLS'.
      " Generación y descarga interactiva de la plantilla
      zcl_ps_crea_grafos_mass=>get_instance( )->download_template( ).

    WHEN 'ONLI' OR space.
      " Validación de ruta de fichero solo si se pulsa Ejecutar
      IF p_local IS INITIAL AND p_fondo EQ abap_false.
        MESSAGE s063(zps) DISPLAY LIKE 'E'. " Ruta de fichero obligatoria
      ENDIF.
  ENDCASE.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.
  DATA(lo_service) = zcl_ps_crea_grafos_mass=>get_instance( ).

  " Caso A: Ejecución en Proceso de Fondo (Job)
  IF p_fondo EQ abap_true.
    lo_service->process_guid(
      IMPORTING
        iv_guid    = p_guid
        es_summary = DATA(ls_summary_bg) ).

    " Mensaje informativo en el spool del Job
    WRITE: / 'Resumen de Ejecución en Fondo'(060),
           / |Total: { ls_summary_bg-total }|,
           / |Creados / Success: { ls_summary_bg-success }|,
           / |Errores / Errors: { ls_summary_bg-error }|.
    RETURN.
  ENDIF.

  " Validar que el archivo esté informado
  IF p_local IS INITIAL.
    RETURN.
  ENDIF.

  " Caso B: El usuario solicita enviar a Segundo Plano (Background Job)
  IF c_fondo EQ abap_true.
    DATA: lt_data_to_bg TYPE zcl_ps_crea_grafos_mass=>tt_grafo_input.

    TRY.
        lo_service->parse_file_local(
          EXPORTING iv_filename = CONV #( p_local )
          IMPORTING et_data     = lt_data_to_bg ).
      CATCH cx_static_check.
        MESSAGE s001(00) WITH 'Error al leer el fichero local'(062) DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.

    IF lt_data_to_bg IS INITIAL.
      MESSAGE s001(00) WITH 'El archivo no contiene datos'(063) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    " Guardar en Cluster INDX estándar sin necesidad de tablas Z
    DATA(lv_guid) = lo_service->save_to_indx( lt_data_to_bg ).

    " Planificar Job en fondo
    DATA(lv_jobname) = lo_service->schedule_job(
      iv_guid       = lv_guid
      iv_local_file = p_local ).

    IF lv_jobname IS NOT INITIAL.
      MESSAGE s120(zps) WITH lv_jobname DISPLAY LIKE 'S'. " Job planificado con éxito
    ENDIF.

    RETURN.
  ENDIF.

  " Caso C: Procesamiento en Línea (Foreground)
  lo_service->process_file(
    EXPORTING
      iv_filename = CONV #( p_local )
    IMPORTING
      et_results  = DATA(lt_results)
      es_summary  = DATA(ls_summary) ).

  " Feedback final al usuario
  IF ls_summary-error > 0.
    " Hubo errores: se avisa para revisar SLG1
    MESSAGE s167(zps) DISPLAY LIKE 'E'. " Revise los errores en el log SLG1
  ELSEIF ls_summary-success > 0.
    " Todo correcto
    MESSAGE s001(00) WITH |{ ls_summary-success } { 'Grafos creados con éxito'(064) }| DISPLAY LIKE 'S'.
  ENDIF.

  " Mostrar el log directamente en pantalla para máxima visibilidad
  lo_service->display_log( ).
