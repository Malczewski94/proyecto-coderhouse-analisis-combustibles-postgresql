-- Identifica los cinco establecimientos con mayor importe de referencia acumulado.
-- Agrupa por cliente y ubicación, suma cantidad por precio y ordena de mayor a menor.
-- COUNT DISTINCT cuenta cada pedido una sola vez aunque incluya varios productos.
-- Filtra pedidos concretados y utiliza precios minoristas mensuales con impuestos.
-- La frecuencia mensual es un supuesto del modelo; no mide fidelidad comercial.
SELECT
    c.id_cliente,
    c.nombre,
    o.localidad,
    c.provincia,
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    ROUND(SUM(d.cantidad * d.precio_unitario_ars), 2) AS gasto_referencia_ars
FROM combustibles.clientes AS c
JOIN combustibles.operadores AS o ON o.id_operador = c.id_operador
JOIN combustibles.pedidos AS p ON p.id_cliente = c.id_cliente
JOIN combustibles.detalle_pedido AS d ON d.id_pedido = p.id_pedido
WHERE p.estado = 'Concretado'
GROUP BY c.id_cliente, c.nombre, o.localidad, c.provincia
ORDER BY SUM(d.cantidad * d.precio_unitario_ars) DESC, c.id_cliente
LIMIT 5;

-- Agrupa los pedidos concretados por mes y calcula su importe de referencia.
-- Cuenta pedidos y clientes sin repetirlos por cada línea de producto.
SELECT
    DATE_TRUNC('month', p.fecha)::date AS mes,
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    COUNT(DISTINCT p.id_cliente) AS cantidad_clientes,
    ROUND(
        SUM(d.cantidad * d.precio_unitario_ars),
        2
    ) AS ventas_referencia_ars
FROM combustibles.pedidos AS p
JOIN combustibles.detalle_pedido AS d
    ON d.id_pedido = p.id_pedido
WHERE p.estado = 'Concretado'
GROUP BY DATE_TRUNC('month', p.fecha)::date
ORDER BY mes;
