-- Paso 4 en desarrollo: primera consulta propuesta.
-- Pendiente revisar el resultado con el autor y documentar su interpretación.
-- Importes de referencia en ARS nominales; clientes y pedidos ficticios.
SELECT
    c.id_cliente,
    c.nombre,
    c.segmento,
    COUNT(DISTINCT p.id_pedido) AS cantidad_pedidos,
    ROUND(SUM(d.cantidad * d.precio_unitario_ars), 2) AS gasto_total_ars
FROM combustibles.clientes AS c
JOIN combustibles.pedidos AS p ON p.id_cliente = c.id_cliente
JOIN combustibles.detalle_pedido AS d ON d.id_pedido = p.id_pedido
WHERE p.estado = 'Concretado'
GROUP BY c.id_cliente, c.nombre, c.segmento
ORDER BY gasto_total_ars DESC, c.id_cliente
LIMIT 5;
