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
ORACLE_PORT = int(os.getenv("ORACLE_HOST_PORT", "1521"))
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
            tours.append({
                "fecha": row[0].strftime("%Y-%m-%d") if row[0] else None,
                "cupos_totales": int(row[1]) if row[1] else 0,
                "costo": float(row[2]) if row[2] else 0.0,
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

        plsql = """
        DECLARE
            v_ins_num   NUMBER;
            v_total     NUMBER;
            v_msg       VARCHAR2(4000);
        BEGIN
            sp_crear_inscripcion(
                p_tour_fecha         => TO_DATE(:p_fecha, 'YYYY-MM-DD'),
                p_cliente_responsable => :p_cli,
                p_participantes_json  => :p_part,
                p_numero_inscripcion  => v_ins_num,
                p_costo_total         => v_total,
                p_mensaje             => v_msg
            );
            :o_ins_num := v_ins_num;
            :o_total   := v_total;
            :o_msg     := v_msg;
        END;
        """

        o_ins_num = cur.var(oracledb.NUMBER)
        o_total = cur.var(oracledb.NUMBER)
        o_msg = cur.var(oracledb.STRING)

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

        conn.commit()
        cur.close()
        conn.close()

        return jsonify({
            "ins_num": int(o_ins_num.getvalue()),
            "ins_total": float(o_total.getvalue()),
            "mensaje": o_msg.getvalue(),
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
        
        cur.execute(
            plsql,
            {
                "p_pnombre": data.get("p_pnombre"),
                "p_papellido": data.get("p_papellido"),
                "p_sapellido": data.get("p_sapellido"),
                "p_dni": int(data.get("p_dni")),
                "p_fnacimiento": data.get("p_fnacimiento"),
                "p_nac": int(data.get("p_nac")),
                "p_reside": int(data.get("p_reside")),
                "p_numpas": data.get("p_numpas") if data.get("p_numpas") else None,
                "p_fvenpas": data.get("p_fvenpas") if data.get("p_fvenpas") else None,
                "p_snombre": data.get("p_snombre") if data.get("p_snombre") else None
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
                "fl_pnombre": data.get("fl_pnombre"),
                "fl_papellido": data.get("fl_papellido"),
                "fl_sapellido": data.get("fl_sapellido"),
                "fl_dni": int(data.get("fl_dni")),
                "fl_fnacimiento": data.get("fl_fnacimiento"),
                "fl_nac": int(data.get("fl_nac")),
                "fl_numpas": data.get("fl_numpas") if data.get("fl_numpas") else None,
                "fl_fvenpas": data.get("fl_fvenpas") if data.get("fl_fvenpas") else None,
                "fl_snombre": data.get("fl_snombre") if data.get("fl_snombre") else None,
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
        
        if not inscripcion_num or not monto_pagado:
            return jsonify({"error": "Faltan datos requeridos"}), 400
        
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
        cur.close()
        conn.close()
        
        return jsonify({
            "inscripcion_num": int(inscripcion_num),
            "recibo": o_recibo.getvalue(),
            "entradas_generadas": int(o_entradas.getvalue()),
            "mensaje": o_msg.getvalue(),
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
