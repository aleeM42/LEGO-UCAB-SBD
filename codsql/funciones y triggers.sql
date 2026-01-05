--------------------------------------------------------------------
--------------------------- FUNCIONES ------------------------------
--------------------------------------------------------------------

------------- FUNCIONES GENERALES—----------------------------------
--funcion para calcular la edad
create or replace function edad (fecha_nacimiento date) 
RETURN number is 
BEGIN
    return trunc((months_between(sysdate, fecha_nacimiento) /12));
end;
/

-- funcion para verificar si pertenece a la UE
create or replace function es_ue(p_pais_id number) 
return varchar2 is
    v_ue paises.p_ue%TYPE;
BEGIN
    select p_ue
    into v_ue 
    from paises where p_id = p_pais_id;
    return v_ue;
end;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- FUNCIONES PARA CALCULAR TOTALES DE FACTURAS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Función para calcular el total de una factura física
CREATE OR REPLACE FUNCTION fn_calcular_total_factura_fisica(
    p_fact_num IN NUMBER,
    p_tienda_id IN NUMBER
) RETURN NUMBER
IS
    v_total NUMBER := 0;
    v_count NUMBER := 0;
    v_count_con_precio NUMBER := 0;
BEGIN
    -- Primero verificar que existan detalles
    SELECT COUNT(*)
    INTO v_count
    FROM det_fact_t dt
    WHERE dt.det_ft_fact = p_fact_num
      AND dt.det_ft_tienda_fact = p_tienda_id;
    
    IF v_count = 0 THEN
        RETURN 0;
    END IF;
    
    -- Verificar cuántos detalles tienen precio activo
    SELECT COUNT(*)
    INTO v_count_con_precio
    FROM det_fact_t dt
    JOIN hist_precios hp ON dt.det_ft_prod = hp.hp_prod 
                        AND hp.hp_ffin IS NULL
    WHERE dt.det_ft_fact = p_fact_num
      AND dt.det_ft_tienda_fact = p_tienda_id;
    
    -- Si hay detalles pero ninguno tiene precio, retornar 0
    IF v_count > 0 AND v_count_con_precio = 0 THEN
        RETURN 0;
    END IF;
    
    -- Calcular el total sumando cantidad * precio
    SELECT NVL(SUM(dt.det_ft_cantidad * hp.hp_precio), 0)
    INTO v_total
    FROM det_fact_t dt
    INNER JOIN hist_precios hp ON dt.det_ft_prod = hp.hp_prod 
                               AND hp.hp_ffin IS NULL
    WHERE dt.det_ft_fact = p_fact_num
      AND dt.det_ft_tienda_fact = p_tienda_id;
    
    RETURN NVL(v_total, 0);
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, retornar 0 pero registrar el error
        RETURN 0;
END fn_calcular_total_factura_fisica;
/

-- Función para calcular el total de una factura online
CREATE OR REPLACE FUNCTION fn_calcular_total_factura_online(
    p_fact_num IN NUMBER
) RETURN NUMBER
IS
    v_total NUMBER := 0;
    v_count NUMBER := 0;
BEGIN
    -- Primero verificar que existan detalles
    SELECT COUNT(*)
    INTO v_count
    FROM det_fact_o
    WHERE det_fo_fact = p_fact_num;
    
    IF v_count = 0 THEN
        RETURN 0;
    END IF;
    
    -- Calcular el total sumando cantidad * precio
    -- Usar LEFT JOIN para incluir detalles aunque no tengan precio activo
    SELECT NVL(SUM(df.det_fo_cantidad * NVL(hp.hp_precio, 0)), 0)
    INTO v_total
    FROM det_fact_o df
    LEFT JOIN hist_precios hp ON df.det_fo_prod = hp.hp_prod 
                              AND hp.hp_ffin IS NULL
    WHERE df.det_fo_fact = p_fact_num;

    RETURN NVL(v_total, 0);
EXCEPTION
    WHEN OTHERS THEN
        -- En caso de error, retornar 0 pero registrar el error
        RETURN 0;
END fn_calcular_total_factura_online;
/


-----------------------------------------------------------
------------------------- TOUR ----------------------------
-----------------------------------------------------------

---funcion para validar periodo de inscripcion 
-- Modificada para permitir inscripciones en cualquier fecha (incluyendo tours pasados)
create or replace function fn_inscripcion_abierta(p_tour_fecha date)
return boolean is 
begin
    -- Siempre permitir inscripciones, sin validar fechas límite
    -- Esto permite inscribirse en tours pasados, presentes y futuros
    RETURN TRUE;
end;
/

--funcion para validar disponibilidad del tour (fecha valida con cupos)
CREATE OR REPLACE FUNCTION fn_tour_disponible(p_tour_fecha IN DATE) 
RETURN BOOLEAN IS
    v_tour_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_tour_existe
    FROM tours
    WHERE to_fini = p_tour_fecha;
    
    -- Solo validar que el tour existe, sin importar la fecha
    RETURN (v_tour_existe > 0);
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20809, 'Error validando disponibilidad tour: ' || SQLERRM);
END fn_tour_disponible;
/


-- Función para validar si tour tiene cupos disponibles
-- Modificada para permitir inscripciones en tours pasados sin validar cupos
CREATE OR REPLACE FUNCTION fn_validar_cupos_tour(
    p_tour_fecha IN DATE,
    p_cantidad_solicitada IN NUMBER
) RETURN BOOLEAN
IS
    v_cupos_disponibles NUMBER;
    v_cupos_totales NUMBER;
    v_inscritos NUMBER;
BEGIN
    -- Para tours pasados, permitir inscripción sin validar cupos
    IF p_tour_fecha < TRUNC(SYSDATE) THEN
        RETURN TRUE;
    END IF;
    
    -- Para tours futuros o presentes, validar cupos
    -- Obtener cupos totales del tour
    SELECT to_cupos INTO v_cupos_totales
    FROM tours
    WHERE to_fini = p_tour_fecha;
    
    -- Contar inscritos en el tour (solo los pagados)
    SELECT COUNT(*) INTO v_inscritos
    FROM det_inscrip di
    JOIN inscripciones i ON di.det_ins_ins = i.ins_num
    WHERE i.ins_tour = p_tour_fecha
      AND i.ins_estado = 'PAGO';
    
    v_cupos_disponibles := v_cupos_totales - v_inscritos;
    
    RETURN (v_cupos_disponibles >= p_cantidad_solicitada);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20802, 'Tour no encontrado: ' || p_tour_fecha);
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20803, 'Error validando cupos: ' || SQLERRM);
END fn_validar_cupos_tour;
/

--------------------------- FUNCIONES FACTURACION --------------------------------------
-- funcion para obtener el numero del dia dado el nombre del dia
CREATE OR REPLACE FUNCTION OBTENER_NUMERO_DIA (
    p_nombre_dia IN VARCHAR2
)
RETURN NUMBER
IS
    v_dia_numerico NUMBER;
BEGIN
    CASE UPPER(p_nombre_dia)
        WHEN 'DOMINGO' THEN
            v_dia_numerico := 1;
        WHEN 'LUNES' THEN
            v_dia_numerico := 2;
        WHEN 'MARTES' THEN
            v_dia_numerico := 3;
        WHEN 'MIÉRCOLES' THEN
            v_dia_numerico := 4;
        WHEN 'JUEVES' THEN
            v_dia_numerico := 5;
        WHEN 'VIERNES' THEN
            v_dia_numerico := 6;
        WHEN 'SÁBADO' THEN
            v_dia_numerico := 7; 
        ELSE
            v_dia_numerico := NULL;
    END CASE;

    RETURN v_dia_numerico;
END OBTENER_NUMERO_DIA;
/

-- funcion para obtener el rango de precio
CREATE OR REPLACE FUNCTION obtener_letra_precio (
    p_rango_precio IN VARCHAR2
)
RETURN VARCHAR2
IS
    v_letra_precio VARCHAR2(4); 
BEGIN
    CASE UPPER(TRIM(p_rango_precio))
        WHEN '10-' THEN
            v_letra_precio := 'A';
        WHEN '10-70' THEN
            v_letra_precio := 'B';
        WHEN '70-200' THEN
            v_letra_precio := 'C';
        WHEN '200+' THEN
            v_letra_precio := 'D';
        ELSE
            v_letra_precio := 'X'; 
    END CASE;

    RETURN v_letra_precio;
END obtener_letra_precio;
/

------------------------------------------------------------------------------------------
------------------------------------- TRIGGERS ------------------------------------
------------------------------------------------------------------------------------------

------------------------- TRIGGER TOUR ---------------------------------------------------
--trigger para validar la edad del fan de legp y clientes en el detalle de la inscripcion
CREATE OR REPLACE TRIGGER tr_validar_edad_inscripcion_tour
BEFORE INSERT ON det_inscrip
FOR EACH ROW
DECLARE
    v_fecha_nac DATE;
    v_edad NUMBER;
BEGIN
    
    -- Si es cliente
    IF :new.det_ins_cli IS NOT NULL THEN
        SELECT cli_fnacimiento
        INTO v_fecha_nac
        FROM clientes
        WHERE cli_id = :new.det_ins_cli;
        
        v_edad := edad(v_fecha_nac);
        
        IF v_edad < 12 THEN
            RAISE_APPLICATION_ERROR(
                -20020,
                'Cliente ID ' || :new.det_ins_cli || 
                ' no cumple edad mínima (12 años). Edad actual: ' || v_edad || '.'
            );
        END IF;
    
    -- Si es fan LEGO
    ELSIF :new.det_ins_fan IS NOT NULL THEN
        SELECT fl_fnacimiento
        INTO v_fecha_nac
        FROM f_lego
        WHERE fl_id = :new.det_ins_fan;
        
        v_edad := edad(v_fecha_nac);
        
        IF v_edad < 12 OR v_edad > 17 THEN
            RAISE_APPLICATION_ERROR(
                -20020,
                'Fan LEGO ID ' || :new.det_ins_fan || 
                ' está fuera del rango permitido (12-17 años). Edad actual: ' || v_edad || '.'
            );
        END IF;
    END IF;
END tr_validar_edad_inscripcion_tour;
/

----triger para validar que fan tiene representante en la inscripcion 
create or replace trigger trg_validar_representante_en_inscripcion
before insert or update on det_inscrip 
for each row 
declare
    v_repre_id number;
    v_repre_ins number; 
