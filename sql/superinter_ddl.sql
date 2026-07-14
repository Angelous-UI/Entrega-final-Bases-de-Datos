-- ============================================================
-- SUPERINTER S.A.S. - AVANCE 3
-- CODIGO DDL (PostgreSQL) - Modelo Logico Relacional
-- Modelo corregido: 19 entidades (sin USUARIO_SISTEMA ni RECEPCION_MERCANCIA)
-- ============================================================
-- Ejecutar sobre una base de datos vacia. Compatible con PostgreSQL 13+.
-- Orden de creacion respeta las dependencias de claves foraneas.
-- Las dependencias circulares (SEDE <-> EMPLEADO) se resuelven con ALTER TABLE.
-- ============================================================

-- Limpieza previa (permite re-ejecutar el script)
DROP SCHEMA IF EXISTS superinter CASCADE;
CREATE SCHEMA superinter;
SET search_path TO superinter;

-- ============================================================
-- DOMINIO: SEDES Y RECURSOS HUMANOS
-- ============================================================

-- SEDE (id_administrador se enlaza luego por dependencia circular con EMPLEADO)
CREATE TABLE sede (
    id_sede            SERIAL       PRIMARY KEY,
    codigo_sede        VARCHAR(10)  NOT NULL UNIQUE,
    nombre_sede        VARCHAR(100) NOT NULL,
    ciudad             VARCHAR(50)  NOT NULL,
    direccion          VARCHAR(200) NOT NULL,
    telefono           VARCHAR(20),
    email              VARCHAR(100),
    horario_apertura   TIME,
    horario_cierre     TIME,
    area_m2            NUMERIC(10,2),
    num_cajas          SMALLINT     DEFAULT 1,
    fecha_apertura     DATE,
    activo             BOOLEAN      NOT NULL DEFAULT TRUE,
    id_administrador   INTEGER      -- FK a EMPLEADO, se agrega mas abajo
);

-- EMPLEADO
CREATE TABLE empleado (
    id_empleado        SERIAL       PRIMARY KEY,
    tipo_documento     VARCHAR(3)   NOT NULL CHECK (tipo_documento IN ('CC','CE')),
    numero_documento   VARCHAR(20)  NOT NULL UNIQUE,
    primer_nombre      VARCHAR(50)  NOT NULL,
    segundo_nombre     VARCHAR(50),
    primer_apellido    VARCHAR(50)  NOT NULL,
    segundo_apellido   VARCHAR(50),
    fecha_nacimiento   DATE         NOT NULL,
    genero             VARCHAR(1)   CHECK (genero IN ('M','F','O')),
    direccion          VARCHAR(200) NOT NULL,
    telefono           VARCHAR(20)  NOT NULL,
    email              VARCHAR(100),
    cargo              VARCHAR(50)  NOT NULL,
    rol_operativo      VARCHAR(30)  NOT NULL
                       CHECK (rol_operativo IN ('ADMIN','SUPERVISOR','CAJERO','BODEGUERO','AUDITOR')),
    tipo_contrato      VARCHAR(30)  CHECK (tipo_contrato IN ('INDEFINIDO','FIJO','OBRA_LABOR','PRESTACION_SERVICIOS')),
    fecha_ingreso      DATE         NOT NULL,
    fecha_retiro       DATE,
    salario_base       NUMERIC(12,2) NOT NULL CHECK (salario_base >= 0),
    activo             BOOLEAN      NOT NULL DEFAULT TRUE,
    id_sede            INTEGER      NOT NULL REFERENCES sede(id_sede)
);

-- Resolver dependencia circular: SEDE.id_administrador -> EMPLEADO
ALTER TABLE sede
    ADD CONSTRAINT fk_sede_administrador
    FOREIGN KEY (id_administrador) REFERENCES empleado(id_empleado);

-- ============================================================
-- DOMINIO: TERCEROS
-- ============================================================

