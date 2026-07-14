"""
Gestion de INVENTARIOS.

Control de stock por producto y bodega, con calculo automatico de los DIAS DE
STOCK y clasificacion del estado (AGOTADO / CRITICO / ALERTA / SEGURO) para
generar alertas de reabastecimiento.

Reglas de negocio aplicadas (guia del proyecto):
- Los DIAS DE STOCK NO se almacenan en la base de datos: se calculan al vuelo
  con la formula  dias = stock_actual / demanda_diaria_promedio.
- NO se puede registrar inventario de un producto no registrado: el producto se
  elige de una lista desplegable de productos activos (que ya exigen proveedor).
- El stock fisico solo cambia mediante MOVIMIENTOS (entrada/salida/ajuste), que
  quedan auditados en movimiento_inventario con el stock anterior y posterior.
- Un producto no se puede duplicar en la misma bodega (restriccion UNIQUE).
"""
from decimal import Decimal

from flask import Blueprint, render_template, request, redirect, url_for, flash

from db import fetch_all, fetch_one, execute, transaction

bp = Blueprint("inventario", __name__, template_folder="../templates")


def clasificar_stock(stock_actual, demanda_diaria):
    """
    Calcula los dias de stock y devuelve la categoria de estado con su accion
    recomendada, segun la tabla de la guia del proyecto:

        0 dias           -> AGOTADO   -> Pedido Inmediato
        menos de 5 dias  -> CRITICO   -> Pedido de Emergencia
        entre 5 y 15     -> ALERTA    -> Realizar Pedido Normal
        mas de 15 dias   -> SEGURO    -> Mantener Monitoreo

    Nota: dias_stock se calcula aqui y NUNCA se guarda en la base de datos.
    """
    stock = float(stock_actual or 0)
    demanda = float(demanda_diaria or 0)

    if stock <= 0:
        dias = 0.0
    elif demanda <= 0:
        # Sin demanda diaria registrada no se puede consumir el inventario.
        dias = None  # "sin demanda" -> se considera SEGURO
    else:
        dias = stock / demanda

    if dias is not None and dias <= 0:
        return dias, "AGOTADO", "Pedido Inmediato", "estado-agotado"
    if dias is not None and dias < 5:
        return dias, "CRITICO", "Pedido de Emergencia", "estado-critico"
    if dias is not None and dias <= 15:
        return dias, "ALERTA", "Realizar Pedido Normal", "estado-alerta"
    return dias, "SEGURO", "Mantener Monitoreo", "estado-seguro"


def _enriquecer(fila):
    """Agrega los campos calculados (dias de stock, estado, accion) a una fila."""
    dias, categoria, accion, css = clasificar_stock(
        fila["stock_actual"], fila["demanda_diaria_promedio"]
    )
    fila["dias_stock"] = dias
    fila["dias_stock_txt"] = "sin demanda" if dias is None else f"{dias:.1f}"
    fila["categoria_estado"] = categoria
    fila["accion_recomendada"] = accion
    fila["estado_css"] = css
    return fila


@bp.route("/")
def listar():
    filas = fetch_all(
        """
        SELECT i.id_inventario, i.stock_actual, i.stock_reservado,
               i.demanda_diaria_promedio, i.fecha_ultima_entrada,
               i.fecha_ultima_salida, i.fecha_ultimo_conteo,
               p.codigo_producto, p.nombre_producto, p.stock_minimo,
               b.id_bodega, b.nombre_bodega,
               u.abreviatura AS unidad,
               pr.razon_social AS proveedor
        FROM inventario i
        JOIN producto p       ON p.codigo_producto     = i.codigo_producto
        JOIN bodega b         ON b.id_bodega            = i.id_bodega
        JOIN unidad_medida u  ON u.id_unidad            = p.id_unidad
        JOIN proveedor pr     ON pr.id_proveedor        = p.id_proveedor_principal
        ORDER BY p.nombre_producto, b.nombre_bodega
        """
    )
    filas = [_enriquecer(f) for f in filas]

    # Ordenamos por urgencia (menos dias de stock primero) para las alertas.
    orden = {"AGOTADO": 0, "CRITICO": 1, "ALERTA": 2, "SEGURO": 3}
    filas.sort(key=lambda f: orden[f["categoria_estado"]])

    resumen = {"AGOTADO": 0, "CRITICO": 0, "ALERTA": 0, "SEGURO": 0}
    for f in filas:
        resumen[f["categoria_estado"]] += 1

    return render_template("inventario/list.html", filas=filas, resumen=resumen)


