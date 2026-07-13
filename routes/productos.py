"""
CRUD de PRODUCTOS / INSUMOS.

Reglas de negocio aplicadas:
- El codigo del producto es la clave primaria y campo critico: se captura al
  crear pero NO se puede editar.
- Eliminacion LOGICA obligatoria: se marca activo = FALSE (nunca DELETE fisico).
- No se puede registrar un producto de un proveedor no registrado: el
  proveedor se elige de una lista desplegable de proveedores activos.
- Al cambiar el precio de venta se guarda el cambio en PRECIO_HISTORIAL.
"""
from flask import Blueprint, render_template, request, redirect, url_for, flash

from db import fetch_all, fetch_one, execute, transaction

bp = Blueprint("productos", __name__, template_folder="../templates")

TARIFAS_IVA = ["0.00", "0.05", "0.19"]


def _catalogos():
    """Trae las listas para los <select> del formulario."""
    return {
        "categorias": fetch_all(
            "SELECT id_categoria, nombre_categoria FROM categoria WHERE activo ORDER BY nombre_categoria"
        ),
        "marcas": fetch_all(
            "SELECT id_marca, nombre_marca FROM marca WHERE activo ORDER BY nombre_marca"
        ),
        "unidades": fetch_all(
            "SELECT id_unidad, nombre_unidad, abreviatura FROM unidad_medida WHERE activo ORDER BY nombre_unidad"
        ),
        "proveedores": fetch_all(
            "SELECT id_proveedor, razon_social FROM proveedor WHERE activo ORDER BY razon_social"
        ),
    }


@bp.route("/")
def listar():
    productos = fetch_all(
        """
        SELECT p.codigo_producto, p.nombre_producto, p.precio_venta, p.tarifa_iva,
               p.stock_minimo, p.activo,
               c.nombre_categoria, pr.razon_social AS proveedor
        FROM producto p
        JOIN categoria c  ON c.id_categoria   = p.id_categoria
        JOIN proveedor pr ON pr.id_proveedor  = p.id_proveedor_principal
        ORDER BY p.activo DESC, p.nombre_producto
        """
    )
    return render_template("productos/list.html", productos=productos)


@bp.route("/<codigo>")
def detalle(codigo):
    producto = fetch_one(
        """
        SELECT p.*, c.nombre_categoria, m.nombre_marca,
               u.nombre_unidad, pr.razon_social AS proveedor
        FROM producto p
        JOIN categoria c  ON c.id_categoria  = p.id_categoria
        LEFT JOIN marca m ON m.id_marca      = p.id_marca
        JOIN unidad_medida u ON u.id_unidad  = p.id_unidad
        JOIN proveedor pr ON pr.id_proveedor = p.id_proveedor_principal
        WHERE p.codigo_producto = %s
        """,
        (codigo,),
    )
    if not producto:
        flash("Producto no encontrado.", "error")
        return redirect(url_for("productos.listar"))
    return render_template("productos/detail.html", producto=producto)


@bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    if request.method == "POST":
        f = request.form
        try:
            execute(
                """
                INSERT INTO producto
                    (codigo_producto, codigo_barras_ean, nombre_producto, descripcion,
                     precio_venta, costo_promedio, tarifa_iva, requiere_refrigeracion,
                     es_perecedero, dias_vida_util, stock_minimo, stock_maximo, punto_reorden,
                     id_categoria, id_marca, id_unidad, id_proveedor_principal)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    f["codigo_producto"].strip(),
                    f.get("codigo_barras_ean") or None,
                    f["nombre_producto"].strip(),
                    f.get("descripcion") or None,
                    f["precio_venta"],
                    f.get("costo_promedio") or 0,
                    f["tarifa_iva"],
                    "requiere_refrigeracion" in f,
                    "es_perecedero" in f,
                    int(f["dias_vida_util"]) if f.get("dias_vida_util") else None,
                    int(f.get("stock_minimo") or 0),
                    int(f["stock_maximo"]) if f.get("stock_maximo") else None,
                    int(f.get("punto_reorden") or 0),
                    int(f["id_categoria"]),
                    int(f["id_marca"]) if f.get("id_marca") else None,
                    int(f["id_unidad"]),
                    int(f["id_proveedor_principal"]),
                ),
            )
            flash("Producto creado correctamente.", "success")
            return redirect(url_for("productos.listar"))
        except Exception as exc:  # noqa: BLE001
            flash(f"No se pudo crear el producto: {exc}", "error")

    return render_template(
        "productos/form.html", producto=None, tarifas=TARIFAS_IVA, **_catalogos()
    )


@bp.route("/<codigo>/editar", methods=["GET", "POST"])
def editar(codigo):
    producto = fetch_one(
        "SELECT * FROM producto WHERE codigo_producto = %s", (codigo,)
    )
    if not producto:
        flash("Producto no encontrado.", "error")
        return redirect(url_for("productos.listar"))

    if request.method == "POST":
        f = request.form
        nuevo_precio = float(f["precio_venta"])
        precio_anterior = float(producto["precio_venta"])
        try:
            # El codigo_producto NO se actualiza (campo critico / PK).
            with transaction() as cur:
                cur.execute(
                    """
                    UPDATE producto SET
                        codigo_barras_ean = %s, nombre_producto = %s, descripcion = %s,
                        precio_venta = %s, costo_promedio = %s, tarifa_iva = %s,
                        requiere_refrigeracion = %s, es_perecedero = %s, dias_vida_util = %s,
                        stock_minimo = %s, stock_maximo = %s, punto_reorden = %s,
                        id_categoria = %s, id_marca = %s, id_unidad = %s,
                        id_proveedor_principal = %s
                    WHERE codigo_producto = %s
                    """,
                    (
                        f.get("codigo_barras_ean") or None,
                        f["nombre_producto"].strip(),
                        f.get("descripcion") or None,
                        nuevo_precio,
                        f.get("costo_promedio") or 0,
                        f["tarifa_iva"],
                        "requiere_refrigeracion" in f,
                        "es_perecedero" in f,
                        int(f["dias_vida_util"]) if f.get("dias_vida_util") else None,
                        int(f.get("stock_minimo") or 0),
                        int(f["stock_maximo"]) if f.get("stock_maximo") else None,
                        int(f.get("punto_reorden") or 0),
                        int(f["id_categoria"]),
                        int(f["id_marca"]) if f.get("id_marca") else None,
                        int(f["id_unidad"]),
                        int(f["id_proveedor_principal"]),
                        codigo,
                    ),
                )
                # Si el precio cambio, dejamos rastro en el historial.
                if nuevo_precio != precio_anterior:
                    cur.execute(
                        """
                        INSERT INTO precio_historial
                            (precio_anterior, precio_nuevo, motivo_cambio, codigo_producto)
                        VALUES (%s, %s, %s, %s)
                        """,
                        (precio_anterior, nuevo_precio, "Edicion desde la app web", codigo),
                    )
            flash("Producto actualizado correctamente.", "success")
            return redirect(url_for("productos.detalle", codigo=codigo))
        except Exception as exc:  # noqa: BLE001
            flash(f"No se pudo actualizar el producto: {exc}", "error")

    return render_template(
        "productos/form.html", producto=producto, tarifas=TARIFAS_IVA, **_catalogos()
    )


@bp.route("/<codigo>/estado", methods=["POST"])
def cambiar_estado(codigo):
    """Eliminacion logica: alterna el campo activo."""
    try:
        execute(
            "UPDATE producto SET activo = NOT activo WHERE codigo_producto = %s",
            (codigo,),
        )
        flash("Estado del producto actualizado (eliminacion logica).", "success")
    except Exception as exc:  # noqa: BLE001
        flash(f"No se pudo cambiar el estado: {exc}", "error")
    return redirect(url_for("productos.listar"))
