create table paises (
p_id number(4) primary key,
p_nom varchar2(30) not null,
p_con varchar2(30) not null, 
p_ue boolean not null, 
p_nac varchar2(30) not null
); 

create table estados (
ep_id number(4) not null,
e_id number(4) not null, 
e_nom varchar2(30) not null,
constraint pk_estado primary key (ep_id, e_id), 
constraint fk_estados foreign key (ep_id) references paises(p_id)
);

create table ciudades (
cp_id number(4) not null, 
ce_id number(4) not null,
ciu_id number(4) not null, 
ciu_nom varchar2(30) not null,
constraint pk_ciudades primary key (cp_id, ce_id, ciu_id),
constraint fk_ciudades foreign key (cp_id, ce_id) references estados(ep_id, e_id) 
);

create table tours (
to_fini date primary key,
to_cupos number(3) not null,
to_costo number(5) not null
//fk inscripiciones
);

create table temas (
te_id number(4) primary key,
te_nom varchar2(30) not null unique,
te_tipo varchar2(10) not null,
te_desc varchar2(100) not null,
constraint fk_temasre foreign key (parent_id) references temas(te_id),
constraint check_tipot check (te_tipo in('SERIE','TEMA'))
);

create table productos (
pro_idtem number(4) not null,
pro_cod number(4) not null unique,
pro_nom varchar2(15) not null,
pro_desc varchar2(100) not null,
pro_raned number(2) not null,
pro_ranpr number(4) not null,
pro_set boolean not null,
pro_instr varchar2(15),
pro_piecs number(5), 
constraint pk_productos primary key(pro_idtem, pro_cod),
constraint fk_temaprod foreign key (pro_idtem) references temas(te_id),
constraint f_set foreign key (id_set, set_idtem) references productos (pro_idtem, pro_cod)
);            
 
create table clientes (
cli_id number(4) primary key,
cli_pnombre varchar2(30) not null,
cli_papellido varchar2(30) not null,
cli_sapellido varchar2(30) not null,
cli_dni number(12) not null,
cli_fnacimiento date not null,
cli_nac varchar  not null,
cli_numpas NUMBER(10),
cli_fvenpas date,
cli_snombre number(4),
constraint fk_pais foreign key (cli_nac) references paises(p_id)
//si la nac pertenece a la eu no necesita pasaporte
);

create table f_lego (
fl_id number(4) primary key,
fl_pnombre varchar2(30) not null,
fl_papellido varchar2(30) not null,
fl_sapellido varchar2(30) not null,
fl_dni number(12) not null,
fl_fnacimiento date not null,
fl_nac number(4) not null,
fl_numpas NUMBER(10),
fl_fvenpas date,
fl_snombre varchar2(30),
fl_repre number(4), 
constraint f_repre foreign key (fl_repre) references clientes(cli_id),
constraint f_nac foreign key(fl_nac) references paises(p_id)
//si no pertenece a la eu deben estar los datos del pasaporte 
);

create table tiendas (
ti_id number(4) primary key,
ti_nom varchar2(30) not null,
ti_dic varchar2(30) not null,
ti_tel number(12) not null,
ti_ciu number(4) not null,
constraint f_ciudad foreign key(ti_ciu) references ciuds (ciu_id)
);

create table horarios (
h_tid number(4) not null,
h_dia date not null,
h_aper date not null,
h_cier date not null, 
constraint pk_horarios primary key (h_dia, h_tid),
constraint fk_tienda foreign key (h_tid) references tiendas(ti_id) 
//hacer conversion de date a hora
);

//revisar porque creo que esta mal
create table prod_rela (
rela_prodcod number(4) not null,
rela_setcod number(4) not null,

constraint pk_prodrela primary key (rela_prodcod, rela_setcod),
constraint fk_prodrela foreign key (rela_prodcod, rela_setcod) references productos (pro_cod, pro_temid )
);

create table catalogos (
cat_prod number(4) not null,
cat_pais number(4) not null,
cat_limcom number(3) not null,

constraint pk_catalogo primary key (cat_prod, cat_pais),
constraint fk_catprod foreign key (cat_prod) references productos (pro_cod, pro_idtem),
constraint fk_catpais foreign key (cat_pais) references paises (p_id)
);
 
 //entidades entrada salida
 
create table hist_precios (
hp_prod number(4) not null,
hp_fini date not null,
hp_precio number(4) not null,
hp_ffin date,
constraint pk_histprecio primary key (hp_prod, hp_ini),
constraint fk_prodhistpre foreign key (hp_prod) references productos (pro_cod, pro_idtem)
);

create table lotes (
lot_prod number(4) not null,
lot_tienda number(4) not null,
lot_id number(4) not null,
lot_stock number(4) not null, 

constraint pk_lote primary key (lot_prod, lot_tienda, lot_id),
constraint fk_loteprod foreign key (lot_prod) references productos (pro_cod, pro_idtem),
constraint fk_lotetienda foreign key (lot_tienda) references tiendas (ti_id)
);

create table descuentos (
d_lote number(4) not null,
d_id number(4) not null,
d_fecha date not null,
d_cantidad number(10) not null,

constraint pk_descuento primary key (d_lote, d_id),
constraint fk_lotedesc foreign key (d_lote) references lotes (lot_prod, lot_tienda, lot_id)
);

create table inscripciones ( 
ins_num number(4) primary key,
ins_femision date not null,
ins_total number(5) not null,
ins_estado varchar2(15) not null,
ins_tour number(4) not null,
constraint check_estado check(ins_estado in ('PENDIENTE', 'PAGO')),
constraint fk_inscriptour foreign key (ins_tour) references tours (to_fini)
);