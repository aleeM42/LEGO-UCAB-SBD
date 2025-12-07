
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
CREATE OR REPLACE TRIGGER trg_validar_edad_inscripcion_tour
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
END trg_validar_edad_inscripcion_tour;
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

--trigger para verificar que la cantidad del producto se puede vender 

/*create or replace trigger verificar_stock
before insert on det_fact_t
for each ROW
declare 
    v_stock_dispo number;
begin
    select lot_stock into v_stock_dispo from lotes 
    where lot_prod = :new.det_ft_prod
    AND lot_idtem = :new.det_ft_idtem
    AND lot_tienda = :new.det_ft_tienda
    AND lot_id = :new.det_ft_lote;

    if v_stock_dispo < :new.det_fact.cantidad then
        raise_application_error(-20006, 'Stock insuficiente');
    end if;
end;
/*/


--trigger para verificar el limite del producto en el catalago
create or replace trigger verificar_lim_prod
before insert on det_fact_o
for EACH ROW
declare 
    v_limite number;
BEGIN
    
    select cat_limcom into v_limite from catalogos 
    where cat_prod = :new.det_fo_prod
    AND cat_prod_idtem = :new.det_fo_idtem
    AND cat_pais = :new.det_fo_pais;

    if :new.det_fo_cantidad > v_limite then
        raise_application_error(-20007, 'Se ha superado el limite de compra para este producto en el catalogo');
    end if;
end;
/


--trigger para el descuento de inventario 

create or replace trigger trg_descuento_inventario
after insert on det_fact_t
for each row 
begin 
    update lotes 
    set lot_stock = lot_stock - :new.det_ft_cantidad 
    where lot_prod = :new.det_ft_prod
    AND lot_idtem = :new.det_ft_idtem
    AND lot_tienda = :new.det_ft_tienda
    AND lot_id = :new.det_ft_lote;
end;
/

--trigger para descuentos manuales 

create or replace trigger descuentos_manuales 
after insert on descuentos 
for EACH ROW
BEGIN
    update lotes set lot_stock = lot_stock - :new.d_cantidad 
    where lot_id = :new.d_lote
    AND lot_idtem = :new.d_idtem
    AND lot_prod = :new.d_prod
    AND lot_tienda = :new.d_tienda;
end;
/


--trigger verificacion descuento manuales 

create or replace trigger desc_manuales 
before insert on descuentos 
for each row 
declare 
    v_stock number;
begin
    select lot_stock into v_stock from lotes 
    where lot_id = :new.d_lote
    AND lot_idtem = :new.d_idtem
    AND lot_prod = :new.d_prod
    AND lot_tienda = :new.d_tienda;

    if v_stock < :new.d_cantidad then 
        raise_application_error(-20007, 'Stock insuficiente para realizar el descuento manual');
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