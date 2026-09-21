-- Paso 2: conteos tras ejecutar estructura.sql.
SELECT 'operadores' AS tabla, COUNT(*) AS filas FROM combustibles.operadores
UNION ALL SELECT 'productos', COUNT(*) FROM combustibles.productos
UNION ALL SELECT 'clientes', COUNT(*) FROM combustibles.clientes
UNION ALL SELECT 'pedidos', COUNT(*) FROM combustibles.pedidos
UNION ALL SELECT 'detalle_pedido', COUNT(*) FROM combustibles.detalle_pedido
UNION ALL SELECT 'fuente_ventas', COUNT(*) FROM combustibles.fuente_ventas
UNION ALL SELECT 'detalle_pedido_entrada', COUNT(*) FROM combustibles.detalle_pedido_entrada;

-- Paso 3: antes y después de limpiar.
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

-- Resultado esperado: 1007 registros comprobados, 0 con diferencias.
SELECT
    COUNT(*) AS registros_comprobados,
    COUNT(*) FILTER (
        WHERE diferencia_cantidad <> 0
           OR diferencia_importe_ars <> 0
    ) AS registros_con_diferencias
FROM combustibles.v_conciliacion;

-- V2: fechas completas, dentro de 2025 y representadas por el primer día del mes.
-- No se imputan fechas: el período de origen está completo y define el pedido mensual.
SELECT COUNT(*) FILTER (WHERE fecha IS NULL) AS fechas_nulas,
       COUNT(*) FILTER (WHERE fecha < DATE '2025-01-01'
           OR fecha >= DATE '2026-01-01' OR EXTRACT(DAY FROM fecha) <> 1) AS fechas_invalidas,
       COUNT(DISTINCT fecha) AS meses
FROM combustibles.pedidos;

-- Debe devolver cero filas: un pedido por cliente y mes.
SELECT id_cliente, DATE_TRUNC('month', fecha) AS mes, COUNT(*) AS pedidos
FROM combustibles.pedidos
GROUP BY id_cliente, DATE_TRUNC('month', fecha)
HAVING COUNT(*) <> 1;

-- Debe devolver cero filas: doce meses para cada uno de los 18 clientes.
SELECT c.id_cliente, COUNT(p.id_pedido) AS pedidos
FROM combustibles.clientes c LEFT JOIN combustibles.pedidos p USING(id_cliente)
GROUP BY c.id_cliente HAVING COUNT(p.id_pedido) <> 12;

-- Debe devolver 1007 filas unidas y 0 errores de trazabilidad.
-- Comprueba que el JOIN conserva el detalle y vincula el establecimiento correcto.
SELECT COUNT(*) AS filas_unidas,
       COUNT(*) FILTER (WHERE c.id_operador <> f.id_operador
           OR p.fecha <> f.periodo OR d.id_producto <> f.id_producto) AS errores_trazabilidad
FROM combustibles.detalle_pedido d
JOIN combustibles.pedidos p USING(id_pedido)
JOIN combustibles.clientes c USING(id_cliente)
JOIN combustibles.fuente_ventas f USING(id_fuente);

-- Revisar DATE y NUMERIC en las columnas relevantes.
SELECT table_name, column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_schema = 'combustibles'
  AND ((table_name = 'pedidos' AND column_name = 'fecha')
    OR (table_name = 'fuente_ventas' AND column_name = 'periodo')
    OR (table_name = 'detalle_pedido' AND column_name IN ('cantidad','precio_unitario_ars')))
ORDER BY table_name, column_name;
