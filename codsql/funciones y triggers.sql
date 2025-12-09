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


-----------------------------------------------------------
------------------------- TOUR ----------------------------
-----------------------------------------------------------

---funcion para el costo total de la inscripcion
create or replace function fn_calcular_costo_inscripcion (p_tour_fecha in date, p_cantidad_participantes in number)
return number is 
    v_costo_unitario number;
    v_costo_total number;
begin
    select to_costo into v_costo_unitario
    from tours where to_fini = p_tour_fecha;

    v_costo_total := v_costo_unitario * p_cantidad_participantes;
    
    return v_costo_total;

end;
/

--funcion para obtener moneda del tour (DKK,EUR,USD) 
create or replace function fn_obtener_moneda_tour(p_tour_fecha in date)
return varchar2 is
    v_moneda varchar2(3);
begin
    v_moneda := 'USD';
    return v_moneda;
end;
/

---funcion para validar periodo de inscripcion 
create or replace function fn_inscripcion_abierta(p_tour_fecha date)
return boolean is 
    v_ano_tour NUMBER;
    v_fecha_limite date;
begin
    v_ano_tour := extract(year from p_tour_fecha);

    v_fecha_limite:= TO_DATE('09/12' || TO_CHAR(v_ano_tour), 'DD/MM/YYYY');

    -- Permitir inscripciones si la fecha límite no ha pasado
    -- Para tours pasados, siempre retornar TRUE (permitir inscripción)
    -- Para tours futuros, validar que no haya pasado la fecha límite
    IF p_tour_fecha < TRUNC(SYSDATE) THEN
        -- Tour pasado: permitir inscripción
        RETURN TRUE;
    ELSE
        -- Tour futuro o presente: validar fecha límite
        RETURN (SYSDATE <= v_fecha_limite);
    END IF;
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


-- funcion para verificar cupos del tour
create or replace function verificar_cupos (p_fecha_tour date)
return number is 
    v_cupos_totales tours.to_cupos%type;
    v_cupos_ocupados number := 0;
    v_cupos_disponibles number;

begin
    select to_cupos into v_cupos_totales from tours 
    where to_fini = p_fecha_tour;

    if v_cupos_totales <= 0 then
        raise_application_error(-20009, 'El tour no tiene cupos disponibles');
    end if;

    select count(*) into v_cupos_ocupados from inscripciones 
    where ins_tour = p_fecha_tour and ins_estado = 'PAGO';

    v_cupos_disponibles := v_cupos_totales - v_cupos_ocupados;
    return v_cupos_disponibles;

end;
/

--funcion para validar la fecha del tour y es vigente 
create or replace function validar_fecha_tour (p_fecha_tour date)
return boolean is
    v_tour_existe number;
    v_fecha_actual date := sysdate; 
    v_ano_actual number := extract(year from v_fecha_actual);
begin

    select count(*) into v_tour_existe from tours 
    where to_fini = p_fecha_tour;

    if v_tour_existe = 0 then
        raise_application_error(-20010, 'La fecha seleccionada para le tour no esta disponible');
    end if;
-- validar que la fecha no es del pasado
    if p_fecha_tour < trunc(v_fecha_actual) THEN
        raise_application_error(-20010, 'No se puede inscribir el tour en una fecha pasada');
    end if;   

-- validar que la fecha esta dentro del rango de anos del proyecto 
    if extract(year from p_fecha_tour) < 2024 then
        raise_application_error(-20010, 'EL tour seleccionado esta fuera del rango de anos permitidos');
    end if;
    return true;

    exception 
        when others THEN
        if sqlcode in (-20010) then
            raise;
        else 
            raise_application_error(-20010, 'Error al validar la fecha del tour');
        end if;    

end;
/

-----------------------------------------------------------
-- Validaciones de clientes 
-----------------------------------------------------------
-- funcion para obtener datos completos de un cliente 
 create or replace function obtener_cliente_info (p_cli_id number) 
 return sys_refcursor is
    v_cursor sys_refcursor;
    v_cliente_existe number; 

begin 
    select count (*) into v_cliente_existe 
    from clientes where cli_id = p_cli_id;
    
    if v_cliente_existe = 0 THEN
        raise_application_error(-20012, 'El cliente con id' || p_cli_id || 'no existe en la base de datos');
    end if;

    --abrir cursor con datos del cliente 

    open v_cursor for 
        select
            cli_id,
            cli_pnombre,
            cli_papellido, 
            cli_sapellido,
            cli_snombre,
            cli_dni,
            cli_fnacimiento,
            cli_nac,
            cli_reside,
            cli_numpas,
            cli_fvenpas,
            edad(cli_fnacimiento) AS edad_calculada,
            p_id AS pais_id,
            p_nom AS pais_nombre,
            p_ue AS pais_pertenece_ue
        from clientes c
        left join paises p on c.cli_nac = p.p_id
        where c.cli_id = p_cli_id;
    return v_cursor;
