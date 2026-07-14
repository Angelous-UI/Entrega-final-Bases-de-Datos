"""
Gestion de FACTURAS DE VENTA.

Reglas de negocio aplicadas:
- Una factura, una vez guardada, NO se puede editar ni eliminar.
  Por eso este modulo solo expone: listar, ver detalle y crear.
- El numero de factura (DIAN) es un campo critico generado por el sistema;
  el usuario no lo escribe a mano.
- La factura se guarda de forma atomica junto con sus lineas de detalle y
  su medio de pago (transaccion): si algo falla, no se guarda nada.
- Los totales (subtotal, IVA, total) se calculan en el servidor a partir del
  precio y la tarifa de IVA de cada producto; nunca se confia en el cliente.
"""
from datetime import datetime
from decimal import Decimal

from flask import Blueprint, render_template, request, redirect, url_for, flash

from db import fetch_all, fetch_one, transaction

bp = Blueprint("facturas", __name__, template_folder="../templates")

TIPOS_PAGO = [
    "EFECTIVO", "TARJETA_DEBITO", "TARJETA_CREDITO",
    "PSE", "QR", "TRANSFERENCIA", "BONO",
]


@bp.route("/")
def listar():
    facturas = fetch_all(
        """
        SELECT fv.id_factura, fv.numero_factura_dian, fv.fecha_expedicion,
               fv.total_pagar, fv.estado,
               cl.nombre_completo AS cliente, s.nombre_sede
        FROM factura_venta fv
        JOIN cliente cl ON cl.id_cliente = fv.id_cliente
        JOIN sede s     ON s.id_sede     = fv.id_sede
        ORDER BY fv.fecha_expedicion DESC
        """
    )
    return render_template("facturas/list.html", facturas=facturas)


@bp.route("/<int:id_factura>")
def detalle(id_factura):
    factura = fetch_one(
        """
        SELECT fv.*, cl.nombre_completo AS cliente, cl.numero_documento AS doc_cliente,
               s.nombre_sede,
               e.primer_nombre || ' ' || e.primer_apellido AS cajero
        FROM factura_venta fv
        JOIN cliente cl ON cl.id_cliente = fv.id_cliente
        JOIN sede s     ON s.id_sede     = fv.id_sede
        JOIN empleado e ON e.id_empleado = fv.id_cajero
        WHERE fv.id_factura = %s
        """,
        (id_factura,),
    )
    if not factura:
        flash("Factura no encontrada.", "error")
        return redirect(url_for("facturas.listar"))

    lineas = fetch_all(
        """
        SELECT df.*, p.nombre_producto
        FROM detalle_factura df
        JOIN producto p ON p.codigo_producto = df.codigo_producto
        WHERE df.id_factura = %s
        ORDER BY df.id_detalle
        """,
        (id_factura,),
    )
    pagos = fetch_all(
        "SELECT * FROM medio_pago WHERE id_factura = %s ORDER BY id_pago",
        (id_factura,),
    )
    return render_template(
        "facturas/detail.html", factura=factura, lineas=lineas, pagos=pagos
    )


