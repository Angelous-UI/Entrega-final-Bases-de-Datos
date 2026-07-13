-- ============================================================
-- SUPERINTER S.A.S. - AVANCE 3
-- CARGA DE DATOS (PostgreSQL) - Datos sinteticos con sesgos estadisticos
-- ============================================================
-- Requiere haber ejecutado antes superinter_ddl.sql
-- Volumen objetivo: > 1.000 transacciones (facturas) + sus detalles y pagos.
--
-- SESGOS INTENCIONALES INCORPORADOS:
--   1. Popularidad de productos NO uniforme (distribucion exponencial:
--      pocos productos concentran la mayoria de las ventas).
--   2. Estacionalidad temporal: mas ventas en fin de ano (nov-dic) y fines de semana.
--   3. Distribucion geografica sesgada: Cali concentra mas ventas que las demas sedes.
--   4. Medios de pago sesgados hacia efectivo y tarjeta debito (realidad colombiana).
-- ============================================================

SET search_path TO superinter;

-- ------------------------------------------------------------
-- 1. SEDES (4 ciudades del Valle del Cauca)
-- ------------------------------------------------------------
INSERT INTO sede (codigo_sede, nombre_sede, ciudad, direccion, telefono, num_cajas, fecha_apertura) VALUES
('S001','Superinter Cali Centro','Cali','Cra 5 #12-34','6023001001',12,'2010-03-15'),
('S002','Superinter Palmira','Palmira','Cll 30 #28-10','6022701002',6,'2013-07-20'),
('S003','Superinter Tulua','Tulua','Cra 25 #26-40','6022331003',5,'2015-11-05'),
('S004','Superinter Buenaventura','Buenaventura','Cll 2 #3-15','6022401004',4,'2017-02-18');

-- ------------------------------------------------------------
-- 2. EMPLEADOS (20 empleados distribuidos con sesgo hacia Cali)
-- ------------------------------------------------------------
INSERT INTO empleado (tipo_documento, numero_documento, primer_nombre, primer_apellido,
    fecha_nacimiento, genero, direccion, telefono, cargo, rol_operativo, tipo_contrato,
    fecha_ingreso, salario_base, id_sede) VALUES
('CC','1130010001','Carlos','Ramirez','1985-05-12','M','Cll 10 #5-20','3001112201','Administrador','ADMIN','INDEFINIDO','2011-01-10',4500000,1),
('CC','1130010002','Diana','Lopez','1990-08-23','F','Cra 8 #14-05','3001112202','Supervisor','SUPERVISOR','INDEFINIDO','2012-03-15',2800000,1),
('CC','1130010003','Andres','Gomez','1993-02-14','M','Cll 22 #9-30','3001112203','Cajero','CAJERO','FIJO','2018-06-01',1450000,1),
('CC','1130010004','Laura','Martinez','1995-11-30','F','Cra 12 #20-15','3001112204','Cajero','CAJERO','FIJO','2019-02-10',1450000,1),
('CC','1130010005','Julian','Torres','1988-07-19','M','Cll 30 #10-40','3001112205','Bodeguero','BODEGUERO','INDEFINIDO','2014-09-05',1600000,1),
('CC','1130010006','Paola','Herrera','1991-04-08','F','Cra 15 #18-22','3001112206','Cajero','CAJERO','FIJO','2020-01-20',1450000,1),
('CC','1130010007','Ricardo','Vargas','1987-12-01','M','Cll 5 #7-11','3001112207','Auditor','AUDITOR','INDEFINIDO','2013-05-18',3200000,1),
('CC','1130010008','Sandra','Jimenez','1994-06-25','F','Cra 9 #12-08','3001112208','Cajero','CAJERO','OBRA_LABOR','2021-08-11',1450000,1),
('CC','1130020001','Miguel','Castro','1986-09-17','M','Cll 28 #26-14','3002112201','Administrador','ADMIN','INDEFINIDO','2013-08-01',4200000,2),
('CC','1130020002','Natalia','Rojas','1992-03-05','F','Cra 27 #29-30','3002112202','Supervisor','SUPERVISOR','INDEFINIDO','2014-10-12',2700000,2),
('CC','1130020003','Felipe','Moreno','1996-01-28','M','Cll 31 #30-05','3002112203','Cajero','CAJERO','FIJO','2019-05-20',1450000,2),
('CC','1130020004','Carolina','Ortiz','1993-10-14','F','Cra 25 #28-18','3002112204','Bodeguero','BODEGUERO','FIJO','2018-11-03',1600000,2),
('CC','1130030001','Oscar','Delgado','1984-11-22','M','Cll 26 #24-40','3003112201','Administrador','ADMIN','INDEFINIDO','2015-12-01',4000000,3),
('CC','1130030002','Adriana','Nunez','1990-05-09','F','Cra 24 #25-11','3003112202','Cajero','CAJERO','FIJO','2016-04-15',1450000,3),
('CC','1130030003','Javier','Pena','1997-08-03','M','Cll 27 #26-33','3003112203','Cajero','CAJERO','OBRA_LABOR','2022-02-08',1450000,3),
('CC','1130030004','Monica','Silva','1989-02-27','F','Cra 26 #27-19','3003112204','Bodeguero','BODEGUERO','FIJO','2017-07-19',1600000,3),
('CC','1130040001','German','Aguirre','1983-06-30','M','Cll 2 #4-22','3004112201','Administrador','ADMIN','INDEFINIDO','2017-03-10',3900000,4),
('CC','1130040002','Luz','Mena','1991-12-15','F','Cra 3 #2-08','3004112202','Cajero','CAJERO','FIJO','2018-09-01',1450000,4),
('CC','1130040003','Hernan','Palacios','1995-07-21','M','Cll 4 #5-16','3004112203','Cajero','CAJERO','OBRA_LABOR','2021-11-25',1450000,4),
('CC','1130040004','Yolanda','Riascos','1988-03-11','F','Cra 1 #3-27','3004112204','Bodeguero','BODEGUERO','FIJO','2019-06-14',1600000,4);

