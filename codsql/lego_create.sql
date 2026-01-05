--secuencias para paises, estados y ciudades
create sequence paises_seq start with 1 increment by 1;
create sequence estados_seq start with 1 increment by 1;
create sequence ciudades_seq start with 1 increment by 1;

create table paises (
    p_id number(4) primary key,
    p_nom varchar2(30) not null,
    p_con varchar2(30) not null, 
    p_ue varchar2(2) not null, 
    p_nac varchar2(30) not null, 

    constraint ck_peu check (p_ue in('SI','NO')),
    constraint ck_con check (p_con in('AFRICA','AMERICA','ASIA','EUROPA','OCEANIA'))
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
);

--secuencias para temas, productos
create sequence temas_seq start with 1 increment by 1;
create sequence productos_seq start with 1 increment by 1;

create table temas (
    te_id number(4) primary key,
    te_nom varchar2(30) not null unique,
    te_tipo varchar2(10) not null,
    te_desc varchar2(800) not null,
    te_padre number(4) null,

    constraint fk_temasre foreign key (te_padre) references temas(te_id),
    constraint check_tipot check (te_tipo in('SERIE','TEMA'))
);

CREATE TABLE productos (   
    pro_cod NUMBER(4) DEFAULT ON NULL productos_seq.NEXTVAL NOT NULL,
    pro_idtem NUMBER(4) NOT NULL,
    pro_nom VARCHAR2(100) NOT NULL, 
    pro_desc VARCHAR2(2000) NOT NULL, 
    pro_raned VARCHAR2(8) NOT NULL, 
    pro_ranpr VARCHAR2(4) NOT NULL, 
    pro_set VARCHAR2(2) NOT NULL, 
    pro_instr VARCHAR2(15), 
    pro_piecs NUMBER(5), 
    set_id NUMBER(4), 
    
    CONSTRAINT pk_productos PRIMARY KEY(pro_cod), 
    CONSTRAINT fk_temaprod FOREIGN KEY (pro_idtem) REFERENCES temas(te_id),
    CONSTRAINT f_set FOREIGN KEY (set_id) REFERENCES productos (pro_cod), 
    CONSTRAINT ck_setprod CHECK (pro_set IN( 'SI','NO')) 
);          
 
--secuencia para clientes y fans lego
create sequence clientes_seq start with 1 increment by 1;
create sequence f_lego_seq start with 1 increment by 1;

create table clientes (
    cli_id number(4) primary key,
    cli_pnombre varchar2(30) not null,
    cli_papellido varchar2(30) not null,
    cli_sapellido varchar2(30) not null,
    cli_dni number(12) not null,
    cli_fnacimiento date not null,
    cli_nac number(4)  not null,
    cli_reside number(4) not null,
    cli_numpas NUMBER(10),
    cli_fvenpas date,
    cli_snombre varchar2(30),

    constraint fk_residecliente foreign key (cli_reside) references paises(p_id),
    constraint fk_pais foreign key (cli_nac) references paises(p_id)
    --si la nac pertenece a la eu no necesita pasaporte
    --constraint de check con la funcion edad
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
    --si no pertenece a la eu deben estar los datos del pasaporte 
    --constraint de check con la funcion edad
);

--secuencia para tiendas
create sequence tiendas_seq start with 1 increment by 1;

create table tiendas (
    ti_id number(4) primary key,
    ti_nom varchar2(30) not null,
    ti_dic varchar2(200) not null,
    ti_tel varchar2(50) not null,
    ti_ciu number(4) not null,
    ti_pais number(4) not null,
    ti_estado number(4) not null,

    constraint fk_pais_tienda foreign key (ti_pais) references paises (p_id),
    constraint fk_estado_tienda foreign key (ti_pais, ti_estado) references estados (ep_id, e_id),
    constraint f_ciudad foreign key(ti_pais, ti_estado, ti_ciu) references ciudades (cp_id, ce_id, ciu_id)
);

create table horarios (
    h_tid number(4) not null,
    h_dia number(1) not null,    
    h_aper varchar2(5) not null,
    h_cier varchar2(5) not null, 
    constraint pk_horarios primary key (h_dia, h_tid),
    constraint fk_tienda foreign key (h_tid) references tiendas(ti_id) 
    --hacer conversion de date a hora
);

CREATE TABLE prod_rela (
    rela_prod_cod NUMBER(4) NOT NULL,
    rela_prod_idtem NUMBER(4) NOT NULL,
    rela_idtem NUMBER(4) NOT NULL,
    rela_setcod NUMBER(4) NOT NULL,

    CONSTRAINT pk_prodrela PRIMARY KEY (
        rela_prod_cod,
        rela_prod_idtem,
        rela_setcod,
        rela_idtem
    ),

    CONSTRAINT fk_prodrela FOREIGN KEY (rela_prod_cod)
        REFERENCES productos (pro_cod),

    CONSTRAINT fk_prodrela_rel FOREIGN KEY (rela_setcod)
        REFERENCES productos (pro_cod)
);



