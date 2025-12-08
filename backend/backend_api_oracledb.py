"""
╔════════════════════════════════════════════════════════════════════════════════╗
║                                                                                ║
║                   BACKEND API - LEGO STORE                                     ║
║              REST API con Flask + oracledb + Pool de Conexiones                ║
║                                                                                ║
╚════════════════════════════════════════════════════════════════════════════════╝
"""

import os
import json
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
import oracledb
from dotenv import load_dotenv

# ═══════════════════════════════════════════════════════════════════════════════
# CARGAR VARIABLES DE ENTORNO
# ═══════════════════════════════════════════════════════════════════════════════

load_dotenv()

DB_USER = os.getenv('DB_USER', 'scott')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'tiger')
DB_HOST = os.getenv('DB_HOST', '127.0.0.1')
DB_PORT = int(os.getenv('DB_PORT', 1521))
DB_SID = os.getenv('DB_SID', 'xe')

FLASK_HOST = os.getenv('FLASK_HOST', '127.0.0.1')
FLASK_PORT = int(os.getenv('FLASK_PORT', 5000))
FLASK_DEBUG = os.getenv('FLASK_DEBUG', 'True').lower() == 'true'

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN LOGGING
# ═══════════════════════════════════════════════════════════════════════════════

os.makedirs('logs', exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)-8s | %(message)s',
    handlers=[
        logging.FileHandler('logs/app.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

# ═══════════════════════════════════════════════════════════════════════════════
# CREAR APLICACIÓN FLASK
# ═══════════════════════════════════════════════════════════════════════════════

app = Flask(__name__)
CORS(app)

# ═══════════════════════════════════════════════════════════════════════════════
# POOL DE CONEXIONES ORACLE
# ═══════════════════════════════════════════════════════════════════════════════

class OraclePool:
    """Gestor de conexiones a Oracle con oracledb"""
    
    def __init__(self):
        self.pool = None
        self.init_pool()
    
    def init_pool(self):
        """Inicializar pool de conexiones"""
        try:
            logger.info("Creando pool de conexiones Oracle...")
            
            self.pool = oracledb.create_pool(
                user=DB_USER,
                password=DB_PASSWORD,
                host=DB_HOST,
                port=DB_PORT,
                service_name=DB_SID,
                min=2,
                max=5,
                increment=1
            )
            
            logger.info("✅ Pool de conexiones Oracle creado exitosamente")
            return True
            
        except Exception as e:
            logger.error(f"❌ Error creando pool de conexiones: {e}")
            return False
    
    def get_connection(self):
        """Obtener conexión del pool"""
        try:
            if self.pool is None:
                logger.warning("Pool no inicializado, intentando reconectar...")
                self.init_pool()
            
            return self.pool.acquire()
        
        except Exception as e:
            logger.error(f"❌ Error obteniendo conexión: {e}")
            return None
    
    def execute_query(self, query, params=None):
        """Ejecutar query y retornar resultados"""
        conn = None
        try:
            conn = self.get_connection()
            if conn is None:
                return None
            
            cursor = conn.cursor()
            
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            # Obtener nombres de columnas
            column_names = [desc[0] for desc in cursor.description] if cursor.description else []
            
            # Convertir filas a diccionarios
            rows = []
            for row in cursor.fetchall():
                rows.append(dict(zip(column_names, row)))
            
            cursor.close()
            return rows
        
        except Exception as e:
            logger.error(f"❌ Error ejecutando query: {e}")
            return None
        
        finally:
            if conn:
                conn.close()
    
    def execute_update(self, query, params=None):
        """Ejecutar INSERT/UPDATE/DELETE"""
        conn = None
        try:
            conn = self.get_connection()
            if conn is None:
                return False
            
            cursor = conn.cursor()
            
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            conn.commit()
            cursor.close()
            logger.info(f"✅ Operación ejecutada: {query[:50]}...")
            return True
        
        except Exception as e:
            if conn:
                conn.rollback()
            logger.error(f"❌ Error en operación: {e}")
            return False
        
        finally:
            if conn:
                conn.close()

# ═══════════════════════════════════════════════════════════════════════════════
# INSTANCIAR POOL GLOBAL
# ═══════════════════════════════════════════════════════════════════════════════

db_pool = OraclePool()

# ═══════════════════════════════════════════════════════════════════════════════
# RUTAS API - SALUD
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/health', methods=['GET'])
def health():
    """Verificar estado del API"""
    try:
        # Intentar conexión a DB
        conn = db_pool.get_connection()
        if conn:
            conn.close()
            return jsonify({
                'status': 'healthy',
                'database': 'connected',
                'timestamp': datetime.now().isoformat()
            }), 200
        else:
            return jsonify({
                'status': 'unhealthy',
                'database': 'disconnected'
            }), 503
    
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/info', methods=['GET'])
def api_info():
    """Información del API"""
    return jsonify({
        'name': 'LEGO STORE API',
        'version': '1.0',
        'description': 'REST API para LEGO Store con Oracle',
        'timestamp': datetime.now().isoformat()
    }), 200

# ═══════════════════════════════════════════════════════════════════════════════
# RUTAS API - TOURS
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/api/v1/tours', methods=['GET'])
def get_tours():
    """Obtener todos los tours"""
    logger.info("GET /api/v1/tours")
    
    query = """
        SELECT t.tour_id, t.tour_name, t.fecha_salida, t.precio_base, 
               t.pais_id, p.nombre_pais
        FROM tours t
        JOIN paises p ON t.pais_id = p.pais_id
        ORDER BY t.fecha_salida
    """
    
    tours = db_pool.execute_query(query)
    
    if tours is None:
        return jsonify({'error': 'Error conectando a BD'}), 500
    
    return jsonify(tours), 200

@app.route('/api/v1/tours/<fecha>', methods=['GET'])
def get_tour_by_fecha(fecha):
    """Obtener tour por fecha"""
    logger.info(f"GET /api/v1/tours/{fecha}")
    
    query = """
        SELECT t.tour_id, t.tour_name, t.fecha_salida, t.precio_base, 
               t.pais_id, p.nombre_pais
        FROM tours t
        JOIN paises p ON t.pais_id = p.pais_id
        WHERE t.fecha_salida = :fecha
    """
    
    tours = db_pool.execute_query(query, {'fecha': fecha})
    
    if tours is None:
        return jsonify({'error': 'Error conectando a BD'}), 500
    
    if not tours:
        return jsonify({'error': 'Tour no encontrado'}), 404
    
    return jsonify(tours[0]), 200

# ═══════════════════════════════════════════════════════════════════════════════
# RUTAS API - PRODUCTOS
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/api/v1/productos', methods=['GET'])
def get_productos():
    """Obtener todos los productos"""
    logger.info("GET /api/v1/productos")
    
    query = """
        SELECT producto_id, nombre_producto, descripcion, precio_unitario, 
               cantidad_disponible
        FROM productos
        ORDER BY nombre_producto
    """
    
    productos = db_pool.execute_query(query)
    
    if productos is None:
        return jsonify({'error': 'Error conectando a BD'}), 500
    
    return jsonify(productos), 200

# ═══════════════════════════════════════════════════════════════════════════════
# RUTAS API - TIENDAS
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/api/v1/tiendas', methods=['GET'])
def get_tiendas():
    """Obtener todas las tiendas"""
    logger.info("GET /api/v1/tiendas")
    
    query = """
        SELECT tienda_id, nombre_tienda, ciudad, pais_id, telefono, email
        FROM tiendas
        ORDER BY nombre_tienda
    """
    
    tiendas = db_pool.execute_query(query)
    
    if tiendas is None:
        return jsonify({'error': 'Error conectando a BD'}), 500
    
    return jsonify(tiendas), 200

# ═══════════════════════════════════════════════════════════════════════════════
# RUTAS API - INSCRIPCIONES
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/api/v1/inscripciones', methods=['GET'])
def get_inscripciones():
    """Obtener todas las inscripciones"""
    logger.info("GET /api/v1/inscripciones")
    
    query = """
        SELECT inscripcion_id, tour_id, cliente_nombre, fecha_inscripcion, 
               estado, monto_total
        FROM inscripciones
        ORDER BY fecha_inscripcion DESC
    """
    
    inscripciones = db_pool.execute_query(query)
    
    if inscripciones is None:
        return jsonify({'error': 'Error conectando a BD'}), 500
    
    return jsonify(inscripciones), 200

@app.route('/api/v1/inscripciones/<int:id>', methods=['GET'])
def get_inscripcion(id):
    """Obtener inscripción específica"""
    logger.info(f"GET /api/v1/inscripciones/{id}")
    
    query = """
        SELECT inscripcion_id, tour_id, cliente_nombre, cliente_email, 
               cliente_telefono, cliente_dni, fecha_inscripcion, estado, monto_total
        FROM inscripciones
        WHERE inscripcion_id = :id
    """
    
    inscripciones = db_pool.execute_query(query, {'id': id})
    
    if inscripciones is None:
        return jsonify({'error': 'Error conectando a BD'}), 500
    
    if not inscripciones:
        return jsonify({'error': 'Inscripción no encontrada'}), 404
    
    return jsonify(inscripciones[0]), 200

@app.route('/api/v1/inscripciones', methods=['POST'])
def create_inscripcion():
    """Crear nueva inscripción"""
    logger.info("POST /api/v1/inscripciones")
    
    try:
        data = request.get_json()
        
        # Validar datos requeridos
        if not all(k in data for k in ['tour_id', 'cliente_nombre', 'cliente_email']):
            return jsonify({'error': 'Faltan datos requeridos'}), 400
        
        query = """
            INSERT INTO inscripciones (
                tour_id, cliente_nombre, cliente_email, cliente_telefono, 
                cliente_dni, fecha_inscripcion, estado, monto_total
            ) VALUES (
                :tour_id, :cliente_nombre, :cliente_email, :cliente_telefono, 
                :cliente_dni, SYSDATE, 'Confirmada', :monto_total
            )
        """
        
        params = {
            'tour_id': data.get('tour_id'),
            'cliente_nombre': data.get('cliente_nombre'),
            'cliente_email': data.get('cliente_email'),
            'cliente_telefono': data.get('cliente_telefono', ''),
            'cliente_dni': data.get('cliente_dni', ''),
            'monto_total': data.get('monto_total', 0)
        }
        
        success = db_pool.execute_update(query, params)
        
        if success:
            return jsonify({'message': 'Inscripción creada exitosamente'}), 201
        else:
            return jsonify({'error': 'Error creando inscripción'}), 500
    
    except Exception as e:
        logger.error(f"Error en POST inscripción: {e}")
        return jsonify({'error': str(e)}), 500

# ═══════════════════════════════════════════════════════════════════════════════
# RUTAS API - VALIDACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/api/v1/validar/dni', methods=['POST'])
def validar_dni():
    """Validar formato DNI"""
    try:
        data = request.get_json()
        dni = data.get('dni', '')
        
        # Validación básica: 8 dígitos
        if len(dni) == 8 and dni.isdigit():
            return jsonify({'valid': True}), 200
        else:
            return jsonify({'valid': False, 'error': 'DNI debe tener 8 dígitos'}), 400
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/v1/validar/pasaporte', methods=['POST'])
def validar_pasaporte():
    """Validar formato pasaporte"""
    try:
        data = request.get_json()
        pasaporte = data.get('pasaporte', '')
        
        # Validación básica: 6-10 caracteres alfanuméricos
        if 6 <= len(pasaporte) <= 10 and pasaporte.isalnum():
            return jsonify({'valid': True}), 200
        else:
            return jsonify({'valid': False, 'error': 'Pasaporte inválido'}), 400
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ═══════════════════════════════════════════════════════════════════════════════
# RUTAS API - MONEDAS
# ═══════════════════════════════════════════════════════════════════════════════

TASAS_CAMBIO = {
    'USD': 1.0,
    'EUR': 0.92,
    'DKK': 6.86
}

@app.route('/api/v1/monedas', methods=['GET'])
def get_monedas():
    """Obtener tasas de conversión"""
    logger.info("GET /api/v1/monedas")
    
    return jsonify({
        'timestamp': datetime.now().isoformat(),
        'tasas': TASAS_CAMBIO
    }), 200

@app.route('/api/v1/convertir', methods=['POST'])
def convertir_moneda():
    """Convertir entre monedas"""
    try:
        data = request.get_json()
        monto = float(data.get('monto', 0))
        desde = data.get('desde', 'USD').upper()
        hacia = data.get('hacia', 'USD').upper()
        
        if desde not in TASAS_CAMBIO or hacia not in TASAS_CAMBIO:
            return jsonify({'error': 'Moneda no soportada'}), 400
        
        # Convertir a USD primero, luego a la moneda destino
        monto_usd = monto / TASAS_CAMBIO[desde]
        monto_convertido = monto_usd * TASAS_CAMBIO[hacia]
        
        return jsonify({
            'monto_original': monto,
            'moneda_desde': desde,
            'monto_convertido': round(monto_convertido, 2),
            'moneda_hacia': hacia,
            'tasa': round(TASAS_CAMBIO[hacia] / TASAS_CAMBIO[desde], 4)
        }), 200
    
    except Exception as e:
        logger.error(f"Error en conversión: {e}")
        return jsonify({'error': str(e)}), 500

# ═══════════════════════════════════════════════════════════════════════════════
# MANEJO DE ERRORES
# ═══════════════════════════════════════════════════════════════════════════════

@app.errorhandler(404)
def not_found(error):
    """Ruta no encontrada"""
    return jsonify({'error': 'Ruta no encontrada'}), 404

@app.errorhandler(500)
def internal_error(error):
    """Error interno del servidor"""
    logger.error(f"Error interno: {error}")
    return jsonify({'error': 'Error interno del servidor'}), 500

# ═══════════════════════════════════════════════════════════════════════════════
# INICIAR SERVIDOR
# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == '__main__':
    logger.info("=" * 80)
    logger.info("INICIANDO BACKEND API - LEGO STORE")
    logger.info("=" * 80)
    logger.info(f"Base de datos: {DB_HOST}:{DB_PORT}/{DB_SID}")
    logger.info(f"Usuario: {DB_USER}")
    logger.info(f"Flask: {FLASK_HOST}:{FLASK_PORT}")
    logger.info("=" * 80)
    
    try:
        # Verificar conexión a BD
        if db_pool.pool:
            logger.info("✅ Pool de conexiones Oracle creado exitosamente")
            logger.info("✅ Iniciando servidor Flask...")
            logger.info(f"✅ Servidor disponible en http://{FLASK_HOST}:{FLASK_PORT}")
            logger.info("=" * 80)
            
            app.run(
                host=FLASK_HOST,
                port=FLASK_PORT,
                debug=FLASK_DEBUG,
                use_reloader=False
            )
        else:
            logger.error("❌ No se pudo crear el pool de conexiones")
            logger.error("❌ Verifica las credenciales en .env")
    
    except KeyboardInterrupt:
        logger.info("⚠️  Servidor detenido por usuario")
    except Exception as e:
        logger.error(f"❌ Error al iniciar servidor: {e}")
