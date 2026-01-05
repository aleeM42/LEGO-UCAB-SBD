-- ═══════════════════════════════════════════════════════════════════════════════
-- SEGURIDAD LÓGICA DEL PROYECTO LEGO – ROLES Y PRIVILEGIOS
-- ═══════════════════════════════════════════════════════════════════════════════
-- Este script define los roles solicitados y asigna privilegios mínimos necesarios
-- por actividad (tour, ventas físicas, ventas online, cliente).
-- Incluye tablas, secuencias, vistas y procedimientos/funciones usados en los flujos
-- automatizados. Ejecutar con un usuario con privilegios de administrador.
-- ═══════════════════════════════════════════════════════════════════════════════

-- Utilidad para eliminar el rol si existe
CREATE OR REPLACE PROCEDURE drop_role_if_exists(p_role VARCHAR2) AS
BEGIN
    EXECUTE IMMEDIATE 'DROP ROLE ' || p_role;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROLES DEL TOUR
-- ═══════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────
-- ROL: Agente de Atención al Cliente (ventas de inscripciones)
-- ───────────────────────────────────────────────────────────────────────────────
BEGIN drop_role_if_exists('RL_TOUR_AGENTE'); END;
/
CREATE ROLE rl_tour_agente;

-- Tablas necesarias para registrar clientes/fans y crear inscripciones
GRANT SELECT, INSERT ON clientes TO rl_tour_agente;
GRANT SELECT, INSERT ON f_lego TO rl_tour_agente;
GRANT SELECT ON paises TO rl_tour_agente;
GRANT SELECT ON tours TO rl_tour_agente;
GRANT SELECT, INSERT ON inscripciones TO rl_tour_agente;
GRANT SELECT, INSERT ON det_inscrip TO rl_tour_agente;
GRANT SELECT, INSERT ON entradas_tour TO rl_tour_agente;
GRANT SELECT, INSERT ON auditoria_tours TO rl_tour_agente;
GRANT SELECT ON hist_precios TO rl_tour_agente;

-- Secuencias necesarias para el flujo de inscripción
GRANT SELECT ON clientes_seq TO rl_tour_agente;
GRANT SELECT ON f_lego_seq TO rl_tour_agente;
GRANT SELECT ON inscripciones_seq TO rl_tour_agente;
GRANT SELECT ON det_inscrip_seq TO rl_tour_agente;
GRANT SELECT ON entradas_seq TO rl_tour_agente;
GRANT SELECT ON auditoria_tours_seq TO rl_tour_agente;

-- Procedimientos/funciones específicos del agente (ventas de inscripciones)
GRANT EXECUTE ON sp_automatizar_inscripcion_tour TO rl_tour_agente;
GRANT EXECUTE ON sp_consultar_cliente_inscripcion TO rl_tour_agente;
GRANT EXECUTE ON sp_consultar_fan_lego_inscripcion TO rl_tour_agente;
GRANT EXECUTE ON sp_consultar_cupos_tour TO rl_tour_agente;
GRANT EXECUTE ON sp_listar_tours_disponibles TO rl_tour_agente;
GRANT EXECUTE ON fn_tour_disponible TO rl_tour_agente;
GRANT EXECUTE ON fn_inscripcion_abierta TO rl_tour_agente;
GRANT EXECUTE ON fn_validar_cupos_tour TO rl_tour_agente;
GRANT EXECUTE ON sp_confirmar_pago_inscripcion TO rl_tour_agente;

-- ───────────────────────────────────────────────────────────────────────────────
-- ROL: Coordinador del Tour (fechas, cupos y reportes)
-- ───────────────────────────────────────────────────────────────────────────────
BEGIN drop_role_if_exists('RL_TOUR_COORD'); END;
/
CREATE ROLE rl_tour_coord;

-- Coordinador gestiona fechas, cupos y reportes del tour
GRANT SELECT, INSERT, UPDATE ON tours TO rl_tour_coord;
GRANT SELECT ON inscripciones TO rl_tour_coord;
GRANT SELECT ON det_inscrip TO rl_tour_coord;
GRANT SELECT ON entradas_tour TO rl_tour_coord;
GRANT SELECT ON auditoria_tours TO rl_tour_coord;
GRANT SELECT ON clientes TO rl_tour_coord;
GRANT SELECT ON f_lego TO rl_tour_coord;
GRANT SELECT ON paises TO rl_tour_coord;

