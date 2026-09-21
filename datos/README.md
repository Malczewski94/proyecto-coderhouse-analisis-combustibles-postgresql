> Organización del repositorio: `estructura.sql` está en la raíz (`../estructura.sql` desde esta carpeta). Ejecutar el generador desde la raíz con `python3 datos/generar_dataset.py`; los CSV permanecen en `datos/`.

# Dataset híbrido de comercialización de combustibles

Proyecto educativo para análisis con PostgreSQL. Combina una muestra de ventas mensuales declaradas ante la Secretaría de Energía con clientes y pedidos ficticios. **No son transacciones reales ni información interna de YPF u otra empresa.**

## Caso de negocio

Una red comercial ficticia utiliza establecimientos reales como referencia para simular ventas a cuentas empresariales. El objetivo es estudiar gasto de clientes simulados, evolución mensual de ventas, productos con menor demanda y ranking de pedidos por categoría.

La pertenencia de los establecimientos a esa red y toda relación cliente–operador son ficticias. El campo `bandera` describe la marca declarada en la fuente; no prueba un contrato de franquicia ni propiedad común. Los pedidos representan lotes comerciales artificiales, que pueden agrupar varios suministros o cargas a una cuenta; no son tickets individuales de surtidor ni una simulación logística.

## Contenido

| Elemento | Cantidad |
| --- | ---: |
| Año seleccionado | 2025, doce meses |
| Establecimientos de referencia | 18 |
| Provincias | 6 |
| Productos | 7 |
| Categorías | 4 |
| Clientes ficticios | 432 |
| Pedidos ficticios | 4.909 |
| Detalles de pedidos limpios | 22.894 |
| Registros reales que sustentan la simulación | 1.007 |

Provincias: Buenos Aires, Chaco, Córdoba, Corrientes, Misiones y Santa Fe. Categorías: Nafta, Gasoil, Queroseno y GNC. La muestra incluye tres establecimientos por provincia. No representa el mercado nacional ni pretende estimar cuotas de mercado.

## Qué es real, derivado o sintético

| Dato | Procedencia |
| --- | --- |
| Operador, inscripción, CUIT, bandera, ubicación, tipo de negocio | Fuente real; textos normalizados mediante eliminación de espacios extremos |
| Producto original, período mensual, volumen, precio promedio e impuestos originales | Fuente real |
| Identificadores internos, categorías, unidades normalizadas, importe de referencia | Derivados |
| Clientes, sectores de clientes, asignaciones a establecimientos | Sintéticos |
| Fecha diaria, identificador y estado de pedido, reparto de cantidades | Sintéticos |
| Precio unitario de un pedido | Precio mensual real asignado artificialmente; no precio transaccional observado |
| Nulos de precios y duplicados en la entrada de práctica | Errores sintéticos controlados, registrados por separado |

No se utilizan nombres de compradores reales. Todos los clientes se denominan explícitamente `Cliente ficticio ...`. `Concretado` es un estado de la simulación, no un campo acreditado por la fuente. Los rankings de clientes y pedidos describen el generador; no permiten extraer conclusiones sobre compradores reales.

## Origen y extracción

- Archivo aportado: `precios_eess_2025_en_adelante.zip`.
- Base interna: `precios_eess_2025_en_adelante.accdb`.
- Tabla: `public_vi_access_eess_2025_en_adelante`.
- Extracción: 408.550 filas, coincidentes con el contador de la tabla de Access.
- Cobertura observada: enero de 2025 a julio de 2026; no se utilizaron datos de 2026.
- Filas de 2025: 261.234.
- SHA-256 de la base: `b79676dc30efcf6e8053325edf34c2b8de2e688d73f917c2753d7948815cec5a`.
- La extracción se realizó con `access-parser`; `fila_extraida` identifica el orden de extracción, no una clave original de Access.
- El archivo mayorista se conservó fuera de este dataset; no se mezclaron ambas fuentes.

Referencias de la fuente y sus unidades:

