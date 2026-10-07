-- ============================================================================
--  SEED · Yoda
--  Se puede ejecutar varias veces: actualiza el personaje y vuelve a cargar
--  su contenido sin duplicar nada.
--  Fechas en el calendario de Star Wars: a.B.Y. = antes de la Batalla de Yavin,
--  d.B.Y. = después de la Batalla de Yavin.
-- ============================================================================

SET NAMES utf8mb4;

-- ----------------------------------------------------------------------------
-- Personaje
-- ----------------------------------------------------------------------------
INSERT INTO personajes (slug, nombre, titulo, universo, resumen, imagen_hero, tema, activo, orden)
VALUES (
  'yoda',
  'Yoda',
  'Gran Maestro de la Orden Jedi',
  'Star Wars',
  'Pequeño en tamaño, inmenso en sabiduría. Durante cientos de años guió a la Orden Jedi, luchó en las Guerras Clon y, ya en el exilio, entrenó a la última esperanza de la galaxia.',
  NULL,
  'dagobah',
  1,
  1
)
ON DUPLICATE KEY UPDATE
  nombre = VALUES(nombre), titulo = VALUES(titulo), universo = VALUES(universo),
  resumen = VALUES(resumen), tema = VALUES(tema), activo = VALUES(activo), orden = VALUES(orden);

SET @pid := (SELECT id FROM personajes WHERE slug = 'yoda');

-- Limpieza para poder re-ejecutar el seed
DELETE FROM secciones      WHERE personaje_id = @pid;
DELETE FROM personaje_datos WHERE personaje_id = @pid;
DELETE FROM cronologia     WHERE personaje_id = @pid;
DELETE FROM poderes        WHERE personaje_id = @pid;
DELETE FROM frases         WHERE personaje_id = @pid;
DELETE FROM apariciones    WHERE personaje_id = @pid;
DELETE FROM curiosidades   WHERE personaje_id = @pid;

-- ----------------------------------------------------------------------------
-- Figura física (la que lleva el QR). Editá estos datos con los de tu figura:
--   UPDATE figuras SET autor='Tu nombre', materiales='PLA verde', escala='15 cm',
--          imagen_url='assets/img/mi-figura.jpg' WHERE codigo='yoda-01';
-- ----------------------------------------------------------------------------
INSERT INTO figuras (personaje_id, codigo, nombre, descripcion, activo)
VALUES (
  @pid,
  'yoda-01',
  'Figura 3D de Yoda',
  'Esta página está vinculada a una figura de Yoda diseñada en 3D. Si llegaste hasta acá escaneando su código QR, ¡bienvenido! Abajo vas a encontrar toda la historia del personaje que la inspira.',
  1
)
ON DUPLICATE KEY UPDATE personaje_id = VALUES(personaje_id), nombre = VALUES(nombre), activo = VALUES(activo);

-- ----------------------------------------------------------------------------
-- Secciones (orden de aparición en la página)
-- ----------------------------------------------------------------------------
INSERT INTO secciones (personaje_id, clave, titulo, subtitulo, contenido, orden, visible) VALUES
(@pid, 'biografia', 'Quién es Yoda', 'Casi mil años de historia',
'Yoda fue uno de los Jedi más sabios y poderosos de toda la historia de la galaxia. Nació alrededor del año 896 a.B.Y. en un lugar que nunca se reveló: tanto su especie como su mundo natal siguen siendo un misterio, y apenas se sabe de otros pocos seres de su misma especie.

Durante unos ocho siglos fue maestro de jóvenes Jedi y llegó a ser Gran Maestro de la Orden y miembro del Alto Consejo Jedi. Su manera de hablar, con la frase "al revés", y su serenidad lo convirtieron en una figura inconfundible, capaz de ver el futuro con claridad y de enseñar tanto con palabras como con silencios.

Cuando estalló la guerra y la Orden fue traicionada, sobrevivió al exterminio, se enfrentó a Darth Sidious y se retiró al pantano de Dagobah. Desde allí esperó años, hasta que apareció un joven granjero llamado Luke Skywalker.

Murió a los 900 años y se volvió uno con la Fuerza, pero su voz sigue guiando a los Jedi mucho tiempo después.',
10, 1),
(@pid, 'ficha',        'Ficha del personaje',    NULL, NULL, 20, 1),
(@pid, 'cronologia',   'Línea de tiempo',        'De Dagobah a Dagobah, pasando por media galaxia', NULL, 30, 1),
(@pid, 'poderes',      'Poderes y habilidades',  'Lo que lo hizo un Gran Maestro', NULL, 40, 1),
(@pid, 'frases',       'Frases icónicas',        'Sabiduría en pocas palabras', NULL, 50, 1),
(@pid, 'apariciones',  'Apariciones',            'Películas y series donde lo vas a encontrar', NULL, 60, 1),
(@pid, 'curiosidades', 'Datos curiosos',         'Detrás de cámaras y más allá de la pantalla', NULL, 70, 1),
(@pid, 'figura',       'Sobre esta figura',      'El objeto que te trajo hasta acá', NULL, 80, 1);

