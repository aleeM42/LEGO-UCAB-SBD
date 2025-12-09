from flask import Flask, jsonify, request
import oracledb
from datetime import datetime
import os
from dotenv import load_dotenv
import logging

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

load_dotenv()

# Oracle Connection – usa EXACTAMENTE lo que tienes en .env
ORACLE_HOST = os.getenv("ORACLE_HOST", "localhost")
ORACLE_PORT = int(os.getenv("ORACLE_PORT", "1521"))
ORACLE_PDB  = os.getenv("ORACLE_PDB", "FREEPDB1")  # service_name correcto

DB_USER = os.getenv("DB_USER", "maria_M")
DB_PASSWORD = os.getenv("DB_PASS", "MariaMarin123")

# Flask
FLASK_HOST = os.getenv("FLASK_HOST", "127.0.0.1")
FLASK_PORT = int(os.getenv("FLASK_PORT", "5000"))

# ═══════════════════════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════════════════════

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def log_event(category, message):
    ts = datetime.now().strftime("%H:%M:%S")
    # quito emojis para evitar UnicodeEncodeError en consola Windows
    print(f"[{ts}] {category:12} | {message}")
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
            log_event("INIT", "Creando pool de conexiones Oracle...")
            self.pool = oracledb.create_pool(
                user=DB_USER,
                password=DB_PASSWORD,
                host=ORACLE_HOST,
                port=ORACLE_PORT,
                service_name=ORACLE_PDB,   # <─ AQUÍ USAMOS FREEPDB1
                min=2,
                max=10,
                increment=1
            )
            log_event("SUCCESS", "Pool de conexiones Oracle creado exitosamente")
        except Exception as e:
            log_event("ERROR", f"Error creando pool: {e}")
            raise

    def get_connection(self):
        """Obtener conexión del pool"""
        try:
            return self.pool.acquire()
        except Exception as e:
            log_event("ERROR", f"Error obteniendo conexión: {e}")
            raise

    def execute_query(self, query, params=None):
        """Ejecutar query SELECT y retornar lista de dicts"""
        conn = None
        cursor = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            columns = [d[0] for d in cursor.description]
            rows = []
            for row in cursor.fetchall():
                rows.append(dict(zip(columns, row)))
            return rows
        except Exception as e:
            log_event("ERROR", f"Error ejecutando query: {e}")
            raise
        finally:
            if cursor:
                cursor.close()
            if conn:
                conn.close()

    def execute_insert(self, query, params=None):
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
# FLASK APP
# ═══════════════════════════════════════════════════════════════════════════════

app = Flask(__name__)
db_pool = None

# ───────────── HEALTH ─────────────

@app.route("/health", methods=["GET"])
def health():
    try:
        log_event("API", "GET /health")
        conn = db_pool.get_connection()
        cur = conn.cursor()
        cur.execute("SELECT 1 FROM dual")
        cur.fetchone()
        cur.close()
        conn.close()
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "database": "connected"
        }), 200
    except Exception as e:
        log_event("ERROR", f"Health check falló: {e}")
        return jsonify({"status": "unhealthy", "error": str(e)}), 503

# ───────────── TOURS ─────────────

@app.route("/api/v1/tours", methods=["GET"])
def get_tours():
    """
    Devuelve todos los tours registrados (no solo futuros) con información de cupos.
    """
    try:
        log_event("API", "GET /api/v1/tours")
        conn = db_pool.get_connection()
        cur = conn.cursor()
        
        # Obtener todos los tours con información de cupos
        sql = """
            SELECT 
                t.to_fini AS fecha_tour,
                t.to_cupos AS cupos_totales,
                t.to_costo AS costo_por_persona,
                COUNT(DISTINCT CASE WHEN i.ins_estado = 'PAGO' THEN di.det_ins_id END) AS inscritos_confirmados,
                t.to_cupos - COUNT(DISTINCT CASE WHEN i.ins_estado = 'PAGO' THEN di.det_ins_id END) AS cupos_disponibles,
                CASE WHEN fn_inscripcion_abierta(t.to_fini) THEN 'ABIERTA'
                     ELSE 'CERRADA' END AS estado_inscripcion,
                CASE WHEN t.to_fini > SYSDATE THEN 'FUTURO'
                     WHEN t.to_fini = TRUNC(SYSDATE) THEN 'HOY'
                     ELSE 'PASADO' END AS tipo_fecha
            FROM tours t
            LEFT JOIN inscripciones i ON t.to_fini = i.ins_tour
            LEFT JOIN det_inscrip di ON i.ins_num = di.det_ins_ins
            GROUP BY t.to_fini, t.to_cupos, t.to_costo
            ORDER BY t.to_fini DESC
        """
        
        cur.execute(sql)
        tours = []
        for row in cur.fetchall():
            costo_usd = float(row[2]) if row[2] else 0.0
            # Convertir USD a DKK para mostrar (3500 USD = 23000 DKK exactamente)
            # Usar redondeo para asegurar que 3500 USD = 23000 DKK exactamente
            costo_dkk = round(costo_usd * (23000 / 3500), 2)
            tours.append({
                "fecha": row[0].strftime("%Y-%m-%d") if row[0] else None,
                "cupos_totales": int(row[1]) if row[1] else 0,
                "costo": costo_dkk,  # Mostrar en DKK
                "costo_usd": costo_usd,  # Precio original en USD
                "inscritos_confirmados": int(row[3]) if row[3] else 0,
                "cupos_disponibles": max(0, int(row[4])) if row[4] is not None else int(row[1]) if row[1] else 0,
                "estado_inscripcion": row[5] if row[5] else "CERRADA",
                "tipo_fecha": row[6] if row[6] else "FUTURO"
            })
        
        cur.close()
        conn.close()
        
        log_event("SUCCESS", f"Tours obtenidos: {len(tours)}")
        return jsonify(tours), 200

    except Exception as e:
        log_event("ERROR", f"Error en /api/v1/tours: {e}")
        return jsonify({"error": "Error obteniendo tours", "detalle": str(e)}), 500

