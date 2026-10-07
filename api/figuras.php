<?php
/**
 * GET api/figuras.php
 * Lista las figuras activas (código + nombre). Lo usa la herramienta de QR.
 */
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/helpers.php';

cabeceras_api();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Método no permitido', 405);
}

try {
    $filas = db()->query(
        'SELECT f.codigo, f.nombre, p.slug AS personaje, p.nombre AS personaje_nombre
           FROM figuras f JOIN personajes p ON p.id = f.personaje_id
          WHERE f.activo = 1 AND p.activo = 1
          ORDER BY p.orden, f.id'
    )->fetchAll();
    responder(['figuras' => $filas]);
} catch (Throwable $e) {
    responder_error('No se pudo leer la lista de figuras', 500, $e);
}