begin
    if :new.det_ins_fan is not null then 
        select fl_repre into v_repre_id 
        from f_lego where fl_id = :new.det_ins_fan;

        if v_repre_id is null then 
            raise_application_error(-20021, 'Fan lego sin representante asignado, no puede ser inscrito');
        end if;

        --- esto solo verifica si el representante ya esta, (si no esta lo valida el procedimiento pprincipal)
        --- este trigger solo adiverte si no esta 
        select count (*) into v_repre_ins    
        from det_inscrip where det_ins_ins = :new.det_ins_ins 
        and det_ins_cli = v_repre_id;

        --- no es error si no esta, se registra para la auditoria 
    end if;
end;
/

--triggers para validar participantes
create or replace trigger tr_validar_participante 
before insert on det_inscrip
for each row
BEGIN
    if (:new.det_ins_fan is null and :new.det_ins_cli is null) then 
        raise_application_error(-20941, 'Participante debe ser cliente o fan lego menor');
    end if;

    --validar edad para menores 
    if :new.det_ins_tipo = 'MENOR' then 
        if :new.det_ins_fan is null then 
            raise_application_error(-20942, 'Menores deben ser registrados como fan lego');
        end if;

        --validar edad 12-20 anos
        if not validar_edad_fan_lego(:new.det_ins_fan) then
            raise_application_error(-20943, 'Menor debe tener entre 12 y 20 años');
        end if;
    end if;

    if :new.det_ins_tipo = 'ADULTO' then
        if :new.det_ins_cli is null then 
            raise_application_error(-20944, 'Adulto debe ser cliente registrado');
        end if;
    end if;     
end;
/
--trigger para prevenir eliminación de inscripción pagada 
create or replace trigger tr_proteger_inscripcion_pagada 
before delete on inscripciones 
for each row 
begin
    if :old.ins_estado = 'PAGO' then 
        raise_application_error(-20946, 'No se pueden eliminar inscripciones pagadas');
    end if;
end;
/

--trigger para auditar cambios de estado de inscripcion 
create or replace trigger tr_auditoria_inscripcion
after update on inscripciones
for each row 
begin
    if :new.ins_estado <> :old.ins_estado then 
        insert into auditoria_tours(aud_fecha, aud_inscripcion_num, aud_tipo_evento, aud_descripcion)
        values (sysdate, :new.ins_num, 'CAMBIO_ESTADO', 'Estado cambió de ' || :old.ins_estado || 'a ' || :new.ins_estado);
    end if;
end;
/

--trigger para validar que tour existe 
create or replace trigger tr_validar_tour_existe 
before insert on inscripciones 
for each row
declare
    v_tour_existe number;
begin
    select count(*) into v_tour_existe
    from tours where to_fini = :new.ins_tour;
    
    if v_tour_existe = 0 then 
        raise_application_error(-20947, 'Tour no existe en esa fecha');
    end if;
end;
/

--trigger para asignar id a auditoria 
create or replace trigger tr_auditoria_tours_id
before insert on auditoria_tours
for each row
begin
    if :new.aud_id is null then 
        select auditoria_tours_seq.nextval into :new.aud_id from dual;
    end if;
end;
/


--trigger para la edad de los clientes 
create or replace trigger verificar_edad_Cliente 
before insert or update on clientes 
for each row 
declare 
    v_edad number;
begin
    v_edad := trunc(months_between(sysdate, :new.cli_fnacimiento)/12);
    if v_edad < 21 then
        raise_application_error(-20006, 'El cliente debe ser mayor a 21 anos');
    end if;
end;
/

--trigger para la edad de los fans de lego
create or replace trigger verificar_edad_fl
before insert or update on f_lego 
for each row 
declare 
    v_edad number;
begin
    v_edad := trunc(months_between(sysdate, :new.fl_fnacimiento)/12);

    if v_edad < 12 or v_edad > 20 then 
        raise_application_error(-20007, 'Fan lego debe tener entre 12 y 20 anos');
    end if;
end;
/

--triggers para la nac de los clientes 
create or replace trigger nac_clientes
before insert or update  on clientes 
for each ROW
    declare v_ue varchar2(2);
begin
    v_ue := es_ue(:new.cli_nac);  

    if v_ue = 'NO' then 
        if :new.cli_numpas is null or :new.cli_fvenpas is null then
            raise_application_error (-2000, 'Si no pertenece a la Union europea debe indicar los datos de pasaporte');
        end if;
    end if;
end;
/

--trigger para nacionalidad de los f_lego
create or replace trigger nac_fan_lego
before insert on f_lego 
for each ROW 
    declare
    v_ue varchar2(2);
BEGIN
    v_ue := es_ue(:new.fl_nac);

    if v_ue = 'NO' THEN
        if :new.fl_numpas is null or :new.fl_fvenpas is null THEN
            raise_application_error(-20003, 'Si el cliente no pertenece a la EU debe ingresar los datos del pasaporte'); 
        end if;
    end if;    
end;
/

--trigger para solicitar los datos del representante 
create or replace trigger datos_representante 
before insert or update on f_lego
for each row 
begin
    if edad(:new.fl_fnacimiento) BETWEEN 12 and 17 THEN
        if :new.fl_repre is null then
            raise_application_error(-20005, 'Los fans de 12 a 17 anios deben tener un representante');
        end if;    
    end if;
end;
/

------------------------------------------------------------------------------
--------------------- TRIGGERS FACTURACION -----------------------------------
------------------------------------------------------------------------------

--trigger para no eliminar facturas online
create or replace trigger no_eliminar_fact_o
before delete on factura_o
begin  
    raise_application_error(-20002, 'Las facturas online no pueden eliminarse');
end;        
/

--trigger para no eliminar detalle facturas online
CREATE OR REPLACE TRIGGER trg_det_fact_o_no_delete
BEFORE DELETE ON det_fact_o
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20003, 'No se permite la eliminación de registros en la tabla det_fact_o.');
END;
/

--trigger para no actualizar detalle facturas online
CREATE OR REPLACE TRIGGER trg_det_fact_o_no_update
BEFORE UPDATE ON det_fact_o
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20004, 'No se permite la actualización de registros en la tabla det_fact_o.');
END;
/

--trigger para no eliminar facturas de tienda
create or replace trigger no_eliminar_fact_t
before delete on factura_tf
begin
    raise_application_error(-20002, 'Las facturas de tienda no pueden eliminarse');
end;
/

--trigger para no actualizar detalle facturas de tienda fisica
CREATE OR REPLACE TRIGGER tr_det_fact_t_no_update
BEFORE UPDATE ON det_fact_t
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20007, 'No se permite actualizar registros en la tabla DET_FACT_T.');
END;
/

--trigger para no eliminar detalle facturas de tienda fisica
CREATE OR REPLACE TRIGGER tr_det_fact_t_no_delete
BEFORE DELETE ON det_fact_t
FOR EACH ROW
    BEGIN
    RAISE_APPLICATION_ERROR(-20008, 'No se permite eliminar registros en la tabla DET_FACT_T.');
END;
/

CREATE OR REPLACE TRIGGER tr_descuentos_no_update
BEFORE UPDATE ON descuentos
FOR EACH ROW
        BEGIN
    RAISE_APPLICATION_ERROR(-20009, 'No se permite actualizar registros en la tabla DESCUENTOS.');
        END;
/

CREATE OR REPLACE TRIGGER tr_descuentos_no_delete
BEFORE DELETE ON descuentos
FOR EACH ROW
        BEGIN
    RAISE_APPLICATION_ERROR(-20010, 'No se permite eliminar registros en la tabla DESCUENTOS.');
END;
/

CREATE OR REPLACE TRIGGER TRG_PRODUCTO_RELACIONADO
FOR INSERT ON PRODUCTOS
COMPOUND TRIGGER

    TYPE t_prods_reco IS RECORD (
        pro_cod     PRODUCTOS.pro_cod%TYPE,
        pro_idtem PRODUCTOS.pro_idtem%TYPE
    );
    TYPE tt_prods_reco IS TABLE OF t_prods_reco INDEX BY PLS_INTEGER;
    
    g_prods_insertados tt_prods_reco; 

    AFTER EACH ROW IS
        BEGIN
        g_prods_insertados(g_prods_insertados.COUNT + 1).pro_cod := :NEW.pro_cod;
        g_prods_insertados(g_prods_insertados.COUNT).pro_idtem := :NEW.pro_idtem;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        CURSOR c_productos_existentes (p_idtem IN NUMBER) IS
             SELECT
                 pro_cod,
                 pro_idtem
             FROM
                 productos
             WHERE
                 pro_idtem = p_idtem;
                
        v_idx PLS_INTEGER;
        
BEGIN
        v_idx := g_prods_insertados.FIRST;
        
        IF v_idx IS NOT NULL THEN
            WHILE v_idx IS NOT NULL LOOP
                
                FOR r_existente IN c_productos_existentes(g_prods_insertados(v_idx).pro_idtem) LOOP
                
                    IF r_existente.pro_cod != g_prods_insertados(v_idx).pro_cod THEN
                        INSERT INTO PROD_RELA (
                            rela_prod_cod, rela_prod_idtem, rela_setcod, rela_idtem
    )
    VALUES (
                            g_prods_insertados(v_idx).pro_cod,
                            g_prods_insertados(v_idx).pro_idtem,
                            r_existente.pro_cod,
                            r_existente.pro_idtem
                        );
        
                        INSERT INTO PROD_RELA (
                            rela_prod_cod, rela_prod_idtem, rela_setcod, rela_idtem
                        )
                        VALUES (
                            r_existente.pro_cod,
                            r_existente.pro_idtem,
                            g_prods_insertados(v_idx).pro_cod,
                            g_prods_insertados(v_idx).pro_idtem
                        );
                        
    END IF;
    END LOOP;
    
                v_idx := g_prods_insertados.NEXT(v_idx);
            END LOOP;
    END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;

    END AFTER STATEMENT;

END TRG_PRODUCTO_RELACIONADO;
/



