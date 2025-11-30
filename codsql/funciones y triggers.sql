
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



------------------------------------- TRIGGERS -------------------------------------------



--trigger para mantener precios actualizados 





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




