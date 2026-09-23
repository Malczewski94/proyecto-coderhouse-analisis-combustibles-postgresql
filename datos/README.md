# Dataset: mayorista ficticio y establecimientos reales

Utilizo 18 establecimientos reales como cuentas de clientes de un mayorista ficticio. Conservo `operadores` como tabla de identidad de origen y `clientes` como vínculo comercial simulado, uno a uno. El Gobierno publica los datos de la fuente; en este modelo no actúa como vendedor.

La fuente contiene ventas de las estaciones al público. No acredita sus compras ni sus proveedores. Utilizo las cantidades vendidas como cantidades compradas simuladas, sin cambios de existencias, y conservo el precio minorista mensual original como referencia. La relación comercial, los pedidos y su estado son supuestos del ejercicio; los nombres y las ubicaciones de los establecimientos son reales.

## Contenido

| Elemento | Cantidad |
| --- | ---: |
| Establecimientos / clientes | 18 / 18 |
| Provincias | 6 |
| Productos | 7 |
| Meses de 2025 | 12 |
| Pedidos mensuales | 216 |
| Registros fuente y detalles limpios | 1.007 cada uno |
| Detalles de entrada | 1.010 |

Las seis provincias son Buenos Aires, Chaco, Córdoba, Corrientes, Misiones y Santa Fe. La bandera indica la marca declarada; no infiero franquicia, propiedad común ni proveedor efectivo de un pedido.

## Origen y extracción

- Archivo utilizado: `precios_eess_2025_en_adelante.zip`.
- Base de origen: `precios_eess_2025_en_adelante.accdb`.
- Tabla: `public_vi_access_eess_2025_en_adelante`.
- Extracción: 408.550 filas, coincidentes con el contador de la tabla de Access.
- La fuente consultada cubre enero de 2025 a julio de 2026; el conjunto publicado utiliza únicamente registros de 2025.
- Filas de 2025: 261.234.
- SHA-256 de la base de origen: `b79676dc30efcf6e8053325edf34c2b8de2e688d73f917c2753d7948815cec5a`.
- La extracción se realizó con `access-parser`; `fila_extraida` identifica el orden de extracción, no una clave original de Access.

Referencias de la fuente y sus unidades:

