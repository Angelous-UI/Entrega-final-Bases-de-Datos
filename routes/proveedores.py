"""
CRUD de PROVEEDORES.

Reglas de negocio aplicadas:
- El NIT es un campo critico: se captura al crear pero NO se puede editar.
- La "eliminacion" es logica (activo = FALSE), porque un proveedor puede
  tener productos y ordenes de pedido asociados.
- Solo los proveedores registrados aqui podran usarse al crear productos
  y ordenes de pedido (integridad referencial via listas desplegables).
"""
from flask import Blueprint, render_template, request, redirect, url_for, flash

from db import fetch_all, fetch_one, execute

bp = Blueprint("proveedores", __name__, template_folder="../templates")

TIPOS_CUENTA = ["AHORROS", "CORRIENTE"]


@bp.route("/")
def listar():
    proveedores = fetch_all(
        """
        SELECT id_proveedor, nit, razon_social, contacto_comercial_nombre,
               contacto_comercial_tel, calificacion, tiempo_entrega_dias, activo
        FROM proveedor
        ORDER BY activo DESC, razon_social
        """
    )
    return render_template("proveedores/list.html", proveedores=proveedores)


@bp.route("/<int:id_proveedor>")
def detalle(id_proveedor):
    proveedor = fetch_one(
        "SELECT * FROM proveedor WHERE id_proveedor = %s", (id_proveedor,)
    )
    if not proveedor:
        flash("Proveedor no encontrado.", "error")
        return redirect(url_for("proveedores.listar"))
    return render_template("proveedores/detail.html", proveedor=proveedor)


@bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    if request.method == "POST":
        f = request.form
        try:
            execute(
                """
                INSERT INTO proveedor
                    (nit, razon_social, numero_rut, banco, tipo_cuenta, numero_cuenta,
                     contacto_comercial_nombre, contacto_comercial_tel, contacto_comercial_email,
                     contacto_cartera_nombre, contacto_cartera_tel, contacto_cartera_email,
                     contacto_logistico_nombre, contacto_logistico_tel, contacto_logistico_email,
                     tiempo_entrega_dias, condiciones_pago_dias, calificacion)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    f["nit"].strip(),
                    f["razon_social"].strip(),
                    f.get("numero_rut") or None,
                    f.get("banco") or None,
                    f.get("tipo_cuenta") or None,
                    f.get("numero_cuenta") or None,
                    f.get("contacto_comercial_nombre") or None,
                    f.get("contacto_comercial_tel") or None,
                    f.get("contacto_comercial_email") or None,
                    f.get("contacto_cartera_nombre") or None,
                    f.get("contacto_cartera_tel") or None,
                    f.get("contacto_cartera_email") or None,
                    f.get("contacto_logistico_nombre") or None,
                    f.get("contacto_logistico_tel") or None,
                    f.get("contacto_logistico_email") or None,
                    int(f.get("tiempo_entrega_dias") or 0),
                    int(f.get("condiciones_pago_dias") or 30),
                    int(f["calificacion"]) if f.get("calificacion") else None,
                ),
            )
            flash("Proveedor creado correctamente.", "success")
            return redirect(url_for("proveedores.listar"))
        except Exception as exc:  # noqa: BLE001
            flash(f"No se pudo crear el proveedor: {exc}", "error")

    return render_template(
        "proveedores/form.html", proveedor=None, tipos_cuenta=TIPOS_CUENTA
    )


@bp.route("/<int:id_proveedor>/editar", methods=["GET", "POST"])
def editar(id_proveedor):
    proveedor = fetch_one(
        "SELECT * FROM proveedor WHERE id_proveedor = %s", (id_proveedor,)
    )
    if not proveedor:
        flash("Proveedor no encontrado.", "error")
        return redirect(url_for("proveedores.listar"))

    if request.method == "POST":
        f = request.form
        try:
            # El NIT NO se actualiza (campo critico).
            execute(
                """
                UPDATE proveedor SET
                    razon_social = %s, numero_rut = %s, banco = %s, tipo_cuenta = %s,
                    numero_cuenta = %s, contacto_comercial_nombre = %s,
                    contacto_comercial_tel = %s, contacto_comercial_email = %s,
                    contacto_cartera_nombre = %s, contacto_cartera_tel = %s,
                    contacto_cartera_email = %s, contacto_logistico_nombre = %s,
                    contacto_logistico_tel = %s, contacto_logistico_email = %s,
                    tiempo_entrega_dias = %s, condiciones_pago_dias = %s, calificacion = %s
                WHERE id_proveedor = %s
                """,
                (
                    f["razon_social"].strip(),
                    f.get("numero_rut") or None,
                    f.get("banco") or None,
                    f.get("tipo_cuenta") or None,
                    f.get("numero_cuenta") or None,
                    f.get("contacto_comercial_nombre") or None,
                    f.get("contacto_comercial_tel") or None,
                    f.get("contacto_comercial_email") or None,
                    f.get("contacto_cartera_nombre") or None,
                    f.get("contacto_cartera_tel") or None,
                    f.get("contacto_cartera_email") or None,
                    f.get("contacto_logistico_nombre") or None,
                    f.get("contacto_logistico_tel") or None,
                    f.get("contacto_logistico_email") or None,
                    int(f.get("tiempo_entrega_dias") or 0),
                    int(f.get("condiciones_pago_dias") or 30),
                    int(f["calificacion"]) if f.get("calificacion") else None,
                    id_proveedor,
                ),
            )
            flash("Proveedor actualizado correctamente.", "success")
            return redirect(url_for("proveedores.detalle", id_proveedor=id_proveedor))
        except Exception as exc:  # noqa: BLE001
            flash(f"No se pudo actualizar el proveedor: {exc}", "error")

    return render_template(
        "proveedores/form.html", proveedor=proveedor, tipos_cuenta=TIPOS_CUENTA
    )


@bp.route("/<int:id_proveedor>/estado", methods=["POST"])
def cambiar_estado(id_proveedor):
    try:
        execute(
            "UPDATE proveedor SET activo = NOT activo WHERE id_proveedor = %s",
            (id_proveedor,),
        )
        flash("Estado del proveedor actualizado.", "success")
    except Exception as exc:  # noqa: BLE001
        flash(f"No se pudo cambiar el estado: {exc}", "error")
    return redirect(url_for("proveedores.listar"))
