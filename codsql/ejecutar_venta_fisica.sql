-- ═══════════════════════════════════════════════════════════════════════════════
-- SCRIPT INTERACTIVO PARA AUTOMATIZACIÓN DE VENTAS EN TIENDA FÍSICA
-- ═══════════════════════════════════════════════════════════════════════════════
-- Este script guía al usuario a través del proceso completo de venta en tienda física
-- usando SQL Developer con comandos ACCEPT y PROMPT
-- ═══════════════════════════════════════════════════════════════════════════════

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT AUTOMATIZACIÓN DE VENTA EN TIENDA FÍSICA
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 1: SELECCIONAR TIENDA Y VALIDAR HORARIO
-- ═══════════════════════════════════════════════════════════════════════════════

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT SELECCIÓN DE TIENDA
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

ACCEPT p_tienda_id NUMBER PROMPT 'Ingrese el ID de la tienda: '

-- Mostrar información de la tienda
DECLARE
    v_tienda_nombre VARCHAR2(30);
    v_tienda_pais VARCHAR2(30);
    v_tienda_ciudad VARCHAR2(30);
    v_pais_id NUMBER;
    v_es_ue VARCHAR2(2);
BEGIN
    SELECT 
        t.ti_nom,
        p.p_nom,
        ciu.ciu_nom,
        t.ti_pais
    INTO 
        v_tienda_nombre,
        v_tienda_pais,
        v_tienda_ciudad,
        v_pais_id
    FROM tiendas t
    JOIN paises p ON t.ti_pais = p.p_id
    JOIN ciudades ciu ON t.ti_pais = ciu.cp_id 
                      AND t.ti_estado = ciu.ce_id 
                      AND t.ti_ciu = ciu.ciu_id
    WHERE t.ti_id = &p_tienda_id;
    
    SELECT p_ue INTO v_es_ue
    FROM paises
    WHERE p_id = v_pais_id;
    
    DBMS_OUTPUT.PUT_LINE('Tienda: ' || v_tienda_nombre);
    DBMS_OUTPUT.PUT_LINE('Ubicación: ' || v_tienda_ciudad || ', ' || v_tienda_pais);
    DBMS_OUTPUT.PUT_LINE('Moneda: ' || CASE WHEN v_es_ue = 'SI' THEN 'EUR' ELSE 'USD' END);
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Tienda no encontrada.');
        RAISE_APPLICATION_ERROR(-21000, 'Tienda no encontrada: ' || &p_tienda_id);
END;
/

-- Validar horario
PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT VALIDACIÓN DE HORARIO
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

DECLARE
    v_esta_abierta VARCHAR2(2);
    v_mensaje VARCHAR2(500);
BEGIN
    sp_validar_horario_tienda(
        p_tienda_id => &p_tienda_id,
        p_fecha_hora => SYSDATE,
        p_esta_abierta => v_esta_abierta,
        p_mensaje => v_mensaje
    );
    
    DBMS_OUTPUT.PUT_LINE(v_mensaje);
    DBMS_OUTPUT.PUT_LINE('');
    
    IF v_esta_abierta = 'NO' THEN
        RAISE_APPLICATION_ERROR(-21001, 'La tienda está cerrada. No se puede realizar la venta.');
    END IF;
END;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 2: CONSULTAR CLIENTE
-- ═══════════════════════════════════════════════════════════════════════════════

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT DATOS DEL CLIENTE
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

ACCEPT p_cliente_id NUMBER PROMPT 'Ingrese el ID del cliente: '

DECLARE
    v_cursor_cliente SYS_REFCURSOR;
    v_cli_id NUMBER;
    v_nombre_completo VARCHAR2(200);
    v_dni NUMBER;
    v_pais_nombre VARCHAR2(30);
    v_pertenece_ue VARCHAR2(2);
BEGIN
    sp_consultar_cliente_venta(
        p_cliente_id => &p_cliente_id,
        p_cursor_cliente => v_cursor_cliente
    );
    
    FETCH v_cursor_cliente INTO
        v_cli_id, v_nombre_completo, v_dni, v_pais_nombre, v_pertenece_ue;
    
    CLOSE v_cursor_cliente;
    
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_cli_id);
    DBMS_OUTPUT.PUT_LINE('Nombre: ' || v_nombre_completo);
    DBMS_OUTPUT.PUT_LINE('DNI: ' || v_dni);
    DBMS_OUTPUT.PUT_LINE('País: ' || v_pais_nombre || ' (UE: ' || v_pertenece_ue || ')');
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Cliente no encontrado.');
        RAISE_APPLICATION_ERROR(-21002, 'Cliente no encontrado: ' || &p_cliente_id);
END;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 3: MOSTRAR CATÁLOGO DISPONIBLE
-- ═══════════════════════════════════════════════════════════════════════════════

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT CATÁLOGO DISPONIBLE DE LA TIENDA
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

DECLARE
    v_cursor_catalogo SYS_REFCURSOR;
    v_pro_cod NUMBER;
    v_pro_nom VARCHAR2(50);
    v_pro_desc VARCHAR2(800);
    v_pro_raned NUMBER;
    v_pro_ranpr VARCHAR2(4);
    v_precio_usd NUMBER;
    v_precio_mostrar NUMBER;
    v_moneda VARCHAR2(3);
    v_stock_disponible NUMBER;
    v_lot_id NUMBER;
    v_stock_lote NUMBER;
    v_simbolo VARCHAR2(3);