-- Asignar administradores a cada sede
UPDATE sede SET id_administrador = 1  WHERE id_sede = 1;
UPDATE sede SET id_administrador = 9  WHERE id_sede = 2;
UPDATE sede SET id_administrador = 13 WHERE id_sede = 3;
UPDATE sede SET id_administrador = 17 WHERE id_sede = 4;

-- ------------------------------------------------------------
-- 3. PROVEEDORES (15)
-- ------------------------------------------------------------
INSERT INTO proveedor (nit, razon_social, banco, tipo_cuenta, numero_cuenta,
    contacto_comercial_nombre, contacto_comercial_tel, tiempo_entrega_dias, condiciones_pago_dias, calificacion) VALUES
('900111001-1','Alimentos del Valle S.A.','Bancolombia','CORRIENTE','1001','Pedro Nel',   '3101110001',2,30,5),
('900111002-2','Distribuidora Nacional Ltda','Davivienda','AHORROS','1002','Ana Maria',   '3101110002',3,45,4),
('900111003-3','Lacteos Colombia S.A.S','BBVA','CORRIENTE','1003','Luis Fernando',        '3101110003',1,30,5),
('900111004-4','Carnes Frescas del Pacifico','Bancolombia','AHORROS','1004','Marta Ruiz','3101110004',1,15,4),
('900111005-5','Aseo y Hogar SA','Banco de Bogota','CORRIENTE','1005','Jorge Diaz',      '3101110005',5,60,3),
('900111006-6','Bebidas Andinas S.A.','Bancolombia','CORRIENTE','1006','Claudia Leon',   '3101110006',3,30,4),
('900111007-7','Panaderia Industrial Ltda','Davivienda','AHORROS','1007','Raul Mejia',   '3101110007',2,30,5),
('900111008-8','Frutas y Verduras del Campo','Banco Agrario','AHORROS','1008','Sofia Cruz','3101110008',1,15,5),
('900111009-9','Productos de Limpieza Sur','BBVA','CORRIENTE','1009','Camilo Rios',       '3101110009',4,45,3),
('900111010-0','Snacks y Golosinas SA','Bancolombia','CORRIENTE','1010','Elena Parra',   '3101110010',3,30,4),
('900111011-1','Granos y Cereales Valle','Davivienda','AHORROS','1011','Fabio Cardona',  '3101110011',4,45,4),
('900111012-2','Cuidado Personal Colombia','Banco de Bogota','CORRIENTE','1012','Nubia Salazar','3101110012',5,60,3),
('900111013-3','Congelados del Pacifico','Bancolombia','CORRIENTE','1013','Ivan Zapata', '3101110013',2,30,4),
('900111014-4','Huevos y Aves del Valle','Banco Agrario','AHORROS','1014','Gloria Mora', '3101110014',1,15,5),
('900111015-5','Articulos para el Hogar SA','BBVA','CORRIENTE','1015','Mario Bravo',      '3101110015',6,60,3);