-------------------------------------------------------------------------------------------
------------------------------------- PROCEDIMIENTOS --------------------------------------
-------------------------------------------------------------------------------------------
-- Procedimiento para confirmar pago y emitir recibo y entradas
CREATE OR REPLACE PROCEDURE sp_confirmar_pago_inscripcion(
    p_numero_inscripcion IN NUMBER,
    p_moneda_pago IN VARCHAR2,  -- 'DKK', 'EUR', 'USD'
    p_monto_pagado IN NUMBER,
    p_referencia_pago IN VARCHAR2,
    p_recibo_generado OUT VARCHAR2,
    p_entradas_generadas OUT NUMBER,
    p_mensaje OUT VARCHAR2
)
IS
    v_inscripcion_existe NUMBER;
    v_estado_actual VARCHAR2(20);
    v_costo_inscripcion NUMBER;
    v_factor_conversion NUMBER;
    v_monto_esperado NUMBER;
    v_tour_fecha DATE;
    v_total_participantes NUMBER;
BEGIN
    SAVEPOINT sp_pago_inicio;
    
    -- 1. VALIDAR INSCRIPCIÓN EXISTE
    SELECT COUNT(*) INTO v_inscripcion_existe
    FROM inscripciones
    WHERE ins_num = p_numero_inscripcion;
    
    IF v_inscripcion_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20921, 
            'Inscripción no encontrada: ' || p_numero_inscripcion);
    END IF;
    
    -- 2. VALIDAR ESTADO = PENDIENTE
    SELECT ins_estado, ins_total, ins_tour
    INTO v_estado_actual, v_costo_inscripcion, v_tour_fecha
    FROM inscripciones
    WHERE ins_num = p_numero_inscripcion;
    
    IF v_estado_actual = 'PAGO' THEN
        RAISE_APPLICATION_ERROR(-20922, 
            'Inscripción ya fue pagada');
    END IF;
    
    -- 3. VALIDAR MONTO PAGADO (con conversión de moneda)
    -- El costo en BD está en USD, convertir a la moneda del pago
    -- Tasas de conversión: 1 USD = 0.88 EUR, 1 USD = 6.57 DKK (3500 USD = 23000 DKK)
    CASE p_moneda_pago
        WHEN 'USD' THEN 
            v_monto_esperado := v_costo_inscripcion;  -- Ya está en USD
        WHEN 'EUR' THEN 
            v_monto_esperado := v_costo_inscripcion * 0.8797;  -- 1 USD = 0.8797 EUR (3500 USD = 3081 EUR)
        WHEN 'DKK' THEN 
            v_monto_esperado := v_costo_inscripcion * (23000 / 3500);  -- 1 USD = 6.5714 DKK (3500 USD = 23000 DKK)
        ELSE 
            RAISE_APPLICATION_ERROR(-20923, 'Moneda no válida: ' || p_moneda_pago);
    END CASE;
    
    -- Permitir pequeña variación (1%)
    IF ABS(p_monto_pagado - v_monto_esperado) > (v_monto_esperado * 0.01) THEN
        RAISE_APPLICATION_ERROR(-20924, 
            'Monto pagado no coincide. Esperado: ' || ROUND(v_monto_esperado, 2) || 
            ' ' || p_moneda_pago || ', Recibido: ' || ROUND(p_monto_pagado, 2));
    END IF;
    
    -- 4. ACTUALIZAR ESTADO A PAGO
    UPDATE inscripciones
    SET ins_estado = 'PAGO'
    WHERE ins_num = p_numero_inscripcion;
    
    -- Verificar que se actualizó correctamente
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20925, 
            'No se pudo actualizar el estado de la inscripción ' || p_numero_inscripcion);
    END IF;
    
    -- 5. GENERAR RECIBO
    p_recibo_generado := 'RECIBO-' || LPAD(p_numero_inscripcion, 6, '0') || 
                        '-' || TO_CHAR(SYSDATE, 'YYYY-MM-DD');
    
    -- 6. GENERAR ENTRADAS
    SELECT COUNT(*) INTO p_entradas_generadas
    FROM entradas_tour
    WHERE ent_insc = p_numero_inscripcion;
    
    -- 7. REGISTRAR AUDITORÍA
    INSERT INTO auditoria_tours (
        aud_fecha, aud_inscripcion_num, aud_tipo_evento, aud_descripcion
    ) VALUES (
        SYSDATE, p_numero_inscripcion, 'PAGO_CONFIRMADO',
        'Pago confirmado. Ref: ' || p_referencia_pago || 
        ' Moneda: ' || p_moneda_pago || ' Monto: ' || p_monto_pagado
    );
    
    p_mensaje := 'Pago confirmado exitosamente. ' ||
                 'Recibo: ' || p_recibo_generado ||
                 ' | Entradas generadas: ' || p_entradas_generadas;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_pago_inicio;
        p_recibo_generado := NULL;
        p_entradas_generadas := 0;
        p_mensaje := 'Error: ' || SQLERRM;
END sp_confirmar_pago_inscripcion;
/

------------------------------------------------------------------------------------------
------------------- PROCEDIMIENTOS TIENDA—----------------------------
------------------------------------------------------------------------------------------

-- procedimiento para insertar productos en el inventario
CREATE OR REPLACE PROCEDURE INSERTAR_LOTE_PRODUCTO (
    p_nombre_producto IN VARCHAR2,
    p_tienda_id IN NUMBER,
    p_stock IN NUMBER
)
IS
    v_pro_cod PRODUCTOS.pro_cod%TYPE;

    e_producto_no_encontrado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_producto_no_encontrado, -20001);
    BEGIN
    BEGIN
    SELECT 
            pro_cod
        INTO
            v_pro_cod
        FROM
            productos
        WHERE
            UPPER(pro_nom) = UPPER(p_nombre_producto);
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_producto_no_encontrado;
    END;

    INSERT INTO lotes (
        lot_prod,
        lot_tienda,
        lot_stock
    )
    VALUES (
        v_pro_cod,
        p_tienda_id,
        p_stock
    );

    COMMIT;

EXCEPTION
    WHEN e_producto_no_encontrado THEN
        RAISE_APPLICATION_ERROR(-20001, 'ERROR: El producto con nombre "' || p_nombre_producto || '" no fue encontrado.');
        WHEN OTHERS THEN
        ROLLBACK;
            RAISE;

END INSERTAR_LOTE_PRODUCTO;
/

-- procedimiento para actualizar el historico del precio
CREATE OR REPLACE PROCEDURE actualizar_precio_producto (
    p_nombre_producto IN VARCHAR2,
    p_nuevo_precio    IN NUMBER
)
AS
    v_pro_cod         productos.pro_cod%TYPE;
    v_precio_actual   hist_precios.hp_precio%TYPE := NULL;
    v_fecha_actual    DATE := TRUNC(SYSDATE);
    
    e_producto_no_encontrado EXCEPTION;

BEGIN
    
    BEGIN
        SELECT pro_cod
        INTO v_pro_cod
        FROM productos
        WHERE pro_nom = p_nombre_producto;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_producto_no_encontrado;
    END;

        BEGIN
        SELECT hp_precio
        INTO v_precio_actual
        FROM hist_precios
        WHERE hp_prod = v_pro_cod
          AND hp_ffin IS NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_precio_actual := NULL;  
    END;

    IF v_precio_actual IS NULL THEN
        
        DBMS_OUTPUT.PUT_LINE('No existe historial de precios. Insertando primer registro.');
        
        INSERT INTO hist_precios (
            hp_prod,
            hp_fini,
            hp_precio,
            hp_ffin
        )
        VALUES (
            v_pro_cod,
            v_fecha_actual,
            p_nuevo_precio,
            NULL
        );
        
    ELSIF p_nuevo_precio <> v_precio_actual THEN 
        
        UPDATE hist_precios
        SET hp_ffin = v_fecha_actual - 1
        WHERE hp_prod = v_pro_cod
          AND hp_ffin IS NULL;

        INSERT INTO hist_precios (
            hp_prod,
            hp_fini,
            hp_precio,
            hp_ffin
        )
        VALUES (
            v_pro_cod,
            v_fecha_actual,
            p_nuevo_precio,
            NULL
        );

        DBMS_OUTPUT.PUT_LINE('Precio actualizado para el producto ' || p_nombre_producto || 
                             '. De ' || v_precio_actual || ' a ' || p_nuevo_precio);
    
    ELSE
        DBMS_OUTPUT.PUT_LINE('El precio ingresado es igual al precio actual (' || v_precio_actual || '). No se requiere actualización.');
            END IF;

    COMMIT;

        EXCEPTION
    WHEN e_producto_no_encontrado THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró el producto con el nombre "' || p_nombre_producto || '".');
            WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        ROLLBACK;
        
END actualizar_precio_producto;
/

-- procedimiento para agregar productos al catalogo
CREATE OR REPLACE PROCEDURE agregar_producto_a_catalogo (
    p_nombre_producto IN productos.pro_nom%TYPE,
    p_nombre_pais IN paises.p_nom%TYPE,
    p_limite_compra IN catalogos.cat_limcom%TYPE
)
IS
    v_pro_cod productos.pro_cod%TYPE;
    v_pais_id paises.p_id%TYPE;
BEGIN
    SELECT pro_cod
    INTO v_pro_cod
    FROM productos
    WHERE pro_nom = p_nombre_producto;

    SELECT p_id
    INTO v_pais_id
    FROM paises
    WHERE p_nom = p_nombre_pais;

    INSERT INTO catalogos (
        cat_prod,
        cat_pais,
        cat_limcom
    ) VALUES (
        v_pro_cod,
        v_pais_id,
        p_limite_compra
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Producto "' || p_nombre_producto || '" (ID: ' || v_pro_cod || ') agregado al catálogo de ' || p_nombre_pais || ' (ID: ' || v_pais_id || ') con límite de compra: ' || p_limite_compra);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró el producto o el país especificado.');
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Error: El producto ya existe en el catálogo para ese país.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado al agregar el producto al catálogo: ' || SQLERRM);
        ROLLBACK;
END;
/

-- procedimiento para insertar productos
CREATE OR REPLACE PROCEDURE insertar_producto (
    p_id_tema_in     IN NUMBER,  
    p_nombre_in      IN VARCHAR2,    
    p_descripcion_in IN VARCHAR2,   
    p_rango_edad_in  IN VARCHAR2,    
    p_rango_precio_in IN VARCHAR2,  
    p_es_set_in      IN VARCHAR2,    
    p_instrucciones_in IN VARCHAR2 DEFAULT NULL, 
    p_piezas_in      IN NUMBER DEFAULT NULL,    
    p_id_set_padre_in IN NUMBER DEFAULT NULL     
)
AS
    v_es_set_upper VARCHAR2(2);
