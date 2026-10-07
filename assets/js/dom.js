/**
 * dom.js · utilidades para construir HTML de forma segura.
 * Todo texto entra con textContent (nunca innerHTML), así que el contenido
 * que venga de la base de datos no puede inyectar código en la página.
 */
(function (global) {
  'use strict';

  var SVG_NS = 'http://www.w3.org/2000/svg';

  /**
   * h('div', { class: 'x', 'data-a': 1 }, 'texto', otroNodo, ...)
   * Atributos null/false/undefined se omiten. Los que empiezan con "on" son eventos.
   */
  function h(tag, attrs) {
    var el = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach(function (k) {
        var v = attrs[k];
        if (v === null || v === undefined || v === false) return;
        if (k.indexOf('on') === 0 && typeof v === 'function') {
          el.addEventListener(k.slice(2).toLowerCase(), v);
        } else if (k === 'class') {
          el.className = v;
        } else if (v === true) {
          el.setAttribute(k, '');
        } else {
          el.setAttribute(k, v);
        }
      });
    }
    for (var i = 2; i < arguments.length; i++) append(el, arguments[i]);
    return el;
  }

  function append(el, hijo) {
    if (hijo === null || hijo === undefined || hijo === false) return;
    if (Array.isArray(hijo)) { hijo.forEach(function (x) { append(el, x); }); return; }
    el.appendChild(hijo.nodeType ? hijo : document.createTextNode(String(hijo)));
  }

  /** Crea un <svg> a partir de una lista de "d" de paths (viewBox 24x24). */
  function svg(paths) {
    var s = document.createElementNS(SVG_NS, 'svg');
    s.setAttribute('viewBox', '0 0 24 24');
    s.setAttribute('aria-hidden', 'true');
    paths.forEach(function (d) {
      var p = document.createElementNS(SVG_NS, 'path');
      p.setAttribute('d', d);
      s.appendChild(p);
    });
    return s;
  }

  function vaciar(el) { while (el.firstChild) el.removeChild(el.firstChild); }

  /** Muestra un aviso breve abajo de la pantalla. */
  var temporizadorAviso;
  function aviso(texto) {
    var el = document.getElementById('aviso');
    if (!el) return;
    el.textContent = texto;
    el.classList.add('activo');
    clearTimeout(temporizadorAviso);
    temporizadorAviso = setTimeout(function () { el.classList.remove('activo'); }, 2200);
  }

  /** localStorage/sessionStorage pueden fallar (modo privado): nunca romper la página. */
  function almacen(tipo) {
    return {
      leer: function (k) { try { return global[tipo].getItem(k); } catch (e) { return null; } },
      guardar: function (k, v) { try { global[tipo].setItem(k, v); } catch (e) { /* ignorar */ } }
    };
  }

  global.DOM = { h: h, svg: svg, vaciar: vaciar, aviso: aviso, almacen: almacen };
})(window);