@bp.route("/<int:id_inventario>")
def detalle(id_inventario):
    inv = fetch_one(
        """
        SELECT i.*, p.nombre_producto, p.stock_minimo, p.stock_maximo,
               p.punto_reorden, u.nombre_unidad, u.abreviatura AS unidad,
               b.nombre_bodega, b.tipo_bodega,
               pr.razon_social AS proveedor, pr.tiempo_entrega_dias
        FROM inventario i
        JOIN producto p       ON p.codigo_producto = i.codigo_producto
        JOIN unidad_medida u  ON u.id_unidad       = p.id_unidad
        JOIN bodega b         ON b.id_bodega        = i.id_bodega
        JOIN proveedor pr     ON pr.id_proveedor    = p.id_proveedor_principal
        WHERE i.id_inventario = %s
        """,
        (id_inventario,),
    )
    if not inv:
        flash("Registro de inventario no encontrado.", "error")
        return redirect(url_for("inventario.listar"))

    inv = _enriquecer(inv)

    movimientos = fetch_all(
        """
        SELECT m.tipo_movimiento, m.cantidad, m.stock_anterior, m.stock_posterior,
               m.costo_unitario, m.fecha_movimiento, m.documento_referencia, m.motivo,
               e.primer_nombre || ' ' || e.primer_apellido AS empleado
        FROM movimiento_inventario m
        JOIN empleado e ON e.id_empleado = m.id_empleado
        WHERE m.id_inventario = %s
        ORDER BY m.fecha_movimiento DESC, m.id_movimiento DESC
        """,
        (id_inventario,),
    )

    empleados = fetch_all(
        """
        SELECT id_empleado, primer_nombre || ' ' || primer_apellido AS nombre
        FROM empleado WHERE activo ORDER BY primer_nombre
        """
    )
    return render_template(
        "inventario/detail.html", inv=inv, movimientos=movimientos, empleados=empleados
    )


@bp.route("/nuevo", methods=["GET", "POST"])
def crear():
    if request.method == "POST":
        f = request.form
        try:
            execute(
                """
                INSERT INTO inventario
                    (stock_actual, stock_reservado, demanda_diaria_promedio,
                     fecha_ultimo_conteo, codigo_producto, id_bodega)
                VALUES (%s, %s, %s, CURRENT_DATE, %s, %s)
                """,
                (
                    int(f.get("stock_actual") or 0),
                    int(f.get("stock_reservado") or 0),
                    Decimal(f.get("demanda_diaria_promedio") or "0"),
                    f["codigo_producto"],
                    int(f["id_bodega"]),
                ),
            )
            flash("Registro de inventario creado correctamente.", "success")
            return redirect(url_for("inventario.listar"))
        except Exception as exc:  # noqa: BLE001
            flash(f"No se pudo crear el registro de inventario: {exc}", "error")

    return render_template(
        "inventario/form.html",
        inv=None,
        productos=fetch_all(
            """
            SELECT codigo_producto, nombre_producto
            FROM producto WHERE activo ORDER BY nombre_producto
            """
        ),
        bodegas=fetch_all(
            "SELECT id_bodega, nombre_bodega FROM bodega WHERE activo ORDER BY nombre_bodega"
        ),
    )


