# Diccionario del dataset

Los identificadores prefijados (`O`, `P`, `C`, `V`, `D`, `F`) son internos y no reemplazan los identificadores de la fuente. `origen` describe procedencia, no validez de un registro.

## Operadores

Una fila representa un establecimiento de referencia. La combinación inscripción, CUIT, provincia, localidad y dirección distingue establecimientos. Un operador empresarial puede tener más de un establecimiento.

| Campo | Tipo PostgreSQL | Significado |
| --- | --- | --- |
| id_operador | TEXT, PK | Identificador interno del establecimiento |
| nro_inscripcion | TEXT | Número de inscripción real, preservado como identificador |
| cuit | TEXT | Identificación tributaria real del operador, con guiones |
| nombre_operador | TEXT | Nombre original del declarante |
| bandera | TEXT | Marca declarada, sin inferir franquicia ni propiedad |
| provincia, localidad, direccion | TEXT | Ubicación declarada |
| tipo_negocio | TEXT | Tipo de establecimiento declarado |
| origen | TEXT | `real` |

## Productos

| Campo | Tipo | Significado |
| --- | --- | --- |
| id_producto | TEXT, PK | Identificador interno |
| nombre_original | TEXT, UNIQUE | Denominación de la fuente |
| categoria | TEXT | Nafta, Gasoil, Queroseno o GNC; clasificación derivada |
| unidad_venta | TEXT | `L` para líquidos; `m3` para GNC |
| unidad_precio | TEXT | `ARS/L` o `ARS/m3` |
| origen_nombre | TEXT | `real` |
| origen_categoria | TEXT | `derivado` |

## Clientes

Una fila es una cuenta del mayorista ficticio asociada a un establecimiento real. Su identidad es real y su relación comercial es simulada. Se trabaja por establecimiento, no por CUIT consolidado.

| Campo | Tipo | Significado |
| --- | --- | --- |
| id_cliente | TEXT, PK | Identificador interno de cuenta |
| id_operador | TEXT, FK, UNIQUE | Establecimiento de origen; no proveedor |
| nombre | TEXT | Nombre real del operador, copiado de la fuente |
| provincia | TEXT | Provincia real del establecimiento |
| origen_identidad | TEXT | `real` |
| relacion_comercial | TEXT | `simulada` |

Nombre y provincia se copian al generar la cuenta; el generador los obtiene de operadores. Para localidad, dirección, CUIT y bandera consultar operadores mediante id_operador. V2 elimina el segmento inventado.

## Pedidos

| Campo | Tipo | Significado |
| --- | --- | --- |
| id_pedido | TEXT, PK | Identificador simulado |
| fecha | DATE | Primer día del mes de 2025 como representación mensual; no fecha de entrega |
| id_cliente | TEXT, FK | Cuenta del establecimiento que compra en la simulación |
| estado | TEXT | `Concretado`, supuesto del caso |
| origen | TEXT | `sintetico_mensual` |

UNIQUE(id_cliente, fecha) y CHECK del primer día del mes garantizan un pedido por cliente/mes. Se generan doce por cliente, 216 en total. El operador se obtiene a través de clientes, sin repetirlo en pedidos.

## Detalle de pedido

Una fila representa un registro fuente completo asignado al pedido mensual del establecimiento. id_fuente es único en el detalle. La cantidad se interpreta con `productos.unidad_venta`.

| Campo | Tipo | Significado |
| --- | --- | --- |
| id_detalle | TEXT, PK | Identificador sintético de línea |
| id_pedido | TEXT, FK | Cabecera |
| id_producto | TEXT, FK | Producto |
| id_fuente | TEXT, FK | Registro mensual real del que procede la cantidad |
| cantidad | NUMERIC(18,3) | Volumen mensual completo convertido a la unidad de venta, usado como compra simulada |
| precio_unitario_ars | NUMERIC(18,2) | Precio minorista mensual con impuestos usado como referencia; ARS por unidad |
| origen | TEXT | `simulado_con_referencia_minorista` |

