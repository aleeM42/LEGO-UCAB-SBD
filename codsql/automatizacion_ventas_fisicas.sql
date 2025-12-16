-- ═══════════════════════════════════════════════════════════════════════════════
-- AUTOMATIZACIÓN COMPLETA DEL FLUJO DE VENTAS EN TIENDA FÍSICA
-- ═══════════════════════════════════════════════════════════════════════════════
-- Este archivo contiene procedimientos almacenados para automatizar todo el flujo
-- de ventas en tiendas físicas, incluyendo:
-- 1. Validación de horario de tienda
-- 2. Consulta de catálogo disponible con precios convertidos
-- 3. Visualización de lotes disponibles en inventario
-- 4. Generación de factura con detalles
-- 5. Descuento de inventario-lotes
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PARA VALIDAR HORARIO DE TIENDA
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_validar_horario_tienda(
    p_tienda_id IN NUMBER,
    p_fecha_hora IN DATE,
    p_esta_abierta OUT VARCHAR2,  -- 'SI' o 'NO'
    p_mensaje OUT VARCHAR2
)
IS
    v_dia_semana NUMBER;
    v_hora_actual VARCHAR2(5);
    v_hora_apertura VARCHAR2(5);
    v_hora_cierre VARCHAR2(5);
    v_horario_existe NUMBER;
BEGIN
    -- Obtener día de la semana (1=Domingo, 2=Lunes, ..., 7=Sábado)
    -- Oracle: 1=Domingo, 2=Lunes, ..., 7=Sábado
    v_dia_semana := TO_NUMBER(TO_CHAR(p_fecha_hora, 'D'));
    -- Convertir a formato del sistema (1=Domingo, 2=Lunes, etc.)
    
    -- Obtener hora actual en formato HH24:MI
    v_hora_actual := TO_CHAR(p_fecha_hora, 'HH24:MI');
    
    -- Verificar si existe horario para ese día
    SELECT COUNT(*)
    INTO v_horario_existe
    FROM horarios
    WHERE h_tid = p_tienda_id
      AND h_dia = v_dia_semana;
    
    IF v_horario_existe = 0 THEN
        p_esta_abierta := 'NO';
        p_mensaje := 'La tienda no tiene horario definido para este día de la semana.';
        RETURN;
    END IF;
    
    -- Obtener horario de apertura y cierre
    SELECT h_aper, h_cier
    INTO v_hora_apertura, v_hora_cierre
    FROM horarios
    WHERE h_tid = p_tienda_id
      AND h_dia = v_dia_semana;
    
    -- Validar si la hora actual está dentro del horario
    IF v_hora_actual >= v_hora_apertura AND v_hora_actual <= v_hora_cierre THEN
        p_esta_abierta := 'SI';
        p_mensaje := 'Tienda abierta. Horario: ' || v_hora_apertura || ' - ' || v_hora_cierre;
    ELSE
        p_esta_abierta := 'NO';
        p_mensaje := 'Tienda cerrada. Horario: ' || v_hora_apertura || ' - ' || v_hora_cierre || 
                     ' | Hora actual: ' || v_hora_actual;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        p_esta_abierta := 'NO';
        p_mensaje := 'Error validando horario: ' || SQLERRM;
END sp_validar_horario_tienda;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PARA CONSULTAR CATÁLOGO DE TIENDA CON PRECIOS CONVERTIDOS
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_consultar_catalogo_tienda(
    p_tienda_id IN NUMBER,
    p_cursor_catalogo OUT SYS_REFCURSOR
)
IS
    v_pais_id NUMBER;
    v_es_ue VARCHAR2(2);
    v_moneda VARCHAR2(3);
