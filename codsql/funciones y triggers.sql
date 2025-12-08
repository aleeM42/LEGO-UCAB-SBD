
---------------------------------- FUNCIONES -------------------------------------------


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

--funcion para calcular el total
create or replace function calcular_total (p_fact_num number)
return number is 
    v_total number := 0;
begin 
    SELECT nvl(sum(hp.hp_precio * d.det_ft_cantidad), 0) 
    into v_total 
    from factura_tf f 
    JOIN det_fact_t d ON d.det_ft_fact = f.fact_tf_num
    JOIN lotes l ON l.lot_prod = d.det_ft_prod
    AND  l.lot_idtem = d.det_ft_idtem
    AND l.lot_tienda = d.det_ft_tienda
    AND l.lot_id = d.det_ft_lote
    JOIN hist_precios hp ON hp.hp_prod = l.lot_prod
    AND hp.hp_idtem = l.lot_idtem 
    ANd f.fact_tf_femision BETWEEN hp.hp_fini AND nvl(hp.hp_ffin, f.fact_tf_femision)
    where f.fact_tf_num = p_fact_num;

    RETURN v_total;
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

    return (sysdate <= v_fecha_limite);
end;
/

--funcion para validar disponibilidad del tour (fecha valida con cupos)
CREATE OR REPLACE FUNCTION fn_tour_disponible(p_tour_fecha IN DATE) 
RETURN BOOLEAN IS
    v_tour_existe NUMBER;
    v_tour_futuro BOOLEAN;
BEGIN
    SELECT COUNT(*) INTO v_tour_existe
    FROM tours
    WHERE to_fini = p_tour_fecha;
    
    IF v_tour_existe = 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Validar que la fecha del tour es en el futuro
    v_tour_futuro := (p_tour_fecha > SYSDATE);
    
    RETURN v_tour_futuro;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20809, 'Error validando disponibilidad tour: ' || SQLERRM);
END fn_tour_disponible;
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

-- Función para validar si tour tiene cupos disponibles
CREATE OR REPLACE FUNCTION fn_validar_cupos_tour(
    p_tour_fecha IN DATE,
    p_cantidad_solicitada IN NUMBER
) RETURN BOOLEAN
IS
    v_cupos_disponibles NUMBER;
    v_cupos_totales NUMBER;
    v_inscritos NUMBER;
BEGIN
    -- Obtener cupos totales del tour
    SELECT to_cupos INTO v_cupos_totales
    FROM tours
    WHERE to_fini = p_tour_fecha;
    
    -- Contar inscritos en el tour
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

------------------------------------------------------------------------------------------
------------------------------------- TRIGGERS -------------------------------------------
------------------------------------------------------------------------------------------

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

--trigger para prevenir eleiminacion de inscripcion pagada 
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
begin
    if not exists (select 1 from tours where to_fini = :new.ins_tour) then 
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
    -- estoy igualando mi variable local a la funcion de es_ue, pasando como parametro
    -- la fk de cli.nac que va con id pais
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

--trigger para recargo de envio por pais de residencia de los clientes 
create or replace trigger residencia_clientes
before insert on factura_o
for each row
    declare 
    v_pais_reside clientes.cli_reside%type; 
    v_es_ue varchar2(2);
BEGIN
    select cli_reside into v_pais_reside from clientes 
    where cli_id = :new.fact_o_cli;

    v_es_ue := es_ue(v_pais_reside);

    if v_es_ue = 'NO' then
        :new.fact_o_total := :new.fact_o_total *  1.15;
    else 
        :new.fact_o_total := :new.fact_o_total * 1.05;

    end if;
end;        
/

--trigger para verificar la edad del cliente en la factura online
create or replace trigger validar_edad_fact_o
before insert on factura_o
for each row
    declare 
    v_fnac clientes.cli_fnacimiento%type;
    v_edad number(2);
BEGIN
    select cli_fnacimiento into v_fnac from clientes where cli_id = :new.fact_o_cli;
    v_edad := edad(v_fnac);

    if v_edad < 21 then 
        raise_application_error(-20004, 'Solo los clientes mayores a 21 años pueden realizar compras');
    end if;
end;       
/

--trigger para verificar la edad del cliente en la factura de tienda 
create or replace trigger validar_edad_fact_t
before insert on factura_tf
for each row
    declare 
    v_fnac clientes.cli_fnacimiento%type;
    v_edad number(2);
