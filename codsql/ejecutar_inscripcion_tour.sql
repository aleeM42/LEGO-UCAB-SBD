-- ═══════════════════════════════════════════════════════════════════════════════
-- SCRIPT INTERACTIVO PARA AUTOMATIZACIÓN DE INSCRIPCIÓN AL TOUR
-- ═══════════════════════════════════════════════════════════════════════════════
-- Este script se ejecuta directamente en SQL Developer
-- Usa variables de sustitución para ingresar datos interactivamente
-- ═══════════════════════════════════════════════════════════════════════════════

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;
DEFINE p_participantes = '';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 1: SOLICITAR DATOS AL USUARIO
-- ═══════════════════════════════════════════════════════════════════════════════

PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT AUTOMATIZACIÓN DE INSCRIPCIÓN AL TOUR
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 


-- Solicitar fecha del tour
PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT DATOS DE LA INSCRIPCIÓN
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

ACCEPT p_fecha_tour CHAR PROMPT 'Ingrese la fecha del tour (YYYY-MM-DD): '

-- Solicitar ID del cliente responsable
ACCEPT p_cliente_responsable NUMBER PROMPT 'Ingrese el ID del cliente responsable: '

-- Solicitar participantes
PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT FORMATO DE PARTICIPANTES
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT Formato: Dos campos separados
PROMPT - IDs de participantes separados por comas: 123,5,7
PROMPT - Tipos de participantes separados por comas: 1,2,2
PROMPT 
PROMPT IMPORTANTE:
PROMPT - Use comas (,) para separar participantes
PROMPT - Tipo 1 = ADULTO (cliente)
PROMPT - Tipo 2 = MENOR (fan LEGO)
PROMPT - Debe haber la misma cantidad de IDs y tipos
PROMPT - Ejemplo: IDs: 123,5,7  Tipos: 1,2,2
PROMPT 

ACCEPT p_participantes_ids CHAR PROMPT 'IDs de participantes (separados por comas): '
ACCEPT p_participantes_tipos CHAR PROMPT 'Tipos de participantes (1=ADULTO, 2=MENOR, separados por comas): '

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 2: PROCESAR INSCRIPCIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

DECLARE
    v_fecha_tour DATE;
    v_cliente_responsable NUMBER;
    v_participantes_ids VARCHAR2(4000);
    v_participantes_tipos VARCHAR2(4000);
    v_ins_num NUMBER;
    v_costo_usd NUMBER;
    v_costo_eur NUMBER;
    v_costo_dkk NUMBER;
    v_moneda VARCHAR2(3);
    v_pais VARCHAR2(50);
    v_ue VARCHAR2(2);
    v_entradas NUMBER;
    v_cantidad NUMBER;
    v_mensaje VARCHAR2(1000);
    v_cursor_part SYS_REFCURSOR;
    v_cursor_rep SYS_REFCURSOR;
    
    -- Variables para mostrar participantes
    v_tipo_part VARCHAR2(10);
    v_cli_id NUMBER;
    v_fan_id NUMBER;
    v_nombre_completo VARCHAR2(200);
    v_dni NUMBER;
    v_edad NUMBER;
    
    -- Variables para mostrar representantes
    v_fan_id_rep NUMBER;
    v_nombre_fan VARCHAR2(200);
    v_dni_fan NUMBER;
    v_rep_id NUMBER;
    v_nombre_rep VARCHAR2(200);
    v_dni_rep NUMBER;
    v_edad_rep NUMBER;
