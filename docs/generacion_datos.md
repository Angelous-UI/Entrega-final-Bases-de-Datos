# Documentación de la generación de datos sintéticos

**Proyecto:** Sistema de Gestión Superinter S.A.S.
**Archivo asociado:** `sql/superinter_datos.sql`
**Requisito previo:** ejecutar antes `sql/superinter_ddl.sql`

Este documento explica **cómo** se generaron los datos de prueba de la base de
datos, **qué volúmenes** se cargaron y **qué sesgos estadísticos** se
introdujeron a propósito para que las consultas del proyecto arrojen resultados
realistas (y no uniformes/planos).

---

## 1. Enfoque general

Los datos **no** se escribieron a mano fila por fila. Se generaron de forma
**procedimental dentro del propio motor PostgreSQL**, usando:

- **`generate_series(1, N)`** para producir N filas de golpe.
- **`random()`** y **`power(random(), k)`** para introducir variabilidad y
  sesgos controlados.
- **`CROSS JOIN LATERAL`** con el truco `+ 0*g` para **forzar que `random()` se
  reevalúe por fila** (si no se correlaciona la subconsulta con la fila externa,
  PostgreSQL puede calcular el valor aleatorio una sola vez y repetirlo).
- **Recálculo de totales** (subtotales, IVA, descuentos) a partir del detalle,
  para que las cabeceras sean **coherentes** con sus líneas.

Las tablas maestras pequeñas y fijas (sedes, empleados, proveedores, categorías,
marcas, unidades, bodegas, promociones) se cargaron con `INSERT ... VALUES`
explícitos porque su contenido es de negocio y debe ser controlado.

---

## 2. Volúmenes cargados

| Entidad | Cantidad | Método |
|--------|:--------:|--------|
| Sedes | 4 | `VALUES` (Cali, Palmira, Tuluá, Buenaventura) |
| Empleados | 20 | `VALUES` (sesgo hacia Cali) |
| Proveedores | 15 | `VALUES` |
| Categorías | 10 | `VALUES` (jerarquía de 2 niveles) |
| Marcas | 15 | `VALUES` |
| Unidades de medida | 5 | `VALUES` |
| Productos | 80 | `generate_series` |
| Bodegas | 6 | `VALUES` |
| Inventario | ~160 | producto × bodega (central + Cali) |
| Clientes | 200 | `generate_series` |
| Promociones | 8 | `VALUES` |
| Órdenes de pedido | 150 | `generate_series` |
| Detalle de órdenes | ~450 | 2–4 líneas por orden |
| **Facturas de venta** | **~1.200** | `generate_series` (objetivo > 1.000) |
| Detalle de facturas | ~3.600 | 1–5 líneas por factura |
| Pagos (medio_pago) | ~1.200+ | 1 medio por factura, algunas mixtas |

> El objetivo del enunciado (**más de 1.000 transacciones**) se cumple con las
> ~1.200 facturas y sus detalles y pagos asociados.

---

## 3. Sesgos estadísticos intencionales

Para que las 20 consultas produzcan resultados interesantes, se introdujeron
cuatro sesgos deliberados:

### 3.1 Popularidad de productos NO uniforme (distribución exponencial)
En `detalle_factura` el producto de cada línea se elige con
`power(random(), 3)`, lo que **concentra las ventas en los productos de código
bajo** (P0001, P0002, …). Así, unos pocos productos acumulan la mayoría de las
ventas, como ocurre en un supermercado real (principio de Pareto).

### 3.2 Estacionalidad temporal
La fecha de cada factura usa `power(random(), 0.5)` sobre el rango del año 2024,
lo que **concentra más ventas hacia el final del año** (noviembre–diciembre).
Además, la hora se limita al **horario comercial (8:00–20:00)**.

### 3.3 Distribución geográfica sesgada
Las facturas se reparten entre sedes con probabilidades fijas:
**55% Cali, 20% Palmira, 15% Tuluá, 10% Buenaventura**. Cali concentra la mayor
parte de la operación, igual que los empleados.