CREATE TABLE catalogos (   
    cat_prod NUMBER(4) NOT NULL,
    cat_pais NUMBER(4) NOT NULL,
    cat_limcom NUMBER(3) NOT NULL,

    CONSTRAINT pk_catalogo PRIMARY KEY (cat_prod,cat_pais),
    CONSTRAINT fk_catprod FOREIGN KEY (cat_prod) REFERENCES productos (pro_cod),
    CONSTRAINT fk_catpais FOREIGN KEY (cat_pais) REFERENCES paises (p_id)
);

 
--entidades entrada salida
 
CREATE TABLE hist_precios (
    hp_prod NUMBER(10, 0) NOT NULL,
    hp_fini DATE NOT NULL,
    hp_precio NUMBER(10, 2) NOT NULL,
    hp_ffin DATE,

    CONSTRAINT pk_histprecio PRIMARY KEY (hp_prod, hp_fini),
    CONSTRAINT fk_prodhistpre FOREIGN KEY (hp_prod) REFERENCES productos (pro_cod)
);


--secuencia para lotes y descuentos
create sequence lotes_seq start with 1 increment by 1;
create sequence descuentos_seq start with 1 increment by 1;

CREATE TABLE lotes ( 
    lot_prod NUMBER(4) NOT NULL,
    lot_tienda NUMBER(4) NOT NULL,
    lot_id NUMBER(4) DEFAULT ON NULL lotes_seq.NEXTVAL NOT NULL,
    lot_stock NUMBER(4) NOT NULL, 

    CONSTRAINT fk_loteprod FOREIGN KEY (lot_prod) REFERENCES productos (pro_cod),
    CONSTRAINT fk_lotetienda FOREIGN KEY (lot_tienda) REFERENCES tiendas (ti_id),
    CONSTRAINT pk_lote PRIMARY KEY (lot_tienda, lot_prod, lot_id)
);


CREATE TABLE descuentos (
    d_lote NUMBER(4) NOT NULL,
    d_prod NUMBER(4) NOT NULL,
    d_tienda NUMBER(4) NOT NULL,
    d_id NUMBER(4) DEFAULT ON NULL descuentos_seq.NEXTVAL NOT NULL,
    d_fecha DATE NOT NULL,
    d_cantidad NUMBER(10) NOT NULL,

    CONSTRAINT pk_descuento PRIMARY KEY (d_lote, d_tienda, d_prod, d_id),
    CONSTRAINT fk_lotedesc FOREIGN KEY (d_prod, d_tienda, d_lote) REFERENCES lotes (lot_prod, lot_tienda, lot_id)
);


--secuencia pra inscripciones y entradas 
create sequence inscripciones_seq start with 1 increment by 1;
create sequence entradas_seq start with 1 increment by 1;

create table inscripciones ( 
    ins_num number(4) primary key,
    ins_femision date not null,
    ins_total number(5) not null,
    ins_estado varchar2(15) not null,
    ins_tour date not null,

    constraint check_estado check(ins_estado in ('PENDIENTE', 'PAGO')),
    constraint fk_inscriptour foreign key (ins_tour) references tours (to_fini)
);

create table entradas_tour (
    ent_insc number(4) not null,
    ent_id number(4) not null,
    ent_tipo_asistente varchar2(10) not null,

    constraint fk_entradainscripcion foreign key (ent_insc) references inscripciones (ins_num),
    constraint pk_entradas primary key (ent_insc, ent_id),
    constraint chk_tipoasistenteent check (ent_tipo_asistente in('ADULTO', 'MENOR')) 
);

--secuencia para detalle inscripcion
create sequence det_inscrip_seq start with 1 increment by 1;

create table det_inscrip (
    det_ins_id number(4) primary key,
    det_ins_ins number(4) not null,
    det_ins_tipo varchar2(15) not null,
    det_ins_fan number(4), 
    det_ins_cli number(4),

    constraint fk_detins_fanlego foreign key (det_ins_fan) references f_lego (fl_id),
    constraint fk_detins_cliente foreign key (det_ins_cli) references clientes (cli_id),
    constraint fk_inscripciondet foreign key (det_ins_ins) references inscripciones (ins_num),
    constraint ck_tipo_cliente check (det_ins_tipo in ('MENOR', 'ADULTO')),
    constraint chek_arcoexc check(
    (det_ins_fan is not null and det_ins_cli is null)
    or (det_ins_fan is null and det_ins_cli is not null)) 
);

