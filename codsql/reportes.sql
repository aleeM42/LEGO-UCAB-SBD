--================================================================================
-- 1. PROCEDIMIENTOS DE REPORTE PARA TOURS
--================================================================================

-- Eliminar tipos existentes si tienen dependencias (FORCE elimina dependencias)
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t_ingreso_tour_tab FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t_ingreso_tour_row FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Procedimiento para obtener ingresos por año
CREATE OR REPLACE TYPE t_ingreso_tour_row AS OBJECT (
    fecha_tour      DATE,
    participantes   NUMBER,
    ingresos_eur    NUMBER,
    ingresos_usd    NUMBER
);
/

CREATE OR REPLACE TYPE t_ingreso_tour_tab AS TABLE OF t_ingreso_tour_row;
/

CREATE OR REPLACE FUNCTION fn_reporte_ingresos_tours(
    p_ano IN NUMBER
) RETURN t_ingreso_tour_tab PIPELINED
IS
BEGIN
    FOR r IN (
        -- Consulta para obtener ingresos en USD y EUR
        SELECT 
            t.to_fini AS fecha_tour,
            COUNT(DISTINCT di.det_ins_id) AS participantes,
            SUM(i.ins_total) AS ingresos_usd,
            ROUND(SUM(i.ins_total) * 0.8797, 2) AS ingresos_eur
        FROM tours t
        JOIN inscripciones i ON t.to_fini = i.ins_tour
        LEFT JOIN det_inscrip di ON i.ins_num = di.det_ins_ins
        WHERE i.ins_estado = 'PAGO'
          AND EXTRACT(YEAR FROM t.to_fini) = p_ano
        GROUP BY t.to_fini
        ORDER BY t.to_fini DESC
    ) LOOP
        -- Enviamos la fila a Jasper
        PIPE ROW (t_ingreso_tour_row(
            r.fecha_tour,
            r.participantes,
            r.ingresos_eur,
            r.ingresos_usd
        ));
    END LOOP;
    
    RETURN;
EXCEPTION
    WHEN OTHERS THEN
        -- Opcional: Si falla, podrías lanzar el error o retornar nada
        RAISE_APPLICATION_ERROR(-20951, 'Error en funcion reporte: ' || SQLERRM);
END fn_reporte_ingresos_tours;
/
-- Procedimiento para obtener distribución de nacionalidades
CREATE OR REPLACE PROCEDURE sp_reporte_nacionalidades_tour(
    p_ano IN NUMBER,
    p_cursor_resultado OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_resultado FOR
    SELECT 
        p.p_nac AS nacionalidad,
        COUNT(*) AS cantidad_participantes,
        ROUND((COUNT(*) * 100.0 / 
            (SELECT COUNT(*) FROM det_inscrip di
             JOIN inscripciones i ON di.det_ins_ins = i.ins_num
             JOIN tours t ON i.ins_tour = t.to_fini
             WHERE i.ins_estado = 'PAGO'
             AND EXTRACT(YEAR FROM t.to_fini) = p_ano)), 2) AS porcentaje
    FROM det_inscrip di
    JOIN inscripciones i ON di.det_ins_ins = i.ins_num
    JOIN tours t ON i.ins_tour = t.to_fini
    LEFT JOIN clientes c ON di.det_ins_cli = c.cli_id
    LEFT JOIN f_lego f ON di.det_ins_fan = f.fl_id
    LEFT JOIN paises p ON COALESCE(c.cli_nac, f.fl_nac) = p.p_id
    WHERE i.ins_estado = 'PAGO'
      AND EXTRACT(YEAR FROM t.to_fini) = p_ano
    GROUP BY p.p_nac
    ORDER BY cantidad_participantes DESC;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20952, 
            'Error generando reporte nacionalidades: ' || SQLERRM);