BEGIN
    v_es_set_upper := UPPER(p_es_set_in);

    IF v_es_set_upper NOT IN ('SI', 'NO') THEN
        RAISE_APPLICATION_ERROR(-20008, 'El valor para "Es Set" (pro_set) debe ser "SI" o "NO".');
    END IF;

    INSERT INTO productos (
        pro_idtem,
        pro_nom,
        pro_desc,
        pro_raned,
        pro_ranpr,
        pro_set,
        pro_instr,
        pro_piecs,
        set_id
    )
    VALUES (
        p_id_tema_in,
        p_nombre_in,
        p_descripcion_in,
        UPPER(p_rango_edad_in),
        UPPER(p_rango_precio_in),
        v_es_set_upper,
        p_instrucciones_in,
        p_piezas_in,
        p_id_set_padre_in
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, 'Error al insertar producto: ' || SQLERRM);

END insertar_producto;
/

-- procedimiento para insertar temas
CREATE OR REPLACE PROCEDURE insertar_tema (
    p_nombre_in   IN VARCHAR2,   
    p_tipo_in     IN VARCHAR2,     
    p_descripcion_in IN VARCHAR2,   
    p_id_padre_in IN NUMBER DEFAULT NULL 
)
AS
    v_tipo_upper VARCHAR2(10);
BEGIN
    v_tipo_upper := UPPER(p_tipo_in);

    IF v_tipo_upper NOT IN ('SERIE', 'TEMA') THEN
        RAISE_APPLICATION_ERROR(-20006, 'El tipo de tema debe ser "SERIE" o "TEMA".');
        END IF;

    INSERT INTO temas (
        te_nom,
        te_tipo,
        te_desc,
        te_padre
    )
    VALUES (
        UPPER(p_nombre_in),
        v_tipo_upper,
        UPPER(p_descripcion_in),
        p_id_padre_in
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'Error al insertar tema: ' || SQLERRM);

END insertar_tema;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO: INICIAR_FACTURA_FISICA
-- ═══════════════════════════════════════════════════════════════════════════════
CREATE OR REPLACE PROCEDURE INICIAR_FACTURA_FISICA (
    p_cli_id IN NUMBER,
    p_ti_id IN NUMBER,
    p_fact_tf_num OUT NUMBER,
    p_msg OUT VARCHAR2
)
AS
    v_fact_num NUMBER;
        BEGIN
    INSERT INTO factura_tf (
        fact_tf_femision,
        fact_tf_total,
        fact_tf_cli,
        fact_tf_tie
    )
    VALUES (
        SYSDATE,
        0,
        p_cli_id,
        p_ti_id
    )
    RETURNING fact_tf_num INTO v_fact_num;

    p_fact_tf_num := v_fact_num;
    p_msg := 'Exito. Cabecera iniciada. Factura: ' || v_fact_num;
    
        EXCEPTION
            WHEN OTHERS THEN
        p_msg := 'Error al iniciar cabecera: ' || SQLERRM;
        p_fact_tf_num := NULL;
                RAISE;
        END;
/

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROCEDIMIENTO: INSERTAR_DETALLE_FISICA
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
    v_total NUMBER;
    v_pro_raned VARCHAR2(8);  
    v_det_ft_id NUMBER;
    v_factura_existe NUMBER;
    v_lote_existe NUMBER;
    v_producto_existe NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('DEBUG INSERTAR_DETALLE_FISICA: INICIO - tienda=' || p_ti_id || 
                         ', factura=' || p_fact_num || ', producto=' || p_pro_cod || 
                         ', cantidad=' || p_cantidad);
    
    -- 1. Verificar que el producto existe
    SELECT COUNT(*)
    INTO v_producto_existe
    FROM productos
    WHERE pro_cod = p_pro_cod;
    
    DBMS_OUTPUT.PUT_LINE('DEBUG: Producto existe? ' || v_producto_existe);
    
    IF v_producto_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20032, 'Error: El producto ' || p_pro_cod || ' no existe.');
    END IF;
    
    -- 2. Verificar que la factura existe
    SELECT COUNT(*)
    INTO v_factura_existe
    FROM factura_tf
    WHERE fact_tf_num = p_fact_num
      AND fact_tf_tie = p_ti_id;
    
    IF v_factura_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20026, 'Error: La factura ' || p_fact_num || ' no existe en la tienda ' || p_ti_id);
    END IF;
    
    -- 3. Verificar stock disponible considerando descuentos ya realizados
    SELECT NVL(SUM(l.lot_stock - NVL(d.total_descontado, 0)), 0) 
    INTO v_total_stock
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
      AND (l.lot_stock - NVL(d.total_descontado, 0)) > 0;
    
    IF v_total_stock < p_cantidad THEN
        RAISE_APPLICATION_ERROR(-20003, 'Stock Insuficiente. Disponible: ' || v_total_stock || ', Requerido: ' || p_cantidad);
    END IF;

    -- 4. Seleccionar el lote con mayor stock disponible
    DBMS_OUTPUT.PUT_LINE('DEBUG: Buscando lote para producto ' || p_pro_cod || ' en tienda ' || p_ti_id);
    
    BEGIN
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
        
        DBMS_OUTPUT.PUT_LINE('DEBUG: Lote encontrado - lot_id=' || v_lote_id || ', stock_disp=' || v_stock_disp);
        
        -- Verificar que se obtuvo un lote válido
        IF v_lote_id IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('DEBUG: v_lote_id es NULL después del SELECT');
            RAISE_APPLICATION_ERROR(-20033, 'Error: No se encontró un lote disponible para el producto ' || p_pro_cod || ' en la tienda ' || p_ti_id);
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('DEBUG: NO_DATA_FOUND al buscar lote');
            RAISE_APPLICATION_ERROR(-20033, 'Error: No se encontró un lote disponible para el producto ' || p_pro_cod || ' en la tienda ' || p_ti_id);
    END;

    -- 5. Verificar que el lote existe y coincide exactamente con la foreign key
    -- La foreign key es: (lot_prod, lot_tienda, lot_id)
    SELECT COUNT(*)
    INTO v_lote_existe
    FROM lotes
    WHERE lot_prod = p_pro_cod
      AND lot_tienda = p_ti_id
      AND lot_id = v_lote_id;
    
    IF v_lote_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20025, 'Error: El lote ' || v_lote_id || ' no existe para el producto ' || p_pro_cod || ' en la tienda ' || p_ti_id);
    END IF;

    -- 5. Obtener precio y tipo de cliente del producto
    SELECT hp.hp_precio, p.pro_raned
    INTO v_precio_unitario, v_pro_raned
    FROM hist_precios hp
    JOIN productos p ON hp.hp_prod = p.pro_cod
    WHERE hp.hp_prod = p_pro_cod
      AND hp.hp_ffin IS NULL;
    
    IF v_precio_unitario IS NULL THEN
        RAISE_APPLICATION_ERROR(-20023, 'Error: No se encontró precio activo para el producto ' || p_pro_cod);
    END IF;
    
    IF v_pro_raned IS NULL THEN
        RAISE_APPLICATION_ERROR(-20023, 'Error: No se encontró tipo de cliente (pro_raned) para el producto ' || p_pro_cod);
    END IF;
    
    v_subtotal := p_cantidad * v_precio_unitario;

    -- 6. Obtener el siguiente ID de detalle
    SELECT det_fact_tf_seq.NEXTVAL INTO v_det_ft_id FROM dual;
    
    IF v_det_ft_id IS NULL THEN
        RAISE_APPLICATION_ERROR(-20021, 'Error: No se pudo obtener el siguiente valor de la secuencia det_fact_tf_seq.');
    END IF;
    
    -- 7. Verificar foreign keys antes del INSERT
    -- Foreign key 1: (det_ft_tienda_fact, det_ft_fact) → factura_tf(fact_tf_tie, fact_tf_num)
    DECLARE
        v_factura_fk_existe NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_factura_fk_existe
        FROM factura_tf
        WHERE fact_tf_tie = p_ti_id
          AND fact_tf_num = p_fact_num;
        
        DBMS_OUTPUT.PUT_LINE('DEBUG: Verificando FK factura - existe? ' || v_factura_fk_existe);
        
        IF v_factura_fk_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20034, 'Error FK factura: No existe factura_tf con (tienda=' || p_ti_id || ', num=' || p_fact_num || ')');
        END IF;
    END;
    
    -- Foreign key 2: (det_ft_prod, det_ft_tienda_lote, det_ft_lote) → lotes(lot_prod, lot_tienda, lot_id)
    DECLARE
        v_lote_fk_existe NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_lote_fk_existe
        FROM lotes
        WHERE lot_prod = p_pro_cod
          AND lot_tienda = p_ti_id
          AND lot_id = v_lote_id;
        
        DBMS_OUTPUT.PUT_LINE('DEBUG: Verificando FK lote - existe? ' || v_lote_fk_existe || 
                            ' (prod=' || p_pro_cod || ', tienda=' || p_ti_id || ', lote=' || v_lote_id || ')');
        
        IF v_lote_fk_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20035, 'Error FK lote: No existe lote con (prod=' || p_pro_cod || 
                ', tienda=' || p_ti_id || ', lote_id=' || v_lote_id || ')');
        END IF;
    END;
    
    -- 8. INSERTAR EL DETALLE - Este es el paso crítico
    -- IMPORTANTE: NO usar bloque BEGIN/EXCEPTION aquí para que el error real de Oracle se propague
    -- Si el INSERT falla, Oracle mostrará el error exacto (constraint, foreign key, etc.)
    -- Estructura según lego_create.sql:
    --   Foreign key 1: (det_ft_tienda_fact, det_ft_fact) → factura_tf(fact_tf_tie, fact_tf_num)
    --   Foreign key 2: (det_ft_prod, det_ft_tienda_lote, det_ft_lote) → lotes(lot_prod, lot_tienda, lot_id)
    
    -- Debug: Mostrar valores antes del INSERT
    DBMS_OUTPUT.PUT_LINE('DEBUG INSERTAR_DETALLE: det_ft_id=' || v_det_ft_id || 
                         ', fact=' || p_fact_num || ', tienda_fact=' || p_ti_id ||
                         ', lote=' || v_lote_id || ', prod=' || p_pro_cod ||
                         ', tienda_lote=' || p_ti_id || ', tipo_cli=' || v_pro_raned ||
                         ', cantidad=' || p_cantidad);
    
    INSERT INTO det_fact_t (
        det_ft_id,
        det_ft_cantidad,
        det_ft_fact,
        det_ft_tienda_fact,
        det_ft_lote,
        det_ft_prod,
        det_ft_tienda_lote,
        det_ft_tipo_cli
    )
    VALUES (
        v_det_ft_id,
        p_cantidad,
        p_fact_num,
        p_ti_id,              -- det_ft_tienda_fact (debe coincidir con fact_tf_tie)
        v_lote_id,            -- det_ft_lote
        p_pro_cod,            -- det_ft_prod
        p_ti_id,              -- det_ft_tienda_lote (debe coincidir con lot_tienda del lote)
        v_pro_raned           -- det_ft_tipo_cli (VARCHAR2(8))
    );
    
    -- Verificar que se insertó correctamente
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20024, 'Error: No se pudo insertar el detalle. SQL%ROWCOUNT = 0');
        END IF;
    
    DBMS_OUTPUT.PUT_LINE('DEBUG: INSERT exitoso. SQL%ROWCOUNT=' || SQL%ROWCOUNT);
    
    -- 10. Verificar que el detalle existe en la tabla inmediatamente después del INSERT
    DECLARE
        v_detalle_verificado NUMBER;
        BEGIN
        SELECT COUNT(*)
        INTO v_detalle_verificado
        FROM det_fact_t
        WHERE det_ft_fact = p_fact_num
          AND det_ft_tienda_fact = p_ti_id
          AND det_ft_id = v_det_ft_id;
        
        IF v_detalle_verificado = 0 THEN
            RAISE_APPLICATION_ERROR(-20027, 'Error: El detalle no se insertó en la tabla. ' ||
                'det_ft_id=' || v_det_ft_id || ', fact=' || p_fact_num || ', tienda=' || p_ti_id ||
                '. Verificar foreign keys: factura (' || p_ti_id || ',' || p_fact_num || 
                '), lote (' || p_pro_cod || ',' || p_ti_id || ',' || v_lote_id || ')');
        END IF;
    END;

    -- 11. Insertar descuento en la tabla descuentos (esto se hace después de verificar que el detalle se insertó)
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

    -- 12. Calcular y actualizar el total de la factura
    SELECT NVL(fact_tf_total, 0)
    INTO v_total
    FROM factura_tf
    WHERE fact_tf_num = p_fact_num
      AND fact_tf_tie = p_ti_id;
    
    v_total := v_total + v_subtotal;
    
    UPDATE factura_tf
    SET fact_tf_total = v_total
    WHERE fact_tf_tie = p_ti_id
      AND fact_tf_num = p_fact_num;
      
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Error: No se pudo actualizar el total de la factura ' || p_fact_num);
    END IF;
    
    p_msg := 'Exito. Detalle insertado. Lote: ' || v_lote_id || ' Subtotal: ' || v_subtotal || ' Total factura: ' || v_total;
    
        EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: No se encontro un lote valido para el producto o no tiene precio activo.';
        DBMS_OUTPUT.PUT_LINE('DEBUG EXCEPTION NO_DATA_FOUND: ' || p_msg);
        RAISE;
            WHEN OTHERS THEN
        p_msg := 'Error al insertar detalle: ' || SQLERRM || ' (Código: ' || SQLCODE || ')';
        DBMS_OUTPUT.PUT_LINE('DEBUG EXCEPTION OTHERS: ' || p_msg);
        DBMS_OUTPUT.PUT_LINE('DEBUG: Valores usados - fact=' || p_fact_num || 
                            ', tienda=' || p_ti_id || ', prod=' || p_pro_cod ||
                            ', lote=' || v_lote_id || ', det_id=' || v_det_ft_id);
                RAISE;
        END;
