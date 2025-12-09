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

-----ESTADOS DE LOS PAISES -----
-- AUSTRALIA
INSERT INTO ESTADOS (ep_id, e_id, e_nom)
VALUES (
    (SELECT p_id FROM PAISES WHERE p_nom = 'AUSTRALIA'),
    estados_seq.NEXTVAL,
    'QUEENSLAND'
);

INSERT INTO ESTADOS (ep_id, e_id, e_nom)
VALUES (
    (SELECT p_id FROM PAISES WHERE p_nom = 'AUSTRALIA'),
    estados_seq.NEXTVAL,
    'AUSTRALIA DEL SUR'
);

-- ESTADOS UNIDOS
INSERT INTO ESTADOS (ep_id, e_id, e_nom)
VALUES (
    (SELECT p_id FROM PAISES WHERE p_nom = 'ESTADOS UNIDOS'),
    estados_seq.NEXTVAL,
    'CONNECTICUT'
);

-- REINO UNIDO
INSERT INTO ESTADOS (ep_id, e_id, e_nom)
VALUES (
    (SELECT p_id FROM PAISES WHERE p_nom = 'REINO UNIDO'),
    estados_seq.NEXTVAL,
    'INGLATERRA'
);

-- ALEMANIA
INSERT INTO ESTADOS (ep_id, e_id, e_nom)
VALUES (
    (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'),
    estados_seq.NEXTVAL,
    'SAJONIA'
);

INSERT INTO ESTADOS (ep_id, e_id, e_nom)
VALUES (
    (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'),
    estados_seq.NEXTVAL,
    'RENANIA DEL NORTE-WESTFALIA'
);

-- IRLANDA
INSERT INTO ESTADOS (ep_id, e_id, e_nom)
VALUES (
    (SELECT p_id FROM PAISES WHERE p_nom = 'IRLANDA'),
    estados_seq.NEXTVAL,
    'LEINSTER'
);

-- PAISES BAJOS
INSERT INTO ESTADOS (ep_id, e_id, e_nom)
VALUES (
    (SELECT p_id FROM PAISES WHERE p_nom = 'PAISES BAJOS'),
    estados_seq.NEXTVAL,
    'ZUID-HOLLAND'
);

COMMIT;



--CIUDADES 
-- AUSTRALIA - QUEENSLAND
INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'COOMERA'
FROM PAISES p
JOIN ESTADOS e ON p.p_id = e.ep_id
WHERE p.p_nom = 'AUSTRALIA'
  AND e.e_nom = 'QUEENSLAND';

-- AUSTRALIA - AUSTRALIA DEL SUR (OAKLANDS PARK)
INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'OAKLANDS PARK'
FROM PAISES p
JOIN ESTADOS e ON p.p_id = e.ep_id
WHERE p.p_nom = 'AUSTRALIA'
  AND e.e_nom = 'AUSTRALIA DEL SUR';

-- ESTADOS UNIDOS - CONNECTICUT (DANBURY)
INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'DANBURY'
FROM PAISES p
JOIN ESTADOS e ON p.p_id = e.ep_id
WHERE p.p_nom = 'ESTADOS UNIDOS'
  AND e.e_nom = 'CONNECTICUT';

-- REINO UNIDO - INGLATERRA (LONDRES)
INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'LONDRES'
FROM PAISES p
JOIN ESTADOS e ON p.p_id = e.ep_id
WHERE p.p_nom = 'REINO UNIDO'
  AND e.e_nom = 'INGLATERRA';

-- ALEMANIA - RENANIA DEL NORTE-WESTFALIA (BONN)
INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'BONN'
FROM PAISES p
JOIN ESTADOS e ON p.p_id = e.ep_id
WHERE p.p_nom = 'ALEMANIA'
  AND e.e_nom = 'RENANIA DEL NORTE-WESTFALIA';

-- ALEMANIA - SAJONIA (DRESDEN)
INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'DRESDEN'
FROM PAISES p
JOIN ESTADOS e ON p.p_id = e.ep_id
WHERE p.p_nom = 'ALEMANIA'
  AND e.e_nom = 'SAJONIA';

-- IRLANDA - LEINSTER (BLANCHARDSTOWN)
INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'BLANCHARDSTOWN'
FROM PAISES p
JOIN ESTADOS e ON p.p_id = e.ep_id
WHERE p.p_nom = 'IRLANDA'
  AND e.e_nom = 'LEINSTER';

-- PAISES BAJOS - ZUID-HOLLAND (LEIDSCHENDAM)
INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'LEIDSCHENDAM'
FROM PAISES p
JOIN ESTADOS e ON p.p_id = e.ep_id
WHERE p.p_nom = 'PAISES BAJOS'
  AND e.e_nom = 'ZUID-HOLLAND';

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

--- inserts para temas 
-- SERIES RAÍZ
INSERT INTO TEMAS (te_id, te_nom, te_tipo, te_desc, te_padre)
VALUES (
    temas_seq.NEXTVAL,
    'PRODUCTOS PARA PREESCOLARES',
    'SERIE',
    'Nuestros juguetes de construcción preescolares, que están diseñados para que los más pequeños los puedan montar con facilidad, animan a los peques a pasar horas apilando, clasificando y construyendo. Estos sets pueden ayudar a los bebés a desarrollar su motricidad fina, su confianza en el juego y muchas otras cosas. Te ofrecemos una amplia variedad de set diseñados específicamente para preescolares, tanto si buscas juguetes que desarrollen la coordinación oculomanual y la destreza, como sets que fomenten el conocimiento emocional o que ayuden a aprender a contar, el abecedario y mucho más. ',
    NULL
);

INSERT INTO TEMAS (te_id, te_nom, te_tipo, te_desc, te_padre)
VALUES (
    temas_seq.NEXTVAL,
    'CONSTRUCCIÓN CREATIVA',
    'SERIE',
    'Productos enfocados en la construcción libre y el fomento de la creatividad.',
    NULL
);

INSERT INTO TEMAS (te_id, te_nom, te_tipo, te_desc, te_padre)
VALUES (
    temas_seq.NEXTVAL,
    'TEMAS DE JUEGO',
    'SERIE',
    'Nuestros Temas de Juego giran en torno a historias, escenarios y profesiones específicas, invitando a los niños a imaginar y recrear mundos complejos. Desde estaciones de policía y bomberos hasta aeropuertos y castillos, estos sets ofrecen una base rica para el juego de roles y la narración. Los niños pueden construir y poblar sus propias ciudades, resolver desafíos y dar vida a sus fantasías, fomentando la creatividad narrativa y las habilidades sociales a través del juego dirigido.',
    NULL
);

INSERT INTO TEMAS (te_id, te_nom, te_tipo, te_desc, te_padre)
VALUES (
    temas_seq.NEXTVAL,
    'PRODUCTOS BAJO LICENCIA',
    'SERIE',
    'Esta serie incluye Temas de Juego basados en propiedades intelectuales populares como películas, series de televisión y cómics, cuyas licencias han sido adquiridas. Los diseñadores de LEGO recrean meticulosamente los universos, personajes y vehículos icónicos en forma de ladrillos, permitiendo a los fans continuar sus historias favoritas en casa. Estos sets estimulan la conexión emocional con sus personajes preferidos y animan a la recreación de escenas o a la invención de nuevas aventuras, expandiendo la experiencia más allá de la pantalla o el libro.',
    NULL
);

-- TEMAS HIJOS

INSERT INTO TEMAS (te_id, te_nom, te_tipo, te_desc, te_padre)
VALUES (
    temas_seq.NEXTVAL,
    'THE BOTANICAL COLLECTION',
    'TEMA',
    'Colección de sets de construcción para adultos centrados en plantas y flores.',
    (SELECT te_id FROM TEMAS WHERE te_nom = 'TEMAS DE JUEGO' AND te_tipo = 'SERIE')
);

INSERT INTO TEMAS (te_id, te_nom, te_tipo, te_desc, te_padre)
VALUES (
    temas_seq.NEXTVAL,
    'CITY',
    'TEMA',
    'Temas basados en la vida urbana cotidiana (vehículos, servicios, edificios).',
    (SELECT te_id FROM TEMAS WHERE te_nom = 'TEMAS DE JUEGO' AND te_tipo = 'SERIE')
);

INSERT INTO TEMAS (te_id, te_nom, te_tipo, te_desc, te_padre)
VALUES (
    temas_seq.NEXTVAL,
    'CREATOR 3-IN-1',
    'TEMA',
    'Sets de construcción versátiles que ofrecen instrucciones para crear tres modelos distintos.',
    (SELECT te_id FROM TEMAS WHERE te_nom = 'TEMAS DE JUEGO' AND te_tipo = 'SERIE')
);

INSERT INTO TEMAS (te_id, te_nom, te_tipo, te_desc, te_padre)
VALUES (
    temas_seq.NEXTVAL,
    'DC',
    'TEMA',
    'Temas basados en el universo de DC Comics (Superhéroes como Batman y Superman), que requieren una licencia externa.',
    (SELECT te_id FROM TEMAS WHERE te_nom = 'PRODUCTOS BAJO LICENCIA' AND te_tipo = 'SERIE')
);







--inserts para clientes 
insert into clientes (cli_id, cli_pnombre, cli_papellido,cli_sapellido,
    cli_dni, cli_fnacimiento, cli_nac, cli_reside, cli_numpas, cli_fvenpas)
values (clientes_seq.nextval, 'ALEX', 'SMITH', 'JONES', 100000001, TO_DATE('1990-05-15', 'YYYY-MM-DD'),
    45, 46, 00012345, DATE '2030-10-20');

insert into clientes (cli_id, cli_pnombre, cli_papellido,cli_sapellido,
    cli_dni, cli_fnacimiento, cli_nac, cli_reside)
values (clientes_seq.nextval, 'CLARA', 'SCHMIDT', 'FISCHER', 100000002, TO_DATE('1985-11-20', 'YYYY-MM-DD'),
    46, 46);

insert into clientes (cli_id, cli_pnombre, cli_papellido,cli_sapellido,
    cli_dni, cli_fnacimiento, cli_nac, cli_reside, cli_snombre)
values (clientes_seq.nextval, 'DAVID', 'OCONNELL', 'MURPHY', 100000003, TO_DATE('1978-01-05', 'YYYY-MM-DD'),
    47, 48, 'JAMES');

insert into clientes (cli_id, cli_pnombre, cli_papellido,cli_sapellido,
    cli_dni, cli_fnacimiento, cli_nac, cli_reside, cli_numpas, cli_fvenpas)
values (clientes_seq.nextval, 'ETHAN', 'MULLER', 'DE JONG', 100000004, TO_DATE('1995-09-28', 'YYYY-MM-DD'),
    48, 47, 99876543, DATE '2035-03-01');

insert into clientes (cli_id, cli_pnombre, cli_papellido,cli_sapellido,
    cli_dni, cli_fnacimiento, cli_nac, cli_reside, cli_numpas, cli_fvenpas)
values (clientes_seq.nextval, 'FIONA', 'BROWN', 'DAVIS', 100000005, TO_DATE('1982-04-12', 'YYYY-MM-DD'),
    44, 44, 78908764, DATE '2035-04-22');

insert into clientes (cli_id, cli_pnombre, cli_papellido,cli_sapellido,
    cli_dni, cli_fnacimiento, cli_nac, cli_reside, cli_numpas, cli_fvenpas, cli_snombre)
values (clientes_seq.nextval, 'GEORGE', 'WHITE', 'ADAMS', 100000006, TO_DATE('2001-07-25', 'YYYY-MM-DD'),
    43, 43, 12356648, DATE '2032-06-12', 'PATRICK');

insert into clientes (cli_id, cli_pnombre, cli_papellido,cli_sapellido,
    cli_dni, cli_fnacimiento, cli_nac, cli_reside, cli_numpas, cli_fvenpas)
values (clientes_seq.nextval, 'HANNAH', 'LEE', 'WANG', 100000007, TO_DATE('2003-12-03', 'YYYY-MM-DD'),
    44, 45, 11223344, DATE '2032-07-15');

insert into clientes (cli_id, cli_pnombre, cli_papellido,cli_sapellido,
    cli_dni, cli_fnacimiento, cli_nac, cli_reside, cli_numpas, cli_fvenpas)
values (clientes_seq.nextval, 'IVAN', 'POPOV', 'SMIRNOV', 100000008, TO_DATE('1970-02-28', 'YYYY-MM-DD'),
    43, 48, 34567239, DATE '2027-04-25');

insert into clientes (cli_id, cli_pnombre, cli_papellido,cli_sapellido,
    cli_dni, cli_fnacimiento, cli_nac, cli_reside, cli_snombre)
values (clientes_seq.nextval, 'JULIA', 'CHEN', 'MAYER', 100000009, TO_DATE('1993-08-18', 'YYYY-MM-DD'),
    46, 47, 'MARIE');

insert into clientes (cli_id, cli_pnombre, cli_papellido,cli_sapellido,
    cli_dni, cli_fnacimiento, cli_nac, cli_reside)
values (clientes_seq.nextval, 'KEVIN', 'KELLY', 'RYAN', 100000010, TO_DATE('1980-06-30', 'YYYY-MM-DD'),
    47, 43);


---- tiendas 

INSERT INTO TIENDAS (ti_id, ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    tiendas_seq.NEXTVAL,
    'DREAMWORLD',
    '1 DREAMWORLD PKWY',
    '(07) 5588 1151',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'COOMERA'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'AUSTRALIA'),
    (SELECT e_id
       FROM ESTADOS
      WHERE e_nom = 'QUEENSLAND'
        AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'AUSTRALIA'))
);

