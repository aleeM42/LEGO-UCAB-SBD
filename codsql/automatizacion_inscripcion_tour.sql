-- ═══════════════════════════════════════════════════════════════════════════════
-- AUTOMATIZACIÓN COMPLETA DEL FLUJO DE INSCRIPCIÓN AL TOUR
-- ═══════════════════════════════════════════════════════════════════════════════
-- Este procedimiento almacenado automatiza todo el flujo de inscripción al tour
-- dentro del manejador de base de datos, incluyendo:
-- 1. Verificación de cupos disponibles
-- 2. Validación de fecha y período de inscripción
-- 3. Validación de cliente responsable
-- 4. Validación de participantes
-- 5. Cálculo de costos con conversión de moneda
-- 6. Creación de inscripción
-- 7. Generación de entradas
-- 8. Retorno de información completa
-- ═══════════════════════════════════════════════════════════════════════════════

-- Procedimiento principal para automatizar todo el flujo de inscripción
CREATE OR REPLACE PROCEDURE sp_automatizar_inscripcion_tour(
    p_tour_fecha IN DATE,
    p_cliente_responsable IN NUMBER,
    p_participantes_ids IN VARCHAR2,  -- Formato: "123,5,7" (IDs separados por comas)
    p_participantes_tipos IN VARCHAR2,  -- Formato: "1,2,2" (1=ADULTO, 2=MENOR, separados por comas)
    p_numero_inscripcion OUT NUMBER,
    p_costo_total_usd OUT NUMBER,
    p_costo_total_eur OUT NUMBER,
    p_costo_total_dkk OUT NUMBER,
    p_moneda_cliente OUT VARCHAR2,  -- 'EUR' o 'USD'
    p_pais_cliente OUT VARCHAR2,
    p_pertenece_ue OUT VARCHAR2,  -- 'SI' o 'NO'
    p_entradas_generadas OUT NUMBER,
    p_cantidad_participantes OUT NUMBER,
    p_mensaje OUT VARCHAR2,
    p_detalle_participantes OUT SYS_REFCURSOR,  -- Cursor con información de participantes
    p_detalle_representantes OUT SYS_REFCURSOR  -- Cursor con información de representantes (si hay menores)
)
IS
    v_cantidad_participantes NUMBER := 0;
    v_costo_unitario_usd NUMBER;
    v_cliente_edad NUMBER;
    v_cliente_nac_id NUMBER;
    v_cliente_reside_id NUMBER;
    v_pais_ue VARCHAR2(2);
    v_pais_nombre VARCHAR2(50);
    v_inscripcion_creada BOOLEAN := FALSE;
    v_contador_loop NUMBER := 1;  -- Contador para el loop de participantes
    v_count_check NUMBER;  -- Variable para COUNT
    v_tipo_asistente VARCHAR2(10);
    v_cliente_id NUMBER;
    v_fan_id NUMBER;
    v_participante_id NUMBER;
    v_tipo_numero NUMBER;
    v_ids_normalizado VARCHAR2(4000);
    v_tipos_normalizado VARCHAR2(4000);
    v_pos_comma NUMBER;
    v_id_str VARCHAR2(50);
    v_tipo_str VARCHAR2(10);
    v_string_restante_ids VARCHAR2(4000);
    v_string_restante_tipos VARCHAR2(4000);
