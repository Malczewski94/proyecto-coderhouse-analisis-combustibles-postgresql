# Estado del proyecto y guía de continuidad

Última actualización: 2026-09-23. Versión vigente del modelo: **V2**.
Repositorio: https://github.com/Malczewski94/proyecto-coderhouse-analisis-combustibles-postgresql
Rama publicada: main.

## 1. Cómo retomar

Leer este archivo, README.md, datos/README.md, datos/diccionario.md y los commits posteriores. Trabajar en español y paso a paso. Antes de cada tarea explicar qué parte del pipeline y del entregable cubre. No desarrollar todas las consultas de una vez: el usuario quiere comprender y revisar cada resultado.

Actualizar este archivo con cada avance, diferenciando preparado, validado técnicamente, ejecutado por el usuario y publicado. No dar por ejecutadas tareas en el PostgreSQL local del usuario: no hay conexión a esa base.

### Criterio editorial del README

Evitar tablas que transcriban resultados ya visibles en capturas. Usar consulta → captura → interpretación; conservar tablas de estructura, métricas o archivos cuando aporten información distinta.

El usuario requiere documentación en primera persona, con voz del autor del proyecto. El README explica problema, modelo, decisiones metodológicas, consultas, resultados y límites; no relata conversaciones, autorizaciones, cambios de enfoque ni entregas de capturas. Evitar expresiones como «el usuario confirmó», «se acordó» o «captura aportada por el usuario».

Cada captura debe estar acompañada por la consulta SQL que produce su resultado y una interpretación. Un enlace o una referencia a validaciones.sql no sustituye mostrar esa consulta. Mantener las instrucciones mínimas de reproducción, exigidas por la entrega, separadas de la descripción del proyecto. El seguimiento operativo y los pendientes detallados pertenecen a PROJECT_STATE.md.

La sección de reemplazo de la carga se retiró del README. Para una reconstrucción expresamente solicitada: reiniciar_esquema.sql comprueba capstone_project y elimina combustibles y combustibles_v1 con sus objetos; luego estructura.sql reconstruye el modelo. Esta ruta es destructiva y no corresponde ejecutarla ahora, porque la carga ya fue comprobada.

Los comentarios de todos los .sql deben justificar por qué se eligen filtros, agrupaciones, uniones y tratamientos; describir solo qué hace una cláusula no satisface el criterio. Colocar las justificaciones junto al código relevante, sin instrucciones al lector, pendientes ni resultados esperados. Mantener sincronizados los comentarios SQL de datos/generar_dataset.py. Los resultados observados se documentan en el README junto a la consulta y captura.

## 2. Decisión central aprobada y alcance

El usuario confirmó que la intención original era usar operadores como clientes de un mayorista ficticio. El modelo V1 con compradores ficticios no reflejaba esa intención. Autorizó modificar los archivos, un pedido mensual por establecimiento y precios originales como referencia.

V2: 18 establecimientos reales son cuentas cliente de un mayorista ficticio. La fuente gubernamental informa ventas de estaciones al público, no compras a distribuidores. El Gobierno es fuente/publicador, no vendedor. Se supone que el volumen vendido al público equivale a la compra mensual simulada, sin variación de existencias. El precio minorista mensual con impuestos se utiliza como referencia, nunca como precio mayorista real. No se inventan descuentos ni márgenes.

Se conserva la muestra de 2025: tres establecimientos en cada una de Buenos Aires, Chaco, Córdoba, Corrientes, Misiones y Santa Fe; siete productos. Fuente Access precios_eess_2025_en_adelante.accdb, tabla public_vi_access_eess_2025_en_adelante; extracción previa de 408.550 filas. Muestra congelada de 1.013 filas, seis excluidas por canal; 1.007 incluidas Al público. No se usa el archivo mayorista.

## 3. Consigna recuperada y verificada

Se leyó el material guardado como “Markdown.md pegado” y se contrastó el entregable y la rúbrica con “program-summary (1).pdf”, páginas 248–250. Este apartado es una síntesis fiel para continuidad, no una transcripción íntegra. El material original no está incorporado al repositorio.

### Numeración y criterios de la actividad

El 23/09/2026 el usuario volvió a proporcionar el texto completo de la actividad. Distinguir sus seis apartados generales (conversación con datos; pipeline; casos de industria; errores a evitar; glosario; conclusión) de los cinco pasos del pipeline incluidos dentro del apartado 2. No confundir ninguno con la numeración editorial del README.

El README ahora sigue los seis apartados generales de la actividad: 1 contexto del análisis; 2 pipeline con 2.1 problema, 2.2 preparación/carga, 2.3 limpieza, 2.4 análisis y 2.5 comunicación; 3 aplicación al contexto de negocio (los casos de industria son orientación); 4 controles con cuatro subapartados; 5 glosario; 6 conclusiones. Las seis consultas se numeran 2.4.1–2.4.6. Incluye índice y enlaces internos corregidos. No volver a mezclar la numeración principal con la del pipeline.