END sp_reporte_nacionalidades_tour;
/
-- Procedimiento para obtener distribución por rango de edad
CREATE OR REPLACE PROCEDURE sp_reporte_rangos_edad_tour(
    p_ano IN NUMBER,
    p_cursor_resultado OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_resultado FOR
    SELECT 
        CASE 
            WHEN TRUNC((SYSDATE - COALESCE(c.cli_fnacimiento, f.fl_fnacimiento)) / 365.25) 
                 BETWEEN 12 AND 17 THEN '12-17 años'
            WHEN TRUNC((SYSDATE - COALESCE(c.cli_fnacimiento, f.fl_fnacimiento)) / 365.25) 
                 BETWEEN 18 AND 30 THEN '18-30 años'
            WHEN TRUNC((SYSDATE - COALESCE(c.cli_fnacimiento, f.fl_fnacimiento)) / 365.25) 
                 BETWEEN 31 AND 60 THEN '31-60 años'
            ELSE 'Mayor de 60 años'
        END AS rango_edad,
        COUNT(*) AS cantidad_participantes,
        ROUND((COUNT(*) * 100.0 / 
            (SELECT COUNT(*) FROM det_inscrip di
             JOIN inscripciones i ON di.det_ins_ins = i.ins_num
             JOIN tours t ON i.ins_tour = t.to_fini
             WHERE i.ins_estado = 'PAGO'
             AND EXTRACT(YEAR FROM t.to_fini) = p_ano)), 2) AS porcentaje
    FROM det_inscrip di
    JOIN inscripciones i ON di.det_ins_ins = i.ins_num
    JOIN tours t ON i.ins_tour = t.to_fini
    LEFT JOIN clientes c ON di.det_ins_cli = c.cli_id
    LEFT JOIN f_lego f ON di.det_ins_fan = f.fl_id
    WHERE i.ins_estado = 'PAGO'
      AND EXTRACT(YEAR FROM t.to_fini) = p_ano
    GROUP BY rango_edad
    ORDER BY cantidad_participantes DESC;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20953, 
            'Error generando reporte edades: ' || SQLERRM);
END sp_reporte_rangos_edad_tour;
/

-- Eliminar tipos existentes si tienen dependencias
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t_recibo_inscripcion_tab FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t_recibo_inscripcion_row FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Procedimiento para obtener recibo de inscripción
CREATE OR REPLACE TYPE t_recibo_inscripcion_row AS OBJECT (
    nombre_completo      VARCHAR2(200),
    edad                 NUMBER,
    nacionalidad         VARCHAR2(30),
    documento_identidad  VARCHAR2(50)
);
/

CREATE OR REPLACE TYPE t_recibo_inscripcion_tab AS TABLE OF t_recibo_inscripcion_row;
/

CREATE OR REPLACE FUNCTION fn_reporte_recibo_inscripcion(
    p_numero_inscripcion IN NUMBER
) RETURN t_recibo_inscripcion_tab PIPELINED
IS
BEGIN
    FOR r IN (
        SELECT 
            CASE 
                WHEN di.det_ins_tipo = 'ADULTO' AND di.det_ins_cli IS NOT NULL THEN
                    c.cli_pnombre || ' ' || NVL(c.cli_snombre || ' ', '') || 
                    c.cli_papellido || ' ' || c.cli_sapellido
                WHEN di.det_ins_tipo = 'MENOR' AND di.det_ins_fan IS NOT NULL THEN
                    f.fl_pnombre || ' ' || NVL(f.fl_snombre || ' ', '') || 
                    f.fl_papellido || ' ' || f.fl_sapellido
                ELSE 'N/A'
            END AS nombre_completo,
            CASE 
                WHEN di.det_ins_tipo = 'ADULTO' AND di.det_ins_cli IS NOT NULL THEN
                    edad(c.cli_fnacimiento)
                WHEN di.det_ins_tipo = 'MENOR' AND di.det_ins_fan IS NOT NULL THEN
                    edad(f.fl_fnacimiento)
                ELSE NULL
            END AS edad_participante,
            CASE 
                WHEN di.det_ins_tipo = 'ADULTO' AND di.det_ins_cli IS NOT NULL THEN
                    p.p_nac
                WHEN di.det_ins_tipo = 'MENOR' AND di.det_ins_fan IS NOT NULL THEN
                    p.p_nac
                ELSE NULL
            END AS nacionalidad,
            CASE 
                WHEN di.det_ins_tipo = 'ADULTO' AND di.det_ins_cli IS NOT NULL THEN
                    CASE 
                        WHEN c.cli_dni IS NOT NULL THEN 'DNI: ' || TO_CHAR(c.cli_dni)
                        WHEN c.cli_numpas IS NOT NULL THEN 'Pasaporte: ' || TO_CHAR(c.cli_numpas)
                        ELSE 'N/A'
                    END
                WHEN di.det_ins_tipo = 'MENOR' AND di.det_ins_fan IS NOT NULL THEN
                    CASE 
                        WHEN f.fl_dni IS NOT NULL THEN 'DNI: ' || TO_CHAR(f.fl_dni)
                        WHEN f.fl_numpas IS NOT NULL THEN 'Pasaporte: ' || TO_CHAR(f.fl_numpas)
                        ELSE 'N/A'
                    END
                ELSE 'N/A'
            END AS documento_identidad
        FROM det_inscrip di
        LEFT JOIN clientes c ON di.det_ins_cli = c.cli_id
        LEFT JOIN f_lego f ON di.det_ins_fan = f.fl_id
        LEFT JOIN paises p ON COALESCE(c.cli_nac, f.fl_nac) = p.p_id
        WHERE di.det_ins_ins = p_numero_inscripcion
        ORDER BY di.det_ins_id
    ) LOOP
        -- Enviamos la fila
        PIPE ROW (t_recibo_inscripcion_row(
            r.nombre_completo,
            r.edad_participante,
            r.nacionalidad,
            r.documento_identidad
        ));
    END LOOP;
    
    RETURN;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20954, 'Error en funcion reporte recibo inscripcion: ' || SQLERRM);