INSERT INTO TIENDAS (ti_id, ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    tiendas_seq.NEXTVAL,
    'MARION',
    'WESTFIELD, 297 DIAGONAL RD',
    '(08) 8375 8901',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'OAKLANDS PARK'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'AUSTRALIA'),
    (SELECT e_id
       FROM ESTADOS
      WHERE e_nom = 'AUSTRALIA DEL SUR'
        AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'AUSTRALIA'))
);

INSERT INTO TIENDAS (ti_id, ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    tiendas_seq.NEXTVAL,
    'LEICESTER SQUARE',
    '3 SWISS COURT, W1D 6AP',
    '+44 2076650413',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'LONDRES'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'REINO UNIDO'),
    (SELECT e_id
       FROM ESTADOS
      WHERE e_nom = 'INGLATERRA'
        AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'REINO UNIDO'))
);

INSERT INTO TIENDAS (ti_id, ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    tiendas_seq.NEXTVAL,
    'BONN',
    'POSTSTRASSE, 53111',
    '+49 22828653972',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'BONN'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'),
    (SELECT e_id
       FROM ESTADOS
      WHERE e_nom = 'RENANIA DEL NORTE-WESTFALIA'
        AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'))
);

INSERT INTO TIENDAS (ti_id, ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    tiendas_seq.NEXTVAL,
    'DRESDEN',
    'ALTMARKT-GALERIE, WEBERGASSE 1',
    '+49 35189732777',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'DRESDEN'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'),
    (SELECT e_id
       FROM ESTADOS
      WHERE e_nom = 'SAJONIA'
        AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'))
);

INSERT INTO TIENDAS (ti_id, ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    tiendas_seq.NEXTVAL,
    'MALL OF THE NETHERLANDS',
    'BERKENHOVE 2, 2262 AK',
    '+31 707013850',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'LEIDSCHENDAM'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'PAISES BAJOS'),
    (SELECT e_id
       FROM ESTADOS
      WHERE e_nom = 'ZUID-HOLLAND'
        AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'PAISES BAJOS'))
);

