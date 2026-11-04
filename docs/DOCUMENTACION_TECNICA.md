# Documentación Técnica y Funcional: Transacción ZTPS046

## 1. Resumen Ejecutivo y Objetivos

La transacción **`ZTPS046`** (Programa ejecutor **`ZPS_R_00046`**) permite la **creación masiva de cabeceras de grafos de proyectos (PS Networks)** a partir de un archivo en formato Excel (`.xlsx`, `.xls`) o delimitado (`.csv`).

### Objetivos Clave de Diseño:
1. **Identidad Visual 100% Homogénea**: Réplica exacta de la interfaz gráfica de usuario (GUI) de la transacción previa `ZTPS047` (cargador de operaciones de grafo).
2. **Arquitectura Clean ABAP OO**: Reemplazo de los modelos procedimentales monolíticos (>6.400 líneas de código en includes `F01`) por una arquitectura orientada a objetos moderna, desacoplada y mantenible.
3. **Internacionalización Completa (ES / EN)**: Textos de selección, títulos y símbolos de texto serializados en los metadatos XML de abapGit para activación automática en español e inglés.
4. **Política de Procesamiento Parcial**: Cada grafo es procesado y confirmado (`COMMIT`) de manera independiente, reportando con exactitud en el log `SLG1` los creados y los fallidos.
5. **Persistencia en Fondo sin Tablas Z**: Uso de clusters de datos nativos de SAP (`INDX`) para transferir los datos al Job de fondo sin crear tablas personalizadas en el diccionario de datos.
6. **Preparación Inmediata para Fiori (Fiori-Ready)**: Toda la lógica de parseo, validación y ejecución de BAPI reside en la clase global `ZCL_PS_CREA_GRAFOS_MASS`, permitiendo su reutilización directa en servicios OData/RAP sin tocar la lógica de negocio.

---

## 2. Comparativa Arquitectónica: ZTPS047 vs. ZTPS046

```
╔═════════════════════════════════════════════════════════════════════════════╗
║                                 ZTPS047                                     ║
║  - Monolito procedimental (ZPS_R_00052_F01 > 6.400 líneas, TOP, SEL)       ║
║  - Dependencia de OLE2 de Windows y ALSM_EXCEL (límite 9.999 filas)         ║
║  - Tablas Z intermedias obligatorias (ZPS_00050, ZPS_00051) con GUIDs       ║
║  - Apertura de SLG1 mediante Batch Input obsoleto (SAPLSLG3 dynpro 0100)    ║
║  - Política "Todo o Nada" (un error bloqueaba todo el archivo)              ║
╚═════════════════════════════════════════════════════════════════════════════╝
                                     ▲
                                     │ EVOLUCIÓN A CLEAN ABAP
                                     ▼
╔═════════════════════════════════════════════════════════════════════════════╗
║                                 ZTPS046                                     ║
║  - Capa GUI delgada (ZPS_R_00046: < 150 líneas)                            ║
║  - Core desacoplado en Clase Global (ZCL_PS_CREA_GRAFOS_MASS)               ║
║  - Parseo binario nativo (CL_FDT_XL_SPREADSHEET) sin límites de volumen     ║
║  - Persistencia temporal en cluster nativo INDX(ZP)                         ║
║  - Visualización nativa de SLG1 vía API (BAL_DSP_LOG_DISPLAY)               ║
║  - Política Parcial: Grafos correctos se crean, erróneos se loguean         ║
║  - 100% Fiori Ready (consumible por OData V2/V4 / RAP Custom Entity)        ║
╚═════════════════════════════════════════════════════════════════════════════╝
```

---

## 3. Especificación del Fichero de Carga (5 Columnas)

El archivo de entrada (Excel o CSV con separador `;` o `,`) contiene 5 columnas:

| Col | Nombre Columna | Campo SAP | Tipo / Longitud | Validación de Negocio |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **PEP del Grafo** | `PRPS-POSID` | `CHAR 24` | Existencia en `PRPS` (conversión `ABPSN`). Obligatorio flag de imputación `PRPS-BELKZ = 'X'`. |
| **2** | **Descripción del Grafo** | `AUFK-KTEXT` | `CHAR 40` | Obligatorio. No puede estar vacío. |
| **3** | **Perfil Grafo** | `TCJ41-PROFIDTX` | `CHAR 7` | Existencia en catálogo de perfiles de red `TCJ41` / `TCJ41T`. |
| **4** | **Centro Logístico** | `T001W-WERKS` | `CHAR 4` | Existencia en catálogo de centros de SAP `T001W`. |
| **5** | **Esquema Cálculo de Costes** | `T685A-KALSM` | `CHAR 6` | Opcional/Recomendado. Si se informa, existencia en tabla de esquemas `T685A`. |

