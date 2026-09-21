-- Modelo V2: mayorista ficticio; establecimientos reales como clientes.
-- Primera pregunta: ¿qué cinco establecimientos acumulan mayor importe de referencia?
-- Precio minorista mensual con impuestos: no representa gasto mayorista observado.
-- COUNT DISTINCT evita contar las líneas de producto como pedidos separados.
-- Cada cliente tiene 12 pedidos por diseño: esa frecuencia no demuestra fidelidad.
-- Se incluyen solo pedidos concretados, estado supuesto para esta simulación.
-- Pendiente: ejecución/captura V2 en pgAdmin e interpretación conjunta.
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
