/**
 * app.js · punto de entrada.
 *
 * URLs que entiende:
 *   index.html?f=yoda-01   -> la figura (es lo que va dentro del QR)
 *   index.html?p=yoda      -> el personaje directamente
 *   index.html             -> el personaje por defecto (.env DEFAULT_PERSONAJE)
 *                             o el catálogo si hay varios personajes
 */
(function () {
  'use strict';

  var h = DOM.h;
  var app = document.getElementById('app');
  var params = new URLSearchParams(location.search);
  var codigoFigura = (params.get('f') || '').toLowerCase().replace(/[^a-z0-9_\-]/g, '').slice(0, 60);
  var slugPersonaje = (params.get('p') || '').toLowerCase().replace(/[^a-z0-9_\-]/g, '').slice(0, 80);

  var ETIQUETA_NAV = {
    biografia: 'Historia', ficha: 'Ficha', cronologia: 'Línea de tiempo', poderes: 'Poderes',
    frases: 'Frases', apariciones: 'Apariciones', curiosidades: 'Curiosidades',
    galeria: 'Galería', figura: 'La figura'
  };

  /* ====================================================================== */
  /*  Arranque                                                              */
  /* ====================================================================== */
  function iniciar() {
    mostrarCargando();
    var promesa;

    if (codigoFigura) {
      promesa = API.personaje({ figura: codigoFigura }).then(pintarPersonaje);
    } else if (slugPersonaje) {
      promesa = API.personaje({ slug: slugPersonaje }).then(pintarPersonaje);
    } else {
      promesa = API.catalogo().then(function (r) {
        var lista = r.personajes || [];
        if (r.por_defecto && lista.some(function (p) { return p.slug === r.por_defecto; })) {
          return API.personaje({ slug: r.por_defecto }).then(pintarPersonaje);
        }
        if (lista.length === 1) {
          return API.personaje({ slug: lista[0].slug }).then(pintarPersonaje);
        }
        if (lista.length === 0) {
          throw Object.assign(new Error('Todavía no hay personajes cargados.'), { estado: 404 });
        }
        pintarCatalogo(lista);
      });
    }

    promesa.catch(function (err) { pintarError(err); });
  }

  /* ====================================================================== */
  /*  Pantallas                                                             */
  /* ====================================================================== */
  function mostrarCargando() {
    DOM.vaciar(app);
    app.appendChild(h('main', { id: 'contenido', tabindex: '-1' },
      h('div', { class: 'estado', role: 'status', 'aria-live': 'polite' },
        h('div', { class: 'cargador', 'aria-hidden': 'true' }),
        h('p', null, 'Conectando con la Fuerza…'))));
  }

  function pintarError(err) {
    var noEncontrado = err && err.estado === 404;
    document.title = noEncontrado ? 'No encontrado' : 'Sin conexión';
    DOM.vaciar(app);
    app.appendChild(h('main', { id: 'contenido', tabindex: '-1' },
      h('div', { class: 'estado', role: 'alert' },
        h('h1', null, noEncontrado ? 'No encontramos esto' : 'Algo salió mal'),
        h('p', null, noEncontrado
          ? 'La figura o el personaje que buscás no existe o ya no está disponible.'
          : 'No pudimos cargar la información. Revisá tu conexión e intentá de nuevo.'),
        h('div', { class: 'hero__acciones' },
          h('button', { type: 'button', class: 'boton boton--primario', onclick: iniciar }, 'Reintentar'),
          (codigoFigura || slugPersonaje)
            ? h('a', { class: 'boton', href: location.pathname }, 'Ir al inicio') : null))));
  }

  function pintarCatalogo(lista) {
    document.title = 'Figuras 3D · Catálogo';
    DOM.vaciar(app);
    app.appendChild(barra('Figuras', ' · 3D', []));
    app.appendChild(h('main', { id: 'contenido', tabindex: '-1' },
      h('div', { class: 'contenedor seccion' },
        h('header', { class: 'seccion__cabecera' },
          h('div', { class: 'sable', 'aria-hidden': 'true' }),
          h('h1', { style: 'font-size:clamp(2rem,9vw,3rem)' }, 'Catálogo de figuras'),
          h('p', { class: 'seccion__sub' }, 'Elegí un personaje para ver toda su historia.')),
        h('div', { class: 'catalogo' }, lista.map(function (p) {
          return h('a', { href: '?p=' + encodeURIComponent(p.slug) },
            h('article', { class: 'tarjeta' },
              h('h2', null, p.nombre),
              p.titulo ? h('span', { class: 'etiqueta' }, p.titulo) : null,
              p.resumen ? h('p', null, p.resumen) : null));
        })))));
    app.appendChild(pie(null, null));
    crearLuciernagas();
  }

  /* ====================================================================== */
  /*  Página de personaje                                                   */
  /* ====================================================================== */
  function pintarPersonaje(d) {
    var p = d.personaje;
    aplicarTema(p.tema);
    document.title = p.nombre + ' · Figura 3D';
    var meta = document.querySelector('meta[name="description"]');
    if (meta && p.resumen) meta.setAttribute('content', p.resumen);

    // Secciones: las que el renderizador pueda dibujar (si no hay datos, se omiten).
    var renderizadores = Secciones.renderizadores;
    var bloques = [];
    d.secciones.forEach(function (s) {
      var fn = renderizadores[s.clave] || renderizadores.texto;
      var cuerpo = fn(d, s);
      if (!cuerpo) return;
      bloques.push({ clave: s.clave, titulo: s.titulo, nodo: seccion(s, cuerpo) });
    });

    var enlaces = bloques.map(function (b) {
      return { id: 'sec-' + b.clave, texto: ETIQUETA_NAV[b.clave] || b.titulo };
    });

    DOM.vaciar(app);
    app.appendChild(barra(p.nombre, ' · 3D', enlaces));
    var claves = bloques.map(function (b) { return b.clave; });
    var main = h('main', { id: 'contenido', tabindex: '-1' }, hero(d, claves), bloques.map(function (b) { return b.nodo; }));
    app.appendChild(main);
    app.appendChild(pie(p, d.figura));

    crearLuciernagas();
    activarReveal();
    activarNavegacion(enlaces);
    registrarVisita(d);
  }

  function aplicarTema(tema) {
    tema = /^[a-z0-9_\-]{1,40}$/.test(tema || '') ? tema : 'dagobah';
    document.body.className = 'tema-' + tema;
    var link = document.getElementById('tema-css');
    if (link && tema !== 'dagobah') {
      link.setAttribute('href', 'assets/css/tema-' + tema + '.css');
    }
  }

  function barra(nombre, sufijo, enlaces) {
    return h('header', { class: 'barra' },
      h('div', { class: 'contenedor barra__fila' },
        h('a', { class: 'barra__marca', href: '#contenido', 'aria-label': nombre + ' – inicio de la página' },
          nombre.toUpperCase(), h('span', null, sufijo)),
        enlaces.length ? h('nav', { 'aria-label': 'Secciones' },
          h('ul', { class: 'nav-secciones', id: 'nav-secciones' }, enlaces.map(function (e) {
            return h('li', null, h('a', { href: '#' + e.id, 'data-sec': e.id }, e.texto));
          }))) : null));
  }

  function hero(d, claves) {
    var p = d.personaje, f = d.figura;
    var foto = p.imagen_hero || (f && f.imagen_url) || null;
    var viaQR = !!codigoFigura;

    var visual = foto
      ? h('div', { class: 'hero__foto' }, h('img', { src: foto, alt: f ? 'Foto de ' + f.nombre : p.nombre }))
      : h('div', { class: 'emblema', role: 'img', 'aria-label': 'Emblema de la figura de ' + p.nombre },
          h('div', { class: 'emblema__centro' },
            h('div', { class: 'emblema__nombre' }, p.nombre),
            f ? h('span', { class: 'emblema__codigo' }, f.codigo) : null));

    return h('section', { class: 'hero', 'aria-labelledby': 'titulo-personaje' },
      h('div', { class: 'contenedor hero__grid' },
        h('div', null,
          h('span', { class: 'hero__etiqueta' }, viaQR ? 'Escaneaste la figura' : (p.universo || 'Personaje')),
          h('h1', { id: 'titulo-personaje' }, p.nombre),
          p.titulo ? h('p', { class: 'hero__titulo' }, p.titulo) : null,
          h('div', { class: 'sable', 'aria-hidden': 'true' }),
          p.resumen ? h('p', { class: 'hero__resumen' }, p.resumen) : null,
          h('div', { class: 'hero__acciones' },
            claves.indexOf('biografia') !== -1 ? h('a', { class: 'boton boton--primario', href: '#sec-biografia',
              onclick: function (e) { irA(e, 'sec-biografia'); } }, 'Descubrir su historia') : null,
            claves.indexOf('figura') !== -1 ? h('a', { class: 'boton', href: '#sec-figura',
              onclick: function (e) { irA(e, 'sec-figura'); } }, 'Sobre la figura') : null)),
        h('div', null, visual)));
  }

  // Los botones del hero solo funcionan si existe la sección destino.
  function irA(e, id) {
    var el = document.getElementById(id);
    if (!el) return;
    e.preventDefault();
    el.scrollIntoView({ behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
    el.setAttribute('tabindex', '-1');
    el.focus({ preventScroll: true });
  }

  function seccion(s, cuerpo) {
    return h('section', { class: 'seccion', id: 'sec-' + s.clave, 'aria-labelledby': 'h-' + s.clave },
      h('div', { class: 'contenedor' },
        h('header', { class: 'seccion__cabecera revelar' },
          h('div', { class: 'sable', 'aria-hidden': 'true' }),
          h('h2', { id: 'h-' + s.clave }, s.titulo),
          s.subtitulo ? h('p', { class: 'seccion__sub' }, s.subtitulo) : null),
        cuerpo));
  }

  function pie(p, f) {
    var nota = p
      ? p.nombre + (p.universo ? ' es un personaje de ' + p.universo : ' es un personaje de ficción') +
        '. Este es un proyecto de fans sin fines de lucro: todos los derechos del personaje pertenecen a sus respectivos titulares.'
      : 'Proyecto de fans sin fines de lucro.';
    return h('footer', { class: 'pie' },
      h('p', null, f ? 'Página vinculada a la figura 3D «' + f.nombre + '» (' + f.codigo + ').' : 'Figuras 3D con código QR.'),
      h('p', null, nota));
  }

  /* ====================================================================== */
  /*  Efectos                                                               */
  /* ====================================================================== */
  var luciernagasCreadas = false;
  function crearLuciernagas() {
    if (luciernagasCreadas) return;
    var cont = document.getElementById('atmosfera');
    if (!cont) return;
    luciernagasCreadas = true;
    var n = matchMedia('(max-width: 640px)').matches ? 12 : 22;
    for (var i = 0; i < n; i++) {
      var l = h('span', { class: 'luciernaga' });
      l.style.left = (Math.random() * 100).toFixed(1) + '%';
      l.style.top = (30 + Math.random() * 70).toFixed(1) + '%';
      l.style.setProperty('--dur', (10 + Math.random() * 12).toFixed(1) + 's');
      l.style.setProperty('--delay', (-Math.random() * 14).toFixed(1) + 's');
      l.style.setProperty('--dx', (-60 + Math.random() * 120).toFixed(0) + 'px');
      l.style.setProperty('--dy', (-120 + Math.random() * 60).toFixed(0) + 'px');
      cont.appendChild(l);
    }
  }

  function activarReveal() {
    var elementos = document.querySelectorAll('.revelar');
    if (!('IntersectionObserver' in window)) {
      elementos.forEach(function (el) { el.classList.add('visible'); });
      return;
    }
    var io = new IntersectionObserver(function (entradas) {
      entradas.forEach(function (en) {
        if (en.isIntersecting) { en.target.classList.add('visible'); io.unobserve(en.target); }
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
    elementos.forEach(function (el) { io.observe(el); });
  }

  function activarNavegacion(enlaces) {
    if (!enlaces.length || !('IntersectionObserver' in window)) return;
    var nav = document.getElementById('nav-secciones');
    var io = new IntersectionObserver(function (entradas) {
      entradas.forEach(function (en) {
        if (!en.isIntersecting) return;
        nav.querySelectorAll('a').forEach(function (a) {
          var activo = a.getAttribute('data-sec') === en.target.id;
          if (activo) {
            a.setAttribute('aria-current', 'true');
            // Mantener visible el chip activo dentro de la barra deslizable
            var ancho = nav.clientWidth;
            nav.scrollTo({ left: a.offsetLeft - ancho / 2 + a.offsetWidth / 2, behavior: 'smooth' });
          } else {
            a.removeAttribute('aria-current');
          }
        });
      });
    }, { rootMargin: '-45% 0px -50% 0px' });
    enlaces.forEach(function (e) {
      var el = document.getElementById(e.id);
      if (el) io.observe(el);
    });
  }

  /* ====================================================================== */
  /*  Estadística de escaneos (una vez por sesión y figura)                 */
  /* ====================================================================== */
  function registrarVisita(d) {
    var clave = 'visita:' + (d.figura ? d.figura.codigo : d.personaje.slug);
    var sesion = DOM.almacen('sessionStorage');
    if (sesion.leer(clave)) return;
    sesion.guardar(clave, '1');
    API.visita(d.figura ? { figura: d.figura.codigo } : { slug: d.personaje.slug });
  }

  iniciar();
})();