-- Secuencias para reportes y consultas
GRANT SELECT ON inscripciones_seq TO rl_tour_coord;
GRANT SELECT ON det_inscrip_seq TO rl_tour_coord;
GRANT SELECT ON entradas_seq TO rl_tour_coord;
GRANT SELECT ON auditoria_tours_seq TO rl_tour_coord;

-- Procedimientos/funciones específicos del coordinador (gestión de tours y reportes)
GRANT EXECUTE ON sp_consultar_cupos_tour TO rl_tour_coord;
GRANT EXECUTE ON sp_listar_tours_disponibles TO rl_tour_coord;
GRANT EXECUTE ON fn_tour_disponible TO rl_tour_coord;
GRANT EXECUTE ON fn_inscripcion_abierta TO rl_tour_coord;
GRANT EXECUTE ON fn_validar_cupos_tour TO rl_tour_coord;
GRANT EXECUTE ON fn_calcular_costo_inscripcion TO rl_tour_coord;
GRANT EXECUTE ON fn_obtener_moneda_tour TO rl_tour_coord;
GRANT EXECUTE ON sp_reporte_ingresos_tours_anual TO rl_tour_coord;
GRANT EXECUTE ON sp_reporte_nacionalidades_tour TO rl_tour_coord;
GRANT EXECUTE ON sp_reporte_rangos_edad_tour TO rl_tour_coord;

-- ───────────────────────────────────────────────────────────────────────────────
-- ROL: Cliente Tour (auto-servicio para inscripciones)
-- ───────────────────────────────────────────────────────────────────────────────
BEGIN drop_role_if_exists('RL_TOUR_CLIENTE'); END;
/
CREATE ROLE rl_tour_cliente;

-- Cliente puede consultar tours e inscribirse
GRANT SELECT ON tours TO rl_tour_cliente;
GRANT SELECT, INSERT ON inscripciones TO rl_tour_cliente;
GRANT SELECT, INSERT ON det_inscrip TO rl_tour_cliente;
GRANT SELECT, INSERT ON entradas_tour TO rl_tour_cliente;

-- Secuencias para inscripción
GRANT SELECT ON inscripciones_seq TO rl_tour_cliente;
GRANT SELECT ON det_inscrip_seq TO rl_tour_cliente;
GRANT SELECT ON entradas_seq TO rl_tour_cliente;

-- Procedimientos/funciones específicos del cliente (consulta y auto-inscripción)
GRANT EXECUTE ON sp_listar_tours_disponibles TO rl_tour_cliente;
GRANT EXECUTE ON sp_consultar_cupos_tour TO rl_tour_cliente;
GRANT EXECUTE ON sp_automatizar_inscripcion_tour TO rl_tour_cliente;

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROLES VENTAS TIENDA FÍSICA
-- ═══════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────
-- ROL: Cajero Tienda (ventas)
-- ───────────────────────────────────────────────────────────────────────────────
BEGIN drop_role_if_exists('RL_TIENDA_CAJERO'); END;
/
CREATE ROLE rl_tienda_cajero;

-- Cajero puede vender y consultar catálogo
GRANT SELECT ON productos TO rl_tienda_cajero;
GRANT SELECT ON hist_precios TO rl_tienda_cajero;
GRANT SELECT ON lotes TO rl_tienda_cajero;
GRANT SELECT ON descuentos TO rl_tienda_cajero;
GRANT SELECT ON tiendas TO rl_tienda_cajero;
GRANT SELECT ON horarios TO rl_tienda_cajero;
GRANT SELECT ON clientes TO rl_tienda_cajero;
GRANT SELECT ON paises TO rl_tienda_cajero;
GRANT SELECT, INSERT, UPDATE ON factura_tf TO rl_tienda_cajero;
GRANT SELECT, INSERT ON det_fact_t TO rl_tienda_cajero;
GRANT SELECT, INSERT ON descuentos TO rl_tienda_cajero;