-- ----------------------------------------------------------------------------
-- Ficha técnica
-- ----------------------------------------------------------------------------
INSERT INTO personaje_datos (personaje_id, etiqueta, valor, orden) VALUES
(@pid, 'Nombre',            'Yoda', 1),
(@pid, 'Especie',           'Desconocida (nunca revelada)', 2),
(@pid, 'Mundo natal',       'Desconocido', 3),
(@pid, 'Nacimiento',        'Aprox. 896 a.B.Y.', 4),
(@pid, 'Fallecimiento',     '4 d.B.Y., en Dagobah (a los 900 años)', 5),
(@pid, 'Altura',            '66 cm', 6),
(@pid, 'Sable de luz',      'Hoja verde', 7),
(@pid, 'Afiliación',        'Orden Jedi · República Galáctica', 8),
(@pid, 'Rango',             'Gran Maestro Jedi · Alto Consejo Jedi', 9),
(@pid, 'Primera aparición', 'El imperio contraataca (1980)', 10),
(@pid, 'Voz y titiritero',  'Frank Oz (cine) · Tom Kane (animación)', 11);

-- ----------------------------------------------------------------------------
-- Cronología
-- ----------------------------------------------------------------------------
INSERT INTO cronologia (personaje_id, etiqueta_fecha, fecha_orden, titulo, descripcion, categoria) VALUES
(@pid, 'Aprox. 896 a.B.Y.', -896, 'Nacimiento',
 'Yoda nace en un mundo que jamás se reveló. Su especie tampoco tiene nombre en la saga.', 'origen'),
(@pid, 'Siglos de servicio', -500, 'Maestro de generaciones Jedi',
 'Durante unos 800 años instruye a jóvenes Jedi y asciende hasta convertirse en Gran Maestro de la Orden y miembro del Alto Consejo.', 'orden'),
(@pid, '32 a.B.Y.', -32, 'La amenaza fantasma',
 'En el Consejo Jedi se muestra reticente a entrenar al joven Anakin Skywalker: percibe miedo en él y advierte adónde puede llevarlo.', 'consejo'),
(@pid, '22 a.B.Y.', -22, 'Batalla de Geonosis',
 'Llega al frente de un ejército de clones para rescatar a los Jedi y se enfrenta en duelo de sables al Conde Dooku, que logra escapar. Comienzan las Guerras Clon.', 'batalla'),
(@pid, '22 – 19 a.B.Y.', -21, 'Las Guerras Clon',
 'Como Gran Maestro, combina el mando en el campo de batalla con su lugar en el Consejo, mientras la República se hunde en la guerra.', 'batalla'),
(@pid, '19 a.B.Y.', -19, 'La Orden 66',
 'Siente a distancia la muerte de sus hermanos Jedi. Sobrevive junto a los wookiees en Kashyyyk y regresa a Coruscant.', 'traicion'),
(@pid, '19 a.B.Y.', -18, 'Duelo contra Darth Sidious',
 'Se enfrenta al Emperador en el Senado. No logra derrotarlo, pero sobrevive y es evacuado con ayuda de Bail Organa.', 'batalla'),
(@pid, '19 a.B.Y. – 3 d.B.Y.', -17, 'Exilio en Dagobah',
 'Se oculta durante más de dos décadas en un pantano lejano, esperando el momento de transmitir lo que sabe.', 'exilio'),