### 3.4 Medios de pago sesgados
Los pagos se inclinan hacia **efectivo y tarjeta débito**, reflejando el
comportamiento típico del consumidor colombiano, con una minoría de pagos
mixtos (más de un medio por factura).

---

## 4. Coherencia y reglas respetadas

La generación no es puramente aleatoria: respeta reglas de negocio y de
integridad para que los datos sean **válidos y creíbles**:

- **IVA coherente con la categoría** del producto (0% excluidos/exentos como
  frescos, carnes y lácteos; 5% canasta procesada; 19% general).
- **Cajero coherente con la sede** de la factura (cada cajero pertenece a su sede).
- **Totales recalculados** desde el detalle (subtotal, IVA y descuentos), nunca
  inventados en la cabecera.
- **Promociones aplicadas solo si son vigentes** a la fecha de la factura y
  compatibles con la sede, recalculando la base gravable y el IVA con descuento.
- **Limpieza de seguridad:** se eliminan facturas que hubieran quedado sin
  detalle para no dejar cabeceras huérfanas.
- **Integridad referencial:** todas las llaves foráneas (cliente, producto,
  proveedor, sede, empleado, bodega) apuntan a filas existentes.

---

## 5. Cómo reproducir la carga

```bash
# 1. Crear el esquema y las tablas
psql -U postgres -d superinter -f sql/superinter_ddl.sql

# 2. Cargar los datos sintéticos
psql -U postgres -d superinter -f sql/superinter_datos.sql
```

Como `random()` no está fijado con `setseed()`, cada ejecución produce un
conjunto de datos distinto pero con **los mismos sesgos y volúmenes**.

---

## 6. Verificación (consultas de conteo)

Tras la carga se puede validar el resultado con:

```sql
SET search_path TO superinter;

SELECT 'clientes'   AS tabla, COUNT(*) FROM cliente
UNION ALL SELECT 'productos',        COUNT(*) FROM producto
UNION ALL SELECT 'facturas',         COUNT(*) FROM factura_venta
UNION ALL SELECT 'detalle_factura',  COUNT(*) FROM detalle_factura
UNION ALL SELECT 'ordenes',          COUNT(*) FROM orden_pedido;

-- Comprobar el sesgo de popularidad: top 10 productos más vendidos
SELECT codigo_producto, SUM(cantidad) AS unidades
FROM detalle_factura
GROUP BY codigo_producto
ORDER BY unidades DESC
LIMIT 10;

-- Comprobar el sesgo geográfico: facturas por sede
SELECT id_sede, COUNT(*) AS facturas
FROM factura_venta
GROUP BY id_sede
ORDER BY facturas DESC;
```

---

## 7. Capturas de pantalla a incluir (evidencias)

Guardar las imágenes en `docs/evidencias/` y referenciarlas en el informe. Se
recomiendan estas capturas tomadas desde **pgAdmin** (o `psql`):

1. **Ejecución exitosa del DDL** (`superinter_ddl.sql`) — mensaje sin errores y
   el esquema `superinter` con todas sus tablas en el árbol de pgAdmin.
2. **Ejecución exitosa de la carga** (`superinter_datos.sql`) — panel de mensajes
   "Query returned successfully".
3. **Conteo de filas por tabla** — resultado de la consulta `UNION ALL` de la
   sección 6, donde se vea que las facturas superan las 1.000.
4. **Sesgo de popularidad** — resultado del "top 10 productos más vendidos",
   mostrando cantidades claramente decrecientes.
5. **Sesgo geográfico** — resultado de "facturas por sede", mostrando a Cali con
   ~55% del total.
6. **Sesgo temporal** *(opcional pero recomendado)* — facturas por mes:
   ```sql
   SELECT EXTRACT(MONTH FROM fecha_expedicion) AS mes, COUNT(*)
   FROM factura_venta GROUP BY mes ORDER BY mes;
   ```
   para evidenciar el pico de noviembre–diciembre.
7. **Muestra de una factura con su detalle** — una fila de `factura_venta` y sus
   líneas de `detalle_factura`, para evidenciar la coherencia cabecera/detalle y
   el cálculo del IVA.
