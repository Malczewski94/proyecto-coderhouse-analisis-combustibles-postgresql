-- Comparo el tamaño de las tablas para detectar cargas incompletas o multiplicación de filas.
SELECT 'operadores' AS tabla, COUNT(*) AS filas FROM combustibles.operadores
UNION ALL SELECT 'productos', COUNT(*) FROM combustibles.productos
UNION ALL SELECT 'clientes', COUNT(*) FROM combustibles.clientes
UNION ALL SELECT 'pedidos', COUNT(*) FROM combustibles.pedidos
UNION ALL SELECT 'detalle_pedido', COUNT(*) FROM combustibles.detalle_pedido
UNION ALL SELECT 'fuente_ventas', COUNT(*) FROM combustibles.fuente_ventas
UNION ALL SELECT 'detalle_pedido_entrada', COUNT(*) FROM combustibles.detalle_pedido_entrada;

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

-- Contrasto cantidades e importes con la fuente para detectar pérdidas o alteraciones durante la transformación.
SELECT
    COUNT(*) AS registros_comprobados,
    COUNT(*) FILTER (
        WHERE diferencia_cantidad <> 0
           OR diferencia_importe_ars <> 0
    ) AS registros_con_diferencias
FROM combustibles.v_conciliacion;

-- Restrinjo las fechas a 2025 y al primer día porque representan meses contables, no entregas diarias.
SELECT COUNT(*) FILTER (WHERE fecha IS NULL) AS fechas_nulas,
       COUNT(*) FILTER (WHERE fecha < DATE '2025-01-01'
           OR fecha >= DATE '2026-01-01' OR EXTRACT(DAY FROM fecha) <> 1) AS fechas_invalidas,
       COUNT(DISTINCT fecha) AS meses
FROM combustibles.pedidos;

-- Busco repeticiones dentro de cada cliente y mes porque el modelo admite un único pedido mensual.
-- Este control solo ve meses presentes; lo complemento con el control de cobertura por cliente.
SELECT id_cliente, DATE_TRUNC('month', fecha) AS mes, COUNT(*) AS pedidos
FROM combustibles.pedidos
GROUP BY id_cliente, DATE_TRUNC('month', fecha)
HAVING COUNT(*) <> 1;

-- Uso LEFT JOIN para incluir cuentas sin pedidos y comprobar la cobertura anual del modelo.
-- Cuento la clave del pedido, no COUNT(*), para que una cuenta sin pedidos compute cero.
SELECT c.id_cliente, COUNT(p.id_pedido) AS pedidos
FROM combustibles.clientes c LEFT JOIN combustibles.pedidos p USING(id_cliente)
GROUP BY c.id_cliente HAVING COUNT(p.id_pedido) <> 12;

-- Compruebo establecimiento, período y producto para evitar asociar una venta a un detalle ajeno.
-- Comparo también las filas unidas con el detalle para detectar pérdidas o multiplicación por el JOIN.
SELECT COUNT(*) AS filas_unidas,
       COUNT(*) FILTER (WHERE c.id_operador <> f.id_operador
           OR p.fecha <> f.periodo OR d.id_producto <> f.id_producto) AS errores_trazabilidad
FROM combustibles.detalle_pedido d
JOIN combustibles.pedidos p USING(id_pedido)
JOIN combustibles.clientes c USING(id_cliente)
JOIN combustibles.fuente_ventas f USING(id_fuente);

-- Verifico DATE y NUMERIC para sostener agrupaciones temporales y cálculos decimales consistentes.
-- Limito la consulta al esquema del proyecto para no confundir columnas homónimas de otras bases lógicas.
SELECT table_name, column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_schema = 'combustibles'
  AND ((table_name = 'pedidos' AND column_name = 'fecha')
    OR (table_name = 'fuente_ventas' AND column_name = 'periodo')
    OR (table_name = 'detalle_pedido' AND column_name IN ('cantidad','precio_unitario_ars')))
ORDER BY table_name, column_name;