end;
/


--validar si cliente no-Ue necesita pasaporte 
create or replace function fn_validar_pasaporte_requerido (p_nacionalidad_id number)
return boolean is 
    v_ue varchar2(2);
begin
    select p_ue into v_ue
    from paises where p_id = p_nacionalidad_id;

    return (v_ue = 'NO');
end;
/
-- funcion para validar edad del cliente 

create or replace function validar_edad_cliente (p_cli_id number)
return boolean is
    v_cli_fnacimiento clientes.cli_fnacimiento%type;
    v_edad number;
begin
    select cli_fnacimiento into v_cli_fnacimiento 
    from clientes where cli_id = p_cli_id;

    v_edad:=  edad(v_cli_fnacimiento);
    if v_edad < 21 then 
        raise_application_error (-20013, 'La edad minima permitida, para realizar una compra, es 21 anos');
    end if;
    return true;
end;
/

--funcion para validar si existe el cliente
create or replace function cliente_existe(p_cli_id number)
return boolean is 
    v_cont number;
begin
    select count(*) into v_cont
    from clientes where cli_id = p_cli_id;

    return (v_cont > 0);

end;
/


-- validar documentacion del cliente 

create or replace function validar_documentacion_cliente (p_cli_id number)
return boolean is
    v_pais_id paises.p_id%type;
    v_pertenece_ue paises.p_ue%type;
    v_numpas clientes.cli_numpas%type;
    v_fvenpas clientes.cli_fvenpas%type;
BEGIN
    select cli_nac, cli_numpas, cli_fvenpas 
    into v_pais_id, v_numpas, v_fvenpas from clientes
    where cli_id = p_cli_id; 

    v_pertenece_ue := es_ue(v_pais_id);
    if v_pertenece_ue = 'NO' then 
        if v_numpas is null then 
            raise_application_error(-20014, 'El cliente debe indicar numero de pasaporte');
        end if;

        if v_fvenpas is null then 
            raise_application_error(-20014, 'El cliente debe indicar la fecha de vencimiento de su pasaporte');
        end if;

        if v_fvenpas < trunc (sysdate) then
            raise_application_error(-20014, 'Debe ingresar un pasaporte vigente');
        end if;
    end if;
END;
/

-----------------------------------------------------------
-- Validaciones de fan lego
-----------------------------------------------------------

CREATE OR REPLACE FUNCTION validar_edad_fan_lego (p_fl_id NUMBER)
RETURN BOOLEAN IS
    v_fecha_nac f_lego.fl_fnacimiento%TYPE;
    v_edad_actual NUMBER;
BEGIN
    
    SELECT fl_fnacimiento
    INTO v_fecha_nac
    FROM f_lego
    WHERE fl_id = p_fl_id;
    
    v_edad_actual := edad(v_fecha_nac);
    
    IF v_edad_actual < 12 OR v_edad_actual > 20 THEN
        RAISE_APPLICATION_ERROR(
            -20015,
            'Los Fans LEGO deben tener entre 12 y 20 años. ' ||
            'Edad actual del fan: ' || v_edad_actual || ' años.'
        );
    END IF;
    
    RETURN TRUE;
END validar_edad_fan_lego;
/

---validar si fan lego existe 
create or replace function fan_lego_existe (p_fl_id number)
return boolean is 
    v_cont number;
begin
    select count(*) into v_cont
    from f_lego where fl_id = p_fl_id;

    return (v_cont > 0);

end;
/


--- funcion para validar que tiene un representante asignado 

create or replace function validar_representante_asignado (p_fl_id number) 
return boolean is
    v_fl_representante f_lego.fl_repre%type;
    v_fl_fnac f_lego.FL_FNACIMIENTO%TYPE;
    v_edad number;
begin
    select fl_repre, fl_fnacimiento into v_fl_representante, v_fl_fnac 
    from f_lego where fl_id = p_fl_id;

    v_edad := edad(v_fl_fnac);

    if v_edad BETWEEN 12 and 17 then
        if v_fl_representante is null then
            raise_application_error(-20016, 'El fan lego debe tener un representante adulto asignado');
        end if;
    end if;

    return true;

end;
/


--funcion para obtener los datos del fan lego + representante 

create or replace function obtener_datos_fl (p_fl_id number) 
return sys_refcursor is
    v_cursor sys_refcursor;
    v_fan_existe number;
