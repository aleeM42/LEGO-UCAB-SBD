-- ═══════════════════════════════════════════════════════════════════════════════
-- CORREGIR PROCEDIMIENTO INSERTAR_DETALLE_FISICA
-- Este script corrige la verificación de stock para considerar descuentos ya realizados
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE PROCEDURE INSERTAR_DETALLE_FISICA (
    p_ti_id IN NUMBER,
    p_fact_num IN NUMBER,
    p_pro_cod IN NUMBER,
    p_cantidad IN NUMBER,
    p_msg OUT VARCHAR2
)
AS
    v_lote_id NUMBER;
    v_stock_disp NUMBER;
    v_total_stock NUMBER;
    v_precio_unitario NUMBER;
    v_subtotal NUMBER;
    v_pro_raned VARCHAR2(8);
BEGIN
    -- Verificar stock disponible considerando descuentos ya realizados
    SELECT NVL(SUM(l.lot_stock - NVL(d.total_descontado, 0)), 0) INTO v_total_stock
    FROM lotes l
    LEFT JOIN (
        SELECT d_lote, d_prod, d_tienda, SUM(d_cantidad) AS total_descontado
        FROM descuentos
        GROUP BY d_lote, d_prod, d_tienda
    ) d ON l.lot_id = d.d_lote
        AND l.lot_prod = d.d_prod
        AND l.lot_tienda = d.d_tienda
    WHERE l.lot_tienda = p_ti_id AND l.lot_prod = p_pro_cod
      AND (l.lot_stock - NVL(d.total_descontado, 0)) > 0;
    
    IF v_total_stock < p_cantidad THEN
        RAISE_APPLICATION_ERROR(-20003, 'Stock Insuficiente en lotes para la cantidad requerida. Stock disponible: ' || v_total_stock);
    END IF;

    -- Seleccionar el lote con mayor stock disponible
    SELECT l.lot_id, (l.lot_stock - NVL(d.total_descontado, 0))
    INTO v_lote_id, v_stock_disp
    FROM lotes l
    LEFT JOIN (
        SELECT d_lote, d_prod, d_tienda, SUM(d_cantidad) AS total_descontado
        FROM descuentos
        GROUP BY d_lote, d_prod, d_tienda
    ) d ON l.lot_id = d.d_lote
        AND l.lot_prod = d.d_prod
        AND l.lot_tienda = d.d_tienda
    WHERE l.lot_tienda = p_ti_id
      AND l.lot_prod = p_pro_cod
      AND (l.lot_stock - NVL(d.total_descontado, 0)) > 0
    ORDER BY (l.lot_stock - NVL(d.total_descontado, 0)) DESC
    FETCH FIRST 1 ROW ONLY;

    SELECT hp_precio
    INTO v_precio_unitario
    FROM hist_precios
    WHERE hp_prod = p_pro_cod
      AND hp_ffin IS NULL;
      
    SELECT pro_raned
    INTO v_pro_raned
    FROM productos
    WHERE pro_cod = p_pro_cod;
    
    v_subtotal := p_cantidad * v_precio_unitario;

    INSERT INTO det_fact_t (
        det_ft_cantidad,
        det_ft_fact,
        det_ft_tienda_fact,
        det_ft_lote,
        det_ft_prod,
        det_ft_tienda_lote,
        det_ft_tipo_cli
    )
    VALUES (
        p_cantidad,
        p_fact_num,
        p_ti_id,
        v_lote_id,
        p_pro_cod,
        p_ti_id,
        v_pro_raned
    );

    INSERT INTO descuentos (
        d_lote,
        d_prod,
        d_tienda,
        d_fecha,
        d_cantidad
    )
    VALUES (
        v_lote_id,
        p_pro_cod,
        p_ti_id,
        SYSDATE,
        p_cantidad
    );

    UPDATE factura_tf
    SET fact_tf_total = fact_tf_total + v_subtotal
    WHERE fact_tf_tie = p_ti_id
      AND fact_tf_num = p_fact_num;
      
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'La factura ' || p_fact_num || ' en la tienda ' || p_ti_id || ' no existe.');
    END IF;
    
    p_msg := 'Exito. Detalle insertado. Lote: ' || v_lote_id || ' Subtotal: ' || v_subtotal;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: No se encontro un lote valido para el producto o no tiene precio activo.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_msg := 'Error al insertar detalle: ' || SQLERRM;
        ROLLBACK;
END;
/

-- Verificar que el procedimiento esté válido
SELECT 
    object_name,
    object_type,
    status
FROM user_objects
WHERE object_name = 'INSERTAR_DETALLE_FISICA';

-- Si hay errores, verlos con:
-- SELECT * FROM user_errors WHERE name = 'INSERTAR_DETALLE_FISICA';

