# Estado del proyecto y guía de continuidad

Última actualización: 2026-09-21.
Repositorio: https://github.com/Malczewski94/proyecto-coderhouse-analisis-combustibles-postgresql
Rama de trabajo: `main`.

## 1. Cómo retomar en otro chat

Leer este archivo, el README raíz, `analisis.sql` y los commits posteriores a esta actualización. Para detalles del dataset, leer `datos/README.md` y `datos/diccionario.md`. Comprobar el estado real de GitHub antes de modificar archivos: este documento es un punto de continuidad, no reemplaza los archivos actuales.

Trabajar en español, paso a paso y documentar cada avance. No completar todas las consultas de una vez: el usuario quiere entender, ejecutar y revisar cada resultado. No repetir la preparación ya realizada ni presentar pruebas técnicas previas como análisis de negocio terminado.

Actualizar este archivo al cerrar cada avance relevante, junto con los archivos afectados: estado, resultado comprobado, evidencia, pendiente y próxima acción. Si algo falla, registrar qué quedó guardado y qué no. No afirmar que una escritura o ejecución fue exitosa sin confirmación. No incorporar claves ni credenciales.

## 2. Objetivo y alcance

Proyecto final Coderhouse: análisis comercial de combustibles con PostgreSQL. Simular el trabajo de un analista desde la preparación y limpieza hasta la interpretación de resultados para una red comercial ficticia.

Dataset híbrido: establecimientos, productos, volúmenes y precios mensuales reales; clientes compradores, pedidos, fechas diarias y relaciones comerciales simulados. No representa transacciones reales ni información interna de YPF.

Muestra minorista de 2025: 18 establecimientos, tres en cada provincia de Buenos Aires, Chaco, Córdoba, Corrientes, Misiones y Santa Fe; doce meses y siete productos. Fuente: `precios_eess_2025_en_adelante.accdb`, tabla `public_vi_access_eess_2025_en_adelante`. Se extrajeron 408.550 filas; la simulación utiliza 1.007 registros del canal Al público. La muestra original seleccionada tiene 1.013 filas antes de excluir seis de otros canales. No se usa el archivo mayorista.

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

## 4. Estructura definida

Base prevista: `capstone_project`. Esquema: `combustibles`. Trabajo del usuario en PostgreSQL y pgAdmin.

| Tabla | Función | Filas esperadas/documentadas |
| --- | --- | ---: |
| operadores | Establecimientos de referencia | 18 |
| productos | Productos, categorías y unidades | 7 |
| clientes | Compradores ficticios | 432 |
| pedidos | Cabeceras con cliente, operador, fecha y estado | 4.909 |
| detalle_pedido | Detalles limpios y vínculo a la fuente | 22.894 |
| fuente_ventas | Registros mensuales reales incluidos | 1.007 |
| detalle_pedido_entrada | Entrada didáctica con incidencias | 22.953 |

Cuatro tablas comerciales: clientes, productos, pedidos y detalle_pedido. Las restantes conservan trazabilidad y permiten auditar la limpieza. Cada pedido pertenece a un cliente y operador; cada detalle a un pedido, producto y registro fuente. Usar claves primarias/foráneas, cantidades y precios positivos, DATE y NUMERIC.

## 5. Estado por paso

| Paso | Estado | Qué falta |
| --- | --- | --- |
| 1. Problema | Definido y documentado | Mantener coherencia con resultados finales |
| 2. Preparación/carga | Realizada previamente y documentada | Publicación incompleta; captura conjunta de conteos |
| 3. Limpieza | Documentada con evidencias en pgAdmin | Mantener trazabilidad; no repetir la carga |
| 4. Análisis | En desarrollo: primera consulta propuesta | Revisar resultado con el usuario y desarrollar las restantes |
| 5. Hallazgos | Pendiente | Interpretaciones, evidencias y conclusiones |

La entrada tiene 22.953 filas, 59 repeticiones y 168 celdas de precio nulas. Se introdujeron 167 precios nulos en detalles distintos y un duplicado repite uno de ellos. DISTINCT elimina duplicados exactos y COALESCE recupera el precio del mismo registro fuente. Salida: 22.894 filas, cero repeticiones y cero precios nulos.

La conciliación documentada en pgAdmin compara 1.007 registros y da cero diferencias de cantidad o importe. Las comprobaciones técnicas previas con Python/Decimal y PGlite (PostgreSQL 18.3) son evidencias separadas, no ejecución nueva en este chat. No se ha conectado este chat a la base local del usuario.

## 6. Decisiones y razones

- Usar datos reales más simulación para construir el modelo comercial sin inventar que se conocen compradores o pedidos reales.
- Separar operadores de clientes: una estación es referencia de origen y no el comprador ficticio.
- La bandera es la marca declarada; no acredita franquicia ni propiedad común.
- Usar solo 2025 y una muestra intencional manejable; no extrapolar resultados a Argentina.
- Convertir líquidos de m³ a litros y conservar GNC en m³; nunca sumar ambas unidades como un volumen único.
- Calcular importes en ARS nominales con precio promedio mensual con impuestos. No llamarlos facturación auditada, rentabilidad ni crecimiento real ajustado por inflación.
- Recuperar precios desde fuente_ventas porque el generador asignó ese mismo precio a los detalles; no rellenar con cero ni con un promedio general.
- Conservar entrada y salida para demostrar limpieza. Las incidencias fueron introducidas para el ejercicio, no atribuirlas a la fuente pública.
- Semilla del generador: 20250915. La concentración de compradores está inducida por ponderaciones del generador; no es un descubrimiento del mercado.
- La carga incluye INSERT y una transacción; no requiere importar cada CSV por separado. No volver a ejecutar estructura.sql sobre las tablas existentes: no borra objetos previos.
- La publicación de estructura.sql y los CSV del dataset quedó pendiente por nombres y CUIT de operadores, según el README actual. Esta sesión no resolvió ese pendiente ni publicó esos datos.

