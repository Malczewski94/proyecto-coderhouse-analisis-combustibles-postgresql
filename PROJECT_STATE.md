# Estado del proyecto y guía de continuidad

Última actualización: 2026-09-21. Versión vigente del modelo: **V2**.
Repositorio: https://github.com/Malczewski94/proyecto-coderhouse-analisis-combustibles-postgresql
Rama publicada: main.

## 1. Cómo retomar

Leer este archivo, README.md, datos/README.md, datos/diccionario.md y los commits posteriores. Trabajar en español y paso a paso. Antes de cada tarea explicar qué parte del pipeline y del entregable cubre. No desarrollar todas las consultas de una vez: el usuario quiere comprender y revisar cada resultado.

Actualizar este archivo con cada avance, diferenciando preparado, validado técnicamente, ejecutado por el usuario y publicado. No dar por ejecutadas tareas en el PostgreSQL local del usuario: no hay conexión a esa base.

## 2. Decisión central aprobada y alcance

El usuario confirmó que la intención original era usar operadores como clientes de un mayorista ficticio. El modelo V1 con compradores ficticios no reflejaba esa intención. Autorizó modificar los archivos, un pedido mensual por establecimiento y precios originales como referencia.

V2: 18 establecimientos reales son cuentas cliente de un mayorista ficticio. La fuente gubernamental informa ventas de estaciones al público, no compras a distribuidores. El Gobierno es fuente/publicador, no vendedor. Se supone que el volumen vendido al público equivale a la compra mensual simulada, sin variación de existencias. El precio minorista mensual con impuestos se utiliza como referencia, nunca como precio mayorista real. No se inventan descuentos ni márgenes.

Se conserva la muestra de 2025: tres establecimientos en cada una de Buenos Aires, Chaco, Córdoba, Corrientes, Misiones y Santa Fe; siete productos. Fuente Access precios_eess_2025_en_adelante.accdb, tabla public_vi_access_eess_2025_en_adelante; extracción previa de 408.550 filas. Muestra congelada de 1.013 filas, seis excluidas por canal; 1.007 incluidas Al público. No se usa el archivo mayorista.

## 3. Consigna recuperada y verificada

Se leyó el material guardado como “Markdown.md pegado” y se contrastó el entregable y la rúbrica con “program-summary (1).pdf”, páginas 248–250. Este apartado es una síntesis fiel para continuidad, no una transcripción íntegra. El material original no está incorporado al repositorio.

### Pipeline del módulo

1. Definición del problema y preguntas de negocio.
2. Preparación y carga en PostgreSQL desde pgAdmin.
3. Limpieza y transformación; el módulo menciona COALESCE, NULLIF y CASE.
4. Análisis con JOIN, GROUP BY y funciones de ventana.
5. Comunicación e interpretación de hallazgos.

### Entregable formal

Repositorio público GitHub con:

- `estructura.sql`: creación de tablas e inserciones, o instrucciones de carga.
- `analisis.sql`: consultas de análisis comentadas.
- `README.md`: problema de negocio, hallazgos interpretados e instrucciones de ejecución.

Crear la base `capstone_project`; importar o generar el dataset. El material permite usar datos del curso, Kaggle o crear tablas clientes, pedidos y productos. Identificar nulos críticos de precios/fechas y tratarlos justificadamente con COALESCE; verificar DATE y NUMERIC.

Resolver al menos tres de estos cuatro análisis:

1. Top 5 clientes por gasto total, con GROUP BY y SUM.
2. Ventas totales por mes, con funciones de fecha.
3. Tres productos menos vendidos.
4. Ranking de pedidos por categoría con RANK().

Además, los criterios generales requieren JOIN entre al menos dos tablas, agregación, una función avanzada (ventana o CASE), limpieza antes del análisis y scripts ejecutables en PostgreSQL sin errores. Los comentarios deben explicar la finalidad de las decisiones. El README debe interpretar resultados, no limitarse a describir el SQL.

**Diferencia interna del material:** el cierre del módulo pide al menos cinco preguntas de negocio; el entregable pide al menos tres de los cuatro análisis enumerados. El alcance actual del README incluye los cuatro y dos preguntas adicionales. Mantener esa cobertura para satisfacer ambos textos. NULLIF y CASE aparecen como herramientas del módulo; no se ha encontrado una obligación de usar las tres funciones de limpieza conjuntamente.

### Rúbrica

| Criterio | Peso |
| --- | ---: |
| Estructura, configuración de repositorio y base de datos | 20% |
| Limpieza y transformación | 15% |
| Consultas de análisis de negocio | 30% |
| Calidad del código SQL | 15% |
| Documentación y conclusiones de negocio | 20% |

Total: 100 puntos. Aprobación: 70 puntos. No confundir esta entrega con el proyecto de IA de reclamos logísticos ni con otras preentregas SQL.

## 4. Modelo vigente

Base requerida: capstone_project. Esquema V2: combustibles. Una cuenta por establecimiento, no por CUIT consolidado.

| Tabla | Filas | Función |
| --- | ---: | --- |
| operadores | 18 | Identidad de origen del establecimiento |
| clientes | 18 | Cuenta con id_operador único, nombre y provincia reales |
| productos | 7 | Producto, categoría y unidad |
| pedidos | 216 | Un pedido mensual por cliente |
| fuente_ventas | 1.007 | Registro real de venta al público |
| detalle_pedido | 1.007 | Una línea por registro fuente |
| detalle_pedido_entrada | 1.010 | Entrada con incidencias didácticas |

