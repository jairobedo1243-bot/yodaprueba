<?php
/**
 * GET api/personajes.php
 * Catálogo de personajes activos (para cuando haya más de uno).
 */
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/helpers.php';

cabeceras_api();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Método no permitido', 405);
}

try {
    $filas = db()->query(
        'SELECT slug, nombre, titulo, universo, resumen, imagen_hero, tema
           FROM personajes WHERE activo = 1 ORDER BY orden, nombre'
    )->fetchAll();

    foreach ($filas as &$f) {
        $f['imagen_hero'] = url_segura($f['imagen_hero']);
        $f['tema']        = limpiar_slug($f['tema'], 40) ?: 'dagobah';
    }
    unset($f);

    $defecto = limpiar_slug(cargar_config()['DEFAULT_PERSONAJE'] ?? '');
    responder(['personajes' => $filas, 'por_defecto' => $defecto !== '' ? $defecto : null]);
} catch (Throwable $e) {
    responder_error('No se pudo leer el catálogo', 500, $e);
}
