-------------------------------------------------------------------------------------------
---------------------------------------- INSERTS-------------------------------------------
-------------------------------------------------------------------------------------------
—PAISES
INSERT INTO PAISES (p_nom, p_con, p_ue, p_nac) VALUES ('AUSTRALIA', 'OCEANIA', 'NO', 'AUSTRALIANA');
INSERT INTO PAISES (p_nom, p_con, p_ue, p_nac) VALUES ('ESTADOS UNIDOS', 'AMERICA', 'NO', 'ESTADOUNIDENSE');
INSERT INTO PAISES (p_nom, p_con, p_ue, p_nac) VALUES ('REINO UNIDO', 'EUROPA', 'NO', 'BRITANICA');
INSERT INTO PAISES (p_nom, p_con, p_ue, p_nac) VALUES ('ALEMANIA', 'EUROPA', 'SI', 'ALEMANA');
INSERT INTO PAISES (p_nom, p_con, p_ue, p_nac) VALUES ('IRLANDA', 'EUROPA', 'SI', 'IRLANDESA');
INSERT INTO PAISES (p_nom, p_con, p_ue, p_nac) VALUES ('PAISES BAJOS', 'EUROPA', 'SI', 'NEERLANDESA');


—ESTADOS
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

INSERT INTO ESTADOS (ep_id, e_id, e_nom) 
    VALUES (
        (SELECT p_id FROM PAISES WHERE p_nom = 'ESTADOS UNIDOS'),
        estados_seq.NEXTVAL,
        'CONNECTICUT'
    );

INSERT INTO ESTADOS (ep_id, e_id, e_nom) 
    VALUES (
        (SELECT p_id FROM PAISES WHERE p_nom = 'REINO UNIDO'),
        estados_seq.NEXTVAL,
        'INGLATERRA'
    );

