<?php
require_once __DIR__ . '/config.php';

/** Cabeceras comunes de la API JSON. */
function cabeceras_api(bool $cache = true): void
{
    header('Content-Type: application/json; charset=utf-8');
    header('X-Content-Type-Options: nosniff');
    header('Referrer-Policy: same-origin');
    header($cache ? 'Cache-Control: public, max-age=60' : 'Cache-Control: no-store');
}

function responder(array $datos, int $codigo = 200): void
{
    http_response_code($codigo);
    echo json_encode($datos, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}

function responder_error(string $mensaje, int $codigo = 400, ?Throwable $e = null): void
{
    $cuerpo = ['error' => $mensaje];
    if ($e !== null && cargar_config()['APP_DEBUG']) {
        $cuerpo['detalle'] = $e->getMessage();
    }
    responder($cuerpo, $codigo);
}

/** Solo letras, números, guion y guion bajo (slugs y códigos de figura). */
function limpiar_slug(?string $valor, int $max = 80): string
{
    $valor = strtolower(trim((string) $valor));
    $valor = preg_replace('/[^a-z0-9_\-]/', '', $valor);
    return substr($valor, 0, $max);
}

/** Convierte tinyint/int de MySQL a tipos reales de JSON. */
function tipar(array $fila, array $enteros = [], array $booleanos = []): array
{
    foreach ($enteros as $k) {
        if (array_key_exists($k, $fila) && $fila[$k] !== null) {
            $fila[$k] = (int) $fila[$k];
        }
    }
    foreach ($booleanos as $k) {
        if (array_key_exists($k, $fila)) {
            $fila[$k] = (bool) $fila[$k];
        }
    }
    return $fila;
}

/** Solo permite rutas relativas al sitio o URLs http(s) para imágenes/modelos. */
function url_segura(?string $url): ?string
{
    if ($url === null || $url === '') {
        return null;
    }
    if (preg_match('#^(https?://|[A-Za-z0-9_./\-]+$)#', $url) && strpos($url, '..') === false) {
        return $url;
    }
    return null;
}