# ───────────── INSCRIPCIONES ─────────────

@app.route("/api/v1/tours/<fecha>/cupos", methods=["GET"])
def verificar_cupos_tour(fecha):
    """
    Verifica cupos disponibles para un tour específico.
    """
    try:
        log_event("API", f"GET /api/v1/tours/{fecha}/cupos")
        conn = db_pool.get_connection()
        cur = conn.cursor()
        
        # Llamar a la función verificar_cupos
        cur.execute("""
            SELECT verificar_cupos(TO_DATE(:fecha, 'YYYY-MM-DD')) FROM dual
        """, {"fecha": fecha})
        
        cupos_disponibles = cur.fetchone()[0]
        cur.close()
        conn.close()
        
        return jsonify({
            "fecha_tour": fecha,
            "cupos_disponibles": int(cupos_disponibles) if cupos_disponibles else 0
        }), 200
        
    except oracledb.DatabaseError as e:
        err = e.args[0]
        log_event("ERROR", f"Error Oracle en verificar_cupos: {err}")
        return jsonify({"error": str(err)}), 400
    except Exception as e:
        log_event("ERROR", f"Error general en verificar_cupos: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/v1/clientes/<int:cli_id>", methods=["GET"])
def obtener_cliente(cli_id):
    """
    Obtiene información completa de un cliente usando obtener_cliente_info.
    """
    try:
        log_event("API", f"GET /api/v1/clientes/{cli_id}")
        conn = db_pool.get_connection()
        cur = conn.cursor()
        
        # Llamar a la función obtener_cliente_info
        cursor_resultado = cur.var(oracledb.CURSOR)
        cur.execute("""
            BEGIN
                :cursor_resultado := obtener_cliente_info(:p_cli_id);
            END;
        """, cursor_resultado=cursor_resultado, p_cli_id=cli_id)
        
        cursor_ref = cursor_resultado.getvalue()
        cliente_data = None
        
        for row in cursor_ref:
            cliente_data = {
                "cli_id": int(row[0]) if row[0] else None,
                "cli_pnombre": row[1] if row[1] else "",
                "cli_papellido": row[2] if row[2] else "",
                "cli_sapellido": row[3] if row[3] else "",
                "cli_snombre": row[4] if row[4] else "",
                "cli_dni": int(row[5]) if row[5] else None,
                "cli_fnacimiento": row[6].strftime("%Y-%m-%d") if row[6] else None,
                "cli_nac": int(row[7]) if row[7] else None,
                "cli_reside": int(row[8]) if row[8] else None,
                "cli_numpas": row[9] if row[9] else None,
                "cli_fvenpas": row[10].strftime("%Y-%m-%d") if row[10] else None,
                "edad_calculada": int(row[11]) if row[11] else None,
                "pais_id": int(row[12]) if row[12] else None,
                "pais_nombre": row[13] if row[13] else "",
                "pais_pertenece_ue": row[14] if row[14] else "NO"
            }
            break
        
        cursor_ref.close()
        cur.close()
        conn.close()
        
        if not cliente_data:
            return jsonify({"error": f"Cliente {cli_id} no encontrado"}), 404
        
        return jsonify(cliente_data), 200
        
    except oracledb.DatabaseError as e:
        err = e.args[0]
        log_event("ERROR", f"Error Oracle en obtener_cliente: {err}")
        return jsonify({"error": str(err)}), 400
    except Exception as e:
        log_event("ERROR", f"Error general en obtener_cliente: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/v1/fans-lego/<int:fl_id>", methods=["GET"])
