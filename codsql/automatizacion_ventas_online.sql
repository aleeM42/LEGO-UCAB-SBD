-- ═══════════════════════════════════════════════════════════════════════════════
-- AUTOMATIZACIÓN COMPLETA DEL FLUJO DE VENTAS ONLINE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Este archivo contiene procedimientos almacenados para automatizar todo el flujo
-- de ventas online, incluyendo:
-- 1. Consulta de catálogo por país con precios convertidos
-- 2. Validación de límites de catálogo
-- 3. Generación de factura con detalles
-- 4. Cálculo y actualización de puntos de lealtad
-- 5. Aplicación de recargos por envío según nacionalidad
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PARA CONSULTAR CATÁLOGO ONLINE POR PAÍS CON PRECIOS CONVERTIDOS
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_consultar_catalogo_online(
    p_pais_id IN NUMBER,
    p_cursor_catalogo OUT SYS_REFCURSOR
)
IS
    v_es_ue VARCHAR2(2);
    v_moneda VARCHAR2(3);
BEGIN
    -- Verificar si el país pertenece a la UE
    SELECT p_ue
    INTO v_es_ue
    FROM paises
    WHERE p_id = p_pais_id;
    
    -- Determinar moneda
    IF UPPER(v_es_ue) = 'SI' THEN
        v_moneda := 'EUR';
    ELSE
        v_moneda := 'USD';
    END IF;
    
    -- Abrir cursor con catálogo y precios convertidos
    OPEN p_cursor_catalogo FOR
        SELECT 
            p.pro_cod,
            p.pro_nom,
            p.pro_desc,
            p.pro_raned,
            p.pro_ranpr,
            hp.hp_precio AS precio_usd,
            CASE 
                WHEN UPPER(v_es_ue) = 'SI' THEN 
                    ROUND(hp.hp_precio * 0.8797, 2)  -- Convertir a EUR
                ELSE 
                    hp.hp_precio  -- Mantener en USD
            END AS precio_mostrar,
            v_moneda AS moneda,
            c.cat_limcom AS limite_compra
        FROM productos p
        JOIN hist_precios hp ON p.pro_cod = hp.hp_prod AND hp.hp_ffin IS NULL
        JOIN catalogos c ON p.pro_cod = c.cat_prod
        WHERE c.cat_pais = p_pais_id
        ORDER BY p.pro_nom;
        
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-22001, 'Error consultando catálogo online: ' || SQLERRM);
END sp_consultar_catalogo_online;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PRINCIPAL PARA AUTOMATIZAR VENTA ONLINE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_automatizar_venta_online(
    p_cliente_id IN NUMBER,
    p_productos_ids IN VARCHAR2,  -- Formato: "123,45,67" (IDs de productos separados por comas)
    p_cantidades IN VARCHAR2,      -- Formato: "2,1,3" (cantidades separadas por comas)
    p_factura_num OUT NUMBER,
    p_total_usd OUT NUMBER,
    p_total_mostrar OUT NUMBER,
    p_moneda OUT VARCHAR2,
    p_puntos_generados OUT NUMBER,
    p_puntos_acumulados OUT NUMBER,
    p_costo_envio OUT NUMBER,
    p_recargo_envio OUT NUMBER,
    p_mensaje OUT VARCHAR2
)
IS
    v_pais_id NUMBER;
    v_es_ue VARCHAR2(2);
    v_fact_num NUMBER;
    v_total_detalles NUMBER := 0;
    v_total_final NUMBER := 0;
    v_pos_comma NUMBER;
    v_prod_id_str VARCHAR2(50);
    v_cantidad_str VARCHAR2(10);
    v_string_restante_ids VARCHAR2(4000);
    v_string_restante_cantidades VARCHAR2(4000);
    v_prod_id NUMBER;
    v_cantidad NUMBER;
    v_msg_detalle VARCHAR2(500);
    v_count_ids NUMBER;
    v_count_cantidades NUMBER;
    v_puntos_ant NUMBER := 0;
    v_venta_gratis VARCHAR2(2) := 'NO';
    v_recargo_porcentaje NUMBER;