begin
    select count(*) into v_fan_existe 
    from f_lego where fl_id = p_fl_id;

    if v_fan_existe = 0 then 
        raise_application_error(-20017, 'EL fan lego no se pudo encontrar');
    end if;

    OPEN v_cursor FOR
        SELECT 
            -- Datos del Fan
            f.fl_id,
            f.fl_pnombre,
            f.fl_papellido,
            f.fl_sapellido,
            f.fl_snombre,
            f.fl_dni,
            f.fl_fnacimiento,
            f.fl_nac,
            f.fl_numpas,
            f.fl_fvenpas,
            edad(f.fl_fnacimiento) AS edad_fan,
            pf.p_nom AS pais_fan_nombre,
            pf.p_ue AS pais_fan_ue,
            
            -- Datos del Representante
            c.cli_id,
            c.cli_pnombre AS rep_pnombre,
            c.cli_papellido AS rep_papellido,
            c.cli_sapellido AS rep_sapellido,
            c.cli_snombre AS rep_snombre,
            c.cli_dni AS rep_dni,
            c.cli_fnacimiento AS rep_fnacimiento,
            edad(c.cli_fnacimiento) AS edad_representante,
            c.cli_nac AS rep_pais_nac,
            pc.p_nom AS rep_pais_nombre,
            c.cli_numpas AS rep_numpas,
            c.cli_fvenpas AS rep_fvenpas
            
        FROM f_lego f
        LEFT JOIN paises pf ON f.fl_nac = pf.p_id
        LEFT JOIN clientes c ON f.fl_repre = c.cli_id
        LEFT JOIN paises pc ON c.cli_nac = pc.p_id
        WHERE f.fl_id = p_fl_id;
    
    RETURN v_cursor;




end;
/


--- validar documentacion del fan lego
create or replace function validar_documentacion_fl (p_fl_id number)
return boolean is
    v_pais_id paises.p_id%TYPE;
    v_pertenece_ue paises.p_ue%TYPE;
    v_numpas f_lego.fl_numpas%TYPE;
    v_fvenpas f_lego.fl_fvenpas%TYPE;

begin
    select fl_nac, fl_numpas, fl_fvenpas into v_pais_id, v_numpas, v_fvenpas
    from f_lego where fl_id = p_fl_id;

    v_pertenece_ue := es_ue(v_pais_id);

    if v_pertenece_ue = 'NO' then 
        if v_numpas is null then
            raise_application_error(-20018, 'El fan lego debe indicar el numero de pasaporte');
        end if;    

        if v_fvenpas is null then 
            raise_application_error(-20018,'El fan lego debe indicar la fecha de vencimiento de su pasaporte');
        end if;

        if v_fvenpas < trunc(sysdate) then 
            raise_application_error(-20018, 'Debe proporcionar un pasaporte vigente');
        end if;

    end if;

    return true;

end;
/

--- validacion para el representante (que sea mayor de edad)

create or replace function validar_representante (p_cli_id number)
return boolean is
    v_fnacimiento clientes.cli_fnacimiento%type;
    v_edad number;
begin

    if not cliente_existe(p_cli_id) then 
        raise_application_error(-20019, 'El cliente representante no existe');
    end if;

    select cli_fnacimiento into v_fnacimiento 
    from clientes where cli_id = p_cli_id;

    v_edad := edad(v_fnacimiento);

    if v_edad < 21 then 
        raise_application_error(-20019, 'El cliente no puede ser un representante porque no tiene la edad para serlo');
    end if; 

    if not validar_documentacion_cliente(p_cli_id) then 
        raise_application_error(-20019,'El representante no tiene la documentacion para viajar');
    end if;
return true;
end;
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
CREATE OR REPLACE PROCEDURE pr_validar_fase_1 (
    p_fecha_tour DATE,
    p_participante_id NUMBER,
    p_tipo_participante CHAR,
    p_validar_cupos BOOLEAN,
    p_resultado OUT VARCHAR2
) IS
    v_cupos_disponibles NUMBER;
    v_es_valido BOOLEAN := TRUE;
    v_mensaje VARCHAR2(1000) := '';