INSERT INTO TIENDAS (ti_id, ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    tiendas_seq.NEXTVAL,
    'DANBURY FAIR',
    '7 BACKUS AVE, DANBURY FAIR, UNIT E207',
    '+1 (475) 348-7339',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'DANBURY'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'ESTADOS UNIDOS'),
    (SELECT e_id
       FROM ESTADOS
      WHERE e_nom = 'CONNECTICUT'
        AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'ESTADOS UNIDOS'))
);

INSERT INTO TIENDAS (ti_id, ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    tiendas_seq.NEXTVAL,
    'BLANCHARDSTOWN',
    'BLANCHARDSTOWN CENTRE, BLANCHARDSTOWN ROAD S',
    '+35 31575 2825',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'BLANCHARDSTOWN'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'IRLANDA'),
    (SELECT e_id
       FROM ESTADOS
      WHERE e_nom = 'LEINSTER'
        AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'IRLANDA'))
);

commit;

---- HORARIOS 
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DREAMWORLD'), OBTENER_NUMERO_DIA('LUNES'), '09:00', '17:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DREAMWORLD'), OBTENER_NUMERO_DIA('MARTES'), '09:00', '17:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DREAMWORLD'), OBTENER_NUMERO_DIA('MIÉRCOLES'), '09:00', '17:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DREAMWORLD'), OBTENER_NUMERO_DIA('JUEVES'), '09:00', '17:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DREAMWORLD'), OBTENER_NUMERO_DIA('VIERNES'), '09:00', '17:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DREAMWORLD'), OBTENER_NUMERO_DIA('SÁBADO'), '09:00', '17:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MARION'), OBTENER_NUMERO_DIA('LUNES'), '09:00', '17:30' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MARION'), OBTENER_NUMERO_DIA('MARTES'), '09:00', '17:30' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MARION'), OBTENER_NUMERO_DIA('MIÉRCOLES'), '09:00', '17:30' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MARION'), OBTENER_NUMERO_DIA('JUEVES'), '09:00', '21:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MARION'), OBTENER_NUMERO_DIA('VIERNES'), '09:00', '17:30' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MARION'), OBTENER_NUMERO_DIA('SÁBADO'), '09:00', '17:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DANBURY FAIR'), OBTENER_NUMERO_DIA('LUNES'), '10:00', '21:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DANBURY FAIR'), OBTENER_NUMERO_DIA('MARTES'), '10:00', '18:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DANBURY FAIR'), OBTENER_NUMERO_DIA('MIÉRCOLES'), '10:00', '18:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DANBURY FAIR'), OBTENER_NUMERO_DIA('JUEVES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DANBURY FAIR'), OBTENER_NUMERO_DIA('VIERNES'), '10:00', '21:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DANBURY FAIR'), OBTENER_NUMERO_DIA('SÁBADO'), '10:00', '21:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'LEICESTER SQUARE'), OBTENER_NUMERO_DIA('LUNES'), '10:00', '22:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'LEICESTER SQUARE'), OBTENER_NUMERO_DIA('MARTES'), '10:00', '22:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'LEICESTER SQUARE'), OBTENER_NUMERO_DIA('MIÉRCOLES'), '10:00', '22:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'LEICESTER SQUARE'), OBTENER_NUMERO_DIA('JUEVES'), '10:00', '22:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'LEICESTER SQUARE'), OBTENER_NUMERO_DIA('VIERNES'), '10:00', '22:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'LEICESTER SQUARE'), OBTENER_NUMERO_DIA('SÁBADO'), '10:00', '22:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BONN'), OBTENER_NUMERO_DIA('LUNES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BONN'), OBTENER_NUMERO_DIA('MARTES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BONN'), OBTENER_NUMERO_DIA('MIÉRCOLES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BONN'), OBTENER_NUMERO_DIA('JUEVES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BONN'), OBTENER_NUMERO_DIA('VIERNES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BONN'), OBTENER_NUMERO_DIA('SÁBADO'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DRESDEN'), OBTENER_NUMERO_DIA('LUNES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DRESDEN'), OBTENER_NUMERO_DIA('MARTES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DRESDEN'), OBTENER_NUMERO_DIA('MIÉRCOLES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DRESDEN'), OBTENER_NUMERO_DIA('JUEVES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DRESDEN'), OBTENER_NUMERO_DIA('VIERNES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'DRESDEN'), OBTENER_NUMERO_DIA('SÁBADO'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MALL OF THE NETHERLANDS'), OBTENER_NUMERO_DIA('LUNES'), '11:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MALL OF THE NETHERLANDS'), OBTENER_NUMERO_DIA('MARTES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MALL OF THE NETHERLANDS'), OBTENER_NUMERO_DIA('MIÉRCOLES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MALL OF THE NETHERLANDS'), OBTENER_NUMERO_DIA('JUEVES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MALL OF THE NETHERLANDS'), OBTENER_NUMERO_DIA('VIERNES'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'MALL OF THE NETHERLANDS'), OBTENER_NUMERO_DIA('SÁBADO'), '10:00', '20:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BLANCHARDSTOWN'), OBTENER_NUMERO_DIA('LUNES'), '09:00', '19:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BLANCHARDSTOWN'), OBTENER_NUMERO_DIA('MARTES'), '09:00', '19:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BLANCHARDSTOWN'), OBTENER_NUMERO_DIA('MIÉRCOLES'), '09:00', '21:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BLANCHARDSTOWN'), OBTENER_NUMERO_DIA('JUEVES'), '09:00', '21:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BLANCHARDSTOWN'), OBTENER_NUMERO_DIA('VIERNES'), '09:00', '21:00' );
INSERT INTO HORARIOS (h_tid, h_dia, h_aper, h_cier)
VALUES ( (SELECT ti_id FROM TIENDAS WHERE ti_nom = 'BLANCHARDSTOWN'), OBTENER_NUMERO_DIA('SÁBADO'), '09:00', '19:00' );
COMMIT;