BEGIN
    SAVEPOINT sp_automatizacion_inicio;
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PASO 1: VALIDAR TOUR
    -- ═══════════════════════════════════════════════════════════════════════════
    IF NOT fn_tour_disponible(p_tour_fecha) THEN
        RAISE_APPLICATION_ERROR(-20911, 'Tour no disponible en esa fecha');
    END IF;
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PASO 2: VALIDAR PERÍODO DE INSCRIPCIÓN
    -- ═══════════════════════════════════════════════════════════════════════════
    IF NOT fn_inscripcion_abierta(p_tour_fecha) THEN
        RAISE_APPLICATION_ERROR(-20912, 'Período de inscripción cerrado para este tour');
    END IF;
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PASO 3: VALIDAR Y OBTENER DATOS DEL CLIENTE RESPONSABLE
    -- ═══════════════════════════════════════════════════════════════════════════
    BEGIN
        SELECT 
            TRUNC((SYSDATE - cli_fnacimiento) / 365.25),
            cli_nac,
            cli_reside
        INTO 
            v_cliente_edad,
            v_cliente_nac_id,
            v_cliente_reside_id
        FROM clientes 
        WHERE cli_id = p_cliente_responsable;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20913, 'Cliente responsable no existe');
    END;
    
    -- Validar edad del cliente responsable (>= 21 años)
    IF v_cliente_edad < 21 THEN
        RAISE_APPLICATION_ERROR(-20914, 'Responsable debe ser mayor de 21 años');
    END IF;
    
    -- Obtener información del país de nacionalidad del cliente
    BEGIN
        SELECT p.p_ue, p.p_nom
        INTO v_pais_ue, v_pais_nombre
        FROM paises p
        WHERE p.p_id = v_cliente_nac_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_pais_ue := 'NO';
            v_pais_nombre := 'N/A';
    END;
    
    -- Normalizar valor de UE
    v_pais_ue := UPPER(TRIM(v_pais_ue));
    IF v_pais_ue IS NULL THEN
        v_pais_ue := 'NO';
    END IF;
    
    -- Determinar moneda según pertenencia a UE
    IF v_pais_ue = 'SI' THEN
        p_moneda_cliente := 'EUR';
    ELSE
        p_moneda_cliente := 'USD';
    END IF;
    
    p_pais_cliente := v_pais_nombre;
    p_pertenece_ue := v_pais_ue;
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PASO 4: PROCESAR Y VALIDAR PARTICIPANTES
    -- ═══════════════════════════════════════════════════════════════════════════
    -- Normalizar los strings: eliminar espacios y comas finales si existen
    v_ids_normalizado := TRIM(p_participantes_ids);
    v_tipos_normalizado := TRIM(p_participantes_tipos);
    
    -- Validar que ambos strings tengan la misma cantidad de elementos
    DECLARE
        v_count_ids NUMBER;
        v_count_tipos NUMBER;
    BEGIN
        -- Contar IDs (separados por comas)
        IF v_ids_normalizado IS NULL OR LENGTH(v_ids_normalizado) = 0 THEN
            v_count_ids := 0;
        ELSE
            v_count_ids := REGEXP_COUNT(v_ids_normalizado, '[^,]+');
        END IF;
        
        -- Contar tipos (separados por comas)
        IF v_tipos_normalizado IS NULL OR LENGTH(v_tipos_normalizado) = 0 THEN
            v_count_tipos := 0;
        ELSE
            v_count_tipos := REGEXP_COUNT(v_tipos_normalizado, '[^,]+');
        END IF;
        
        IF v_count_ids = 0 OR v_count_tipos = 0 THEN
            RAISE_APPLICATION_ERROR(-20915, 'Debe proporcionar al menos un participante. IDs recibidos: [' || v_ids_normalizado || '], Tipos recibidos: [' || v_tipos_normalizado || ']');
        END IF;
        
        IF v_count_ids != v_count_tipos THEN
            RAISE_APPLICATION_ERROR(-20920, 'Error: La cantidad de IDs (' || v_count_ids || ') no coincide con la cantidad de tipos (' || v_count_tipos || '). ' ||
                                            'Debe haber el mismo número de IDs y tipos separados por comas.');
        END IF;
    END;
    
    -- Procesar y validar participantes
    DECLARE
        v_string_restante_ids VARCHAR2(4000);
        v_string_restante_tipos VARCHAR2(4000);
        v_pos_comma NUMBER;
        v_id_str VARCHAR2(50);
        v_tipo_str VARCHAR2(10);
    BEGIN
        v_string_restante_ids := v_ids_normalizado;
        v_string_restante_tipos := v_tipos_normalizado;
        
        WHILE v_string_restante_ids IS NOT NULL AND LENGTH(v_string_restante_ids) > 0 LOOP
            -- Extraer ID
            v_pos_comma := INSTR(v_string_restante_ids, ',');
            IF v_pos_comma > 0 THEN
                v_id_str := TRIM(SUBSTR(v_string_restante_ids, 1, v_pos_comma - 1));
                v_string_restante_ids := SUBSTR(v_string_restante_ids, v_pos_comma + 1);
            ELSE
                v_id_str := TRIM(v_string_restante_ids);
                v_string_restante_ids := NULL;
            END IF;
            
            -- Extraer tipo
            v_pos_comma := INSTR(v_string_restante_tipos, ',');
            IF v_pos_comma > 0 THEN
                v_tipo_str := TRIM(SUBSTR(v_string_restante_tipos, 1, v_pos_comma - 1));
                v_string_restante_tipos := SUBSTR(v_string_restante_tipos, v_pos_comma + 1);
            ELSE
                v_tipo_str := TRIM(v_string_restante_tipos);
                v_string_restante_tipos := NULL;
            END IF;
            
            -- Validar que ambos valores no estén vacíos
            IF v_id_str IS NULL OR v_id_str = '' OR v_tipo_str IS NULL OR v_tipo_str = '' THEN
                CONTINUE;
            END IF;
            
            -- Convertir tipo a número y validar
            BEGIN
                v_tipo_numero := TO_NUMBER(v_tipo_str);
                
                IF v_tipo_numero = 1 THEN
                    v_tipo_asistente := 'ADULTO';
                ELSIF v_tipo_numero = 2 THEN
                    v_tipo_asistente := 'MENOR';
                ELSE
                    RAISE_APPLICATION_ERROR(-20919, 'Tipo de participante inválido: ' || v_tipo_numero || '. Debe ser 1 (ADULTO) o 2 (MENOR).');
                END IF;
            EXCEPTION
                WHEN VALUE_ERROR THEN
                    RAISE_APPLICATION_ERROR(-20919, 'Error: Tipo de participante inválido: [' || v_tipo_str || ']. Debe ser un número (1=ADULTO, 2=MENOR).');
            END;
            
            -- Convertir ID a número y validar
            BEGIN
                v_participante_id := TO_NUMBER(v_id_str);
            EXCEPTION
                WHEN VALUE_ERROR THEN
                    RAISE_APPLICATION_ERROR(-20917, 'Error: ID de participante inválido: [' || v_id_str || ']. Debe ser un número.');
            END;
            
            -- Validar que el participante existe según su tipo
            IF v_tipo_asistente = 'ADULTO' THEN
                SELECT COUNT(*) INTO v_count_check
                FROM clientes WHERE cli_id = v_participante_id;
                IF v_count_check = 0 THEN
                    RAISE_APPLICATION_ERROR(-20917, 'Cliente participante no existe: ' || v_participante_id);
                END IF;
            ELSIF v_tipo_asistente = 'MENOR' THEN
                SELECT COUNT(*) INTO v_count_check
                FROM f_lego WHERE fl_id = v_participante_id;
                IF v_count_check = 0 THEN
                    RAISE_APPLICATION_ERROR(-20918, 'Fan LEGO participante no existe: ' || v_participante_id);
                END IF;
            END IF;
            
            v_cantidad_participantes := v_cantidad_participantes + 1;
        END LOOP;
    END;
    
    IF v_cantidad_participantes = 0 THEN
        RAISE_APPLICATION_ERROR(-20915, 'Inscripción debe tener al menos un participante. IDs recibidos: [' || p_participantes_ids || '], Tipos recibidos: [' || p_participantes_tipos || ']');
    END IF;
    
    p_cantidad_participantes := v_cantidad_participantes;
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PASO 5: VALIDAR CUPOS DISPONIBLES
    -- ═══════════════════════════════════════════════════════════════════════════
    IF NOT fn_validar_cupos_tour(p_tour_fecha, v_cantidad_participantes) THEN
        RAISE_APPLICATION_ERROR(-20916, 'No hay cupos disponibles para la cantidad solicitada');
    END IF;
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PASO 6: CALCULAR COSTOS (en todas las monedas)
    -- ═══════════════════════════════════════════════════════════════════════════
    SELECT to_costo INTO v_costo_unitario_usd
    FROM tours WHERE to_fini = p_tour_fecha;
    
    -- Costo total en USD (precio base en BD)
    p_costo_total_usd := v_costo_unitario_usd * v_cantidad_participantes;
    
    -- Costo total en EUR (si es UE)
    p_costo_total_eur := p_costo_total_usd * 0.8797;  -- 1 USD = 0.8797 EUR
    
    -- Costo total en DKK (para mostrar)
    p_costo_total_dkk := ROUND(p_costo_total_usd * (23000 / 3500), 2);  -- 1 USD = 6.5714 DKK
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PASO 7: CREAR INSCRIPCIÓN (ESTADO: PENDIENTE PAGO)
    -- ═══════════════════════════════════════════════════════════════════════════
    SELECT inscripciones_seq.NEXTVAL INTO p_numero_inscripcion FROM dual;
    
    INSERT INTO inscripciones (
        ins_num, ins_femision, ins_total, ins_estado, ins_tour
    ) VALUES (
        p_numero_inscripcion, SYSDATE, p_costo_total_usd, 'PENDIENTE', p_tour_fecha
    );
    
    v_inscripcion_creada := TRUE;
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PASO 8: REGISTRAR PARTICIPANTES Y GENERAR ENTRADAS
    -- ═══════════════════════════════════════════════════════════════════════════
    p_entradas_generadas := 0;
    
    -- Procesar participantes nuevamente para insertar en det_inscrip y generar entradas
    -- Usar el mismo método para dividir los strings de IDs y tipos
    DECLARE
        v_string_restante_ids VARCHAR2(4000);
        v_string_restante_tipos VARCHAR2(4000);
        v_pos_comma NUMBER;
        v_id_str VARCHAR2(50);
        v_tipo_str VARCHAR2(10);
        v_participante_id NUMBER;
        v_tipo_numero NUMBER;
    BEGIN
        v_string_restante_ids := v_ids_normalizado;
        v_string_restante_tipos := v_tipos_normalizado;
        
        WHILE v_string_restante_ids IS NOT NULL AND LENGTH(v_string_restante_ids) > 0 LOOP
            -- Extraer ID
            v_pos_comma := INSTR(v_string_restante_ids, ',');
            IF v_pos_comma > 0 THEN
                v_id_str := TRIM(SUBSTR(v_string_restante_ids, 1, v_pos_comma - 1));
                v_string_restante_ids := SUBSTR(v_string_restante_ids, v_pos_comma + 1);
            ELSE
                v_id_str := TRIM(v_string_restante_ids);
                v_string_restante_ids := NULL;
            END IF;
            
            -- Extraer tipo
            v_pos_comma := INSTR(v_string_restante_tipos, ',');
            IF v_pos_comma > 0 THEN
                v_tipo_str := TRIM(SUBSTR(v_string_restante_tipos, 1, v_pos_comma - 1));
                v_string_restante_tipos := SUBSTR(v_string_restante_tipos, v_pos_comma + 1);
            ELSE
                v_tipo_str := TRIM(v_string_restante_tipos);
                v_string_restante_tipos := NULL;
            END IF;
            
            -- Validar que ambos valores no estén vacíos
            IF v_id_str IS NULL OR v_id_str = '' OR v_tipo_str IS NULL OR v_tipo_str = '' THEN
                CONTINUE;
            END IF;
            
            -- Convertir tipo a número y determinar tipo_asistente
            BEGIN
                v_tipo_numero := TO_NUMBER(v_tipo_str);
                
                IF v_tipo_numero = 1 THEN
                    v_tipo_asistente := 'ADULTO';
                ELSIF v_tipo_numero = 2 THEN
                    v_tipo_asistente := 'MENOR';
                ELSE
                    CONTINUE; -- Saltar si el tipo no es válido
                END IF;
            EXCEPTION
                WHEN VALUE_ERROR THEN
                    CONTINUE; -- Saltar si no se puede convertir
            END;
            
            -- Convertir ID a número
            BEGIN
                v_participante_id := TO_NUMBER(v_id_str);
            EXCEPTION
                WHEN VALUE_ERROR THEN
                    CONTINUE; -- Saltar si no se puede convertir
            END;
            
            -- Insertar en det_inscrip
            INSERT INTO det_inscrip (
                det_ins_id, det_ins_ins, det_ins_tipo,
                det_ins_fan, det_ins_cli
            ) VALUES (
                det_inscrip_seq.NEXTVAL, 
                p_numero_inscripcion, 
                v_tipo_asistente,
                CASE WHEN v_tipo_asistente = 'MENOR' THEN v_participante_id ELSE NULL END,
                CASE WHEN v_tipo_asistente = 'ADULTO' THEN v_participante_id ELSE NULL END
            );
            
            -- Generar entrada usando la secuencia entradas_seq
            INSERT INTO entradas_tour (
                ent_insc, ent_id, ent_tipo_asistente
            ) VALUES (
                p_numero_inscripcion, 
                entradas_seq.NEXTVAL, 
                v_tipo_asistente
            );
            
            p_entradas_generadas := p_entradas_generadas + 1;
        END LOOP;
    END;
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PASO 9: PREPARAR CURSORES CON INFORMACIÓN DE PARTICIPANTES
    -- ═══════════════════════════════════════════════════════════════════════════
    -- Cursor con información de participantes (adultos y menores)
    OPEN p_detalle_participantes FOR
        SELECT 
            di.det_ins_tipo AS tipo_participante,
            di.det_ins_cli AS cliente_id,
            di.det_ins_fan AS fan_id,
            CASE 
                WHEN di.det_ins_tipo = 'ADULTO' THEN
                    c.cli_pnombre || ' ' || c.cli_papellido || ' ' || c.cli_sapellido
                WHEN di.det_ins_tipo = 'MENOR' THEN
                    f.fl_pnombre || ' ' || f.fl_papellido || ' ' || f.fl_sapellido
                ELSE 'N/A'
            END AS nombre_completo,
            CASE 
                WHEN di.det_ins_tipo = 'ADULTO' THEN c.cli_dni
                WHEN di.det_ins_tipo = 'MENOR' THEN f.fl_dni
                ELSE NULL
            END AS dni,
            CASE 
                WHEN di.det_ins_tipo = 'ADULTO' THEN 
                    TRUNC((SYSDATE - c.cli_fnacimiento) / 365.25)
                WHEN di.det_ins_tipo = 'MENOR' THEN 
                    TRUNC((SYSDATE - f.fl_fnacimiento) / 365.25)
                ELSE NULL
            END AS edad
        FROM det_inscrip di
        LEFT JOIN clientes c ON di.det_ins_cli = c.cli_id
        LEFT JOIN f_lego f ON di.det_ins_fan = f.fl_id
        WHERE di.det_ins_ins = p_numero_inscripcion
        ORDER BY di.det_ins_id;
    
    -- Cursor con información de representantes (solo para menores)
    OPEN p_detalle_representantes FOR
        SELECT DISTINCT
            f.fl_id AS fan_id,
            f.fl_pnombre || ' ' || f.fl_papellido || ' ' || f.fl_sapellido AS nombre_fan,
            f.fl_dni AS dni_fan,
            c.cli_id AS representante_id,
            c.cli_pnombre || ' ' || c.cli_papellido || ' ' || c.cli_sapellido AS nombre_representante,
            c.cli_dni AS dni_representante,
            TRUNC((SYSDATE - c.cli_fnacimiento) / 365.25) AS edad_representante
        FROM det_inscrip di
        JOIN f_lego f ON di.det_ins_fan = f.fl_id
        JOIN clientes c ON f.fl_repre = c.cli_id
        WHERE di.det_ins_ins = p_numero_inscripcion
          AND di.det_ins_tipo = 'MENOR'
        ORDER BY f.fl_id;
    
    -- ═══════════════════════════════════════════════════════════════════════════
    -- PASO 10: PREPARAR MENSAJE DE ÉXITO
    -- ═══════════════════════════════════════════════════════════════════════════
    p_mensaje := 'Inscripción creada exitosamente. ' ||
                 'Número: ' || p_numero_inscripcion || ' | ' ||
                 'Total USD: ' || ROUND(p_costo_total_usd, 2) || ' | ' ||
                 'Total ' || p_moneda_cliente || ': ' || 
                 CASE 
                     WHEN p_moneda_cliente = 'EUR' THEN ROUND(p_costo_total_eur, 2)
                     ELSE ROUND(p_costo_total_usd, 2)
                 END || ' | ' ||
                 'Participantes: ' || p_cantidad_participantes || ' | ' ||
                 'Entradas generadas: ' || p_entradas_generadas || ' | ' ||
                 'Estado: PENDIENTE PAGO';
    
    -- Registrar en auditoría
    INSERT INTO auditoria_tours (
        aud_fecha, aud_inscripcion_num, aud_tipo_evento, aud_descripcion
    ) VALUES (
        SYSDATE, p_numero_inscripcion, 'INSCRIPCION_CREADA',
        'Inscripción creada automáticamente. Tour: ' || TO_CHAR(p_tour_fecha, 'DD/MM/YYYY') ||
        ' | Cliente responsable: ' || p_cliente_responsable ||
        ' | Participantes: ' || p_cantidad_participantes
    );
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_automatizacion_inicio;
        p_numero_inscripcion := -1;
        p_costo_total_usd := 0;
        p_costo_total_eur := 0;
        p_costo_total_dkk := 0;
        p_moneda_cliente := 'USD';
        p_pais_cliente := 'N/A';
        p_pertenece_ue := 'NO';
        p_entradas_generadas := 0;
        p_cantidad_participantes := 0;
        p_mensaje := 'Error: ' || SQLERRM || ' | IDs: [' || p_participantes_ids || '] | Tipos: [' || p_participantes_tipos || ']';
        -- Cerrar cursores si están abiertos
        BEGIN
            IF p_detalle_participantes%ISOPEN THEN
                CLOSE p_detalle_participantes;
            END IF;
            IF p_detalle_representantes%ISOPEN THEN
                CLOSE p_detalle_representantes;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;
        RAISE;
