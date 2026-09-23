# Análisis de combustibles con PostgreSQL

Desarrollo este proyecto final de Coderhouse para analizar una cartera de clientes de un **distribuidor mayorista ficticio de combustibles**. Utilizo datos públicos de establecimientos reales y construyo un modelo relacional en PostgreSQL para estudiar los importes de venta simulados, la evolución mensual y la composición por productos.

Trabajo con 18 establecimientos de seis provincias, siete productos y los doce meses de 2025. Cada establecimiento representa un cliente del mayorista y tiene un pedido mensual. Distingo los datos de origen de los supuestos comerciales para que los resultados puedan interpretarse dentro del alcance del ejercicio.

## Índice

- [1. El análisis de datos como una conversación](#1-el-análisis-de-datos-como-una-conversación)
- [2. Flujo de trabajo del proyecto](#2-flujo-de-trabajo-del-proyecto): [2.1 Problema](#21-definición-del-problema), [2.2 Preparación](#22-preparación-y-carga), [2.3 Limpieza](#23-limpieza-y-transformación), [2.4 Análisis](#24-análisis-y-extracción-de-hallazgos) y [2.5 Comunicación](#25-comunicación-de-hallazgos).
- [3. Aplicación al contexto de negocio](#3-aplicación-al-contexto-de-negocio)
- [4. Controles para evitar errores de análisis](#4-controles-para-evitar-errores-de-análisis)
- [5. Glosario aplicado al proyecto](#5-glosario-aplicado-al-proyecto)
- [6. Conclusiones y próximos pasos](#6-conclusiones-y-próximos-pasos)
- [Archivos y reproducción](#archivos-y-reproducción)

## 1. El análisis de datos como una conversación

Utilizo PostgreSQL para transformar preguntas sobre una cartera comercial en resultados comprobables. Relaciono clientes, pedidos y productos, resumo importes y volúmenes y comparo operaciones mediante funciones de ventana. Vinculo cada resultado con una interpretación de negocio y explicito los límites de la simulación.

## 2. Flujo de trabajo del proyecto

### 2.1. Definición del problema

Mi objetivo es identificar las cuentas con mayor peso comercial y comprender cómo se distribuyen los volúmenes y los importes de referencia. Planteo estas preguntas:

| Pregunta | Métrica y criterio |
| --- | --- |
| ¿Cuáles son los cinco clientes con mayor gasto de referencia? | Suma de cantidad × precio de referencia por establecimiento. |
| ¿Cómo evolucionan las ventas mensuales simuladas? | Importe de referencia agrupado por mes. |
| ¿Cuáles son los tres productos menos vendidos? | Volumen en litros entre los seis combustibles líquidos; GNC por separado. |
| ¿Qué pedidos tienen mayor importe dentro de cada categoría? | Importe del pedido por categoría y posición mediante `RANK()`. |
| ¿Qué porcentaje del importe concentran los cinco principales clientes? | Importe del top 5 / importe total × 100. |
| ¿Cómo evoluciona el precio ponderado de cada producto? | `SUM(cantidad * precio) / SUM(cantidad)`, por producto y mes. |

#### Fuente de datos

Utilizo el conjunto público [Precios y volúmenes EESS, Resolución 1104/04](https://datos.gob.ar/ar/dataset/energia-precios-volumenes-eess---resolucion-110404), a partir del archivo `precios_eess_2025_en_adelante.accdb` y su tabla `public_vi_access_eess_2025_en_adelante`.

Selecciono registros del canal **Al público**, que describen ventas de estaciones a consumidores. El Gobierno publica estos datos; la fuente no acredita compras de las estaciones a distribuidores. Por eso, la relación entre mi mayorista ficticio y sus clientes forma parte de la simulación.

Mi muestra incluye tres establecimientos de cada provincia: Buenos Aires, Chaco, Córdoba, Corrientes, Misiones y Santa Fe. Conservo 1.013 filas originales para mantener la trazabilidad y utilizo 1.007, tras excluir seis correspondientes a otros canales. La selección es intencional y no representa todo el mercado argentino.

#### Supuestos del modelo

- Identifico cada cuenta cliente por establecimiento. Un mismo CUIT puede corresponder a más de una ubicación.
- Genero un pedido por cliente y mes. Represento el período con el primer día del mes, sin atribuirle una fecha real de entrega.
- Asigno como cantidad comprada simulada el volumen mensual vendido al público por ese establecimiento. No modelo variaciones de existencias.
- Conservo el precio promedio mensual minorista con impuestos como referencia. No aplico descuentos ni estimo márgenes mayoristas.
- Asigno el estado `Concretado` a todos los pedidos como supuesto del caso.

Los nombres, ubicaciones, productos, volúmenes y precios proceden de la fuente pública. Los pedidos y la relación comercial con el mayorista son simulados. Interpreto los importes como **ARS nominales de referencia**, sin atribuirles carácter de facturación mayorista real o rentabilidad. Los doce pedidos por cliente son una regla del modelo y no permiten medir fidelidad.

#### Unidades

Convierto los volúmenes de combustibles líquidos de m³ a litros multiplicando por 1.000 y conservo sus precios en ARS/L. Para GNC mantengo m³ y ARS/m³.

Analizo los volúmenes de líquidos y GNC por separado. Puedo sumar sus importes porque están expresados en ARS bajo el mismo criterio de valoración.

### 2.2. Preparación y carga

Organizo los datos en la base `capstone_project`, dentro del esquema `combustibles`. Utilizo PostgreSQL para almacenar y consultar la información, y pgAdmin para ejecutar las consultas e inspeccionar los resultados.

| Tabla | Función | Filas |
| --- | --- | ---: |
| operadores | Identidad original de cada establecimiento | 18 |
| clientes | Cuenta comercial vinculada a un establecimiento | 18 |
| productos | Combustibles, categorías y unidades | 7 |
| pedidos | Cabecera del pedido mensual de cada cliente | 216 |
| detalle_pedido | Producto, cantidad y precio de cada línea | 1.007 |
| fuente_ventas | Registros originales utilizados como referencia | 1.007 |
| detalle_pedido_entrada | Entrada con incidencias didácticas para la limpieza | 1.010 |

Relaciono cada cliente con su establecimiento mediante `clientes.id_operador`, una clave foránea única. Vinculo los pedidos con los clientes y cada detalle con su pedido, producto y registro fuente. Así puedo rastrear el origen de las cantidades y los precios.

```mermaid
erDiagram
    operadores ||--|| clientes : identifica
    operadores ||--o{ fuente_ventas : declara
    clientes ||--o{ pedidos : realiza
    pedidos ||--|{ detalle_pedido : contiene
    productos ||--o{ detalle_pedido : integra
    productos ||--o{ fuente_ventas : corresponde
    fuente_ventas ||--|| detalle_pedido : sustenta
```

Defino claves primarias y foráneas, restricciones de valores positivos y unicidad de cliente y mes. Uso `DATE` para fechas, `NUMERIC(18,3)` para cantidades y `NUMERIC(18,2)` para precios.

#### Comprobación de la carga

Para comprobar el número de registros de las siete tablas, utilizo esta consulta:

```sql
-- Comparo el tamaño de las tablas para detectar cargas incompletas o multiplicación de filas.
SELECT 'operadores' AS tabla, COUNT(*) AS filas FROM combustibles.operadores
UNION ALL SELECT 'productos', COUNT(*) FROM combustibles.productos
UNION ALL SELECT 'clientes', COUNT(*) FROM combustibles.clientes
UNION ALL SELECT 'pedidos', COUNT(*) FROM combustibles.pedidos
UNION ALL SELECT 'detalle_pedido', COUNT(*) FROM combustibles.detalle_pedido
UNION ALL SELECT 'fuente_ventas', COUNT(*) FROM combustibles.fuente_ventas
UNION ALL SELECT 'detalle_pedido_entrada', COUNT(*) FROM combustibles.detalle_pedido_entrada;
```

![Resultado de la consulta de conteos de las siete tablas](imagenes/conteos_tablas.png)

Obtengo los siete conteos previstos: 18 operadores, 7 productos, 18 clientes, 216 pedidos, 1.007 detalles, 1.007 registros fuente y 1.010 filas de entrada.

### 2.3. Limpieza y transformación

Introduzco ocho precios nulos y tres duplicados exactos exclusivamente en `detalle_pedido_entrada` para demostrar el tratamiento de estas incidencias. Mantengo intacta la fuente real y registro las alteraciones en `datos/incidencias_simuladas.csv`.

#### Tratamiento de duplicados y precios nulos

Utilizo `DISTINCT` para eliminar las copias idénticas y `COALESCE` para recuperar cada precio faltante desde su registro fuente:

```sql
-- DISTINCT elimina copias exactas sin confundirlas con ventas distintas.
-- Recupero el precio fuente porque es el asignado al pedido por diseño;
-- sustituirlo por cero o por otro promedio alteraría la valoración.
INSERT INTO combustibles.detalle_pedido
SELECT DISTINCT
    e.id_detalle, e.id_pedido, e.id_producto, e.id_fuente,
    e.cantidad,
    COALESCE(e.precio_unitario_ars, f.precio_promedio_con_impuestos_ars),
    e.origen
FROM combustibles.detalle_pedido_entrada e
JOIN combustibles.fuente_ventas f ON f.id_fuente = e.id_fuente;
```

Recupero el precio del mismo registro porque es la referencia asignada al pedido por diseño. Esto evita introducir un cero o un promedio ajeno a la operación. Incluyo esta transformación en la carga inicial.

Para comparar la entrada con el detalle limpio, ejecuto:

```sql
-- Comparo entrada y salida para comprobar que la limpieza trata las incidencias sin perder detalle válido.
SELECT
    'Entrada antes de limpiar' AS etapa,
    COUNT(*) AS filas,
    COUNT(*) - COUNT(DISTINCT id_detalle) AS filas_repetidas,
    COUNT(*) FILTER (WHERE precio_unitario_ars IS NULL) AS precios_nulos
FROM combustibles.detalle_pedido_entrada
UNION ALL
SELECT
    'Detalle limpio',
    COUNT(*),
    COUNT(*) - COUNT(DISTINCT id_detalle),
    COUNT(*) FILTER (WHERE precio_unitario_ars IS NULL)
FROM combustibles.detalle_pedido;
```

![Comparación de filas, repeticiones y precios nulos antes y después de la limpieza](imagenes/limpieza.png)


El resultado confirma que elimino las tres filas duplicadas y recupero los ocho precios faltantes, conservando los 1.007 detalles previstos.

#### Fechas y precisión numérica

Transformo los períodos de origen al tipo `DATE` mediante el primer día del mes. Como los períodos de la muestra están completos, no imputo fechas.

Conservo tres decimales en las cantidades y dos en los precios. Calculo el importe como cantidad × precio y redondeo para su presentación, evitando introducir diferencias en la conciliación.

#### Conciliación con la fuente

Comparo las cantidades y los importes de cada registro fuente con los de su detalle de pedido mediante la vista `v_conciliacion`. Compruebo las diferencias con esta consulta:

```sql
-- Contrasto cantidades e importes con la fuente para detectar pérdidas o alteraciones durante la transformación.
SELECT
    COUNT(*) AS registros_comprobados,
    COUNT(*) FILTER (
        WHERE diferencia_cantidad <> 0
           OR diferencia_importe_ars <> 0
    ) AS registros_con_diferencias
FROM combustibles.v_conciliacion;
```

![Resultado de conciliación: 1007 registros comprobados y cero con diferencias](imagenes/conciliacion.png)

Obtengo **1.007 registros comprobados y 0 con diferencias**. Esto confirma que la transformación conserva las cantidades y los importes de referencia de los registros incluidos.

Los totales del dataset son **93.213.130 litros de combustibles líquidos**, **8.638.800,20 m³ de GNC** y **141.717.574.607,79 ARS de referencia**. Mantengo separadas las dos unidades de volumen.

#### Validez y cobertura de las fechas

Compruebo que los pedidos pertenezcan a 2025 y utilicen el primer día del mes como representación del período.

```sql
-- Restrinjo las fechas a 2025 y al primer día porque representan meses contables, no entregas diarias.
SELECT COUNT(*) FILTER (WHERE fecha IS NULL) AS fechas_nulas,
       COUNT(*) FILTER (WHERE fecha < DATE '2025-01-01'
           OR fecha >= DATE '2026-01-01' OR EXTRACT(DAY FROM fecha) <> 1) AS fechas_invalidas,
       COUNT(DISTINCT fecha) AS meses
FROM combustibles.pedidos;
```

![Validez y cobertura de las fechas: resultado en pgAdmin](imagenes/fechas.png)

Obtengo 0 fechas nulas, 0 inválidas y 12 meses distintos.

#### Unicidad del pedido mensual

Agrupo los pedidos por cliente y mes para detectar grupos cuya cantidad de pedidos difiera de uno.

```sql
-- Busco repeticiones dentro de cada cliente y mes porque el modelo admite un único pedido mensual.
-- Este control solo ve meses presentes; lo complemento con el control de cobertura por cliente.
SELECT id_cliente, DATE_TRUNC('month', fecha) AS mes, COUNT(*) AS pedidos
FROM combustibles.pedidos
GROUP BY id_cliente, DATE_TRUNC('month', fecha)
HAVING COUNT(*) <> 1;
```

![Unicidad del pedido mensual: resultado en pgAdmin](imagenes/pedidos_por_mes.png)

La consulta no devuelve filas: cada combinación de cliente y mes presente tiene un solo pedido.

#### Cobertura anual por cliente

Cuento los pedidos de cada cliente mediante LEFT JOIN, incluyendo a quienes pudieran no tener pedidos.

```sql
-- Uso LEFT JOIN para incluir cuentas sin pedidos y comprobar la cobertura anual del modelo.
-- Cuento la clave del pedido, no COUNT(*), para que una cuenta sin pedidos compute cero.
SELECT c.id_cliente, COUNT(p.id_pedido) AS pedidos
FROM combustibles.clientes c LEFT JOIN combustibles.pedidos p USING(id_cliente)
GROUP BY c.id_cliente HAVING COUNT(p.id_pedido) <> 12;
```

![Cobertura anual por cliente: resultado en pgAdmin](imagenes/pedidos_por_cliente.png)

La consulta no devuelve filas: todos los clientes tienen doce pedidos. Junto con los controles de fechas y unicidad, esto confirma un pedido por mes de 2025 para cada cliente.

#### Trazabilidad de las relaciones

Relaciono detalles, pedidos, clientes y fuente para comprobar la correspondencia del establecimiento, período y producto.

```sql
-- Compruebo establecimiento, período y producto para evitar asociar una venta a un detalle ajeno.
-- Comparo también las filas unidas con el detalle para detectar pérdidas o multiplicación por el JOIN.
SELECT COUNT(*) AS filas_unidas,
       COUNT(*) FILTER (WHERE c.id_operador <> f.id_operador
           OR p.fecha <> f.periodo OR d.id_producto <> f.id_producto) AS errores_trazabilidad
FROM combustibles.detalle_pedido d
JOIN combustibles.pedidos p USING(id_pedido)
JOIN combustibles.clientes c USING(id_cliente)
JOIN combustibles.fuente_ventas f USING(id_fuente);
```

![Trazabilidad de las relaciones: resultado en pgAdmin](imagenes/trazabilidad.png)

Obtengo 1.007 filas unidas y 0 errores de trazabilidad. El JOIN conserva el número de detalles y las relaciones comprobadas coinciden con la fuente.

#### Tipos de datos

Consulto el catálogo de columnas para comprobar los tipos definidos y la precisión numérica.

```sql
-- Verifico DATE y NUMERIC para sostener agrupaciones temporales y cálculos decimales consistentes.
-- Limito la consulta al esquema del proyecto para no confundir columnas homónimas de otras bases lógicas.
SELECT table_name, column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_schema = 'combustibles'
  AND ((table_name = 'pedidos' AND column_name = 'fecha')
    OR (table_name = 'fuente_ventas' AND column_name = 'periodo')
    OR (table_name = 'detalle_pedido' AND column_name IN ('cantidad','precio_unitario_ars')))
ORDER BY table_name, column_name;
```

![Tipos de datos: resultado en pgAdmin](imagenes/tipos_datos.png)

Confirmo DATE en las fechas, NUMERIC(18,3) en la cantidad y NUMERIC(18,2) en el precio. Los valores NULL de precisión y escala en las fechas indican que esos atributos numéricos no corresponden al tipo DATE.

Conservo también los reportes técnicos de [Python Decimal](datos/validacion.json) y [PostgreSQL mediante PGlite](datos/validacion_final_postgresql.json) como comprobaciones complementarias.

### 2.4. Análisis y extracción de hallazgos

#### 2.4.1. Cinco clientes con mayor gasto de referencia

Identifico los establecimientos que acumulan el mayor importe de compra simulado durante 2025. Calculo el gasto de referencia como la suma de cantidad × precio y cuento los pedidos con `COUNT(DISTINCT id_pedido)` para evitar contar cada línea de producto como un pedido diferente. Considero los pedidos con estado `Concretado`.

```sql
-- Priorizo las cinco cuentas con mayor peso en el importe de referencia de la cartera.
-- Los precios minoristas permiten una valoración común de la simulación; no son ingresos mayoristas reales.
SELECT
    c.id_cliente,
    c.nombre,
    o.localidad,
    c.provincia,
    -- Evito inflar la frecuencia por las múltiples líneas de un mismo pedido.
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    ROUND(SUM(d.cantidad * d.precio_unitario_ars), 2) AS gasto_referencia_ars
FROM combustibles.clientes AS c
JOIN combustibles.operadores AS o ON o.id_operador = c.id_operador
JOIN combustibles.pedidos AS p ON p.id_cliente = c.id_cliente
JOIN combustibles.detalle_pedido AS d ON d.id_pedido = p.id_pedido
-- Delimito el análisis a ventas concretadas; hoy todas lo son por supuesto del modelo.
WHERE p.estado = 'Concretado'
-- Conservo cada establecimiento como cuenta; no consolido sucursales por nombre o CUIT.
GROUP BY c.id_cliente, c.nombre, o.localidad, c.provincia
-- Desempato por identificador para obtener cinco cuentas reproducibles.
ORDER BY SUM(d.cantidad * d.precio_unitario_ars) DESC, c.id_cliente
LIMIT 5;
```

![Cinco clientes con mayor gasto de referencia en 2025](imagenes/top_5_clientes.png)


Identifico a **SUCATA S.A.** como la cuenta de mayor importe de referencia, seguida por SANTA BARBARA SA. Los cinco establecimientos se ubican en Santa Fe y Córdoba: dos en la primera provincia y tres en la segunda. Este resultado describe las cuentas seleccionadas y no un ranking provincial del mercado.

Los cinco clientes tienen doce pedidos porque esa frecuencia está fijada en el modelo. Interpreto las diferencias de importe a partir de las cantidades y los precios de los productos adquiridos, sin atribuirlas a una mayor frecuencia ni a fidelidad.

Dentro de la simulación, utilizaría el ranking para priorizar el seguimiento comercial de estas cuentas y profundizar en su composición de compra. El importe por sí solo no permite identificar a los clientes más rentables: no dispongo de costos ni márgenes, y utilizo precios minoristas como referencia.

#### 2.4.2. Evolución mensual de las ventas simuladas

Agrupo los pedidos por mes y calculo el importe total de referencia. Cuento pedidos y clientes distintos para contextualizar cada período.

```sql
-- Comparo períodos mensuales porque la fuente y los pedidos tienen esa granularidad.
-- El importe es nominal: su variación combina precios, cantidades y composición de productos.
SELECT
    DATE_TRUNC('month', p.fecha)::date AS mes,
    -- El JOIN repite cabeceras; DISTINCT evita confundir líneas con pedidos o clientes.
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    COUNT(DISTINCT p.id_cliente) AS cantidad_clientes,
    ROUND(
        SUM(d.cantidad * d.precio_unitario_ars),
        2
    ) AS ventas_referencia_ars
FROM combustibles.pedidos AS p
JOIN combustibles.detalle_pedido AS d
    ON d.id_pedido = p.id_pedido
-- Delimito el análisis a ventas concretadas; hoy todas lo son por supuesto del modelo.
WHERE p.estado = 'Concretado'
GROUP BY DATE_TRUNC('month', p.fecha)::date
ORDER BY mes;
```

![Evolución mensual de las ventas simuladas en 2025](imagenes/ventas_mensuales.png)


Identifico **diciembre** como el mes de mayor importe, con **15.860.282.317,40 ARS**, y **febrero** como el menor, con **10.024.372.092,50 ARS**. La suma de los doce importes es **141.717.574.607,79 ARS**, coincidente con el total anual del dataset.

Observo una tendencia nominal ascendente, con descensos respecto del mes anterior en febrero, abril y noviembre. Diciembre supera a enero en **57,11 %**, calculado como `(importe_diciembre / importe_enero - 1) * 100`.

En cada mes cuento 18 pedidos y 18 clientes, de acuerdo con la frecuencia establecida en el modelo. Por eso, las variaciones del importe no se explican por incorporar más cuentas o registrar más pedidos. La consulta combina cantidades, precios y composición por productos; no permite separar sus efectos ni demostrar crecimiento real del volumen.

Utilizaría esta evolución para identificar períodos que requieren un análisis adicional de cantidades y precios. Con un solo año de datos no concluyo que el pico de diciembre sea un patrón estacional.

#### 2.4.3. Tres combustibles líquidos menos vendidos

Comparo el volumen acumulado de los productos medidos en litros y selecciono los tres de menor cantidad. Excluyo GNC de este ranking porque su volumen está expresado en m³; mantengo esa unidad separada.

```sql
-- Identifico productos de menor volumen para orientar una revisión de surtido y cobertura.
-- El volumen por sí solo no permite decidir su rentabilidad ni recomendar su retiro.
SELECT
    pr.id_producto,
    pr.nombre_original AS producto,
    pr.categoria,
    SUM(d.cantidad) AS litros_vendidos
FROM combustibles.productos AS pr
JOIN combustibles.detalle_pedido AS d
    ON d.id_producto = pr.id_producto
JOIN combustibles.pedidos AS p
    ON p.id_pedido = d.id_pedido
-- Delimito el análisis a ventas concretadas; hoy todas lo son por supuesto del modelo.
WHERE p.estado = 'Concretado'
  -- Excluyo GNC para no comparar litros con m3 en un mismo ranking de volumen.
  AND pr.unidad_venta = 'L'
GROUP BY
    pr.id_producto,
    pr.nombre_original,
    pr.categoria
ORDER BY litros_vendidos ASC, pr.id_producto
LIMIT 3;
```

![Tres combustibles líquidos con menor volumen vendido](imagenes/productos_menos_vendidos.png)


Identifico al queroseno como el producto de menor volumen de la cartera, seguido por la nafta común y la nafta premium. Comparo litros acumulados durante 2025, por lo que este orden no representa un ranking de importes ni de rentabilidad.

Utilizaría este resultado para revisar la cobertura comercial de estos productos: cuántos establecimientos los compran y durante cuántos meses. Un volumen bajo puede estar relacionado con su presencia en menos establecimientos o períodos; esta consulta no demuestra por sí sola una menor demanda entre quienes los ofrecen. No recomendaría retirar un producto sin conocer esa cobertura, sus costos y su función en la oferta.

#### 2.4.4. Ranking de pedidos por categoría

Calculo el importe de cada pedido dentro de cada categoría y utilizo `RANK()` para ordenar los pedidos de mayor a menor importe. Muestro las posiciones uno a tres por categoría para comparar las operaciones de mayor valor.

La unidad de análisis es **pedido y categoría**: si un pedido incluye nafta y gasoil, aparece en ambos rankings con el importe correspondiente a cada categoría. Comparo importes en ARS, por lo que incluyo GNC sin sumar sus m³ a los litros.

```sql
-- Comparo operaciones dentro de cada categoría para identificar pedidos relevantes en cada rubro.
-- Agrego primero las líneas por pedido y categoría para no clasificar productos individuales.
WITH importes_por_categoria AS (
    SELECT
        pr.categoria,
        p.id_pedido,
        p.fecha,
        c.id_cliente,
        c.nombre AS cliente,
        SUM(d.cantidad * d.precio_unitario_ars) AS importe_categoria
    FROM combustibles.pedidos AS p
    JOIN combustibles.clientes AS c
        ON c.id_cliente = p.id_cliente
    JOIN combustibles.detalle_pedido AS d
        ON d.id_pedido = p.id_pedido
    JOIN combustibles.productos AS pr
        ON pr.id_producto = d.id_producto
    -- Delimito el análisis a ventas concretadas; hoy todas lo son por supuesto del modelo.
    WHERE p.estado = 'Concretado'
    GROUP BY pr.categoria, p.id_pedido, p.fecha, c.id_cliente, c.nombre
),
ranking AS (
    SELECT
        *,
        -- Conservo empates: importes iguales merecen la misma posición comercial.
        RANK() OVER (
            -- Cada categoría tiene su propia clasificación, sin competir con otros rubros.
            PARTITION BY categoria
            ORDER BY importe_categoria DESC
        ) AS posicion
    FROM importes_por_categoria
)
SELECT
    categoria,
    posicion,
    id_pedido,
    fecha,
    id_cliente,
    cliente,
    -- Redondeo solo la presentación para no crear empates artificiales al clasificar.
    ROUND(importe_categoria, 2) AS importe_referencia_ars
FROM ranking
-- Incluyo las tres primeras posiciones; los empates pueden ampliar el número de filas.
WHERE posicion <= 3
ORDER BY categoria, posicion, id_pedido;
```

Clasifico por el importe sin redondear y redondeo únicamente para mostrarlo. Los empates comparten posición y generan saltos en la siguiente; el filtro puede devolver más de tres filas por categoría si hay empates. El identificador del pedido ordena la presentación sin romper esos empates.

![Ranking de pedidos por categoría: posiciones uno a tres](imagenes/ranking_pedidos_categoria.png)

Obtengo tres posiciones por cada una de las cuatro categorías, sin empates en las posiciones mostradas. Identifico los pedidos que encabezan cada ranking:

- **Gasoil:** pedido V000139, de SUCATA S.A., correspondiente a julio, con **1.763.802.594,40 ARS**.
- **GNC:** pedido V000067, de D.G.B. S.R.L., correspondiente a julio, con **120.939.940,50 ARS**.
- **Nafta:** pedido V000012, de ESTACION EL SURTIDOR S.R.L., correspondiente a diciembre, con **999.287.344,80 ARS**.
- **Queroseno:** pedido V000158, de LIBEROIL SRL, correspondiente a febrero, con **107.067.890,00 ARS**.

Observo que D.G.B. S.R.L. ocupa las tres primeras posiciones de GNC y ESTACION EL SURTIDOR S.R.L. las tres de nafta, mediante pedidos de meses diferentes. Esto destaca operaciones de estas cuentas dentro de cada categoría, pero no mide su participación en el importe anual total.

Utilizaría el ranking para seleccionar pedidos cuyo volumen y composición conviene revisar con mayor detalle. Cada importe corresponde únicamente a la categoría indicada; no representa necesariamente el importe completo del pedido ni permite inferir rentabilidad.

#### 2.4.5. Concentración del importe en los cinco principales clientes

Calculo qué porcentaje del importe total de la cartera corresponde a los cinco clientes de mayor gasto de referencia. Selecciono exactamente cinco cuentas con el mismo desempate por identificador utilizado en el top 5. La métrica es `importe_top_5 / importe_total * 100`.

```sql
-- Mido cuánto depende el importe de referencia de las cinco cuentas principales.
-- Mantengo el mismo criterio de selección del top 5 para que ambos análisis sean comparables.
WITH gasto_por_cliente AS (
    SELECT
        p.id_cliente,
        SUM(d.cantidad * d.precio_unitario_ars) AS importe
    FROM combustibles.pedidos AS p
    JOIN combustibles.detalle_pedido AS d
        ON d.id_pedido = p.id_pedido
    -- Delimito el análisis a ventas concretadas; hoy todas lo son por supuesto del modelo.
    WHERE p.estado = 'Concretado'
    GROUP BY p.id_cliente
),
clientes_ordenados AS (
    SELECT
        id_cliente,
        importe,
        -- Necesito exactamente cinco cuentas, incluso si hay importes empatados.
        ROW_NUMBER() OVER (
            ORDER BY importe DESC, id_cliente
        ) AS posicion
    FROM gasto_por_cliente
)
-- FILTER limita solo el numerador: el denominador debe conservar toda la cartera.
SELECT
    ROUND(SUM(importe) FILTER (WHERE posicion <= 5), 2)
        AS importe_top_5_ars,
    ROUND(SUM(importe), 2) AS importe_total_ars,
    ROUND(
        100.0 * SUM(importe) FILTER (WHERE posicion <= 5)
        -- Un total cero no define una participación; NULLIF evita dividir por cero.
        / NULLIF(SUM(importe), 0),
        2
    ) AS participacion_top_5_pct
FROM clientes_ordenados;
```

Uso `ROW_NUMBER()` para numerar las cuentas y `FILTER` para sumar las cinco primeras sin excluir a las demás del total. `NULLIF` evita dividir por cero. Mantengo los importes sin redondear durante el cálculo del porcentaje y redondeo la presentación.

![Participación de los cinco principales clientes en el importe total](imagenes/concentracion_top_5.png)

Obtengo un importe acumulado de **78.173.422.323,82 ARS** para los cinco principales clientes, sobre **141.717.574.607,79 ARS** de toda la cartera. Su participación es **55,16 %**.

Cinco de los dieciocho establecimientos reúnen más de la mitad del importe de referencia; los trece restantes representan el 44,84 %. Esto muestra una concentración comercial en esas cuentas dentro de la simulación, sin establecer por sí solo un nivel de riesgo aceptable ni medir rentabilidad.

Utilizaría este indicador para priorizar el seguimiento de las cuentas principales y evaluar oportunidades de diversificación de la cartera. La métrica describe importes simulados a precios de referencia; no informa sobre incumplimientos, contratos ni probabilidad de pérdida de clientes.

#### 2.4.6. Precio ponderado por producto y mes

Calculo el precio medio de referencia dando mayor peso a los registros con mayor volumen. Utilizo `SUM(cantidad * precio) / SUM(cantidad)` para cada producto y mes, en lugar de un promedio simple que asignaría el mismo peso a volúmenes diferentes.

```sql
-- Pondero por volumen para que una venta pequeña no pese igual que una grande en el precio medio.
-- Comparo cada producto consigo mismo por mes, conservando su unidad de precio.
SELECT
    DATE_TRUNC('month', p.fecha)::date AS mes,
    pr.id_producto,
    pr.nombre_original AS producto,
    pr.unidad_precio,
    -- La cobertura ayuda a detectar cambios de composición entre meses.
    COUNT(DISTINCT p.id_cliente) AS cantidad_clientes,
    SUM(d.cantidad) AS volumen_total,
    ROUND(
        SUM(d.cantidad * d.precio_unitario_ars)
        -- Sin volumen no hay precio ponderado definido; evito una división por cero.
        / NULLIF(SUM(d.cantidad), 0),
        2
    ) AS precio_ponderado_ars
FROM combustibles.pedidos AS p
JOIN combustibles.detalle_pedido AS d
    ON d.id_pedido = p.id_pedido
JOIN combustibles.productos AS pr
    ON pr.id_producto = d.id_producto
-- Delimito el análisis a ventas concretadas; hoy todas lo son por supuesto del modelo.
WHERE p.estado = 'Concretado'
-- No completo meses sin registros: su ausencia no equivale a un precio cero.
GROUP BY
    DATE_TRUNC('month', p.fecha)::date,
    pr.id_producto,
    pr.nombre_original,
    pr.unidad_precio
ORDER BY pr.id_producto, mes;
```

Expreso los precios de líquidos en ARS/L y los de GNC en ARS/m³. La columna `volumen_total` conserva la unidad correspondiente: litros para líquidos y m³ para GNC. Cuento los clientes participantes para contextualizar posibles cambios en la composición de cada grupo.

Conservo el [resultado completo de la consulta en CSV](resultados/precios_ponderados_mensuales.csv), con 83 combinaciones de producto y mes. Compruebo que los volúmenes, el número de clientes y los precios ponderados coinciden con los datos de pedidos y detalles.

Los seis productos restantes aparecen en los doce meses; la nafta común (P005) aparece en once. No encuentro registros de este producto en octubre dentro de la muestra, por lo que no asigno un precio cero ni completo el período con una estimación.

Al comparar enero con diciembre, observo aumentos nominales del precio ponderado en los siete productos. Por ejemplo, Gas Oil Grado 2 pasa de **1.234,06 a 1.742,90 ARS/L** (+41,23 %), nafta súper de **1.213,22 a 1.657,09 ARS/L** (+36,59 %) y GNC de **635,32 a 705,99 ARS/m³** (+11,12 %). Calculo estas variaciones sobre los precios publicados en el resultado, redondeados a dos decimales.

No observo un incremento continuo en todos los meses. Kerosene pasa de 1.588,74 ARS/L en noviembre a 1.116,85 ARS/L en diciembre, mientras su volumen pasa de 9.350 a 93.030 litros. Esta combinación requiere considerar el peso de cada establecimiento antes de atribuir la caída a un cambio general de precios.

La cobertura también varía: GNC incluye entre siete y nueve clientes por mes y nafta común entre uno y cinco en los meses con registros. En septiembre, noviembre y diciembre, el precio ponderado de nafta común representa a un único cliente de la muestra.

Utilizaría esta métrica para seguir los precios de referencia por producto y contextualizar la evolución de los importes. La interpreto como un precio ponderado de la muestra, no como un precio nacional ni un índice puro de inflación: puede cambiar tanto por los precios declarados como por el peso relativo de cada establecimiento.




### 2.5. Comunicación de hallazgos

Presento cada pregunta del apartado 2.4 con su consulta SQL, evidencia del resultado e interpretación de negocio. Explico qué mide el indicador, qué decisión podría orientar y qué información falta para sostener una conclusión más amplia. Conservo los precios ponderados completos en CSV para que puedan consultarse los 83 resultados.

Distingo hechos observados, supuestos y propuestas: la concentración del 55,16 % es un resultado del cálculo; el seguimiento de las cuentas principales es una posible acción. No atribuyo causalidad a una variación de importes ni equiparo ventas de referencia con rentabilidad. Reúno las conclusiones generales en el [apartado 6](#6-conclusiones-y-próximos-pasos).

## 3. Aplicación al contexto de negocio

Aplico el enfoque de análisis comercial a la distribución simulada de combustibles: identifico cuentas relevantes, comparo períodos y productos y selecciono pedidos para revisión. Utilizo estos resultados para orientar preguntas sobre concentración de cartera y cobertura del surtido.

Delimito el alcance a datos relacionales y períodos mensuales. No desarrollo recomendaciones de compra conjunta, análisis geoespacial ni explotación de JSON: esas líneas requerirían preguntas y datos adicionales. La aplicación de este proyecto se concentra en los seis análisis del apartado 2.4.

## 4. Controles para evitar errores de análisis

### 4.1. Multiplicación de filas en los JOIN

Verifico las relaciones mediante claves y comparo el número de detalles con las filas del JOIN. Documento 1.007 filas unidas y cero discrepancias de establecimiento, período y producto en [Trazabilidad de las relaciones](#trazabilidad-de-las-relaciones). En los indicadores de frecuencia utilizo `COUNT(DISTINCT ...)` para no contar varias veces un pedido con múltiples líneas.

### 4.2. Tratamiento de valores nulos

Justifico la recuperación de precios desde su registro fuente y la eliminación de copias exactas en [Tratamiento de duplicados y precios nulos](#tratamiento-de-duplicados-y-precios-nulos). No sustituyo valores desconocidos por cero. En las divisiones utilizo `NULLIF` para que un denominador cero produzca un resultado no definido, y no invento precios para meses sin registros.

### 4.3. Criterio de índices

Mantengo las restricciones de clave primaria y unicidad del modelo. No agrego índices mediante `CREATE INDEX` sin una necesidad de rendimiento medida. Si ampliara el dataset, evaluaría los planes de ejecución y los tiempos de las consultas antes de decidir índices adicionales; no presento una optimización de rendimiento como resultado de este trabajo.

### 4.4. Comentarios que justifican decisiones

Incluyo comentarios `--` junto a las decisiones relevantes de los scripts: por qué comparo solo litros en el ranking de volumen, evito duplicar pedidos, conservo empates con `RANK()`, selecciono exactamente cinco cuentas con `ROW_NUMBER()` y pondero precios por cantidad. Mantengo esas explicaciones en las consultas del apartado 2.4 y separo la justificación técnica de la interpretación del resultado.

## 5. Glosario aplicado al proyecto

Utilizo estos conceptos en la preparación, limpieza y análisis de la base. Reúno sus definiciones y aplicaciones para facilitar la lectura del modelo y de las consultas.

| Concepto | Significado | Aplicación en el proyecto |
| --- | --- | --- |
| **Schema (esquema)** | Espacio de nombres que agrupa tablas, vistas y otros objetos dentro de una base de datos. | Organizo los objetos en `combustibles`, dentro de la base `capstone_project`. Uso nombres como `combustibles.pedidos` para identificar la tabla y su esquema. |
| **Query (consulta)** | Sentencia SQL con la que solicito o proceso información de la base. | Respondo seis preguntas de negocio mediante las consultas de [analisis.sql](analisis.sql), acompañadas de resultados e interpretación en el [apartado 2.4](#24-análisis-y-extracción-de-hallazgos). |
| **CTE (Common Table Expression)** | Resultado con nombre definido mediante `WITH`, cuyo alcance es la sentencia que lo utiliza. No crea una tabla temporal independiente. | En el ranking separo el cálculo en `importes_por_categoria` y `ranking`. En la concentración utilizo `gasto_por_cliente` y `clientes_ordenados`. Esta separación permite revisar cada etapa del cálculo. |
| **ER Diagram (diagrama entidad-relación)** | Representación de las entidades y sus relaciones, que ayuda a comprender las claves y cardinalidades del modelo. | Presento el diagrama en el [apartado 2.2](#22-preparación-y-carga): relaciono operadores, clientes, pedidos, productos, detalles y registros fuente. |

Aplico el esquema para organizar los objetos, las consultas para responder preguntas y las CTE para descomponer cálculos complejos. Con el diagrama hago visible cómo conecto los datos y cómo puedo rastrear un detalle de pedido hasta su registro fuente.

## 6. Conclusiones y próximos pasos

Identifico una cartera cuyo importe de referencia se concentra en pocas cuentas: los cinco principales clientes reúnen el **55,16 %** del total anual, y SUCATA S.A. encabeza el ranking. Priorizaría el seguimiento de estas cuentas y analizaría oportunidades para diversificar la cartera, sin equiparar su importe con rentabilidad.

Observo un importe mensual de diciembre **57,11 % superior al de enero**, en términos nominales. Como el modelo fija dieciocho clientes y dieciocho pedidos cada mes, no atribuyo esa variación a una incorporación de cuentas ni a una mayor frecuencia de pedidos. Considero conjuntamente precios, volúmenes y composición de productos; el análisis ponderado muestra que los siete productos terminan el año con precios de referencia superiores a los de enero, pero no cuantifica por separado el aporte de cada factor al importe total.

Identifico kerosene, nafta común y nafta premium como los líquidos de menor volumen acumulado. Revisaría su cobertura comercial y los volúmenes por establecimiento antes de tomar decisiones de surtido: vender menos litros no demuestra un margen menor. Complemento esa lectura con el ranking de pedidos por categoría, que permite seleccionar operaciones para un análisis más detallado.

Concluyo que el modelo permite describir concentración, composición y evolución de una cartera simulada mediante consultas reproducibles. Para convertir estos hallazgos en decisiones comerciales reales, necesitaría precios de venta mayoristas, costos, inventarios y condiciones de los clientes.

### 6.1. Límites de interpretación

Delimito las conclusiones a los establecimientos seleccionados y al período 2025. Considero el efecto conjunto de cantidades, precios y composición por productos al interpretar los importes.

No extrapolo la muestra al país ni interpreto una variación nominal como crecimiento real ajustado por inflación. Tampoco calculo rentabilidad, porque no dispongo de costos de compra del mayorista.

### 6.2. Próximos pasos

Para ampliar el análisis, incorporaría costos y precios mayoristas reales para evaluar márgenes, e inventarios para contrastar el supuesto que equipara compras con ventas al público. También descompondría la variación del importe entre precios, volúmenes y composición, y ampliaría el período observado para estudiar patrones que un único año no permite establecer.

Puedo profundizar en la descomposición de precios, volúmenes y composición con los datos actuales. Para evaluar márgenes reales, contrastar inventarios o estudiar más años necesito información adicional. Estas ampliaciones no forman parte de los resultados obtenidos en este proyecto.

### 6.3. Verificación del entregable

Compruebo los cinco criterios del cierre de la actividad mediante los archivos y evidencias del proyecto:

| Criterio | Evidencia |
| --- | --- |
| Contexto y hallazgos en README | Defino el problema en 2.1, interpreto las seis consultas en 2.4 y sintetizo las conclusiones en 6. |
| JOIN entre al menos dos tablas | Relaciono pedidos y detalles en todos los análisis, incorporando clientes, operadores o productos según la pregunta. |
| Agregación y función avanzada | Utilizo `GROUP BY` y `SUM`; aplico `RANK()` en 2.4.4 y `ROW_NUMBER()` en 2.4.5. |
| Scripts ejecutables | Ejecuto la estructura, los ocho controles y las seis consultas de análisis en una base aislada con PostgreSQL 18.3 mediante PGlite 0.5.8. |
| Limpieza antes del análisis | Documento en 2.3 la eliminación de tres duplicados y la recuperación de ocho precios, con conciliación de 1.007 registros sin diferencias. |

Conservo el [reporte de verificación técnica](datos/validacion_final_postgresql.json), que identifica los archivos mediante SHA-256. También compruebo los quince bloques SQL del README. Distingo esta prueba aislada de las capturas de pgAdmin y del CSV de precios ponderados, que documentan la ejecución en la base del proyecto.

## Archivos y reproducción

| Archivo | Contenido |
| --- | --- |
| [estructura.sql](estructura.sql) | Tablas, inserciones, limpieza y vistas |
| [analisis.sql](analisis.sql) | Consultas de negocio comentadas |
| [validaciones.sql](validaciones.sql) | Consultas de control de carga, limpieza, conciliación y relaciones |
| [datos/validacion_final_postgresql.json](datos/validacion_final_postgresql.json) | Evidencia técnica de ejecución de la estructura, controles y seis análisis |
| [datos/README.md](datos/README.md) | Fuente, selección y metodología del dataset |
| [datos/diccionario.md](datos/diccionario.md) | Definición de campos, relaciones y unidades |
| [datos/generar_dataset.py](datos/generar_dataset.py) | Generación determinista de los datos derivados |
| [datos/sha256_csv.json](datos/sha256_csv.json) | Huellas de integridad de los CSV |
| [resultados/precios_ponderados_mensuales.csv](resultados/precios_ponderados_mensuales.csv) | Resultado completo del precio ponderado por producto y mes |
| [imagenes/](imagenes/) | Resultados de las consultas en pgAdmin |

Para reproducir la base, utilizo una base vacía llamada `capstone_project` y ejecuto completo `estructura.sql`. El archivo contiene las inserciones y la limpieza en una transacción, por lo que no requiere importar los CSV por separado. Desde la raíz del repositorio, puedo cargarlo con:

```bash
psql -d capstone_project -v ON_ERROR_STOP=1 -f estructura.sql
```

Después de la carga, ejecuto los controles y las seis consultas de negocio:

```bash
psql -d capstone_project -v ON_ERROR_STOP=1 -f validaciones.sql
psql -d capstone_project -v ON_ERROR_STOP=1 -f analisis.sql
```

En pgAdmin utilizo Query Tool conectado a `capstone_project`: ejecuto `estructura.sql` completo sobre la base vacía y luego los bloques de `validaciones.sql` y `analisis.sql` por separado para inspeccionar cada resultado. La limpieza ya está incluida en la carga; los bloques del README muestran el procedimiento y no requieren repetir las inserciones sobre una base cargada.

Para regenerar los datos derivados, utilizo Python 3.10 o superior, sin dependencias externas:

```bash
python3 datos/generar_dataset.py
```

El generador utiliza la muestra congelada `datos/fuente_original.csv` y reemplaza los derivados y `estructura.sql`. No descarga novedades ni repite la selección desde Access. La validación PostgreSQL se realiza por separado.

Mantengo la atribución de la fuente pública y no asigno una licencia nueva a los datos de terceros.