BEGIN
    
    -- ════════════════════════════════════════════════════════
    -- VALIDACIÓN 1: Verificar que la fecha del tour es válida
    -- ════════════════════════════════════════════════════════
    BEGIN
        v_es_valido := validar_fecha_tour(p_fecha_tour);
        v_mensaje := v_mensaje || ' [✓] Fecha del tour válida.';
    EXCEPTION
        WHEN OTHERS THEN
            v_es_valido := FALSE;
            v_mensaje := v_mensaje || ' [✗] ' || SQLERRM;
            RAISE;
    END;
    
    -- ════════════════════════════════════════════════════════
    -- VALIDACIÓN 2: Verificar cupos disponibles (opcional)
    -- ════════════════════════════════════════════════════════
    IF p_validar_cupos THEN
        BEGIN
            v_cupos_disponibles := verificar_cupos(p_fecha_tour);
            IF v_cupos_disponibles <= 0 THEN
                RAISE_APPLICATION_ERROR(
                    -20010,
                    'No hay cupos disponibles para este tour.'
                );
            END IF;
            v_mensaje := v_mensaje || ' [✓] Cupos disponibles: ' || v_cupos_disponibles || '.';
        EXCEPTION
            WHEN OTHERS THEN
                v_es_valido := FALSE;
                v_mensaje := v_mensaje || ' [✗] ' || SQLERRM;
                RAISE;
        END;
    END IF;
    
    -- ════════════════════════════════════════════════════════
    -- VALIDACIÓN 3: Validar participante (Cliente o Fan)
    -- ════════════════════════════════════════════════════════
    IF p_tipo_participante = 'C' THEN
        
        -- Validar cliente
        IF NOT cliente_existe(p_participante_id) THEN
            RAISE_APPLICATION_ERROR(
                -20012,
                'Cliente ID ' || p_participante_id || ' no existe.'
            );
        END IF;
        v_mensaje := v_mensaje || ' [✓] Cliente existe.';
        
        
        -- Validar documentación
        BEGIN
            v_es_valido := validar_documentacion_cliente(p_participante_id);
            v_mensaje := v_mensaje || ' [✓] Documentación válida.';
        EXCEPTION
            WHEN OTHERS THEN
                v_es_valido := FALSE;
                v_mensaje := v_mensaje || ' [✗] ' || SQLERRM;
                RAISE;
        END;
        
    ELSIF p_tipo_participante = 'F' THEN
        
        -- Validar fan LEGO
        IF NOT fan_lego_existe(p_participante_id) THEN
            RAISE_APPLICATION_ERROR(
                -20017,
                'Fan LEGO ID ' || p_participante_id || ' no existe.'
            );
        END IF;
        v_mensaje := v_mensaje || ' [✓] Fan LEGO existe.';
        
        -- Validar edad (12-20 años)
        BEGIN
            v_es_valido := validar_edad_fan_lego(p_participante_id);
            v_mensaje := v_mensaje || ' [✓] Edad en rango 12-20 años.';
        EXCEPTION
            WHEN OTHERS THEN
                v_es_valido := FALSE;
                v_mensaje := v_mensaje || ' [✗] ' || SQLERRM;
                RAISE;
        END;
        
        -- Validar representante
        BEGIN
            v_es_valido := validar_representante_asignado(p_participante_id);
            v_mensaje := v_mensaje || ' [✓] Representante asignado.';
        EXCEPTION
            WHEN OTHERS THEN
                v_es_valido := FALSE;
                v_mensaje := v_mensaje || ' [✗] ' || SQLERRM;
                RAISE;
        END;
        
        -- Validar representante es válido
        DECLARE
            v_repre_id NUMBER;
        BEGIN
            SELECT fl_repre INTO v_repre_id FROM f_lego WHERE fl_id = p_participante_id;
            v_es_valido := validar_representante(v_repre_id);
            v_mensaje := v_mensaje || ' [✓] Representante es cliente válido.';
        EXCEPTION
            WHEN OTHERS THEN
                v_es_valido := FALSE;
                v_mensaje := v_mensaje || ' [✗] ' || SQLERRM;
                RAISE;
        END;
        
        -- Validar documentación del fan
        BEGIN
            v_es_valido := validar_documentacion_fl(p_participante_id);
            v_mensaje := v_mensaje || ' [✓] Documentación del fan válida.';
        EXCEPTION
            WHEN OTHERS THEN
                v_es_valido := FALSE;
                v_mensaje := v_mensaje || ' [✗] ' || SQLERRM;
                RAISE;
        END;
        
    ELSE
        RAISE_APPLICATION_ERROR(
            -20099,
            'Tipo de participante inválido. Use "C" para cliente o "F" para fan.'
        );
    END IF;
    
    -- ════════════════════════════════════════════════════════
    -- RESULTADO FINAL
    -- ════════════════════════════════════════════════════════
    IF v_es_valido THEN
        p_resultado := 'VALIDACIÓN EXITOSA.' || v_mensaje;
    ELSE
        p_resultado := 'VALIDACIÓN FALLIDA.' || v_mensaje;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        p_resultado := 'ERROR EN VALIDACIONES: ' || SQLERRM;
        RAISE;
END pr_validar_fase_1;
/

