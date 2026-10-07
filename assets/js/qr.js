/**
 * qr.js · envoltorio sencillo sobre vendor/qrcode.js (MIT, funciona sin internet).
 *   QR.svg('http://192.168.1.20/yoda-qr/?f=yoda-01')  -> elemento <svg>
 *   QR.pngDataUrl(texto, 1024)                         -> "data:image/png;base64,..."
 */
(function (global) {
  'use strict';

  function crear(texto, nivel) {
    var qr = global.qrcode(0, nivel || 'M');   // 0 = tamaño automático
    qr.addData(texto);
    qr.make();
    return qr;
  }

  /** Devuelve un <svg> escalable con el QR (fondo blanco, margen de 4 módulos). */
  function svg(texto, nivel) {
    var cadena = crear(texto, nivel).createSvgTag({ cellSize: 4, margin: 16, scalable: true });
    var doc = new DOMParser().parseFromString(cadena, 'image/svg+xml');
    var nodo = document.importNode(doc.documentElement, true);
    nodo.setAttribute('aria-hidden', 'true');
    return nodo;
  }

  /** PNG de alta resolución para imprimir o pegar en la figura. */
  function pngDataUrl(texto, tamanio, nivel) {
    var qr = crear(texto, nivel || 'Q');
    var n = qr.getModuleCount();
    var margen = 4;
    var celda = Math.max(1, Math.floor((tamanio || 1024) / (n + margen * 2)));
    var lado = celda * (n + margen * 2);
    var canvas = document.createElement('canvas');
    canvas.width = canvas.height = lado;
    var ctx = canvas.getContext('2d');
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, lado, lado);
    ctx.fillStyle = '#000000';
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (qr.isDark(r, c)) ctx.fillRect((c + margen) * celda, (r + margen) * celda, celda, celda);
      }
    }
    return canvas.toDataURL('image/png');
  }

  global.QR = { svg: svg, pngDataUrl: pngDataUrl };
})(window);