BEGIN
    select cli_fnacimiento into v_fnac from clientes where cli_id = :new.fact_tf_cli;
    v_edad := edad(v_fnac);

    if v_edad < 21 then 
        raise_application_error(-20004, 'Solo los clientes mayores a 21 años pueden realizar compras');
    end if;
end;   
/

--trigger para no modificar la factura online
create or replace trigger no_modifcar_fact_o
before update on factura_o
begin
    raise_application_error(-20001, 'Las facturas online no pueden modificarse');
end;
/

--trigger para no eliminar facturas online
create or replace trigger no_eliminar_fact_o
before delete on factura_o
begin  
    raise_application_error(-20002, 'Las facturas online no pueden eliminarse');
end;
/

--trigger para no modificar la factura de tienda
create or replace trigger no_modifcar_fact_t
before update on factura_tf
begin
    raise_application_error(-20001, 'Las facturas de tienda no pueden modificarse');
end;
/

--trigger para no eliminar facturas de tienda
create or replace trigger no_eliminar_fact_t
before delete on factura_tf
begin  
    raise_application_error(-20002, 'Las facturas de tienda no pueden eliminarse');
end;
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
    p_primer_nombre in varchar2,
    p_segundo_nombre in varchar2,
    p_primer_apellido in varchar2,
    p_segundo_apellido in varchar2,
    p_documento_id in number,
    p_fecha_nacimiento in date,
    p_pais_nacionalidad in number, 
    p_numero_pasaporte in number default null,
    p_fecha_vencimiento_pasaporte in date default null,
    p_cliente_id out number,
    p_mensaje out varchar2
)
is 
    v_edad number;
    v_requiere_pas boolean;
    v_ue varchar2(2);
begin
    --validaciones
    v_edad := edad(p_fecha_nacimiento);

    --validar edad
    if v_edad < 21 then 
        raise_application_error(-20901, 'Cliente debe ser mayor de 21 años par registrarse'); 
    end if;

    --validar que el documento no exista
    if exists (select 1 from clientes where cli_dni = p_documento_id) then 
        raise_application_error(-20902, 'Cliente con este documento ya esta registrado');
    end if;

    --Validar pasaporte para no-UE
    select p_ue into v_ue from paises where p_id = p_pais_nacionalidad;

    if v_ue = 'NO' then 
        if p_numero_pasaporte is null or p_fecha_vencimiento_pasaporte is null then 
            raise_application_error(-20903, 
                'Ciudadanos no-UE deben proporcionar datos de pasaporte');
        end if;

        if p_fecha_vencimiento_pasaporte <= sysdate then
            raise_application_error(-20904, 
                'Pasaporte debe estar vigente'); 
        end if;
    end if;
    -- generar nuevo cliente 

    select clientes_seq.nextval into p_cliente_id from dual; 
    insert into clientes (cli_id, cli_pnombre, cli_papellido, cli_sapellido, cli_dni,
        cli_fnacimiento, cli_nac, cli_reside, cli_snombre, cli_numpas, cli_fvenpas
    )
    values (
        p_cliente_id, p_primer_nombre, p_primer_apellido, p_segundo_apellido,
        p_documento_id, p_fecha_nacimiento, p_pais_nacionalidad, p_pais_nacionalidad,
        p_segundo_nombre, p_numero_pasaporte, p_fecha_vencimiento_pasaporte
    );

    p_mensaje := 'Cliente registrado exitosamente. ID: ' || p_cliente_id;
    COMMIT;
    
end;
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
    
    -- 3. VALIDAR CLIENTE RESPONSABLE
    IF NOT EXISTS(SELECT 1 FROM clientes WHERE cli_id = p_cliente_responsable) THEN
        RAISE_APPLICATION_ERROR(-20913, 
            'Cliente responsable no existe');
    END IF;
    
    -- 4. VALIDAR EDAD CLIENTE RESPONSABLE >= 21 AÑOS
    SELECT TRUNC((SYSDATE - cli_fnacimiento) / 365.25)
    INTO v_cliente_edad
    FROM clientes WHERE cli_id = p_cliente_responsable;
    
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
                
                -- Crear entrada
                INSERT INTO entradas_tour (
                    ent_insc, ent_id, ent_tipo_asistente
                ) VALUES (
                    p_numero_inscripcion, v_contador, v_tipo_asistente
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

--================================================================================
-- 5. VISTA CONSOLIDADA DE TOURS
--================================================================================

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

--================================================================================
-- 6. ÍNDICES PARA OPTIMIZACIÓN
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
-- 7. PROCEDIMIENTOS DE REPORTE PARA TOURS
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
