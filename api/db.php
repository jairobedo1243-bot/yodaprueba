<?php
require_once __DIR__ . '/config.php';

/** Conexión PDO única (consultas siempre preparadas). */
function db(): PDO
{
    static $pdo = null;
    if ($pdo !== null) {
        return $pdo;
    }
    $c   = cargar_config();
    $dsn = sprintf(
        'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
        $c['DB_HOST'],
        $c['DB_PORT'],
        $c['DB_NAME']
    );
    $pdo = new PDO($dsn, $c['DB_USER'], $c['DB_PASS'], [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
    return $pdo;
}