/



-- procedimiento para finalizar la factura de tienda fisica
CREATE OR REPLACE PROCEDURE FINALIZAR_FACTURA_FISICA (
    p_ti_id IN NUMBER,
    p_fact_num IN NUMBER,
    p_msg OUT VARCHAR2
)
AS
    v_total NUMBER;
    v_total_actual NUMBER;
    v_detalles_count NUMBER;
        BEGIN
    -- Verificar que hay detalles antes de finalizar
    SELECT COUNT(*)
    INTO v_detalles_count
    FROM det_fact_t
    WHERE det_ft_fact = p_fact_num
      AND det_ft_tienda_fact = p_ti_id;
    
    IF v_detalles_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Error: No hay detalles para la factura ' || p_fact_num || 
            ' en la tienda ' || p_ti_id || '. No se puede finalizar una factura sin detalles.');
    END IF;
    
    -- Calcular el total usando la función
    v_total := fn_calcular_total_factura_fisica(p_fact_num, p_ti_id);
    
    -- Si el total es 0 pero hay detalles, recalcular manualmente
    IF v_total = 0 AND v_detalles_count > 0 THEN
        SELECT NVL(SUM(dt.det_ft_cantidad * hp.hp_precio), 0)
        INTO v_total
        FROM det_fact_t dt
        INNER JOIN hist_precios hp ON dt.det_ft_prod = hp.hp_prod 
                                   AND hp.hp_ffin IS NULL
        WHERE dt.det_ft_fact = p_fact_num
          AND dt.det_ft_tienda_fact = p_ti_id;
    END IF;
    
    -- Actualizar el total en la factura
    UPDATE factura_tf
    SET fact_tf_total = v_total
    WHERE fact_tf_num = p_fact_num
      AND fact_tf_tie = p_ti_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'No se pudo actualizar el total de la factura ' || p_fact_num);
    END IF;
    
    -- Verificar que se actualizó correctamente
    SELECT fact_tf_total
    INTO v_total_actual
    FROM factura_tf
    WHERE fact_tf_num = p_fact_num
      AND fact_tf_tie = p_ti_id;
    
    p_msg := 'Exito. Factura FINALIZADA, lista para COMMIT. Total calculado: ' || v_total_actual || 
             ' | Detalles: ' || v_detalles_count;
    
        EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: No se encontro detalles para la factura.';
        -- NO hacer ROLLBACK aquí, dejar que el procedimiento superior maneje la transacción
        RAISE;
            WHEN OTHERS THEN
        p_msg := 'Error al finalizar factura: ' || SQLERRM;
        -- NO hacer ROLLBACK aquí, dejar que el procedimiento superior maneje la transacción
                RAISE;
        END;
/

-- procedimiento para iniciar la factura de venta online
CREATE OR REPLACE PROCEDURE INICIAR_FACTURA_ONLINE (
    p_cli_id IN NUMBER,
    p_fact_o_num OUT NUMBER, 
    p_msg OUT VARCHAR2
)
AS
    v_fact_num NUMBER;
    v_cliente_existe NUMBER;
        BEGIN
    -- Verificar que el cliente existe
    SELECT COUNT(*)
    INTO v_cliente_existe
    FROM clientes
    WHERE cli_id = p_cli_id;
    
    IF v_cliente_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-22020, 'Error: El cliente ' || p_cli_id || ' no existe.');
    END IF;
    
    INSERT INTO factura_o (
        fact_o_femision,
        fact_o_total,
        fact_o_puntosgen,
        fact_o_cli,
        venta_gratis
    )
    VALUES (
        SYSDATE,
        0, 
        0, 
        p_cli_id,
        'NO'
    )
    RETURNING fact_o_num INTO v_fact_num; 

    IF v_fact_num IS NULL THEN
        RAISE_APPLICATION_ERROR(-22021, 'Error: No se pudo obtener el número de factura después del INSERT.');
    END IF;

    p_fact_o_num := v_fact_num;
    p_msg := 'Exito. Cabecera online iniciada. Factura: ' || v_fact_num;
    
        EXCEPTION
            WHEN OTHERS THEN
        p_msg := 'Error al iniciar cabecera online: ' || SQLERRM;
        p_fact_o_num := NULL;
        -- NO hacer ROLLBACK aquí, dejar que el procedimiento superior maneje la transacción
                RAISE;
        END;
/
        
-- procedimiento para insertar detalles a la factura de venta online
CREATE OR REPLACE PROCEDURE INSERTAR_DETALLE_ONLINE (
    p_fact_num IN NUMBER, 
    p_pro_cod IN NUMBER,
    p_cantidad IN NUMBER,
    p_msg OUT VARCHAR2
)
AS
    v_cli_id             clientes.cli_id%TYPE;
    v_pais_residencia    clientes.cli_reside%TYPE;
    v_precio_unitario    hist_precios.hp_precio%TYPE;
    v_pro_raned          productos.pro_raned%TYPE;
    v_subtotal           NUMBER;
    v_limite_catalogo    catalogos.cat_limcom%TYPE; 
    
    e_limite_excedido EXCEPTION; 
        BEGIN
    SELECT fo.fact_o_cli, c.cli_reside
    INTO v_cli_id, v_pais_residencia
    FROM factura_o fo
    JOIN clientes c ON fo.fact_o_cli = c.cli_id
    WHERE fo.fact_o_num = p_fact_num;

    SELECT hp.hp_precio, pro.pro_raned, c.cat_limcom
    INTO v_precio_unitario, v_pro_raned, v_limite_catalogo
    FROM productos pro
    JOIN hist_precios hp ON pro.pro_cod = hp.hp_prod AND hp.hp_ffin IS NULL
    JOIN catalogos c ON pro.pro_cod = c.cat_prod
    WHERE pro.pro_cod = p_pro_cod 
      AND c.cat_pais = v_pais_residencia; 
      
    IF p_cantidad > v_limite_catalogo THEN
        RAISE e_limite_excedido;
    END IF;

    v_subtotal := p_cantidad * v_precio_unitario;

    INSERT INTO det_fact_o (
        det_fo_fact,
        det_fo_pais,
        det_fo_prod,
        det_fo_cantidad,
        det_fo_tipo_cli 
    )
    VALUES (
        p_fact_num,
        v_pais_residencia,
        p_pro_cod,
        p_cantidad,
        v_pro_raned
    );

    -- Calcular y actualizar el total usando la función
    UPDATE factura_o
    SET fact_o_total = fn_calcular_total_factura_online(p_fact_num)
    WHERE fact_o_num = p_fact_num;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'La factura online ' || p_fact_num || ' no existe.');
    END IF;
    
    p_msg := 'Exito. Detalle online insertado. Subtotal: ' || v_subtotal;
    
        EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: El producto no existe, no tiene precio actual, o no está catalogado para el país del cliente.';
        ROLLBACK;
    WHEN e_limite_excedido THEN
        p_msg := 'Error: La cantidad (' || p_cantidad || ') excede el límite de compra del catálogo (' || v_limite_catalogo || ').';
        ROLLBACK;
            WHEN OTHERS THEN
        p_msg := 'Error al insertar detalle online: ' || SQLERRM;
        ROLLBACK;
        END;