8. **Muestra de datos maestros** — por ejemplo `SELECT * FROM cliente LIMIT 10;`
   para evidenciar que los campos quedaron poblados (no vacíos).
9. **Completitud de sedes** — `SELECT codigo_sede, nombre_sede, email, horario_apertura,
   horario_cierre, area_m2, num_cajas FROM sede;` para evidenciar que el área en
   metros cuadrados y los horarios ya están registrados.
10. **Completitud de proveedores** — `SELECT nit, razon_social, numero_rut,
    contacto_comercial_email, contacto_cartera_email, contacto_logistico_email
    FROM proveedor LIMIT 10;` para evidenciar los contactos completos.

> Sugerencia de nombres: `01_ddl_ok.png`, `02_datos_ok.png`,
> `03_conteos.png`, `04_top_productos.png`, `05_facturas_por_sede.png`,
> `06_facturas_por_mes.png`, `07_factura_detalle.png`, `08_clientes.png`,
> `09_sedes.png`, `10_proveedores.png`.

## 8. Nota sobre completitud de campos

En una revisión de calidad de datos se detectaron campos opcionales que quedaban
vacíos (`NULL`) y se completaron para que las evidencias no muestren columnas en
blanco:

- **sede**: se agregaron `email`, `horario_apertura`, `horario_cierre` y
  `area_m2` (área proporcional al número de cajas: entre ~620 m² y ~1.850 m²).
- **cliente**: se agregaron `direccion_residencia` (todos) y, solo para clientes
  jurídicos (NIT), `direccion_operativa` y `representante_legal`. En clientes
  naturales estos dos campos permanecen `NULL` intencionalmente, por coherencia
  con el dominio (una persona natural no tiene representante legal).
- **proveedor**: se completaron `numero_rut`, `contacto_comercial_email` y los
  contactos de **cartera** y **logística** mediante un `UPDATE` derivado de los
  datos ya cargados.

## 9. Herramienta de IA utilizada y prompts

**Herramienta:** Claude (Anthropic), a través de la interfaz web claude.ai.

> **Nota de transparencia:** los prompts exactos no quedaron guardados durante
> el desarrollo. Los que se listan a continuación son una **reconstrucción**
> fiel del proceso real seguido (visible en la estructura del propio script
> `superinter_datos.sql`: uso de `generate_series`, sesgos estadísticos,
> `UPDATE` de completitud de campos), y no una transcripción literal.

Prompts reconstruidos, en el orden aproximado en que se usaron:

1. *"Necesito generar datos sintéticos en SQL para PostgreSQL para un proyecto
   de supermercado (Superinter S.A.S.), con al menos 1000 facturas de venta.
   No quiero datos uniformes: quiero que unos pocos productos concentren la
   mayoría de las ventas, que haya más ventas en fin de año y fines de semana,
   y que la sede de Cali concentre más ventas que las demás. ¿Cómo lo hago con
   `generate_series` en vez de escribir cada INSERT a mano?"*

2. *"¿Cómo hago que `random()` se recalcule para cada fila cuando uso
   `CROSS JOIN LATERAL generate_series`? Me está devolviendo el mismo valor
   aleatorio repetido en todas las filas."*

3. *"Necesito que los subtotales, el IVA y el total de cada factura sean
   coherentes con la suma real de sus líneas de detalle, no valores
   inventados aparte. ¿Cómo recalculo eso a partir del detalle ya generado?"*

4. *"Al revisar los datos cargados, veo columnas opcionales en NULL (email y
   horario de las sedes, dirección de residencia de clientes, contactos de
   cartera y logística de proveedores). Ayúdame a completarlas con datos
   derivados coherentes usando UPDATE, sin tener que regenerar todo desde
   cero."*

**Ajuste manual del equipo:** en todos los casos, el equipo adaptó los nombres
de columnas y tablas a los del esquema real (`superinter_ddl.sql`), verificó
que las cantidades generadas (facturas, órdenes, líneas) cumplieran el mínimo
de 1.000 transacciones exigido, y validó manualmente en pgAdmin que los sesgos
(fin de año, concentración en Cali, popularidad de productos) fueran visibles
al ejecutar las consultas de validación.