def obtener_fan_lego(fl_id):
    """
    Obtiene información completa de un fan LEGO con su representante usando obtener_datos_fl.
    """
    try:
        log_event("API", f"GET /api/v1/fans-lego/{fl_id}")
        conn = db_pool.get_connection()
        cur = conn.cursor()
        
        # Llamar a la función obtener_datos_fl
        cursor_resultado = cur.var(oracledb.CURSOR)
        cur.execute("""
            BEGIN
                :cursor_resultado := obtener_datos_fl(:p_fl_id);
            END;
        """, cursor_resultado=cursor_resultado, p_fl_id=fl_id)
        
        cursor_ref = cursor_resultado.getvalue()
        fan_data = None
        
        for row in cursor_ref:
            fan_data = {
                # Datos del Fan
                "fl_id": int(row[0]) if row[0] else None,
                "fl_pnombre": row[1] if row[1] else "",
                "fl_papellido": row[2] if row[2] else "",
                "fl_sapellido": row[3] if row[3] else "",
                "fl_snombre": row[4] if row[4] else "",
                "fl_dni": int(row[5]) if row[5] else None,
                "fl_fnacimiento": row[6].strftime("%Y-%m-%d") if row[6] else None,
                "fl_nac": int(row[7]) if row[7] else None,
                "fl_numpas": row[8] if row[8] else None,
                "fl_fvenpas": row[9].strftime("%Y-%m-%d") if row[9] else None,
                "edad_fan": int(row[10]) if row[10] else None,
                "pais_fan_nombre": row[11] if row[11] else "",
                "pais_fan_ue": row[12] if row[12] else "NO",
                # Datos del Representante
                "rep_cli_id": int(row[13]) if row[13] else None,
                "rep_pnombre": row[14] if row[14] else "",
                "rep_papellido": row[15] if row[15] else "",
                "rep_sapellido": row[16] if row[16] else "",
                "rep_snombre": row[17] if row[17] else "",
                "rep_dni": int(row[18]) if row[18] else None,
                "rep_fnacimiento": row[19].strftime("%Y-%m-%d") if row[19] else None,
                "edad_representante": int(row[20]) if row[20] else None,
                "rep_pais_nac": int(row[21]) if row[21] else None,
                "rep_pais_nombre": row[22] if row[22] else "",
                "rep_numpas": row[23] if row[23] else None,
                "rep_fvenpas": row[24].strftime("%Y-%m-%d") if row[24] else None
            }
            break
        
        cursor_ref.close()
        cur.close()
        conn.close()
        
        if not fan_data:
            return jsonify({"error": f"Fan LEGO {fl_id} no encontrado"}), 404
        
        return jsonify(fan_data), 200
        
    except oracledb.DatabaseError as e:
        err = e.args[0]
        log_event("ERROR", f"Error Oracle en obtener_fan_lego: {err}")
        return jsonify({"error": str(err)}), 400
    except Exception as e:
        log_event("ERROR", f"Error general en obtener_fan_lego: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/v1/inscripciones/crear", methods=["POST"])