-- CLIENTE
CREATE TABLE cliente (
    id_cliente             SERIAL       PRIMARY KEY,
    tipo_documento         VARCHAR(3)   NOT NULL CHECK (tipo_documento IN ('CC','NIT','CE')),
    numero_documento       VARCHAR(20)  NOT NULL UNIQUE,
    nombre_completo        VARCHAR(150) NOT NULL,
    habeas_data            BOOLEAN      NOT NULL DEFAULT FALSE,
    ciudad                 VARCHAR(50)  NOT NULL,
    direccion_operativa    VARCHAR(200),
    direccion_residencia   VARCHAR(200),
    telefono               VARCHAR(20),
    email                  VARCHAR(100),
    representante_legal    VARCHAR(150),
    tipo_regimen           VARCHAR(30)  CHECK (tipo_regimen IN ('RESPONSABLE_IVA','NO_RESPONSABLE_IVA')),
    canal_venta_preferido  VARCHAR(30)  CHECK (canal_venta_preferido IN ('PRESENCIAL','DOMICILIO','WEB')),
    fecha_registro         DATE         NOT NULL DEFAULT CURRENT_DATE,
    activo                 BOOLEAN      NOT NULL DEFAULT TRUE
);

-- PROVEEDOR
CREATE TABLE proveedor (
    id_proveedor               SERIAL       PRIMARY KEY,
    nit                        VARCHAR(20)  NOT NULL UNIQUE,
    razon_social               VARCHAR(150) NOT NULL,
    numero_rut                 VARCHAR(20),
    banco                      VARCHAR(50),
    tipo_cuenta                VARCHAR(20)  CHECK (tipo_cuenta IN ('AHORROS','CORRIENTE')),
    numero_cuenta              VARCHAR(30),
    contacto_comercial_nombre  VARCHAR(100),
    contacto_comercial_tel     VARCHAR(20),
    contacto_comercial_email   VARCHAR(100),
    contacto_cartera_nombre    VARCHAR(100),
    contacto_cartera_tel       VARCHAR(20),
    contacto_cartera_email     VARCHAR(100),
    contacto_logistico_nombre  VARCHAR(100),
    contacto_logistico_tel     VARCHAR(20),
    contacto_logistico_email   VARCHAR(100),
    tiempo_entrega_dias        SMALLINT     DEFAULT 0,
    condiciones_pago_dias      SMALLINT     DEFAULT 30,
    calificacion               SMALLINT     CHECK (calificacion BETWEEN 1 AND 5),
    activo                     BOOLEAN      NOT NULL DEFAULT TRUE
);

-- ============================================================
-- DOMINIO: CATALOGO DE PRODUCTOS
-- ============================================================

-- CATEGORIA (jerarquia autoreferenciada)
CREATE TABLE categoria (
    id_categoria         SERIAL       PRIMARY KEY,
    codigo_categoria     VARCHAR(10)  NOT NULL UNIQUE,
    nombre_categoria     VARCHAR(100) NOT NULL,
    descripcion          TEXT,
    nivel                SMALLINT     NOT NULL DEFAULT 1,
    activo               BOOLEAN      NOT NULL DEFAULT TRUE,
    id_categoria_padre   INTEGER      REFERENCES categoria(id_categoria)
);

-- MARCA
CREATE TABLE marca (
    id_marca       SERIAL       PRIMARY KEY,
    nombre_marca   VARCHAR(100) NOT NULL UNIQUE,
    descripcion    TEXT,
    pais_origen    VARCHAR(50),
    logo_url       VARCHAR(255),
    activo         BOOLEAN      NOT NULL DEFAULT TRUE
);

-- UNIDAD_MEDIDA
CREATE TABLE unidad_medida (
    id_unidad      SERIAL       PRIMARY KEY,
    codigo_unidad  VARCHAR(10)  NOT NULL UNIQUE,
    nombre_unidad  VARCHAR(50)  NOT NULL,
    abreviatura    VARCHAR(10)  NOT NULL,
    tipo           VARCHAR(20)  CHECK (tipo IN ('CANTIDAD','PESO','VOLUMEN','LONGITUD')),
    activo         BOOLEAN      NOT NULL DEFAULT TRUE
);