1. [Catálogo de precios y volúmenes EESS](https://datos.gob.ar/ar/dataset/energia-precios-volumenes-eess---resolucion-110404).
2. [Resolución 259/2024: volúmenes mensuales y precios ponderados](https://www.boletinoficial.gob.ar/detalleAviso/primera/314055/20240917).
3. [Aclaraciones de Energía, copia alojada por la OCDE](https://webfs.oecd.org/TADWEB/agriculture/data/AMIS/Indicators/Sources/energia3.mecon.gov.ar_contenidos_verpagina.php_idpagina%3D2577.pdf).

No se adjudica una licencia nueva a los datos de terceros. La atribución de origen se mantiene. Este paquete no certifica la exactitud de las declaraciones originales.

## Selección y calidad de la fuente

1. Seleccionar registros de 2025.
2. Identificar establecimientos mediante inscripción, CUIT, provincia, localidad y dirección. Un CUIT por sí solo no identifica una estación.
3. Exigir doce meses con volumen y precio positivos en el canal `Al público`, y nombre y bandera estables para la clave seleccionada.
4. Entre candidatos de las seis provincias, apartar establecimientos con registros positivos al público que superen 5.000 m³ de combustible líquido por producto/mes, o cuyo precio promedio esté fuera de 100–5.000 ARS por unidad. Son **umbrales de selección definidos para este ejercicio**, no límites oficiales ni demostración de un error. No se divide ningún volumen por 1.000 para corregir una sospecha.
5. Priorizar diversidad de productos (sin `N/D` ni GLPA); desempatar por inscripción y clave completa. Tomar tres establecimientos por provincia. Esta elección introduce sesgo de selección deliberado.
6. Conservar las 1.013 filas originales de esos establecimientos en `fuente_original.csv`, incluidas seis filas de otros canales. Excluir esas seis de la simulación para trabajar exclusivamente con ventas al público.
7. Comprobar producto, movimiento, valores positivos y duplicados exactos antes de generar los pedidos.

`candidatos_revision.csv` conserva los registros de candidatos que motivaron su exclusión por los umbrales anteriores. `exclusiones.csv` registra las exclusiones dentro de la muestra final. `perfil_fuente.json` conserva conteos y claves de selección. `advertencias_fuente.csv` documenta señales adicionales en la muestra elegida; un archivo sin filas no equivale a una auditoría exhaustiva de calidad.

Las fechas de baja, los impuestos y los textos originales se preservan en `fuente_original.csv`. Un vacío de fecha de baja no implica un error. `N/D` y campos vacíos deben interpretarse según su significado, no reemplazarse indiscriminadamente por cero.

## Unidades e importes

| Familia | Volumen en fuente | Cantidad en pedidos | Precio asignado |
| --- | --- | --- | --- |
| Nafta, gasoil y queroseno | m³ | Litros (`L`): volumen × 1.000 | ARS/L, promedio mensual con impuestos |
| GNC | m³ | m³, sin conversión | ARS/m³, promedio mensual con impuestos |

`cantidad × precio_unitario_ars` produce el importe de referencia de cada detalle. Se usa `Precio con impuestos`, no `Precio surtidor`. El importe reconstruido depende de la exactitud, definición y redondeo de los promedios declarados; **no es facturación auditada**. Los montos son pesos nominales, sin ajuste por inflación. No se infieren márgenes ni rentabilidad.

No sumar litros y m³ de GNC como un volumen único. El ranking de tres productos menos vendidos en volumen se realiza sobre los **seis combustibles líquidos**; el GNC se analiza aparte. Los rankings por importes sí pueden combinar productos bajo el mismo criterio monetario. El precio ponderado se calcula por producto y unidad: `SUM(cantidad * precio) / SUM(cantidad)`; no se mezclan ARS/L y ARS/m³.

Totales del conjunto incluido: **93.213.130 litros de combustibles líquidos** y **8.638.800,20 m³ de GNC**, siempre separados. Importe de referencia combinado: **141.717.574.607,79 ARS**. Son totales de esta muestra intencional, no del país.

## Reglas de simulación

- Semilla fija: `20250915`, con semillas derivadas por SHA-256 para cada establecimiento/mes y registro de fuente.
- Crear 24 clientes ficticios por establecimiento, 432 en total. Los sectores son asignaciones artificiales, no observaciones.
- Seleccionar doce días ficticios de cada mes y hasta dos asignaciones de clientes por día. Los cuatro primeros clientes de cada grupo reciben un peso de selección ocho veces mayor. La concentración resultante es inducida por diseño; no es un hallazgo del mercado.
- Dividir la cantidad de cada registro fuente en hasta 24 partes positivas, con precisión de 0,001 L o m³. La partición se realiza con enteros para que la suma sea exacta.
- Agrupar por establecimiento, fecha ficticia y cliente para formar pedidos. Esto permite que un pedido incluya varias categorías. Consolidar detalles del mismo pedido y registro fuente.
- Todos los detalles usan el precio mensual con impuestos de su registro fuente, sin generar descuentos ni precios diarios.
- Todos los pedidos son concretados. No se simulan devoluciones, crédito, cancelaciones ni costos.
- No interpretar las fechas o tamaños de pedido como patrones de demanda diarios reales. La simulación no calibra tamaños de tickets ni capacidad de vehículos.

## Tablas y archivos

| Archivo | Función |
| --- | --- |
| `operadores.csv` | Establecimientos de referencia reales |
| `productos.csv` | Productos y categorías con unidades |
| `clientes.csv` | Compradores ficticios |
| `pedidos.csv` | Cabeceras ficticias |
| `detalle_pedido.csv` | Detalle limpio listo para análisis |
| `fuente_ventas.csv` | Registros reales incluidos, con conversión y trazabilidad |
| `fuente_original.csv` | Muestra extraída con encabezados y valores originales |
| `detalle_pedido_entrada.csv` | Entrada didáctica con nulos y duplicados sintéticos |
| `incidencias_simuladas.csv` | Identificación de los errores agregados a la entrada |
| `conciliacion.csv` | Comparación fuente–pedidos por cada registro incluido |
| `estructura.sql` | Creación, inserción, limpieza y vistas en PostgreSQL |
| `generar_dataset.py` | Regeneración desde la muestra original incluida |
| `diccionario.md` | Significado, claves, unidades y procedencia de los campos |
| `validacion.json` | Comprobaciones independientes con aritmética decimal |
| `resumen_dataset.json` | Conteos, parámetros y totales |
| `sha256_csv.json` | Huellas para comprobar integridad de los CSV |

CSV en UTF-8, separador coma, punto decimal y encabezados en primera fila. Campos vacíos representan valores ausentes. No abrir y volver a guardar los CSV con conversiones automáticas de Excel: puede alterar fechas, identificadores o decimales.

Relaciones: `clientes → pedidos ← operadores`; `pedidos → detalle_pedido ← productos`; `detalle_pedido → fuente_ventas`, que a su vez identifica operador, producto y mes reales. Las tablas auxiliares de fuente y entrada hacen auditable el proceso; la rúbrica no impone un máximo de tablas.

## Limpieza para el ejercicio

`detalle_pedido_entrada.csv` contiene 22.953 filas: 22.894 detalles más 59 duplicados exactos. Se retiraron artificialmente los precios de 167 detalles. Puede haber una copia duplicada de un precio faltante; el registro de incidencias cuenta detalles afectados, no necesariamente todas las celdas vacías de la entrada.

La carga SQL elimina duplicados exactos con `SELECT DISTINCT` y recupera los precios mediante `COALESCE(precio_entrada, precio_fuente)`. La recuperación es válida **porque el generador asignó el mismo precio mensual a todos los detalles de una fuente**. En transacciones reales, el precio mensual no recupera necesariamente un precio faltante.

Se preservan tanto la entrada como el detalle limpio. Las comprobaciones verifican que la limpieza reconstruya exactamente este último. No se introdujeron errores en el archivo original ni se convirtió un precio desconocido en cero.

## Cargar en PostgreSQL

1. Crear una base vacía llamada `capstone_project` desde pgAdmin. Alternativamente ejecutar `CREATE DATABASE capstone_project;` conectado a otra base, fuera de una transacción.
2. Conectarse a `capstone_project`.
3. Abrir `estructura.sql` en Query Tool y ejecutar el archivo completo. Incluye los datos; no requiere importar CSV manualmente ni configurar rutas.
4. Consultar `combustibles.v_ventas`. La consulta final de conciliación debe devolver cero filas.

Con `psql`, si está instalado: `psql -d capstone_project -v ON_ERROR_STOP=1 -f estructura.sql`.

El script utiliza el esquema `combustibles` y una transacción. No borra tablas previas; una segunda ejecución sobre tablas existentes falla deliberadamente. Usar una base vacía para repetir una carga completa.

La carga completa y la limpieza se ejecutaron correctamente en **PostgreSQL 18.3 mediante PGlite 0.5.8 (WebAssembly)**. Se verificaron claves, trazabilidad, doce meses de resultados y consultas técnicas con `GROUP BY`, funciones de fecha y `RANK()`. La conciliación SQL no devolvió diferencias. `validacion_postgresql.json` conserva el resultado y las salidas de prueba; no sustituye el futuro análisis de negocio ni acredita ejecución en la instalación local del usuario.

La entrada contiene 168 celdas de precio vacías: 167 detalles afectados y una copia duplicada de uno de ellos. Después de eliminar duplicados y recuperar los precios, se obtienen los 22.894 detalles esperados.

Para regenerar los archivos sin Access: `python generar_dataset.py` desde esta carpeta (Python 3.10 o superior, sin dependencias externas). Mantener `fuente_original.csv` junto al script. Esta reproducción parte de la muestra congelada; no descarga novedades ni vuelve a seleccionar establecimientos del archivo de un gigabyte. La regeneración reemplaza los CSV derivados, SQL y reportes de validación.

## Alcance de esta entrega

Esta entrega prepara el **dataset**, su carga y su validación. Las consultas finales de negocio, sus conclusiones y la publicación en GitHub se desarrollarán en la siguiente etapa. No se incluye todavía un `analisis.sql` final ni se afirma que el proyecto completo esté entregado.

Las cuatro preguntas pueden resolverse: top de clientes sintéticos por gasto, ventas por mes, tres productos líquidos menos vendidos y ranking de pedidos sintéticos por categoría. Para este último, sumar primero el importe de cada pedido dentro de cada categoría y aplicar `RANK()` con partición por categoría y orden por importe descendente.
