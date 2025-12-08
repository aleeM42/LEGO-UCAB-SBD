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
--AUSTRALIA
insert into estados (ep_id, e_id, e_nom) 
values (43, estados_seq.nextval, 'QUEENSLAND');

insert into estados (ep_id, e_id, e_nom) 
values (43, estados_seq.nextval, 'SOUTH AUSTRALIA');

--ESTADOS UNIDOS
insert into estados (ep_id, e_id, e_nom) 
values (44, estados_seq.nextval, 'CONNECTICUT');

--REINO UNIDO
insert into estados (ep_id, e_id, e_nom) 
values (45, estados_seq.nextval, 'INGLATERRA');

--ALEMANIA
insert into estados (ep_id, e_id, e_nom) 
values (46, estados_seq.nextval,'SAXONY');

insert into estados (ep_id,e_id, e_nom) 
values (46, estados_seq.nextval, 'NORDRHEIN-WESTFALEN');

--IRLANDA
insert into estados (ep_id, e_id, e_nom) 
values (47, estados_seq.nextval, 'DUBLIN');

--PAISES BAJOS 
insert into estados (ep_id, e_id, e_nom) 
values (48, estados_seq.nextval, 'NORTH HOLLAND');


--DINAMARCA 
insert into estados (ep_id, e_id,  e_nom) 
values (49, estados_seq.nextval, 'JUTLANDIA');

COMMIT; 


--CIUDADES 
--AUSTRALIA - QUEENSLAND 
insert into ciudades (cp_id, ce_id, ciu_id, ciu_nom) 
values (43, 10, ciudades_seq.nextval, 'COOMERA');
--AUSTRALIA - SOUTH AUSTRALIA 
insert into ciudades (cp_id, ce_id, ciu_id, ciu_nom) 
values (43, 11, ciudades_seq.nextval, 'ADELAIDE');

--USA- CONNECTICUT
insert into ciudades (cp_id, ce_id, ciu_id, ciu_nom) 
values (44, 12, ciudades_seq.nextval, 'DANBURY');

--REINO UNIDO - INGLATERRA 
insert into ciudades (cp_id, ce_id, ciu_id, ciu_nom) 
values (45, 13, ciudades_seq.nextval, 'LONDRES');

-- ALEMANIA - SAXONY 
insert into ciudades (cp_id, ce_id, ciu_id, ciu_nom) 
values (46, 14, ciudades_seq.nextval, 'DRESDEN');

-- ALEMANIA - NORDRHEIN- WESTFALEN 
insert into ciudades (cp_id, ce_id, ciu_id, ciu_nom) 
values (46, 15, ciudades_seq.nextval, 'BONN');

-- IRLANDA - DUBLIN
insert into ciudades (cp_id, ce_id, ciu_id, ciu_nom) 
values (47, 16, ciudades_seq.nextval, 'DUBLIN');

-- PAISES BAJOS 
insert into ciudades (cp_id, ce_id, ciu_id, ciu_nom) 
values (48, 17, ciudades_seq.nextval, 'AMSTERDAM');

-- DINAMARCA -- JUTLANDIA 
insert into ciudades (cp_id, ce_id, ciu_id, ciu_nom) 
values (49, 18, ciudades_seq.nextval, 'BILLUND');

COMMIT; 

--- TOURS 
insert into tours (to_fini, to_cupos, to_costo)
values (TO_DATE('8-09-2025', 'DD-MM-YYYY'), 25, 3500);

insert into tours (to_fini, to_cupos, to_costo)
values (TO_DATE('01-10-2025', 'DD-MM-YYYY'), 25, 3500);

insert into tours (to_fini, to_cupos, to_costo)
values (TO_DATE('29-10-2025', 'DD-MM-YYYY'), 25, 3500);

insert into tours (to_fini, to_cupos, to_costo)
values (TO_DATE('19-11-2025', 'DD-MM-YYYY'), 25, 3500);

insert into tours (to_fini, to_cupos, to_costo)
values (TO_DATE('10-12-2025', 'DD-MM-YYYY'), 25, 3500);

commit;