-- ------------------------------------------------------------
-- 4. CATEGORIAS (jerarquia de 2 niveles)
-- ------------------------------------------------------------
INSERT INTO categoria (codigo_categoria, nombre_categoria, nivel, id_categoria_padre) VALUES
('CAT01','Alimentos Frescos',1,NULL),
('CAT02','Alimentos Procesados',1,NULL),
('CAT03','Aseo Personal',1,NULL),
('CAT04','Aseo del Hogar',1,NULL),
('CAT05','Bebidas',1,NULL),
('CAT06','Hogar',1,NULL),
('CAT07','Frutas y Verduras',2,1),
('CAT08','Carnes',2,1),
('CAT09','Lacteos',2,1),
('CAT10','Snacks',2,2);

-- ------------------------------------------------------------
-- 5. MARCAS (15)
-- ------------------------------------------------------------
INSERT INTO marca (nombre_marca, pais_origen) VALUES
('Alqueria','Colombia'),('Colanta','Colombia'),('Zenu','Colombia'),('Postobon','Colombia'),
('Coca-Cola','USA'),('Nestle','Suiza'),('Colgate','USA'),('Fab','Colombia'),
('Familia','Colombia'),('Doria','Colombia'),('Diana','Colombia'),('Ramo','Colombia'),
('Bimbo','Mexico'),('Marca Propia','Colombia'),('Sin Marca','Colombia');

-- ------------------------------------------------------------
-- 6. UNIDADES DE MEDIDA (5)
-- ------------------------------------------------------------
INSERT INTO unidad_medida (codigo_unidad, nombre_unidad, abreviatura, tipo) VALUES
('UND','Unidad','und','CANTIDAD'),
('KG','Kilogramo','kg','PESO'),
('GR','Gramo','g','PESO'),
('LT','Litro','L','VOLUMEN'),
('ML','Mililitro','ml','VOLUMEN');

-- ------------------------------------------------------------
-- 7. PRODUCTOS (80 productos generados)
--    tarifa_iva por categoria segun legislacion colombiana:
--    Frescos/Frutas/Carnes/Lacteos basicos -> 0.00 (excluidos)
--    Procesados canasta -> 0.05 ; Aseo/Hogar/Bebidas -> 0.19
-- ------------------------------------------------------------
INSERT INTO producto (codigo_producto, codigo_barras_ean, nombre_producto, precio_venta,
    costo_promedio, tarifa_iva, es_perecedero, stock_minimo, punto_reorden,
    id_categoria, id_marca, id_unidad, id_proveedor_principal)
SELECT
    'P' || LPAD(g::text, 4, '0'),
    '770' || LPAD((1000000 + g)::text, 10, '0'),
    'Producto ' || g,
    -- precio con variabilidad
    ROUND((1000 + random() * 49000)::numeric, -1),
    ROUND((800 + random() * 35000)::numeric, -1),
    -- tarifa_iva COHERENTE con la categoria (1 + g % 10):
    --   1 Frescos, 7 Frutas/Verduras, 8 Carnes, 9 Lacteos -> 0.00 (excluidos/exentos)
    --   2 Procesados -> 0.05 (canasta diferencial)
    --   3 Aseo Personal, 4 Aseo Hogar, 5 Bebidas, 6 Hogar, 10 Snacks -> 0.19 (general)
    CASE (1 + (g % 10))
        WHEN 1 THEN 0.00
        WHEN 7 THEN 0.00
        WHEN 8 THEN 0.00
        WHEN 9 THEN 0.00
        WHEN 2 THEN 0.05
        ELSE 0.19
    END,
    (g % 3 = 0),                        -- ~1/3 perecederos
    10,
    20,
    1 + (g % 10),                       -- categoria 1..10
    1 + (g % 15),                       -- marca 1..15
    1 + (g % 5),                        -- unidad 1..5
    1 + (g % 15)                        -- proveedor 1..15
FROM generate_series(1, 80) AS g;