--procedimiento para registrar cliente por primera vez 
create or replace procedure sp_registrar_cliente_nuevo (
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
        cli_id,
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
        clientes_seq.NEXTVAL,
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
END sp_registrar_cliente_nuevo;
/

--procedimiento para crear inscripcion (antes de pago)
CREATE OR REPLACE PROCEDURE sp_crear_inscripcion(
    p_tour_fecha IN DATE,
    p_cliente_responsable IN NUMBER,
    p_participantes_json IN VARCHAR2,  -- JSON con [{tipo, cliente_id/fan_id}]
    p_numero_inscripcion OUT NUMBER,
    p_costo_total OUT NUMBER,
    p_mensaje OUT VARCHAR2
)
IS
    v_cantidad_participantes NUMBER := 0;
    v_costo_unitario NUMBER;
    v_cupos_requeridos NUMBER;
    v_cliente_edad NUMBER;
    CURSOR c_participantes IS
    SELECT REGEXP_SUBSTR(p_participantes_json, '[^;]+', 1, LEVEL) AS linea
    FROM dual
    CONNECT BY LEVEL <= REGEXP_COUNT(p_participantes_json, ';') + 1;
BEGIN
    SAVEPOINT sp_inscripcion_inicio;
    
    -- 1. VALIDAR TOUR
    IF NOT fn_tour_disponible(p_tour_fecha) THEN
        RAISE_APPLICATION_ERROR(-20911, 'Tour no disponible en esa fecha');
    END IF;
    
    -- 2. VALIDAR PERÍODO DE INSCRIPCIÓN
    IF NOT fn_inscripcion_abierta(p_tour_fecha) THEN
        RAISE_APPLICATION_ERROR(-20912, 
            'Período de inscripción cerrado para este tour');
    END IF;
    
    -- 3. VALIDAR CLIENTE RESPONSABLE Y OBTENER EDAD
    BEGIN
        SELECT TRUNC((SYSDATE - cli_fnacimiento) / 365.25)
        INTO v_cliente_edad
        FROM clientes WHERE cli_id = p_cliente_responsable;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20913, 
                'Cliente responsable no existe');
    END;
    
    -- 4. VALIDAR EDAD CLIENTE RESPONSABLE >= 21 AÑOS
    
    IF v_cliente_edad < 21 THEN
        RAISE_APPLICATION_ERROR(-20914, 
            'Responsable debe ser mayor de 21 años');
    END IF;
    
    -- 5. PROCESAR PARTICIPANTES
    FOR registro IN c_participantes LOOP
        v_cantidad_participantes := v_cantidad_participantes + 1;
    END LOOP;
    
    IF v_cantidad_participantes = 0 THEN
        RAISE_APPLICATION_ERROR(-20915, 
            'Inscripción debe tener al menos un participante');
    END IF;
    
    -- 6. VALIDAR CUPOS DISPONIBLES
    IF NOT fn_validar_cupos_tour(p_tour_fecha, v_cantidad_participantes) THEN
        RAISE_APPLICATION_ERROR(-20916, 
            'No hay cupos disponibles para la cantidad solicitada');
    END IF;
    
    -- 7. CALCULAR COSTO TOTAL
    p_costo_total := fn_calcular_costo_inscripcion(p_tour_fecha, 
                                                    v_cantidad_participantes);
    
    -- 8. CREAR INSCRIPCIÓN (ESTADO: PENDIENTE PAGO)
    SELECT inscripciones_seq.NEXTVAL INTO p_numero_inscripcion FROM dual;
    
    INSERT INTO inscripciones (
        ins_num, ins_femision, ins_total, ins_estado, ins_tour
    ) VALUES (
        p_numero_inscripcion, SYSDATE, p_costo_total, 'PENDIENTE', p_tour_fecha
    );
    
    -- 9. REGISTRAR PARTICIPANTES Y ENTRADAS
    DECLARE
        v_contador NUMBER := 1;
        v_tipo_asistente VARCHAR2(10);
        v_cliente_id NUMBER;
        v_fan_id NUMBER;
        v_linea VARCHAR2(100);
    BEGIN
        FOR registro IN c_participantes LOOP
            v_linea := TRIM(registro.linea);
            
            IF v_linea IS NOT NULL THEN
                v_tipo_asistente := TRIM(REGEXP_SUBSTR(v_linea, '^[^:]+', 1, 1));
                
                INSERT INTO det_inscrip (
                    det_ins_id, det_ins_ins, det_ins_tipo,
                    det_ins_fan, det_ins_cli
                ) VALUES (
                    det_inscrip_seq.NEXTVAL, p_numero_inscripcion, v_tipo_asistente,
                    CASE WHEN v_tipo_asistente = 'MENOR' 
                         THEN TO_NUMBER(TRIM(REGEXP_SUBSTR(v_linea, '[^:]+', 1, 2)))
                         ELSE NULL END,
                    CASE WHEN v_tipo_asistente = 'ADULTO' 
                         THEN TO_NUMBER(TRIM(REGEXP_SUBSTR(v_linea, '[^:]+', 1, 2)))
                         ELSE NULL END
                );
                
                -- Crear entrada usando la secuencia entradas_seq
                INSERT INTO entradas_tour (
                    ent_insc, ent_id, ent_tipo_asistente
                ) VALUES (
                    p_numero_inscripcion, entradas_seq.NEXTVAL, v_tipo_asistente
                );
                
                v_contador := v_contador + 1;
            END IF;
        END LOOP;
    END;
    
    p_mensaje := 'Inscripción creada. Número: ' || p_numero_inscripcion || 
                 ' | Total: ' || p_costo_total || ' USD | Estado: PENDIENTE PAGO';
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_inscripcion_inicio;
        p_numero_inscripcion := -1;
        p_costo_total := 0;
        p_mensaje := 'Error: ' || SQLERRM;