(@pid, '3 d.B.Y.', 3, 'Entrena a Luke Skywalker',
 'Luke llega a Dagobah buscando a un gran guerrero y encuentra a un anciano diminuto. Yoda lo pone a prueba y comienza su instrucción.', 'maestro'),
(@pid, '4 d.B.Y.', 4, 'Se vuelve uno con la Fuerza',
 'A los 900 años, ya muy débil, confirma a Luke su destino y muere en paz, convirtiéndose en un fantasma de la Fuerza.', 'muerte'),
(@pid, '34 d.B.Y.', 34, 'Reaparece como fantasma de la Fuerza',
 'Aparece ante un Luke desanimado en Ahch-To y le recuerda que el fracaso también enseña.', 'legado');

-- ----------------------------------------------------------------------------
-- Poderes y habilidades
-- ----------------------------------------------------------------------------
INSERT INTO poderes (personaje_id, nombre, descripcion, icono, orden) VALUES
(@pid, 'Maestría en la Fuerza',
 'Uno de los usuarios de la Fuerza más poderosos de su época. Levitó con la mente un caza X-wing hundido en el pantano de Dagobah, una proeza que dejó mudo a Luke.', 'fuerza', 1),
(@pid, 'Sable de luz acrobático',
 'Con su sable de hoja verde combinaba la Fuerza y una agilidad asombrosa. Dominaba la Forma IV (Ataru), un estilo basado en saltos y giros veloces.', 'sable', 2),
(@pid, 'Absorber y devolver relámpagos',
 'En su duelo contra Darth Sidious absorbió los rayos de la Fuerza que le lanzó y los desvió, un acto de control fuera de lo común.', 'rayo', 3),
(@pid, 'Premonición y sensibilidad',
 'Percibía los cambios en la Fuerza a enormes distancias: sintió la muerte de los Jedi durante la Orden 66 estando a años luz.', 'vision', 4),
(@pid, 'Enseñanza y paciencia',
 'Su mayor don fue formar a otros. Entrenó a generaciones de Jedi y supo ver en cada alumno lo que necesitaba aprender.', 'maestro', 5),
(@pid, 'Fantasma de la Fuerza',
 'Aprendió de Qui-Gon Jinn a conservar su conciencia más allá de la muerte, y pudo seguir guiando a quienes lo necesitaban.', 'espiritu', 6);

-- ----------------------------------------------------------------------------
-- Frases icónicas (traducciones libres al español)
-- ----------------------------------------------------------------------------
INSERT INTO frases (personaje_id, texto, texto_original, fuente, contexto, orden) VALUES
(@pid, 'Hazlo, o no lo hagas. Pero no lo intentes.',
 'Do or do not. There is no try.',
 'El imperio contraataca (1980)',
 'Le dice a Luke cuando duda de poder sacar su nave del pantano.', 1),
(@pid, 'El tamaño no importa. Mírame a mí. ¿Me juzgas por mi tamaño?',
 'Size matters not. Look at me. Judge me by my size, do you?',
 'El imperio contraataca (1980)',
 'En su primera charla con Luke, antes de revelarle quién es.', 2),
(@pid, 'Seres luminosos somos, no esta materia burda.',
 'Luminous beings are we, not this crude matter.',
 'El imperio contraataca (1980)',
 'Explicándole a Luke qué es realmente la Fuerza.', 3),
(@pid, 'Siempre en movimiento está el futuro.',
 'Always in motion is the future.',
 'El imperio contraataca (1980)',
 'Sobre lo difícil que es ver con claridad lo que vendrá.', 4),
(@pid, 'El miedo es el camino hacia el lado oscuro: el miedo lleva a la ira, la ira lleva al odio, el odio lleva al sufrimiento.',
 'Fear is the path to the dark side. Fear leads to anger. Anger leads to hate. Hate leads to suffering.',
 'La amenaza fantasma (1999)',
 'Advertencia sobre el joven Anakin Skywalker.', 5),
(@pid, 'Entrénate para soltar todo aquello que temes perder.',
 'Train yourself to let go of everything you fear to lose.',
 'La venganza de los Sith (2005)',
 'Consejo a Anakin sobre el apego.', 6),
(@pid, 'Transmite lo que has aprendido.',
 'Pass on what you have learned.',
 'El retorno del Jedi (1983)',
 'Sus últimas palabras a Luke antes de volverse uno con la Fuerza.', 7),
