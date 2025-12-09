-- ═══════════════════════════════════════════════════════════════════════════════
-- VISTAS PARA INSCRIPCIONES, TOURS Y ENTRADAS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Vista para inscripciones con información completa
CREATE OR REPLACE VIEW v_inscripciones_completa AS
SELECT 
    i.ins_num AS numero_inscripcion,
    i.ins_femision AS fecha_emision,
    i.ins_total AS total_pagado,
    i.ins_estado AS estado,
    i.ins_tour AS fecha_tour,
    t.to_cupos AS cupos_totales_tour,
    t.to_costo AS costo_unitario_tour,
    COUNT(DISTINCT di.det_ins_id) AS total_participantes,
    COUNT(DISTINCT CASE WHEN di.det_ins_tipo = 'ADULTO' THEN di.det_ins_id END) AS adultos,
    COUNT(DISTINCT CASE WHEN di.det_ins_tipo = 'MENOR' THEN di.det_ins_id END) AS menores,
    COUNT(DISTINCT e.ent_id) AS total_entradas_generadas,
    CASE 
        WHEN i.ins_estado = 'PAGO' THEN 'PAGADA'
        ELSE 'PENDIENTE PAGO'
    END AS estado_descripcion
FROM inscripciones i
LEFT JOIN tours t ON i.ins_tour = t.to_fini
LEFT JOIN det_inscrip di ON i.ins_num = di.det_ins_ins
LEFT JOIN entradas_tour e ON i.ins_num = e.ent_insc
GROUP BY 
    i.ins_num, 
    i.ins_femision, 
    i.ins_total, 
    i.ins_estado, 
    i.ins_tour,
    t.to_cupos,
    t.to_costo;

-- Vista para entradas con información del participante
CREATE OR REPLACE VIEW v_entradas_detalle AS
SELECT 
    e.ent_insc AS numero_inscripcion,
    e.ent_id AS numero_entrada,
    e.ent_tipo_asistente AS tipo_asistente,
    i.ins_tour AS fecha_tour,
    i.ins_estado AS estado_inscripcion,
    i.ins_femision AS fecha_emision_inscripcion,
    -- Información del participante (cliente o fan LEGO)
    CASE 
        WHEN e.ent_tipo_asistente = 'ADULTO' AND di.det_ins_cli IS NOT NULL THEN
            c.cli_pnombre || ' ' || c.cli_papellido || ' ' || c.cli_sapellido
        WHEN e.ent_tipo_asistente = 'MENOR' AND di.det_ins_fan IS NOT NULL THEN
            f.fl_pnombre || ' ' || f.fl_papellido || ' ' || f.fl_sapellido
        ELSE 'N/A'
    END AS nombre_participante,
    CASE 
        WHEN e.ent_tipo_asistente = 'ADULTO' AND di.det_ins_cli IS NOT NULL THEN
            c.cli_dni
        WHEN e.ent_tipo_asistente = 'MENOR' AND di.det_ins_fan IS NOT NULL THEN
            f.fl_dni
        ELSE NULL
    END AS dni_participante,
    CASE 
        WHEN e.ent_tipo_asistente = 'ADULTO' AND di.det_ins_cli IS NOT NULL THEN
            edad(c.cli_fnacimiento)
        WHEN e.ent_tipo_asistente = 'MENOR' AND di.det_ins_fan IS NOT NULL THEN
            edad(f.fl_fnacimiento)
        ELSE NULL
    END AS edad_participante
FROM entradas_tour e
JOIN inscripciones i ON e.ent_insc = i.ins_num
LEFT JOIN det_inscrip di ON e.ent_insc = di.det_ins_ins 
    AND e.ent_tipo_asistente = di.det_ins_tipo
    AND (
        (e.ent_tipo_asistente = 'ADULTO' AND di.det_ins_cli IS NOT NULL) OR
        (e.ent_tipo_asistente = 'MENOR' AND di.det_ins_fan IS NOT NULL)
    )
LEFT JOIN clientes c ON di.det_ins_cli = c.cli_id
LEFT JOIN f_lego f ON di.det_ins_fan = f.fl_id;

-- Verificar que las vistas se crearon correctamente
SELECT 
    view_name,
    text
FROM user_views
WHERE view_name IN ('V_INSCRIPCIONES_COMPLETA', 'V_ENTRADAS_DETALLE')
ORDER BY view_name;

-- 5. VISTA CONSOLIDADA DE TOURS

CREATE OR REPLACE VIEW v_tours_con_inscripciones AS
SELECT 
    t.to_fini AS fecha_tour,
    t.to_cupos AS cupos_totales,
    COUNT(DISTINCT i.ins_num) AS inscripciones_totales,
    COUNT(DISTINCT di.det_ins_id) AS participantes_confirmados,
    SUM(CASE WHEN i.ins_estado = 'PAGO' THEN i.ins_total ELSE 0 END) 
        AS ingresos_totales,
    COUNT(CASE WHEN i.ins_estado = 'PENDIENTE' THEN 1 END) 
        AS inscripciones_pendientes,
    COUNT(CASE WHEN i.ins_estado = 'PAGO' THEN 1 END) 
        AS inscripciones_pagadas,
    t.to_cupos - COUNT(DISTINCT di.det_ins_id) AS cupos_disponibles
FROM tours t
LEFT JOIN inscripciones i ON t.to_fini = i.ins_tour
LEFT JOIN det_inscrip di ON i.ins_num = di.det_ins_ins 
                          AND i.ins_estado = 'PAGO'
GROUP BY t.to_fini, t.to_cupos
ORDER BY t.to_fini DESC;