BEGIN
    -- Obtener país de la tienda
    SELECT ti_pais
    INTO v_pais_id
    FROM tiendas
    WHERE ti_id = p_tienda_id;
    
    -- Verificar si pertenece a la UE
    SELECT p_ue
    INTO v_es_ue
    FROM paises
    WHERE p_id = v_pais_id;
    
    -- Determinar moneda
    IF UPPER(v_es_ue) = 'SI' THEN
        v_moneda := 'EUR';
    ELSE
        v_moneda := 'USD';
    END IF;
    
    -- Abrir cursor con catálogo y precios convertidos
    OPEN p_cursor_catalogo FOR
        SELECT DISTINCT
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
            NVL(SUM(l.lot_stock - NVL(d.total_descontado, 0)), 0) AS stock_disponible,
            l.lot_id,
            l.lot_stock AS stock_lote
        FROM productos p
        JOIN hist_precios hp ON p.pro_cod = hp.hp_prod AND hp.hp_ffin IS NULL
        LEFT JOIN lotes l ON p.pro_cod = l.lot_prod AND l.lot_tienda = p_tienda_id
        LEFT JOIN (
            SELECT d_lote, d_prod, d_tienda, SUM(d_cantidad) AS total_descontado
            FROM descuentos
            GROUP BY d_lote, d_prod, d_tienda
        ) d ON l.lot_id = d.d_lote 
            AND l.lot_prod = d.d_prod 
            AND l.lot_tienda = d.d_tienda
        WHERE l.lot_tienda = p_tienda_id
          AND (l.lot_stock - NVL(d.total_descontado, 0)) > 0
        GROUP BY p.pro_cod, p.pro_nom, p.pro_desc, p.pro_raned, p.pro_ranpr, 
                 hp.hp_precio, l.lot_id, l.lot_stock, v_moneda, v_es_ue
        ORDER BY p.pro_nom;
        
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-21001, 'Error consultando catálogo: ' || SQLERRM);
END sp_consultar_catalogo_tienda;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PARA OBTENER INFORMACIÓN DEL CLIENTE
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_consultar_cliente_venta(
    p_cliente_id IN NUMBER,
    p_cursor_cliente OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_cliente FOR
        SELECT 
            c.cli_id,
            c.cli_pnombre || ' ' || NVL(c.cli_snombre || ' ', '') || 
            c.cli_papellido || ' ' || c.cli_sapellido AS nombre_completo,
            c.cli_dni,
            p.p_nom AS pais_nombre,
            p.p_ue AS pertenece_ue
        FROM clientes c
        LEFT JOIN paises p ON c.cli_reside = p.p_id
        WHERE c.cli_id = p_cliente_id;
        
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-21002, 'Error consultando cliente: ' || SQLERRM);
END sp_consultar_cliente_venta;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PRINCIPAL PARA AUTOMATIZAR VENTA EN TIENDA FÍSICA
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE sp_automatizar_venta_fisica(
    p_tienda_id IN NUMBER,
    p_cliente_id IN NUMBER,
    p_productos_ids IN VARCHAR2,  -- Formato: "123,45,67" (IDs de productos separados por comas)
    p_cantidades IN VARCHAR2,     -- Formato: "2,1,3" (cantidades separadas por comas)
    p_factura_num OUT NUMBER,
    p_total_usd OUT NUMBER,
    p_total_mostrar OUT NUMBER,
    p_moneda OUT VARCHAR2,
    p_mensaje OUT VARCHAR2
)
IS
    v_pais_id NUMBER;
    v_es_ue VARCHAR2(2);
    v_fact_num NUMBER;
    v_total_calculado NUMBER := 0;
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
BEGIN
    SAVEPOINT sp_venta_inicio;
    
    -- Validar que ambos strings tengan la misma cantidad de elementos
    IF p_productos_ids IS NULL OR LENGTH(TRIM(p_productos_ids)) = 0 THEN
        RAISE_APPLICATION_ERROR(-21010, 'Debe proporcionar al menos un producto.');
    END IF;
    
    IF p_cantidades IS NULL OR LENGTH(TRIM(p_cantidades)) = 0 THEN
        RAISE_APPLICATION_ERROR(-21011, 'Debe proporcionar las cantidades para cada producto.');
    END IF;
    
    v_count_ids := REGEXP_COUNT(TRIM(p_productos_ids), '[^,]+');
    v_count_cantidades := REGEXP_COUNT(TRIM(p_cantidades), '[^,]+');
    
    IF v_count_ids != v_count_cantidades THEN
        RAISE_APPLICATION_ERROR(-21012, 'La cantidad de productos (' || v_count_ids || 
                                ') no coincide con la cantidad de cantidades (' || v_count_cantidades || ').');
    END IF;
    
    -- Obtener país de la tienda para conversión de moneda
    SELECT ti_pais
    INTO v_pais_id
    FROM tiendas
    WHERE ti_id = p_tienda_id;
    
    SELECT p_ue
    INTO v_es_ue
    FROM paises
    WHERE p_id = v_pais_id;
    
    IF UPPER(v_es_ue) = 'SI' THEN
        p_moneda := 'EUR';
    ELSE
        p_moneda := 'USD';
    END IF;
    
    -- Iniciar factura
    INICIAR_FACTURA_FISICA(
        p_cli_id => p_cliente_id,
        p_ti_id => p_tienda_id,
        p_fact_tf_num => v_fact_num,
        p_msg => p_mensaje
    );
    
    IF v_fact_num IS NULL THEN
        RAISE_APPLICATION_ERROR(-21013, 'Error al iniciar factura: ' || p_mensaje);
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
                    RAISE_APPLICATION_ERROR(-21014, 'La cantidad debe ser mayor a 0. Producto: ' || v_prod_id);
                END IF;
                
                -- Insertar detalle
                INSERTAR_DETALLE_FISICA(
                    p_ti_id => p_tienda_id,
                    p_fact_num => v_fact_num,
                    p_pro_cod => v_prod_id,
                    p_cantidad => v_cantidad,
                    p_msg => v_msg_detalle
                );
                
                IF v_msg_detalle NOT LIKE 'Exito%' THEN
                    RAISE_APPLICATION_ERROR(-21015, 'Error agregando producto ' || v_prod_id || ': ' || v_msg_detalle);
                END IF;
                
            EXCEPTION
                WHEN VALUE_ERROR THEN
                    RAISE_APPLICATION_ERROR(-21016, 'Error: ID o cantidad inválido. Producto: [' || v_prod_id_str || 
                                    '], Cantidad: [' || v_cantidad_str || ']');
            END;
        END IF;
    END LOOP;
    
    -- Finalizar factura
    FINALIZAR_FACTURA_FISICA(
        p_ti_id => p_tienda_id,
        p_fact_num => v_fact_num,
        p_msg => p_mensaje
    );
    
    -- Obtener total final
    SELECT fact_tf_total
    INTO v_total_calculado
    FROM factura_tf
    WHERE fact_tf_num = v_fact_num
      AND fact_tf_tie = p_tienda_id;
    
    p_total_usd := v_total_calculado;
    
    -- Convertir total según moneda
    IF p_moneda = 'EUR' THEN
        p_total_mostrar := ROUND(v_total_calculado * 0.8797, 2);
    ELSE
        p_total_mostrar := v_total_calculado;
    END IF;
    
    p_mensaje := 'Venta completada exitosamente. Factura: ' || v_fact_num || 
                 ' | Total: ' || p_total_mostrar || ' ' || p_moneda;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_venta_inicio;
        p_factura_num := NULL;
        p_total_usd := 0;
        p_total_mostrar := 0;
        p_moneda := 'USD';
        p_mensaje := 'Error: ' || SQLERRM;
        RAISE;
