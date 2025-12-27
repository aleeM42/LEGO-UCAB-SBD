-- ═══════════════════════════════════════════════════════════════════════════════
-- SCRIPT INTERACTIVO PARA AUTOMATIZACIÓN DE VENTAS ONLINE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Este script guía al usuario a través del proceso completo de venta online
-- usando SQL Developer con comandos ACCEPT y PROMPT
-- ═══════════════════════════════════════════════════════════════════════════════

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT AUTOMATIZACIÓN DE VENTA ONLINE
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 1: CONSULTAR CLIENTE Y OBTENER PAÍS
-- ═══════════════════════════════════════════════════════════════════════════════

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT DATOS DEL CLIENTE
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

ACCEPT p_cliente_id NUMBER PROMPT 'Ingrese el ID del cliente: '

DECLARE
    v_cli_id NUMBER;
    v_nombre_completo VARCHAR2(200);
    v_dni NUMBER;
    v_pais_id NUMBER;
    v_pais_nombre VARCHAR2(30);
    v_pertenece_ue VARCHAR2(2);
    v_moneda VARCHAR2(3);
BEGIN
    SELECT 
        c.cli_id,
        c.cli_pnombre || ' ' || NVL(c.cli_snombre || ' ', '') || 
        c.cli_papellido || ' ' || c.cli_sapellido,
        c.cli_dni,
        c.cli_reside,
        p.p_nom,
        p.p_ue
    INTO 
        v_cli_id,
        v_nombre_completo,
        v_dni,
        v_pais_id,
        v_pais_nombre,
        v_pertenece_ue
    FROM clientes c
    LEFT JOIN paises p ON c.cli_reside = p.p_id
    WHERE c.cli_id = &p_cliente_id;
    
    v_moneda := CASE WHEN v_pertenece_ue = 'SI' THEN 'EUR' ELSE 'USD' END;
    
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_cli_id);
    DBMS_OUTPUT.PUT_LINE('Nombre: ' || v_nombre_completo);
    DBMS_OUTPUT.PUT_LINE('DNI: ' || v_dni);
    DBMS_OUTPUT.PUT_LINE('País de residencia: ' || v_pais_nombre || ' (UE: ' || v_pertenece_ue || ')');
    DBMS_OUTPUT.PUT_LINE('Moneda: ' || v_moneda);
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Cliente no encontrado.');
        RAISE_APPLICATION_ERROR(-22000, 'Cliente no encontrado: ' || &p_cliente_id);
END;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 2: MOSTRAR CATÁLOGO DISPONIBLE POR PAÍS
-- ═══════════════════════════════════════════════════════════════════════════════

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT CATÁLOGO DISPONIBLE PARA EL PAÍS DEL CLIENTE
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

DECLARE
    v_pais_id NUMBER;
    v_cursor_catalogo SYS_REFCURSOR;
    v_pro_cod NUMBER;
    v_pro_nom VARCHAR2(50);
    v_pro_desc VARCHAR2(800);
    v_pro_raned VARCHAR2(8);
    v_pro_ranpr VARCHAR2(4);
    v_precio_usd NUMBER;
    v_precio_mostrar NUMBER;
    v_moneda VARCHAR2(3);
    v_limite_compra NUMBER;
    v_simbolo VARCHAR2(3);
BEGIN
    -- Obtener país del cliente
    SELECT cli_reside
    INTO v_pais_id
    FROM clientes
    WHERE cli_id = &p_cliente_id;
    
    sp_consultar_catalogo_online(
        p_pais_id => v_pais_id,
        p_cursor_catalogo => v_cursor_catalogo
    );
    
    v_simbolo := 'USD';
    
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('PRODUCTOS DISPONIBLES EN EL CATÁLOGO');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('');
    
    LOOP
        FETCH v_cursor_catalogo INTO
            v_pro_cod, v_pro_nom, v_pro_desc, v_pro_raned, v_pro_ranpr,
            v_precio_usd, v_precio_mostrar, v_moneda, v_limite_compra;
        EXIT WHEN v_cursor_catalogo%NOTFOUND;
        
        IF v_moneda = 'EUR' THEN
            v_simbolo := 'EUR';
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_pro_cod || ' | ' || v_pro_nom);
        DBMS_OUTPUT.PUT_LINE('  Descripción: ' || SUBSTR(v_pro_desc, 1, 50) || '...');
        DBMS_OUTPUT.PUT_LINE('  Precio: ' || v_simbolo || ' ' || v_precio_mostrar || 
                           ' (USD ' || v_precio_usd || ')');
        DBMS_OUTPUT.PUT_LINE('  Límite de compra: ' || v_limite_compra || ' unidades');
        DBMS_OUTPUT.PUT_LINE('  Rango edad: ' || v_pro_raned || ' | Rango precio: ' || v_pro_ranpr);
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    -- Verificar si se encontraron productos antes de cerrar el cursor
    IF v_cursor_catalogo%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No hay productos disponibles en el catálogo para este país.');
    END IF;
    
    CLOSE v_cursor_catalogo;
    
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
-- PASO 3: AGREGAR PRODUCTOS A LA FACTURA
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
PROMPT - Las cantidades no pueden exceder el límite de compra del catálogo
PROMPT - Ejemplo: IDs: 123,45,67  Cantidades: 2,1,3
PROMPT 

