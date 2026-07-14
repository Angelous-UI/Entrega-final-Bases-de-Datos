# DOC_IA.md — Documentación del uso de Inteligencia Artificial

**Proyecto:** Sistema de Gestión Superinter S.A.S.
**Asignatura:** Bases de Datos
**Integrantes:** _(nombre y código de los 2 integrantes)_

Este documento describe **cómo** se utilizó la Inteligencia Artificial (IA) como
herramienta de apoyo durante el desarrollo del proyecto, siguiendo la exigencia
del enunciado de ser **transparentes** sobre su uso.

---

## 1. Herramientas de IA utilizadas

| Herramienta | Uso principal |
|-------------|---------------|
| Asistente de IA (modelo de lenguaje) | Generación y explicación de código Flask, plantillas HTML, consultas SQL y documentación. |

---

## 2. ¿Para qué se usó la IA?

La IA se utilizó como **apoyo**, no como reemplazo del trabajo del equipo. Los usos
concretos fueron:

### 2.1 Aplicación web (Flask)
- Diseño de la **estructura del proyecto** (separación en `app.py`, `config.py`, `db.py`,
  blueprints por entidad y plantillas).
- Generación de la **capa de acceso a datos** con `psycopg` usando **consultas parametrizadas**.
- Creación de los formularios HTML y la navegación entre vistas.
- Implementación de **transacciones** (cabecera + detalle) para facturas y órdenes.

### 2.2 Consultas SQL
- Apoyo para redactar las **10 consultas básicas** y revisar las **10 complejas**.
- Explicación de las técnicas usadas (JOIN, subconsultas, GROUP BY, funciones de agregación).

### 2.3 Documentación
- Redacción de `README.md`, este `DOC_IA.md` y el informe final.

---

## 3. ¿Qué hizo el equipo (no la IA)?

- **Análisis del modelo de datos** y del enunciado del negocio Superinter.
- **Decisión del stack** (Flask + psycopg + PostgreSQL local) y justificación.
- **Selección de las 5 entidades** del CRUD según relevancia para el negocio.
- **Definición de las reglas de negocio** (baja lógica, documentos inmutables,
  integridad referencial mediante listas desplegables).
- **Verificación y pruebas** de cada consulta y de cada operación CRUD contra la
  base de datos real en PostgreSQL.
- **Adaptación del código** generado a los nombres reales de tablas y columnas del
  esquema `superinter`.

---

## 4. Ejemplos de prompts utilizados

A continuación, ejemplos representativos de las instrucciones dadas a la IA:

1. *"Crea una app web CRUD en Flask + psycopg conectada a PostgreSQL local para el
   esquema `superinter`, con 5 entidades: clientes, proveedores, productos, facturas
   y órdenes de pedido."*

2. *"Las facturas y órdenes no se deben poder editar ni eliminar; clientes,
   proveedores y productos deben usar baja lógica."*

3. *"Escribe 10 consultas SQL básicas (una sola tabla, filtros y agregados simples)
   documentadas con su objetivo de negocio."*

4. *"Usa consultas parametrizadas y transacciones para insertar la cabecera y el
   detalle de las facturas."*

---

## 5. Validación y responsabilidad

Todo el código y las consultas generadas con apoyo de IA fueron:

- **Revisados** línea por línea por el equipo.
- **Ajustados** a los nombres reales del esquema (`superinter_ddl.sql`).
- **Probados** en PostgreSQL local antes de la entrega.

El equipo asume la **responsabilidad total** sobre el resultado final y comprende
el funcionamiento de cada parte del proyecto, tal como se demostrará en la sustentación.

---

## 6. Aprendizajes

- Uso de **blueprints** en Flask para organizar un CRUD por entidades.
- Conexión a PostgreSQL con **psycopg** y buenas prácticas (parámetros, transacciones,
  cierre de conexiones).
- Diferencia práctica entre **borrado físico** y **baja lógica**.
- Importancia de la **integridad referencial** en operaciones de inserción.
