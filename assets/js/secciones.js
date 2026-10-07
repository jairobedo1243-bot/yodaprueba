/**
 * secciones.js · un "renderizador" por cada tipo de sección (secciones.clave).
 *
 * Para AGREGAR un tipo nuevo de sección en el futuro:
 *   1) Creá la tabla/columnas necesarias y devolvelas desde api/personaje.php.
 *   2) Agregá acá una función  Secciones.renderizadores.mi_clave = function (datos, seccion) {...}
 *      que devuelva un nodo DOM (o null si no hay nada que mostrar).
 *   3) Insertá una fila en `secciones` con esa clave para el personaje.
 * Las claves desconocidas se muestran como texto simple (sus párrafos).
 */
(function (global) {
  'use strict';

  var h = DOM.h;

  /* ---- Iconos de poderes (viewBox 24, trazo) ------------------------------ */
  var ICONOS = {
    fuerza:   ['M12 12m-2 0a2 2 0 1 0 4 0a2 2 0 1 0 -4 0', 'M12 12m-6 0a6 6 0 1 0 12 0a6 6 0 1 0 -12 0', 'M12 12m-10 0a10 10 0 1 0 20 0a10 10 0 1 0 -20 0'],
    sable:    ['M4 20l3-3', 'M7 17L18 6', 'M16.5 4.5l3 3', 'M5.5 15.5l3 3'],
    rayo:     ['M13 2L4 14h7l-1 8 9-12h-7z'],
    vision:   ['M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z', 'M12 12m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0'],
    maestro:  ['M2 8l10-5 10 5-10 5z', 'M6 10.5V16c0 1.4 2.7 3 6 3s6-1.6 6-3v-5.5'],
    espiritu: ['M12 3c3 3.2 5 5.4 5 9a5 5 0 0 1-10 0c0-3.6 2-5.8 5-9z', 'M10 13a2 2 0 0 0 2 2'],
    estrella: ['M12 3l2.6 5.6 6.1.7-4.5 4.2 1.2 6L12 16.6 6.6 19.5l1.2-6L3.3 9.3l6.1-.7z']
  };

  var TIPOS = {
    pelicula: 'Película', serie: 'Serie', videojuego: 'Videojuego',
    libro: 'Libro', comic: 'Cómic', otro: 'Otro'
  };

  var COLOR_CATEGORIA = {
    origen: 'var(--cat-origen)', orden: 'var(--cat-orden)', consejo: 'var(--cat-consejo)',
    batalla: 'var(--cat-batalla)', traicion: 'var(--cat-traicion)', exilio: 'var(--cat-exilio)',
    maestro: 'var(--cat-maestro)', muerte: 'var(--cat-muerte)', legado: 'var(--cat-legado)'
  };

  function lista(x) { return Array.isArray(x) && x.length ? x : null; }

  var R = {};

  /* ---- Texto de sección ---------------------------------------------------- */
  R.biografia = function (d, s) {
    if (!lista(s.parrafos)) return null;
    return h('div', { class: 'bio' }, s.parrafos.map(function (t) { return h('p', null, t); }));
  };

  R.texto = R.biografia;

  /* ---- Ficha técnica ------------------------------------------------------- */
  R.ficha = function (d) {
    if (!lista(d.ficha)) return null;
    return h('dl', { class: 'ficha' }, d.ficha.map(function (f) {
      return h('div', { class: 'ficha__item' }, h('dt', null, f.etiqueta), h('dd', null, f.valor));
    }));
  };

  /* ---- Línea de tiempo ----------------------------------------------------- */
  R.cronologia = function (d) {
    if (!lista(d.cronologia)) return null;
    return h('ol', { class: 'linea' }, d.cronologia.map(function (e) {
      var color = COLOR_CATEGORIA[e.categoria] || 'var(--acento)';
      return h('li', { class: 'linea__item revelar', style: '--punto:' + color },
        h('span', { class: 'linea__punto', 'aria-hidden': 'true' }),
        h('span', { class: 'linea__fecha' }, e.etiqueta_fecha),
        h('h3', null, e.titulo),
        e.descripcion ? h('p', null, e.descripcion) : null
      );
    }));
  };

  /* ---- Poderes ------------------------------------------------------------- */
  R.poderes = function (d) {
    if (!lista(d.poderes)) return null;
    return h('div', { class: 'rejilla' }, d.poderes.map(function (p) {
      return h('article', { class: 'tarjeta poder revelar' },
        h('div', { class: 'poder__icono' }, DOM.svg(ICONOS[p.icono] || ICONOS.estrella)),
        h('div', null, h('h3', null, p.nombre), p.descripcion ? h('p', null, p.descripcion) : null)
      );
    }));
  };

  /* ---- Frases -------------------------------------------------------------- */
  R.frases = function (d) {
    if (!lista(d.frases)) return null;
    return h('div', { class: 'rejilla' }, d.frases.map(function (f) {
      return h('figure', { class: 'tarjeta frase revelar' },
        h('blockquote', { class: 'frase__texto' }, f.texto),
        h('figcaption', null,
          f.fuente ? h('p', { class: 'frase__fuente' }, f.fuente) : null,
          f.contexto ? h('p', { class: 'frase__contexto' }, f.contexto) : null,
          f.texto_original
            ? h('details', null, h('summary', null, 'Ver en idioma original'), h('p', { lang: 'en' }, f.texto_original))
            : null
        )
      );
    }));
  };

  /* ---- Apariciones (con filtro por tipo) ----------------------------------- */
  R.apariciones = function (d) {
    if (!lista(d.apariciones)) return null;

    var tipos = [];
    d.apariciones.forEach(function (a) { if (tipos.indexOf(a.tipo) === -1) tipos.push(a.tipo); });

    var ul = h('ul', { class: 'apariciones' });
    var botones = [];

    function pintar(filtro) {
      DOM.vaciar(ul);
      d.apariciones.forEach(function (a) {
        if (filtro !== 'todas' && a.tipo !== filtro) return;
        ul.appendChild(h('li', { class: 'tarjeta aparicion' },
          h('div', { class: 'aparicion__anio' }, a.anio || '—'),
          h('div', null,
            h('h3', null, a.titulo),
            h('div', { class: 'aparicion__meta' },
              h('span', { class: 'etiqueta' }, TIPOS[a.tipo] || a.tipo),
              a.interprete ? h('span', null, a.interprete) : null
            ),
            a.notas ? h('p', null, a.notas) : null
          )
        ));
      });
      botones.forEach(function (b) { b.el.setAttribute('aria-pressed', String(b.valor === filtro)); });
    }

    var barra = null;
    if (tipos.length > 1) {
      var opciones = [{ valor: 'todas', texto: 'Todas' }].concat(tipos.map(function (t) {
        return { valor: t, texto: (TIPOS[t] || t) + 's' };
      }));
      barra = h('div', { class: 'filtros', role: 'group', 'aria-label': 'Filtrar apariciones' },
        opciones.map(function (o) {
          var el = h('button', { type: 'button', class: 'chip', onclick: function () { pintar(o.valor); } }, o.texto);
          botones.push({ el: el, valor: o.valor });
          return el;
        }));
    }
    pintar('todas');
    return h('div', null, barra, ul);
  };

  /* ---- Curiosidades -------------------------------------------------------- */
  R.curiosidades = function (d) {
    if (!lista(d.curiosidades)) return null;
    return h('div', { class: 'rejilla' }, d.curiosidades.map(function (c, i) {
      return h('article', { class: 'tarjeta curio revelar' },
        h('span', { class: 'curio__num', 'aria-hidden': 'true' }, String(i + 1)),
        c.titulo ? h('h3', null, c.titulo) : null,
        h('p', null, c.texto)
      );
    }));
  };

  /* ---- Galería ------------------------------------------------------------- */
  R.galeria = function (d) {
    if (!lista(d.media)) return null;
    return h('div', { class: 'galeria' }, d.media.filter(function (m) { return m.url; }).map(function (m) {
      var pieza = null;
      if (m.tipo === 'imagen') pieza = h('img', { src: m.url, alt: m.titulo || '', loading: 'lazy' });
      else if (m.tipo === 'video') pieza = h('video', { src: m.url, controls: true, preload: 'metadata' });
      else pieza = h('a', { href: m.url, class: 'boton', target: '_blank', rel: 'noopener' }, m.titulo || 'Abrir archivo');
      return h('figure', { class: 'revelar' }, pieza,
        (m.titulo || m.creditos) ? h('figcaption', null, [m.titulo, m.creditos].filter(Boolean).join(' · ')) : null);
    }));
  };

  /* ---- Sobre esta figura 3D + compartir ------------------------------------ */
  R.figura = function (d) {
    var f = d.figura;
    var urlPagina = location.origin + location.pathname + (f ? '?f=' + encodeURIComponent(f.codigo) : '?p=' + encodeURIComponent(d.personaje.slug));

    var datos = [];
    if (f) {
      if (f.autor)          datos.push(['Creada por', f.autor]);
      if (f.materiales)     datos.push(['Materiales', f.materiales]);
      if (f.escala)         datos.push(['Escala', f.escala]);
      if (f.fecha_creacion) datos.push(['Fecha', formatearFecha(f.fecha_creacion)]);
      datos.push(['Código de figura', f.codigo]);
    }

    var info = f ? h('div', null,
      h('h3', null, f.nombre),
      f.descripcion ? h('p', null, f.descripcion) : null,
      datos.length ? h('dl', { class: 'figura__datos' }, datos.map(function (x) {
        return h('div', null, h('dt', null, x[0]), h('dd', null, x[1]));
      })) : null,
      f.modelo_url ? h('p', { style: 'margin-top:1rem' },
        h('a', { class: 'boton', href: f.modelo_url, download: true }, 'Descargar modelo 3D')) : null
    ) : null;

    var foto = f && f.imagen_url
      ? h('div', { class: 'figura__foto' }, h('img', { src: f.imagen_url, alt: 'Foto de ' + f.nombre, loading: 'lazy' }))
      : null;

    var compartir = h('div', { class: 'tarjeta compartir revelar' },
      h('h3', null, 'Compartí esta página'),
      h('div', { class: 'compartir__qr', role: 'img', 'aria-label': 'Código QR de esta página' }, safeQR(urlPagina)),
      h('div', { class: 'compartir__acciones' },
        h('button', { type: 'button', class: 'boton', onclick: function () { copiar(urlPagina); } }, 'Copiar enlace'),
        navigator.share ? h('button', { type: 'button', class: 'boton boton--primario', onclick: function () {
          navigator.share({ title: d.personaje.nombre, text: 'Mirá la historia de ' + d.personaje.nombre, url: urlPagina }).catch(function () {});
        } }, 'Compartir') : null
      )
    );

    return h('div', { class: 'figura' + (foto ? '' : ' figura--sin-foto') },
      foto, info ? h('div', { class: 'revelar' }, info) : null, compartir);
  };

  function safeQR(url) {
    try { return QR.svg(url); } catch (e) { return h('span', null, ''); }
  }

  function copiar(texto) {
    var ok = function () { DOM.aviso('Enlace copiado'); };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(texto).then(ok, function () { DOM.aviso(texto); });
    } else {
      var t = h('textarea', { style: 'position:fixed;opacity:0' });
      t.value = texto;
      document.body.appendChild(t);
      t.select();
      try { document.execCommand('copy'); ok(); } catch (e) { DOM.aviso(texto); }
      document.body.removeChild(t);
    }
  }

  function formatearFecha(iso) {
    var p = String(iso).split('-');
    return p.length === 3 ? p[2] + '/' + p[1] + '/' + p[0] : iso;
  }

  global.Secciones = { renderizadores: R };
})(window);