INSERT INTO ESTADOS (ep_id, e_id, e_nom) 
    VALUES (
        (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'),
        estados_seq.NEXTVAL,
        'RENANIA DEL NORTE-WESTFALIA'
    );

INSERT INTO ESTADOS (ep_id, e_id, e_nom) 
    VALUES (
        (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'),
        estados_seq.NEXTVAL,
        'SAJONIA'
    );

INSERT INTO ESTADOS (ep_id, e_id, e_nom) 
    VALUES (
        (SELECT p_id FROM PAISES WHERE p_nom = 'IRLANDA'),
        estados_seq.NEXTVAL,
        'LEINSTER'
    );

INSERT INTO ESTADOS (ep_id, e_id, e_nom) 
    VALUES (
        (SELECT p_id FROM PAISES WHERE p_nom = 'PAISES BAJOS'),
        estados_seq.NEXTVAL,
        'ZUID-HOLLAND'
    );

—CIUDADES
INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
    SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'COOMERA'
    FROM PAISES p JOIN ESTADOS e ON p.p_id = e.ep_id
    WHERE p.p_nom = 'AUSTRALIA' AND e.e_nom = 'QUEENSLAND';

INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
    SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'OAKLANDS PARK'
    FROM PAISES p JOIN ESTADOS e ON p.p_id = e.ep_id
    WHERE p.p_nom = 'AUSTRALIA' AND e.e_nom = 'AUSTRALIA DEL SUR';

INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
    SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'DANBURY'
    FROM PAISES p JOIN ESTADOS e ON p.p_id = e.ep_id
    WHERE p.p_nom = 'ESTADOS UNIDOS' AND e.e_nom = 'CONNECTICUT';

INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
    SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'LONDRES'
    FROM PAISES p JOIN ESTADOS e ON p.p_id = e.ep_id
    WHERE p.p_nom = 'REINO UNIDO' AND e.e_nom = 'INGLATERRA';

INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
    SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'BONN'
    FROM PAISES p JOIN ESTADOS e ON p.p_id = e.ep_id
    WHERE p.p_nom = 'ALEMANIA' AND e.e_nom = 'RENANIA DEL NORTE-WESTFALIA';

INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
    SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'DRESDEN'
    FROM PAISES p JOIN ESTADOS e ON p.p_id = e.ep_id
    WHERE p.p_nom = 'ALEMANIA' AND e.e_nom = 'SAJONIA';

INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
    SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'BLANCHARDSTOWN'
    FROM PAISES p JOIN ESTADOS e ON p.p_id = e.ep_id
    WHERE p.p_nom = 'IRLANDA' AND e.e_nom = 'LEINSTER';

INSERT INTO CIUDADES (cp_id, ce_id, ciu_id, ciu_nom)
    SELECT p.p_id, e.e_id, ciudades_seq.NEXTVAL, 'LEIDSCHENDAM'
    FROM PAISES p JOIN ESTADOS e ON p.p_id = e.ep_id
    WHERE p.p_nom = 'PAISES BAJOS' AND e.e_nom = 'ZUID-HOLLAND';



—-TOURS 
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

insert into tours (to_fini, to_cupos, to_costo)
values (TO_DATE('8-09-2024', 'DD-MM-YYYY'), 20, 3500);

insert into tours (to_fini, to_cupos, to_costo)
values (TO_DATE('01-10-2024', 'DD-MM-YYYY'), 20, 3500);

insert into tours (to_fini, to_cupos, to_costo)
values (TO_DATE('29-10-2024', 'DD-MM-YYYY'), 20, 3500);

insert into tours (to_fini, to_cupos, to_costo)
values (TO_DATE('19-11-2024', 'DD-MM-YYYY'), 20, 3500);






—TEMAS
INSERT INTO TEMAS (te_nom, te_tipo, te_desc, te_padre)
VALUES ('PRODUCTOS PARA PREESCOLARES', 'SERIE', 'Nuestros juguetes de construcción preescolares, que están diseñados para que los más pequeños los puedan montar con facilidad, animan a los peques a pasar horas apilando, clasificando y construyendo. Estos sets pueden ayudar a los bebés a desarrollar su motricidad fina, su confianza en el juego y muchas otras cosas. Te ofrecemos una amplia variedad de set diseñados específicamente para preescolares, tanto si buscas juguetes que desarrollen la coordinación oculomanual y la destreza, como sets que fomenten el conocimiento emocional o que ayuden a aprender a contar, el abecedario y mucho más. ', NULL);

INSERT INTO TEMAS (te_nom, te_tipo, te_desc, te_padre)
VALUES ('CONSTRUCCIÓN CREATIVA', 'SERIE', 'Productos enfocados en la construcción libre y el fomento de la creatividad.', NULL);

INSERT INTO TEMAS (te_nom, te_tipo, te_desc, te_padre)
VALUES ('TEMAS DE JUEGO', 'SERIE', 'Nuestros Temas de Juego giran en torno a historias, escenarios y profesiones específicas, invitando a los niños a imaginar y recrear mundos complejos. Desde estaciones de policía y bomberos hasta aeropuertos y castillos, estos sets ofrecen una base rica para el juego de roles y la narración. Los niños pueden construir y poblar sus propias ciudades, resolver desafíos y dar vida a sus fantasías, fomentando la creatividad narrativa y las habilidades sociales a través del juego dirigido.', NULL);

INSERT INTO TEMAS (te_nom, te_tipo, te_desc, te_padre)
VALUES ('PRODUCTOS BAJO LICENCIA', 'SERIE', 'Esta serie incluye Temas de Juego basados en propiedades intelectuales populares como películas, series de televisión y cómics, cuyas licencias han sido adquiridas. Los diseñadores de LEGO recrean meticulosamente los universos, personajes y vehículos icónicos en forma de ladrillos, permitiendo a los fans continuar sus historias favoritas en casa. Estos sets estimulan la conexión emocional con sus personajes preferidos y animan a la recreación de escenas o a la invención de nuevas aventuras, expandiendo la experiencia más allá de la pantalla o el libro.', NULL);


INSERT INTO TEMAS (te_nom, te_tipo, te_desc, te_padre)
VALUES ('THE BOTANICAL COLLECTION', 'TEMA', 'Colección de sets de construcción para adultos centrados en plantas y flores.', 
    (SELECT te_id FROM TEMAS WHERE te_nom = 'TEMAS DE JUEGO' AND te_tipo = 'SERIE')
);

INSERT INTO TEMAS (te_nom, te_tipo, te_desc, te_padre)
VALUES ('CITY', 'TEMA', 'Temas basados en la vida urbana cotidiana (vehículos, servicios, edificios).', 
    (SELECT te_id FROM TEMAS WHERE te_nom = 'TEMAS DE JUEGO' AND te_tipo = 'SERIE')
);

INSERT INTO TEMAS (te_nom, te_tipo, te_desc, te_padre)
VALUES ('CREATOR 3-IN-1', 'TEMA', 'Sets de construcción versátiles que ofrecen instrucciones para crear tres modelos distintos.', 
    (SELECT te_id FROM TEMAS WHERE te_nom = 'TEMAS DE JUEGO' AND te_tipo = 'SERIE')
);

INSERT INTO TEMAS (te_nom, te_tipo, te_desc, te_padre)
VALUES ('DC', 'TEMA', 'Temas basados en el universo de DC Comics (Superhéroes como Batman y Superman), que requieren una licencia externa.', 
    (SELECT te_id FROM TEMAS WHERE te_nom = 'PRODUCTOS BAJO LICENCIA' AND te_tipo = 'SERIE')
);

--PRODUCTOS
INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='THE BOTANICAL COLLECTION'),
    'Ramo de flores',
    'Dar y recibir flores hermosas es una alegría. Si buscas un regalo floral diferente, el Ramo de Flores LEGO® (10280) es una opción inspiradora. Ya sea para obsequiar a un ser querido o para tu próximo proyecto creativo, este kit de construcción de ramo de flores te permite relajarte, desconectar y crear algo maravilloso. ',
    'ADULTOS',
    'B',
    'NO',
    '10280.pdf',
    756,
    NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='THE BOTANICAL COLLECTION'),
    'Ave del paraíso',
    'Celebre su amor por las plantas mientras construye este elegante modelo LEGO® Ave del Paraíso para exhibir en casa.',
    'ADULTOS',
    'B',
    'NO',
    '10289.pdf',
    1173,
    NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='THE BOTANICAL COLLECTION'),
    'Suculentas',
    'Los 3 juegos de instrucciones de construcción te permiten disfrutar de la construcción con amigos o familiares antes de combinar tus diferentes suculentas.',
    'ADULTOS',
    'C',
    'NO',
    '10309.pdf',
    771,
    NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='THE BOTANICAL COLLECTION'),
    'Centro de mesa de flores secas',
    'La pieza central puede ser construida por varias personas, lo que brinda la oportunidad de crear recuerdos especiales con sus seres queridos.',
    'ADULTOS',
    'D',
    'NO',
    '10314.pdf',
    812,
    NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='DC'),
    'Batmóvil de The Batman',
    'Los fans de Batman pueden llevar la acción de la película de 2022 al mundo real con el juguete Batmóvil de The Batman (76332), un regalo de construcción de un modelo de coche para niños y niñas a partir de 9 años. Celebra el 20 aniversario de LEGO® DC Batman con este artículo coleccionable que contiene el vehículo y una minifigura de Batman con capa de tela.',
    '9-11',
    'D',
    'SI',
    '76300.pdf',
    2953,
   (SELECT pro_cod FROM PRODUCTOS WHERE pro_nom='Asilo Arkham')
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='DC'),
    'Gotham City',
    'Inspirado en los icónicos créditos iniciales de Batman: La Serie Animada, este nuevo set recrea los colores dinámicos y los conocidos edificios del paisaje urbano de Gotham City. Pero la verdadera sorpresa comienza después, al sumergirte en la escena. Los fans se darán cuenta de que cada detalle, vehículo, estructura y elemento de decoración forman parte de una escena, episodio o momento específico de la rompedora serie.',
    'ADULTOS',
    'D',
    'NO',
    '76271.pdf',
    4210,
   NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='DC'),
    'Batmóvil de la Serie Clásica de TV',
    'El kit de construcción coleccionable LEGO® DC Batman: Batmóvil de la Serie Clásica de TV (76328) es ideal para fans que busquen proyectos gratificantes para construir y exponer. Este creativo regalo para adultos encantará tanto los entusiastas de Batman como a los interesados en la cultura pop de la década de 1960.',
    'ADULTOS',
    'C',
    'NO',
    '76328.pdf',
    1822,
   NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='DC'),
    'Tumbler de Batman contra Dos Caras y El Guasón',
    'El set Tumbler de Batman vs. Two-Face y The Joker (76303) es un divertido juguete para pequeños apasionados de Batman, los vehículos, el poder creativo de LEGO® y las aventuras de superhéroes. Pon la acción sobre ruedas de Batman en las manos de tu joven superhéroe o superheroína de 8 años o más con este set LEGO de alta calidad que incluye el emblemático Batmóvil Tumbler de la trilogía clásica El caballero oscuro.',
    '7-8',
    'B',
    'NO',
    '76303.pdf',
    429,
   NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='CITY'),
    'Camión de helados',
    'Este camión de helados de colores brillantes está repleto de características emocionantes que inspirarán un juego imaginativo sin fin.',
    '5-6',
    'B',
    'NO',
    '60253.pdf',
    200,
   NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='CITY'),
    'Helicóptero de rescate de incendios',
    'Un regalo para los fans de la serie de televisión LEGO® City Adventures, este emocionante set de juego LEGO City Helicóptero de Rescate de Bomberos (60281) incluye un helicóptero de juguete, una moto y una central eléctrica con llamas LEGO apilables para grandes incendios. Los niños pueden disparar los cañones de agua del helicóptero para apagar el fuego y disfrutar del juego de rol con 3 minifiguras, incluyendo un trabajador, un piloto de helicóptero y el héroe de la serie de televisión LEGO City, Clemmons.',
    '5-6',
    'B',
    'NO',
    '60281.pdf',
    212,
   NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='CITY'),
    'Picnic en el parque',
    'Los niños pueden disfrutar de picnics de verano todos los días con este divertido juego LEGO® City, lleno de inspiración para el juego imaginativo.',
    '5-6',
    'A',
    'NO',
    '60326.pdf',
    147,
   NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='CITY'),
    'Coche de policía',
    'Introduce a los niños a un mundo de diversión y emoción con el set de juego LEGO® City Coche de Policía (60312), que incluye un deportivo coche patrulla de juguete con llantas alucinantes, guardabarros anchos y neumáticos de alto agarre. ¡Solo añade la minifigura de un policía, con linterna de juguete y gorra de policía, para disfrutar de horas de imaginativa persecución de ladrones!',
    '5-6',
    'A',
    'NO',
    '60312.pdf',
    94,
   NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='CREATOR 3-IN-1'),
    'Super Robot',
    'Satisface la pasión de los niños por la acción futurista con este juego 3 en 1 que les permite construir un robot, un avión a reacción o un dragón.',
    '7-8',
    'B',
    'NO',
    '31124.pdf',
    159,
   NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='CREATOR 3-IN-1'),
    'Motocicleta clásica',
    'Este juego LEGO® 3 en 1 permite a los niños construir 3 vehículos superrápidos: una motocicleta clásica, una motocicleta de calle y un dragster de alta velocidad.',
    '9-11',
    'A',
    'NO',
    '31135.pdf',
    128,
   NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='CREATOR 3-IN-1'),
    'Mech de minería espacial',
    'A los fans de LEGO® les encantará recrear escenas de acción con el impresionante set de construcción Creator 3 en 1 Robot de Minería Espacial (31115). Las fantásticas características de este robot de juguete incluyen piernas y brazos articulados, una sierra circular giratoria, una mochila propulsora en la espalda y una cara con expresiones cambiantes, lo que les da a los niños todo lo que necesitan para horas de diversión interpretando.',
    '7-8',
    'B',
    'NO',
    '31115.pdf',
    327,
   NULL
);