@bp.route("/nueva", methods=["GET", "POST"])
def crear():
    if request.method == "POST":
        f = request.form
        # Lineas de detalle: listas paralelas de codigos y cantidades.
        codigos = f.getlist("codigo_producto")
        cantidades = f.getlist("cantidad")

        # Filtramos lineas vacias.
        items = [
            (c, int(q))
            for c, q in zip(codigos, cantidades)
            if c and q and int(q) > 0
        ]
        if not items:
            flash("Debe agregar al menos un producto a la factura.", "error")
            return redirect(url_for("facturas.crear"))

        try:
            with transaction() as cur:
                # 1) Calcular totales a partir de los precios reales en BD.
                subtotal = Decimal("0")
                total_iva = Decimal("0")
                lineas_calculadas = []
                for codigo, cantidad in items:
                    cur.execute(
                        "SELECT precio_venta, tarifa_iva FROM producto WHERE codigo_producto = %s AND activo",
                        (codigo,),
                    )
                    prod = cur.fetchone()
                    if not prod:
                        raise ValueError(f"Producto {codigo} inexistente o inactivo.")
                    precio = prod["precio_venta"]
                    tarifa = prod["tarifa_iva"]
                    sub_linea = precio * cantidad
                    iva_linea = (sub_linea * tarifa).quantize(Decimal("0.01"))
                    total_linea = sub_linea + iva_linea
                    subtotal += sub_linea
                    total_iva += iva_linea
                    lineas_calculadas.append(
                        (codigo, cantidad, precio, tarifa, sub_linea, iva_linea, total_linea)
                    )

                total_pagar = subtotal + total_iva

                # 2) Generar numero de factura DIAN (consecutivo simple).
                prefijo = "SETP"
                cur.execute("SELECT COALESCE(MAX(id_factura), 0) + 1 AS siguiente FROM factura_venta")
                siguiente = cur.fetchone()["siguiente"]
                numero_dian = f"{prefijo}{siguiente:08d}"
                ahora = datetime.now()

                # 3) Insertar cabecera de la factura.
                cur.execute(
                    """
                    INSERT INTO factura_venta
                        (numero_factura_dian, prefijo_dian, fecha_expedicion,
                         subtotal, valor_total_iva, valor_descuento, total_pagar,
                         id_cliente, id_sede, id_cajero)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING id_factura
                    """,
                    (
                        numero_dian, prefijo, ahora,
                        subtotal, total_iva, Decimal("0"), total_pagar,
                        int(f["id_cliente"]), int(f["id_sede"]), int(f["id_cajero"]),
                    ),
                )
                id_factura = cur.fetchone()["id_factura"]

                # 4) Insertar cada linea de detalle.
                for (codigo, cantidad, precio, tarifa, sub_linea, iva_linea, total_linea) in lineas_calculadas:
                    cur.execute(
                        """
                        INSERT INTO detalle_factura
                            (cantidad, valor_unitario, tarifa_iva_aplicada,
                             subtotal_linea, iva_linea, total_linea,
                             id_factura, codigo_producto)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                        """,
                        (cantidad, precio, tarifa, sub_linea, iva_linea, total_linea,
                         id_factura, codigo),
                    )

                # 5) Registrar el medio de pago por el total.
                cur.execute(
                    """
                    INSERT INTO medio_pago (tipo_pago, valor_pago, id_factura)
                    VALUES (%s, %s, %s)
                    """,
                    (f.get("tipo_pago", "EFECTIVO"), total_pagar, id_factura),
                )

            flash(f"Factura {numero_dian} generada correctamente.", "success")
            return redirect(url_for("facturas.detalle", id_factura=id_factura))
        except Exception as exc:  # noqa: BLE001
            flash(f"No se pudo generar la factura: {exc}", "error")
            return redirect(url_for("facturas.crear"))

    # GET: cargar catalogos para el formulario.
    return render_template(
        "facturas/form.html",
        clientes=fetch_all(
            "SELECT id_cliente, nombre_completo, numero_documento FROM cliente WHERE activo ORDER BY nombre_completo"
        ),
        sedes=fetch_all(
            "SELECT id_sede, nombre_sede FROM sede WHERE activo ORDER BY nombre_sede"
        ),
        cajeros=fetch_all(
            """
            SELECT id_empleado, primer_nombre || ' ' || primer_apellido AS nombre
            FROM empleado WHERE activo AND rol_operativo IN ('CAJERO','SUPERVISOR','ADMIN')
            ORDER BY primer_nombre
            """
        ),
        productos=fetch_all(
            """
            SELECT codigo_producto, nombre_producto, precio_venta, tarifa_iva
            FROM producto WHERE activo ORDER BY nombre_producto
            """
        ),
        tipos_pago=TIPOS_PAGO,
    )