def crear_inscripcion():
    """
    Crea una inscripción llamando a sp_crear_inscripcion.
    Body JSON esperado:
    {
      "tour_fecha": "2025-12-10",
      "cliente_responsable": 123,   -- cli_id
      "participantes_json": "ADULTO:123;MENOR:5;MENOR:7"
    }
    """
    try:
        data = request.get_json(force=True)

        tour_fecha_str = data.get("tour_fecha")
        cliente_responsable = data.get("cliente_responsable")
        participantes_json = data.get("participantes_json")

        if not tour_fecha_str or not cliente_responsable or not participantes_json:
            return jsonify({"error": "Faltan datos requeridos"}), 400

        # Convertir fecha de string a DATE en Oracle
        conn = db_pool.get_connection()
        cur = conn.cursor()

        # Crear variables para parámetros OUT
        o_ins_num = cur.var(oracledb.NUMBER)
        o_total = cur.var(oracledb.NUMBER)
        o_msg = cur.var(oracledb.STRING)

        plsql = """
        BEGIN
            sp_crear_inscripcion(
                p_tour_fecha         => TO_DATE(:p_fecha, 'YYYY-MM-DD'),
                p_cliente_responsable => :p_cli,
                p_participantes_json  => :p_part,
                p_numero_inscripcion  => :o_ins_num,
                p_costo_total         => :o_total,
                p_mensaje             => :o_msg
            );
        END;
        """

        try:
            cur.execute(
                plsql,
                {
                    "p_fecha": tour_fecha_str,
                    "p_cli": int(cliente_responsable),
                    "p_part": participantes_json,
                    "o_ins_num": o_ins_num,
                    "o_total": o_total,
                    "o_msg": o_msg,
                },
            )
        except oracledb.DatabaseError as db_err:
            # Si hay un error, el procedimiento puede haber asignado -1
            log_event("ERROR", f"Error ejecutando procedimiento: {db_err}")
            # Intentar obtener valores de todos modos
            pass
        
        # Hacer commit para asegurar que los cambios se guarden
        conn.commit()
        
        # Obtener valores de los parámetros OUT DESPUÉS del commit
        # Para parámetros OUT, getvalue() puede retornar el valor directamente o una lista
        ins_num_raw = o_ins_num.getvalue()
        total_raw = o_total.getvalue()
        msg_raw = o_msg.getvalue()
        
        # Manejar diferentes formatos de retorno
        ins_num_val = ins_num_raw[0] if isinstance(ins_num_raw, (list, tuple)) and len(ins_num_raw) > 0 else ins_num_raw
        total_val = total_raw[0] if isinstance(total_raw, (list, tuple)) and len(total_raw) > 0 else total_raw
        msg_val = msg_raw[0] if isinstance(msg_raw, (list, tuple)) and len(msg_raw) > 0 else (msg_raw or "")
        
        log_event("DEBUG", f"Valores obtenidos del procedimiento - ins_num: {ins_num_val}, total: {total_val}, msg: {msg_val}")
        
        # Hacer commit para asegurar que los cambios se guarden (el procedimiento ya hace commit, pero por si acaso)
        conn.commit()
        
        # Si el mensaje contiene "Error" o el número es -1, el procedimiento falló
        if (msg_val and "Error" in msg_val) or ins_num_val == -1:
            log_event("ERROR", f"El procedimiento reportó un error - ins_num: {ins_num_val}, msg: {msg_val}")
            cur.close()
            conn.close()
            error_msg = msg_val if msg_val and "Error" in msg_val else "Error al crear inscripción: el procedimiento retornó un número de inscripción inválido"
            return jsonify({"error": error_msg}), 400
        
        # Si aún es None, intentar obtener de la BD usando el cliente responsable y tour
        if ins_num_val is None:
            log_event("WARNING", f"ins_num_val es {ins_num_val}, intentando obtener de BD...")
            # Obtener el último número de inscripción creado para este cliente responsable y tour
            cur.execute("""
                SELECT MAX(i.ins_num) 
                FROM inscripciones i
                JOIN det_inscrip di ON i.ins_num = di.det_ins_ins
                WHERE i.ins_tour = TO_DATE(:fecha, 'YYYY-MM-DD')
                  AND di.det_ins_cli = :cli_id
                ORDER BY i.ins_num DESC
                FETCH FIRST 1 ROW ONLY
            """, {"fecha": tour_fecha_str, "cli_id": int(cliente_responsable)})
            row = cur.fetchone()
            if row and row[0] and row[0] is not None:
                ins_num_val = int(row[0])
                log_event("SUCCESS", f"Número de inscripción obtenido de BD: {ins_num_val}")
            else:
                # Si aún no funciona, obtener el máximo número de inscripción reciente (últimos 5 minutos)
                cur.execute("""
                    SELECT MAX(ins_num) FROM inscripciones
                    WHERE ins_tour = TO_DATE(:fecha, 'YYYY-MM-DD')
                      AND ins_femision >= SYSDATE - 5/1440
                      AND ins_estado = 'PENDIENTE'
                """, {"fecha": tour_fecha_str})
                row = cur.fetchone()
                if row and row[0] and row[0] is not None:
                    ins_num_val = int(row[0])
                    log_event("SUCCESS", f"Número de inscripción obtenido de BD (método alternativo): {ins_num_val}")
                else:
                    # Último intento: obtener el máximo número de inscripción sin filtros de fecha
                    cur.execute("""
                        SELECT MAX(ins_num) FROM inscripciones
                        WHERE ins_estado = 'PENDIENTE'
                          AND ins_femision >= SYSDATE - 5/1440
                    """)
                    row = cur.fetchone()
                    if row and row[0] and row[0] is not None:
                        ins_num_val = int(row[0])
                        log_event("SUCCESS", f"Número de inscripción obtenido de BD (último método): {ins_num_val}")
        
        # Si después de todos los intentos sigue siendo None o -1, hay un problema
        if ins_num_val is None or ins_num_val == -1:
            # Intentar una última vez: obtener la última inscripción creada sin filtros
            cur.execute("""
                SELECT ins_num, ins_total, ins_femision
                FROM inscripciones
                WHERE ins_estado = 'PENDIENTE'
                  AND ins_femision >= SYSDATE - 10/1440
                ORDER BY ins_femision DESC
                FETCH FIRST 1 ROW ONLY
            """)
            row = cur.fetchone()
            if row and row[0] and row[0] is not None:
                ins_num_val = int(row[0])
                if total_val is None or total_val == 0:
                    total_val = float(row[1]) if row[1] else 0
                log_event("SUCCESS", f"Número de inscripción obtenido de BD (método final): {ins_num_val}")
        
        if total_val is None:
            log_event("WARNING", "total_val es None")
            total_val = 0
        
        conn.commit()
        
        # Obtener nacionalidad del cliente responsable para determinar moneda
        cur.execute("""
            SELECT p.p_ue, p.p_nom
            FROM clientes c
            JOIN paises p ON c.cli_nac = p.p_id
            WHERE c.cli_id = :cli_id
        """, {"cli_id": int(cliente_responsable)})
        
        row = cur.fetchone()
        pertenece_ue = row[0] if row else "NO"
        pais_nombre = row[1] if row else ""
        
        # Determinar moneda: EUR si es UE, USD si no
        moneda = "EUR" if pertenece_ue == "SI" else "USD"
        
        # Obtener precio del tour en USD (precio base en BD)
        cur.execute("""
            SELECT to_costo
            FROM tours
            WHERE to_fini = TO_DATE(:fecha, 'YYYY-MM-DD')
        """, {"fecha": tour_fecha_str})
        
        tour_row = cur.fetchone()
        precio_usd = float(tour_row[0]) if tour_row else 0.0
        
        # Convertir USD a DKK para mostrar (3500 USD = 23000 DKK exactamente)
        precio_dkk = round(precio_usd * (23000 / 3500), 2)
        
        # Convertir a la moneda final según nacionalidad del cliente
        # Si es UE: convertir USD a EUR (1 USD ≈ 0.88 EUR, basado en 3500 USD = 3081 EUR)
        # Si no es UE: mantener en USD
        if moneda == "EUR":
            # 3500 USD = 3081 EUR → 1 USD = 0.8797 EUR
            precio_convertido = precio_usd * 0.8797
        else:  # USD
            precio_convertido = precio_usd  # Ya está en USD
        
        # Calcular total en la moneda correcta
        cantidad_participantes = len(participantes_json.split(";"))
        total_en_moneda = precio_convertido * cantidad_participantes
        
        if ins_num_val is None or ins_num_val == -1:
            log_event("ERROR", f"Procedimiento no retornó número de inscripción válido - ins_num: {ins_num_val}")
            cur.close()
            conn.close()
            return jsonify({"error": "Error al crear inscripción: número de inscripción no válido"}), 500
        
        if total_val is None:
            log_event("ERROR", "Procedimiento no retornó total válido")
            cur.close()
            conn.close()
            return jsonify({"error": "Error al crear inscripción: total no válido"}), 500
        
        # Contar entradas generadas para esta inscripción
        cur.execute("""
            SELECT COUNT(*) FROM entradas_tour WHERE ent_insc = :ins_num
        """, {"ins_num": int(ins_num_val)})
        
        entradas_row = cur.fetchone()
        entradas_generadas = int(entradas_row[0]) if entradas_row and entradas_row[0] else 0
        
        # Si no hay entradas, las entradas deberían haberse generado en el procedimiento
        # Verificar que el número de entradas coincida con el número de participantes
        if entradas_generadas == 0:
            log_event("WARNING", f"No se encontraron entradas para inscripción {ins_num_val}, deberían ser {cantidad_participantes}")
        elif entradas_generadas != cantidad_participantes:
            log_event("WARNING", f"Número de entradas ({entradas_generadas}) no coincide con participantes ({cantidad_participantes})")
        
        cur.close()
        conn.close()

        log_event("SUCCESS", f"Inscripción creada - Número: {ins_num_val}, Total USD (BD): {total_val}, Total {moneda}: {total_en_moneda}, Entradas: {entradas_generadas}")
        
        return jsonify({
            "ins_num": int(ins_num_val),
            "ins_total": float(total_en_moneda),  # Total en la moneda correcta (EUR o USD)
            "ins_total_usd": float(total_val),  # Total en USD (precio base en BD)
            "ins_total_dkk": float(precio_dkk * cantidad_participantes),  # Total en DKK (para mostrar)
            "moneda": moneda,
            "precio_unitario": float(precio_convertido),  # Precio unitario en moneda final
            "precio_unitario_usd": float(precio_usd),  # Precio unitario en USD (BD)
            "precio_unitario_dkk": float(precio_dkk),  # Precio unitario en DKK (para mostrar)
            "pais_cliente": pais_nombre,
            "pertenece_ue": pertenece_ue,
            "entradas_generadas": entradas_generadas,
            "cantidad_participantes": cantidad_participantes,
            "mensaje": msg_val,
            "estado": "PENDIENTE"
        }), 201

    except oracledb.DatabaseError as e:
        err = e.args[0]
        log_event("ERROR", f"Error Oracle en crear_inscripcion: {err}")
        # devolvemos el texto exacto del error de negocio
        return jsonify({"error": str(err)}), 400
    except Exception as e:
        log_event("ERROR", f"Error general en crear_inscripcion: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/v1/paises", methods=["GET"])
