-- ============================================================
-- SUPERINTER S.A.S. - ENTREGA FINAL
-- CONSULTAS BASICAS (10 consultas SELECT elementales)
-- ============================================================
-- Requiere haber ejecutado superinter_ddl.sql y superinter_datos.sql
-- A diferencia de las 10 consultas complejas (JOIN + GROUP BY), estas
-- consultas operan principalmente sobre una sola tabla y usan filtros
-- (WHERE), ordenamientos (ORDER BY), patrones (LIKE) y agregados simples.
-- Responden preguntas basicas y cotidianas del negocio.
-- ============================================================

SET search_path TO superinter;

-- ------------------------------------------------------------
-- CONSULTA B1: Directorio de clientes activos
-- Negocio: listado telefonico basico de los clientes vigentes.
-- Tecnica: SELECT con WHERE (booleano) + ORDER BY alfabetico.
-- ------------------------------------------------------------
SELECT
    id_cliente,
    numero_documento,
    nombre_completo,
    ciudad,
    telefono,
    email
FROM cliente
WHERE activo = TRUE
ORDER BY nombre_completo;

-- ------------------------------------------------------------
-- CONSULTA B2: Catalogo de productos con su precio de venta
-- Negocio: lista de precios vigente para consulta rapida.
-- Tecnica: SELECT de una tabla + ORDER BY descendente por precio.
-- ------------------------------------------------------------
SELECT
    codigo_producto,
    nombre_producto,
    precio_venta,
    tarifa_iva,
    stock_minimo,
    punto_reorden
FROM producto
WHERE activo = TRUE
ORDER BY precio_venta DESC;

-- ------------------------------------------------------------
-- CONSULTA B3: Productos perecederos que requieren refrigeracion
-- Negocio: control de cadena de frio y productos delicados.
-- Tecnica: WHERE con dos condiciones booleanas.
-- ------------------------------------------------------------
SELECT
    codigo_producto,
    nombre_producto,
    es_perecedero,
    requiere_refrigeracion,
    dias_vida_util
FROM producto
WHERE es_perecedero = TRUE
  AND requiere_refrigeracion = TRUE
ORDER BY dias_vida_util ASC;

-- ------------------------------------------------------------
-- CONSULTA B4: Empleados activos por rol operativo
-- Negocio: cuantos empleados hay en cada rol (nomina basica).
-- Tecnica: GROUP BY simple sobre una sola tabla + COUNT.
-- ------------------------------------------------------------
SELECT
    rol_operativo,
    COUNT(*)              AS cantidad_empleados,
    ROUND(AVG(salario_base), 2) AS salario_promedio
FROM empleado
WHERE activo = TRUE
GROUP BY rol_operativo
ORDER BY cantidad_empleados DESC;

-- ------------------------------------------------------------
-- CONSULTA B5: Proveedores mejor calificados
-- Negocio: identificar proveedores con calificacion alta (4 o 5).
-- Tecnica: WHERE con rango + ORDER BY.
-- ------------------------------------------------------------
SELECT
    id_proveedor,
    nit,
    razon_social,
    calificacion,
    tiempo_entrega_dias,
    condiciones_pago_dias
FROM proveedor
WHERE activo = TRUE
  AND calificacion >= 4
ORDER BY calificacion DESC, tiempo_entrega_dias ASC;

-- ------------------------------------------------------------
-- CONSULTA B6: Sedes de la compania y su capacidad instalada
-- Negocio: ficha basica de cada sede (ciudad, cajas, area).
-- Tecnica: SELECT de una tabla + ORDER BY por ciudad.
-- ------------------------------------------------------------
SELECT
    codigo_sede,
    nombre_sede,
    ciudad,
    num_cajas,
    area_m2,
    fecha_apertura
FROM sede
WHERE activo = TRUE
ORDER BY ciudad, nombre_sede;

-- ------------------------------------------------------------
-- CONSULTA B7: Promociones vigentes hoy
-- Negocio: que promociones estan activas en la fecha actual.
-- Tecnica: WHERE con comparacion de fechas (CURRENT_DATE).
-- ------------------------------------------------------------
SELECT
    codigo_promocion,
    nombre_promocion,
    tipo_promocion,
    valor_descuento,
    fecha_inicio,
    fecha_fin
FROM promocion
WHERE activo = TRUE
  AND CURRENT_DATE BETWEEN fecha_inicio AND fecha_fin
ORDER BY fecha_fin ASC;

-- ------------------------------------------------------------
-- CONSULTA B8: Facturas por estado
-- Negocio: cuantas facturas hay emitidas, anuladas, etc.
-- Tecnica: GROUP BY simple + COUNT + SUM sobre una sola tabla.
-- ------------------------------------------------------------
SELECT
    estado,
    COUNT(*)               AS numero_facturas,
    SUM(total_pagar)       AS monto_total,
    ROUND(AVG(total_pagar), 2) AS ticket_promedio
FROM factura_venta
GROUP BY estado
ORDER BY numero_facturas DESC;

-- ------------------------------------------------------------
-- CONSULTA B9: Ordenes de pedido pendientes de recibir
-- Negocio: compras que aun no han llegado a bodega.
-- Tecnica: WHERE con IN (varios estados) + ORDER BY por fecha.
-- ------------------------------------------------------------
SELECT
    num_orden,
    fecha_pedido,
    fecha_entrega_esperada,
    estado,
    total_orden
FROM orden_pedido
WHERE estado IN ('PENDIENTE', 'APROBADO', 'ENVIADO', 'PARCIAL')
ORDER BY fecha_entrega_esperada ASC;

-- ------------------------------------------------------------
-- CONSULTA B10: Referencias de inventario sin stock disponible
-- Negocio: alerta de reabastecimiento (todo el stock esta reservado).
-- Tecnica: una sola tabla, WHERE comparando dos columnas entre si.
-- ------------------------------------------------------------
SELECT
    i.codigo_producto,
    i.stock_actual,
    i.stock_reservado,
    (i.stock_actual - i.stock_reservado) AS stock_disponible
FROM inventario i
WHERE i.stock_actual <= i.stock_reservado
ORDER BY stock_disponible ASC;

-- ============================================================
-- FIN DE LAS CONSULTAS BASICAS
-- ============================================================
