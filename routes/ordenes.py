"""
Gestion de ORDENES DE PEDIDO (compras a proveedores).

Reglas de negocio aplicadas:
- Una orden, una vez guardada, NO se puede editar ni eliminar.
  Este modulo solo expone: listar, ver detalle y crear.
- No se puede crear una orden de un proveedor no registrado: el proveedor se
  elige de una lista desplegable de proveedores activos.
- Solo se piden productos ya registrados (lista desplegable de productos).
- La orden se guarda de forma atomica con sus lineas de detalle (transaccion).
- Los totales se calculan en el servidor.
"""
from datetime import date
from decimal import Decimal

from flask import Blueprint, render_template, request, redirect, url_for, flash

from db import fetch_all, fetch_one, transaction

bp = Blueprint("ordenes", __name__, template_folder="../templates")


@bp.route("/")
def listar():
    ordenes = fetch_all(
        """
        SELECT o.num_orden, o.fecha_pedido, o.fecha_entrega_esperada, o.estado,
               o.total_orden, pr.razon_social AS proveedor, b.nombre_bodega
        FROM orden_pedido o
        JOIN proveedor pr ON pr.id_proveedor = o.id_proveedor
        JOIN bodega b     ON b.id_bodega     = o.id_bodega_destino
        ORDER BY o.fecha_pedido DESC, o.num_orden DESC
        """
    )
    return render_template("ordenes/list.html", ordenes=ordenes)


@bp.route("/<int:num_orden>")
def detalle(num_orden):
    orden = fetch_one(
        """
        SELECT o.*, pr.razon_social AS proveedor, pr.nit,
               b.nombre_bodega,
               e.primer_nombre || ' ' || e.primer_apellido AS solicitante
        FROM orden_pedido o
        JOIN proveedor pr ON pr.id_proveedor = o.id_proveedor
        JOIN bodega b     ON b.id_bodega     = o.id_bodega_destino
        JOIN empleado e   ON e.id_empleado   = o.id_empleado_solicita
        WHERE o.num_orden = %s
        """,
        (num_orden,),
    )
    if not orden:
        flash("Orden no encontrada.", "error")
        return redirect(url_for("ordenes.listar"))

    lineas = fetch_all(
        """
        SELECT d.*, p.nombre_producto
        FROM detalle_orden d
        JOIN producto p ON p.codigo_producto = d.codigo_producto
        WHERE d.num_orden = %s
        ORDER BY d.id_detalle_orden
        """,
        (num_orden,),
    )
    return render_template("ordenes/detail.html", orden=orden, lineas=lineas)


@bp.route("/nueva", methods=["GET", "POST"])
def crear():
    if request.method == "POST":
        f = request.form
        codigos = f.getlist("codigo_producto")
        cantidades = f.getlist("cantidad_solicitada")
        costos = f.getlist("costo_unitario")

        items = []
        for c, q, costo in zip(codigos, cantidades, costos):
            if c and q and int(q) > 0:
                items.append((c, int(q), Decimal(costo or "0")))
        if not items:
            flash("Debe agregar al menos un producto a la orden.", "error")
            return redirect(url_for("ordenes.crear"))

        try:
            with transaction() as cur:
                subtotal = Decimal("0")
                total_iva = Decimal("0")
                lineas_calculadas = []
                for codigo, cantidad, costo in items:
                    cur.execute(
                        "SELECT tarifa_iva FROM producto WHERE codigo_producto = %s AND activo",
                        (codigo,),
                    )
                    prod = cur.fetchone()
                    if not prod:
                        raise ValueError(f"Producto {codigo} inexistente o inactivo.")
                    tarifa = prod["tarifa_iva"]
                    sub_linea = costo * cantidad
                    iva_linea = (sub_linea * tarifa).quantize(Decimal("0.01"))
                    total_linea = sub_linea + iva_linea
                    subtotal += sub_linea
                    total_iva += iva_linea
                    lineas_calculadas.append(
                        (codigo, cantidad, costo, tarifa, sub_linea, iva_linea, total_linea)
                    )

                total_orden = subtotal + total_iva

                cur.execute(
                    """
                    INSERT INTO orden_pedido
                        (fecha_pedido, fecha_entrega_esperada, estado,
                         subtotal, valor_iva, total_orden, observaciones,
                         id_proveedor, id_bodega_destino, id_empleado_solicita)
                    VALUES (%s, %s, 'PENDIENTE', %s, %s, %s, %s, %s, %s, %s)
                    RETURNING num_orden
                    """,
                    (
                        date.today(),
                        f.get("fecha_entrega_esperada") or None,
                        subtotal, total_iva, total_orden,
                        f.get("observaciones") or None,
                        int(f["id_proveedor"]),
                        int(f["id_bodega_destino"]),
                        int(f["id_empleado_solicita"]),
                    ),
                )
                num_orden = cur.fetchone()["num_orden"]

                for (codigo, cantidad, costo, tarifa, sub_linea, iva_linea, total_linea) in lineas_calculadas:
                    cur.execute(
                        """
                        INSERT INTO detalle_orden
                            (cantidad_solicitada, costo_unitario, tarifa_iva,
                             subtotal_linea, iva_linea, total_linea, num_orden, codigo_producto)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        """,
                        (cantidad, costo, tarifa, sub_linea, iva_linea, total_linea,
                         num_orden, codigo),
                    )

            flash(f"Orden de pedido #{num_orden} creada correctamente.", "success")
            return redirect(url_for("ordenes.detalle", num_orden=num_orden))
        except Exception as exc:  # noqa: BLE001
            flash(f"No se pudo crear la orden: {exc}", "error")
            return redirect(url_for("ordenes.crear"))

    return render_template(
        "ordenes/form.html",
        proveedores=fetch_all(
            "SELECT id_proveedor, razon_social, nit FROM proveedor WHERE activo ORDER BY razon_social"
        ),
        bodegas=fetch_all(
            "SELECT id_bodega, nombre_bodega FROM bodega WHERE activo ORDER BY nombre_bodega"
        ),
        empleados=fetch_all(
            """
            SELECT id_empleado, primer_nombre || ' ' || primer_apellido AS nombre
            FROM empleado WHERE activo ORDER BY primer_nombre
            """
        ),
        productos=fetch_all(
            """
            SELECT codigo_producto, nombre_producto, costo_promedio, tarifa_iva
            FROM producto WHERE activo ORDER BY nombre_producto
            """
        ),
    )