END sp_automatizar_venta_fisica;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO PARA DESCONTAR INVENTARIO-LOTES POR DÍA/TIENDA/FACTURA
-- ═══════════════════════════════════════════════════════════════════════════════
-- Este procedimiento procesa todas las facturas de un día específico para una tienda
-- y descuenta el inventario de los lotes según los descuentos registrados
CREATE OR REPLACE PROCEDURE sp_descontar_inventario_lotes(
    p_tienda_id IN NUMBER,
    p_fecha IN DATE,
    p_facturas_procesadas OUT NUMBER,
    p_mensaje OUT VARCHAR2
)
IS
    v_factura_num NUMBER;
    v_lote_id NUMBER;
    v_prod_id NUMBER;
    v_cantidad_descontar NUMBER;
    v_stock_actual NUMBER;
    v_stock_descontado NUMBER;
    v_total_descontado NUMBER;
    v_facturas_count NUMBER := 0;
BEGIN
    -- Obtener todas las facturas del día para la tienda
    FOR factura_rec IN (
        SELECT DISTINCT fact_tf_num
        FROM factura_tf
        WHERE fact_tf_tie = p_tienda_id
          AND TRUNC(fact_tf_femision) = TRUNC(p_fecha)
        ORDER BY fact_tf_num
    ) LOOP
        v_factura_num := factura_rec.fact_tf_num;
        v_facturas_count := v_facturas_count + 1;
        
        -- Para cada detalle de la factura, descontar del lote
        FOR detalle_rec IN (
            SELECT 
                dt.det_ft_lote,
                dt.det_ft_prod,
                dt.det_ft_cantidad,
                l.lot_stock,
                NVL(SUM(d.d_cantidad), 0) AS ya_descontado
            FROM det_fact_t dt
            JOIN lotes l ON dt.det_ft_prod = l.lot_prod 
                         AND dt.det_ft_lote = l.lot_id 
                         AND dt.det_ft_tienda = l.lot_tienda
            LEFT JOIN descuentos d ON l.lot_id = d.d_lote 
                                   AND l.lot_prod = d.d_prod 
                                   AND l.lot_tienda = d.d_tienda
                                   AND TRUNC(d.d_fecha) = TRUNC(p_fecha)
            WHERE dt.det_ft_fact = v_factura_num
              AND dt.det_ft_tienda_fact = p_tienda_id
            GROUP BY dt.det_ft_lote, dt.det_ft_prod, dt.det_ft_cantidad, l.lot_stock
        ) LOOP
            v_lote_id := detalle_rec.det_ft_lote;
            v_prod_id := detalle_rec.det_ft_prod;
            v_cantidad_descontar := detalle_rec.det_ft_cantidad;
            v_stock_actual := detalle_rec.lot_stock;
            v_stock_descontado := detalle_rec.ya_descontado;
            
            -- Calcular stock disponible (stock original - ya descontado)
            v_total_descontado := v_stock_actual - v_stock_descontado;
            
            -- Verificar que hay stock suficiente
            IF v_total_descontado < v_cantidad_descontar THEN
                RAISE_APPLICATION_ERROR(-21020, 
                    'Stock insuficiente en lote ' || v_lote_id || 
                    ' para producto ' || v_prod_id || 
                    '. Disponible: ' || v_total_descontado || 
                    ', Requerido: ' || v_cantidad_descontar);
            END IF;
            
            -- El descuento ya se registró en INSERTAR_DETALLE_FISICA
            -- Este procedimiento solo verifica y reporta
        END LOOP;
    END LOOP;
    
    p_facturas_procesadas := v_facturas_count;
    p_mensaje := 'Proceso completado. Facturas procesadas: ' || v_facturas_count || 
                 ' | Fecha: ' || TO_CHAR(p_fecha, 'DD/MM/YYYY');
    
EXCEPTION
    WHEN OTHERS THEN
        p_facturas_procesadas := 0;
        p_mensaje := 'Error procesando descuentos: ' || SQLERRM;
        RAISE;
END sp_descontar_inventario_lotes;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- FIN DEL ARCHIVO
-- ═══════════════════════════════════════════════════════════════════════════════

