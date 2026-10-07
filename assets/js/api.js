/**
 * api.js · comunicación con los scripts PHP de /api
 * Las rutas son relativas, así que funciona en cualquier carpeta de XAMPP o hosting.
 */
(function (global) {
  'use strict';

  function pedir(url, opciones) {
    return fetch(url, opciones).then(function (resp) {
      return resp.json().catch(function () { return {}; }).then(function (cuerpo) {
        if (!resp.ok) {
          var err = new Error(cuerpo.error || 'Error ' + resp.status);
          err.estado = resp.status;
          throw err;
        }
        return cuerpo;
      });
    });
  }

  var API = {
    personaje: function (parametros) {
      var q = Object.keys(parametros).map(function (k) {
        return encodeURIComponent(k) + '=' + encodeURIComponent(parametros[k]);
      }).join('&');
      return pedir('api/personaje.php?' + q);
    },

    catalogo: function () {
      return pedir('api/personajes.php');
    },

    /** Registra el escaneo del QR. Falla en silencio: nunca debe molestar al visitante. */
    visita: function (datos) {
      return fetch('api/visita.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(datos),
        keepalive: true
      }).catch(function () { /* ignorar */ });
    }
  };

  global.API = API;
})(window);