### Ejemplo de Datos de Carga:
```csv
PEP del Grafo;Descripción del Grafo;Perfil Grafo;Centro Logístico;Esquema Cálculo de Costes
FB.0221.D.C;B1220_ARMAMENTO UNION_(ETAPA_L);ZB00002;2220;ZGP000
FB.0221.D.C;B1220_CHORREADO Y PINTADO_(ETAPA_F);ZB00002;2220;ZGP000
FB.0221.D.C;B1220_CORTE Y ELABORACION_(ETAPA_A);ZB00002;2220;ZGP000
FB.0221.D.C;B1220_FABRICACION_(ETAPA_D);ZB00002;2220;ZGP000
FB.0221.D.C;B1220_P1 NORMAL_(ETAPA_E);ZB00002;2220;ZGP000
FB.0221.D.C;B1220_P2_(ETAPA_G);ZB00002;2220;ZGP000
```

---

## 4. Diagrama de Secuencia y Lógica Transaccional

```
Usuario                  ZPS_R_00046           ZCL_PS_CREA_GRAFOS_MASS       SAP PS BAPI / DB
   │                          │                           │                          │
   │── [Ejecutar (F8)] ──────>│                           │                          │
   │                          │── parse_file_local() ────>│                          │
   │                          │                           │── SELECT bulk (PRPS...) ─│
   │                          │                           │<─ [OK Data] ─────────────│
   │                          │── validate_data() ───────>│                          │
   │                          │                           │                          │
   │                          │── execute_creation() ────>│                          │
   │                          │                           │ LOOP at registros:       │
   │                          │                           │── BAPI_NETWORK_MAINTAIN─>│
   │                          │                           │   (Network Create)       │
   │                          │                           │── BAPI_PS_PRECOMMIT ────>│
   │                          │                           │── BAPI_COMMIT_WAIT ─────>│
   │                          │                           │<─ AUFNR generado ────────│
   │                          │                           │   (Log verde en BAL)     │
   │                          │                           │ ENDLOOP                  │
   │                          │                           │── BAL_DB_SAVE ──────────>│
   │                          │<─ Resultados / Resumen ───│                          │
   │<─ Pantalla Log SLG1 ─────│── display_log() ─────────│                          │
```

---

## 5. Configuración de Prerrequisitos en SAP

### A. Objeto de Log en `SLG0`
- **Objeto**: `ZTPS046`
- **Descripción**: *Cargador masivo de Grafos PS*
- **Subobjeto**: Dejar vacío (o crear `CARGA` si se requiere clasificación).

### B. Creación de la Transacción en `SE93`
- **Código de transacción**: `ZTPS046`
- **Texto**: *Cargador de Grafos* (ES) / *Network Mass Loader* (EN)
- **Tipo de transacción**: Programa y dynpro de selección (Report transaction)
- **Programa**: `ZPS_R_00046`
- **Dynpro de inicio**: `1000`
- **Clasificación**: Marcar soporte para SAP GUI for Windows y SAP GUI for HTML (WebGUI).

---

## 6. Guía de Migración a SAP Fiori

Gracias al desacoplamiento en capas, migrar la funcionalidad a Fiori se realiza en dos modalidades:

### Opción 1: Publicación Inmediata como Fiori Tile (0 código)
1. Abrir **Fiori Launchpad Designer** (`FLPD_CUST`).
2. Crear un Tile de tipo App Launcher:
   - **Semantic Object**: `ProjectNetwork`
   - **Action**: `massCreate`
   - **Target Mapping**: Tipo de aplicación `Transaction`, Código `ZTPS046`.
3. El usuario accede desde el Launchpad web y opera exactamente igual que en SAP GUI.

### Opción 2: App Fiori Nativa (SAPUI5 + RAP / OData)
1. **Backend**:
   - Crear un servicio OData (ej. `ZPS_MASS_NETWORK_SRV`) o servicio RAP no administrado (Unmanaged Query / Action).
   - En el método de subida de fichero (Stream Handler / Action), recibir el contenido binario (`xstring`) y delegar en una sola llamada:
     ```abap
     zcl_ps_crea_grafos_mass=>get_instance( )->process_file(
       EXPORTING
         iv_filename = lv_file_name
         iv_file_raw = lv_xstring
       IMPORTING
         et_results  = lt_results
         es_summary  = ls_summary ).
     ```
2. **Frontend (SAPUI5)**:
   - Pantalla simple con `sap.ui.unified.FileUploader`.
   - Botón *"Descargar Plantilla"* vinculado a `zcl_ps_crea_grafos_mass=>get_instance( )->generate_template_csv( )`.
   - `sap.m.Table` para visualizar los grafos creados en tiempo real con sus semáforos verde y rojo.