INSERT INTO PRODUCTOS (
    pro_idtem,
    pro_nom,
    pro_desc,
    pro_raned,
    pro_ranpr,
    pro_set,
    pro_instr,
    pro_piecs,
    set_id
)
VALUES (
    (SELECT te_id FROM TEMAS WHERE te_nom='CREATOR 3-IN-1'),
    'Tigre majestuoso',
    'Este juego sumamente detallado ofrece a los fanáticos de LEGO® 3 opciones diferentes de construcción y juego para disfrutar de historias divertidas con animales geniales.',
    '9-11',
    'B',
    'NO',
    '31129.pdf',
    755,
   NULL
);

—CLIENTES
INSERT INTO CLIENTES (cli_nac, cli_reside, cli_pnombre, cli_papellido, cli_sapellido, cli_dni, cli_fnacimiento, cli_snombre, cli_numpas, cli_fvenpas) 
SELECT 
    p_nacio.p_id, 
    p_reside.p_id, 
    'ALEX', 
    'SMITH', 
    'JONES', 
    100000000005, 
    DATE '1990-05-15', 
    'MARK', 
    'RU0000000000', 
    DATE '2030-10-20'
FROM 
    PAISES p_nacio, PAISES p_reside
WHERE 
    p_nacio.p_nom = 'REINO UNIDO' AND p_reside.p_nom = 'ALEMANIA';

