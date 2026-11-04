# Guía de Internacionalización (Traducción al Inglés)

En SAP, cada objeto de repositorio se crea en un **Idioma Original / Maestro** (en nuestro caso, Español `ES` / `S`). Para que el programa se muestre en **Inglés (`EN` / `E`)** cuando un usuario inicia sesión en inglés, se realiza la traducción en el sistema mediante cualquiera de los siguientes métodos estándar:

---

## Método 1: Traducción mediante la Transacción Estándar `SE63` (Recomendado)

La transacción **`SE63`** es la herramienta estándar de SAP para traducir cualquier objeto sin tocar el código fuente.

### Pasos:
1. Entra en la transacción **`SE63`**.
2. En el menú superior: **Traducción** $\rightarrow$ **Objetos ABAP** $\rightarrow$ **Textos breves** (o pulsa el botón *Textos breves*).
3. Despliega la carpeta **00 - Textos de programa y textos de dynpro** $\rightarrow$ doble clic en **REPT - Textos de programa**.
4. Rellena los parámetros:
   - **Nombre de objeto**: `ZPS_R_00046`
   - **Idioma fuente**: `ES` (Español)
   - **Idioma destino**: `EN` (Inglés)
5. Pulsa **Modificar (`F8`)**.
6. Aparecerá la pantalla partida con los textos originales en español a la izquierda y el campo editable en inglés a la derecha. Pega los textos de la **Tabla de Traducción** que figura abajo.
7. Pulsa **Guardar (`Ctrl + S`)**.

---

## Método 2: Traducción directa desde Eclipse ADT

1. En Eclipse, abre el programa **`ZPS_R_00046`**.
2. Abre la pestaña **Text Elements** (en la parte inferior del editor de código).
3. Haz clic derecho sobre cualquier texto de selección o símbolo de texto $\rightarrow$ selecciona **Translate...** (o pulsa `Ctrl + 6`).
4. Selecciona **Target Language: `EN`** (Inglés).
5. Introduce los textos en inglés de la tabla y pulsa **Save**.

---

## Método 3: Inicio de Sesión en Inglés en SAP GUI

1. En la pantalla de logon de SAP, introduce tu usuario y pon **Idioma: `EN`**.
2. Entra en la transacción **`SE38`**, pon el programa `ZPS_R_00046`.
3. Selecciona **Text Elements** $\rightarrow$ **Change**.
4. Introduce directamente los textos en inglés y guarda.

---

## Tabla de Traducción Oficial (Español $\leftrightarrow$ Inglés)

### 1. Título del Programa
| Clave | Texto en Español (`ES`) | English Translation (`EN`) |
| :---: | :--- | :--- |
| **Title** | `Cargador de Grafos PS` | `PS Project Network Mass Loader` |

### 2. Textos de Selección (Selection Texts)
| Parámetro | Texto en Español (`ES`) | English Translation (`EN`) |
| :---: | :--- | :--- |
| **`P_LOCAL`** | `Ruta Fichero:` | `File Path:` |
| **`C_FONDO`** | `Procesar en segundo plano` | `Process in background` |

### 3. Símbolos de Texto (Text Symbols)
| ID | Texto en Español (`ES`) | English Translation (`EN`) |
| :---: | :--- | :--- |
| **`001`** | `Parámetros:` | `Parameters:` |
| **`002`** | `Descargar Plantilla Excel` | `Download Excel Template` |
| **`010`** | `Seleccione Fichero de Grafos` | `Select Network File` |
| **`021`** | `SLG1` | `SLG1` |
| **`022`** | `Visualizar Log de Aplicación` | `Display Application Log` |
| **`030`** | `Cargador de Grafos` | `Network Loader` |
| **`060`** | `Resumen de Ejecución en Fondo` | `Background Execution Summary` |
| **`061`** | `No se encontraron registros de log` | `No log entries found` |
| **`062`** | `Error al leer el fichero local` | `Error reading local file` |
| **`063`** | `El archivo no contiene datos` | `File contains no data` |
| **`064`** | `Grafos creados con éxito` | `Networks created successfully` |

---

## Traducción de la Transacción `ZTPS046`

1. Entra en la transacción **`SE63`**.
2. Selecciona **Textos breves** $\rightarrow$ **TRA - Transacciones**.
3. Objeto: `ZTPS046`, Fuente: `ES`, Destino: `EN`.
4. Traducir:
   - Español: `Cargador de Grafos`
   - Inglés: `Project Network Mass Loader`
5. Guardar.
