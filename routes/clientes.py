"""
CRUD de CLIENTES.

Reglas de negocio aplicadas:
- El numero de documento (Cedula/NIT) es un campo critico: se captura al
  crear, pero NO se puede editar despues.
- La "eliminacion" es logica: se marca activo = FALSE (no se borra la fila),
  porque un cliente puede tener facturas asociadas (integridad referencial).
"""
from flask import Blueprint, render_template, request, redirect, url_for, flash

from db import fetch_all, fetch_one, execute

bp = Blueprint("clientes", __name__, template_folder="../templates")

# Valores permitidos segun los CHECK del DDL.
TIPOS_DOCUMENTO = ["CC", "NIT", "CE"]
TIPOS_REGIMEN = ["RESPONSABLE_IVA", "NO_RESPONSABLE_IVA"]
CANALES = ["PRESENCIAL", "DOMICILIO", "WEB"]


@bp.route("/")
def listar():
    """Lista todos los clientes (activos e inactivos)."""
    clientes = fetch_all(
        """
        SELECT id_cliente, tipo_documento, numero_documento, nombre_completo,
               ciudad, telefono, email, canal_venta_preferido, activo
        FROM cliente
        ORDER BY activo DESC, nombre_completo
        """
    )
    return render_template("clientes/list.html", clientes=clientes)


@bp.route("/<int:id_cliente>")
def detalle(id_cliente):
    """Ficha completa de un cliente."""
    cliente = fetch_one("SELECT * FROM cliente WHERE id_cliente = %s", (id_cliente,))
    if not cliente:
        flash("Cliente no encontrado.", "error")
        return redirect(url_for("clientes.listar"))
    return render_template("clientes/detail.html", cliente=cliente)


@bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    """Crea un nuevo cliente."""
    if request.method == "POST":
        f = request.form
        try:
            execute(
                """
                INSERT INTO cliente
                    (tipo_documento, numero_documento, nombre_completo, habeas_data,
                     ciudad, direccion_operativa, direccion_residencia, telefono, email,
                     representante_legal, tipo_regimen, canal_venta_preferido)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    f["tipo_documento"],
                    f["numero_documento"].strip(),
                    f["nombre_completo"].strip(),
                    "habeas_data" in f,
                    f["ciudad"].strip(),
                    f.get("direccion_operativa") or None,
                    f.get("direccion_residencia") or None,
                    f.get("telefono") or None,
                    f.get("email") or None,
                    f.get("representante_legal") or None,
                    f.get("tipo_regimen") or None,
                    f.get("canal_venta_preferido") or None,
                ),
            )
            flash("Cliente creado correctamente.", "success")
            return redirect(url_for("clientes.listar"))
        except Exception as exc:  # noqa: BLE001
            flash(f"No se pudo crear el cliente: {exc}", "error")

    return render_template(
        "clientes/form.html",
        cliente=None,
        tipos_documento=TIPOS_DOCUMENTO,
        tipos_regimen=TIPOS_REGIMEN,
        canales=CANALES,
    )


@bp.route("/<int:id_cliente>/editar", methods=["GET", "POST"])
def editar(id_cliente):
    """Edita un cliente. El numero de documento NO se modifica."""
    cliente = fetch_one("SELECT * FROM cliente WHERE id_cliente = %s", (id_cliente,))
    if not cliente:
        flash("Cliente no encontrado.", "error")
        return redirect(url_for("clientes.listar"))

    if request.method == "POST":
        f = request.form
        try:
            # OJO: tipo_documento y numero_documento NO se actualizan (campo critico).
            execute(
                """
                UPDATE cliente SET
                    nombre_completo = %s,
                    habeas_data = %s,
                    ciudad = %s,
                    direccion_operativa = %s,
                    direccion_residencia = %s,
                    telefono = %s,
                    email = %s,
                    representante_legal = %s,
                    tipo_regimen = %s,
                    canal_venta_preferido = %s
                WHERE id_cliente = %s
                """,
                (
                    f["nombre_completo"].strip(),
                    "habeas_data" in f,
                    f["ciudad"].strip(),
                    f.get("direccion_operativa") or None,
                    f.get("direccion_residencia") or None,
                    f.get("telefono") or None,
                    f.get("email") or None,
                    f.get("representante_legal") or None,
                    f.get("tipo_regimen") or None,
                    f.get("canal_venta_preferido") or None,
                    id_cliente,
                ),
            )
            flash("Cliente actualizado correctamente.", "success")
            return redirect(url_for("clientes.detalle", id_cliente=id_cliente))
        except Exception as exc:  # noqa: BLE001
            flash(f"No se pudo actualizar el cliente: {exc}", "error")

    return render_template(
        "clientes/form.html",
        cliente=cliente,
        tipos_documento=TIPOS_DOCUMENTO,
        tipos_regimen=TIPOS_REGIMEN,
        canales=CANALES,
    )


@bp.route("/<int:id_cliente>/estado", methods=["POST"])
def cambiar_estado(id_cliente):
    """Activa o desactiva un cliente (eliminacion logica)."""
    try:
        execute(
            "UPDATE cliente SET activo = NOT activo WHERE id_cliente = %s",
            (id_cliente,),
        )
        flash("Estado del cliente actualizado.", "success")
    except Exception as exc:  # noqa: BLE001
        flash(f"No se pudo cambiar el estado: {exc}", "error")
    return redirect(url_for("clientes.listar"))