--CATALOGOS 
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='AUSTRALIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Ramo de flores'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='ESTADOS UNIDOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Ramo de flores'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='REINO UNIDO'), (SELECT pro_cod FROM productos WHERE pro_nom='Ramo de flores'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='AUSTRALIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Ave del paraíso'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='ESTADOS UNIDOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Ave del paraíso'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='REINO UNIDO'), (SELECT pro_cod FROM productos WHERE pro_nom='Ave del paraíso'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='ALEMANIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Suculentas'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='IRLANDA'), (SELECT pro_cod FROM productos WHERE pro_nom='Suculentas'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='PAISES BAJOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Suculentas'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='ALEMANIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Centro de mesa de flores secas'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='IRLANDA'), (SELECT pro_cod FROM productos WHERE pro_nom='Centro de mesa de flores secas'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='PAISES BAJOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Centro de mesa de flores secas'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='AUSTRALIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Batmóvil de The Batman'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='ESTADOS UNIDOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Batmóvil de The Batman'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='REINO UNIDO'), (SELECT pro_cod FROM productos WHERE pro_nom='Batmóvil de The Batman'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='AUSTRALIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Gotham City'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='ESTADOS UNIDOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Gotham City'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='REINO UNIDO'), (SELECT pro_cod FROM productos WHERE pro_nom='Gotham City'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='ALEMANIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Batmóvil de la Serie Clásica de TV'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='IRLANDA'), (SELECT pro_cod FROM productos WHERE pro_nom='Batmóvil de la Serie Clásica de TV'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='PAISES BAJOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Batmóvil de la Serie Clásica de TV'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='ALEMANIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Tumbler de Batman contra Dos Caras y El Guasón'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='IRLANDA'), (SELECT pro_cod FROM productos WHERE pro_nom='Tumbler de Batman contra Dos Caras y El Guasón'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='PAISES BAJOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Tumbler de Batman contra Dos Caras y El Guasón'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='AUSTRALIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Camión de helados'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='ESTADOS UNIDOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Camión de helados'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='REINO UNIDO'), (SELECT pro_cod FROM productos WHERE pro_nom='Camión de helados'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='AUSTRALIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Helicóptero de rescate de incendios'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='ESTADOS UNIDOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Helicóptero de rescate de incendios'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='REINO UNIDO'), (SELECT pro_cod FROM productos WHERE pro_nom='Helicóptero de rescate de incendios'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='ALEMANIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Picnic en el parque'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='IRLANDA'), (SELECT pro_cod FROM productos WHERE pro_nom='Picnic en el parque'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='PAISES BAJOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Picnic en el parque'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (20, (SELECT p_id FROM paises WHERE p_nom='ALEMANIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Coche de policía'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (20, (SELECT p_id FROM paises WHERE p_nom='IRLANDA'), (SELECT pro_cod FROM productos WHERE pro_nom='Coche de policía'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (20, (SELECT p_id FROM paises WHERE p_nom='PAISES BAJOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Coche de policía'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (20, (SELECT p_id FROM paises WHERE p_nom='AUSTRALIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Super Robot'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (20, (SELECT p_id FROM paises WHERE p_nom='ESTADOS UNIDOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Super Robot'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (20, (SELECT p_id FROM paises WHERE p_nom='REINO UNIDO'), (SELECT pro_cod FROM productos WHERE pro_nom='Super Robot'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='AUSTRALIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Motocicleta clásica'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='ESTADOS UNIDOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Motocicleta clásica'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='REINO UNIDO'), (SELECT pro_cod FROM productos WHERE pro_nom='Motocicleta clásica'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='ALEMANIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Mech de minería espacial'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='IRLANDA'), (SELECT pro_cod FROM productos WHERE pro_nom='Mech de minería espacial'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (10, (SELECT p_id FROM paises WHERE p_nom='PAISES BAJOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Mech de minería espacial'));

INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='ALEMANIA'), (SELECT pro_cod FROM productos WHERE pro_nom='Tigre majestuoso'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='IRLANDA'), (SELECT pro_cod FROM productos WHERE pro_nom='Tigre majestuoso'));
INSERT INTO CATALOGOS (CAT_LIMCOM, CAT_PAIS, CAT_PROD) VALUES (5, (SELECT p_id FROM paises WHERE p_nom='PAISES BAJOS'), (SELECT pro_cod FROM productos WHERE pro_nom='Tigre majestuoso'));
COMMIT;

-- HISTORIAL DE PRECIOS
INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Centro de mesa de flores secas'), DATE '2024-01-01', 30, DATE '2024-03-31');
INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Centro de mesa de flores secas'), DATE '2024-03-31', 38, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), DATE '2023-05-20', 100, DATE '2024-01-31');
INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), DATE '2024-01-31', 95, DATE '2025-02-28');
INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), DATE '2025-02-28', 120, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Gotham City'), DATE '2024-09-01', 250, DATE '2025-01-10');
INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Gotham City'), DATE '2025-01-10', 230, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de la Serie Clásica de TV'), DATE '2024-04-01', 80, DATE '2025-06-15');
INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de la Serie Clásica de TV'), DATE '2025-06-15', 85, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tumbler de Batman contra Dos Caras y El Guasón'), DATE '2023-07-07', 150, DATE '2024-08-01');
INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tumbler de Batman contra Dos Caras y El Guasón'), DATE '2024-08-01', 145, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Camión de helados'), DATE '2024-01-15', 45, DATE '2024-12-31');
INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Camión de helados'), DATE '2024-12-31', 50, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), DATE '2024-03-20', 70, DATE '2024-10-20');
INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), DATE '2024-10-20', 72, DATE '2025-05-01');
INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), DATE '2025-05-01', 68, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ramo de flores'), DATE '2025-01-01', 50, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ave del paraíso'), DATE '2025-05-15', 35, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Suculentas'), DATE '2024-11-20', 15, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Picnic en el parque'), DATE '2023-10-05', 40, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Coche de policía'), DATE '2025-03-01', 25, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Super Robot'), DATE '2024-07-25', 90, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Motocicleta clásica'), DATE '2025-04-10', 65, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Mech de minería espacial'), DATE '2025-06-01', 110, NULL);

