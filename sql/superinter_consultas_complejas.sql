-- ============================================================
-- SUPERINTER S.A.S. - AVANCE 3
-- CONSULTAS DE VALIDACION (10 consultas SELECT complejas)
-- ============================================================
-- Requiere haber ejecutado superinter_ddl.sql y superinter_datos.sql
-- Todas usan JOIN y GROUP BY y responden preguntas de negocio reales
-- de un supermercado (ventas, inventario, compras, clientes, promociones).
-- ============================================================

SET search_path TO superinter;

-- ------------------------------------------------------------
-- CONSULTA 1: Top 10 productos mas vendidos (unidades e ingresos)
-- Negocio: identificar los productos estrella para asegurar stock.
-- Demuestra el sesgo de popularidad de los datos.
-- ------------------------------------------------------------
SELECT
    p.codigo_producto,
    p.nombre_producto,
    c.nombre_categoria,
    SUM(df.cantidad)                AS unidades_vendidas,
    SUM(df.total_linea)             AS ingreso_total,
    COUNT(DISTINCT df.id_factura)   AS num_facturas
FROM detalle_factura df
JOIN producto  p ON p.codigo_producto = df.codigo_producto
JOIN categoria c ON c.id_categoria    = p.id_categoria
GROUP BY p.codigo_producto, p.nombre_producto, c.nombre_categoria
ORDER BY unidades_vendidas DESC
LIMIT 10;

-- ------------------------------------------------------------
-- CONSULTA 2: Ventas mensuales por sede (estacionalidad)
-- Negocio: comparar el desempeno de cada sede mes a mes.
-- Demuestra el sesgo temporal (fin de ano) y geografico (Cali).
-- ------------------------------------------------------------
SELECT
    s.nombre_sede,
    TO_CHAR(fv.fecha_expedicion, 'YYYY-MM')      AS mes,
    COUNT(fv.id_factura)                         AS num_ventas,
    SUM(fv.total_pagar)                          AS total_facturado,
    ROUND(AVG(fv.total_pagar), 2)                AS ticket_promedio
FROM factura_venta fv
JOIN sede s ON s.id_sede = fv.id_sede
GROUP BY s.nombre_sede, TO_CHAR(fv.fecha_expedicion, 'YYYY-MM')
ORDER BY s.nombre_sede, mes;

-- ------------------------------------------------------------
-- CONSULTA 3: Ranking de ventas por sede con participacion (%)
-- Negocio: cuanto aporta cada sede al total de la compania.
-- ------------------------------------------------------------
SELECT
    s.nombre_sede,
    s.ciudad,
    COUNT(fv.id_factura)                                            AS num_ventas,
    SUM(fv.total_pagar)                                             AS total_ventas,
    ROUND(100.0 * SUM(fv.total_pagar) / SUM(SUM(fv.total_pagar)) OVER (), 2) AS participacion_pct
FROM factura_venta fv
JOIN sede s ON s.id_sede = fv.id_sede
GROUP BY s.nombre_sede, s.ciudad
ORDER BY total_ventas DESC;

-- ------------------------------------------------------------
-- CONSULTA 4: Ventas por categoria y su recaudo de IVA
-- Negocio: analizar el mix de ventas por categoria y el IVA generado.
-- ------------------------------------------------------------
SELECT
    c.nombre_categoria,
    COUNT(DISTINCT df.codigo_producto)  AS productos_distintos,
    SUM(df.cantidad)                    AS unidades,
    SUM(df.subtotal_linea)              AS base_gravable,
    SUM(df.iva_linea)                   AS iva_recaudado,
    SUM(df.total_linea)                 AS total_con_iva
FROM detalle_factura df
JOIN producto  p ON p.codigo_producto = df.codigo_producto
JOIN categoria c ON c.id_categoria    = p.id_categoria
GROUP BY c.nombre_categoria
HAVING SUM(df.cantidad) > 0
ORDER BY total_con_iva DESC;

-- ------------------------------------------------------------
-- CONSULTA 5: Preferencia de medios de pago (mix e importancia)
-- Negocio: entender como pagan los clientes (efectivo, tarjeta, QR, PSE).
-- Demuestra el sesgo de medios de pago.
-- ------------------------------------------------------------
SELECT
    mp.tipo_pago,
    COUNT(*)                                          AS num_pagos,
    SUM(mp.valor_pago)                                AS valor_total,
    ROUND(AVG(mp.valor_pago), 2)                      AS valor_promedio,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_transacciones
FROM medio_pago mp
JOIN factura_venta fv ON fv.id_factura = mp.id_factura
GROUP BY mp.tipo_pago
ORDER BY valor_total DESC;