(@pid, 'El mayor maestro, el fracaso es.',
 'The greatest teacher, failure is.',
 'Los últimos Jedi (2017)',
 'Como fantasma de la Fuerza, consolando a Luke en Ahch-To.', 8);

-- ----------------------------------------------------------------------------
-- Apariciones
-- ----------------------------------------------------------------------------
INSERT INTO apariciones (personaje_id, titulo, tipo, anio, interprete, notas, orden) VALUES
(@pid, 'Star Wars: Episodio V – El imperio contraataca', 'pelicula', 1980, 'Frank Oz (titiritero y voz)',
 'Su debut: aparece en el pantano de Dagobah y entrena a Luke Skywalker.', 1),
(@pid, 'Star Wars: Episodio VI – El retorno del Jedi', 'pelicula', 1983, 'Frank Oz (titiritero y voz)',
 'Muere a los 900 años y se vuelve uno con la Fuerza.', 2),
(@pid, 'Star Wars: Episodio I – La amenaza fantasma', 'pelicula', 1999, 'Frank Oz (titiritero y voz)',
 'Primera película de la trilogía precuela: Yoda en el Consejo Jedi.', 3),
(@pid, 'Star Wars: Episodio II – El ataque de los clones', 'pelicula', 2002, 'Frank Oz (voz)',
 'Primera vez que se lo ve en versión totalmente digital y también empuñando su sable de luz.', 4),
(@pid, 'Star Wars: Episodio III – La venganza de los Sith', 'pelicula', 2005, 'Frank Oz (voz)',
 'La Orden 66, el exilio y el duelo contra Darth Sidious.', 5),
(@pid, 'Star Wars: The Clone Wars', 'serie', 2008, 'Tom Kane (voz)',
 'La guerra vista desde el frente y los consejos de Yoda a sus Jedi.', 6),
(@pid, 'Star Wars: The Bad Batch', 'serie', 2021, 'Tom Kane (voz)',
 'Aparece en los primeros momentos tras la caída de la República.', 7),
(@pid, 'Star Wars: Episodio VIII – Los últimos Jedi', 'pelicula', 2017, 'Frank Oz (voz)',
 'Reaparece como fantasma de la Fuerza ante Luke Skywalker.', 8),
(@pid, 'Star Wars: Episodio IX – El ascenso de Skywalker', 'pelicula', 2019, 'Frank Oz (voz)',
 'Su voz se escucha entre los Jedi del pasado que guían a Rey.', 9);

-- ----------------------------------------------------------------------------
-- Curiosidades
-- ----------------------------------------------------------------------------
INSERT INTO curiosidades (personaje_id, titulo, texto, orden) VALUES
(@pid, 'Habla al revés',
 'Yoda construye sus frases con el orden objeto-sujeto-verbo ("Cuando 900 años tengas, tan bien no te verás"), lo que le da su cadencia inconfundible.', 1),
(@pid, 'Un titiritero muy famoso',
 'En las películas originales Yoda era una marioneta manejada y doblada por Frank Oz, que también dio vida a personajes de Los Muppets como Miss Piggy.', 2),
(@pid, 'Su primer sable de luz en pantalla',
 'En "El ataque de los clones" Yoda pasó de marioneta a personaje digital y, por primera vez, se lo vio combatir con un sable de luz.', 3),
(@pid, 'Una primera impresión engañosa',
 'En "El imperio contraataca", cuando Luke llega al pantano, Yoda se hace pasar por una criatura traviesa para ponerlo a prueba.', 4),
(@pid, 'Misterio sin resolver',
 'La especie y el mundo natal de Yoda nunca fueron revelados. De su especie se conoce a muy pocos: la Jedi Yaddle y, más tarde, el pequeño Grogu.', 5),
(@pid, 'Diseño de la marioneta',
 'El diseño de su rostro estuvo a cargo del maquillador Stuart Freeborn, que según se cuenta tomó rasgos de su propio rostro y del de Albert Einstein.', 6),
(@pid, 'Tamaño y edad',
 'Mide solo 66 centímetros y vivió unos 900 años: toda una demostración de que, como él decía, el tamaño no importa.', 7);