Criterios explícitos del texto recibido para la revisión final:
- Al menos cinco preguntas de negocio: hay seis documentadas.
- README con contexto, hallazgos interpretados y reproducción.
- SQL de creación e inserciones o instrucciones de carga, y SQL de análisis comentado.
- JOIN entre al menos dos tablas; GROUP BY y una función avanzada (ventana o CASE).
- Limpieza previa al análisis, con tratamiento justificado de nulos y control de filas en JOIN.
- Comentarios que expliquen por qué se toman las decisiones.
- Scripts sin errores de sintaxis y ejecutables en PostgreSQL: distinguir las pruebas técnicas previas de la ejecución local documentada; no declarar una nueva prueba integral sin realizarla.

El glosario es apoyo conceptual y queda explícito en README por solicitud editorial. Los casos de industria son ejemplos de inspiración, no exigencias de reproducir esas tecnologías. El texto pegado no aporta nuevos porcentajes de evaluación: conservar la rúbrica previamente recuperada hasta contrastar las instrucciones detalladas del entregable. No inventar puntajes ni declarar finalizada la revisión integral.

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
| 2. Preparación/carga | Generador y SQL actualizados; carga técnica comprobada; conteos, fechas, pedidos mensuales, trazabilidad y tipos confirmados mediante capturas locales (23/09/2026) |
| 3. Limpieza | 8 precios nulos y 3 duplicados; limpieza y conciliación confirmadas en capturas locales (23/09/2026) |
| 4. Análisis | Seis análisis ejecutados y documentados; CSV de precios ponderados conciliado |
| 5. Hallazgos | Conclusiones redactadas en README; revisión final pendiente |

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

1. Cinco clientes con mayor gasto de referencia: ejecutado por el usuario, captura publicada e interpretación descriptiva documentada en README.
2. Evolución mensual de importes: ejecutada por el usuario; captura y doce importes documentados, con interpretación nominal.
3. Tres productos líquidos menos vendidos: ejecutada; captura y resultados documentados con interpretación y límites.
4. Ranking de pedidos por categoría con RANK(): ejecución confirmada, captura e interpretación publicadas.
5. Concentración del top 5: ejecutada y documentada; 78173422323.82 / 141717574607.79 ARS, participación 55.16%.
6. Precio ponderado por producto/mes: CSV de ejecución recibido y publicado; 83 grupos conciliados con pedidos y detalles, sin diferencias.

Las secciones 1–6 de la actividad son orientación, pipeline, ejemplos, controles, conceptos y cierre, no seis entregas diferentes. Se cubren los cuatro pasos del entregable: configuración, limpieza, análisis y documentación. Mantener las seis preguntas y revisar todos los criterios de la rúbrica al cerrar.

Para cada consulta: pregunta y métrica → explicación y ejecución del usuario → control del resultado → interpretación conjunta y límites → SQL/README/evidencia/estado en GitHub. No añadir análisis futuros para adelantarse al aprendizaje.

## 8. Estado de las evidencias y siguiente tarea

Los ocho controles de validaciones.sql están confirmados mediante capturas del usuario en pgAdmin y publicados en imagenes/, con consulta e interpretación en el README:
- Conteos: 18 operadores, 7 productos, 18 clientes, 216 pedidos, 1.007 detalles, 1.007 fuentes y 1.010 entradas.
- Limpieza: entrada 1.010 / 3 repeticiones / 8 precios nulos; salida 1.007 / 0 / 0.
- Conciliación: 1.007 registros, 0 diferencias.
- Fechas: 0 nulas, 0 inválidas, 12 meses.
- Pedidos por cliente/mes: consulta de anomalías sin filas.
- Doce pedidos por cliente: consulta de anomalías sin filas.
- Trazabilidad: 1.007 filas unidas, 0 errores.
- Tipos: DATE para período y fecha; NUMERIC(18,3) para cantidad y NUMERIC(18,2) para precio.

Las imágenes muestran resultados de la ejecución del usuario; no hay conexión directa al servidor. La base capstone_project ya está confirmada. No repetir carga ni reinicio.

El usuario aportó la captura del top 5, publicada en imagenes/top_5_clientes.png. Orden e importes en ARS: C0012 26229253774.57; C0011 16697526321.86; C0001 12936900987.89; C0006 12487467190.62; C0017 9822274048.88. Todos tienen 12 pedidos. El nombre truncado de C0001 se completó desde datos/clientes.csv. Interpretación documentada: SUCATA encabeza el ranking; cuentas en Santa Fe y Córdoba; la frecuencia fija no mide fidelidad, y el importe no mide rentabilidad.

Evolución mensual confirmada mediante captura del usuario (imagenes/ventas_mensuales.png): 12 filas, 18 pedidos y 18 clientes cada mes. Importes enero-diciembre: 10095233279.25; 10024372092.50; 10636993017.83; 10213597094.02; 10765760001.72; 10813129530.75; 12004274839.26; 12260514811.11; 12356546180.88; 13391668900.60; 13295202542.47; 15860282317.40 ARS. Suma comprobada con Decimal: 141717574607.79 ARS. Máximo diciembre, mínimo febrero, variación diciembre/enero +57.11% nominal. No atribuir el incremento a inflación, volumen o estacionalidad sin análisis que lo sostenga.

