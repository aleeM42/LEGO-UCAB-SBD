-================================================================================
-- 5. ÍNDICES PARA OPTIMIZACIÓN
--================================================================================

-- Índices para búsquedas rápidas en tours
CREATE INDEX idx_inscripciones_tour ON inscripciones(ins_tour);
CREATE INDEX idx_inscripciones_estado ON inscripciones(ins_estado);
CREATE INDEX idx_inscripciones_fecha ON inscripciones(ins_femision);
CREATE INDEX idx_det_inscrip_insc ON det_inscrip(det_ins_ins);
CREATE INDEX idx_entradas_insc ON entradas_tour(ent_insc);
CREATE INDEX idx_auditoria_tours_insc ON auditoria_tours(aud_inscripcion_num);
CREATE INDEX idx_auditoria_tours_fecha ON auditoria_tours(aud_fecha);