-- Secuencias para facturación
GRANT SELECT ON factura_tf_seq TO rl_tienda_cajero;
GRANT SELECT ON det_fact_tf_seq TO rl_tienda_cajero;
GRANT SELECT ON descuentos_seq TO rl_tienda_cajero;

-- Procedimientos/funciones específicos del cajero (ventas)
GRANT EXECUTE ON sp_validar_horario_tienda TO rl_tienda_cajero;
GRANT EXECUTE ON sp_consultar_catalogo_tienda TO rl_tienda_cajero;
GRANT EXECUTE ON sp_consultar_cliente_venta TO rl_tienda_cajero;
GRANT EXECUTE ON sp_automatizar_venta_fisica TO rl_tienda_cajero;
GRANT EXECUTE ON INICIAR_FACTURA_FISICA TO rl_tienda_cajero;
GRANT EXECUTE ON INSERTAR_DETALLE_FISICA TO rl_tienda_cajero;
GRANT EXECUTE ON FINALIZAR_FACTURA_FISICA TO rl_tienda_cajero;

-- ───────────────────────────────────────────────────────────────────────────────
-- ROL: Encargado de Tienda (reportes de ventas)
-- ───────────────────────────────────────────────────────────────────────────────
BEGIN drop_role_if_exists('RL_TIENDA_ENCARGADO'); END;
/
CREATE ROLE rl_tienda_encargado;

-- Encargado consulta reportes de ventas
GRANT SELECT ON productos TO rl_tienda_encargado;
GRANT SELECT ON hist_precios TO rl_tienda_encargado;
GRANT SELECT ON tiendas TO rl_tienda_encargado;
GRANT SELECT ON horarios TO rl_tienda_encargado;
GRANT SELECT ON factura_tf TO rl_tienda_encargado;
GRANT SELECT ON det_fact_t TO rl_tienda_encargado;
GRANT SELECT ON clientes TO rl_tienda_encargado;
GRANT SELECT ON paises TO rl_tienda_encargado;
GRANT SELECT ON lotes TO rl_tienda_encargado;
GRANT SELECT ON descuentos TO rl_tienda_encargado;

-- Secuencias para consultas
GRANT SELECT ON factura_tf_seq TO rl_tienda_encargado;
GRANT SELECT ON det_fact_tf_seq TO rl_tienda_encargado;

-- Procedimientos/funciones específicos del encargado (reportes de ventas)
GRANT EXECUTE ON sp_consultar_catalogo_tienda TO rl_tienda_encargado;
GRANT EXECUTE ON sp_automatizar_venta_fisica TO rl_tienda_encargado;
GRANT EXECUTE ON CONVERTIR_PRECIOS_TIENDA TO rl_tienda_encargado;

-- ───────────────────────────────────────────────────────────────────────────────
-- ROL: Supervisor de Inventario (inventario)
-- ───────────────────────────────────────────────────────────────────────────────
BEGIN drop_role_if_exists('RL_TIENDA_SUPERVISOR_INVENTARIO'); END;
/
CREATE ROLE rl_tienda_supervisor_inventario;

-- Supervisor maneja inventario (lotes y descuentos)
GRANT SELECT, INSERT, UPDATE ON lotes TO rl_tienda_supervisor_inventario;
GRANT SELECT, INSERT, UPDATE ON descuentos TO rl_tienda_supervisor_inventario;
GRANT SELECT ON productos TO rl_tienda_supervisor_inventario;
GRANT SELECT ON tiendas TO rl_tienda_supervisor_inventario;
GRANT SELECT ON factura_tf TO rl_tienda_supervisor_inventario;
GRANT SELECT ON det_fact_t TO rl_tienda_supervisor_inventario;

-- Secuencias para inventario
GRANT SELECT ON lotes_seq TO rl_tienda_supervisor_inventario;
GRANT SELECT ON descuentos_seq TO rl_tienda_supervisor_inventario;

-- Procedimientos/funciones específicos del supervisor (inventario)
GRANT EXECUTE ON INSERTAR_LOTE_PRODUCTO TO rl_tienda_supervisor_inventario;
GRANT EXECUTE ON sp_descontar_inventario_lotes TO rl_tienda_supervisor_inventario;