END sp_crear_inscripcion;
/

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
    -- Conversión aproximada: 1 DKK = 0.134 EUR = 0.145 USD
    CASE p_moneda_pago
        WHEN 'DKK' THEN v_factor_conversion := 1;
        WHEN 'EUR' THEN v_factor_conversion := 7.47;  -- 1 EUR = 7.47 DKK
        WHEN 'USD' THEN v_factor_conversion := 6.42;  -- 1 USD = 6.42 DKK
        ELSE RAISE_APPLICATION_ERROR(-20923, 'Moneda no válida');
    END CASE;
    
    v_monto_esperado := v_costo_inscripcion / v_factor_conversion;
    
    -- Permitir pequeña variación (1%)
    IF ABS(p_monto_pagado - v_monto_esperado) > (v_monto_esperado * 0.01) THEN
        RAISE_APPLICATION_ERROR(-20924, 
            'Monto pagado no coincide. Esperado: ' || v_monto_esperado || 
            ' ' || p_moneda_pago);
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
-- Procedimiento para obtener información completa de inscripción
CREATE OR REPLACE PROCEDURE sp_obtener_informacion_inscripcion(
    p_numero_inscripcion IN NUMBER,
    p_cursor_resultado OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_resultado FOR
    SELECT 
        i.ins_num AS numero_inscripcion,
        i.ins_femision AS fecha_emision,
        i.ins_total AS costo_total,
        i.ins_estado AS estado,
        i.ins_tour AS fecha_tour,
        t.to_cupos AS cupos_tour,
        COUNT(DISTINCT di.det_ins_id) AS total_participantes,
        SUM(CASE WHEN di.det_ins_tipo = 'ADULTO' THEN 1 ELSE 0 END) AS adultos,
        SUM(CASE WHEN di.det_ins_tipo = 'MENOR' THEN 1 ELSE 0 END) AS menores
    FROM inscripciones i
    JOIN tours t ON i.ins_tour = t.to_fini
    LEFT JOIN det_inscrip di ON i.ins_num = di.det_ins_ins
    WHERE i.ins_num = p_numero_inscripcion
    GROUP BY i.ins_num, i.ins_femision, i.ins_total, i.ins_estado, 
             i.ins_tour, t.to_cupos;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20931, 
            'Error obteniendo información: ' || SQLERRM);
END sp_obtener_informacion_inscripcion;
/

-- Procedimiento para obtener disponibilidad de tours
CREATE OR REPLACE PROCEDURE sp_obtener_tours_disponibles(
    p_cursor_resultado OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_resultado FOR
    SELECT 
        t.to_fini AS fecha_tour,
        t.to_cupos AS cupos_totales,
        t.to_costo AS costo_por_persona,
        COUNT(DISTINCT di.det_ins_id) AS inscritos_confirmados,
        t.to_cupos - COUNT(DISTINCT di.det_ins_id) AS cupos_disponibles,
        CASE WHEN fn_inscripcion_abierta(t.to_fini) THEN 'ABIERTA'
             ELSE 'CERRADA' END AS estado_inscripcion
    FROM tours t
    LEFT JOIN inscripciones i ON t.to_fini = i.ins_tour AND i.ins_estado = 'PAGO'
    LEFT JOIN det_inscrip di ON i.ins_num = di.det_ins_ins
    WHERE t.to_fini > SYSDATE
    GROUP BY t.to_fini, t.to_cupos, t.to_costo
    ORDER BY t.to_fini ASC;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20932, 
            'Error obteniendo tours: ' || SQLERRM);
END sp_obtener_tours_disponibles;
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
        ROLLBACK;
END;
/

-- procedimiento para insertar detalles a la factura de tienda fisica
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



-- procedimiento para finalizar la factura de tienda fisica
CREATE OR REPLACE PROCEDURE FINALIZAR_FACTURA_FISICA (
    p_ti_id IN NUMBER,
    p_fact_num IN NUMBER,
    p_msg OUT VARCHAR2
)
AS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(dt.det_ft_cantidad * hp.hp_precio), 0)
    INTO v_total
    FROM det_fact_t dt
    JOIN HIST_PRECIOS hp ON dt.det_ft_prod = hp.hp_prod AND hp.hp_ffin IS NULL
    WHERE dt.det_ft_tienda_fact = p_ti_id
      AND dt.det_ft_fact = p_fact_num;
    
    p_msg := 'Exito. Factura FINALIZADA, lista para COMMIT. Total calculado: ' || v_total;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: No se encontro detalles para la factura.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_msg := 'Error al finalizar factura: ' || SQLERRM;
        ROLLBACK;
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
BEGIN
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

    p_fact_o_num := v_fact_num;
    p_msg := 'Exito. Cabecera online iniciada. Factura: ' || v_fact_num;
    
