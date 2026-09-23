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