El importe no se almacena en la tabla: `v_ventas` lo calcula como cantidad × precio. El producto puede tener hasta cinco decimales monetarios; redondear solo para presentación evita introducir diferencias de conciliación.

`detalle_pedido_entrada` tiene las mismas columnas, pero permite nulos y duplicados. No tiene clave primaria para conservar deliberadamente la entrada defectuosa. La carga SQL utiliza esta tabla y produce el detalle limpio.

## Fuente de ventas

Una fila corresponde a un registro incluido de la extracción de Access. No es un ticket ni un pedido. No se agrupan ni se inventan ventas antes de guardar esta tabla.

| Campo | Tipo | Significado |
| --- | --- | --- |
| id_fuente | TEXT, PK | `F` más número de fila extraída con seis posiciones |
| fila_extraida | INTEGER, UNIQUE | Orden de extracción, no identificador oficial |
| id_operador | TEXT, FK | Establecimiento de referencia |
| periodo | DATE | Primer día del mes, representación técnica; no fecha de transacción |
| id_producto | TEXT, FK | Producto original clasificado |
| canal | TEXT | `Al público` en esta selección |
| volumen_original_m3 | NUMERIC(18,3) | Volumen declarado interpretado en m³ según documentación |
| unidad_original | TEXT | `m3` |
| cantidad_venta | NUMERIC(18,3) | Volumen ×1.000 para líquidos, volumen sin conversión para GNC |
| unidad_venta | TEXT | `L` o `m3` |
| precio_promedio_con_impuestos_ars | NUMERIC(18,2) | Campo original `Precio con impuestos`, ARS por unidad de venta |
| precio_surtidor_ars | NUMERIC(18,2), admite NULL | Precio al cierre, conservado y no utilizado para calcular ventas |
| origen | TEXT | `real_con_conversion` |

## Archivos de trazabilidad

- `fuente_original.csv`: encabezados originales, 25 campos de Access más `_fila_extraida`. Se preservan precios sin/con impuestos, volumen, precio surtidor, fecha de baja, indicador de movimiento e impuestos. La fecha de baja se mantiene como texto original, aunque su orden sea inusual. Los impuestos no se suman para reconstruir precios: pueden expresar conceptos o escalas distintos.
- `exclusiones.csv`: `fila_extraida`, `motivo`. Identifica filas de la muestra que no alimentan la simulación.
- `candidatos_revision.csv`: `fila_extraida`, `operador`, `periodo`, `producto`, `volumen_original`, `precio_original`, `motivo`. Procede del conjunto de candidatos, no solo de los 18 establecimientos finales.
- `advertencias_fuente.csv`: `id_fuente`, `campo`, `valor`, `motivo`. Señales que requieren revisión sin cambiar la fuente.
- `incidencias_simuladas.csv`: `id_detalle`, `campo`, `incidencia`, `recuperacion`. Registra cada precio retirado y duplicado agregado artificialmente.
- `conciliacion.csv`: `id_fuente`, `unidad`, cantidades de fuente/pedidos y diferencia, importes de fuente/pedidos y diferencia. Las diferencias deben ser cero para cada fila.

## Vistas SQL

- `v_ventas`: une pedidos, clientes, detalle y productos. Expone mes representado como fecha, cliente, operador de origen, categoría, unidad, cantidad, precio y `importe_referencia_ars`.
- `v_conciliacion`: compara cantidades e importes por fuente. `COALESCE(SUM(...),0)` representa correctamente ausencia de detalles; no sustituye precios desconocidos por cero.

## Valores ausentes y límites

CSV vacío corresponde a NULL al cargar en SQL. `N/D` se mantiene en el original y debe tratarse explícitamente como desconocido cuando corresponda. Los datos reales excluidos no alimentan los pedidos. Las cifras del dataset describen únicamente registros incluidos; ni el muestreo ni la imputación permiten inferir comportamiento de compradores reales.