EXCEPTION
    WHEN OTHERS THEN
        p_msg := 'Error al iniciar cabecera online: ' || SQLERRM;
        p_fact_o_num := NULL;
        ROLLBACK;
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

    UPDATE factura_o
    SET fact_o_total = fact_o_total + v_subtotal
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
    
    e_total_cero EXCEPTION;
BEGIN
    SELECT SUM(df.det_fo_cantidad * hp.hp_precio), fo.fact_o_cli
    INTO v_total_detalles, v_cli_id
    FROM det_fact_o df
    JOIN hist_precios hp ON df.det_fo_prod = hp.hp_prod AND hp.hp_ffin IS NULL
    JOIN factura_o fo ON df.det_fo_fact = fo.fact_o_num
    WHERE df.det_fo_fact = p_fact_num
    GROUP BY fo.fact_o_cli;
    
    IF v_total_detalles IS NULL OR v_total_detalles <= 0 THEN
        RAISE e_total_cero;
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

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: Factura Online ' || p_fact_num || ' no encontrada o no tiene detalles válidos.';
        ROLLBACK;
    WHEN e_total_cero THEN
        p_msg := 'Error: Factura Online ' || p_fact_num || ' no tiene detalles o el total es cero.';
        ROLLBACK;
    WHEN OTHERS THEN
        ROLLBACK;
        p_msg := 'Error al finalizar factura online: ' || SQLERRM;
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





--================================================================================
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

--================================================================================
-- 8. PROCEDIMIENTOS DE REPORTE PARA TOURS
--================================================================================

-- Procedimiento para obtener ingresos por año
CREATE OR REPLACE PROCEDURE sp_reporte_ingresos_tours_anual(
    p_ano IN NUMBER,
    p_cursor_resultado OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_resultado FOR
    SELECT 
        t.to_fini AS fecha_tour,
        COUNT(DISTINCT di.det_ins_id) AS participantes,
        SUM(i.ins_total) AS ingresos_dkk,
        ROUND(SUM(i.ins_total) / 7.46, 2) AS ingresos_eur,
        ROUND(SUM(i.ins_total) / 6.90, 2) AS ingresos_usd
    FROM tours t
    JOIN inscripciones i ON t.to_fini = i.ins_tour
    LEFT JOIN det_inscrip di ON i.ins_num = di.det_ins_ins
    WHERE i.ins_estado = 'PAGO'
      AND EXTRACT(YEAR FROM t.to_fini) = p_ano
    GROUP BY t.to_fini
    ORDER BY t.to_fini DESC;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20951, 
            'Error generando reporte: ' || SQLERRM);
END sp_reporte_ingresos_tours_anual;
/
-- Procedimiento para obtener distribución de nacionalidades
CREATE OR REPLACE PROCEDURE sp_reporte_nacionalidades_tour(
    p_ano IN NUMBER,
    p_cursor_resultado OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_resultado FOR
    SELECT 
        p.p_nac AS nacionalidad,
        COUNT(*) AS cantidad_participantes,
        ROUND((COUNT(*) * 100.0 / 
            (SELECT COUNT(*) FROM det_inscrip di
             JOIN inscripciones i ON di.det_ins_ins = i.ins_num
             JOIN tours t ON i.ins_tour = t.to_fini
             WHERE i.ins_estado = 'PAGO'
             AND EXTRACT(YEAR FROM t.to_fini) = p_ano)), 2) AS porcentaje
    FROM det_inscrip di
    JOIN inscripciones i ON di.det_ins_ins = i.ins_num
    JOIN tours t ON i.ins_tour = t.to_fini
    LEFT JOIN clientes c ON di.det_ins_cli = c.cli_id
    LEFT JOIN f_lego f ON di.det_ins_fan = f.fl_id
    LEFT JOIN paises p ON COALESCE(c.cli_nac, f.fl_nac) = p.p_id
    WHERE i.ins_estado = 'PAGO'
      AND EXTRACT(YEAR FROM t.to_fini) = p_ano
    GROUP BY p.p_nac
    ORDER BY cantidad_participantes DESC;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20952, 
            'Error generando reporte nacionalidades: ' || SQLERRM);