1. [Catálogo de precios y volúmenes EESS](https://datos.gob.ar/ar/dataset/energia-precios-volumenes-eess---resolucion-110404).
2. [Resolución 259/2024: volúmenes mensuales y precios ponderados](https://www.boletinoficial.gob.ar/detalleAviso/primera/314055/20240917).
3. [Aclaraciones de Energía, copia alojada por la OCDE](https://webfs.oecd.org/TADWEB/agriculture/data/AMIS/Indicators/Sources/energia3.mecon.gov.ar_contenidos_verpagina.php_idpagina%3D2577.pdf).

No asigno una licencia nueva a los datos de terceros y mantengo la atribución de origen. Este paquete no certifica la exactitud de las declaraciones originales.

## Selección y calidad de la fuente

1. Selecciono registros de 2025.
2. Identifico los establecimientos mediante inscripción, CUIT, provincia, localidad y dirección. Un CUIT por sí solo no identifica una estación.
3. Exijo doce meses con volumen y precio positivos en el canal `Al público`, además de nombre y bandera estables para la clave seleccionada.
4. Excluyo establecimientos candidatos de las seis provincias con registros positivos del canal `Al público` que superen 5.000 m³ de combustible líquido por producto y mes o cuyo precio promedio esté fuera de 100–5.000 ARS por unidad. Estos son umbrales definidos para este ejercicio; no son límites oficiales ni demuestran un error en la fuente. No divido volúmenes por 1.000 para corregir una sospecha.
5. Priorizo la diversidad de productos, sin contar `N/D` ni GLPA, y desempato por inscripción y clave completa. Selecciono tres establecimientos por provincia. Esta elección introduce un sesgo deliberado.
6. Conservo las 1.013 filas originales de esos establecimientos en `fuente_original.csv`, incluidas seis filas de otros canales. Excluyo esas seis de la simulación para trabajar exclusivamente con ventas al público.
7. Compruebo producto, movimiento, valores positivos y duplicados exactos antes de generar los pedidos.

`candidatos_revision.csv` conserva los registros de candidatos que motivaron su exclusión por los umbrales anteriores. `exclusiones.csv` registra las exclusiones dentro de la muestra final. `perfil_fuente.json` conserva conteos y claves de selección. `advertencias_fuente.csv` documenta señales adicionales en la muestra elegida; un archivo sin filas no equivale a una auditoría exhaustiva de calidad.

Conservo las fechas de baja, los impuestos y los textos originales en `fuente_original.csv`. Un campo vacío en la fecha de baja no implica un error. Interpreto `N/D` y los campos vacíos según su significado, sin reemplazarlos indiscriminadamente por cero.

## Unidades e importes

| Familia | Volumen en fuente | Cantidad en pedidos | Precio asignado |
| --- | --- | --- | --- |
| Nafta, gasoil y queroseno | m³ | Litros (`L`): volumen × 1.000 | ARS/L, promedio mensual con impuestos |
| GNC | m³ | m³, sin conversión | ARS/m³, promedio mensual con impuestos |

Calculo el importe de referencia de cada detalle como `cantidad × precio_unitario_ars`. Utilizo `Precio con impuestos`, no `Precio surtidor`. El importe depende de la exactitud, la definición y el redondeo de los promedios declarados; **no es facturación auditada**. Los montos son pesos nominales, sin ajuste por inflación. No infiero márgenes ni rentabilidad.

No sumo litros y m³ de GNC como un volumen único. El ranking de tres productos menos vendidos en volumen se realiza sobre los **seis combustibles líquidos**; el GNC se analiza aparte. Los rankings por importe sí pueden combinar productos bajo el mismo criterio monetario. Calculo el precio ponderado por producto y unidad: `SUM(cantidad * precio) / SUM(cantidad)`; no mezclo ARS/L y ARS/m³.

Los totales del conjunto incluido son **93.213.130 litros de combustibles líquidos**, **8.638.800,20 m³ de GNC** y **141.717.574.607,79 ARS de importe de referencia**. Son totales de esta muestra intencional, no del país.

## Reglas del modelo

1. Creo una cuenta de cliente por establecimiento identificado mediante inscripción, CUIT y ubicación. No agrupo sucursales por CUIT sin una decisión adicional.
2. Creo un pedido por cliente y mes, 216 en total. `fecha` usa el primer día del mes como representación técnica; no indica una entrega observada.
3. Creo un detalle por registro fuente, con su cantidad completa y su precio mensual con impuestos. No fragmento cantidades ni asigno compradores aleatorios.
4. Uso el precio minorista como referencia, no como precio mayorista. No aplico descuentos inventados ni calculo márgenes.
5. Mantengo el estado `Concretado` en todos los pedidos como supuesto del caso. No hay cancelaciones ni información de costos.
6. Los doce pedidos de cada cliente son una regla del modelo y no permiten inferir fidelidad o frecuencia comercial real.
7. Genero los datos de forma determinista, según el orden de claves, períodos e identificadores fuente, sin azar ni semilla.

## Limpieza didáctica

Copio los 1.007 detalles, retiro ocho precios y agrego tres duplicados exactos. Así genero 1.010 filas de entrada, con ocho celdas de precio nulas. Registro las incidencias en `incidencias_simuladas.csv`; no son defectos atribuidos a la fuente real.

`DISTINCT` elimina las copias idénticas y `COALESCE` recupera el precio de la misma fuente mensual, porque ese es el precio de referencia asignado por diseño. El resultado es un detalle de 1.007 filas, sin duplicados ni precios nulos. Los períodos no tienen nulos: verifico su conversión a `DATE` y no imputo fechas ficticias.

La conciliación compara cada uno de los 1.007 registros con su detalle y debe producir cero diferencias de cantidad e importe. El control de JOIN comprueba establecimiento, producto, período y número de filas.

## Archivos y reproducción

- `fuente_original.csv`: muestra congelada de 1.013 filas con encabezados originales.
- `operadores.csv`, `clientes.csv`, `productos.csv`, `pedidos.csv`, `fuente_ventas.csv`, `detalle_pedido.csv` y `detalle_pedido_entrada.csv`: tablas del modelo.
- `exclusiones.csv`, `advertencias_fuente.csv`, `candidatos_revision.csv` y `perfil_fuente.json`: trazabilidad de la selección y sus controles.
- `incidencias_simuladas.csv`, `conciliacion.csv`, `resumen_dataset.json` y `validacion.json`: resultados y controles generados con Python.
- `sha256_csv.json`: huellas de integridad de los CSV.
- `validacion_final_postgresql.json`: evidencia técnica de la ejecución aislada de la estructura, las validaciones y los análisis.
- `../estructura.sql`: DDL, inserciones, limpieza y vistas.
- `../analisis.sql`: consultas de negocio.
- `../validaciones.sql`: controles de carga, limpieza, conciliación y relaciones.

Los CSV están en UTF-8, separados por comas, con punto decimal y encabezado. Los campos vacíos corresponden a valores ausentes; no convierto automáticamente identificadores, fechas o decimales al abrirlos en Excel.

Desde la raíz, ejecuto `python3 datos/generar_dataset.py` con Python 3.10 o superior y la biblioteca estándar. El generador utiliza la muestra congelada `datos/fuente_original.csv`, regenera los derivados y actualiza `estructura.sql`. No descarga novedades ni repite la extracción o la selección desde Access.

Las instrucciones de carga están en el [README principal](../README.md). Allí documento las consultas y capturas de pgAdmin que confirman conteos, limpieza, conciliación, fechas, pedidos mensuales, trazabilidad y tipos.

## Alcance de la entrega

El modelo está cargado y validado. Documento el top 5, la evolución mensual, los combustibles líquidos menos vendidos, el ranking de pedidos por categoría, la concentración del top 5 y el precio ponderado por producto y mes en el README principal. El resultado completo de los precios ponderados se encuentra en `../resultados/precios_ponderados_mensuales.csv`, con 83 combinaciones y sin registro de nafta común en octubre. Presento las conclusiones globales y los límites de interpretación en el README principal.