END fn_reporte_recibo_inscripcion;
/


--================================================================================
-- REPORTE: PORCENTAJE DE PARTICIPANTES POR NACIONALIDAD (2024-2025)
--================================================================================

-- Eliminar tipos existentes si tienen dependencias
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t_nacionalidad_tour_anual_tab FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE t_nacionalidad_tour_anual_row FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Reporte: Porcentaje de participantes por nacionalidad durante los años 2024 y 2025
CREATE OR REPLACE TYPE t_nacionalidad_tour_anual_row AS OBJECT (
    nacionalidad          VARCHAR2(30),
    año                   NUMBER,
    cantidad_participantes NUMBER,
    porcentaje            NUMBER
);
/

CREATE OR REPLACE TYPE t_nacionalidad_tour_anual_tab AS TABLE OF t_nacionalidad_tour_anual_row;
/

CREATE OR REPLACE FUNCTION fn_reporte_nacionalidad_tour_anual(
    p_ano_inicio IN NUMBER DEFAULT 2024,
    p_ano_fin IN NUMBER DEFAULT 2025
) RETURN t_nacionalidad_tour_anual_tab PIPELINED
IS
BEGIN
    FOR r IN (
        SELECT 
            NVL(p.p_nac, 'NO ESPECIFICADA') AS nacionalidad,
            EXTRACT(YEAR FROM t.to_fini) AS año,
            COUNT(*) AS cantidad_participantes,
            ROUND((COUNT(*) * 100.0 / 
                (SELECT COUNT(*) 
                 FROM det_inscrip di2
                 JOIN inscripciones i2 ON di2.det_ins_ins = i2.ins_num
                 JOIN tours t2 ON i2.ins_tour = t2.to_fini
                 WHERE i2.ins_estado = 'PAGO'
                   AND EXTRACT(YEAR FROM t2.to_fini) = EXTRACT(YEAR FROM t.to_fini)
                   AND EXTRACT(YEAR FROM t2.to_fini) BETWEEN p_ano_inicio AND p_ano_fin)), 2) AS porcentaje
        FROM det_inscrip di
        JOIN inscripciones i ON di.det_ins_ins = i.ins_num
        JOIN tours t ON i.ins_tour = t.to_fini
        LEFT JOIN clientes c ON di.det_ins_cli = c.cli_id
        LEFT JOIN f_lego f ON di.det_ins_fan = f.fl_id
        LEFT JOIN paises p ON COALESCE(c.cli_nac, f.fl_nac) = p.p_id
        WHERE i.ins_estado = 'PAGO'
          AND EXTRACT(YEAR FROM t.to_fini) BETWEEN p_ano_inicio AND p_ano_fin
        GROUP BY p.p_nac, EXTRACT(YEAR FROM t.to_fini)
        ORDER BY EXTRACT(YEAR FROM t.to_fini) DESC, cantidad_participantes DESC
    ) LOOP
        PIPE ROW (t_nacionalidad_tour_anual_row(
            r.nacionalidad,
            r.año,
            r.cantidad_participantes,
            r.porcentaje
        ));
    END LOOP;
    
    RETURN;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20960, 'Error en funcion reporte nacionalidad tour anual: ' || SQLERRM);
END fn_reporte_nacionalidad_tour_anual;
/