ACCEPT p_productos_ids CHAR PROMPT 'IDs de productos (separados por comas): '
ACCEPT p_cantidades CHAR PROMPT 'Cantidades (separados por comas): '

-- ═══════════════════════════════════════════════════════════════════════════════
-- PASO 4: CONFIRMAR Y PROCESAR VENTA
-- ═══════════════════════════════════════════════════════════════════════════════

PROMPT 
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT CONFIRMAR VENTA
PROMPT ═══════════════════════════════════════════════════════════════════════════
PROMPT 

ACCEPT p_confirmar CHAR PROMPT '¿Desea confirmar la venta? (S/N): '

DECLARE
    v_cliente_id NUMBER;
    v_productos_ids VARCHAR2(4000);
    v_cantidades VARCHAR2(4000);
    v_factura_num NUMBER;
    v_total_usd NUMBER;
    v_total_mostrar NUMBER;
    v_moneda VARCHAR2(3);
    v_puntos_generados NUMBER;
    v_puntos_acumulados NUMBER;
    v_costo_envio NUMBER;
    v_recargo_envio NUMBER;
    v_mensaje VARCHAR2(1000);
    v_simbolo VARCHAR2(3);
    v_total_final NUMBER;
BEGIN
    IF UPPER('&p_confirmar') != 'S' THEN
        DBMS_OUTPUT.PUT_LINE('Operación cancelada por el usuario.');
        RETURN;
    END IF;
    
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
    
    DBMS_OUTPUT.PUT_LINE('Procesando venta online...');
    DBMS_OUTPUT.PUT_LINE('IDs de productos: [' || v_productos_ids || ']');
    DBMS_OUTPUT.PUT_LINE('Cantidades: [' || v_cantidades || ']');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Llamar al procedimiento principal
    sp_automatizar_venta_online(
        p_cliente_id => v_cliente_id,
        p_productos_ids => v_productos_ids,
        p_cantidades => v_cantidades,
        p_factura_num => v_factura_num,
        p_total_usd => v_total_usd,
        p_total_mostrar => v_total_mostrar,
        p_moneda => v_moneda,
        p_puntos_generados => v_puntos_generados,
        p_puntos_acumulados => v_puntos_acumulados,
        p_costo_envio => v_costo_envio,
        p_recargo_envio => v_recargo_envio,
        p_mensaje => v_mensaje
    );
    
    IF v_factura_num IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || v_mensaje);
        RETURN;
    END IF;
    
    v_simbolo := CASE WHEN v_moneda = 'EUR' THEN '€' ELSE '$' END;
    v_total_final := v_total_mostrar + v_costo_envio + v_recargo_envio;
    
    -- Mostrar resumen de la venta
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('VENTA ONLINE COMPLETADA EXITOSAMENTE');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Número de factura: ' || v_factura_num);
    DBMS_OUTPUT.PUT_LINE('Cliente: ' || v_cliente_id);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('DETALLE DE COSTOS');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Subtotal productos: ' || v_simbolo || v_total_mostrar || ' ' || v_moneda || 
                        ' (USD ' || v_total_usd || ')');
    DBMS_OUTPUT.PUT_LINE('Costo de envío: ' || v_simbolo || v_costo_envio);
    DBMS_OUTPUT.PUT_LINE('Recargo por envío: ' || v_simbolo || v_recargo_envio);
    DBMS_OUTPUT.PUT_LINE('───────────────────────────────────────────────────────────────────────────');
    DBMS_OUTPUT.PUT_LINE('TOTAL A PAGAR: ' || v_simbolo || v_total_final || ' ' || v_moneda);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('PUNTOS DE LEALTAD');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Puntos generados en esta compra: ' || v_puntos_generados);
    DBMS_OUTPUT.PUT_LINE('Puntos acumulados totales: ' || v_puntos_acumulados);
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