/

-- procedimiento para finalizar la factura de ventas online
CREATE OR REPLACE PROCEDURE FINALIZAR_FACTURA_ONLINE (
    p_fact_num IN NUMBER,
    p_msg OUT VARCHAR2
)
AS
    v_cli_id              factura_o.fact_o_cli%TYPE;
    v_pais_id             clientes.cli_reside%TYPE;
    v_es_ue               paises.p_ue%TYPE;
    v_total_detalles      NUMBER;
    v_total_final         NUMBER;
    v_recargo_adicional   NUMBER; 
    
    v_costo_envio         NUMBER; 
    v_puntos_acumulados_ant NUMBER;
    v_puntos_generados    NUMBER := 0;
    v_venta_gratis        factura_o.venta_gratis%TYPE := 'NO';
    v_recargo_porcentaje  NUMBER;
    v_detalles_count      NUMBER := 0;
    
    e_total_cero EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_total_cero, -20050);
BEGIN
    -- Verificar que hay detalles antes de finalizar
    SELECT COUNT(*)
    INTO v_detalles_count
    FROM det_fact_o
    WHERE det_fo_fact = p_fact_num;
    
    IF v_detalles_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20050, 'Error: No hay detalles para la factura ' || p_fact_num || '. No se puede finalizar una factura sin detalles.');
    END IF;
    
    -- Calcular el total de detalles usando la función
    v_total_detalles := fn_calcular_total_factura_online(p_fact_num);
    
    -- Obtener el cliente de la factura
    SELECT fact_o_cli
    INTO v_cli_id
    FROM factura_o
    WHERE fact_o_num = p_fact_num;
    
    IF v_total_detalles IS NULL OR v_total_detalles <= 0 THEN
        RAISE_APPLICATION_ERROR(-20050, 'Error: Factura Online ' || p_fact_num || ' no tiene detalles válidos o el total es cero.');
    END IF;
    
    v_costo_envio := 
        CASE 
            WHEN v_total_detalles >= 500 THEN 20
            WHEN v_total_detalles >= 100 THEN 15
            ELSE 10 
        END;

    SELECT c.cli_reside, p.p_ue
    INTO v_pais_id, v_es_ue
    FROM clientes c
    JOIN paises p ON c.cli_reside = p.p_id
    WHERE c.cli_id = v_cli_id;

    IF UPPER(v_es_ue) = 'SI' THEN
        v_recargo_porcentaje := 0.05; 
    ELSE
        v_recargo_porcentaje := 0.15; 
    END IF;
    
    SELECT NVL(SUM(fact_o_puntosgen), 0) INTO v_puntos_acumulados_ant
    FROM factura_o
    WHERE fact_o_cli = v_cli_id
      AND fact_o_num < p_fact_num;
      
    IF v_puntos_acumulados_ant >= 500 THEN
        v_recargo_adicional := v_costo_envio * v_recargo_porcentaje;
        v_total_final := v_costo_envio + v_recargo_adicional;
        
        v_venta_gratis := 'SI';
        v_puntos_generados := 0; 
        
        p_msg := 'Factura ' || p_fact_num || ' finalizada. ¡Venta GRATIS aplicada! Total: ' 
            || v_total_final || ' (Solo Envío y Recargo Adicional). Puntos reseteados.';
    ELSE
        v_recargo_adicional := v_total_detalles * v_recargo_porcentaje;
        v_total_final := v_total_detalles + v_recargo_adicional + v_costo_envio;
        
        v_puntos_generados := 
            CASE 
                WHEN v_total_detalles >= 200 THEN 200 
                WHEN v_total_detalles >= 70 THEN 50  
                WHEN v_total_detalles >= 10 THEN 20  
                ELSE 5 
            END;

        p_msg := 'Factura ' || p_fact_num || ' finalizada. Total: ' 
            || v_total_final || ' (Envío: ' || v_costo_envio || ' + Recargo Adicional: ' || v_recargo_porcentaje * 100 || '%). Puntos obtenidos: ' || v_puntos_generados;
    END IF;
    
    UPDATE factura_o
    SET fact_o_total = v_total_final,
        fact_o_puntosgen = v_puntos_generados,
        venta_gratis = v_venta_gratis
    WHERE fact_o_num = p_fact_num;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-22023, 'Error: No se pudo actualizar la factura ' || p_fact_num || '. La factura no existe.');
    END IF;

    -- NO hacer COMMIT aquí, dejar que el procedimiento superior maneje la transacción
    -- El COMMIT se hará en sp_automatizar_venta_online después de obtener toda la información

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: Factura Online ' || p_fact_num || ' no encontrada o no tiene detalles válidos.';
        -- NO hacer ROLLBACK aquí, dejar que el procedimiento superior maneje la transacción
        RAISE;
    WHEN e_total_cero THEN
        p_msg := 'Error: Factura Online ' || p_fact_num || ' no tiene detalles o el total es cero.';
        -- NO hacer ROLLBACK aquí, dejar que el procedimiento superior maneje la transacción
        RAISE;
    WHEN OTHERS THEN
        p_msg := 'Error al finalizar factura online: ' || SQLERRM || ' (Código: ' || SQLCODE || ')';
        -- NO hacer ROLLBACK aquí, dejar que el procedimiento superior maneje la transacción
        RAISE;
END FINALIZAR_FACTURA_ONLINE;
/

CREATE OR REPLACE PROCEDURE CONVERTIR_PRECIOS_TIENDA (
    p_tienda_id IN NUMBER,
    p_tasa_conversion IN NUMBER DEFAULT 1.08 
)
AS
    v_pais_id       NUMBER(4);
    v_es_ue         VARCHAR2(2);
    v_fecha_actual  DATE := TRUNC(SYSDATE); 
    v_precio_actual NUMBER(10, 2);

    CURSOR c_productos IS
SELECT 
            l.lot_prod,
            hp.hp_precio
        FROM lotes l
        JOIN hist_precios hp ON l.lot_prod = hp.hp_prod
        WHERE l.lot_tienda = p_tienda_id
          AND hp.hp_ffin IS NULL;

BEGIN
    DBMS_OUTPUT.ENABLE(NULL);
    
    SELECT ti_pais INTO v_pais_id
    FROM tiendas
    WHERE ti_id = p_tienda_id;

    SELECT p_ue INTO v_es_ue
    FROM paises
    WHERE p_id = v_pais_id;

    IF v_es_ue = 'NO' THEN

        FOR r_prod IN c_productos LOOP

            v_precio_actual := r_prod.hp_precio;
            
            DECLARE
                v_nuevo_precio NUMBER(10, 2) := ROUND(v_precio_actual * p_tasa_conversion, 2);
            BEGIN
                IF v_nuevo_precio <> v_precio_actual THEN

                    UPDATE hist_precios
                    SET hp_precio = v_nuevo_precio
                    WHERE hp_prod = r_prod.lot_prod
                      AND hp_ffin IS NULL;

                END IF;
            END; 
            
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Proceso completado. Se ACTUALIZARON los precios a USD para la tienda ' || p_tienda_id);

    ELSIF v_es_ue = 'SI' THEN
        DBMS_OUTPUT.PUT_LINE('Tienda ' || p_tienda_id || ' pertenece a la UE. No se realizó ninguna conversión de precios.');
    END IF;

    COMMIT; 

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Tienda o País no encontrado.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error SQL: ' || SQLERRM);
        ROLLBACK;
END CONVERTIR_PRECIOS_TIENDA;
/


------------------------------------------------------------------------------------------
------------------- PROCEDIMIENTOS TIENDA—----------------------------
------------------------------------------------------------------------------------------

-- procedimiento para insertar productos en el inventario
CREATE OR REPLACE PROCEDURE INSERTAR_LOTE_PRODUCTO (
    p_nombre_producto IN VARCHAR2,
    p_tienda_id IN NUMBER,
    p_stock IN NUMBER
)
IS
    v_pro_cod PRODUCTOS.pro_cod%TYPE;

    e_producto_no_encontrado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_producto_no_encontrado, -20001);
BEGIN
    BEGIN
        SELECT
            pro_cod
        INTO
            v_pro_cod
        FROM
            productos
        WHERE
            UPPER(pro_nom) = UPPER(p_nombre_producto);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_producto_no_encontrado;
    END;

    INSERT INTO lotes (
        lot_prod,
        lot_tienda,
        lot_stock
    )
    VALUES (
        v_pro_cod,
        p_tienda_id,
        p_stock
    );

    COMMIT;

