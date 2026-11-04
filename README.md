# sap-ps-gui-ztps046

Repositorio para la transacción **`ZTPS046`** en SAP PS: **Cargador Masivo de Grafos desde Fichero Excel / CSV**.

[![ABAP](https://img.shields.io/badge/ABAP-Clean_OO-blue.svg)](https://github.com/SAP/styleguides/blob/main/clean-abap/clean-abap.md)
[![abapGit](https://img.shields.io/badge/abapGit-Ready-brightgreen.svg)](https://abapgit.org/)
[![Language](https://img.shields.io/badge/Language-ES%20%7C%20EN-orange.svg)]()
[![Fiori Ready](https://img.shields.io/badge/Architecture-Fiori_Ready-success.svg)]()

---

## 📌 Características Principales

- **Misma interfaz que ZTPS047**: Pantalla de selección homogénea con selección de fichero local, botón de descarga de plantilla, checkbox para ejecución en segundo plano y botón de acceso al log `SLG1` en la barra de herramientas.
- **Arquitectura Clean ABAP**: Toda la lógica desacoplada en la clase global `ZCL_PS_CREA_GRAFOS_MASS`, garantizando un report `ZPS_R_00046` limpio y ligero.
- **Internacionalización Completa (ES / EN)**: Símbolos de texto y textos de selección empaquetados en metadatos XML para activación automática en español e inglés sin intervención manual en SE38.
- **Política Parcial de Creación**: Creación y confirmación (`COMMIT`) independiente por cada grafo para no penalizar a los registros correctos si una fila puntual contiene errores.
- **Persistencia en Fondo sin Tablas Z**: Almacenamiento seguro en cluster estándar `INDX(ZP)` para la programación de jobs en segundo plano.
- **Preparado para Fiori**: La capa de servicio está lista para ser consumida directamente desde un servicio OData V2/V4 o RAP de Fiori sin refactorizar la lógica de negocio.

---

## 📂 Estructura del Proyecto

```
sap-ps-gui-ztps046/
├── .abapgit.xml                                  # Configuración de abapGit
├── .gitignore
├── README.md
├── src/                                          # Código fuente ABAP
│   ├── zps_r_00046.prog.abap                     # Report ejecutor (Capa GUI)
│   ├── zps_r_00046.prog.xml                      # Text pool multi-idioma (ES/EN)
│   ├── zcl_ps_crea_grafos_mass.clas.abap         # Motor de Negocio (Clean ABAP OO)
│   └── zcl_ps_crea_grafos_mass.clas.xml          # Metadatos de la clase
└── docs/                                         # Documentación y plantillas
    ├── DOCUMENTACION_TECNICA.md                  # Especificación funcional y técnica
    └── PLANTILLA_CARGA_GRAFOS.csv                # Datos de prueba de ejemplo
```

---

## 📋 Estructura del Archivo de Carga (5 Columnas)

| N° | Columna | Campo SAP | Validación |
| :-: | :--- | :--- | :--- |
| **1** | **PEP del Grafo** | `PRPS-POSID` | Existencia en `PRPS` y flag de elemento de imputación `BELKZ = 'X'`. |
| **2** | **Descripción del Grafo** | `AUFK-KTEXT` | Obligatorio (máx. 40 caracteres). |
| **3** | **Perfil Grafo** | `TCJ41-PROFIDTX` | Existencia en catálogo de perfiles de red `TCJ41`. |
| **4** | **Centro Logístico** | `T001W-WERKS` | Existencia en catálogo de centros `T001W`. |
| **5** | **Esquema Cálculo de Costes** | `T685A-KALSM` | Existencia en procedimientos de costes `T685A`. |

---

## 🚀 Instalación en SAP mediante abapGit

1. Abrir la transacción **`ZABAPGIT`**.
2. Clonar el repositorio: `https://github.com/mrgxzz/sap-ps-gui-ztps046.git`.
3. Asignar el paquete de desarrollo correspondiente (ej. `$TMP` o paquete Z de PS).
4. Ejecutar **Pull** y activar los objetos (`ZCL_PS_CREA_GRAFOS_MASS` y `ZPS_R_00046`).
5. Crear la transacción **`ZTPS046`** en `SE93` apuntando al programa `ZPS_R_00046`.
6. Verificar que el objeto **`ZTPS046`** esté creado en **`SLG0`**.