END sp_reporte_nacionalidades_tour;
/
-- Procedimiento para obtener distribución por rango de edad
CREATE OR REPLACE PROCEDURE sp_reporte_rangos_edad_tour(
    p_ano IN NUMBER,
    p_cursor_resultado OUT SYS_REFCURSOR
)
IS
BEGIN
    OPEN p_cursor_resultado FOR
    SELECT 
        CASE 
            WHEN TRUNC((SYSDATE - COALESCE(c.cli_fnacimiento, f.fl_fnacimiento)) / 365.25) 
                 BETWEEN 12 AND 17 THEN '12-17 años'
            WHEN TRUNC((SYSDATE - COALESCE(c.cli_fnacimiento, f.fl_fnacimiento)) / 365.25) 
                 BETWEEN 18 AND 30 THEN '18-30 años'
            WHEN TRUNC((SYSDATE - COALESCE(c.cli_fnacimiento, f.fl_fnacimiento)) / 365.25) 
                 BETWEEN 31 AND 60 THEN '31-60 años'
            ELSE 'Mayor de 60 años'
        END AS rango_edad,
        COUNT(*) AS cantidad_participantes,
        ROUND((COUNT(*) * 100.0 / 
            (SELECT COUNT(*) FROM det_inscrip di
             JOIN inscripciones i ON di.det_ins_ins = i.ins_num
             JOIN tours t ON i.ins_tour = t.to_fini
             WHERE i.ins_estado = 'PAGO'
             AND EXTRACT(YEAR FROM t.to_fini) = p_ano)), 2) AS porcentaje
    FROM det_inscrip di
    JOIN inscripciones i ON di.det_ins_ins = i.ins_num
    JOIN tours t ON i.ins_tour = t.to_fini
    LEFT JOIN clientes c ON di.det_ins_cli = c.cli_id
    LEFT JOIN f_lego f ON di.det_ins_fan = f.fl_id
    WHERE i.ins_estado = 'PAGO'
      AND EXTRACT(YEAR FROM t.to_fini) = p_ano
    GROUP BY rango_edad
    ORDER BY cantidad_participantes DESC;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20953, 
            'Error generando reporte edades: ' || SQLERRM);
END sp_reporte_rangos_edad_tour;
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
        ROLLBACK;
END;
/

-- procedimiento para insertar detalles a la factura de tienda fisica
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
    SELECT NVL(SUM(lot_stock), 0) INTO v_total_stock
    FROM lotes
    WHERE lot_tienda = p_ti_id AND lot_prod = p_pro_cod;
    
    IF v_total_stock < p_cantidad THEN
        RAISE_APPLICATION_ERROR(-20003, 'Stock Insuficiente en lotes para la cantidad requerida.');
    END IF;

    SELECT lot_id, lot_stock
    INTO v_lote_id, v_stock_disp
    FROM lotes
    WHERE lot_tienda = p_ti_id
      AND lot_prod = p_pro_cod
    ORDER BY lot_stock DESC
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


-- procedimiento para finalizar la factura de tienda fisica
CREATE OR REPLACE PROCEDURE FINALIZAR_FACTURA_FISICA (
    p_ti_id IN NUMBER,
    p_fact_num IN NUMBER,
    p_msg OUT VARCHAR2
)
AS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(dt.det_ft_cantidad * hp.hp_precio), 0)
    INTO v_total
    FROM det_fact_t dt
    JOIN HIST_PRECIOS hp ON dt.det_ft_prod = hp.hp_prod AND hp.hp_ffin IS NULL
    WHERE dt.det_ft_tienda_fact = p_ti_id
      AND dt.det_ft_fact = p_fact_num;
    
    p_msg := 'Exito. Factura FINALIZADA, lista para COMMIT. Total calculado: ' || v_total;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: No se encontro detalles para la factura.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_msg := 'Error al finalizar factura: ' || SQLERRM;
        ROLLBACK;
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
BEGIN
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

    p_fact_o_num := v_fact_num;
    p_msg := 'Exito. Cabecera online iniciada. Factura: ' || v_fact_num;
    
EXCEPTION
    WHEN OTHERS THEN
        p_msg := 'Error al iniciar cabecera online: ' || SQLERRM;
        p_fact_o_num := NULL;
        ROLLBACK;
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

    UPDATE factura_o
    SET fact_o_total = fact_o_total + v_subtotal
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
    
    e_total_cero EXCEPTION;
BEGIN
    SELECT SUM(df.det_fo_cantidad * hp.hp_precio), fo.fact_o_cli
    INTO v_total_detalles, v_cli_id
    FROM det_fact_o df
    JOIN hist_precios hp ON df.det_fo_prod = hp.hp_prod AND hp.hp_ffin IS NULL
    JOIN factura_o fo ON df.det_fo_fact = fo.fact_o_num
    WHERE df.det_fo_fact = p_fact_num
    GROUP BY fo.fact_o_cli;
    
    IF v_total_detalles IS NULL OR v_total_detalles <= 0 THEN
        RAISE e_total_cero;
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

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_msg := 'Error: Factura Online ' || p_fact_num || ' no encontrada o no tiene detalles válidos.';
        ROLLBACK;
    WHEN e_total_cero THEN
        p_msg := 'Error: Factura Online ' || p_fact_num || ' no tiene detalles o el total es cero.';
        ROLLBACK;
    WHEN OTHERS THEN
        ROLLBACK;
        p_msg := 'Error al finalizar factura online: ' || SQLERRM;
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
