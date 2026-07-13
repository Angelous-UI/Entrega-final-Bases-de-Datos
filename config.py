"""
Configuracion central de la aplicacion.

Lee las variables de entorno desde el archivo .env (usando python-dotenv)
y las expone como constantes para el resto del proyecto.
"""
import os
from dotenv import load_dotenv

# Carga las variables definidas en el archivo .env al entorno del proceso.
load_dotenv()


class Config:
    # Clave secreta de Flask (para flash messages y sesiones).
    SECRET_KEY = os.getenv("SECRET_KEY", "clave-insegura-solo-desarrollo")

    # Parametros de conexion a PostgreSQL.
    PGHOST = os.getenv("PGHOST", "localhost")
    PGPORT = os.getenv("PGPORT", "5432")
    PGDATABASE = os.getenv("PGDATABASE", "superinter")
    PGUSER = os.getenv("PGUSER", "postgres")
    PGPASSWORD = os.getenv("PGPASSWORD", "")

    # Esquema donde viven las tablas (definido en el DDL como "superinter").
    PGSCHEMA = os.getenv("PGSCHEMA", "superinter")

    @classmethod
    def dsn(cls) -> str:
        """Cadena de conexion (DSN) que entiende psycopg."""
        return (
            f"host={cls.PGHOST} port={cls.PGPORT} dbname={cls.PGDATABASE} "
            f"user={cls.PGUSER} password={cls.PGPASSWORD}"
        )