EXCEPTION
    WHEN e_producto_no_encontrado THEN
        RAISE_APPLICATION_ERROR(-20001, 'ERROR: El producto con nombre "' || p_nombre_producto || '" no fue encontrado.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;

END INSERTAR_LOTE_PRODUCTO;
/

-- procedimiento para actualizar el historico del precio
CREATE OR REPLACE PROCEDURE actualizar_precio_producto (
    p_nombre_producto IN VARCHAR2,
    p_nuevo_precio    IN NUMBER
)
AS
    v_pro_cod         productos.pro_cod%TYPE;
    v_precio_actual   hist_precios.hp_precio%TYPE := NULL;
    v_fecha_actual    DATE := TRUNC(SYSDATE);
    
    e_producto_no_encontrado EXCEPTION;

BEGIN
    
    BEGIN
        SELECT pro_cod
        INTO v_pro_cod
        FROM productos
        WHERE pro_nom = p_nombre_producto;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_producto_no_encontrado;
    END;

    BEGIN
        SELECT hp_precio
        INTO v_precio_actual
        FROM hist_precios
        WHERE hp_prod = v_pro_cod
          AND hp_ffin IS NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_precio_actual := NULL;  
    END;

    IF v_precio_actual IS NULL THEN
        
        DBMS_OUTPUT.PUT_LINE('No existe historial de precios. Insertando primer registro.');
        
        INSERT INTO hist_precios (
            hp_prod,
            hp_fini,
            hp_precio,
            hp_ffin
        )
        VALUES (
            v_pro_cod,
            v_fecha_actual,
            p_nuevo_precio,
            NULL
        );
        
    ELSIF p_nuevo_precio <> v_precio_actual THEN 
        
        UPDATE hist_precios
        SET hp_ffin = v_fecha_actual - 1
        WHERE hp_prod = v_pro_cod
          AND hp_ffin IS NULL;

        INSERT INTO hist_precios (
            hp_prod,
            hp_fini,
            hp_precio,
            hp_ffin
        )
        VALUES (
            v_pro_cod,
            v_fecha_actual,
            p_nuevo_precio,
            NULL
        );

        DBMS_OUTPUT.PUT_LINE('Precio actualizado para el producto ' || p_nombre_producto || 
                             '. De ' || v_precio_actual || ' a ' || p_nuevo_precio);
    
    ELSE
        DBMS_OUTPUT.PUT_LINE('El precio ingresado es igual al precio actual (' || v_precio_actual || '). No se requiere actualización.');
    END IF;

    COMMIT;

EXCEPTION
    WHEN e_producto_no_encontrado THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró el producto con el nombre "' || p_nombre_producto || '".');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        ROLLBACK;
        
END actualizar_precio_producto;
/

-- procedimiento para agregar productos al catalogo
CREATE OR REPLACE PROCEDURE agregar_producto_a_catalogo (
    p_nombre_producto IN productos.pro_nom%TYPE,
    p_nombre_pais IN paises.p_nom%TYPE,
    p_limite_compra IN catalogos.cat_limcom%TYPE
)
IS
    v_pro_cod productos.pro_cod%TYPE;
    v_pais_id paises.p_id%TYPE;
BEGIN
    SELECT pro_cod
    INTO v_pro_cod
    FROM productos
    WHERE pro_nom = p_nombre_producto;

    SELECT p_id
    INTO v_pais_id
    FROM paises
    WHERE p_nom = p_nombre_pais;

    INSERT INTO catalogos (
        cat_prod,
        cat_pais,
        cat_limcom
    ) VALUES (
        v_pro_cod,
        v_pais_id,
        p_limite_compra
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Producto "' || p_nombre_producto || '" (ID: ' || v_pro_cod || ') agregado al catálogo de ' || p_nombre_pais || ' (ID: ' || v_pais_id || ') con límite de compra: ' || p_limite_compra);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: No se encontró el producto o el país especificado.');
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Error: El producto ya existe en el catálogo para ese país.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado al agregar el producto al catálogo: ' || SQLERRM);
        ROLLBACK;
END;
/

-- procedimiento para insertar el cliente por primera vez
CREATE OR REPLACE PROCEDURE INSERTAR_CLIENTE (
  p_pnombre       IN CLIENTES.cli_pnombre%TYPE,
    p_papellido     IN CLIENTES.cli_papellido%TYPE,
    p_sapellido     IN CLIENTES.cli_sapellido%TYPE,
    p_dni           IN CLIENTES.cli_dni%TYPE,
    p_fnacimiento   IN CLIENTES.cli_fnacimiento%TYPE,
    p_nac           IN CLIENTES.cli_nac%TYPE,
    p_reside        IN CLIENTES.cli_reside%TYPE,
    p_numpas        IN CLIENTES.cli_numpas%TYPE DEFAULT NULL,
    p_fvenpas       IN CLIENTES.cli_fvenpas%TYPE DEFAULT NULL,
    p_snombre       IN CLIENTES.cli_snombre%TYPE DEFAULT NULL
)
AS
    v_error_msg     VARCHAR2(255);
    v_dni_count     NUMBER; 
BEGIN

    IF p_pnombre IS NULL OR p_papellido IS NULL OR p_sapellido IS NULL OR p_dni IS NULL OR p_fnacimiento IS NULL OR p_nac IS NULL OR p_reside IS NULL THEN
        
        v_error_msg := 'Error: Faltan datos obligatorios.';

        IF p_pnombre IS NULL THEN v_error_msg := v_error_msg || ' Primer nombre;'; END IF;
        IF p_papellido IS NULL THEN v_error_msg := v_error_msg || ' Primer apellido;'; END IF;
        IF p_sapellido IS NULL THEN v_error_msg := v_error_msg || ' Segundo apellido;'; END IF;
        IF p_dni IS NULL THEN v_error_msg := v_error_msg || ' DNI;'; END IF;
        IF p_fnacimiento IS NULL THEN v_error_msg := v_error_msg || ' Fecha de nacimiento;'; END IF;
        IF p_nac IS NULL THEN v_error_msg := v_error_msg || ' País de nacionalidad (cli_nac);'; END IF;
        IF p_reside IS NULL THEN v_error_msg := v_error_msg || ' País de residencia (cli_reside);'; END IF;

        RAISE_APPLICATION_ERROR(-20002, v_error_msg);
    END IF;

    SELECT COUNT(*)
    INTO v_dni_count
    FROM CLIENTES
    WHERE cli_dni = p_dni;

    IF v_dni_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error: El DNI ' || p_dni || ' ya está registrado para otro cliente.');
    END IF;
    
    INSERT INTO CLIENTES (
        cli_pnombre,
        cli_papellido,
        cli_sapellido,
        cli_dni,
        cli_fnacimiento,
        cli_nac,
        cli_reside,
        cli_numpas,
        cli_fvenpas,
        cli_snombre
    )
    VALUES (
        p_pnombre,
        p_papellido,
        p_sapellido,
        p_dni,
        p_fnacimiento,
        p_nac,
        p_reside,
        p_numpas,
        p_fvenpas,
        p_snombre
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'Error en la inserción o integridad de datos: ' || SQLERRM);
END INSERTAR_CLIENTE;
/


-- procedimiento para insertar productos
CREATE OR REPLACE PROCEDURE insertar_producto (
    p_id_tema_in     IN NUMBER,  
    p_nombre_in      IN VARCHAR2,    
    p_descripcion_in IN VARCHAR2,   
    p_rango_edad_in  IN VARCHAR2,    
    p_rango_precio_in IN VARCHAR2,  
    p_es_set_in      IN VARCHAR2,    
    p_instrucciones_in IN VARCHAR2 DEFAULT NULL, 
    p_piezas_in      IN NUMBER DEFAULT NULL,    
    p_id_set_padre_in IN NUMBER DEFAULT NULL     
)
AS
    v_es_set_upper VARCHAR2(2);
BEGIN
    v_es_set_upper := UPPER(p_es_set_in);
    
    IF v_es_set_upper NOT IN ('SI', 'NO') THEN
        RAISE_APPLICATION_ERROR(-20008, 'El valor para "Es Set" (pro_set) debe ser "SI" o "NO".');
    END IF;
    
    INSERT INTO productos (
        pro_idtem,
        pro_nom,
        pro_desc,
        pro_raned,
        pro_ranpr,
        pro_set,
        pro_instr,
        pro_piecs,
        set_id
    )
    VALUES (
        p_id_tema_in,
        p_nombre_in,
        p_descripcion_in,
        UPPER(p_rango_edad_in),
        UPPER(p_rango_precio_in),
        v_es_set_upper,
        p_instrucciones_in,
        p_piezas_in,
        p_id_set_padre_in
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, 'Error al insertar producto: ' || SQLERRM);

END insertar_producto;
/

-- procedimiento para insertar temas
CREATE OR REPLACE PROCEDURE insertar_tema (
    p_nombre_in   IN VARCHAR2,   
    p_tipo_in     IN VARCHAR2,     
    p_descripcion_in IN VARCHAR2,   
    p_id_padre_in IN NUMBER DEFAULT NULL 
)
AS
    v_tipo_upper VARCHAR2(10);
BEGIN
    v_tipo_upper := UPPER(p_tipo_in);
    
    IF v_tipo_upper NOT IN ('SERIE', 'TEMA') THEN
        RAISE_APPLICATION_ERROR(-20006, 'El tipo de tema debe ser "SERIE" o "TEMA".');
    END IF;
    
    INSERT INTO temas (
        te_nom,
        te_tipo,
        te_desc,
        te_padre
    )
    VALUES (
        UPPER(p_nombre_in),
        v_tipo_upper,
        UPPER(p_descripcion_in),
        p_id_padre_in
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20007, 'Error al insertar tema: ' || SQLERRM);

END insertar_tema;
/

-- procedimiento para iniciar la factura de tienda fisica
CREATE OR REPLACE PROCEDURE INICIAR_FACTURA_FISICA (
    p_cli_id IN NUMBER,
    p_ti_id IN NUMBER,
    p_fact_tf_num OUT NUMBER,
    p_msg OUT VARCHAR2
)
AS
    v_fact_num NUMBER;
    BEGIN
    INSERT INTO factura_tf (
        fact_tf_femision,
        fact_tf_total,
        fact_tf_cli,
        fact_tf_tie
    )
    VALUES (
        SYSDATE,
        0,
        p_cli_id,
        p_ti_id
    )
    RETURNING fact_tf_num INTO v_fact_num;

    p_fact_tf_num := v_fact_num;
    p_msg := 'Exito. Cabecera iniciada. Factura: ' || v_fact_num;
    
EXCEPTION
    WHEN OTHERS THEN
        p_msg := 'Error al iniciar cabecera: ' || SQLERRM;
        p_fact_tf_num := NULL;
        -- NO hacer ROLLBACK aquí, dejar que el procedimiento superior maneje la transacción
        RAISE;
END;
/

-- Esta versión duplicada del procedimiento FINALIZAR_FACTURA_FISICA ha sido eliminada.
-- Se usa la versión correcta que está más arriba en el archivo (línea ~1295).


-- Esta versión duplicada del procedimiento INICIAR_FACTURA_ONLINE ha sido eliminada.
-- Se usa la versión correcta que está más arriba en el archivo (línea ~1424).

-- procedimiento para insertar detalles a la factura de venta online
CREATE OR REPLACE PROCEDURE INSERTAR_DETALLE_ONLINE (
    p_fact_num IN NUMBER, 
    p_pro_cod IN NUMBER,
    p_cantidad IN NUMBER,
    p_msg OUT VARCHAR2
)
AS
    v_cli_id             clientes.cli_id%TYPE;
    v_pais_residencia    clientes.cli_reside%TYPE;
    v_precio_unitario    hist_precios.hp_precio%TYPE;
    v_pro_raned          productos.pro_raned%TYPE;
    v_subtotal           NUMBER;
    v_limite_catalogo    catalogos.cat_limcom%TYPE; 
    
    e_limite_excedido EXCEPTION; 
BEGIN
    SELECT fo.fact_o_cli, c.cli_reside
    INTO v_cli_id, v_pais_residencia
    FROM factura_o fo
    JOIN clientes c ON fo.fact_o_cli = c.cli_id
    WHERE fo.fact_o_num = p_fact_num;

    SELECT hp.hp_precio, pro.pro_raned, c.cat_limcom
    INTO v_precio_unitario, v_pro_raned, v_limite_catalogo
    FROM productos pro
    JOIN hist_precios hp ON pro.pro_cod = hp.hp_prod AND hp.hp_ffin IS NULL
    JOIN catalogos c ON pro.pro_cod = c.cat_prod
    WHERE pro.pro_cod = p_pro_cod 
      AND c.cat_pais = v_pais_residencia; 
      
    IF p_cantidad > v_limite_catalogo THEN
        RAISE e_limite_excedido;
            END IF;

    v_subtotal := p_cantidad * v_precio_unitario;

    INSERT INTO det_fact_o (
        det_fo_fact,
        det_fo_pais,
        det_fo_prod,
        det_fo_cantidad,
        det_fo_tipo_cli 
    )
    VALUES (
        p_fact_num,
        v_pais_residencia,
        p_pro_cod,
        p_cantidad,
        v_pro_raned
    );

    -- Calcular y actualizar el total usando la función
    UPDATE factura_o
    SET fact_o_total = fn_calcular_total_factura_online(p_fact_num)
    WHERE fact_o_num = p_fact_num;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'La factura online ' || p_fact_num || ' no existe.');
    END IF;
    
    p_msg := 'Exito. Detalle online insertado. Subtotal: ' || v_subtotal;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: El producto no existe, no tiene precio actual, o no está catalogado para el país del cliente.';
        ROLLBACK;
    WHEN e_limite_excedido THEN
        p_msg := 'Error: La cantidad (' || p_cantidad || ') excede el límite de compra del catálogo (' || v_limite_catalogo || ').';
        ROLLBACK;
    WHEN OTHERS THEN
        p_msg := 'Error al insertar detalle online: ' || SQLERRM;
        ROLLBACK;