INSERT INTO CLIENTES (cli_nac, cli_reside, cli_pnombre, cli_papellido, cli_sapellido, cli_dni, cli_fnacimiento, cli_numpas, cli_fvenpas) 
SELECT 
    p_nacio.p_id, 
    p_reside.p_id, 
    'FIONA', 
    'BROWN', 
    'DAVIS', 
    100000000006, 
    DATE '1982-04-12',
    'USA000000001',
    DATE '2030-05-01'
FROM 
    PAISES p_nacio, PAISES p_reside
WHERE 
    p_nacio.p_nom = 'ESTADOS UNIDOS' AND p_reside.p_nom = 'ESTADOS UNIDOS';

INSERT INTO CLIENTES (cli_nac, cli_reside, cli_pnombre, cli_papellido, cli_sapellido, cli_dni, cli_fnacimiento, cli_snombre, cli_numpas, cli_fvenpas) 
SELECT 
    p_nacio.p_id, 
    p_reside.p_id, 
    'GEORGE', 
    'WHITE', 
    'ADAMS', 
    100000000007, 
    DATE '2001-07-25', 
    'PATRICK',
    'AUS000000002',
    DATE '2031-08-15'
FROM 
    PAISES p_nacio, PAISES p_reside
WHERE 
    p_nacio.p_nom = 'AUSTRALIA' AND p_reside.p_nom = 'AUSTRALIA';

