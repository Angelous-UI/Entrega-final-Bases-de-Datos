"""
Punto de entrada de la aplicacion web Superinter S.A.S.

Ejecutar en local:
    1. Crear y activar un entorno virtual
    2. pip install -r requirements.txt
    3. Copiar .env.example -> .env y poner las credenciales de PostgreSQL
    4. python app.py
    5. Abrir http://localhost:5000
"""
from flask import Flask, render_template

from config import Config
from db import check_connection

# Blueprints (un modulo por entidad principal del CRUD)
from routes.clientes import bp as clientes_bp
from routes.proveedores import bp as proveedores_bp
from routes.productos import bp as productos_bp
from routes.inventario import bp as inventario_bp
from routes.facturas import bp as facturas_bp
from routes.ordenes import bp as ordenes_bp


def create_app() -> Flask:
    """Application factory: crea y configura la instancia de Flask."""
    app = Flask(__name__)
    app.config.from_object(Config)

    # Registro de cada modulo del CRUD bajo su propio prefijo de URL.
    app.register_blueprint(clientes_bp, url_prefix="/clientes")
    app.register_blueprint(proveedores_bp, url_prefix="/proveedores")
    app.register_blueprint(productos_bp, url_prefix="/productos")
    app.register_blueprint(inventario_bp, url_prefix="/inventario")
    app.register_blueprint(facturas_bp, url_prefix="/facturas")
    app.register_blueprint(ordenes_bp, url_prefix="/ordenes")

    @app.route("/")
    def index():
        """Panel de inicio con el estado de la conexion a la BD."""
        ok, mensaje = check_connection()
        return render_template("index.html", conexion_ok=ok, mensaje=mensaje)

    return app


app = create_app()


if __name__ == "__main__":
    # debug=True recarga automaticamente al guardar cambios (solo desarrollo).
    app.run(host="0.0.0.0", port=5000, debug=True)
