/**
 * api.js · obtiene los datos del personaje.
 *
 * Dos modos (se elige solo):
 *   · PHP  -> api/*.php + MariaDB (XAMPP u otro hosting con PHP)
 *   · ESTÁTICO -> archivos datos/*.json generados con database/exportar_estatico.php
 *                 (GitHub Pages y otros hostings sin PHP)
 *
 * Reglas:
 *   - En *.github.io (o con <meta name="modo-datos" content="estatico">) va directo al modo estático.
 *   - En cualquier otro lugar prueba PHP primero; si ahí no hay PHP (el servidor no devuelve JSON),
 *     cae al modo estático automáticamente.
 * Las rutas son relativas: funciona en cualquier carpeta o subcarpeta (/yodaprueba/).
 */
(function (global) {
  'use strict';

  var meta = document.querySelector('meta[name="modo-datos"]');
  var forzarEstatico = /\.github\.io$/i.test(location.hostname) ||
                       (meta && meta.getAttribute('content') === 'estatico');

  function pedir(url, opciones) {
    return fetch(url, opciones).then(function (resp) {
      return resp.json().then(
        function (cuerpo) { return { resp: resp, cuerpo: cuerpo, json: true }; },
        function () { return { resp: resp, cuerpo: {}, json: false }; }
      );
    }).then(function (r) {
      if (!r.resp.ok || !r.json) {
        var err = new Error(r.cuerpo.error || 'Error ' + r.resp.status);
        err.estado = r.resp.status;
        err.sinApi = !r.json;          // el servidor no devolvió JSON: no hay PHP detrás
        throw err;
      }
      return r.cuerpo;
    });
  }

  /** ¿Conviene reintentar con los archivos estáticos? */
  function sinPhp(err) { return !err.estado || err.sinApi; }

  function conRespaldo(php, estatico) {
    if (forzarEstatico) return estatico();
    return php().catch(function (err) {
      if (sinPhp(err)) return estatico();
      throw err;
    });
  }

  function limpio(x) { return String(x).replace(/[^a-z0-9_\-]/gi, '').toLowerCase(); }

  var API = {
    personaje: function (p) {
      var porFigura = !!p.figura;
      var php = function () {
        var q = Object.keys(p).map(function (k) {
          return encodeURIComponent(k) + '=' + encodeURIComponent(p[k]);
        }).join('&');
        return pedir('api/personaje.php?' + q);
      };
      var estatico = function () {
        var archivo = porFigura ? 'f-' + limpio(p.figura) : 'p-' + limpio(p.slug);
        return pedir('datos/' + archivo + '.json');
      };
      return conRespaldo(php, estatico);
    },

    catalogo: function () {
      return conRespaldo(
        function () { return pedir('api/personajes.php'); },
        function () { return pedir('datos/personajes.json'); }
      );
    },

    /** Registra el escaneo del QR (solo con PHP). Falla en silencio: nunca debe molestar al visitante. */
    visita: function (datos) {
      if (forzarEstatico) return Promise.resolve();
      return fetch('api/visita.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(datos),
        keepalive: true
      }).catch(function () { /* ignorar */ });
    },

    modoEstatico: function () { return forzarEstatico; }
  };

  global.API = API;
})(window);
