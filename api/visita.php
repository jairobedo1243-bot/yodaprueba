<?php
/**
 * POST api/visita.php   { "figura": "yoda-01" }   o   { "slug": "yoda" }
 * Registra una visita (escaneo de QR). La IP se guarda solo como hash con sal.
 * Ignora repeticiones del mismo dispositivo en la misma figura durante 30 minutos.
 */
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/helpers.php';

cabeceras_api(false);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    responder_error('Método no permitido', 405);
}

$entrada = json_decode(file_get_contents('php://input') ?: '', true);
$entrada = is_array($entrada) ? $entrada : [];
$codigo  = limpiar_slug($entrada['figura'] ?? '', 60);
$slug    = limpiar_slug($entrada['slug']   ?? '');
if ($codigo === '' && $slug === '') {
    responder_error('Falta figura o slug', 400);
}

try {
    $pdo = db();

    $figuraId = null;
    if ($codigo !== '') {
        $st = $pdo->prepare('SELECT id, personaje_id FROM figuras WHERE codigo = ? AND activo = 1 LIMIT 1');
        $st->execute([$codigo]);
        $f = $st->fetch();
        if (!$f) {
            responder_error('Figura no encontrada', 404);
        }
        $figuraId   = (int) $f['id'];
        $personajeId = (int) $f['personaje_id'];
    } else {
        $st = $pdo->prepare('SELECT id FROM personajes WHERE slug = ? AND activo = 1 LIMIT 1');
        $st->execute([$slug]);
        $p = $st->fetch();
        if (!$p) {
            responder_error('Personaje no encontrado', 404);
        }
        $personajeId = (int) $p['id'];
    }

    $ip     = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
    $ipHash = hash('sha256', $ip . '|' . cargar_config()['IP_SALT']);
    $agente = substr((string) ($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255);

    // Anti-repetición (30 minutos).
    $st = $pdo->prepare(
        'SELECT 1 FROM visitas
          WHERE ip_hash = ? AND personaje_id = ? AND (figura_id <=> ?)
            AND visitado_en > (NOW() - INTERVAL 30 MINUTE) LIMIT 1'
    );
    $st->execute([$ipHash, $personajeId, $figuraId]);
    if ($st->fetch()) {
        responder(['ok' => true, 'registrada' => false]);
    }

    $st = $pdo->prepare('INSERT INTO visitas (personaje_id, figura_id, ip_hash, agente) VALUES (?, ?, ?, ?)');
    $st->execute([$personajeId, $figuraId, $ipHash, $agente]);
    responder(['ok' => true, 'registrada' => true]);
} catch (Throwable $e) {
    responder_error('No se pudo registrar la visita', 500, $e);
}
