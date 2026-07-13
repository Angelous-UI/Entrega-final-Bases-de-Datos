# Superinter S.A.S. — Sistema de Gestión (Proyecto Bases de Datos)

Aplicación web CRUD desarrollada en **Python + Flask** conectada a **PostgreSQL**,
para la gestión de la cadena de supermercados **Superinter S.A.S.**

Este repositorio contiene:

1. **Scripts SQL** (DDL, datos, 20 consultas: 10 básicas + 10 complejas).
2. **Aplicación web CRUD** sobre 5 entidades del negocio.
3. Documentación del proyecto (`README.md`, `DOC_IA.md`, informe).

---

## Tabla de contenido

- [Requisitos](#requisitos)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Instalación paso a paso](#instalación-paso-a-paso)
- [Configuración de la base de datos](#configuración-de-la-base-de-datos)
- [Ejecución de la aplicación](#ejecución-de-la-aplicación)
- [Entidades del CRUD](#entidades-del-crud)
- [Consultas SQL](#consultas-sql)
- [Reglas de negocio implementadas](#reglas-de-negocio-implementadas)
- [Integrantes](#integrantes)

---

## Requisitos

- **Python 3.10+**
- **PostgreSQL 14+** (con pgAdmin, ejecutándose en `localhost`)
- Navegador web

---

## Estructura del proyecto

```
superinter/
├── app.py                  # Punto de entrada Flask (registra blueprints)
├── config.py               # Lee variables de entorno (.env)
├── db.py                   # Conexión y helpers de consulta con psycopg
├── requirements.txt        # Dependencias de Python
├── .env.example            # Plantilla de variables de entorno
├── .gitignore
├── README.md
├── DOC_IA.md               # Documentación del uso de IA
│
├── routes/                 # Blueprints (un archivo por entidad)
│   ├── clientes.py
│   ├── proveedores.py
│   ├── productos.py
│   ├── facturas.py
│   └── ordenes.py
│
├── templates/              # Vistas HTML (Jinja2)
│   ├── base.html
│   ├── index.html
│   ├── clientes/
│   ├── proveedores/
│   ├── productos/
│   ├── facturas/
│   └── ordenes/
│
├── static/css/styles.css   # Estilos
│
└── sql/
    ├── superinter_ddl.sql              # Creación del esquema y tablas
    ├── superinter_datos.sql            # Datos de prueba
    ├── superinter_consultas_basicas.sql    # 10 consultas básicas
    └── superinter_consultas_complejas.sql  # 10 consultas complejas
```

---

## Instalación paso a paso

### 1. Clonar el repositorio

```bash
git clone https://github.com/USUARIO/superinter.git
cd superinter
```

### 2. Crear y activar un entorno virtual

**Windows (PowerShell):**
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

**Linux / macOS:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

---

## Configuración de la base de datos

### 1. Crear la base de datos en PostgreSQL

Desde **pgAdmin** o `psql`, crea una base de datos (por ejemplo `superinter`):

```sql
CREATE DATABASE superinter;
```

### 2. Cargar el esquema y los datos

Ejecuta, en orden, los scripts de la carpeta `sql/` sobre la base `superinter`:

1. `sql/superinter_ddl.sql`   → crea el esquema `superinter` y las tablas.
2. `sql/superinter_datos.sql` → inserta los datos de prueba.

Puedes hacerlo desde pgAdmin (Query Tool → abrir archivo → ejecutar) o por consola:

```bash
psql -U postgres -d superinter -f sql/superinter_ddl.sql
psql -U postgres -d superinter -f sql/superinter_datos.sql
```

### 3. Configurar las variables de entorno

Copia la plantilla y edítala con tus credenciales locales:

```bash
cp .env.example .env
```

Contenido de `.env` (ajusta según tu instalación de PostgreSQL):

```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=superinter
DB_USER=postgres
DB_PASSWORD=tu_contraseña
DB_SCHEMA=superinter
SECRET_KEY=cambia-esta-clave
```

> El archivo `.env` **no se sube a GitHub** (está en `.gitignore`) porque contiene credenciales.

---

## Ejecución de la aplicación

Con el entorno virtual activo y el `.env` configurado:

```bash
python app.py
```

La aplicación quedará disponible en:

```
http://localhost:5000
```

La página de inicio muestra el estado de conexión a la base de datos.

---

## Entidades del CRUD

La aplicación gestiona **5 entidades** del modelo de Superinter:

| Entidad         | Operaciones                        | Notas de negocio |
|-----------------|------------------------------------|------------------|
| **Clientes**    | Crear, Listar, Ver, Editar, Baja   | Baja lógica (no se borra físicamente). Documento no editable. |
| **Proveedores** | Crear, Listar, Ver, Editar, Baja   | Baja lógica. NIT no editable. |
| **Productos**   | Crear, Listar, Ver, Editar, Baja   | Baja lógica. Código no editable. Registra histórico de precios. |
| **Facturas**    | Crear, Listar, Ver                 | Documento contable: **no se edita ni se elimina**. Incluye líneas de detalle. |
| **Órdenes de pedido** | Crear, Listar, Ver           | Documento a proveedor: **no se edita ni se elimina**. Incluye líneas de detalle. |

---

## Consultas SQL

En la carpeta `sql/` se incluyen **20 consultas** documentadas:

- **10 consultas básicas** (`superinter_consultas_basicas.sql`): filtros, ordenamientos,
  agregados simples sobre una sola tabla.
- **10 consultas complejas** (`superinter_consultas_complejas.sql`): JOINs de varias tablas,
  subconsultas, agrupaciones y funciones de agregación aplicadas al negocio.

Cada consulta está comentada con: **objetivo de negocio** y **técnica SQL** utilizada.

---

## Reglas de negocio implementadas

- **Integridad referencial:** las relaciones (cliente-factura, proveedor-producto,
  producto-línea, etc.) se seleccionan desde listas desplegables, nunca escribiendo IDs a mano.
- **Baja lógica** en clientes, proveedores y productos: se marca como inactivo en vez de borrar,
  para preservar el histórico de facturas y órdenes.
- **Documentos inmutables:** facturas y órdenes de pedido no se pueden editar ni eliminar
  una vez creadas.
- **Transacciones:** la creación de facturas y órdenes (cabecera + detalle) se hace dentro de
  una transacción; si algo falla, se revierte todo (`ROLLBACK`).
- **Consultas parametrizadas:** todo acceso a datos usa parámetros para evitar inyección SQL.

---

## Integrantes

- Integrante 1 — _(nombre y código)_
- Integrante 2 — _(nombre y código)_

Proyecto para la asignatura de **Bases de Datos**.