END;
/

-- procedimiento para finalizar la factura de ventas online
CREATE OR REPLACE PROCEDURE FINALIZAR_FACTURA_ONLINE (
    p_fact_num IN NUMBER,
    p_msg OUT VARCHAR2
)
AS
    v_cli_id              factura_o.fact_o_cli%TYPE;
    v_pais_id             clientes.cli_reside%TYPE;
    v_es_ue               paises.p_ue%TYPE;
    v_total_detalles      NUMBER;
    v_total_final         NUMBER;
    v_recargo_adicional   NUMBER; 
    
    v_costo_envio         NUMBER; 
    v_puntos_acumulados_ant NUMBER;
    v_puntos_generados    NUMBER := 0;
    v_venta_gratis        factura_o.venta_gratis%TYPE := 'NO';
    v_recargo_porcentaje  NUMBER;
    v_detalles_count      NUMBER := 0;
    
    e_total_cero EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_total_cero, -20050);
BEGIN
    -- Verificar que hay detalles antes de finalizar
    SELECT COUNT(*)
    INTO v_detalles_count
    FROM det_fact_o
    WHERE det_fo_fact = p_fact_num;
    
    IF v_detalles_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20050, 'Error: No hay detalles para la factura ' || p_fact_num || '. No se puede finalizar una factura sin detalles.');
    END IF;
    
    -- Calcular el total de detalles usando la función
    v_total_detalles := fn_calcular_total_factura_online(p_fact_num);
    
    -- Obtener el cliente de la factura
    SELECT fact_o_cli
    INTO v_cli_id
    FROM factura_o
    WHERE fact_o_num = p_fact_num;
    
    IF v_total_detalles IS NULL OR v_total_detalles <= 0 THEN
        RAISE_APPLICATION_ERROR(-20050, 'Error: Factura Online ' || p_fact_num || ' no tiene detalles válidos o el total es cero.');
    END IF;
    
    v_costo_envio := 
        CASE 
            WHEN v_total_detalles >= 500 THEN 20
            WHEN v_total_detalles >= 100 THEN 15
            ELSE 10 
        END;

    SELECT c.cli_reside, p.p_ue
    INTO v_pais_id, v_es_ue
    FROM clientes c
    JOIN paises p ON c.cli_reside = p.p_id
    WHERE c.cli_id = v_cli_id;

    IF UPPER(v_es_ue) = 'SI' THEN
        v_recargo_porcentaje := 0.05; 
    ELSE
        v_recargo_porcentaje := 0.15; 
    END IF;
    
    SELECT NVL(SUM(fact_o_puntosgen), 0) INTO v_puntos_acumulados_ant
    FROM factura_o
    WHERE fact_o_cli = v_cli_id
      AND fact_o_num < p_fact_num;
      
    IF v_puntos_acumulados_ant >= 500 THEN
        v_recargo_adicional := v_costo_envio * v_recargo_porcentaje;
        v_total_final := v_costo_envio + v_recargo_adicional;
        
        v_venta_gratis := 'SI';
        v_puntos_generados := 0; 
        
        p_msg := 'Factura ' || p_fact_num || ' finalizada. ¡Venta GRATIS aplicada! Total: ' 
            || v_total_final || ' (Solo Envío y Recargo Adicional). Puntos reseteados.';
    ELSE
        v_recargo_adicional := v_total_detalles * v_recargo_porcentaje;
        v_total_final := v_total_detalles + v_recargo_adicional + v_costo_envio;
        
        v_puntos_generados := 
            CASE 
                WHEN v_total_detalles >= 200 THEN 200 
                WHEN v_total_detalles >= 70 THEN 50  
                WHEN v_total_detalles >= 10 THEN 20  
                ELSE 5 
            END;

        p_msg := 'Factura ' || p_fact_num || ' finalizada. Total: ' 
            || v_total_final || ' (Envío: ' || v_costo_envio || ' + Recargo Adicional: ' || v_recargo_porcentaje * 100 || '%). Puntos obtenidos: ' || v_puntos_generados;
    END IF;
    
    UPDATE factura_o
    SET fact_o_total = v_total_final,
        fact_o_puntosgen = v_puntos_generados,
        venta_gratis = v_venta_gratis
    WHERE fact_o_num = p_fact_num;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-22023, 'Error: No se pudo actualizar la factura ' || p_fact_num || '. La factura no existe.');
    END IF;

    -- NO hacer COMMIT aquí, dejar que el procedimiento superior maneje la transacción
    -- El COMMIT se hará en sp_automatizar_venta_online después de obtener toda la información

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: Factura Online ' || p_fact_num || ' no encontrada o no tiene detalles válidos.';
        -- NO hacer ROLLBACK aquí, dejar que el procedimiento superior maneje la transacción
        RAISE;
    WHEN e_total_cero THEN
        p_msg := 'Error: Factura Online ' || p_fact_num || ' no tiene detalles o el total es cero.';
        -- NO hacer ROLLBACK aquí, dejar que el procedimiento superior maneje la transacción
        RAISE;
    WHEN OTHERS THEN
        p_msg := 'Error al finalizar factura online: ' || SQLERRM || ' (Código: ' || SQLCODE || ')';
        -- NO hacer ROLLBACK aquí, dejar que el procedimiento superior maneje la transacción
        RAISE;
END FINALIZAR_FACTURA_ONLINE;
/

CREATE OR REPLACE PROCEDURE CONVERTIR_PRECIOS_TIENDA (
    p_tienda_id IN NUMBER,
    p_tasa_conversion IN NUMBER DEFAULT 1.08 
)
AS
    v_pais_id       NUMBER(4);
    v_es_ue         VARCHAR2(2);
    v_fecha_actual  DATE := TRUNC(SYSDATE); 
    v_precio_actual NUMBER(10, 2);

    CURSOR c_productos IS
    SELECT 
            l.lot_prod,
            hp.hp_precio
        FROM lotes l
        JOIN hist_precios hp ON l.lot_prod = hp.hp_prod
        WHERE l.lot_tienda = p_tienda_id
          AND hp.hp_ffin IS NULL;

BEGIN
    DBMS_OUTPUT.ENABLE(NULL);
    
    SELECT ti_pais INTO v_pais_id
    FROM tiendas
    WHERE ti_id = p_tienda_id;

    SELECT p_ue INTO v_es_ue
    FROM paises
    WHERE p_id = v_pais_id;

    IF v_es_ue = 'NO' THEN

        FOR r_prod IN c_productos LOOP

            v_precio_actual := r_prod.hp_precio;
            
            DECLARE
                v_nuevo_precio NUMBER(10, 2) := ROUND(v_precio_actual * p_tasa_conversion, 2);
BEGIN
                IF v_nuevo_precio <> v_precio_actual THEN

                    UPDATE hist_precios
                    SET hp_precio = v_nuevo_precio
                    WHERE hp_prod = r_prod.lot_prod
                      AND hp_ffin IS NULL;

                END IF;
            END; 
            
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('Proceso completado. Se ACTUALIZARON los precios a USD para la tienda ' || p_tienda_id);

    ELSIF v_es_ue = 'SI' THEN
        DBMS_OUTPUT.PUT_LINE('Tienda ' || p_tienda_id || ' pertenece a la UE. No se realizó ninguna conversión de precios.');
    END IF;

    COMMIT; 
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Tienda o País no encontrado.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error SQL: ' || SQLERRM);
        ROLLBACK;
END CONVERTIR_PRECIOS_TIENDA;
/
