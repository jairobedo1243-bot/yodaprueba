<?php
/**
 * Configuración: lee api/.env (nunca se sube al repositorio ni es accesible por web).
 * Si no existe .env se usan valores por defecto pensados para XAMPP.
 */

function cargar_config(): array
{
    static $cfg = null;
    if ($cfg !== null) {
        return $cfg;
    }

    $cfg = [
        'DB_HOST'   => '127.0.0.1',
        'DB_PORT'   => 3306,
        'DB_NAME'   => 'figuras_qr',
        'DB_USER'   => 'root',
        'DB_PASS'   => '',
        'APP_DEBUG' => false,
        'IP_SALT'   => 'cambiar-esta-sal',
        'DEFAULT_PERSONAJE' => '',
    ];

    $archivo = __DIR__ . '/.env';
    if (is_readable($archivo)) {
        foreach (file($archivo, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $linea) {
            $linea = trim($linea);
            if ($linea === '' || $linea[0] === '#' || strpos($linea, '=') === false) {
                continue;
            }
            [$clave, $valor] = array_map('trim', explode('=', $linea, 2));
            $valor = trim($valor, " \t\"'");
            if (array_key_exists($clave, $cfg)) {
                $cfg[$clave] = $valor;
            }
        }
    }

    $cfg['DB_PORT']   = (int) $cfg['DB_PORT'];
    $cfg['APP_DEBUG'] = in_array(strtolower((string) $cfg['APP_DEBUG']), ['1', 'true', 'si', 'yes'], true);
    return $cfg;
}