-- PRODUCTO
CREATE TABLE producto (
    codigo_producto         VARCHAR(20)  PRIMARY KEY,
    codigo_barras_ean       VARCHAR(20)  UNIQUE,
    nombre_producto         VARCHAR(150) NOT NULL,
    descripcion             TEXT,
    precio_venta            NUMERIC(12,2) NOT NULL CHECK (precio_venta > 0),
    costo_promedio          NUMERIC(12,2) DEFAULT 0,
    -- tarifa_iva: 0.19 general, 0.05 diferencial (canasta procesada),
    -- 0.00 agrupa bienes EXENTOS y EXCLUIDOS (ambos no suman IVA a la venta).
    tarifa_iva              NUMERIC(4,2) NOT NULL CHECK (tarifa_iva IN (0.00, 0.05, 0.19)),
    peso_neto               NUMERIC(10,3),
    volumen                 NUMERIC(10,3),
    requiere_refrigeracion  BOOLEAN      DEFAULT FALSE,
    es_perecedero           BOOLEAN      DEFAULT FALSE,
    dias_vida_util          SMALLINT,
    stock_minimo            INTEGER      DEFAULT 0,
    stock_maximo            INTEGER,
    punto_reorden           INTEGER      DEFAULT 0,
    fecha_creacion          DATE         NOT NULL DEFAULT CURRENT_DATE,
    activo                  BOOLEAN      NOT NULL DEFAULT TRUE,
    id_categoria            INTEGER      NOT NULL REFERENCES categoria(id_categoria),
    id_marca                INTEGER      REFERENCES marca(id_marca),
    id_unidad               INTEGER      NOT NULL REFERENCES unidad_medida(id_unidad),
    id_proveedor_principal  INTEGER      NOT NULL REFERENCES proveedor(id_proveedor)
);

-- PRECIO_HISTORIAL
CREATE TABLE precio_historial (
    id_historial     SERIAL        PRIMARY KEY,
    precio_anterior  NUMERIC(12,2) NOT NULL,
    precio_nuevo     NUMERIC(12,2) NOT NULL,
    fecha_cambio     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo_cambio    VARCHAR(100),
    codigo_producto  VARCHAR(20)   NOT NULL REFERENCES producto(codigo_producto),
    id_empleado      INTEGER       REFERENCES empleado(id_empleado)
);

-- ============================================================
-- DOMINIO: INVENTARIOS
-- ============================================================

-- BODEGA
CREATE TABLE bodega (
    id_bodega               SERIAL       PRIMARY KEY,
    codigo_bodega           VARCHAR(10)  NOT NULL UNIQUE,
    nombre_bodega           VARCHAR(100) NOT NULL,
    tipo_bodega             VARCHAR(30)  CHECK (tipo_bodega IN ('CENTRAL','LOCAL','REFRIGERADA','TRANSITO')),
    direccion               VARCHAR(200),
    capacidad_m3            NUMERIC(10,2),
    temperatura_controlada  BOOLEAN      DEFAULT FALSE,
    temperatura_min         NUMERIC(5,2),
    temperatura_max         NUMERIC(5,2),
    activo                  BOOLEAN      NOT NULL DEFAULT TRUE,
    id_sede                 INTEGER      REFERENCES sede(id_sede),      -- NULL = bodega independiente
    id_responsable          INTEGER      REFERENCES empleado(id_empleado)
);

-- INVENTARIO
CREATE TABLE inventario (
    id_inventario             SERIAL        PRIMARY KEY,
    stock_actual              INTEGER       NOT NULL DEFAULT 0 CHECK (stock_actual >= 0),
    stock_reservado           INTEGER       DEFAULT 0,
    demanda_diaria_promedio   NUMERIC(10,2) DEFAULT 0,
    fecha_ultima_entrada      DATE,
    fecha_ultima_salida       DATE,
    fecha_ultimo_conteo       DATE,
    codigo_producto           VARCHAR(20)   NOT NULL REFERENCES producto(codigo_producto),
    id_bodega                 INTEGER       NOT NULL REFERENCES bodega(id_bodega),
    CONSTRAINT uq_inventario_producto_bodega UNIQUE (codigo_producto, id_bodega)
);

-- MOVIMIENTO_INVENTARIO
CREATE TABLE movimiento_inventario (
    id_movimiento         SERIAL        PRIMARY KEY,
    tipo_movimiento       VARCHAR(20)   NOT NULL
                          CHECK (tipo_movimiento IN ('ENTRADA','SALIDA','AJUSTE_POSITIVO','AJUSTE_NEGATIVO','TRANSFERENCIA')),
    cantidad              INTEGER       NOT NULL CHECK (cantidad > 0),
    stock_anterior        INTEGER       NOT NULL,
    stock_posterior       INTEGER       NOT NULL,
    costo_unitario        NUMERIC(12,2),
    fecha_movimiento      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    documento_referencia  VARCHAR(50),
    motivo                TEXT,
    id_inventario         INTEGER       NOT NULL REFERENCES inventario(id_inventario),
    id_empleado           INTEGER       NOT NULL REFERENCES empleado(id_empleado),
    id_bodega_destino     INTEGER       REFERENCES bodega(id_bodega)
);

