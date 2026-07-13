# Informe Final del Proyecto — Bases de Datos

## Sistema de Gestión para Superinter S.A.S.

**Asignatura:** Bases de Datos
**Integrantes:** _(nombre y código de los 2 integrantes)_
**Fecha:** _(fecha de entrega)_
**Repositorio:** _(URL de GitHub)_

---

## 1. Introducción

Superinter S.A.S. es una cadena de supermercados que requiere un sistema para
gestionar su información de clientes, proveedores, productos y sus documentos
comerciales (facturas de venta y órdenes de pedido a proveedores).

Este proyecto implementa:

1. Una **base de datos relacional** en PostgreSQL (esquema `superinter`).
2. Un conjunto de **20 consultas SQL** (10 básicas + 10 complejas).
3. Una **aplicación web CRUD** en Python (Flask) que opera sobre 5 entidades.

---

## 2. Objetivos

### Objetivo general
Diseñar e implementar una solución de base de datos con una aplicación web que
permita administrar la información operativa de Superinter S.A.S.

### Objetivos específicos
- Implementar el esquema relacional con integridad referencial.
- Cargar datos de prueba representativos del negocio.
- Desarrollar 20 consultas SQL que respondan a necesidades reales del negocio.
- Construir una aplicación web CRUD sobre las entidades principales.
- Documentar el proyecto y el uso de herramientas de IA.

---

## 3. Modelo de datos

El esquema `superinter` está compuesto por tablas que modelan:

- **Maestros:** clientes, proveedores, productos, categorías, marcas, unidades de
  medida, bodegas, cajas, empleados, medios de pago.
- **Inventario:** existencias de producto por bodega.
- **Documentos de venta:** facturas y su detalle (líneas), pagos por medio de pago.
- **Documentos de compra:** órdenes de pedido y su detalle.
- **Histórico:** precios de producto a lo largo del tiempo.

> El detalle completo de tablas, columnas, llaves primarias y foráneas está en
> `sql/superinter_ddl.sql`.

### Decisiones de diseño destacadas
- Uso de **llaves foráneas** para garantizar la integridad referencial.
- Separación **cabecera / detalle** en facturas y órdenes (una factura tiene muchas
  líneas).
- **Histórico de precios** en tabla aparte para no perder el valor con el que se
  vendió/compró en cada momento.

---

## 4. Consultas SQL

Se desarrollaron **20 consultas** documentadas (objetivo de negocio + técnica SQL):

### 4.1 Consultas básicas (`sql/superinter_consultas_basicas.sql`)
Operan sobre una sola tabla con filtros, ordenamientos y agregados simples.
Ejemplos de propósito:
- Listado de clientes activos.
- Productos ordenados por precio.
- Conteo de productos por estado.
- Referencias de inventario sin stock disponible.

### 4.2 Consultas complejas (`sql/superinter_consultas_complejas.sql`)
Combinan varias tablas mediante JOIN, subconsultas y agrupaciones. Ejemplos:
- Ventas totales por cliente.
- Productos más vendidos.
- Órdenes de pedido por proveedor con su total.
- Cruces entre facturas, detalle y productos.

---

## 5. Aplicación web

### 5.1 Arquitectura y tecnología

| Capa | Tecnología | Justificación |
|------|------------|---------------|
| Lenguaje | Python 3 | Lenguaje conocido por el equipo. |
| Framework web | **Flask** | Ligero y explícito; permite entender y defender cada parte del código. |
| Driver BD | **psycopg** | Conexión directa a PostgreSQL con consultas parametrizadas. |
| Plantillas | Jinja2 | Motor de plantillas integrado en Flask. |
| Base de datos | PostgreSQL | Motor relacional requerido por el proyecto. |

**¿Por qué Flask y no un ORM/framework más pesado?**
Se eligió Flask con SQL directo para tener **control total sobre las consultas**
y poder explicar en la sustentación exactamente qué SQL se ejecuta en cada
operación, sin la "magia" de un ORM.

### 5.2 Organización del código

- `app.py` — crea la app y registra los *blueprints*.
- `config.py` — lee la configuración desde `.env`.
- `db.py` — gestiona la conexión y expone helpers (`fetch_all`, `fetch_one`, `execute`).
- `routes/` — un *blueprint* por entidad (clientes, proveedores, productos, facturas, órdenes).
- `templates/` — vistas HTML organizadas por entidad.
- `static/css/` — estilos.

### 5.3 Entidades del CRUD

| Entidad | Crear | Listar | Ver | Editar | Eliminar |
|---------|:-----:|:------:|:---:|:------:|:--------:|
| Clientes | Sí | Sí | Sí | Sí | Baja lógica |
| Proveedores | Sí | Sí | Sí | Sí | Baja lógica |
| Productos | Sí | Sí | Sí | Sí | Baja lógica |
| Facturas | Sí | Sí | Sí | No | No |
| Órdenes de pedido | Sí | Sí | Sí | No | No |

### 5.4 Reglas de negocio implementadas
- **Baja lógica** (no borrado físico) en maestros para conservar el histórico.
- **Documentos inmutables**: facturas y órdenes no se editan ni eliminan.
- **Integridad referencial** en la interfaz: las relaciones se eligen desde
  listas desplegables (nunca se escriben IDs a mano).
- **Transacciones** para insertar cabecera + detalle de forma atómica.
- **Consultas parametrizadas** para prevenir inyección SQL.

---

## 6. Pruebas realizadas

- Verificación de que la aplicación importa y registra correctamente las 22 rutas.
- Compilación sin errores de todas las plantillas Jinja2.
- Pruebas manuales de cada operación CRUD contra PostgreSQL local:
  crear, listar, ver, editar y dar de baja en maestros; crear y consultar
  facturas y órdenes con su detalle.
- Ejecución y verificación de las 20 consultas SQL.

---

## 7. Conclusiones

- Se implementó una solución completa: base de datos, consultas y aplicación web.
- La separación cabecera/detalle y la baja lógica reflejan necesidades reales de
  un negocio de retail.
- Flask con SQL directo resultó adecuado para un equipo pequeño y para poder
  **explicar y defender** cada parte del sistema.
- El uso de IA se limitó a apoyo y aceleración, con revisión y validación humana
  (ver `DOC_IA.md`).

---

## 8. Anexos

- `sql/superinter_ddl.sql` — esquema y tablas.
- `sql/superinter_datos.sql` — datos de prueba.
- `sql/superinter_consultas_basicas.sql` — 10 consultas básicas.
- `sql/superinter_consultas_complejas.sql` — 10 consultas complejas.
- `README.md` — instrucciones de instalación y ejecución.
- `DOC_IA.md` — documentación del uso de IA.
