"""
Capa de acceso a datos.

Centraliza la conexion a PostgreSQL con psycopg (v3) y ofrece funciones
sencillas para ejecutar consultas. Todas las consultas usan parametros
($ / %s) para evitar inyeccion SQL.

Cada llamada abre y cierra su propia conexion. Para un proyecto academico
con poca concurrencia esto es suficiente, simple de entender y de defender.
"""
from contextlib import contextmanager

import psycopg
from psycopg.rows import dict_row

from config import Config


@contextmanager
def get_connection():
    """
    Context manager que entrega una conexion configurada.

    - row_factory=dict_row: cada fila se devuelve como diccionario
      (accedemos por nombre de columna, ej. fila["nombre_completo"]).
    - Fija el search_path al esquema 'superinter' para no anteponerlo
      en cada consulta.
    """
    conn = psycopg.connect(Config.dsn(), row_factory=dict_row)
    try:
        with conn.cursor() as cur:
            cur.execute(f"SET search_path TO {Config.PGSCHEMA}")
        yield conn
    finally:
        conn.close()


def fetch_all(sql: str, params: tuple = ()):
    """Ejecuta un SELECT y devuelve una lista de diccionarios."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.fetchall()


def fetch_one(sql: str, params: tuple = ()):
    """Ejecuta un SELECT y devuelve una sola fila (o None)."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return cur.fetchone()


def execute(sql: str, params: tuple = ()):
    """
    Ejecuta un INSERT/UPDATE/DELETE.
    Si la sentencia lleva RETURNING, devuelve la primera fila resultante.
    Hace commit automatico si todo sale bien.
    """
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            result = None
            if cur.description is not None:  # la consulta devuelve filas
                result = cur.fetchone()
        conn.commit()
        return result


@contextmanager
def transaction():
    """
    Context manager para operaciones que insertan en varias tablas de forma
    atomica (ej. una factura + sus lineas de detalle + su medio de pago).

    Uso:
        with transaction() as cur:
            cur.execute(...)
            cur.execute(...)
    Si algo falla, se hace rollback automatico y no se guarda nada.
    """
    conn = psycopg.connect(Config.dsn(), row_factory=dict_row)
    try:
        with conn.cursor() as cur:
            cur.execute(f"SET search_path TO {Config.PGSCHEMA}")
            yield cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def check_connection():
    """Devuelve (True, version) si conecta; (False, error) si falla."""
    try:
        row = fetch_one("SELECT version() AS v")
        return True, row["v"]
    except Exception as exc:  # noqa: BLE001
        return False, str(exc)