def obtener_paises():
    """
    Obtiene la lista de países disponibles.
    """
    try:
        log_event("API", "GET /api/v1/paises")
        sql = """
            SELECT 
                p_id,
                p_nom,
                p_ue,
                p_nac
            FROM paises
            ORDER BY p_nom
        """
        rows = db_pool.execute_query(sql)
        
        paises = []
        for r in rows:
            paises.append({
                "p_id": int(r["P_ID"]),
                "p_nom": r["P_NOM"],
                "p_ue": r["P_UE"],
                "p_nac": r["P_NAC"]
            })
        
        log_event("SUCCESS", f"Países obtenidos: {len(paises)}")
        return jsonify(paises), 200
        
    except Exception as e:
        log_event("ERROR", f"Error en /api/v1/paises: {e}")
        return jsonify({"error": "Error obteniendo países", "detalle": str(e)}), 500

@app.route("/api/v1/clientes/registrar", methods=["POST"])
def registrar_cliente():
    """
    Registra un nuevo cliente usando sp_registrar_cliente_nuevo.
    Body JSON esperado:
    {
      "p_pnombre": "Juan",
      "p_papellido": "Pérez",
      "p_sapellido": "García",
      "p_dni": 12345678,
      "p_fnacimiento": "1990-01-15",
      "p_nac": 1,
      "p_reside": 1,
      "p_numpas": "AB123456",
      "p_fvenpas": "2030-01-15",
      "p_snombre": "Carlos"
    }
    """
    try:
        data = request.get_json(force=True)
        
        conn = db_pool.get_connection()
        cur = conn.cursor()
        
        # Llamar al procedimiento almacenado
        plsql = """
        BEGIN
            sp_registrar_cliente_nuevo(
                p_pnombre     => :p_pnombre,
                p_papellido   => :p_papellido,
                p_sapellido   => :p_sapellido,
                p_dni         => :p_dni,
                p_fnacimiento => TO_DATE(:p_fnacimiento, 'YYYY-MM-DD'),
                p_nac         => :p_nac,
                p_reside      => :p_reside,
                p_numpas      => :p_numpas,
                p_fvenpas     => CASE WHEN :p_fvenpas IS NOT NULL THEN TO_DATE(:p_fvenpas, 'YYYY-MM-DD') ELSE NULL END,
                p_snombre     => :p_snombre
            );
        END;
        """
        p_snombre = data.get("p_snombre").upper() if data.get("p_snombre") else None
        
        cur.execute(
            plsql,
            {
                "p_pnombre": data.get("p_pnombre").upper(),
                "p_papellido": data.get("p_papellido").upper(),
                "p_sapellido": data.get("p_sapellido").upper(),
                "p_dni": int(data.get("p_dni")),
                "p_fnacimiento": data.get("p_fnacimiento"),
                "p_nac": int(data.get("p_nac")),
                "p_reside": int(data.get("p_reside")),
                "p_numpas": data.get("p_numpas") if data.get("p_numpas") else None,
                "p_fvenpas": data.get("p_fvenpas") if data.get("p_fvenpas") else None,
                "p_snombre": p_snombre
            }
        )
        
        # Obtener el ID del cliente recién creado
        cur.execute("""
            SELECT cli_id 
            FROM clientes 
            WHERE cli_dni = :dni
            ORDER BY cli_id DESC
            FETCH FIRST 1 ROW ONLY
        """, {"dni": int(data.get("p_dni"))})
        
        row = cur.fetchone()
        cli_id = int(row[0]) if row else None
        
        conn.commit()
        cur.close()
        conn.close()
        
        log_event("SUCCESS", f"Cliente registrado: ID {cli_id}")
        return jsonify({
            "success": True,
            "cli_id": cli_id,
            "mensaje": f"Cliente registrado exitosamente con ID: {cli_id}"
        }), 201
        
    except oracledb.DatabaseError as e:
        err = e.args[0]
        log_event("ERROR", f"Error Oracle en registrar_cliente: {err}")
        return jsonify({"error": str(err)}), 400
    except Exception as e:
        log_event("ERROR", f"Error general en registrar_cliente: {e}")
        return jsonify({"error": str(e)}), 500

