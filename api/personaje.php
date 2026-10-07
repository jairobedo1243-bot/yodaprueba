<?php
/**
 * GET api/personaje.php?slug=yoda
 * GET api/personaje.php?figura=yoda-01     (lo que trae el QR)
 *
 * Devuelve TODO el contenido de un personaje en un solo JSON:
 * { personaje, figura, secciones[], ficha[], cronologia[], poderes[],
 *   frases[], apariciones[], curiosidades[], media[] }
 */
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/helpers.php';

cabeceras_api();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    responder_error('Método no permitido', 405);
}

$slug   = limpiar_slug($_GET['slug']   ?? '');
$codigo = limpiar_slug($_GET['figura'] ?? '', 60);
if ($slug === '' && $codigo === '') {
    responder_error('Falta el parámetro slug o figura', 400);
}

try {
    $pdo = db();

    // 1) Buscar el personaje (directo o a través del código de la figura).
    $figura = null;
    if ($codigo !== '') {
        $st = $pdo->prepare('SELECT * FROM figuras WHERE codigo = ? AND activo = 1 LIMIT 1');
        $st->execute([$codigo]);
        $figura = $st->fetch() ?: null;
        if (!$figura) {
            responder_error('Figura no encontrada', 404);
        }
        $st = $pdo->prepare('SELECT * FROM personajes WHERE id = ? AND activo = 1 LIMIT 1');
        $st->execute([$figura['personaje_id']]);
    } else {
        $st = $pdo->prepare('SELECT * FROM personajes WHERE slug = ? AND activo = 1 LIMIT 1');
        $st->execute([$slug]);
    }
    $p = $st->fetch();
    if (!$p) {
        responder_error('Personaje no encontrado', 404);
    }
    $pid = (int) $p['id'];

    // 2) Figura por defecto del personaje si se entró por slug.
    if ($figura === null) {
        $st = $pdo->prepare('SELECT * FROM figuras WHERE personaje_id = ? AND activo = 1 ORDER BY id LIMIT 1');
        $st->execute([$pid]);
        $figura = $st->fetch() ?: null;
    }

    // Helper: lista de filas ordenadas de una tabla hija.
    $lista = function (string $sql) use ($pdo, $pid): array {
        $st = $pdo->prepare($sql);
        $st->execute([$pid]);
        return $st->fetchAll();
    };

    $secciones = array_map(function ($s) {
        $s = tipar($s, ['id', 'orden']);
        $texto = trim((string) ($s['contenido'] ?? ''));
        $s['parrafos'] = $texto === '' ? [] : array_values(array_filter(
            array_map('trim', preg_split('/\R{2,}/', $texto))
        ));
        unset($s['contenido'], $s['personaje_id'], $s['visible']);
        return $s;
    }, $lista('SELECT * FROM secciones WHERE personaje_id = ? AND visible = 1 ORDER BY orden, id'));

    $media = array_map(function ($m) {
        $m = tipar($m, ['id', 'orden']);
        $m['url'] = url_segura($m['url']);
        return $m;
    }, $lista('SELECT id, tipo, url, titulo, descripcion, creditos, orden FROM media WHERE personaje_id = ? ORDER BY orden, id'));

    $salida = [
        'personaje' => [
            'slug'        => $p['slug'],
            'nombre'      => $p['nombre'],
            'titulo'      => $p['titulo'],
            'universo'    => $p['universo'],
            'resumen'     => $p['resumen'],
            'imagen_hero' => url_segura($p['imagen_hero']),
            'tema'        => limpiar_slug($p['tema'], 40) ?: 'dagobah',
        ],
        'figura' => $figura ? [
            'codigo'         => $figura['codigo'],
            'nombre'         => $figura['nombre'],
            'autor'          => $figura['autor'],
            'descripcion'    => $figura['descripcion'],
            'materiales'     => $figura['materiales'],
            'escala'         => $figura['escala'],
            'fecha_creacion' => $figura['fecha_creacion'],
            'imagen_url'     => url_segura($figura['imagen_url']),
            'modelo_url'     => url_segura($figura['modelo_url']),
        ] : null,
        'secciones'    => $secciones,
        'ficha'        => $lista('SELECT etiqueta, valor FROM personaje_datos WHERE personaje_id = ? ORDER BY orden, id'),
        'cronologia'   => $lista('SELECT etiqueta_fecha, titulo, descripcion, categoria FROM cronologia WHERE personaje_id = ? ORDER BY fecha_orden, id'),
        'poderes'      => $lista('SELECT nombre, descripcion, icono FROM poderes WHERE personaje_id = ? ORDER BY orden, id'),
        'frases'       => $lista('SELECT texto, texto_original, fuente, contexto FROM frases WHERE personaje_id = ? ORDER BY orden, id'),
        'apariciones'  => array_map(fn($a) => tipar($a, ['anio']),
            $lista('SELECT titulo, tipo, anio, interprete, notas FROM apariciones WHERE personaje_id = ? ORDER BY anio, orden, id')),
        'curiosidades' => $lista('SELECT titulo, texto FROM curiosidades WHERE personaje_id = ? ORDER BY orden, id'),
        'media'        => $media,
    ];

    responder($salida);
} catch (Throwable $e) {
    responder_error('No se pudo leer la información', 500, $e);
}