INSERT INTO CLIENTES (cli_nac, cli_reside, cli_pnombre, cli_papellido, cli_sapellido, cli_dni, cli_fnacimiento, cli_numpas, cli_fvenpas) 
SELECT 
    p_nacio.p_id, 
    p_reside.p_id, 
    'HANNAH', 
    'LEE', 
    'WANG', 
    100000000008, 
    DATE '1998-12-03', 
    'USA000000003', 
    DATE '2032-06-15'
FROM 
    PAISES p_nacio, PAISES p_reside
WHERE 
    p_nacio.p_nom = 'ESTADOS UNIDOS' AND p_reside.p_nom = 'REINO UNIDO';

INSERT INTO CLIENTES (cli_nac, cli_reside, cli_pnombre, cli_papellido, cli_sapellido, cli_dni, cli_fnacimiento, cli_numpas, cli_fvenpas) 
SELECT 
    p_nacio.p_id, 
    p_reside.p_id, 
    'IVAN', 
    'POPOV', 
    'SMIRNOV', 
    100000000009, 
    DATE '1970-02-28',
    'AUS000000004',
    DATE '2030-01-20'
FROM 
    PAISES p_nacio, PAISES p_reside
WHERE 
    p_nacio.p_nom = 'AUSTRALIA' AND p_reside.p_nom = 'PAISES BAJOS';


INSERT INTO CLIENTES (cli_nac, cli_reside, cli_pnombre, cli_papellido, cli_sapellido, cli_dni, cli_fnacimiento, cli_snombre) 
SELECT 
    p_nacio.p_id, 
    p_reside.p_id, 
    'CLARA', 
    'SCHMIDT', 
    'FISCHER', 
    100000000000, 
    DATE '1985-11-20',
    NULL
FROM 
    PAISES p_nacio, PAISES p_reside
WHERE 
    p_nacio.p_nom = 'ALEMANIA' AND p_reside.p_nom = 'ALEMANIA';

INSERT INTO CLIENTES (cli_nac, cli_reside, cli_pnombre, cli_papellido, cli_sapellido, cli_dni, cli_fnacimiento, cli_snombre) 
SELECT 
    p_nacio.p_id, 
    p_reside.p_id, 
    'DAVID', 
    'OCONNELL', 
    'MURPHY', 
    100000000001, 
    DATE '1978-01-05', 
    'JAMES'
FROM 
    PAISES p_nacio, PAISES p_reside
WHERE 
    p_nacio.p_nom = 'IRLANDA' AND p_reside.p_nom = 'PAISES BAJOS';

INSERT INTO CLIENTES (cli_nac, cli_reside, cli_pnombre, cli_papellido, cli_sapellido, cli_dni, cli_fnacimiento, cli_snombre) 
SELECT 
    p_nacio.p_id, 
    p_reside.p_id, 
    'JULIA', 
    'CHEN', 
    'MAYER', 
    100000000002, 
    DATE '1993-08-18', 
    'MARIE'
FROM 
    PAISES p_nacio, PAISES p_reside
WHERE 
    p_nacio.p_nom = 'ALEMANIA' AND p_reside.p_nom = 'IRLANDA';