BEGIN
    -- Validar que ambos strings tengan la misma cantidad de elementos
    IF p_productos_ids IS NULL OR LENGTH(TRIM(p_productos_ids)) = 0 THEN
        RAISE_APPLICATION_ERROR(-22010, 'Debe proporcionar al menos un producto.');
    END IF;
    
    IF p_cantidades IS NULL OR LENGTH(TRIM(p_cantidades)) = 0 THEN
        RAISE_APPLICATION_ERROR(-22011, 'Debe proporcionar las cantidades para cada producto.');
    END IF;
    
    v_count_ids := REGEXP_COUNT(TRIM(p_productos_ids), '[^,]+');
    v_count_cantidades := REGEXP_COUNT(TRIM(p_cantidades), '[^,]+');
    
    IF v_count_ids != v_count_cantidades THEN
        RAISE_APPLICATION_ERROR(-22012, 'La cantidad de productos (' || v_count_ids || 
                                ') no coincide con la cantidad de cantidades (' || v_count_cantidades || ').');
    END IF;
    
    -- Obtener país de residencia del cliente para conversión de moneda
    SELECT cli_reside
    INTO v_pais_id
    FROM clientes
    WHERE cli_id = p_cliente_id;
    
    SELECT p_ue
    INTO v_es_ue
    FROM paises
    WHERE p_id = v_pais_id;
    
    IF UPPER(v_es_ue) = 'SI' THEN
        p_moneda := 'EUR';
        v_recargo_porcentaje := 0.05;  -- 5% para UE
    ELSE
        p_moneda := 'USD';
        v_recargo_porcentaje := 0.15;  -- 15% para no-UE
    END IF;
    
    -- Establecer SAVEPOINT después de las validaciones iniciales y antes de iniciar factura
    SAVEPOINT sp_venta_online_inicio;
    
    -- Iniciar factura
    INICIAR_FACTURA_ONLINE(
        p_cli_id => p_cliente_id,
        p_fact_o_num => v_fact_num,
        p_msg => p_mensaje
    );
    
    IF v_fact_num IS NULL THEN
        RAISE_APPLICATION_ERROR(-22013, 'Error al iniciar factura: ' || p_mensaje);
    END IF;
    
    p_factura_num := v_fact_num;
    
    -- Procesar productos y cantidades
    v_string_restante_ids := TRIM(p_productos_ids);
    v_string_restante_cantidades := TRIM(p_cantidades);
    
    WHILE v_string_restante_ids IS NOT NULL AND LENGTH(v_string_restante_ids) > 0 LOOP
        -- Extraer ID de producto
        v_pos_comma := INSTR(v_string_restante_ids, ',');
        IF v_pos_comma > 0 THEN
            v_prod_id_str := TRIM(SUBSTR(v_string_restante_ids, 1, v_pos_comma - 1));
            v_string_restante_ids := SUBSTR(v_string_restante_ids, v_pos_comma + 1);
        ELSE
            v_prod_id_str := TRIM(v_string_restante_ids);
            v_string_restante_ids := NULL;
        END IF;
        
        -- Extraer cantidad
        v_pos_comma := INSTR(v_string_restante_cantidades, ',');
        IF v_pos_comma > 0 THEN
            v_cantidad_str := TRIM(SUBSTR(v_string_restante_cantidades, 1, v_pos_comma - 1));
            v_string_restante_cantidades := SUBSTR(v_string_restante_cantidades, v_pos_comma + 1);
        ELSE
            v_cantidad_str := TRIM(v_string_restante_cantidades);
            v_string_restante_cantidades := NULL;
        END IF;
        
        IF v_prod_id_str IS NOT NULL AND v_prod_id_str != '' AND 
           v_cantidad_str IS NOT NULL AND v_cantidad_str != '' THEN
            BEGIN
                v_prod_id := TO_NUMBER(v_prod_id_str);
                v_cantidad := TO_NUMBER(v_cantidad_str);
                
                IF v_cantidad <= 0 THEN
                    RAISE_APPLICATION_ERROR(-22014, 'La cantidad debe ser mayor a 0. Producto: ' || v_prod_id);
                END IF;
                
                -- Insertar detalle
                INSERTAR_DETALLE_ONLINE(
                    p_fact_num => v_fact_num,
                    p_pro_cod => v_prod_id,
                    p_cantidad => v_cantidad,
                    p_msg => v_msg_detalle
                );
                
                IF v_msg_detalle NOT LIKE 'Exito%' THEN
                    RAISE_APPLICATION_ERROR(-22015, 'Error agregando producto ' || v_prod_id || ': ' || v_msg_detalle);
                END IF;
                
            EXCEPTION
                WHEN VALUE_ERROR THEN
                    RAISE_APPLICATION_ERROR(-22016, 'Error: ID o cantidad inválido. Producto: [' || v_prod_id_str || 
                                    '], Cantidad: [' || v_cantidad_str || ']');
            END;
        END IF;
    END LOOP;
    
    -- Finalizar factura (calcula puntos, envío, recargos)
    FINALIZAR_FACTURA_ONLINE(
        p_fact_num => v_fact_num,
        p_msg => p_mensaje
    );
    
    -- Obtener información final de la factura
    SELECT 
        fact_o_total,
        fact_o_puntosgen,
        CASE 
            WHEN venta_gratis = 'SI' THEN 1
            ELSE 0
        END
    INTO 
        v_total_final,
        p_puntos_generados,
        v_venta_gratis
    FROM factura_o
    WHERE fact_o_num = v_fact_num;
    
    -- Calcular total de detalles (sin envío ni recargos) usando la función
    v_total_detalles := fn_calcular_total_factura_online(v_fact_num);
    
    p_total_usd := v_total_detalles;
    
    -- Convertir total según moneda
    IF p_moneda = 'EUR' THEN
        p_total_mostrar := ROUND(v_total_detalles * 0.8797, 2);
    ELSE
        p_total_mostrar := v_total_detalles;
    END IF;
    
    -- Calcular costo de envío
    p_costo_envio := 
        CASE 
            WHEN v_total_detalles >= 500 THEN 20
            WHEN v_total_detalles >= 100 THEN 15
            ELSE 10 
        END;
    
    -- Calcular recargo de envío
    IF v_venta_gratis = 1 THEN
        p_recargo_envio := ROUND(p_costo_envio * v_recargo_porcentaje, 2);
    ELSE
        p_recargo_envio := ROUND(v_total_detalles * v_recargo_porcentaje, 2);
    END IF;
    
    -- Obtener puntos acumulados totales del cliente
    SELECT NVL(SUM(fact_o_puntosgen), 0)
    INTO p_puntos_acumulados
    FROM factura_o
    WHERE fact_o_cli = p_cliente_id;
    
    p_mensaje := 'Venta online completada exitosamente. Factura: ' || v_fact_num || 
                 ' | Total productos: ' || p_total_mostrar || ' ' || p_moneda ||
                 ' | Envío: ' || p_costo_envio || ' | Recargo: ' || p_recargo_envio ||
                 ' | Puntos generados: ' || p_puntos_generados ||
                 ' | Puntos acumulados totales: ' || p_puntos_acumulados;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Intentar hacer ROLLBACK al SAVEPOINT si existe, si no, hacer ROLLBACK completo
        BEGIN
            ROLLBACK TO sp_venta_online_inicio;
        EXCEPTION
            WHEN OTHERS THEN
                -- Si el SAVEPOINT no existe, hacer ROLLBACK completo
                ROLLBACK;
        END;
        p_factura_num := NULL;
        p_total_usd := 0;
        p_total_mostrar := 0;
        p_moneda := 'USD';
        p_puntos_generados := 0;
        p_puntos_acumulados := 0;
        p_costo_envio := 0;
        p_recargo_envio := 0;
        p_mensaje := 'Error: ' || SQLERRM;
        RAISE;
END sp_automatizar_venta_online;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIN DEL ARCHIVO
-- ═══════════════════════════════════════════════════════════════════════════════

