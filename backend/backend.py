"""
╔════════════════════════════════════════════════════════════════════════════════╗
║                                                                                ║
║              BACKEND API LEGO STORE - TOURS AUTOMATIZACIÓN                     ║
║                                                                                ║
║        API Flask con endpoints completos para tours e inscripciones            ║
║                                                                                ║
╚════════════════════════════════════════════════════════════════════════════════╝
"""

from flask import Flask, jsonify, request
import oracledb
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv
import logging
import json

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

load_dotenv()

# Oracle Connection
DB_USER = os.getenv("DB_USER", "maria_M")
DB_PASSWORD = os.getenv("DB_PASSWORD", "maria2003")
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = os.getenv("DB_PORT", "1521")
DB_SERVICE = os.getenv("DB_SERVICE", "xe")

# Flask
FLASK_HOST = "127.0.0.1"
FLASK_PORT = 5000

# ═══════════════════════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════════════════════

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def log_event(category, message):
    """Log con timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {category:12} | {message}")
    logger.info(f"[{category}] {message}")

# ═══════════════════════════════════════════════════════════════════════════════
# POOL DE CONEXIONES ORACLE
# ═══════════════════════════════════════════════════════════════════════════════

class OraclePool:
    """Gestión de conexiones Oracle"""
    
    def __init__(self):
        self.pool = None
        self.init_pool()
    
    def init_pool(self):
        """Inicializar pool de conexiones"""
        try:
            dsn = f"{DB_HOST}:{DB_PORT}/{DB_SERVICE}"
            
            self.pool = oracledb.create_pool(
                user=DB_USER,
                password=DB_PASSWORD,
                dsn=dsn,
                min=2,
                max=10,
                increment=1
            )
            
            log_event("SUCCESS", "✅ Pool de conexiones Oracle creado exitosamente")
        
        except Exception as e:
            log_event("ERROR", f"❌ Error creando pool: {e}")
            raise
    
    def get_connection(self):
        """Obtener conexión del pool"""
        try:
            return self.pool.acquire()
        except Exception as e:
            log_event("ERROR", f"Error obteniendo conexión: {e}")
            raise
    
    def execute_query(self, query, params=None):
        """Ejecutar query SELECT"""
        conn = None
        cursor = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            columns = [desc[0] for desc in cursor.description]
            results = []
            
            for row in cursor.fetchall():
                results.append(dict(zip(columns, row)))
            
            return results
        
        except Exception as e:
            log_event("ERROR", f"Error ejecutando query: {e}")
            raise
        
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()
    
    def execute_insert(self, query, params=None):
        """Ejecutar INSERT/UPDATE/DELETE"""
        conn = None
        cursor = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            conn.commit()
            return {"success": True, "affected_rows": cursor.rowcount}
        
        except Exception as e:
            if conn:
                conn.rollback()
            log_event("ERROR", f"Error ejecutando insert: {e}")
            raise
        
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZAR APLICACIÓN FLASK
# ═══════════════════════════════════════════════════════════════════════════════

app = Flask(__name__)
db_pool = None

# ═══════════════════════════════════════════════════════════════════════════════
# ENDPOINTS - HEALTH CHECK
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    try:
        log_event("API", "GET /health")
        
        # Verificar conexión a BD
        conn = db_pool.get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1 FROM dual")
        cursor.close()
        conn.close()
        
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "database": "connected"
        }), 200
    
    except Exception as e:
        log_event("ERROR", f"Health check falló: {e}")
        return jsonify({
            "status": "unhealthy",
            "error": str(e)
        }), 503

# ═══════════════════════════════════════════════════════════════════════════════
# ENDPOINTS - TOURS
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/api/v1/tours', methods=['GET'])
def obtener_tours():
    """
    Obtener todos los tours disponibles
    """
    try:
        log_event("API", "GET /api/v1/tours")
        
        query = """
        SELECT 
            TO_FINI as fecha,
            TO_CUPOS as cupos_totales,
            TO_COSTO as costo,
            NVL((SELECT TO_CUPOS - COUNT(DISTINCT DI.DET_INS_ID)
                 FROM INSCRIPCIONES I
                 LEFT JOIN DET_INSCRIP DI ON I.INS_NUM = DI.DET_INS_INS
                 WHERE I.INS_TOUR = T.TO_FINI 
                 AND I.INS_ESTADO = 'PAGO'), TO_CUPOS) as cupos_disponibles
        FROM TOURS T
        WHERE TO_FINI > TRUNC(SYSDATE)
        ORDER BY TO_FINI ASC
        """
        
        tours = db_pool.execute_query(query)
        
        # Convertir dates a string
        for tour in tours:
            if isinstance(tour.get('fecha'), datetime):
                tour['fecha'] = tour['fecha'].strftime('%Y-%m-%d')
        
        log_event("SUCCESS", f"Tours obtenidos: {len(tours)}")
        
        return jsonify(tours), 200
    
    except Exception as e:
        log_event("ERROR", f"Error obteniendo tours: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/v1/tours/<fecha>', methods=['GET'])
def obtener_tour(fecha):
    """
    Obtener tour específico por fecha
    """
    try:
        log_event("API", f"GET /api/v1/tours/{fecha}")
        
        query = """
        SELECT 
            TO_FINI as fecha,
            TO_CUPOS as cupos_totales,
            TO_COSTO as costo
        FROM TOURS
        WHERE TO_FINI = TO_DATE(:fecha, 'YYYY-MM-DD')
        """
        
        tours = db_pool.execute_query(query, {"fecha": fecha})
        
        if not tours:
            return jsonify({"error": "Tour no encontrado"}), 404
        
        tour = tours[0]
        if isinstance(tour.get('fecha'), datetime):
            tour['fecha'] = tour['fecha'].strftime('%Y-%m-%d')
        
        return jsonify(tour), 200
    
    except Exception as e:
        log_event("ERROR", f"Error obteniendo tour: {e}")
        return jsonify({"error": str(e)}), 500

# ═══════════════════════════════════════════════════════════════════════════════
# ENDPOINTS - INSCRIPCIONES
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/api/v1/inscripciones', methods=['GET'])
def obtener_inscripciones():
    """
    Obtener todas las inscripciones
    """
    try:
        log_event("API", "GET /api/v1/inscripciones")
        
        query = """
        SELECT 
            I.INS_NUM,
            I.INS_FEMISION,
            I.INS_TOTAL,
            I.INS_ESTADO,
            I.INS_TOUR
        FROM INSCRIPCIONES I
        ORDER BY I.INS_FEMISION DESC
        """
        
        inscripciones = db_pool.execute_query(query)
        
        for insc in inscripciones:
            if isinstance(insc.get('INS_FEMISION'), datetime):
                insc['INS_FEMISION'] = insc['INS_FEMISION'].strftime('%Y-%m-%d %H:%M:%S')
            if isinstance(insc.get('INS_TOUR'), datetime):
                insc['INS_TOUR'] = insc['INS_TOUR'].strftime('%Y-%m-%d')
        
        log_event("SUCCESS", f"Inscripciones obtenidas: {len(inscripciones)}")
        
        return jsonify(inscripciones), 200
    
    except Exception as e:
        log_event("ERROR", f"Error obteniendo inscripciones: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/v1/inscripciones/crear', methods=['POST'])
def crear_inscripcion():
    """
    Crear nueva inscripción con participantes
    Payload:
    {
        "tour_fecha": "2025-09-08",
        "cantidad_participantes": 3,
        "costo_total": 10500.00,
        "participantes": [
            {
                "tipo": "ADULTO",
                "nombre": "Juan García",
                "dni": "12345678",
                "fnacimiento": "1985-03-15",
                "pais_nacionalidad": "ESPAÑA",
                "pasaporte": null
            }
        ]
    }
    """
    try:
        log_event("API", "POST /api/v1/inscripciones/crear")
        
        data = request.get_json()
        
        # Validación básica
        if not all(k in data for k in ['tour_fecha', 'cantidad_participantes', 'costo_total', 'participantes']):
            return jsonify({"error": "Datos incompletos"}), 400
        
        tour_fecha = data['tour_fecha']
        cantidad = data['cantidad_participantes']
        costo_total = data['costo_total']
        participantes = data['participantes']
        
        # Insertar inscripción
        insert_insc = """
        INSERT INTO INSCRIPCIONES (INS_NUM, INS_FEMISION, INS_TOTAL, INS_ESTADO, INS_TOUR)
        VALUES (INSCRIPCIONES_SEQ.NEXTVAL, SYSDATE, :costo, 'PENDIENTE', TO_DATE(:fecha, 'YYYY-MM-DD'))
        """
        
        conn = db_pool.get_connection()
        cursor = conn.cursor()
        
        # Insertar inscripción
        cursor.execute(insert_insc, {"costo": costo_total, "fecha": tour_fecha})
        
        # Obtener ID de inscripción creada
        cursor.execute("SELECT INSCRIPCIONES_SEQ.CURRVAL FROM DUAL")
        ins_num = cursor.fetchone()[0]
        
        # Insertar detalle de inscripción para cada participante
        for p in participantes:
            tipo_asistente = "ADULTO" if p['tipo'] == "ADULTO" else "MENOR"
            
            insert_det = """
            INSERT INTO DET_INSCRIP (DET_INS_ID, DET_INS_INS, DET_INS_TIPO, DET_INS_CLI, DET_INS_FAN)
            VALUES (DET_INSCRIP_SEQ.NEXTVAL, :ins_num, :tipo, NULL, NULL)
            """
            
            cursor.execute(insert_det, {"ins_num": ins_num, "tipo": tipo_asistente})
            
            # Insertar entrada
            insert_ent = """
            INSERT INTO ENTRADAS_TOUR (ENT_INSC, ENT_ID, ENT_TIPO_ASISTENTE)
            VALUES (:ins_num, ENTRADAS_SEQ.NEXTVAL, :tipo)
            """
            
            cursor.execute(insert_ent, {"ins_num": ins_num, "tipo": tipo_asistente})
        
        conn.commit()
        cursor.close()
        conn.close()
        
        log_event("SUCCESS", f"Inscripción creada: #{ins_num}")
        
        return jsonify({
            "ins_num": ins_num,
            "ins_femision": datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            "ins_total": costo_total,
            "ins_estado": "PENDIENTE"
        }), 201
    
    except Exception as e:
        log_event("ERROR", f"Error creando inscripción: {e}")
        return jsonify({"error": str(e)}), 500

# ═══════════════════════════════════════════════════════════════════════════════
# ENDPOINTS - PAGOS
# ═══════════════════════════════════════════════════════════════════════════════

@app.route('/api/v1/pagos/procesar', methods=['POST'])
def procesar_pago():
    """
    Procesar pago de inscripción
    """
    try:
        log_event("API", "POST /api/v1/pagos/procesar")
        
        data = request.get_json()
        
        if not all(k in data for k in ['inscripcion_num', 'metodo_pago', 'monto']):
            return jsonify({"error": "Datos incompletos"}), 400
        
        ins_num = data['inscripcion_num']
        metodo = data['metodo_pago']
        monto = data['monto']
        
        # Actualizar estado a PAGO
        update_insc = """
        UPDATE INSCRIPCIONES
        SET INS_ESTADO = 'PAGO'
        WHERE INS_NUM = :ins_num
        """
        
        conn = db_pool.get_connection()
        cursor = conn.cursor()
        
        cursor.execute(update_insc, {"ins_num": ins_num})
        
        # Insertar en auditoria
        insert_aud = """
        INSERT INTO AUDITORIA_TOURS (AUD_ID, AUD_FECHA, AUD_INSCRIPCION_NUM, AUD_TIPO_EVENTO, AUD_DESCRIPCION)
        VALUES (AUDITORIA_TOURS_SEQ.NEXTVAL, SYSDATE, :ins_num, 'PAGO_CONFIRMADO', :desc)
        """
        
        cursor.execute(insert_aud, {
            "ins_num": ins_num,
            "desc": f"Pago procesado - Método: {metodo} - Monto: ${monto}"
        })
        
        conn.commit()
        cursor.close()
        conn.close()
        
        log_event("SUCCESS", f"Pago procesado para inscripción #{ins_num}")
        
        return jsonify({
            "success": True,
            "message": "Pago procesado correctamente",
            "inscripcion_num": ins_num
        }), 200
    
    except Exception as e:
        log_event("ERROR", f"Error procesando pago: {e}")
        return jsonify({"error": str(e)}), 500

# ═══════════════════════════════════════════════════════════════════════════════
# INICIAR SERVIDOR
# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("=" * 80)
    log_event("INFO", "════════════════════════════════════════════════════════════════════════════════")
    
    try:
        # Inicializar pool
        db_pool = OraclePool()
        
        log_event("INFO", "════════════════════════════════════════════════════════════════════════════════")
        log_event("INFO", "INICIANDO BACKEND API - LEGO STORE")
        log_event("INFO", "════════════════════════════════════════════════════════════════════════════════")
        log_event("INFO", f"Base de datos: {DB_HOST}:{DB_PORT}/{DB_SERVICE}")
        log_event("INFO", f"Usuario: {DB_USER}")
        log_event("INFO", f"Flask: {FLASK_HOST}:{FLASK_PORT}")
        log_event("INFO", "════════════════════════════════════════════════════════════════════════════════")
        log_event("SUCCESS", "✅ Pool de conexiones Oracle creado exitosamente")
        log_event("SUCCESS", "✅ Iniciando servidor Flask...")
        log_event("SUCCESS", f"✅ Servidor disponible en http://{FLASK_HOST}:{FLASK_PORT}")
        log_event("INFO", "════════════════════════════════════════════════════════════════════════════════")
        
        # Iniciar servidor
        app.run(host=FLASK_HOST, port=FLASK_PORT, debug=False)
    
    except Exception as e:
        log_event("ERROR", f"Error iniciando servidor: {e}")
        print("=" * 80)