BEGIN
    -- Convertir fecha
    v_fecha_tour := TO_DATE('&p_fecha_tour', 'YYYY-MM-DD');
    v_cliente_responsable := &p_cliente_responsable;
    v_participantes_ids := TRIM('&p_participantes_ids');
    v_participantes_tipos := TRIM('&p_participantes_tipos');
    
    -- Limpiar espacios en blanco alrededor de las comas
    v_participantes_ids := REGEXP_REPLACE(v_participantes_ids, '\s*,\s*', ',');
    v_participantes_tipos := REGEXP_REPLACE(v_participantes_tipos, '\s*,\s*', ',');
    -- Eliminar comas finales si existen
    IF SUBSTR(v_participantes_ids, -1) = ',' THEN
        v_participantes_ids := SUBSTR(v_participantes_ids, 1, LENGTH(v_participantes_ids) - 1);
    END IF;
    IF SUBSTR(v_participantes_tipos, -1) = ',' THEN
        v_participantes_tipos := SUBSTR(v_participantes_tipos, 1, LENGTH(v_participantes_tipos) - 1);
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('IDs de participantes: [' || v_participantes_ids || ']');
    DBMS_OUTPUT.PUT_LINE('Tipos de participantes: [' || v_participantes_tipos || ']');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Llamar al procedimiento principal
    sp_automatizar_inscripcion_tour(
        p_tour_fecha => v_fecha_tour,
        p_cliente_responsable => v_cliente_responsable,
        p_participantes_ids => v_participantes_ids,
        p_participantes_tipos => v_participantes_tipos,
        p_numero_inscripcion => v_ins_num,
        p_costo_total_usd => v_costo_usd,
        p_costo_total_eur => v_costo_eur,
        p_costo_total_dkk => v_costo_dkk,
        p_moneda_cliente => v_moneda,
        p_pais_cliente => v_pais,
        p_pertenece_ue => v_ue,
        p_entradas_generadas => v_entradas,
        p_cantidad_participantes => v_cantidad,
        p_mensaje => v_mensaje,
        p_detalle_participantes => v_cursor_part,
        p_detalle_representantes => v_cursor_rep
    );
    
    IF v_ins_num = -1 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || v_mensaje);
        RETURN;
    END IF;
    
    -- Mostrar resumen de la inscripción
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('INSCRIPCIÓN CREADA EXITOSAMENTE');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Número de inscripción: ' || v_ins_num);
    DBMS_OUTPUT.PUT_LINE('Fecha del tour: ' || TO_CHAR(v_fecha_tour, 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE('Cliente responsable: ' || v_cliente_responsable);
    DBMS_OUTPUT.PUT_LINE('País del cliente: ' || v_pais || ' (UE: ' || v_ue || ')');
    DBMS_OUTPUT.PUT_LINE('Moneda: ' || v_moneda);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('COSTOS');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Total USD: $' || ROUND(v_costo_usd, 2));
    DBMS_OUTPUT.PUT_LINE('Total EUR: €' || ROUND(v_costo_eur, 2));
    DBMS_OUTPUT.PUT_LINE('Total DKK: ' || ROUND(v_costo_dkk, 2) || ' DKK');
    DBMS_OUTPUT.PUT_LINE('Total en moneda del cliente (' || v_moneda || '): ' || 
                        CASE WHEN v_moneda = 'EUR' THEN '€' || ROUND(v_costo_eur, 2) 
                             ELSE '$' || ROUND(v_costo_usd, 2) END);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Participantes: ' || v_cantidad);
    DBMS_OUTPUT.PUT_LINE('Entradas generadas: ' || v_entradas);
    DBMS_OUTPUT.PUT_LINE('Estado: PAGO');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Mostrar información de participantes
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('INFORMACIÓN DE PARTICIPANTES');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    
    LOOP
        FETCH v_cursor_part INTO
            v_tipo_part, v_cli_id, v_fan_id, v_nombre_completo, v_dni, v_edad;
        EXIT WHEN v_cursor_part%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Tipo: ' || v_tipo_part);
        DBMS_OUTPUT.PUT_LINE('Nombre: ' || v_nombre_completo);
        DBMS_OUTPUT.PUT_LINE('DNI: ' || v_dni);
        DBMS_OUTPUT.PUT_LINE('Edad: ' || v_edad || ' años');
        IF v_tipo_part = 'ADULTO' THEN
            DBMS_OUTPUT.PUT_LINE('ID Cliente: ' || v_cli_id);
        ELSE
            DBMS_OUTPUT.PUT_LINE('ID Fan LEGO: ' || v_fan_id);
        END IF;
    END LOOP;
    
    CLOSE v_cursor_part;
    
    -- Mostrar información de representantes (si hay menores)
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('INFORMACIÓN DE REPRESENTANTES (para menores)');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    
    LOOP
        FETCH v_cursor_rep INTO
            v_fan_id_rep, v_nombre_fan, v_dni_fan, v_rep_id, v_nombre_rep, v_dni_rep, v_edad_rep;
        EXIT WHEN v_cursor_rep%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Fan LEGO:');
        DBMS_OUTPUT.PUT_LINE('  ID: ' || v_fan_id_rep);
        DBMS_OUTPUT.PUT_LINE('  Nombre: ' || v_nombre_fan);
        DBMS_OUTPUT.PUT_LINE('  DNI: ' || v_dni_fan);
        DBMS_OUTPUT.PUT_LINE('Representante:');
        DBMS_OUTPUT.PUT_LINE('  ID: ' || v_rep_id);
        DBMS_OUTPUT.PUT_LINE('  Nombre: ' || v_nombre_rep);
        DBMS_OUTPUT.PUT_LINE('  DNI: ' || v_dni_rep);
        DBMS_OUTPUT.PUT_LINE('  Edad: ' || v_edad_rep || ' años');
    END LOOP;
    
    CLOSE v_cursor_rep;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Procedimiento PL/SQL terminado correctamente.');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    
EXCEPTION
    WHEN OTHERS THEN
        IF v_cursor_part%ISOPEN THEN
            CLOSE v_cursor_part;
        END IF;
        IF v_cursor_rep%ISOPEN THEN
            CLOSE v_cursor_rep;
        END IF;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END;
/

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT Script completado.
PROMPT ═══════════════════════════════════════════════════════════════════════════

