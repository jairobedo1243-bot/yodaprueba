-- ============================================================================
--  PLANTILLA · agregar un personaje nuevo (y su página con QR)
--  1) Copiá este archivo como database/seed_<slug>.sql
--  2) Reemplazá todos los «CAMBIAR» y borrá lo que no uses
--  3) Cargalo con:  php database/instalar.php seed_<slug>
--     (o importalo desde phpMyAdmin dentro de la base figuras_qr)
--  4) Generá el QR en herramientas/qr.html eligiendo la figura nueva
--
--  No hace falta tocar HTML, CSS, JS ni PHP.
--  Para un diseño distinto: copiá assets/css/tema-dagobah.css como tema-<nombre>.css,
--  cambiá las variables y poné ese nombre en la columna `tema`.
-- ============================================================================

SET NAMES utf8mb4;

INSERT INTO personajes (slug, nombre, titulo, universo, resumen, tema, activo, orden)
VALUES ('CAMBIAR-slug', 'CAMBIAR Nombre', 'CAMBIAR título', 'CAMBIAR universo',
        'CAMBIAR resumen de portada', 'dagobah', 1, 2)
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), titulo = VALUES(titulo),
  universo = VALUES(universo), resumen = VALUES(resumen), tema = VALUES(tema);

SET @pid := (SELECT id FROM personajes WHERE slug = 'CAMBIAR-slug');

DELETE FROM secciones       WHERE personaje_id = @pid;
DELETE FROM personaje_datos WHERE personaje_id = @pid;
DELETE FROM cronologia      WHERE personaje_id = @pid;
DELETE FROM poderes         WHERE personaje_id = @pid;
DELETE FROM frases          WHERE personaje_id = @pid;
DELETE FROM apariciones     WHERE personaje_id = @pid;
DELETE FROM curiosidades    WHERE personaje_id = @pid;

-- La figura física que llevará el QR (el código tiene que ser único)
INSERT INTO figuras (personaje_id, codigo, nombre, autor, materiales, escala, descripcion)
VALUES (@pid, 'CAMBIAR-01', 'CAMBIAR nombre de la figura', 'Tu nombre', 'PLA', '15 cm',
        'CAMBIAR descripción de la figura')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre), autor = VALUES(autor),
  materiales = VALUES(materiales), escala = VALUES(escala), descripcion = VALUES(descripcion);

-- Qué secciones se muestran y en qué orden.
-- Claves disponibles: biografia, ficha, cronologia, poderes, frases, apariciones,
--                     curiosidades, galeria, figura   (cualquier otra se muestra como texto)
-- Los párrafos de `contenido` se separan con una línea en blanco.
INSERT INTO secciones (personaje_id, clave, titulo, subtitulo, contenido, orden, visible) VALUES
(@pid, 'biografia',    'Quién es', NULL, 'CAMBIAR primer párrafo.

CAMBIAR segundo párrafo.', 10, 1),
(@pid, 'ficha',        'Ficha',        NULL, NULL, 20, 1),
(@pid, 'cronologia',   'Línea de tiempo', NULL, NULL, 30, 1),
(@pid, 'frases',       'Frases',       NULL, NULL, 50, 1),
(@pid, 'curiosidades', 'Datos curiosos', NULL, NULL, 70, 1),
(@pid, 'figura',       'Sobre esta figura', NULL, NULL, 80, 1);

INSERT INTO personaje_datos (personaje_id, etiqueta, valor, orden) VALUES
(@pid, 'CAMBIAR etiqueta', 'CAMBIAR valor', 1);

INSERT INTO cronologia (personaje_id, etiqueta_fecha, fecha_orden, titulo, descripcion, categoria) VALUES
(@pid, 'CAMBIAR fecha', 1, 'CAMBIAR evento', 'CAMBIAR descripción', 'origen');
-- categorías con color: origen, orden, consejo, batalla, traicion, exilio, maestro, muerte, legado

INSERT INTO frases (personaje_id, texto, texto_original, fuente, contexto, orden) VALUES
(@pid, 'CAMBIAR frase', NULL, 'CAMBIAR fuente', NULL, 1);

INSERT INTO curiosidades (personaje_id, titulo, texto, orden) VALUES
(@pid, 'CAMBIAR título', 'CAMBIAR texto', 1);