-- ============================================================
-- DOMINIO: PROMOCIONES
-- ============================================================

-- PROMOCION
CREATE TABLE promocion (
    id_promocion            SERIAL       PRIMARY KEY,
    codigo_promocion        VARCHAR(20)  NOT NULL UNIQUE,
    nombre_promocion        VARCHAR(100) NOT NULL,
    descripcion             TEXT,
    tipo_promocion          VARCHAR(30)  NOT NULL
                            CHECK (tipo_promocion IN ('DESCUENTO_PORCENTAJE','DESCUENTO_VALOR','NxM','PRECIO_ESPECIAL','COMBO')),
    valor_descuento         NUMERIC(10,2),
    cantidad_minima         INTEGER      DEFAULT 1,
    cantidad_gratis         INTEGER,
    precio_especial         NUMERIC(12,2),
    fecha_inicio            DATE         NOT NULL,
    fecha_fin               DATE         NOT NULL,
    dias_semana_aplicables  VARCHAR(20),
    hora_inicio             TIME,
    hora_fin                TIME,
    limite_uso_total        INTEGER,
    limite_uso_cliente      INTEGER,
    activo                  BOOLEAN      NOT NULL DEFAULT TRUE,
    id_sede                 INTEGER      REFERENCES sede(id_sede),   -- NULL = aplica a todas las sedes
    CONSTRAINT chk_promocion_fechas CHECK (fecha_fin >= fecha_inicio)
);

-- PROMOCION_PRODUCTO (asociativa)
CREATE TABLE promocion_producto (
    id_promocion     INTEGER      NOT NULL REFERENCES promocion(id_promocion),
    codigo_producto  VARCHAR(20)  NOT NULL REFERENCES producto(codigo_producto),
    CONSTRAINT pk_promocion_producto PRIMARY KEY (id_promocion, codigo_producto)
);

-- ============================================================
-- DOMINIO: COMPRAS Y APROVISIONAMIENTO
-- ============================================================

-- ORDEN_PEDIDO (incluye recepcion como atributos: fecha_recepcion, numero_remision)
CREATE TABLE orden_pedido (
    num_orden               SERIAL       PRIMARY KEY,
    fecha_pedido            DATE         NOT NULL DEFAULT CURRENT_DATE,
    fecha_entrega_esperada  DATE,
    estado                  VARCHAR(20)  NOT NULL DEFAULT 'PENDIENTE'
                            CHECK (estado IN ('PENDIENTE','APROBADO','ENVIADO','RECIBIDO','PARCIAL','CANCELADO')),
    subtotal                NUMERIC(14,2) NOT NULL DEFAULT 0,
    valor_iva               NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_orden             NUMERIC(14,2) NOT NULL DEFAULT 0,
    observaciones           TEXT,
    fecha_aprobacion        TIMESTAMP,
    fecha_recepcion         DATE,                  -- recepcion como atributo (ex RECEPCION_MERCANCIA)
    numero_remision         VARCHAR(50),           -- documento de entrega del proveedor
    id_proveedor            INTEGER      NOT NULL REFERENCES proveedor(id_proveedor),
    id_bodega_destino       INTEGER      NOT NULL REFERENCES bodega(id_bodega),
    id_empleado_solicita    INTEGER      NOT NULL REFERENCES empleado(id_empleado),
    id_empleado_aprueba     INTEGER      REFERENCES empleado(id_empleado)
);

-- DETALLE_ORDEN
CREATE TABLE detalle_orden (
    id_detalle_orden     SERIAL        PRIMARY KEY,
    cantidad_solicitada  INTEGER       NOT NULL CHECK (cantidad_solicitada >= 1),
    cantidad_recibida    INTEGER       DEFAULT 0,
    costo_unitario       NUMERIC(12,2) NOT NULL,
    tarifa_iva           NUMERIC(4,2)  NOT NULL DEFAULT 0.19
                         CHECK (tarifa_iva IN (0.00, 0.05, 0.19)),
    subtotal_linea       NUMERIC(14,2) NOT NULL,
    iva_linea            NUMERIC(14,2) NOT NULL,
    total_linea          NUMERIC(14,2) NOT NULL,
    num_orden            INTEGER       NOT NULL REFERENCES orden_pedido(num_orden),
    codigo_producto      VARCHAR(20)   NOT NULL REFERENCES producto(codigo_producto)
);

