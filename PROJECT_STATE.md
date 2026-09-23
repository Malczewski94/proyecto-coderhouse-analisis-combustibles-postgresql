# Estado del proyecto y guía de continuidad

Última actualización: 2026-09-23. Versión vigente del modelo: **V2**.
Repositorio: https://github.com/Malczewski94/proyecto-coderhouse-analisis-combustibles-postgresql
Rama publicada: main.

## 1. Cómo retomar

Leer este archivo, README.md, datos/README.md, datos/diccionario.md y los commits posteriores. Trabajar en español y paso a paso. Antes de cada tarea explicar qué parte del pipeline y del entregable cubre. No desarrollar todas las consultas de una vez: el usuario quiere comprender y revisar cada resultado.

Actualizar este archivo con cada avance, diferenciando preparado, validado técnicamente, ejecutado por el usuario y publicado. No dar por ejecutadas tareas en el PostgreSQL local del usuario: no hay conexión a esa base.

### Criterio editorial del README

El usuario requiere documentación en primera persona, con voz del autor del proyecto. El README explica problema, modelo, decisiones metodológicas, consultas, resultados y límites; no relata conversaciones, autorizaciones, cambios de enfoque ni entregas de capturas. Evitar expresiones como «el usuario confirmó», «se acordó» o «captura aportada por el usuario».

Cada captura debe estar acompañada por la consulta SQL que produce su resultado y una interpretación. Un enlace o una referencia a validaciones.sql no sustituye mostrar esa consulta. Mantener las instrucciones mínimas de reproducción, exigidas por la entrega, separadas de la descripción del proyecto. El seguimiento operativo y los pendientes detallados pertenecen a PROJECT_STATE.md.

La sección de reemplazo de la carga se retiró del README. Para una reconstrucción expresamente solicitada: reiniciar_esquema.sql comprueba capstone_project y elimina combustibles y combustibles_v1 con sus objetos; luego estructura.sql reconstruye el modelo. Esta ruta es destructiva y no corresponde ejecutarla ahora, porque la carga ya fue comprobada.

La revisión editorial no ejecuta nuevas validaciones ni completa análisis pendientes.

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

Base confirmada por el usuario: capstone_project. Esquema vigente: combustibles. Una cuenta por establecimiento, no por CUIT consolidado.

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
| 2. Preparación/carga | Generador y SQL actualizados; carga técnica comprobada; conteos locales confirmados mediante captura (23/09/2026) |
| 3. Limpieza | 8 precios nulos y 3 duplicados; limpieza y conciliación confirmadas en capturas locales (23/09/2026) |
| 4. Análisis | Primera consulta adaptada; prueba técnica exitosa; resultado e interpretación con usuario pendientes |
| 5. Hallazgos | Pendientes de revisión conjunta |

Entrada: 1.010 filas, 3 repeticiones y 8 precios nulos. Salida: 1.007, cero repeticiones y cero nulos. DISTINCT elimina copias; COALESCE recupera el precio de la misma fuente por el diseño del caso. Los nulos y duplicados son sintéticos. Fechas completas y válidas: no imputar valores si no faltan.

Python Decimal comprueba claves, doce meses, limpieza y conservación exacta de volúmenes/importes. PGlite 0.5.8 (PostgreSQL 18.3) ejecutó estructura.sql, validaciones.sql y primera consulta, comprobó 1.007 fuentes sin diferencias, fechas/tipos, JOIN sin multiplicación y restricciones mensuales. Reportes en datos/validacion.json y datos/validacion_postgresql.json. No equivalen a ejecución en pgAdmin del usuario.

## 6. Archivos modificados y evidencias

- estructura.sql y datos/generar_dataset.py: modelo V2 determinista, sin reparto aleatorio ni semilla.
- CSV derivados, incidencias, conciliacion, resumen, hashes y validaciones: regenerados V2.
- fuente_original.csv, fuente_ventas.csv, operadores.csv, productos.csv y auxiliares de selección conservan la fuente original.
- reiniciar_esquema.sql: comprueba capstone_project y elimina los esquemas del proyecto antes de la carga desde cero.
- validaciones.sql: mantiene conteos/limpieza/conciliación y agrega fechas, pedidos mensuales, JOIN y tipos.
- analisis.sql: top 5 con nombres reales, localidad, provincia, cantidad_pedidos y gasto_referencia_ars.
- README y diccionario: actualizados; README incluye relaciones mediante Mermaid.
- Capturas de conteos, limpieza y conciliación: publicadas las nuevas en imagenes/ y enlazadas en README.

El usuario indicó «borrón y cuenta nueva»: no conservar carpetas históricas, capturas anteriores ni esquemas de respaldo. Se retiran esos archivos y la ruta de migración de la entrega vigente. Los commits normales de Git no se reescriben. Las capturas del usuario confirman los conteos, la limpieza y la conciliación del modelo cargado.

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

El 23/09/2026 el usuario aportó tres capturas de pgAdmin, publicadas en `imagenes/`:
- `conteos_tablas.png`: siete conteos coincidentes con el modelo.
- `limpieza.png`: entrada 1.010 filas / 3 repeticiones / 8 precios nulos; salida 1.007 / 0 / 0.
- `conciliacion.png`: 1.007 registros comprobados / 0 diferencias.

Son resultados observados en imágenes, no una conexión directa a su servidor. El nombre `capstone_project` está confirmado por el usuario, aunque no aparece en los recortes. No solicitar otra carga ni volver a ejecutar el reinicio.

1. Completar los bloques restantes de `validaciones.sql`: fechas (0 nulas/invalidas, 12 meses), un pedido mensual y doce pedidos por cliente (ambas consultas sin filas), trazabilidad (1.007 filas, 0 errores) y tipos DATE/NUMERIC.
2. Registrar los resultados locales confirmados sin atribuirles los resultados de las pruebas técnicas.
3. Retomar el top 5 de `analisis.sql`, revisar el resultado e interpretación con el usuario y documentarlos antes de avanzar a otra consulta.

No dar por terminados análisis, conclusiones ni reproducción final. Mantener las evidencias actuales y no fabricar capturas.