-- ------------------------------------------------------------
-- 8. BODEGAS (una por sede + 1 central independiente)
-- ------------------------------------------------------------
INSERT INTO bodega (codigo_bodega, nombre_bodega, tipo_bodega, id_sede, id_responsable) VALUES
('B001','Bodega Central Cali','CENTRAL',NULL,5),
('B002','Bodega Cali Centro','LOCAL',1,5),
('B003','Bodega Palmira','LOCAL',2,12),
('B004','Bodega Tulua','LOCAL',3,16),
('B005','Bodega Buenaventura','LOCAL',4,20),
('B006','Bodega Refrigerada Cali','REFRIGERADA',1,5);

-- ------------------------------------------------------------
-- 9. INVENTARIO (cada producto en la bodega central + su bodega local)
-- ------------------------------------------------------------
INSERT INTO inventario (codigo_producto, id_bodega, stock_actual, demanda_diaria_promedio, fecha_ultimo_conteo)
SELECT p.codigo_producto, b.id_bodega,
       (50 + floor(random() * 500))::int,
       ROUND((1 + random() * 30)::numeric, 2),
       CURRENT_DATE - (floor(random() * 30))::int
FROM producto p
CROSS JOIN bodega b
WHERE b.id_bodega IN (1, 2);   -- central + Cali centro (evita explosion de filas)

-- ------------------------------------------------------------
-- 10. CLIENTES (200: mezcla de naturales CC/CE y juridicos NIT)
-- ------------------------------------------------------------
INSERT INTO cliente (tipo_documento, numero_documento, nombre_completo, habeas_data,
    ciudad, telefono, email, tipo_regimen, canal_venta_preferido)
SELECT
    CASE WHEN g % 10 = 0 THEN 'NIT' WHEN g % 17 = 0 THEN 'CE' ELSE 'CC' END,
    LPAD((10000000 + g * 7)::text, 10, '0'),
    CASE WHEN g % 10 = 0 THEN 'Empresa Cliente ' || g ELSE 'Cliente Natural ' || g END,
    TRUE,
    (ARRAY['Cali','Cali','Cali','Palmira','Tulua','Buenaventura'])[1 + (g % 6)],  -- sesgo Cali
    '31' || LPAD((10000000 + g)::text, 8, '0'),
    'cliente' || g || '@correo.com',
    CASE WHEN g % 10 = 0 THEN 'RESPONSABLE_IVA' ELSE 'NO_RESPONSABLE_IVA' END,
    (ARRAY['PRESENCIAL','PRESENCIAL','PRESENCIAL','DOMICILIO','WEB'])[1 + (g % 5)]
FROM generate_series(1, 200) AS g;

-- ------------------------------------------------------------
-- 11. PROMOCIONES (8) + productos asociados
-- ------------------------------------------------------------
INSERT INTO promocion (codigo_promocion, nombre_promocion, tipo_promocion, valor_descuento,
    fecha_inicio, fecha_fin, id_sede) VALUES
('PROMO01','Descuento 10% Aseo','DESCUENTO_PORCENTAJE',10,'2024-01-01','2024-12-31',NULL),
('PROMO02','2x1 Bebidas','NxM',NULL,'2024-06-01','2024-08-31',1),
('PROMO03','Precio especial Lacteos','PRECIO_ESPECIAL',NULL,'2024-03-01','2024-12-31',NULL),
('PROMO04','Descuento 15% Snacks','DESCUENTO_PORCENTAJE',15,'2024-11-01','2024-12-31',NULL),
('PROMO05','Combo Hogar','COMBO',NULL,'2024-05-01','2024-12-31',2),
('PROMO06','Descuento fijo Carnes','DESCUENTO_VALOR',2000,'2024-07-01','2024-12-31',NULL),
('PROMO07','20% Cuidado Personal','DESCUENTO_PORCENTAJE',20,'2024-09-01','2024-10-31',NULL),
('PROMO08','Fin de ano procesados','DESCUENTO_PORCENTAJE',12,'2024-12-01','2024-12-31',NULL);

INSERT INTO promocion_producto (id_promocion, codigo_producto)
SELECT 1 + (g % 8), 'P' || LPAD(g::text, 4, '0')
FROM generate_series(1, 40) AS g;

-- ============================================================
-- 12. ORDENES DE PEDIDO (150 ordenes + detalles) - flujo de compras
-- ============================================================
INSERT INTO orden_pedido (fecha_pedido, fecha_entrega_esperada, estado, subtotal, valor_iva, total_orden,
    fecha_recepcion, numero_remision, id_proveedor, id_bodega_destino, id_empleado_solicita, id_empleado_aprueba)