END sp_automatizar_inscripcion_tour;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PARA CONSULTAR INFORMACIÓN DE CLIENTE (para el flujo)
-- ═══════════════════════════════════════════════════════════════════════════════
-- Este procedimiento retorna información completa del cliente para el flujo
CREATE OR REPLACE PROCEDURE sp_consultar_cliente_inscripcion(
    p_cliente_id IN NUMBER,
    p_cursor_cliente OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_cliente FOR
        SELECT 
            c.cli_id,
            c.cli_pnombre,
            c.cli_papellido,
            c.cli_sapellido,
            c.cli_snombre,
            c.cli_dni,
            c.cli_fnacimiento,
            TRUNC((SYSDATE - c.cli_fnacimiento) / 365.25) AS edad,
            c.cli_nac AS pais_nac_id,
            p_nac.p_nom AS pais_nac_nombre,
            p_nac.p_ue AS pais_nac_ue,
            c.cli_reside AS pais_reside_id,
            p_reside.p_nom AS pais_reside_nombre,
            p_reside.p_ue AS pais_reside_ue,
            c.cli_numpas,
            c.cli_fvenpas,
            CASE 
                WHEN p_nac.p_ue = 'SI' THEN 'EUR'
                ELSE 'USD'
            END AS moneda
        FROM clientes c
        LEFT JOIN paises p_nac ON c.cli_nac = p_nac.p_id
        LEFT JOIN paises p_reside ON c.cli_reside = p_reside.p_id
        WHERE c.cli_id = p_cliente_id;
END sp_consultar_cliente_inscripcion;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PARA CONSULTAR INFORMACIÓN DE FAN LEGO Y REPRESENTANTE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_consultar_fan_lego_inscripcion(
    p_fan_id IN NUMBER,
    p_cursor_fan OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_fan FOR
        SELECT 
            f.fl_id,
            f.fl_pnombre,
            f.fl_papellido,
            f.fl_sapellido,
            f.fl_snombre,
            f.fl_dni,
            f.fl_fnacimiento,
            TRUNC((SYSDATE - f.fl_fnacimiento) / 365.25) AS edad_fan,
            f.fl_nac AS pais_nac_id,
            pf.p_nom AS pais_nac_nombre,
            pf.p_ue AS pais_nac_ue,
            f.fl_repre AS representante_id,
            c.cli_id AS rep_cli_id,
            c.cli_pnombre AS rep_pnombre,
            c.cli_papellido AS rep_papellido,
            c.cli_sapellido AS rep_sapellido,
            c.cli_snombre AS rep_snombre,
            c.cli_dni AS rep_dni,
            c.cli_fnacimiento AS rep_fnacimiento,
            TRUNC((SYSDATE - c.cli_fnacimiento) / 365.25) AS edad_representante,
            c.cli_nac AS rep_pais_nac_id,
            pc.p_nom AS rep_pais_nac_nombre,
            pc.p_ue AS rep_pais_nac_ue,
            c.cli_reside AS rep_pais_reside_id,
            pr.p_nom AS rep_pais_reside_nombre,
            pr.p_ue AS rep_pais_reside_ue,
            c.cli_numpas AS rep_numpas,
            c.cli_fvenpas AS rep_fvenpas
        FROM f_lego f
        LEFT JOIN paises pf ON f.fl_nac = pf.p_id
        LEFT JOIN clientes c ON f.fl_repre = c.cli_id
        LEFT JOIN paises pc ON c.cli_nac = pc.p_id
        LEFT JOIN paises pr ON c.cli_reside = pr.p_id
        WHERE f.fl_id = p_fan_id;
END sp_consultar_fan_lego_inscripcion;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PARA OBTENER CUPOS DISPONIBLES DE UN TOUR
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_consultar_cupos_tour(
    p_tour_fecha IN DATE,
    p_cupos_totales OUT NUMBER,
    p_cupos_ocupados OUT NUMBER,
    p_cupos_disponibles OUT NUMBER,
    p_inscripcion_abierta OUT VARCHAR2,  -- 'SI' o 'NO'
    p_tour_existe OUT VARCHAR2,  -- 'SI' o 'NO'
    p_costo_unitario_usd OUT NUMBER,
    p_costo_unitario_eur OUT NUMBER,
    p_costo_unitario_dkk OUT NUMBER
)
IS
BEGIN
    -- Verificar si el tour existe
    BEGIN
        SELECT 
            to_cupos,
            to_costo
        INTO 
            p_cupos_totales,
            p_costo_unitario_usd
        FROM tours
        WHERE to_fini = p_tour_fecha;
        
        p_tour_existe := 'SI';
        
        -- Contar cupos ocupados (solo inscripciones pagadas)
        SELECT COUNT(*)
        INTO p_cupos_ocupados
        FROM det_inscrip di
        JOIN inscripciones i ON di.det_ins_ins = i.ins_num
        WHERE i.ins_tour = p_tour_fecha
          AND i.ins_estado = 'PAGO';
        
        p_cupos_disponibles := p_cupos_totales - p_cupos_ocupados;
        
        -- Calcular costos en otras monedas
        p_costo_unitario_eur := p_costo_unitario_usd * 0.8797;
        p_costo_unitario_dkk := ROUND(p_costo_unitario_usd * (23000 / 3500), 2);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_tour_existe := 'NO';
            p_cupos_totales := 0;
            p_cupos_ocupados := 0;
            p_cupos_disponibles := 0;
            p_costo_unitario_usd := 0;
            p_costo_unitario_eur := 0;
            p_costo_unitario_dkk := 0;
    END;
    
    -- Verificar si la inscripción está abierta
    IF fn_inscripcion_abierta(p_tour_fecha) THEN
        p_inscripcion_abierta := 'SI';
    ELSE
        p_inscripcion_abierta := 'NO';
    END IF;
END sp_consultar_cupos_tour;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PARA OBTENER LISTA DE TOURS DISPONIBLES
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_listar_tours_disponibles(
    p_cursor_tours OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_tours FOR
        SELECT 
            t.to_fini AS fecha_tour,
            t.to_cupos AS cupos_totales,
            t.to_costo AS costo_unitario_usd,
            ROUND(t.to_costo * 0.8797, 2) AS costo_unitario_eur,
            ROUND(t.to_costo * (23000 / 3500), 2) AS costo_unitario_dkk,
            NVL((
                SELECT COUNT(*)
                FROM det_inscrip di
                JOIN inscripciones i ON di.det_ins_ins = i.ins_num
                WHERE i.ins_tour = t.to_fini
                  AND i.ins_estado = 'PAGO'
            ), 0) AS cupos_ocupados,
            t.to_cupos - NVL((
                SELECT COUNT(*)
                FROM det_inscrip di
                JOIN inscripciones i ON di.det_ins_ins = i.ins_num
                WHERE i.ins_tour = t.to_fini
                  AND i.ins_estado = 'PAGO'
            ), 0) AS cupos_disponibles,
            CASE 
                WHEN fn_inscripcion_abierta(t.to_fini) THEN 'ABIERTA'
                ELSE 'CERRADA'
            END AS estado_inscripcion,
            CASE 
                WHEN t.to_fini < TRUNC(SYSDATE) THEN 'PASADO'
                WHEN t.to_fini = TRUNC(SYSDATE) THEN 'HOY'
                ELSE 'FUTURO'
            END AS tipo_fecha
        FROM tours t
        ORDER BY t.to_fini;
END sp_listar_tours_disponibles;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIN DEL ARCHIVO
-- ═══════════════════════════════════════════════════════════════════════════════

