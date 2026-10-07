<?php
/**
 * Instalador por línea de comandos.
 *
 *   php database/instalar.php            -> crea la BD (si no existe), tablas y seed de Yoda
 *   php database/instalar.php --solo-tablas
 *   php database/instalar.php seed_otro  -> carga además database/seed_otro.sql
 *
 * Lee las credenciales de api/.env (copiá api/.env.example a api/.env primero).
 * Por seguridad NO se puede ejecutar desde el navegador.
 */

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit('Este script solo se ejecuta desde la línea de comandos.');
}

require __DIR__ . '/../api/config.php';

$args      = array_slice($argv, 1);
$soloTablas = in_array('--solo-tablas', $args, true);
$seeds      = array_values(array_filter($args, fn($a) => strpos($a, '--') !== 0));
if (!$soloTablas && !$seeds) {
    $seeds = ['seed_yoda'];
}

$cfg = cargar_config();

try {
    // 1) Conexión al servidor (sin elegir BD) para poder crearla.
    $dsnServidor = sprintf('mysql:host=%s;port=%d;charset=utf8mb4', $cfg['DB_HOST'], $cfg['DB_PORT']);
    $pdo = new PDO($dsnServidor, $cfg['DB_USER'], $cfg['DB_PASS'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);

    $bd = preg_replace('/[^A-Za-z0-9_]/', '', $cfg['DB_NAME']);
    if ($bd === '') {
        throw new RuntimeException('DB_NAME inválido en api/.env');
    }
    $pdo->exec("CREATE DATABASE IF NOT EXISTS `$bd` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("USE `$bd`");
    echo "Base de datos lista: $bd\n";

    // 2) Esquema y seeds.
    ejecutar_archivo($pdo, __DIR__ . '/schema.sql');
    echo "Tablas creadas / verificadas.\n";

    foreach ($seeds as $seed) {
        $seed = preg_replace('/[^A-Za-z0-9_\-]/', '', $seed);
        $ruta = __DIR__ . "/$seed.sql";
        if (!is_file($ruta)) {
            throw new RuntimeException("No existe $seed.sql");
        }
        ejecutar_archivo($pdo, $ruta);
        echo "Cargado: $seed.sql\n";
    }
    echo "Listo. Probá en el navegador: http://localhost/<carpeta>/index.html\n";
} catch (Throwable $e) {
    fwrite(STDERR, 'ERROR: ' . $e->getMessage() . "\n");
    exit(1);
}

/** Ejecuta un .sql sentencia por sentencia (respeta comillas y comentarios). */
function ejecutar_archivo(PDO $pdo, string $ruta): void
{
    $sql = file_get_contents($ruta);
    if ($sql === false) {
        throw new RuntimeException("No se pudo leer $ruta");
    }
    foreach (dividir_sentencias($sql) as $sentencia) {
        $pdo->exec($sentencia);
    }
}

function dividir_sentencias(string $sql): array
{
    $sentencias = [];
    $actual     = '';
    $len        = strlen($sql);
    $enComilla  = false;

    for ($i = 0; $i < $len; $i++) {
        $c = $sql[$i];

        if ($enComilla) {
            $actual .= $c;
            if ($c === '\\' && $i + 1 < $len) {          // escape \'
                $actual .= $sql[++$i];
            } elseif ($c === "'") {
                if ($i + 1 < $len && $sql[$i + 1] === "'") { // '' dentro de cadena
                    $actual .= $sql[++$i];
                } else {
                    $enComilla = false;
                }
            }
            continue;
        }

        // Comentario de línea (-- ...) fuera de cadenas
        if ($c === '-' && $i + 1 < $len && $sql[$i + 1] === '-') {
            while ($i < $len && $sql[$i] !== "\n") {
                $i++;
            }
            $actual .= "\n";
            continue;
        }

        if ($c === "'") {
            $enComilla = true;
            $actual   .= $c;
        } elseif ($c === ';') {
            if (trim($actual) !== '') {
                $sentencias[] = trim($actual);
            }
            $actual = '';
        } else {
            $actual .= $c;
        }
    }
    if (trim($actual) !== '') {
        $sentencias[] = trim($actual);
    }
    return $sentencias;
}