@bp.route("/<int:id_inventario>/editar", methods=["GET", "POST"])
def editar(id_inventario):
    inv = fetch_one(
        """
        SELECT i.*, p.nombre_producto, b.nombre_bodega
        FROM inventario i
        JOIN producto p ON p.codigo_producto = i.codigo_producto
        JOIN bodega b   ON b.id_bodega        = i.id_bodega
        WHERE i.id_inventario = %s
        """,
        (id_inventario,),
    )
    if not inv:
        flash("Registro de inventario no encontrado.", "error")
        return redirect(url_for("inventario.listar"))

    if request.method == "POST":
        f = request.form
        try:
            # El stock_actual NO se edita aqui: cambia solo por movimientos.
            execute(
                """
                UPDATE inventario SET
                    stock_reservado = %s,
                    demanda_diaria_promedio = %s,
                    fecha_ultimo_conteo = %s
                WHERE id_inventario = %s
                """,
                (
                    int(f.get("stock_reservado") or 0),
                    Decimal(f.get("demanda_diaria_promedio") or "0"),
                    f.get("fecha_ultimo_conteo") or None,
                    id_inventario,
                ),
            )
            flash("Registro de inventario actualizado correctamente.", "success")
            return redirect(url_for("inventario.detalle", id_inventario=id_inventario))
        except Exception as exc:  # noqa: BLE001
            flash(f"No se pudo actualizar el inventario: {exc}", "error")

    return render_template("inventario/form.html", inv=inv, productos=None, bodegas=None)


@bp.route("/<int:id_inventario>/movimiento", methods=["POST"])
def movimiento(id_inventario):
    """
    Registra un movimiento de stock (ENTRADA / SALIDA / AJUSTE) y actualiza el
    stock fisico de forma atomica, dejando la traza en movimiento_inventario.
    """
    f = request.form
    tipo = f["tipo_movimiento"]
    cantidad = int(f["cantidad"])
    id_empleado = int(f["id_empleado"])

    try:
        if cantidad <= 0:
            raise ValueError("La cantidad debe ser mayor a cero.")

        with transaction() as cur:
            cur.execute(
                "SELECT stock_actual FROM inventario WHERE id_inventario = %s FOR UPDATE",
                (id_inventario,),
            )
            row = cur.fetchone()
            if not row:
                raise ValueError("Inventario inexistente.")
            stock_anterior = row["stock_actual"]

            if tipo in ("ENTRADA", "AJUSTE_POSITIVO"):
                stock_posterior = stock_anterior + cantidad
            elif tipo in ("SALIDA", "AJUSTE_NEGATIVO"):
                stock_posterior = stock_anterior - cantidad
                if stock_posterior < 0:
                    raise ValueError(
                        f"Stock insuficiente: hay {stock_anterior} y se intentan retirar {cantidad}."
                    )
            else:
                raise ValueError("Tipo de movimiento no valido.")

            campo_fecha = (
                "fecha_ultima_entrada"
                if tipo in ("ENTRADA", "AJUSTE_POSITIVO")
                else "fecha_ultima_salida"
            )
            cur.execute(
                f"""
                UPDATE inventario
                SET stock_actual = %s, {campo_fecha} = CURRENT_DATE
                WHERE id_inventario = %s
                """,
                (stock_posterior, id_inventario),
            )

            cur.execute(
                """
                INSERT INTO movimiento_inventario
                    (tipo_movimiento, cantidad, stock_anterior, stock_posterior,
                     costo_unitario, documento_referencia, motivo,
                     id_inventario, id_empleado)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    tipo,
                    cantidad,
                    stock_anterior,
                    stock_posterior,
                    Decimal(f.get("costo_unitario") or "0") or None,
                    f.get("documento_referencia") or None,
                    f.get("motivo") or None,
                    id_inventario,
                    id_empleado,
                ),
            )
        flash("Movimiento de inventario registrado correctamente.", "success")
    except Exception as exc:  # noqa: BLE001
        flash(f"No se pudo registrar el movimiento: {exc}", "error")

    return redirect(url_for("inventario.detalle", id_inventario=id_inventario))