INSERT INTO CLIENTES (cli_nac, cli_reside, cli_pnombre, cli_papellido, cli_sapellido, cli_dni, cli_fnacimiento) 
SELECT 
    p_nacio.p_id, 
    p_reside.p_id, 
    'KEVIN', 
    'KELLY', 
    'RYAN', 
    100000000003, 
    DATE '1980-06-30'
FROM 
    PAISES p_nacio, PAISES p_reside
WHERE 
    p_nacio.p_nom = 'IRLANDA' AND p_reside.p_nom = 'AUSTRALIA';

INSERT INTO CLIENTES (cli_nac, cli_reside, cli_pnombre, cli_papellido, cli_sapellido, cli_dni, cli_fnacimiento) 
SELECT 
    p_nacio.p_id, 
    p_reside.p_id, 
    'ETHAN', 
    'MULLER', 
    'DE JONG', 
    100000000004, 
    DATE '1995-09-28'
FROM 
    PAISES p_nacio, PAISES p_reside
WHERE 
    p_nacio.p_nom = 'PAISES BAJOS' AND p_reside.p_nom = 'IRLANDA';values (TO_DATE('10-12-2025', 'DD-MM-YYYY'), 25, 3500);


—-TIENDAS
INSERT INTO TIENDAS (ti_nom,ti_dic,ti_tel,ti_ciu,ti_pais,ti_estado)
VALUES (
    'DREAMWORLD',
    '1 DREAMWORLD PKWY',
     '(07) 5588 1151',
     (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'COOMERA'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'AUSTRALIA'),
    (SELECT e_id FROM ESTADOS WHERE e_nom = 'QUEENSLAND' AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'AUSTRALIA'))    
);

INSERT INTO TIENDAS (ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    'MARION',
    'WESTFIELD, 297 DIAGONAL RD',
    '(08) 8375 8901',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'OAKLANDS PARK'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'AUSTRALIA'),
    (SELECT e_id FROM ESTADOS WHERE e_nom = 'AUSTRALIA DEL SUR' AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'AUSTRALIA'))
);

INSERT INTO TIENDAS (ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    'LEICESTER SQUARE',
    '3 SWISS COURT, W1D 6AP',
    '+44 2076650413',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'LONDRES'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'REINO UNIDO'),
    (SELECT e_id FROM ESTADOS WHERE e_nom = 'INGLATERRA' AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'REINO UNIDO'))
);

INSERT INTO TIENDAS (ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    'BONN',
    'POSTSTRASSE, 53111',
    '+49 22828653972',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'BONN'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'),
    (SELECT e_id FROM ESTADOS WHERE e_nom = 'RENANIA DEL NORTE-WESTFALIA' AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'))
);

INSERT INTO TIENDAS (ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    'DRESDEN',
    'ALTMARKT-GALERIE, WEBERGASSE 1',
    '+49 35189732777',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'DRESDEN'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'),
    (SELECT e_id FROM ESTADOS WHERE e_nom = 'SAJONIA' AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'ALEMANIA'))
);

INSERT INTO TIENDAS (ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    'MALL OF THE NETHERLANDS',
    'BERKENHOVE 2, 2262 AK',
    '+31 707013850',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'LEIDSCHENDAM'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'PAISES BAJOS'),
    (SELECT e_id FROM ESTADOS WHERE e_nom = 'ZUID-HOLLAND' AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'PAISES BAJOS'))
);


INSERT INTO TIENDAS (ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    'DANBURY FAIR',
    '7 BACKUS AVE, DANBURY FAIR, UNIT E207',
    '+1 (475) 348-7339',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'DANBURY'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'ESTADOS UNIDOS'),
    (SELECT e_id FROM ESTADOS WHERE e_nom = 'CONNECTICUT' AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'ESTADOS UNIDOS'))
);

INSERT INTO TIENDAS (ti_nom, ti_dic, ti_tel, ti_ciu, ti_pais, ti_estado)
VALUES (
    'BLANCHARDSTOWN',
    'BLANCHARDSTOWN CENTRE, BLANCHARDSTOWN ROAD S',
    '+35 31575 2825',
    (SELECT ciu_id FROM CIUDADES WHERE ciu_nom = 'BLANCHARDSTOWN'),
    (SELECT p_id FROM PAISES WHERE p_nom = 'IRLANDA'),
    (SELECT e_id FROM ESTADOS WHERE e_nom = 'LEINSTER' AND ep_id = (SELECT p_id FROM PAISES WHERE p_nom = 'IRLANDA'))
);



–HORARIOS
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

—CATALOGOS
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





—-HISTORICOS
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

—INVENTARIO
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

COMMIT;