BEGIN
    sp_consultar_catalogo_tienda(
        p_tienda_id => &p_tienda_id,
        p_cursor_catalogo => v_cursor_catalogo
    );
    
    v_simbolo := 'USD';
    
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('PRODUCTOS DISPONIBLES');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('');
    
    LOOP
        FETCH v_cursor_catalogo INTO
            v_pro_cod, v_pro_nom, v_pro_desc, v_pro_raned, v_pro_ranpr,
            v_precio_usd, v_precio_mostrar, v_moneda, v_stock_disponible,
            v_lot_id, v_stock_lote;
        EXIT WHEN v_cursor_catalogo%NOTFOUND;
        
        IF v_moneda = 'EUR' THEN
            v_simbolo := 'EUR';
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_pro_cod || ' | ' || v_pro_nom);
        DBMS_OUTPUT.PUT_LINE('  Descripción: ' || SUBSTR(v_pro_desc, 1, 50) || '...');
        DBMS_OUTPUT.PUT_LINE('  Precio: ' || v_simbolo || ' ' || v_precio_mostrar || 
                           ' (USD ' || v_precio_usd || ')');
        DBMS_OUTPUT.PUT_LINE('  Stock disponible: ' || v_stock_disponible);
        DBMS_OUTPUT.PUT_LINE('  Rango edad: ' || v_pro_raned || ' | Rango precio: ' || v_pro_ranpr);
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    CLOSE v_cursor_catalogo;
    
    IF v_cursor_catalogo%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No hay productos disponibles en el inventario de esta tienda.');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        IF v_cursor_catalogo%ISOPEN THEN
            CLOSE v_cursor_catalogo;
        END IF;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 4: AGREGAR PRODUCTOS A LA FACTURA
-- ═══════════════════════════════════════════════════════════════════════════════

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT AGREGAR PRODUCTOS A LA FACTURA
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 
PROMPT Formato: Dos campos separados
PROMPT - IDs de productos separados por comas: 123,45,67
PROMPT - Cantidades separadas por comas: 2,1,3
PROMPT 
PROMPT IMPORTANTE:
PROMPT - Use comas (,) para separar productos y cantidades
PROMPT - Debe haber la misma cantidad de IDs y cantidades
PROMPT - Ejemplo: IDs: 123,45,67  Cantidades: 2,1,3
PROMPT 

ACCEPT p_productos_ids CHAR PROMPT 'IDs de productos (separados por comas): '
ACCEPT p_cantidades CHAR PROMPT 'Cantidades (separados por comas): '

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 5: CONFIRMAR Y PROCESAR VENTA
-- ═══════════════════════════════════════════════════════════════════════════════

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT CONFIRMAR VENTA
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

ACCEPT p_confirmar CHAR PROMPT '¿Desea confirmar la venta? (S/N): '

DECLARE
    v_tienda_id NUMBER;
    v_cliente_id NUMBER;
    v_productos_ids VARCHAR2(4000);
    v_cantidades VARCHAR2(4000);
    v_factura_num NUMBER;
    v_total_usd NUMBER;
    v_total_mostrar NUMBER;
    v_moneda VARCHAR2(3);
    v_mensaje VARCHAR2(1000);
    v_simbolo VARCHAR2(3);
BEGIN
    IF UPPER('&p_confirmar') != 'S' THEN
        DBMS_OUTPUT.PUT_LINE('Operación cancelada por el usuario.');
        RETURN;
    END IF;
    
    v_tienda_id := &p_tienda_id;
    v_cliente_id := &p_cliente_id;
    v_productos_ids := TRIM('&p_productos_ids');
    v_cantidades := TRIM('&p_cantidades');
    
    -- Limpiar espacios en blanco alrededor de las comas
    v_productos_ids := REGEXP_REPLACE(v_productos_ids, '\s*,\s*', ',');
    v_cantidades := REGEXP_REPLACE(v_cantidades, '\s*,\s*', ',');
    -- Eliminar comas finales si existen
    IF SUBSTR(v_productos_ids, -1) = ',' THEN
        v_productos_ids := SUBSTR(v_productos_ids, 1, LENGTH(v_productos_ids) - 1);
    END IF;
    IF SUBSTR(v_cantidades, -1) = ',' THEN
        v_cantidades := SUBSTR(v_cantidades, 1, LENGTH(v_cantidades) - 1);
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Procesando venta...');
    DBMS_OUTPUT.PUT_LINE('IDs de productos: [' || v_productos_ids || ']');
    DBMS_OUTPUT.PUT_LINE('Cantidades: [' || v_cantidades || ']');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Llamar al procedimiento principal
    sp_automatizar_venta_fisica(
        p_tienda_id => v_tienda_id,
        p_cliente_id => v_cliente_id,
        p_productos_ids => v_productos_ids,
        p_cantidades => v_cantidades,
        p_factura_num => v_factura_num,
        p_total_usd => v_total_usd,
        p_total_mostrar => v_total_mostrar,
        p_moneda => v_moneda,
        p_mensaje => v_mensaje
    );
    
    IF v_factura_num IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || v_mensaje);
        RETURN;
    END IF;
    
    v_simbolo := CASE WHEN v_moneda = 'EUR' THEN '€' ELSE '$' END;
    
    -- Mostrar resumen de la venta
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('VENTA COMPLETADA EXITOSAMENTE');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Número de factura: ' || v_factura_num);
    DBMS_OUTPUT.PUT_LINE('Cliente: ' || v_cliente_id);
    DBMS_OUTPUT.PUT_LINE('Tienda: ' || v_tienda_id);
    DBMS_OUTPUT.PUT_LINE('Total: ' || v_simbolo || v_total_mostrar || ' ' || v_moneda || 
                        ' (USD ' || v_total_usd || ')');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(v_mensaje);
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RAISE;
END;
/

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT Script completado.
PROMPT ═══════════════════════════════════════════════════════════════════════════