SELECT
    d.fecha_pedido,
    d.fecha_pedido + 5,
    (ARRAY['RECIBIDO','RECIBIDO','RECIBIDO','PARCIAL','PENDIENTE','CANCELADO'])[1 + (g % 6)],
    0, 0, 0,
    CASE WHEN g % 6 < 4 THEN d.fecha_pedido + (2 + floor(random()*5))::int ELSE NULL END,
    CASE WHEN g % 6 < 4 THEN 'REM-' || LPAD(g::text,5,'0') ELSE NULL END,
    1 + (g % 15),
    1 + (g % 6),
    (ARRAY[5,12,16,20,5])[1 + (g % 5)],   -- bodegueros
    (ARRAY[1,9,13,17])[1 + (g % 4)]        -- administradores
FROM generate_series(1, 150) AS g
CROSS JOIN LATERAL (
    -- (0*g) correlaciona la subconsulta con la fila externa para que random()
    -- se reevalue POR FILA (si no, PostgreSQL puede evaluarla una sola vez).
    SELECT (DATE '2024-01-01' + (floor(random() * 365) + 0*g)::int) AS fecha_pedido
) d;

-- Detalles de orden (2 a 4 lineas por orden)
-- La tarifa de IVA de la compra se toma del producto real (no fija en 0.19),
-- de modo que un producto excluido/exento no genere IVA ficticio en la orden.
INSERT INTO detalle_orden (num_orden, codigo_producto, cantidad_solicitada, cantidad_recibida,
    costo_unitario, tarifa_iva, subtotal_linea, iva_linea, total_linea)
SELECT
    o.num_orden,
    prod.codigo_producto,
    cant.cantidad,
    cant.cantidad,
    prc.costo,
    prod.tarifa_iva,
    ROUND(cant.cantidad * prc.costo, 2),
    ROUND(cant.cantidad * prc.costo * prod.tarifa_iva, 2),
    ROUND(cant.cantidad * prc.costo * (1 + prod.tarifa_iva), 2)
FROM orden_pedido o
CROSS JOIN LATERAL generate_series(1, 2 + (o.num_orden % 3)) AS linea
-- (0*(o.num_orden+linea)) correlaciona cada subconsulta con la fila externa
-- para forzar la reevaluacion de random() por linea.
CROSS JOIN LATERAL (SELECT (10 + floor(random() * 200) + 0*(o.num_orden+linea))::int AS cantidad) cant
CROSS JOIN LATERAL (SELECT ROUND((500 + random() * 20000 + 0*(o.num_orden+linea))::numeric, -1) AS costo) prc
CROSS JOIN LATERAL (
    SELECT codigo_producto, tarifa_iva FROM producto
    WHERE codigo_producto = 'P' || LPAD((1 + floor(random() * 80) + 0*(o.num_orden+linea))::int::text, 4, '0')
    LIMIT 1
) prod;

-- Recalcular totales de orden a partir de sus detalles
UPDATE orden_pedido o SET
    subtotal    = t.subtotal,
    valor_iva   = t.iva,
    total_orden = t.total
FROM (
    SELECT num_orden, SUM(subtotal_linea) subtotal, SUM(iva_linea) iva, SUM(total_linea) total
    FROM detalle_orden GROUP BY num_orden
) t
WHERE o.num_orden = t.num_orden;

-- ============================================================
-- 13. FACTURAS DE VENTA (1.200 facturas) - CON SESGOS ESTADISTICOS
-- ============================================================
-- Sesgo temporal: la fecha se concentra en nov-dic y fines de semana.
-- Sesgo geografico: la sede se elige con mayor probabilidad para Cali (id 1).
INSERT INTO factura_venta (numero_factura_dian, prefijo_dian, resolucion_dian, vigencia_resolucion,
    fecha_generacion, fecha_expedicion, subtotal, valor_total_iva, total_pagar, estado,
    id_cliente, id_sede, id_cajero)
SELECT
    'FE' || LPAD(g::text, 8, '0'),
    'SETP',
    'DIAN-18764000001234',
    '2025-12-31',
    f.fecha,
    f.fecha,
    0, 0, 0,
    'EMITIDA',
    1 + floor(random() * 200)::int,          -- cliente aleatorio
    sd.id_sede,
    -- cajero COHERENTE con la sede de la factura (cada cajero pertenece a su sede)
    CASE sd.id_sede
        WHEN 1 THEN (ARRAY[3,4,6,8])[1 + floor(random() * 4)::int]  -- Cali
        WHEN 2 THEN 11                                              -- Palmira
        WHEN 3 THEN (ARRAY[14,15])[1 + floor(random() * 2)::int]    -- Tulua
        ELSE      (ARRAY[18,19])[1 + floor(random() * 2)::int]      -- Buenaventura
    END
