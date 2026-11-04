# Guía de Instalación Manual desde Eclipse ADT (Sin abapGit)

Esta guía detalla los pasos para dar de alta la transacción **`ZTPS046`** en el sistema SAP utilizando **Eclipse con ABAP Development Tools (ADT)**, sin requerir conexión a internet ni herramientas de transporte externas.

---

## Resumen de Objetos a Crear en Eclipse ADT

| Orden | Tipo de Objeto en Eclipse | Nombre Técnico | Ubicación del Código en este Repositorio |
| :---: | :--- | :--- | :--- |
| **1** | **ABAP Class** | `ZCL_PS_CREA_GRAFOS_MASS` | [`src/zcl_ps_crea_grafos_mass.clas.abap`](../src/zcl_ps_crea_grafos_mass.clas.abap) |
| **2** | **ABAP Program** | `ZPS_R_00046` | [`src/zps_r_00046.prog.abap`](../src/zps_r_00046.prog.abap) |
| **3** | **Transaction** | `ZTPS046` | Parámetros descritos en el Paso 3 |

---

## Paso 1: Crear la Clase `ZCL_PS_CREA_GRAFOS_MASS`

1. En el **Project Explorer** de Eclipse, haz clic derecho sobre tu paquete ABAP $\rightarrow$ **New** $\rightarrow$ **ABAP Class**.
   - **Package**: Tu paquete de desarrollo (o `$TMP` para pruebas).
   - **Name**: `ZCL_PS_CREA_GRAFOS_MASS`
   - **Description**: `Cargador Masivo de Grafos PS (ZTPS046)`
2. Pulsa **Next**, selecciona tu Orden de Transporte $\rightarrow$ **Finish**.
3. En el editor que se abre, selecciona todo el contenido (`Ctrl + A`), bórralo y pega el código completo del archivo:
   `src/zcl_ps_crea_grafos_mass.clas.abap`
4. Guarda con **`Ctrl + S`** y activa con **`Ctrl + F3`**.

---

## Paso 2: Crear el Programa `ZPS_R_00046`

1. Clic derecho sobre el paquete $\rightarrow$ **New** $\rightarrow$ **ABAP Program**.
   - **Name**: `ZPS_R_00046`
   - **Description**: `Cargador de Grafos PS`
2. Pulsa **Next** $\rightarrow$ Orden de Transporte $\rightarrow$ **Finish**.
3. Selecciona todo el código inicial, bórralo y pega el código del archivo:
   `src/zps_r_00046.prog.abap`
4. Guarda con **`Ctrl + S`**.

### Asignar Textos de Selección en Eclipse:
1. En la parte inferior del editor de código de `ZPS_R_00046`, pulsa en la pestaña **Text Elements** (o clic derecho sobre el programa en el Project Explorer $\rightarrow$ **Open With** $\rightarrow$ **Text Elements**).
2. Ve a la subpestaña **Selection Texts** y rellena:

| Name | Text |
| :--- | :--- |
| **`P_LOCAL`** | `Ruta Fichero:` |
| **`C_FONDO`** | `Procesar en segundo plano` |

3. Guarda con **`Ctrl + S`** y activa el programa con **`Ctrl + F3`**.

> **Nota sobre símbolos de texto**: Todos los botones (`SLG1`, `Descargar Plantilla Excel`) y títulos ya tienen sus textos asignados directamente en el código mediante la sintaxis `'Texto'(nnn)`, por lo que no es necesario crear símbolos de texto a mano en la pestaña *Text Symbols*.

---

## Paso 3: Crear la Transacción `ZTPS046`

1. Clic derecho sobre tu paquete $\rightarrow$ **New** $\rightarrow$ **Other ABAP Repository Object**.
2. Escribe **Transaction** en el buscador y pulsa **Next**.
   - **Name**: `ZTPS046`
   - **Description**: `Cargador de Grafos`
3. En el formulario de configuración:
   - **Transaction Type**: Selecciona `Program and selection screen (report transaction)`.
   - **Program**: `ZPS_R_00046`
   - **Selection Screen**: `1000`
   - **GUI Support**: Marca las casillas:
     - `[x] SAP GUI for Windows`
     - `[x] SAP GUI for HTML`
4. Guarda con **`Ctrl + S`** y activa con **`Ctrl + F3`**.

---

## Paso 4: Confirmar el Objeto de Log en `SLG0`

En SAP GUI:
1. Entrar en la transacción **`SLG0`**.
2. Comprobar que existe el objeto **`ZTPS046`** (Descripción: *Cargador masivo de Grafos PS*). Si no está, crearlo pulsando en *Entradas nuevas*.
