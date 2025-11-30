-- funcion para verificar si pertenece a la UE

create or replace function es_ue(p_pais_id number) 
return varchar2 is
    v_ue paises.p%TYPE;
BEGIN
    select p_ue
    into v_ue 
    from paises where p_id = p_pais_id;
    return v_ue;
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



--trigger para pais de residencia de los f_lego
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

--trigger para pais de residencia de los clientes 

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

    if es_ue = 'NO' then
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


--funcion para calcular la edad
create or replace function edad (fecha_nacimiento date) 
RETURN number is 
BEGIN
    return trunc((months_between(sysdate, fecha_nacimiento) /12));
end;