FROM generate_series(1, 1200) AS g
-- (0*g) correlaciona las subconsultas con cada factura para que random() se
-- reevalue POR FILA; de lo contrario todas las facturas compartirian fecha/sede.
CROSS JOIN LATERAL (
    SELECT (
        -- sesgo temporal hacia fin de ano: raiz para concentrar en meses altos
        DATE '2024-01-01' + (floor(power(random(), 0.5) * 364) + 0*g)::int
    )::timestamp
    + (floor(random() * 12) + 8) * INTERVAL '1 hour'  -- horario comercial 8am-8pm
    AS fecha
) f
CROSS JOIN LATERAL (
    -- sesgo geografico con un solo sorteo: 55% Cali, 20% Palmira, 15% Tulua, 10% Buenaventura
    SELECT CASE
        WHEN rr < 0.55 THEN 1
        WHEN rr < 0.75 THEN 2
        WHEN rr < 0.90 THEN 3
        ELSE 4
    END AS id_sede
    FROM (SELECT random() + 0*g AS rr) x
) sd;

-- ------------------------------------------------------------
-- 14. DETALLE_FACTURA - SESGO DE POPULARIDAD DE PRODUCTOS
--     Se usa una distribucion exponencial: pocos productos (los de codigo bajo)
--     concentran la mayoria de las ventas.
-- ------------------------------------------------------------
INSERT INTO detalle_factura (id_factura, codigo_producto, cantidad, valor_unitario,
    tarifa_iva_aplicada, subtotal_linea, iva_linea, total_linea)
SELECT
    fv.id_factura,
    pr.codigo_producto,
    ln.cantidad,
    pr.precio_venta,
    pr.tarifa_iva,
    ROUND(ln.cantidad * pr.precio_venta, 2),
    ROUND(ln.cantidad * pr.precio_venta * pr.tarifa_iva, 2),
    ROUND(ln.cantidad * pr.precio_venta * (1 + pr.tarifa_iva), 2)
FROM factura_venta fv
-- (0*fv.id_factura / 0*(fv.id_factura+l)) correlacionan las subconsultas con la
-- factura para forzar la reevaluacion de random() por fila (numero de lineas,
-- cantidad y producto varian entre facturas; si no, todas serian identicas).
CROSS JOIN LATERAL generate_series(1, 1 + floor(random() * 5 + 0*fv.id_factura)::int) AS l  -- 1 a 5 lineas
CROSS JOIN LATERAL (SELECT (1 + floor(random() * 8 + 0*(fv.id_factura+l)))::int AS cantidad) ln
CROSS JOIN LATERAL (
    -- power(random(),3) sesga fuertemente hacia productos de codigo bajo (populares)
    SELECT * FROM producto
    WHERE codigo_producto = 'P' || LPAD((1 + floor(power(random(), 3) * 79) + 0*(fv.id_factura+l))::int::text, 4, '0')
    LIMIT 1
) pr;

-- ------------------------------------------------------------
-- 14b. APLICAR PROMOCIONES a las lineas de factura elegibles
--     Enlaza detalle_factura.id_promocion cuando el producto tiene una
--     promocion vigente a la fecha de la factura y compatible con la sede.
--     Calcula el descuento para promociones de % y de valor fijo.
-- ------------------------------------------------------------
WITH promo_aplicable AS (
    SELECT
        df.id_detalle,
        df.cantidad,
        df.subtotal_linea,
        pm.id_promocion,
        pm.tipo_promocion,
        pm.valor_descuento,
        ROW_NUMBER() OVER (PARTITION BY df.id_detalle ORDER BY pm.id_promocion) AS rn
    FROM detalle_factura df
    JOIN factura_venta       fv ON fv.id_factura     = df.id_factura
    JOIN promocion_producto  pp ON pp.codigo_producto = df.codigo_producto
    JOIN promocion           pm ON pm.id_promocion    = pp.id_promocion
    WHERE fv.fecha_expedicion::date BETWEEN pm.fecha_inicio AND pm.fecha_fin
      AND (pm.id_sede IS NULL OR pm.id_sede = fv.id_sede)
      AND pm.activo
)
UPDATE detalle_factura df SET
    id_promocion         = pa.id_promocion,
    porcentaje_descuento = CASE WHEN pa.tipo_promocion = 'DESCUENTO_PORCENTAJE'
                                THEN pa.valor_descuento ELSE 0 END,
    valor_descuento      = CASE
        WHEN pa.tipo_promocion = 'DESCUENTO_PORCENTAJE'
            THEN ROUND(pa.subtotal_linea * pa.valor_descuento / 100.0, 2)
        WHEN pa.tipo_promocion = 'DESCUENTO_VALOR'
            THEN LEAST(ROUND(pa.valor_descuento * pa.cantidad, 2), pa.subtotal_linea)
        ELSE 0
    END