INSERT INTO hist_precios (hp_prod, hp_fini, hp_precio, hp_ffin) 
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tigre majestuoso'), DATE '2024-12-15', 75, NULL);

INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ramo de flores'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ave del paraíso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Suculentas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Centro de mesa de flores secas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Gotham City'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de la Serie Clásica de TV'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tumbler de Batman contra Dos Caras y El Guasón'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Camión de helados'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Picnic en el parque'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Coche de policía'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Super Robot'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Motocicleta clásica'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Mech de minería espacial'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tigre majestuoso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DREAMWORLD'), 50);


INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ramo de flores'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ave del paraíso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Suculentas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Centro de mesa de flores secas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Gotham City'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de la Serie Clásica de TV'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tumbler de Batman contra Dos Caras y El Guasón'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Camión de helados'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Picnic en el parque'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Coche de policía'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Super Robot'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Motocicleta clásica'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Mech de minería espacial'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tigre majestuoso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MARION'), 50);


INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ramo de flores'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ave del paraíso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Suculentas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Centro de mesa de flores secas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Gotham City'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de la Serie Clásica de TV'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tumbler de Batman contra Dos Caras y El Guasón'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Camión de helados'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Picnic en el parque'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Coche de policía'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Super Robot'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Motocicleta clásica'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Mech de minería espacial'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tigre majestuoso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DANBURY FAIR'), 50);

INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ramo de flores'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ave del paraíso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Suculentas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Centro de mesa de flores secas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Gotham City'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de la Serie Clásica de TV'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tumbler de Batman contra Dos Caras y El Guasón'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Camión de helados'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Picnic en el parque'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Coche de policía'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Super Robot'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Motocicleta clásica'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Mech de minería espacial'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tigre majestuoso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'LEICESTER SQUARE'), 25);

INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ramo de flores'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ave del paraíso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Suculentas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Centro de mesa de flores secas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Gotham City'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de la Serie Clásica de TV'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tumbler de Batman contra Dos Caras y El Guasón'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Camión de helados'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Picnic en el parque'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Coche de policía'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Super Robot'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Motocicleta clásica'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Mech de minería espacial'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tigre majestuoso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BONN'), 25);

INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ramo de flores'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ave del paraíso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Suculentas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Centro de mesa de flores secas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Gotham City'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de la Serie Clásica de TV'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tumbler de Batman contra Dos Caras y El Guasón'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Camión de helados'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Picnic en el parque'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Coche de policía'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Super Robot'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Motocicleta clásica'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Mech de minería espacial'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tigre majestuoso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'DRESDEN'), 25);

INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ramo de flores'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ave del paraíso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Suculentas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Centro de mesa de flores secas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Gotham City'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de la Serie Clásica de TV'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tumbler de Batman contra Dos Caras y El Guasón'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Camión de helados'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Picnic en el parque'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Coche de policía'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Super Robot'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Motocicleta clásica'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Mech de minería espacial'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tigre majestuoso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'MALL OF THE NETHERLANDS'), 10);

INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ramo de flores'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Ave del paraíso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Suculentas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Centro de mesa de flores secas'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de The Batman'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Gotham City'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Batmóvil de la Serie Clásica de TV'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tumbler de Batman contra Dos Caras y El Guasón'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Camión de helados'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Helicóptero de rescate de incendios'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Picnic en el parque'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Coche de policía'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Super Robot'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Motocicleta clásica'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Mech de minería espacial'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
INSERT INTO LOTES (lot_prod, lot_tienda, lot_stock)
VALUES ((SELECT pro_cod FROM productos WHERE pro_nom = 'Tigre majestuoso'), (SELECT ti_id FROM tiendas WHERE ti_nom = 'BLANCHARDSTOWN'), 10);
