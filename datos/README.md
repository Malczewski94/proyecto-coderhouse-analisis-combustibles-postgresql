# Dataset V2: mayorista ficticio y establecimientos reales

Los 18 establecimientos reales seleccionados se utilizan como cuentas cliente de un mayorista ficticio. Se conserva `operadores` como tabla de identidad de origen y `clientes` como vínculo comercial simulado, uno a uno. El Gobierno es el publicador de datos, no nuestro vendedor.

La fuente contiene ventas de las estaciones al público. No acredita sus compras ni sus proveedores. Usamos cantidades vendidas como cantidades compradas simuladas, sin cambios de existencias, y el precio minorista mensual original como referencia. La relación comercial, los pedidos y su estado son simulados; los nombres y ubicaciones de los establecimientos son reales.

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

Las seis provincias son Buenos Aires, Chaco, Córdoba, Corrientes, Misiones y Santa Fe. La bandera indica la marca declarada y no prueba franquicia, propiedad común ni proveedor efectivo de un pedido.

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

## Reglas de simulación V2

1. Una cuenta cliente por establecimiento identificado por inscripción, CUIT y ubicación. No agrupar sucursales por CUIT sin una decisión adicional.
2. Un pedido por cliente/mes, 216 en total. `fecha` usa el primer día del mes como representación técnica. No indica una entrega observada.
3. Un detalle por registro fuente, con su cantidad completa y su precio mensual con impuestos. No se fragmentan cantidades ni se asignan compradores aleatorios.
4. Precio de referencia minorista, no precio mayorista. No se aplican descuentos inventados ni se calculan márgenes.
5. Estado `Concretado` en todos los pedidos, por supuesto del caso. No hay cancelaciones ni información de costos.
6. Los doce pedidos de cada cliente están fijados por diseño: no permiten inferir fidelidad o frecuencia comercial real.
7. Generación determinista por orden de claves, períodos e identificadores fuente. V2 no utiliza azar ni semilla.

## Limpieza didáctica

El generador copia los 1.007 detalles, retira 8 precios y agrega 3 duplicados exactos. Quedan 1.010 filas de entrada, con 8 celdas de precio nulas. Las incidencias se registran en `incidencias_simuladas.csv`; no son defectos atribuidos a la fuente real.

`DISTINCT` elimina las copias idénticas y `COALESCE` recupera el precio de la misma fuente mensual, válido porque ese es el precio de referencia asignado por diseño. Resultado: 1.007 detalles, sin duplicados ni precios nulos. Los períodos no tienen nulos; se verifica su conversión a DATE y no se imputan fechas ficticias adicionales.

La conciliación compara cada uno de los 1.007 registros con su detalle y debe dar cero diferencias de cantidad e importe. El control de JOIN comprueba establecimiento, producto, período y número de filas.

## Archivos y reproducción

- `fuente_original.csv`: muestra congelada de 1.013 filas con encabezados originales.
- `operadores.csv`, `clientes.csv`, `productos.csv`, `pedidos.csv`, `fuente_ventas.csv`, `detalle_pedido.csv` y `detalle_pedido_entrada.csv`: siete tablas.
- `exclusiones.csv`, `advertencias_fuente.csv`, `candidatos_revision.csv`, `perfil_fuente.json`: trazabilidad de la selección original y sus controles.
- `incidencias_simuladas.csv`, `conciliacion.csv`, `resumen_dataset.json`, `validacion.json`: resultados V2 del generador.
- `sha256_csv.json`: huellas de todos los CSV.
- `validacion_postgresql.json`: prueba técnica V2 separada, realizada con PGlite 0.5.8 / PostgreSQL 18.3.
- `../estructura.sql`: DDL, INSERT, limpieza y vistas V2.
- `../reiniciar_esquema.sql`: elimina los esquemas del proyecto en capstone_project antes de una carga desde cero.

CSV en UTF-8, separados por coma, punto decimal y encabezado. Los campos vacíos corresponden a valores ausentes; no convertir automáticamente identificadores, fechas o decimales al abrirlos en Excel.

Desde la raíz: `python3 datos/generar_dataset.py` (Python 3.10+, biblioteca estándar). Regenera tablas, SQL y controles Python; no descarga datos ni repite la extracción/selección desde Access. El reporte PostgreSQL debe verificarse por separado si cambia el generador.

Las instrucciones de carga desde cero están en el [README principal](../README.md). Las capturas de pgAdmin aportadas el 23/09/2026 confirman conteos, limpieza y conciliación y están incorporadas al README principal. Quedan pendientes los controles locales adicionales de fechas, pedidos mensuales, trazabilidad y tipos. No se conservan evidencias del enfoque descartado. El dataset está publicado con autorización del usuario para incluir nombres y CUIT de la fuente pública (21/09/2026).

## Alcance de la entrega

Se prepara y verifica el modelo V2. `analisis.sql` contiene únicamente la primera consulta de negocio adaptada; su revisión conjunta y las cinco restantes están pendientes. No se declara terminado el proyecto.