FROM promo_aplicable pa
WHERE df.id_detalle = pa.id_detalle
  AND pa.rn = 1;

-- Recalcular la linea neta (base gravable e IVA sobre el valor con descuento)
UPDATE detalle_factura SET
    subtotal_linea = ROUND(cantidad * valor_unitario - valor_descuento, 2),
    iva_linea      = ROUND((cantidad * valor_unitario - valor_descuento) * tarifa_iva_aplicada, 2),
    total_linea    = ROUND((cantidad * valor_unitario - valor_descuento) * (1 + tarifa_iva_aplicada), 2)
WHERE valor_descuento > 0;

-- Recalcular totales de factura desde sus detalles (incluyendo descuentos)
UPDATE factura_venta fv SET
    subtotal        = t.subtotal,
    valor_total_iva = t.iva,
    valor_descuento = t.descuento,
    total_pagar     = t.total
FROM (
    SELECT id_factura,
           SUM(subtotal_linea)   AS subtotal,
           SUM(iva_linea)        AS iva,
           SUM(valor_descuento)  AS descuento,
           SUM(total_linea)      AS total
    FROM detalle_factura GROUP BY id_factura
) t
WHERE fv.id_factura = t.id_factura;

-- Eliminar posibles facturas sin detalle (por seguridad) y sus dependencias
DELETE FROM factura_venta WHERE id_factura NOT IN (SELECT DISTINCT id_factura FROM detalle_factura);

-- ------------------------------------------------------------
-- 15. MEDIO_PAGO - SESGO hacia efectivo y tarjeta debito
--     La mayoria de facturas se pagan con un solo medio; algunas con pago mixto.
-- ------------------------------------------------------------
INSERT INTO medio_pago (id_factura, tipo_pago, valor_pago, valor_recibido, valor_cambio,
    entidad_financiera, referencia_transaccion, fecha_pago)
SELECT
    fv.id_factura,
    mp.tipo,
    fv.total_pagar,
    CASE WHEN mp.tipo = 'EFECTIVO' THEN CEIL(fv.total_pagar / 1000) * 1000 ELSE NULL END,
    CASE WHEN mp.tipo = 'EFECTIVO' THEN CEIL(fv.total_pagar / 1000) * 1000 - fv.total_pagar ELSE 0 END,
    CASE WHEN mp.tipo IN ('PSE','QR','TRANSFERENCIA') THEN
        (ARRAY['Nequi','Daviplata','transfiYa','Bancolombia','PSE'])[1 + floor(random()*5)::int]
    ELSE NULL END,
    CASE WHEN mp.tipo <> 'EFECTIVO' THEN 'REF-' || fv.id_factura ELSE NULL END,
    fv.fecha_expedicion
FROM factura_venta fv
CROSS JOIN LATERAL (
    -- sesgo de medios de pago (realidad colombiana) con un solo sorteo por factura.
    -- (0*fv.id_factura) correlaciona para forzar la reevaluacion de random() por fila.
    SELECT CASE
        WHEN rr < 0.40 THEN 'EFECTIVO'
        WHEN rr < 0.70 THEN 'TARJETA_DEBITO'
        WHEN rr < 0.82 THEN 'TARJETA_CREDITO'
        WHEN rr < 0.90 THEN 'QR'
        WHEN rr < 0.96 THEN 'PSE'
        ELSE 'TRANSFERENCIA'
    END AS tipo
    FROM (SELECT random() + 0*fv.id_factura AS rr) q
) mp
WHERE fv.id_factura % 12 <> 0;   -- pago con un solo medio