-- ============================================================
-- DOMINIO: VENTAS Y FACTURACION
-- ============================================================

-- FACTURA_VENTA
CREATE TABLE factura_venta (
    id_factura           SERIAL        PRIMARY KEY,
    numero_factura_dian  VARCHAR(20)   NOT NULL UNIQUE,
    prefijo_dian         VARCHAR(10)   NOT NULL,
    resolucion_dian      VARCHAR(50),
    vigencia_resolucion  DATE,
    fecha_generacion     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expedicion     TIMESTAMP     NOT NULL,
    subtotal             NUMERIC(14,2) NOT NULL,
    valor_total_iva      NUMERIC(14,2) NOT NULL,
    valor_descuento      NUMERIC(14,2) DEFAULT 0,
    total_pagar          NUMERIC(14,2) NOT NULL,
    estado               VARCHAR(20)   DEFAULT 'EMITIDA'
                         CHECK (estado IN ('EMITIDA','ANULADA','NOTA_CREDITO')),
    cufe                 VARCHAR(100),
    qr_code              TEXT,
    id_cliente           INTEGER       NOT NULL REFERENCES cliente(id_cliente),
    id_sede              INTEGER       NOT NULL REFERENCES sede(id_sede),
    id_cajero            INTEGER       NOT NULL REFERENCES empleado(id_empleado)
);

-- DETALLE_FACTURA
CREATE TABLE detalle_factura (
    id_detalle             SERIAL        PRIMARY KEY,
    cantidad               INTEGER       NOT NULL CHECK (cantidad >= 1),
    valor_unitario         NUMERIC(12,2) NOT NULL,
    tarifa_iva_aplicada    NUMERIC(4,2)  NOT NULL CHECK (tarifa_iva_aplicada IN (0.00, 0.05, 0.19)),
    porcentaje_descuento   NUMERIC(5,2)  DEFAULT 0,
    valor_descuento        NUMERIC(14,2) DEFAULT 0,
    subtotal_linea         NUMERIC(14,2) NOT NULL,
    iva_linea              NUMERIC(14,2) NOT NULL,
    total_linea            NUMERIC(14,2) NOT NULL,
    id_factura             INTEGER       NOT NULL REFERENCES factura_venta(id_factura),
    codigo_producto        VARCHAR(20)   NOT NULL REFERENCES producto(codigo_producto),
    id_promocion           INTEGER       REFERENCES promocion(id_promocion)
);

-- MEDIO_PAGO (generico: efectivo, PSE, QR/transfiYa, tarjeta, transferencia)
CREATE TABLE medio_pago (
    id_pago                 SERIAL        PRIMARY KEY,
    tipo_pago               VARCHAR(30)   NOT NULL
                            CHECK (tipo_pago IN ('EFECTIVO','TARJETA_DEBITO','TARJETA_CREDITO','PSE','QR','TRANSFERENCIA','BONO')),
    valor_pago              NUMERIC(14,2) NOT NULL CHECK (valor_pago > 0),
    valor_recibido          NUMERIC(14,2),          -- solo efectivo
    valor_cambio            NUMERIC(14,2) DEFAULT 0, -- solo efectivo
    entidad_financiera      VARCHAR(50),            -- banco/billetera: PSE, Nequi, Daviplata, transfiYa
    referencia_transaccion  VARCHAR(50),            -- codigo de aprobacion / referencia electronica
    numero_cuotas           SMALLINT      DEFAULT 1, -- solo tarjeta credito
    fecha_pago              TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_factura              INTEGER       NOT NULL REFERENCES factura_venta(id_factura)
);

-- ============================================================
-- INDICES DE APOYO PARA CONSULTAS ANALITICAS
-- ============================================================
CREATE INDEX idx_factura_fecha    ON factura_venta(fecha_expedicion);
CREATE INDEX idx_factura_cliente  ON factura_venta(id_cliente);
CREATE INDEX idx_factura_sede     ON factura_venta(id_sede);
CREATE INDEX idx_detfact_producto ON detalle_factura(codigo_producto);
CREATE INDEX idx_detfact_factura  ON detalle_factura(id_factura);
CREATE INDEX idx_producto_categoria ON producto(id_categoria);
CREATE INDEX idx_pago_factura     ON medio_pago(id_factura);

-- ============================================================
-- FIN DEL DDL
-- ============================================================