Pedidos ya no duplica id_operador: se obtiene por clientes. Se eliminó segmento inventado. Fecha = primer día del mes como representación contable, no fecha de entrega. UNIQUE(cliente, fecha) más CHECK de primer día garantizan frecuencia mensual. Doce pedidos por cliente no demuestran fidelidad.

Se conservan PK/FK y cantidades/precios positivos. DATE para fecha/período; NUMERIC para cantidades y precios. Líquidos en L, GNC en m³, sin sumarlos como volumen único. Totales: 93.213.130 L y 8.638.800,20 m³; importe de referencia 141.717.574.607,79 ARS nominales. Sin extrapolación nacional ni inferencias de rentabilidad.

## 5. Estado y validación

| Paso del pipeline | Estado V2 |
| --- | --- |
| 1. Problema | Reformulado y aprobado: mayorista ficticio y establecimientos clientes |
| 2. Preparación/carga | Generador y SQL actualizados; carga técnica comprobada; carga local y captura pendientes |
| 3. Limpieza | 8 precios nulos y 3 duplicados; validada técnicamente; capturas locales pendientes |
| 4. Análisis | Primera consulta adaptada; prueba técnica exitosa; resultado e interpretación con usuario pendientes |
| 5. Hallazgos | Pendientes de revisión conjunta |

Entrada: 1.010 filas, 3 repeticiones y 8 precios nulos. Salida: 1.007, cero repeticiones y cero nulos. DISTINCT elimina copias; COALESCE recupera el precio de la misma fuente por el diseño del caso. Los nulos y duplicados son sintéticos. Fechas completas y válidas: no imputar valores si no faltan.

Python Decimal comprueba claves, doce meses, limpieza y conservación exacta de volúmenes/importes. PGlite 0.5.8 (PostgreSQL 18.3) ejecutó estructura.sql, validaciones.sql y primera consulta, comprobó 1.007 fuentes sin diferencias, fechas/tipos, JOIN sin multiplicación y restricciones mensuales. También comprobó migración V1→V2, preservación de 432 clientes antiguos y rechazo de migración repetida. Reportes en datos/validacion.json y datos/validacion_postgresql.json. No equivalen a ejecución en pgAdmin del usuario.

## 6. Archivos modificados y evidencias

- estructura.sql y datos/generar_dataset.py: modelo V2 determinista, sin reparto aleatorio ni semilla.
- CSV derivados, incidencias, conciliacion, resumen, hashes y validaciones: regenerados V2.
- fuente_original.csv, fuente_ventas.csv, operadores.csv, productos.csv y auxiliares de selección conservan la fuente original.
- migrar_v1.sql: renombra combustibles a combustibles_v1 sin borrar datos, con guardas.
- validaciones.sql: mantiene conteos/limpieza/conciliación y agrega fechas, pedidos mensuales, JOIN y tipos.
- analisis.sql: top 5 con nombres reales, localidad, provincia, cantidad_pedidos y gasto_referencia_ars.
- README y diccionario: actualizados; README incluye relaciones mediante Mermaid.
- historico/v1/: capturas y validación PostgreSQL anterior, claramente excluidas como evidencia V2.

V1 completa se conserva en el historial, commit d81d873cd2004164bb0cdb330f045efe1a54add9. No eliminar el respaldo local del usuario. El top 5 antiguo con C0265 y demás clientes ficticios es obsoleto y no debe interpretarse ni documentarse como V2.

La publicación de nombres/CUIT de operadores públicos fue autorizada el 21/09/2026. La actualización del modelo y sus archivos fue autorizada explícitamente en esta conversación.

## 7. Preguntas y forma de trabajar

1. Cinco clientes con mayor gasto de referencia: SQL adaptado, pendiente captura/interpretación V2.
2. Evolución mensual de importes: pendiente.
3. Tres productos líquidos menos vendidos, GNC aparte: pendiente.
4. Ranking de pedidos por categoría con RANK(): pendiente.
5. Concentración del top 5: pendiente.
6. Precio ponderado por producto/mes: pendiente.

Las secciones 1–6 de la actividad son orientación, pipeline, ejemplos, controles, conceptos y cierre, no seis entregas diferentes. Se cubren los cuatro pasos del entregable: configuración, limpieza, análisis y documentación. Mantener las seis preguntas y revisar todos los criterios de la rúbrica al cerrar.

Para cada consulta: pregunta y métrica → explicación y ejecución del usuario → control del resultado → interpretación conjunta y límites → SQL/README/evidencia/estado en GitHub. No añadir análisis futuros para adelantarse al aprendizaje.

## 8. Siguiente tarea concreta

Guiar la actualización en pgAdmin antes de retomar análisis:

1. Pedir resultado de SELECT current_database(); el nombre local aún no está confirmado.
2. En la base que contiene V1, ejecutar migrar_v1.sql una sola vez; conserva el esquema antiguo. Luego estructura.sql V2 completo. En base nueva vacía solo estructura.sql.
3. Ejecutar validaciones.sql por bloques y pedir capturas V2: conteos generales, limpieza y conciliación. Confirmar también fechas (0 nulas/invalidas, 12 meses) y trazabilidad (1.007 filas, 0 errores).
4. Incorporar las nuevas evidencias, cerrar los pendientes locales y retomar el top 5 V2.

No pedir de nuevo autorización para estas modificaciones: ya fue concedida. Si una carga falla, conservar el respaldo y diagnosticar sin borrar esquemas. No presentar la entrega completa hasta revisar análisis, conclusiones y reproducción final.
