
---------------------------------- FUNCIONES -------------------------------------------


--funcion para calcular la edad
create or replace function edad (fecha_nacimiento date) 
RETURN number is 
BEGIN
    return trunc((months_between(sysdate, fecha_nacimiento) /12));
end;



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
    if p_fecha_tour < trunc(v_ano_actual) THEN
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
-----------------------------------------------------------
-- Validaciones de clientes 
-----------------------------------------------------------

-- funcion para obtener datos completos de un cliente 

 create or replace function obtner_cliente_info (p_cli_id number) 
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
        where c_cli_id = p_cli_id;
    return v_cursor;
end;

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

-- validar documentacion del cliente 

create or replace function fn_validar_documentacion_cliente (p_cli_id number)
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


-----------------------------------------------------------
-- Validaciones de fan lego
-----------------------------------------------------------

create or replace function validar_edad_fan_lego (p_fl_id number)
return boolean is
    v_fl_fnac f_lego.fl_fnacimiento%type;
    v_edad number; 
BEGIN

    select fl_fnacimiento into v_fl_fanc 
    from f_lego where fl_id = p_fl_id;

    v_edad := edad(v_fl_fnac);
    if v_edad < 12 or v_edad > 20 then
        raise_application_error(-20015, 'La edad del fan lego debe estar entre 12 y 20 anos');
    end if;
    return true;
end;

--- funcion para validar que tiene un representante asignado 

create or replace function validar_representante_fl (p_fl_id number) 
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







------------------------------------- TRIGGERS -------------------------------------------

--trigger para mantener precios actualizados 


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


--trigger para verificar que la cantidad del producto se puede vender 

create or replace trigger verificar_stock
before insert on det_fact_t
for each ROW
declare 
    v_stock_dispo number;
begin
    select lot_stock into v_stockv_stock_dispo from lotes 
    where lot_prod = :new.det_ft_prod
    AND lot_idtem = :new.det_ft_idtem
    AND lot_tienda = :new.det_ft_tienda
    AND lot_id = :new.det_ft_lote;

    if v_stock_dispo < :new.det_fact.cantidad then
        raise_application_error(-20006, 'Stock insuficiente');
    end if;
end;

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
            raise_application_error (-20000, "Si no pertenece a la Union europea debe indicar los datos de pasaporte");
        end if;
    end if;
end;



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

--trigger para verificar la edad del cliente en la factura online

create or replace trigger validar_edad_fact_o
before insert on factura_o
for each row
    declare 
    v_fnac clientes.cli_fnacimiento%type;
    v_edad number(2);
BEGIN
    select cli_fnacimiento into v_fnac from clientes where cli_id = :new.fact_o_cli;
    v_edad := edad(v_edad_cli);

    if v_edad < 21 then 
        raise_application_error(-20004, 'Solo los clientes mayores a 21 años pueden realizar compras');
    end if;
end;       


--trigger para verificar la edad del cliente en la factura de tienda 

create or replace trigger validar_edad_fact_t
before insert on factura_tf
for each row
    declare 
    v_fnac clientes.cli_fnacimiento%type;
    v_edad number(2);
BEGIN
    select cli_fnacimiento into v_fnac from clientes where cli_id = :new.fact_tf_cli;
    v_edad := edad(v_edad_cli);

    if v_edad < 21 then 
        raise_application_error(-20004, 'Solo los clientes mayores a 21 años pueden realizar compras');
    end if;
end;   


--trigger para no modificar la factura online

create or replace trigger no_modifcar_fact_o
before update on factura_o
begin
    raise_application_error(-20001, 'Las facturas online no pueden modificarse');
end;

--trigger para no eliminar facturas online
create or replace trigger no_eliminar_fact_o
before delete on factura_o
begin  
    raise_application_error(-20002, 'Las facturas online no pueden eliminarse');
end;

--trigger para no modificar la factura de tienda

create or replace trigger no_modifcar_fact_t
before update on factura_tf
begin
    raise_application_error(-20001, 'Las facturas de tienda no pueden modificarse');
end;

--trigger para no eliminar facturas de tienda
create or replace trigger no_eliminar_fact_t
before delete on factura_tf
begin  
    raise_application_error(-20002, 'Las facturas de tienda no pueden eliminarse');
end;