## 7. Análisis previstos y avance

| Pregunta | Criterio | Estado |
| --- | --- | --- |
| Cinco clientes con mayor gasto | SUM(cantidad × precio) por cliente | Consulta en analisis.sql; interpretación pendiente |
| Evolución mensual de ventas | Importe de referencia por mes | Pendiente |
| Tres productos menos vendidos | Volumen en litros entre seis productos líquidos; GNC aparte | Pendiente |
| Ranking de pedidos por categoría | Sumar importe del pedido en cada categoría y aplicar RANK por categoría | Pendiente |
| Concentración del top 5 | Importe top 5 / total × 100 | Pendiente |
| Precio ponderado por producto/mes | SUM(cantidad × precio) / SUM(cantidad) | Pendiente |

La primera consulta usa JOIN, GROUP BY, COUNT(DISTINCT id_pedido), SUM, filtro Concretado y LIMIT 5. No se registró todavía aquí un resultado validado conjuntamente ni conclusiones.

## 8. Archivos disponibles y ausentes

Disponibles en GitHub al verificar main:

- `README.md`: pasos 1–3, métricas y pendientes.
- `analisis.sql`: primera consulta de negocio.
- `validaciones.sql`: controles de conteos, limpieza y conciliación.
- `datos/README.md`: metodología, selección, simulación y reproducción.
- `datos/diccionario.md`: campos, claves y unidades.
- `datos/generar_dataset.py`: generador.
- `datos/validacion.json` y `datos/validacion_postgresql.json`: pruebas previas.
- `datos/advertencias_fuente.csv`: archivo de advertencias.
- `imagenes/limpieza.png` y `imagenes/conciliacion.png`: capturas.
- `PROJECT_STATE.md`: creado en esta actualización.

Ausentes del repositorio al verificar: `estructura.sql`, los CSV del dataset (incluido `fuente_original.csv`) y otros auxiliares mencionados en la metodología, como `sha256_csv.json`, `perfil_fuente.json` y `resumen_dataset.json`. Estaban descritos como preparados previamente; su disponibilidad fuera del repositorio no se comprobó en esta sesión. El generador necesita fuente_original.csv: por ahora no permite reproducir el proyecto desde GitHub solamente.

Referencia previa a la creación de este archivo: commit `a17c5a3e4a691e831d47ca8d2d1e75a9bfa4c4b6`, del 2026-09-21, “Documentar pasos 1 a 3 y evidencias; dejar publicación de datos pendiente”. Consultar el historial para el commit de este archivo y cualquier cambio posterior.

## 9. Evidencias y documentación pendientes

- Captura del conteo conjunto de todas las tablas en pgAdmin.
- Resultados y capturas legibles de las consultas de negocio, a medida que se revisen.
- Interpretaciones, conclusiones y limitaciones específicas por consulta.
- Completar las instrucciones de reproducción cuando estén publicados los archivos necesarios.
- Revisar el nombre real de la base local frente a capstone_project antes de dar la configuración por plenamente verificada.
- Alinear datos/README.md con el estado actual: todavía habla de publicación GitHub futura y de capturas locales futuras, mientras el README raíz ya registra ambas cosas parcialmente realizadas.
- Verificar al finalizar el cumplimiento de cada criterio de la rúbrica y la ejecución completa de los scripts entregados.

Las capturas son evidencias acordadas para el proyecto; no afirmar que cada captura enumerada sea un requisito literal de la consigna.

## 10. Criterios de documentación del README

Mantener la estructura de los cinco pasos del pipeline. Explicar qué se hizo y por qué, con cifras comprobadas. Diferenciar preparado, ejecutado, validado y publicado. No declarar reproducibilidad mientras falten datos o scripts.

Para cada análisis: pregunta de negocio, definición de métrica/unidad/filtros, referencia a la consulta, resultado observado, interpretación y limitación. Incorporar la captura junto a su explicación con rutas relativas en imagenes/. No inventar resultados ni causas.

Conservar la diferencia entre datos reales, derivados y sintéticos. Separar evidencia técnica de conclusiones comerciales. Documentar decisiones de nulos, duplicados y unidades, y los pasos concretos para ejecutar. Usar el README como explicación del proyecto; este archivo conserva continuidad y tareas pendientes.

## 11. Último punto y siguiente tarea

Último punto: se recuperó el trabajo tras un fallo de la conversación anterior, se comprobó lectura de GitHub y los permisos informados, y se recuperó la consigna detallada con rúbrica. El usuario pidió crear este archivo antes de continuar el análisis.

Siguiente tarea de trabajo: retomar la primera consulta de analisis.sql con el usuario, ejecutarla en su base ya cargada (o revisar el resultado que aporte), comprobar los cinco clientes, interpretar los importes y documentar resultado/evidencia. Luego avanzar consulta por consulta.

Pendiente de publicación independiente: recuperar los archivos faltantes y resolver la publicación de datos señalada en el README. No bloquear la revisión de una consulta local por ese pendiente, pero sí resolverlo antes de declarar la entrega reproducible y completa.