--secuencia para facturas
create sequence factura_tf_seq start with 1 increment by 1;
create sequence factura_o_seq start with 1 increment by 1;

CREATE TABLE factura_tf( 
    fact_tf_num NUMBER(4) DEFAULT ON NULL factura_tf_seq.NEXTVAL NOT NULL,
    fact_tf_femision DATE NOT NULL,
    fact_tf_total NUMBER(5) NOT NULL,
    fact_tf_cli NUMBER(4) NOT NULL,
    fact_tf_tie NUMBER(4) NOT NULL,

    CONSTRAINT fk_tienda_fact FOREIGN KEY (fact_tf_tie) REFERENCES tiendas (ti_id),
    CONSTRAINT fk_cliente_fact_tf FOREIGN KEY (fact_tf_cli) REFERENCES clientes (cli_id),
    CONSTRAINT pk_facturatf PRIMARY KEY (fact_tf_tie, fact_tf_num)
);


CREATE TABLE factura_o (
    fact_o_num NUMBER(10, 0) DEFAULT ON NULL factura_o_seq.NEXTVAL PRIMARY KEY,
    fact_o_femision DATE NOT NULL, 
    fact_o_total NUMBER(10, 2) NOT NULL,
    fact_o_puntosgen NUMBER(5, 0) NOT NULL,
    fact_o_cli NUMBER(10, 0) NOT NULL,
    venta_gratis VARCHAR(2), 

    CONSTRAINT ck_ventagrat CHECK (venta_gratis IN ('SI','NO')),
    CONSTRAINT fk_cliente_facto FOREIGN KEY (fact_o_cli) REFERENCES clientes (cli_id)
);


--secuencia para detalle factura
create sequence det_fact_tf_seq start with 1 increment by 1;
create sequence det_fact_o_seq start with 1 increment by 1;

CREATE TABLE det_fact_t ( 
    det_ft_id NUMBER(4) DEFAULT ON NULL det_fact_tf_seq.NEXTVAL NOT NULL, 
    det_ft_cantidad NUMBER(4) NOT NULL,
    det_ft_tipo_cli VARCHAR2(8), 
    det_ft_fact NUMBER(4) NOT NULL, 
    det_ft_tienda_fact NUMBER(4) NOT NULL,    
    det_ft_lote NUMBER(4) NOT NULL,
    det_ft_prod NUMBER(4) NOT NULL,
    det_ft_tienda_lote NUMBER(4) NOT NULL,

    CONSTRAINT fk_fact_det_fact_tf FOREIGN KEY (det_ft_tienda_fact, det_ft_fact)  REFERENCES factura_tf(fact_tf_tie, fact_tf_num),
    CONSTRAINT fk_factdet_lote FOREIGN KEY (det_ft_prod, det_ft_tienda_lote, det_ft_lote) REFERENCES lotes (lot_prod, lot_tienda, lot_id),
    CONSTRAINT pk_det_facturatf PRIMARY KEY (det_ft_tienda_fact, det_ft_fact, det_ft_id)
);

CREATE TABLE det_fact_o (
    det_fo_fact NUMBER(10, 0) NOT NULL,
    det_fo_pais NUMBER(10, 0) NOT NULL,
    det_fo_prod NUMBER(10, 0) NOT NULL,
    det_fo_id  NUMBER(10, 0) DEFAULT ON NULL det_fact_o_seq.NEXTVAL NOT NULL, 
    det_fo_cantidad NUMBER(10, 0) NOT NULL,
    det_fo_tipo_cli VARCHAR2(10) NOT NULL,

    CONSTRAINT pk_det_facturaO PRIMARY KEY (det_fo_fact, det_fo_id),
    CONSTRAINT fk_fact_det_fact_o FOREIGN KEY (det_fo_fact) REFERENCES factura_o(fact_o_num),
    CONSTRAINT fk_factdet_cat FOREIGN KEY (det_fo_prod, det_fo_pais) REFERENCES catalogos (cat_prod, cat_pais)
);

--secuencia para auditoria tours 
create sequence auditoria_tours_seq start with 1 increment by 1;

create table auditoria_tours (
    aud_id number(4) primary key,
    aud_fecha date not null, 
    aud_inscripcion_num number not null,
    aud_tipo_evento varchar2(30) not null,
    aud_descripcion varchar2(200), 

    constraint fk_aud_tour_insc foreign key (aud_inscripcion_num) references inscripciones (ins_num),
    constraint ck_tipo_evento_aud_tour check(aud_tipo_evento in ('INSCRIPCION_CREADA', 'PAGO_CONFIRMADO', 'CAMBIO_ESTADO', 'ENTRADA_GENERADA'))  
);