-- ------------------------------------------------------------
-- CONSULTA 6: Top 10 clientes por compras (segmentacion)
-- Negocio: identificar clientes de alto valor para fidelizacion.
-- ------------------------------------------------------------
SELECT
    cl.id_cliente,
    cl.nombre_completo,
    cl.tipo_documento,
    cl.canal_venta_preferido,
    COUNT(fv.id_factura)            AS compras,
    SUM(fv.total_pagar)             AS total_gastado,
    ROUND(AVG(fv.total_pagar), 2)   AS ticket_promedio,
    MAX(fv.fecha_expedicion)::date  AS ultima_compra
FROM factura_venta fv
JOIN cliente cl ON cl.id_cliente = fv.id_cliente
GROUP BY cl.id_cliente, cl.nombre_completo, cl.tipo_documento, cl.canal_venta_preferido
ORDER BY total_gastado DESC
LIMIT 10;

-- ------------------------------------------------------------
-- CONSULTA 7: Desempeno de cajeros por sede
-- Negocio: medir productividad del personal de caja.
-- ------------------------------------------------------------
SELECT
    s.nombre_sede,
    e.primer_nombre || ' ' || e.primer_apellido  AS cajero,
    e.rol_operativo,
    COUNT(fv.id_factura)                          AS facturas_emitidas,
    SUM(fv.total_pagar)                           AS total_recaudado,
    ROUND(AVG(fv.total_pagar), 2)                 AS ticket_promedio
FROM factura_venta fv
JOIN empleado e ON e.id_empleado = fv.id_cajero
JOIN sede     s ON s.id_sede     = fv.id_sede
GROUP BY s.nombre_sede, e.id_empleado, e.primer_nombre, e.primer_apellido, e.rol_operativo
ORDER BY total_recaudado DESC;

-- ------------------------------------------------------------
-- CONSULTA 8: Valorizacion del inventario por bodega
-- Negocio: cuanto capital esta inmovilizado en cada bodega.
-- ------------------------------------------------------------
SELECT
    b.nombre_bodega,
    b.tipo_bodega,
    COALESCE(s.nombre_sede, 'Independiente')          AS sede,
    COUNT(i.id_inventario)                            AS referencias,
    SUM(i.stock_actual)                               AS unidades_en_stock,
    SUM(i.stock_actual * p.costo_promedio)            AS valor_inventario_costo,
    SUM(i.stock_actual * p.precio_venta)              AS valor_inventario_venta
FROM inventario i
JOIN bodega   b ON b.id_bodega       = i.id_bodega
JOIN producto p ON p.codigo_producto = i.codigo_producto
LEFT JOIN sede s ON s.id_sede        = b.id_sede
GROUP BY b.id_bodega, b.nombre_bodega, b.tipo_bodega, s.nombre_sede
ORDER BY valor_inventario_costo DESC;

-- ------------------------------------------------------------
-- CONSULTA 9: Cumplimiento de proveedores (ordenes recibidas)
-- Negocio: evaluar proveedores por volumen de compra y ordenes completas.
-- ------------------------------------------------------------
SELECT
    pr.razon_social,
    pr.calificacion,
    COUNT(o.num_orden)                                                    AS total_ordenes,
    COUNT(*) FILTER (WHERE o.estado = 'RECIBIDO')                         AS ordenes_recibidas,
    COUNT(*) FILTER (WHERE o.estado = 'CANCELADO')                        AS ordenes_canceladas,
    SUM(o.total_orden)                                                    AS monto_comprado,
    ROUND(100.0 * COUNT(*) FILTER (WHERE o.estado = 'RECIBIDO')
          / NULLIF(COUNT(o.num_orden), 0), 2)                            AS pct_cumplimiento
FROM orden_pedido o
JOIN proveedor pr ON pr.id_proveedor = o.id_proveedor
GROUP BY pr.id_proveedor, pr.razon_social, pr.calificacion
ORDER BY monto_comprado DESC;

-- ------------------------------------------------------------
-- CONSULTA 10: Impacto de las promociones en las ventas
-- Negocio: cuantificar unidades y montos vendidos bajo cada promocion.
-- Usa LEFT JOIN para separar ventas con y sin promocion.
-- ------------------------------------------------------------
SELECT
    COALESCE(pm.nombre_promocion, 'SIN PROMOCION')  AS promocion,
    COALESCE(pm.tipo_promocion, 'N/A')              AS tipo,
    COUNT(DISTINCT df.id_factura)                   AS facturas,
    SUM(df.cantidad)                                AS unidades,
    SUM(df.valor_descuento)                         AS descuento_otorgado,
    SUM(df.total_linea)                             AS total_vendido
FROM detalle_factura df
LEFT JOIN promocion pm ON pm.id_promocion = df.id_promocion
GROUP BY pm.nombre_promocion, pm.tipo_promocion
ORDER BY total_vendido DESC;

-- ============================================================
-- FIN DE LAS CONSULTAS
-- ============================================================