La captura mensual se reemplazó por la versión con fechas completas en el mismo archivo imagenes/ventas_mensuales.png. Los importes coinciden y no cambian la interpretación.

La tercera consulta quedó confirmada en imagenes/productos_menos_vendidos.png: P004 Kerosene 495530 L; P005 Nafta común 3405860 L; P006 Nafta premium 11885870 L. El nombre completo de P006 procede del catálogo de productos ya leído. El README documenta menor volumen, sin equipararlo a baja rentabilidad ni atribuir causas.

Ranking confirmado en imagenes/ranking_pedidos_categoria.png: doce filas, tres por categoría. Ganadores: Gasoil V000139/C0012 julio 1763802594.40; GNC V000067/C0006 julio 120939940.50; Nafta V000012/C0001 diciembre 999287344.80; Queroseno V000158/C0014 febrero 107067890.00. D.G.B. ocupa las tres primeras posiciones GNC y EL SURTIDOR las de nafta. Son importes parciales de pedido por categoría, no concentración anual.

Se retiraron las cuatro tablas que duplicaban resultados de limpieza, top 5, meses y productos. Se conservaron las tablas de preguntas, estructura y archivos. La captura que muestra la duplicación del README es referencia editorial y no evidencia nueva para publicar.

Concentración confirmada mediante imagenes/concentracion_top_5.png: importe top 5 78173422323.82 ARS; total 141717574607.79; participación 55.16%. El README interpreta que cinco de dieciocho cuentas reúnen más de la mitad del importe, sin etiquetar arbitrariamente el riesgo ni inferir rentabilidad.

Sexta consulta confirmada mediante data-1790186245005.csv, publicado sin alterar su contenido en resultados/precios_ponderados_mensuales.csv. Contiene 83 grupos: seis productos con 12 meses y P005 con 11, sin octubre. Recalculados los 83 volúmenes, cantidades de clientes y precios ponderados contra datos/pedidos.csv y datos/detalle_pedido.csv, con aritmética entera escalada y redondeo a centavos; cero diferencias. No se ejecutó una consulta nueva en el servidor del usuario. No convertir la ausencia de octubre en precio cero.

README actualizado con resultado completo enlazado, interpretación en primera persona y conclusiones de las seis preguntas. La variación enero/diciembre se calcula sobre precios redondeados del CSV. Se destacan cobertura variable y efecto de composición sin atribuir causalidad. El CSV sustituye múltiples capturas para este análisis, como se solicitó en el paso anterior.

Siguiente paso: lectura de las conclusiones por el usuario y, cuando solicite la revisión completa, contrastar entrega con rúbrica, coherencia SQL/documentación, enlaces y legibilidad de capturas. No recargar ni reiniciar la base.

El usuario indica que los nombres truncados y otros detalles de presentación se revisarán al final cuando pida una revisión completa. No frenar las consultas para solicitar nuevas capturas por esos detalles. Mantener este pendiente para esa revisión.

Preferencia explícita: al documentar una captura, incluir en la respuesta el siguiente paso concreto y su consulta; no responder solamente confirmando la actualización. Continuar de una consulta a la vez.

Las seis consultas y las conclusiones globales están documentadas. La revisión final solicitada para el cierre sigue pendiente.

## Revisión de comentarios SQL

Se revisaron analisis.sql, validaciones.sql, estructura.sql y reiniciar_esquema.sql para explicar decisiones junto al código: unidades comparables, granularidad mensual, conteos sin duplicar, empates, denominadores, ponderación y recuperación del precio fuente. Se sincronizaron las consultas equivalentes del README y los comentarios emitidos por datos/generar_dataset.py. Se comprobó que los cuatro scripts mantienen el mismo SQL ejecutable al excluir comentarios y espacios. No requiere nueva carga ni nuevas capturas. Esta revisión puntual no sustituye la revisión integral pendiente.

## Revisión de correspondencia con la actividad

A solicitud del usuario, se corrigió la jerarquía del README y se preparó un checklist punto por punto. Se explicitó la comunicación en 2.5 y los controles en 4.1–4.4, incluido el criterio de no agregar índices sin evidencia de necesidad. Se verificó que estructura.sql no contiene CREATE INDEX adicional. El apartado 3 contextualiza el caso propio sin atribuirle análisis de canastas, PostGIS o JSON no realizados. Se conservaron los 15 bloques SQL del README y se comprobaron sus enlaces internos. Las conclusiones del apartado 6 se conservaron sin revisarlas en esta tarea.

Esta es una revisión de cobertura documental y estructura, no una nueva ejecución integral del SQL ni una inspección visual de todas las capturas. Pendientes: revisión final de legibilidad (nombres truncados), prueba integral de reproducción si se exige el cierre técnico y revisión conjunta del apartado 6. El requisito de ejecutabilidad tiene evidencias previas; no marcarlo como nuevamente probado durante este checklist.
