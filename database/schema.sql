-- ============================================================================
--  FIGURAS QR · Esquema de base de datos (MariaDB / MySQL)
--  Motor: InnoDB · Codificación: utf8mb4
--
--  Idea de diseño
--  --------------
--  * Un PERSONAJE es el contenido (Yoda hoy; mañana cualquier otro).
--  * Una FIGURA es el objeto físico (tu impresión 3D) que lleva el código QR.
--    Un personaje puede tener varias figuras y cada figura tiene un `codigo`
--    único, que es lo que va dentro del QR:  .../index.html?f=yoda-01
--  * Todo el contenido (cronología, frases, poderes...) cuelga de `personajes`
--    con ON DELETE CASCADE, así que agregar otro personaje = insertar filas,
--    sin tocar ni una línea de HTML/JS/PHP.
--  * `secciones` decide QUÉ secciones se muestran, en QUÉ orden y con QUÉ título
--    para cada personaje.
--
--  Cómo usarlo
--  -----------
--  1) Crear la base (ej. figuras_qr) y ejecutar este archivo dentro de ella.
--  2) Ejecutar después database/seed_yoda.sql
--  (o simplemente:  php database/instalar.php  — ver README.md)
-- ============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- personajes: una fila por personaje / tema de página
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS personajes (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  slug          VARCHAR(80)      NOT NULL,                 -- 'yoda' (URL amigable, único)
  nombre        VARCHAR(120)     NOT NULL,
  titulo        VARCHAR(160)     NULL,                     -- 'Gran Maestro de la Orden Jedi'
  universo      VARCHAR(120)     NULL,                     -- 'Star Wars'
  resumen       TEXT             NULL,                     -- frase/párrafo de portada
  imagen_hero   VARCHAR(255)     NULL,                     -- ruta relativa, ej. assets/img/yoda-hero.jpg
  tema          VARCHAR(40)      NOT NULL DEFAULT 'dagobah', -- clase CSS: tema-<tema>
  activo        TINYINT(1)       NOT NULL DEFAULT 1,
  orden         SMALLINT         NOT NULL DEFAULT 0,       -- orden en el catálogo
  creado_en     TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_personajes_slug (slug),
  KEY ix_personajes_activo_orden (activo, orden)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- figuras: el objeto físico (3D) que lleva el QR
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS figuras (
  id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  personaje_id   INT UNSIGNED  NOT NULL,
  codigo         VARCHAR(60)   NOT NULL,                   -- el que va en el QR: 'yoda-01'
  nombre         VARCHAR(160)  NOT NULL,
  autor          VARCHAR(160)  NULL,
  descripcion    TEXT          NULL,
  materiales     VARCHAR(255)  NULL,                       -- ej. 'PLA verde, impresión FDM'
  escala         VARCHAR(60)   NULL,                       -- ej. '1:6', '15 cm de alto'
  fecha_creacion DATE          NULL,
  imagen_url     VARCHAR(255)  NULL,                       -- foto de TU figura
  modelo_url     VARCHAR(255)  NULL,                       -- .glb/.stl para descarga o visor (futuro)
  activo         TINYINT(1)    NOT NULL DEFAULT 1,
  creado_en      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_figuras_codigo (codigo),
  KEY ix_figuras_personaje (personaje_id),
  CONSTRAINT fk_figuras_personaje FOREIGN KEY (personaje_id)
    REFERENCES personajes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- secciones: qué se muestra, en qué orden y con qué título (por personaje)
--   clave = tipo de render que conoce el JS: biografia, cronologia, poderes,
--           frases, apariciones, curiosidades, galeria, figura, texto (genérica)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS secciones (
  id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  personaje_id  INT UNSIGNED  NOT NULL,
  clave         VARCHAR(40)   NOT NULL,
  titulo        VARCHAR(160)  NOT NULL,
  subtitulo     VARCHAR(255)  NULL,
  contenido     MEDIUMTEXT    NULL,                        -- párrafos separados por línea en blanco
  orden         SMALLINT      NOT NULL DEFAULT 0,
  visible       TINYINT(1)    NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_secciones_personaje_clave (personaje_id, clave),
  KEY ix_secciones_orden (personaje_id, visible, orden),
  CONSTRAINT fk_secciones_personaje FOREIGN KEY (personaje_id)
    REFERENCES personajes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- personaje_datos: ficha técnica (pares etiqueta / valor)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS personaje_datos (
  id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  personaje_id  INT UNSIGNED  NOT NULL,
  etiqueta      VARCHAR(80)   NOT NULL,
  valor         VARCHAR(255)  NOT NULL,
  orden         SMALLINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY ix_datos_personaje (personaje_id, orden),
  CONSTRAINT fk_datos_personaje FOREIGN KEY (personaje_id)
    REFERENCES personajes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- cronologia: línea de tiempo
--   etiqueta_fecha = lo que se lee ('896 a.B.Y.'); fecha_orden = número para ordenar
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cronologia (
  id              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  personaje_id    INT UNSIGNED  NOT NULL,
  etiqueta_fecha  VARCHAR(60)   NOT NULL,
  fecha_orden     INT           NOT NULL DEFAULT 0,
  titulo          VARCHAR(160)  NOT NULL,
  descripcion     TEXT          NULL,
  categoria       VARCHAR(40)   NULL,                      -- 'batalla', 'origen', 'exilio'...
  PRIMARY KEY (id),
  KEY ix_cronologia_personaje (personaje_id, fecha_orden),
  CONSTRAINT fk_cronologia_personaje FOREIGN KEY (personaje_id)
    REFERENCES personajes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- poderes: habilidades
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS poderes (
  id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  personaje_id  INT UNSIGNED  NOT NULL,
  nombre        VARCHAR(120)  NOT NULL,
  descripcion   TEXT          NULL,
  icono         VARCHAR(40)   NULL,                        -- nombre de icono del set del front
  orden         SMALLINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY ix_poderes_personaje (personaje_id, orden),
  CONSTRAINT fk_poderes_personaje FOREIGN KEY (personaje_id)
    REFERENCES personajes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- frases
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS frases (
  id              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  personaje_id    INT UNSIGNED  NOT NULL,
  texto           VARCHAR(500)  NOT NULL,                  -- en español
  texto_original  VARCHAR(500)  NULL,                      -- idioma original
  fuente          VARCHAR(160)  NULL,                      -- película / episodio
  contexto        VARCHAR(500)  NULL,
  orden           SMALLINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY ix_frases_personaje (personaje_id, orden),
  CONSTRAINT fk_frases_personaje FOREIGN KEY (personaje_id)
    REFERENCES personajes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- apariciones: películas, series, juegos, libros...
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS apariciones (
  id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  personaje_id  INT UNSIGNED  NOT NULL,
  titulo        VARCHAR(200)  NOT NULL,
  tipo          ENUM('pelicula','serie','videojuego','libro','comic','otro') NOT NULL DEFAULT 'pelicula',
  anio          SMALLINT      NULL,
  interprete    VARCHAR(160)  NULL,                        -- voz / titiritero / actor
  notas         VARCHAR(500)  NULL,
  orden         SMALLINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY ix_apariciones_personaje (personaje_id, anio, orden),
  CONSTRAINT fk_apariciones_personaje FOREIGN KEY (personaje_id)
    REFERENCES personajes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- curiosidades
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS curiosidades (
  id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  personaje_id  INT UNSIGNED  NOT NULL,
  titulo        VARCHAR(160)  NULL,
  texto         TEXT          NOT NULL,
  orden         SMALLINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY ix_curiosidades_personaje (personaje_id, orden),
  CONSTRAINT fk_curiosidades_personaje FOREIGN KEY (personaje_id)
    REFERENCES personajes (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- media: galería (imágenes propias, videos, modelos 3D)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS media (
  id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  personaje_id  INT UNSIGNED  NOT NULL,
  figura_id     INT UNSIGNED  NULL,
  tipo          ENUM('imagen','video','modelo3d','audio') NOT NULL DEFAULT 'imagen',
  url           VARCHAR(255)  NOT NULL,
  titulo        VARCHAR(160)  NULL,
  descripcion   VARCHAR(500)  NULL,
  creditos      VARCHAR(160)  NULL,
  orden         SMALLINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  KEY ix_media_personaje (personaje_id, orden),
  CONSTRAINT fk_media_personaje FOREIGN KEY (personaje_id)
    REFERENCES personajes (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_media_figura FOREIGN KEY (figura_id)
    REFERENCES figuras (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- visitas: cuántas veces se escaneó cada QR (la IP se guarda hasheada)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS visitas (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  personaje_id  INT UNSIGNED    NOT NULL,
  figura_id     INT UNSIGNED    NULL,
  visitado_en   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ip_hash       CHAR(64)        NOT NULL,
  agente        VARCHAR(255)    NULL,
  PRIMARY KEY (id),
  KEY ix_visitas_personaje_fecha (personaje_id, visitado_en),
  KEY ix_visitas_figura_fecha (figura_id, visitado_en),
  KEY ix_visitas_dedupe (ip_hash, figura_id, visitado_en),
  CONSTRAINT fk_visitas_personaje FOREIGN KEY (personaje_id)
    REFERENCES personajes (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_visitas_figura FOREIGN KEY (figura_id)
    REFERENCES figuras (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
