# Yoda · Figura 3D con código QR

Página web pensada para que quien escanee el QR de tu figura vea toda la información de Yoda (historia, línea de tiempo, poderes, frases, apariciones y curiosidades). Está construida para crecer: más personajes, más figuras y más secciones sin reescribir código.

## Cómo funciona

```
Celular escanea el QR  →  index.html?f=yoda-01
                              │  (JavaScript)
                              ▼
                     api/personaje.php?figura=yoda-01   (PHP + PDO)
                              │
                              ▼
                     MariaDB · base «figuras_qr»
```

- **HTML** (`index.html`): una sola página; el contenido lo dibuja el JavaScript.
- **CSS** (`assets/css/`): `base.css` (layout y componentes) + `tema-dagobah.css` (colores y atmósfera). Cambiar de estilo = cambiar un archivo de tema.
- **JavaScript** (`assets/js/`): `api.js` (pide los datos), `secciones.js` (cómo se dibuja cada tipo de sección), `app.js` (arranque, navegación, efectos), `qr.js` (generador de QR sin internet).
- **PHP** (`api/`): endpoints JSON con consultas preparadas. Las credenciales están en `api/.env`.
- **Base de datos** (`database/`): `schema.sql` (tablas), `seed_yoda.sql` (datos de Yoda), `instalar.php` (instalador).

## Instalación en XAMPP (Windows)

1. Copiá la carpeta `yoda-qr` dentro de `C:\xampp\htdocs\` (o la carpeta `htdocs` de tu instalación).
2. Iniciá **Apache** y **MySQL/MariaDB** desde el panel de XAMPP.
3. En `api\`, copiá `.env.example` como `.env` y revisá los datos. Por defecto XAMPP usa puerto `3306`, usuario `root` y sin contraseña. Si tu MariaDB corre en otro puerto (por ejemplo `3310`), cambialo en `DB_PORT`.
4. Cargá la base de datos, con **una** de estas dos opciones:
   - **Línea de comandos:** abrí una terminal en la carpeta del proyecto y ejecutá  
     `C:\xampp\php\php.exe database\instalar.php`
   - **phpMyAdmin:** creá una base llamada `figuras_qr` (cotejamiento `utf8mb4_unicode_ci`), y en ella importá primero `database/schema.sql` y después `database/seed_yoda.sql`.
5. Abrí `http://localhost/yoda-qr/index.html`.

## Hacer que el QR funcione desde los celulares

El QR tiene que apuntar a una dirección que el celular pueda alcanzar. `localhost` solo existe en tu PC.

1. Conectá el celular al mismo WiFi que tu PC.
2. En la PC ejecutá `ipconfig` y anotá la **Dirección IPv4** (por ejemplo `192.168.1.20`).
3. Abrí `http://localhost/yoda-qr/herramientas/qr.html`, cambiá `localhost` por esa IP en el campo de dirección y descargá el QR en PNG o SVG.
4. Si el celular no carga la página, permití **Apache (puerto 80)** en el Firewall de Windows para redes privadas.

Si más adelante subís el sitio a un hosting con dominio propio, solo hay que volver a generar el QR con la nueva dirección (y crear la base en el hosting con los mismos archivos `.sql`, ajustando `api/.env`).

## Datos de tu figura

La sección «Sobre esta figura» muestra lo que cargues en la tabla `figuras`. Desde phpMyAdmin o con esta consulta:

```sql
UPDATE figuras
   SET autor = 'Tu nombre',
       materiales = 'PLA verde, impresión FDM',
       escala = '15 cm de alto',
       fecha_creacion = '2026-09-15',
       imagen_url = 'assets/img/mi-figura.jpg'      -- foto de tu figura (copiala a esa carpeta)
 WHERE codigo = 'yoda-01';
```

Los campos vacíos no se muestran. Si cargás `imagen_url` (o `personajes.imagen_hero`), la foto reemplaza al emblema de la portada. También podés cargar `modelo_url` con un archivo `.glb` o `.stl` para que se pueda descargar.

## Agregar más páginas en el futuro

| Quiero… | Qué hago |
|---|---|
| Otro personaje con su QR | Copiar `database/plantilla_personaje.sql`, completarla y ejecutar `php database\instalar.php seed_<nombre>`. Aparece solo en el catálogo (`index.html`) y con su figura en `?f=<codigo>`. |
| Otra figura del mismo personaje | Insertar una fila en `figuras` con un `codigo` nuevo. |
| Cambiar el orden o los títulos de las secciones | Editar la tabla `secciones` (`orden`, `titulo`, `visible`). |
| Un diseño distinto para otro personaje | Copiar `tema-dagobah.css` como `tema-<nombre>.css` y poner ese nombre en `personajes.tema`. |
| Un tipo de sección nuevo | Crear la tabla, devolverla en `api/personaje.php` y sumar un renderizador en `assets/js/secciones.js`. |

URLs que entiende `index.html`: `?f=yoda-01` (figura, lo que va en el QR), `?p=yoda` (personaje) y sin parámetros (el personaje por defecto de `.env`, o el catálogo si hay varios).

## Base de datos

| Tabla | Para qué sirve |
|---|---|
| `personajes` | Un registro por personaje (nombre, título, resumen, tema visual). |
| `figuras` | El objeto físico con QR; un personaje puede tener varias. |
| `secciones` | Qué secciones se muestran, su orden y títulos. |
| `personaje_datos`, `cronologia`, `poderes`, `frases`, `apariciones`, `curiosidades`, `media` | El contenido, todo ligado al personaje con `ON DELETE CASCADE`. |
| `visitas` | Registro de escaneos (la IP se guarda solo como hash). |

Cantidad de escaneos por figura:

```sql
SELECT f.codigo, COUNT(*) AS escaneos, DATE(v.visitado_en) AS dia
  FROM visitas v JOIN figuras f ON f.id = v.figura_id
 GROUP BY f.codigo, dia ORDER BY dia DESC;
```

## Seguridad

- Todas las consultas usan sentencias preparadas (PDO) y los slugs se validan.
- El contenido se inserta en la página con `textContent`, nunca con `innerHTML`, así que un texto de la base no puede inyectar código.
- `api/.htaccess` bloquea el acceso web a `.env`, `config.php`, `db.php` y `helpers.php`; `database/.htaccess` bloquea los `.sql`. Esto funciona con Apache de XAMPP o de casi cualquier hosting. En producción conviene además un usuario de base de datos propio (no `root`).
- `instalar.php` solo corre desde la línea de comandos.

## Créditos y aviso

Información basada en el universo de Star Wars. Es un proyecto de fans sin fines de lucro; Yoda y Star Wars pertenecen a sus respectivos titulares. El generador de QR usa la librería `qrcode-generator` de Kazuhiko Arase (licencia MIT), incluida en `assets/js/vendor/`.