-- ───────────────────────────────────────────────────────────────────────────────
-- ROL: Cliente Tienda Física (consulta catálogo)
-- ───────────────────────────────────────────────────────────────────────────────
BEGIN drop_role_if_exists('RL_TIENDA_CLIENTE'); END;
/
CREATE ROLE rl_tienda_cliente;

-- Cliente puede consultar catálogo de tienda
GRANT SELECT ON productos TO rl_tienda_cliente;
GRANT SELECT ON hist_precios TO rl_tienda_cliente;
GRANT SELECT ON lotes TO rl_tienda_cliente;
GRANT SELECT ON tiendas TO rl_tienda_cliente;
GRANT SELECT ON horarios TO rl_tienda_cliente;
GRANT SELECT ON paises TO rl_tienda_cliente;

-- Procedimientos/funciones específicos del cliente (consulta catálogo)
GRANT EXECUTE ON sp_consultar_catalogo_tienda TO rl_tienda_cliente;
GRANT EXECUTE ON sp_validar_horario_tienda TO rl_tienda_cliente;

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROLES VENTAS ONLINE
-- ═══════════════════════════════════════════════════════════════════════════════

-- ───────────────────────────────────────────────────────────────────────────────
-- ROL: Empleado Online (reportes y consultas)
-- ───────────────────────────────────────────────────────────────────────────────
BEGIN drop_role_if_exists('RL_ONLINE_EMPLEADO'); END;
/
CREATE ROLE rl_online_empleado;

-- Empleado gestiona ventas online y reportes
GRANT SELECT ON catalogos TO rl_online_empleado;
GRANT SELECT ON productos TO rl_online_empleado;
GRANT SELECT ON hist_precios TO rl_online_empleado;
GRANT SELECT, INSERT, UPDATE ON factura_o TO rl_online_empleado;
GRANT SELECT, INSERT ON det_fact_o TO rl_online_empleado;
GRANT SELECT ON paises TO rl_online_empleado;
GRANT SELECT ON clientes TO rl_online_empleado;

-- Secuencias para facturación online
GRANT SELECT ON factura_o_seq TO rl_online_empleado;
GRANT SELECT ON det_fact_o_seq TO rl_online_empleado;

-- Procedimientos/funciones específicos del empleado (ventas online y reportes)
GRANT EXECUTE ON sp_consultar_catalogo_online TO rl_online_empleado;
GRANT EXECUTE ON sp_automatizar_venta_online TO rl_online_empleado;
GRANT EXECUTE ON INICIAR_FACTURA_ONLINE TO rl_online_empleado;
GRANT EXECUTE ON INSERTAR_DETALLE_ONLINE TO rl_online_empleado;
GRANT EXECUTE ON FINALIZAR_FACTURA_ONLINE TO rl_online_empleado;

-- ───────────────────────────────────────────────────────────────────────────────
-- ROL: Cliente Online (registro y select catálogos)
-- ───────────────────────────────────────────────────────────────────────────────
BEGIN drop_role_if_exists('RL_ONLINE_CLIENTE'); END;
/
CREATE ROLE rl_online_cliente;

-- Cliente puede consultar catálogos y realizar compras online
GRANT SELECT ON catalogos TO rl_online_cliente;
GRANT SELECT ON productos TO rl_online_cliente;
GRANT SELECT ON hist_precios TO rl_online_cliente;
GRANT SELECT ON paises TO rl_online_cliente;
GRANT SELECT ON clientes TO rl_online_cliente;
GRANT SELECT, INSERT, UPDATE ON factura_o TO rl_online_cliente;
GRANT SELECT, INSERT ON det_fact_o TO rl_online_cliente;

-- Secuencias para compras online
GRANT SELECT ON factura_o_seq TO rl_online_cliente;
GRANT SELECT ON det_fact_o_seq TO rl_online_cliente;

-- Procedimientos/funciones específicos del cliente (consulta catálogo y auto-compra)
GRANT EXECUTE ON sp_consultar_catalogo_online TO rl_online_cliente;
GRANT EXECUTE ON sp_automatizar_venta_online TO rl_online_cliente;

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIN DEL SCRIPT
-- ═══════════════════════════════════════════════════════════════════════════════