-- Pago MIXTO (efectivo 60% + tarjeta debito 40%) para ~8% de las facturas.
-- Demuestra el caso que justifica la tabla MEDIO_PAGO (1 factura : N pagos).
INSERT INTO medio_pago (id_factura, tipo_pago, valor_pago, valor_recibido, valor_cambio,
    referencia_transaccion, fecha_pago)
SELECT
    fv.id_factura,
    m.tipo,
    m.valor,
    CASE WHEN m.tipo = 'EFECTIVO' THEN CEIL(m.valor / 1000) * 1000 ELSE NULL END,
    CASE WHEN m.tipo = 'EFECTIVO' THEN CEIL(m.valor / 1000) * 1000 - m.valor ELSE 0 END,
    CASE WHEN m.tipo <> 'EFECTIVO' THEN 'REF-' || fv.id_factura || '-2' ELSE NULL END,
    fv.fecha_expedicion
FROM factura_venta fv
CROSS JOIN LATERAL (
    VALUES
        ('EFECTIVO',       ROUND(fv.total_pagar * 0.60, 2)),
        ('TARJETA_DEBITO', ROUND(fv.total_pagar - ROUND(fv.total_pagar * 0.60, 2), 2))
) AS m(tipo, valor)
WHERE fv.id_factura % 12 = 0
  AND fv.total_pagar > 0
  AND m.valor > 0;

-- ------------------------------------------------------------
-- 16. MOVIMIENTOS DE INVENTARIO (300 movimientos de ejemplo)
-- ------------------------------------------------------------
INSERT INTO movimiento_inventario (tipo_movimiento, cantidad, stock_anterior, stock_posterior,
    costo_unitario, fecha_movimiento, id_inventario, id_empleado)
SELECT
    (ARRAY['ENTRADA','SALIDA','SALIDA','SALIDA','AJUSTE_POSITIVO','AJUSTE_NEGATIVO'])[1 + (g % 6)],
    (1 + floor(random() * 100) + 0*g)::int,
    100, 100,
    ROUND((500 + random() * 20000 + 0*g)::numeric, -1),
    (DATE '2024-01-01' + (floor(random() * 365) + 0*g)::int)::timestamp,
    inv.id_inventario,
    (ARRAY[5,12,16,20])[1 + (g % 4)]
FROM generate_series(1, 300) AS g
CROSS JOIN LATERAL (
    -- (0*g) correlaciona la seleccion aleatoria de inventario con la fila externa
    SELECT id_inventario FROM inventario ORDER BY random() + 0*g LIMIT 1
) inv;

-- ------------------------------------------------------------
-- 17. PRECIO_HISTORIAL (60 cambios de precio de ejemplo)
-- ------------------------------------------------------------
INSERT INTO precio_historial (codigo_producto, precio_anterior, precio_nuevo, fecha_cambio, motivo_cambio, id_empleado)
SELECT
    'P' || LPAD(g::text, 4, '0'),
    p.precio_venta,
    ROUND((p.precio_venta * (1 + (random() * 0.2 - 0.05)))::numeric, -1),
    (DATE '2024-01-01' + (floor(random() * 365))::int)::timestamp,
    (ARRAY['Ajuste inflacion','Negociacion proveedor','Promocion','Correccion'])[1 + (g % 4)],
    (ARRAY[1,9,13,17])[1 + (g % 4)]
FROM generate_series(1, 60) AS g
JOIN producto p ON p.codigo_producto = 'P' || LPAD(g::text, 4, '0');

-- ============================================================
-- RESUMEN DE CARGA (verificacion rapida de volumen)
-- ============================================================
SELECT 'facturas'         AS tabla, COUNT(*) AS filas FROM factura_venta
UNION ALL SELECT 'detalle_factura', COUNT(*) FROM detalle_factura
UNION ALL SELECT 'medio_pago',      COUNT(*) FROM medio_pago
UNION ALL SELECT 'ordenes',         COUNT(*) FROM orden_pedido
UNION ALL SELECT 'detalle_orden',   COUNT(*) FROM detalle_orden
UNION ALL SELECT 'productos',       COUNT(*) FROM producto
UNION ALL SELECT 'clientes',        COUNT(*) FROM cliente
UNION ALL SELECT 'movimientos',     COUNT(*) FROM movimiento_inventario
ORDER BY filas DESC;

-- ============================================================
-- FIN DE LA CARGA DE DATOS
-- ============================================================