@app.route("/api/v1/fans-lego/registrar", methods=["POST"])
def registrar_fan_lego():
    """
    Registra un nuevo fan LEGO.
    Body JSON esperado:
    {
      "fl_pnombre": "María",
      "fl_papellido": "González",
      "fl_sapellido": "López",
      "fl_dni": 87654321,
      "fl_fnacimiento": "2010-05-20",
      "fl_nac": 1,
      "fl_numpas": "CD789012",
      "fl_fvenpas": "2030-05-20",
      "fl_snombre": "Ana",
      "fl_repre": 1
    }
    """
    try:
        data = request.get_json(force=True)
        
        conn = db_pool.get_connection()
        cur = conn.cursor()
        
        # Obtener siguiente ID de la secuencia
        cur.execute("SELECT f_lego_seq.NEXTVAL FROM dual")
        fl_id = int(cur.fetchone()[0])
        
        # Insertar fan LEGO
        sql = """
            INSERT INTO f_lego (
                fl_id,
                fl_pnombre,
                fl_papellido,
                fl_sapellido,
                fl_dni,
                fl_fnacimiento,
                fl_nac,
                fl_numpas,
                fl_fvenpas,
                fl_snombre,
                fl_repre
            ) VALUES (
                :fl_id,
                :fl_pnombre,
                :fl_papellido,
                :fl_sapellido,
                :fl_dni,
                TO_DATE(:fl_fnacimiento, 'YYYY-MM-DD'),
                :fl_nac,
                :fl_numpas,
                CASE WHEN :fl_fvenpas IS NOT NULL THEN TO_DATE(:fl_fvenpas, 'YYYY-MM-DD') ELSE NULL END,
                :fl_snombre,
                :fl_repre
            )
        """
        
        cur.execute(
            sql,
            {
                "fl_id": fl_id,
                "fl_pnombre": data.get("fl_pnombre").upper(),
                "fl_papellido": data.get("fl_papellido").upper(),
                "fl_sapellido": data.get("fl_sapellido").upper(),
                "fl_dni": int(data.get("fl_dni")),
                "fl_fnacimiento": data.get("fl_fnacimiento"),
                "fl_nac": int(data.get("fl_nac")),
                "fl_numpas": data.get("fl_numpas") if data.get("fl_numpas") else None,
                "fl_fvenpas": data.get("fl_fvenpas") if data.get("fl_fvenpas") else None,
                "fl_snombre": data.get("fl_snombre").upper() if data.get("fl_snombre").upper() else None,
                "fl_repre": int(data.get("fl_repre")) if data.get("fl_repre") else None
            }
        )
        
        conn.commit()
        cur.close()
        conn.close()
        
        log_event("SUCCESS", f"Fan LEGO registrado: ID {fl_id}")
        return jsonify({
            "success": True,
            "fl_id": fl_id,
            "mensaje": f"Fan LEGO registrado exitosamente con ID: {fl_id}"
        }), 201
        
    except oracledb.DatabaseError as e:
        err = e.args[0]
        log_event("ERROR", f"Error Oracle en registrar_fan_lego: {err}")
        try:
            if conn:
                conn.rollback()
        except:
            pass
        return jsonify({"error": str(err)}), 400
    except Exception as e:
        log_event("ERROR", f"Error general en registrar_fan_lego: {e}")
        try:
            if conn:
                conn.rollback()
        except:
            pass
        return jsonify({"error": str(e)}), 500

