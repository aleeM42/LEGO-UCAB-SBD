--paises donde hay tiendas 

insert into paises (p_id, p_nom, p_con, p_ue, p_nac) 
values (paises_seq.nextval, 'AUSTRALIA', 'OCEANIA', 'NO', 'AUSTRALIANO');

insert into paises (p_id, p_nom, p_con, p_ue, p_nac) 
values (paises_seq.nextval, 'ESTADOS UNIDOS', 'AMERICA', 'NO', 'ESTADOUNIDENSE');

insert into paises (p_id, p_nom, p_con, p_ue, p_nac) 
values (paises_seq.nextval, 'REINO UNIDO', 'EUROPA', 'SI', 'BRITANICO');

insert into paises (p_id, p_nom, p_con, p_ue, p_nac) 
values (paises_seq.nextval, 'ALEMANIA', 'EUROPA', 'SI', 'ALEMAN');

insert into paises (p_id, p_nom, p_con, p_ue, p_nac) 
values (paises_seq.nextval, 'IRLANDA', 'EUROPA', 'SI', 'IRLANDES');

insert into paises (p_id, p_nom, p_con, p_ue, p_nac) 
values (paises_seq.nextval, 'PAISES BAJOS', 'EUROPA', 'SI', 'HOLANDES');

--pais del tour 
insert into paises (p_id, p_nom, p_con, p_ue, p_nac) 
values (paises_seq.nextval, 'DINAMARCA', 'EUROPA', 'SI', 'DINAMARQUENSE');

commit; 
select p_id, p_nom from paises order by p_id; 
--------------------estados por pais donde hay tiendas------------
--- AUSTRALIA