@app.route("/api/v1/pagos/confirmar", methods=["POST"])
def confirmar_pago():
    """
    Confirma el pago de una inscripción usando sp_confirmar_pago_inscripcion.
    Body JSON esperado:
    {
      "inscripcion_num": 123,
      "moneda_pago": "USD",
      "monto_pagado": 500.00,
      "referencia_pago": "REF-12345"
    }
    """
    try:
        data = request.get_json(force=True)
        
        inscripcion_num = data.get("inscripcion_num")
        moneda_pago = data.get("moneda_pago", "USD")
        monto_pagado = data.get("monto_pagado")
        referencia_pago = data.get("referencia_pago", "")
        
        if not inscripcion_num:
            return jsonify({"error": "Faltan datos requeridos: número de inscripción"}), 400
        
        # Si no se proporciona monto, obtenerlo de la inscripción
        if not monto_pagado:
            conn_temp = db_pool.get_connection()
            cur_temp = conn_temp.cursor()
            cur_temp.execute("""
                SELECT ins_total FROM inscripciones WHERE ins_num = :ins_num
            """, {"ins_num": int(inscripcion_num)})
            row = cur_temp.fetchone()
            if row:
                monto_pagado = float(row[0])
            else:
                cur_temp.close()
                conn_temp.close()
                return jsonify({"error": "Inscripción no encontrada"}), 404
            cur_temp.close()
            conn_temp.close()
        
        conn = db_pool.get_connection()
        cur = conn.cursor()
        
        plsql = """
        DECLARE
            v_recibo      VARCHAR2(100);
            v_entradas    NUMBER;
            v_msg         VARCHAR2(4000);
        BEGIN
            sp_confirmar_pago_inscripcion(
                p_numero_inscripcion => :p_ins_num,
                p_moneda_pago        => :p_moneda,
                p_monto_pagado       => :p_monto,
                p_referencia_pago    => :p_ref,
                p_recibo_generado    => v_recibo,
                p_entradas_generadas => v_entradas,
                p_mensaje            => v_msg
            );
            :o_recibo := v_recibo;
            :o_entradas := v_entradas;
            :o_msg := v_msg;
        END;
        """
        
        o_recibo = cur.var(oracledb.STRING)
        o_entradas = cur.var(oracledb.NUMBER)
        o_msg = cur.var(oracledb.STRING)
        
        cur.execute(
            plsql,
            {
                "p_ins_num": int(inscripcion_num),
                "p_moneda": moneda_pago,
                "p_monto": float(monto_pagado),
                "p_ref": referencia_pago,
                "o_recibo": o_recibo,
                "o_entradas": o_entradas,
                "o_msg": o_msg
            }
        )
        
        conn.commit()
        
        # Obtener valores de los parámetros OUT
        recibo_raw = o_recibo.getvalue()
        entradas_raw = o_entradas.getvalue()
        msg_raw = o_msg.getvalue()
        
        # Manejar diferentes formatos de retorno
        recibo_val = recibo_raw[0] if isinstance(recibo_raw, (list, tuple)) else recibo_raw
        entradas_val = entradas_raw[0] if isinstance(entradas_raw, (list, tuple)) else entradas_raw
        msg_val = msg_raw[0] if isinstance(msg_raw, (list, tuple)) else (msg_raw or "")
        
        # Si el número de entradas es 0 o None, verificar directamente en la BD
        if not entradas_val or entradas_val == 0:
            log_event("WARNING", f"Procedimiento retornó {entradas_val} entradas, verificando en BD...")
            cur.execute("""
                SELECT COUNT(*) FROM entradas_tour WHERE ent_insc = :ins_num
            """, {"ins_num": int(inscripcion_num)})
            row = cur.fetchone()
            if row and row[0] and row[0] > 0:
                entradas_val = int(row[0])
                log_event("SUCCESS", f"Entradas encontradas en BD: {entradas_val}")
        
        cur.close()
        conn.close()
        
        log_event("SUCCESS", f"Pago confirmado - Inscripción: {inscripcion_num}, Entradas: {entradas_val}, Recibo: {recibo_val}")
        
        return jsonify({
            "inscripcion_num": int(inscripcion_num),
            "recibo": recibo_val or "",
            "entradas_generadas": int(entradas_val) if entradas_val else 0,
            "mensaje": msg_val,
            "estado": "PAGO"
        }), 200
        
    except oracledb.DatabaseError as e:
        err = e.args[0]
        log_event("ERROR", f"Error Oracle en confirmar_pago: {err}")
        return jsonify({"error": str(err)}), 400
    except Exception as e:
        log_event("ERROR", f"Error general en confirmar_pago: {e}")
        return jsonify({"error": str(e)}), 500


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("=" * 80)
    log_event("INFO", "Iniciando backend LEGO...")
    try:
        db_pool = OraclePool()
        log_event("INFO", f"Base de datos: {ORACLE_HOST}:{ORACLE_PORT}/{ORACLE_PDB}")
        log_event("INFO", f"Usuario: {DB_USER}")
        log_event("INFO", f"Flask: {FLASK_HOST}:{FLASK_PORT}")
        log_event("INFO", "Backend listo. Abre /health o /api/v1/tours")
        app.run(host=FLASK_HOST, port=FLASK_PORT, debug=False)
    except Exception as e:
        log_event("ERROR", f"Error iniciando servidor: {e}")
    print("=" * 80)
