/* FishMe en mouvement : groupe « lancement » (A Le bond, B Ronds dans l'eau, C Marée). Préfixe CSS : fmL- */
(function () {
  'use strict';
  var FM = window.FM, ASSETS = window.FMAssets;
  if (!FM || !ASSETS) return;

  /* ---------- CSS ---------- */
  var st = document.createElement('style');
  st.textContent = '.fmL-svg{position:absolute;left:0;top:0;width:100%;height:100%;display:block}';
  document.head.appendChild(st);

  /* ---------- géométrie de l'écran (390 x 844) ---------- */
  var W = 390, H = 844;
  var K = 52 / 32;                             // disque de lune : 104 px de large
  var MX = 195, MY = 388;                      // centre de la lune à l'écran (un peu au-dessus du milieu)
  var IX = MX - 50 * K, IY = MY - 48 * K;      // origine du repère du logo
  var MR = 32 * K;                             // rayon de la lune à l'écran
  var NAVY = '#0D4A85', TINT = '#F2F5F9';
  var BASE = 'translate(' + IX + ' ' + IY + ') scale(' + K + ')';
  var FISH_T = 'translate(50 46) rotate(-28) scale(.76 .46) translate(-50 -50)';
  var WATER_D = 'M0,74 C20,70 34,72 50,76 C66,72 80,70 100,74 L100,100 L0,100 Z';

  /* ---------- outils ---------- */
  var NS = 'http://www.w3.org/2000/svg', uidN = 0;
  function el(tag, attrs, parent) {
    var n = document.createElementNS(NS, tag);
    if (attrs) for (var k in attrs) n.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(n);
    return n;
  }
  function clamp(x, a, b) { return x < (a == null ? 0 : a) ? (a == null ? 0 : a) : x > (b == null ? 1 : b) ? (b == null ? 1 : b) : x; }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function seg(t, a, b) { return clamp((t - a) / (b - a)); }
  function bez(x1, y1, x2, y2) {
    var cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx;
    var cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by;
    return function (x) {
      if (x <= 0) return 0; if (x >= 1) return 1;
      var t = x, i, d, e;
      for (i = 0; i < 8; i++) {
        e = ((ax * t + bx) * t + cx) * t - x;
        if (Math.abs(e) < 1e-6) break;
        d = (3 * ax * t + 2 * bx) * t + cx;
        if (Math.abs(d) < 1e-6) break;
        t -= e / d;
      }
      t = clamp(t);
      return ((ay * t + by) * t + cy) * t;
    };
  }
  var eIO = bez(.65, 0, .35, 1), eOut = bez(.16, 1, .3, 1), eStd = bez(.4, 0, .2, 1), eIn = bez(.5, 0, .85, .45);
  // réponse d'un ressort amorti à un échelon (0 -> 1), temps en secondes
  function spring(t, w, z) {
    if (t <= 0) return 0;
    var wd = w * Math.sqrt(1 - z * z);
    return 1 - Math.exp(-z * w * t) * (Math.cos(wd * t) + (z * w / wd) * Math.sin(wd * t));
  }
  function hex(c) { return [parseInt(c.substr(1, 2), 16), parseInt(c.substr(3, 2), 16), parseInt(c.substr(5, 2), 16)]; }
  function mix(a, b, t) {
    var x = hex(a), y = hex(b);
    return 'rgb(' + Math.round(lerp(x[0], y[0], t)) + ',' + Math.round(lerp(x[1], y[1], t)) + ',' + Math.round(lerp(x[2], y[2], t)) + ')';
  }
  function f(n) { return Math.round(n * 100) / 100; }

  // hauteur de l'eau du logo (courbe statique), lue sur les deux Béziers
  var WTAB = (function () {
    var tab = [], segs = [[[0, 74], [20, 70], [34, 72], [50, 76]], [[50, 76], [66, 72], [80, 70], [100, 74]]];
    segs.forEach(function (p) {
      for (var i = 0; i <= 100; i++) {
        var t = i / 100, u = 1 - t;
        tab.push([u * u * u * p[0][0] + 3 * u * u * t * p[1][0] + 3 * u * t * t * p[2][0] + t * t * t * p[3][0],
                  u * u * u * p[0][1] + 3 * u * u * t * p[1][1] + 3 * u * t * t * p[2][1] + t * t * t * p[3][1]]);
      }
    });
    return tab;
  })();
  function staticY(x) {
    if (x <= 0) return 74; if (x >= 100) return 74;
    for (var i = 1; i < WTAB.length; i++) {
      if (WTAB[i][0] >= x) {
        var a = WTAB[i - 1], b = WTAB[i], d = b[0] - a[0];
        return d < 1e-9 ? b[1] : lerp(a[1], b[1], (x - a[0]) / d);
      }
    }
    return 74;
  }

  /* ---------- le logo, en pièces animables (même silhouette que logoSVG) ---------- */
  function logo(parent, uid) {
    var r = {};
    var defs = el('defs', null, parent);
    var gb = el('linearGradient', { id: uid + 'bg', x1: 0, y1: 0, x2: 0, y2: 100, gradientUnits: 'userSpaceOnUse' }, defs);
    el('stop', { offset: 0, 'stop-color': '#0B3A86' }, gb); el('stop', { offset: 1, 'stop-color': '#05173A' }, gb);
    var gm = el('radialGradient', { id: uid + 'mn', cx: '45%', cy: '40%', r: '60%' }, defs);
    el('stop', { offset: 0, 'stop-color': '#F4FBFF' }, gm); el('stop', { offset: .8, 'stop-color': '#BFE6FF' }, gm); el('stop', { offset: 1, 'stop-color': '#8FD0FF' }, gm);
    var gh = el('radialGradient', { id: uid + 'ha', cx: '50%', cy: '50%', r: '50%' }, defs);
    el('stop', { offset: .6, 'stop-color': '#6FC3FF', 'stop-opacity': .35 }, gh); el('stop', { offset: 1, 'stop-color': '#6FC3FF', 'stop-opacity': 0 }, gh);
    var cp = el('clipPath', { id: uid + 'cl' }, defs);
    r.clip = el('circle', { cx: 50, cy: 48, r: 32 }, cp);
    var cw = el('clipPath', { id: uid + 'cw' }, defs);        // forme de l'eau (pour les rides)
    el('path', { d: WATER_D }, cw);
    r.uid = uid; r.defs = defs;

    r.word = el('text', { x: MX, y: MY + MR * 1.6 + 25, 'text-anchor': 'middle', fill: '#FFFFFF', 'font-size': 34, 'font-weight': 800, 'font-family': 'ui-rounded, \"SF Pro Rounded\", \"Nunito\", system-ui, sans-serif' }, parent);
    r.word.textContent = 'FishMe';
    r.root = el('g', { transform: BASE }, parent);
    r.halo = el('circle', { cx: 50, cy: 48, r: 46, fill: 'url(#' + uid + 'ha)' }, r.root);
    r.halo2 = el('circle', { cx: 50, cy: 48, r: 46, fill: 'url(#' + uid + 'ha)', opacity: 0 }, r.root);
    r.clipG = el('g', { 'clip-path': 'url(#' + uid + 'cl)' }, r.root);
    r.moon = el('circle', { cx: 50, cy: 48, r: 32, fill: 'url(#' + uid + 'mn)' }, r.clipG);
    r.glow = el('circle', { cx: 50, cy: 48, r: 32, fill: '#F4FBFF', opacity: 0 }, r.clipG);
    r.waterG = el('g', null, r.clipG);
    r.water = el('path', { d: WATER_D, fill: '#04122B' }, r.waterG);
    r.ripIn = el('g', { 'clip-path': 'url(#' + uid + 'cw)' }, r.clipG);   // rides sur l'eau du logo
    var ca = el('clipPath', { id: uid + 'ca' }, defs);     // tout ce qui est au-dessus de l'eau
    el('path', { d: 'M-200,74 C-100,74 -50,74 0,74 C20,70 34,72 50,76 C66,72 80,70 100,74 L300,74 L300,-300 L-200,-300 Z' }, ca);
    r.topIn = el('g', null, r.clipG);
    r.fishC = el('g', { 'clip-path': 'url(#' + uid + 'ca)' }, r.root);
    r.fishO = el('g', null, r.fishC);
    var ft = el('g', { transform: FISH_T, fill: '#04122B' }, r.fishO);
    r.fish = el('path', { d: ASSETS.poissonPath }, ft);
    r.eye = el('circle', { cx: 74, cy: 45, r: 3.6, fill: '#BFE6FF' }, ft);
    r.dropsG = el('g', { fill: '#04122B' }, r.clipG);
    r.dropsDef = [[20.5, 69, 1.7], [16.5, 65, 1.2], [36, 68.5, 1.2]];
    r.drops = r.dropsDef.map(function (d) { return el('circle', { cx: d[0], cy: d[1], r: d[2] }, r.dropsG); });
    r.top = el('g', null, r.root);   // éclaboussures, par-dessus (hors du disque aussi)
    return r;
  }
  function setFish(r, dx, dy, th) {
    r.fishO.setAttribute('transform', 'translate(' + f(dx) + ' ' + f(dy) + ') rotate(' + f(th + 28) + ' 50 46)');
  }

  /* ---------- l'écran de l'app (la teinte pâle avec une rivière) ---------- */
  function appLayer(parent, uid, withBg) {
    var a = {};
    a.g = el('g', null, parent);
    a.bg = el('rect', { x: -10, y: -10, width: W + 20, height: H + 20, fill: TINT, opacity: withBg === false ? 0 : 1 }, a.g);
    a.feat = el('g', null, a.g);
    var f1 = a.feat;
    // parcs et plan d'eau
    el('rect', { x: 238, y: 70, width: 190, height: 150, rx: 30, fill: '#E7EFF8' }, f1);
    el('rect', { x: -40, y: 560, width: 150, height: 130, rx: 30, fill: '#E7EFF8' }, f1);
    el('rect', { x: 250, y: 330, width: 170, height: 90, rx: 24, fill: '#E7EFF8' }, f1);
    el('path', { d: 'M236,770 C226,742 262,712 312,722 C366,732 404,764 392,812 C380,860 300,870 258,838 C242,826 240,798 236,770Z', fill: '#C7DFF3', stroke: '#9CC7EA', 'stroke-width': 1.5 }, f1);
    // routes
    var roads = ['M-10,330 L400,262', 'M232,-10 C250,200 292,520 262,860', 'M-10,640 C120,610 200,640 400,560', 'M60,-10 C90,120 40,200 70,300'];
    roads.forEach(function (d) {
      el('path', { d: d, fill: 'none', stroke: '#DCE3EB', 'stroke-width': 9, 'stroke-linecap': 'round' }, f1);
      el('path', { d: d, fill: 'none', stroke: '#FFFFFF', 'stroke-width': 6, 'stroke-linecap': 'round' }, f1);
    });
    // la rivière : une seule ligne
    var rd = 'M-20,150 C80,190 150,170 172,250 C194,330 92,382 112,470 C132,560 262,556 290,650 C310,716 382,742 420,760';
    el('path', { d: rd, fill: 'none', stroke: '#9CC7EA', 'stroke-width': 13, 'stroke-linecap': 'round' }, f1);
    a.river = el('path', { d: rd, fill: 'none', stroke: '#C7DFF3', 'stroke-width': 8, 'stroke-linecap': 'round', pathLength: 100, 'stroke-dasharray': 100, 'stroke-dashoffset': 100 }, f1);
    a.river0 = a.river.previousSibling;
    a.river0.setAttribute('pathLength', 100); a.river0.setAttribute('stroke-dasharray', 100);
    // deux stations
    a.pins = el('g', null, f1);
    [[160, 232], [200, 524]].forEach(function (p) {
      el('circle', { cx: p[0], cy: p[1], r: 9, fill: '#FFFFFF' }, a.pins);
      el('circle', { cx: p[0], cy: p[1], r: 5.5, fill: '#0D4A85' }, a.pins);
    });
    a.setRiver = function (p) {
      var o = f(100 * (1 - p));
      a.river.setAttribute('stroke-dashoffset', o);
      a.river0.setAttribute('stroke-dashoffset', o);
      a.pins.setAttribute('opacity', f(seg(p, .55, 1)));
    };
    a.setRiver(0);
    return a;
  }

  /* ---------- le moteur commun : boucle, visibilité, relance ---------- */
  var CYCLE = 6.0;
  function mount(el0, ctx, def) {
    var uid = 'fmL' + (++uidN) + '-';
    var red = !!(ctx && ctx.reduit);
    var svg = el('svg', { viewBox: '0 0 ' + W + ' ' + H, preserveAspectRatio: 'xMidYMid slice', 'class': 'fmL-svg' }, el0);
    el('rect', { x: -20, y: -20, width: W + 40, height: H + 40, fill: NAVY }, svg);
    var scene = red ? buildReduit(svg, uid) : def.build(svg, uid);
    var last = red ? .9 : def.fin, beat = red ? .3 : def.beat;
    var raf = 0, t0 = null, visible = true, tPause = 0, fired = false, fadeIn = false, dead = false, io = null;

    function opacityAt(t) {
      if (red) return 1;
      var o = 1;
      if (fadeIn) o = Math.min(o, clamp(t / .25));
      if (t > CYCLE - .3) o = Math.min(o, clamp((CYCLE - t) / .3));
      return o;
    }
    function frame(now) {
      raf = 0; if (dead || !visible) return;
      if (t0 == null) t0 = now;
      var t = (now - t0) / 1000;
      if (!red && t >= CYCLE) { t0 = now; t = 0; fired = false; fadeIn = true; }
      if (!fired && t >= beat) { fired = true; try { ctx && ctx.son && ctx.son('lancement'); } catch (e) {} }
      if (t <= last + .05 || t < .3) scene.render(Math.min(t, last));
      var o = opacityAt(t);
      svg.style.opacity = o < 1 ? f(o) : '';
      if (red && t > last + .3) return;       // réduit : tout est fini, on s'arrête
      raf = requestAnimationFrame(frame);
    }
    function go() { if (!raf && !dead && visible) raf = requestAnimationFrame(frame); }
    function rejouer() { t0 = null; fired = false; fadeIn = false; svg.style.opacity = ''; scene.render(0); if (raf) { cancelAnimationFrame(raf); raf = 0; } go(); }
    scene.render(0);
    if (typeof IntersectionObserver !== 'undefined') {
      io = new IntersectionObserver(function (es) {
        var v = es[es.length - 1].isIntersecting;
        if (v === visible) return;
        visible = v;
        if (!v) { tPause = performance.now(); if (raf) { cancelAnimationFrame(raf); raf = 0; } }
        else { if (t0 != null) t0 += performance.now() - tPause; go(); }
      });
      io.observe(el0);
    }
    go();
    return {
      rejouer: rejouer,
      arreter: function () { dead = true; if (raf) cancelAnimationFrame(raf); raf = 0; if (io) io.disconnect(); if (svg.parentNode) svg.parentNode.removeChild(svg); },
      seek: function (t) { dead = true; if (raf) cancelAnimationFrame(raf); raf = 0; svg.style.opacity = ''; scene.render(t); }
    };
  }

  /* ---------- Réduire les animations : fondu de 300 ms du logo vers la teinte de l'app ---------- */
  function buildReduit(svg, uid) {
    var L = logo(svg, uid);
    var app = appLayer(svg, uid, true);
    app.setRiver(1);
    return { render: function (t) { app.g.setAttribute('opacity', f(eStd(seg(t, .5, .8)))); } };
  }

  /* =====================================================================
     A — Le bond
     ===================================================================== */
  function buildA(svg, uid) {
    var L = logo(svg, uid), root = L.root;
    var app = appLayer(svg, uid, true);
    var lgr = el('radialGradient', { id: uid + 'lg', cx: '50%', cy: '45%', r: '60%' }, L.defs);
    el('stop', { offset: 0, 'stop-color': '#F4FBFF' }, lgr); el('stop', { offset: .7, 'stop-color': '#EEF5FB' }, lgr); el('stop', { offset: 1, 'stop-color': TINT }, lgr);
    var light = el('circle', { cx: MX, cy: MY, r: MR, fill: 'url(#' + uid + 'lg)', opacity: 0 }, svg);
    svg.appendChild(app.g);
    var splashG = el('g', null, L.top);
    var ripples = [0, 1, 2].map(function () { return el('ellipse', { fill: 'none', stroke: '#9CC7EA' }, L.ripIn); });
    var sdrops = [0, 1, 2].map(function (i) {
      return el('ellipse', { fill: '#04122B', stroke: '#8FD0FF', 'stroke-width': .3 }, splashG);
    });

    // trajectoire du poisson : montée freinée, puis chute accélérée (parabole)
    function fishAt(t) {
      var q1 = seg(t, .08, .34), q2 = seg(t, .34, .9);
      var dy = q2 > 0 ? -23 + 80 * q2 * q2 : -23 * bez(.3, .5, .6, 1)(q1);
      var dx = -4 * eStd(seg(t, .08, .8));
      var th = t < .34 ? -28 - 12 * eOut(seg(t, .08, .34)) : -40 + 112 * eIO(seg(t, .34, .8));
      return { dx: dx, dy: dy, th: th };
    }
    function nose(s) {
      var a = s.th * Math.PI / 180;
      return [50 + s.dx + 27.36 * Math.cos(a), 46 + s.dy + 27.36 * Math.sin(a)];
    }
    var tE = .6, xE = 78, yE = 73;
    for (var tt = .4; tt < .9; tt += .002) {
      var s = fishAt(tt), n = nose(s);
      if (n[1] >= staticY(n[0]) + .5) { tE = tt; xE = n[0]; yE = staticY(n[0]); break; }
    }
    var G = 330, SV = [[-15, -54, 1.2], [4, -72, 1.4], [17, -46, .95]];
    var RD = [0, .09, .19];
    // gouttes qui se détachent de la queue : elles retombent dans l'eau
    var DROP = [[-7, -22], [-9, -30], [3, -13]];
    var ease = bez(.55, 0, .2, 1);

    function render(t) {
      // la lune s'éclaire un peu
      var b = eStd(seg(t, 0, .24));
      L.word.setAttribute('opacity', f(1 - eStd(seg(t, .12, .42))));
      L.glow.setAttribute('opacity', f(b * .34 + eIn(seg(t, 1.0, 1.3)) * .66));
      L.halo2.setAttribute('opacity', f(b * .75));
      L.halo.setAttribute('transform', 'translate(50 48) scale(' + f(1 + b * .07) + ') translate(-50 -48)');
      L.halo2.setAttribute('transform', 'translate(50 48) scale(' + f(1 + b * .07) + ') translate(-50 -48)');
      // le bond
      var s = fishAt(t);
      setFish(L, s.dx, s.dy, s.th);
      // gouttes de la queue
      var td = Math.max(0, t - .08);
      L.drops.forEach(function (c, i) {
        var d = L.dropsDef[i];
        c.setAttribute('cx', f(d[0] + DROP[i][0] * td * .5));
        c.setAttribute('cy', f(d[1] + DROP[i][1] * td + .5 * 300 * td * td));
        c.setAttribute('r', d[2] * (td > 0 ? 1 - .25 * seg(td, 0, .3) : 1));
      });
      // éclaboussure : 3 gouttes en parabole
      SV.forEach(function (v, i) {
        var tau = t - tE, c = sdrops[i], life = 2 * -v[1] / G;
        if (tau < 0 || tau > life) { c.setAttribute('opacity', 0); return; }
        var x = xE + v[0] * tau, y = yE + v[1] * tau + .5 * G * tau * tau;
        var vx = v[0], vy = v[1] + G * tau, ang = Math.atan2(vy, vx) * 180 / Math.PI;
        var sp = Math.min(1.7, 1 + Math.abs(vy) / 90), rr = v[2];
        c.setAttribute('cx', f(x)); c.setAttribute('cy', f(y));
        c.setAttribute('rx', f(rr * sp)); c.setAttribute('ry', f(rr / Math.sqrt(sp)));
        c.setAttribute('transform', 'rotate(' + f(ang) + ' ' + f(x) + ' ' + f(y) + ')');
        c.setAttribute('opacity', 1);
      });
      // rides concentriques sur la ligne d'eau (elles s'élargissent et s'atténuent)
      ripples.forEach(function (e, i) {
        var p = seg(t, tE + RD[i], tE + RD[i] + .6);
        if (p <= 0 || p >= 1) { e.setAttribute('opacity', 0); return; }
        var rx = 2 + 17 * eOut(p);
        e.setAttribute('cx', f(xE)); e.setAttribute('cy', f(yE + 6));
        e.setAttribute('rx', f(rx)); e.setAttribute('ry', f(rx * .2));
        e.setAttribute('stroke-width', f(.9 * (1 - p) + .25));
        e.setAttribute('opacity', f(.85 * Math.pow(1 - p, 1.35) * clamp(p / .08)));
      });
      // la lune s'agrandit jusqu'à remplir l'écran
      var x = ease(seg(t, .84, 1.28)), sc = 1 + 9.2 * x;
      root.setAttribute('transform', 'translate(' + MX + ' ' + MY + ') scale(' + f(sc) + ') translate(' + (-MX) + ' ' + (-MY) + ') ' + BASE);
      // la lumière devient l'écran de l'app
      var wf = f(1 - eStd(seg(t, .88, 1.05)));
      L.waterG.setAttribute('opacity', wf); L.ripIn.setAttribute('opacity', wf); L.top.setAttribute('opacity', wf); L.dropsG.setAttribute('opacity', wf);
      var lg = bez(.3, 0, .25, 1)(seg(t, 1.0, 1.4));
      light.setAttribute('r', f(MR * sc + 160 * lg));
      light.setAttribute('opacity', f(clamp(seg(t, 1.0, 1.1))));
      app.bg.setAttribute('opacity', t > 1.38 ? 1 : 0);
      app.feat.setAttribute('opacity', f(seg(t, 1.22, 1.42)));
      app.setRiver(eStd(seg(t, 1.16, 1.45)));
    }
    return { render: render };
  }

  /* =====================================================================
     B — Ronds dans l'eau
     ===================================================================== */
  function buildB(svg, uid) {
    var L = logo(svg, uid);
    var CX = IX + 50 * K, CY = IY + 79 * K;        // là où la queue touche l'eau (écran)
    // rides hors de l'icône (zone extérieure) : clip « evenodd »
    var iconPath = (function () {
      return 'M' + (MX - MR) + ',' + MY + ' A' + MR + ',' + MR + ' 0 1 0 ' + (MX + MR) + ',' + MY + ' A' + MR + ',' + MR + ' 0 1 0 ' + (MX - MR) + ',' + MY + ' Z';
    })();
    var co = el('clipPath', { id: uid + 'co' }, L.defs);
    el('path', { d: 'M-2000,-2000 H3000 V3000 H-2000 Z ' + iconPath, 'clip-rule': 'evenodd' }, co);
    var outG = el('g', { 'clip-path': 'url(#' + uid + 'co)' }, svg);
    var DEL = [.1, .3, .52], LIFE = [1.0, .95, .9];
    var outR = [], inR = [];
    DEL.forEach(function () {
      outR.push([el('ellipse', { fill: 'none', stroke: '#C7DFF3' }, outG), el('ellipse', { fill: 'none', stroke: '#9CC7EA' }, outG)]);
      inR.push([el('ellipse', { fill: 'none', stroke: '#C7DFF3' }, L.ripIn), el('ellipse', { fill: 'none', stroke: '#9CC7EA' }, L.ripIn)]);
    });
    // petites rides des gouttes qui retombent, dans le logo
    var mini = [[36, 75.5, .16], [20, 74.6, .21]].map(function (m) { return { d: m, e: el('ellipse', { fill: 'none', stroke: '#9CC7EA' }, L.ripIn) }; });

    var app = appLayer(svg, uid, true);
    var mk = el('mask', { id: uid + 'mk', maskUnits: 'userSpaceOnUse', x: -50, y: -50, width: W + 100, height: H + 100 }, L.defs);
    var mp = el('path', { fill: '#fff' }, mk);
    app.g.setAttribute('mask', 'url(#' + uid + 'mk)');
    var edge = el('path', { fill: 'none', stroke: '#C7DFF3', 'stroke-linejoin': 'round' }, svg);
    var edge2 = el('path', { fill: 'none', stroke: '#9CC7EA', 'stroke-linejoin': 'round' }, svg);
    var open = bez(.5, 0, .15, 1);

    function ringPath(R, t) {
      var n = 96, d = '';
      for (var i = 0; i < n; i++) {
        var a = i / n * Math.PI * 2;
        var k = 1 + (.010 * Math.sin(5 * a + 7 * t) + .007 * Math.sin(9 * a - 9 * t) + .004 * Math.sin(14 * a + 5 * t)) * clamp(R / 80);
        d += (i ? 'L' : 'M') + f(CX + Math.cos(a) * R * k) + ',' + f(CY + Math.sin(a) * R * k);
      }
      return d + 'Z';
    }
    function render(t) {
      // le poisson s'enfonce un peu : la queue touche l'eau, ressort amorti
      var sp = spring(t - .06, 15, .5);
      setFish(L, 0.4 * sp, 4.6 * sp, -28 - 4 * sp);
      L.drops.forEach(function (c, i) {
        var d = L.dropsDef[i], td = Math.max(0, t - .06), y = d[1] + .5 * 260 * td * td - (i === 1 ? 6 : 3) * td;
        c.setAttribute('cy', f(y));
      });
      // les grandes rides (écran) : 3 ellipses, chacune avec un reflet derrière
      DEL.forEach(function (d, i) {
        var p = seg(t, d, d + LIFE[i]);
        var live = p > 0 && p < 1;
        var rx = 640 * (1 - Math.pow(1 - p, 1.7)) + 3;
        var a = live ? .78 * Math.pow(1 - p, 1.2) * clamp(p / .06) * (i === 2 ? .8 : 1) : 0;
        var w = .8 + 2.6 * Math.pow(1 - p, .8);
        [0, 1].forEach(function (j) {
          var rr = rx * (j ? .88 : 1), ww = j ? w * .55 : w, aa = j ? a * .42 : a;
          var o = outR[i][j], n = inR[i][j];
          o.setAttribute('cx', f(CX)); o.setAttribute('cy', f(CY)); o.setAttribute('rx', f(rr)); o.setAttribute('ry', f(rr * .3));
          o.setAttribute('stroke-width', f(ww)); o.setAttribute('opacity', f(aa));
          n.setAttribute('cx', f((CX - IX) / K)); n.setAttribute('cy', f((CY - IY) / K)); n.setAttribute('rx', f(rr / K)); n.setAttribute('ry', f(rr * .3 / K));
          n.setAttribute('stroke-width', f(ww / K)); n.setAttribute('opacity', f(aa));
        });
      });
      mini.forEach(function (m) {
        var p = seg(t, m.d[2], m.d[2] + .5), e = m.e;
        if (p <= 0 || p >= 1) { e.setAttribute('opacity', 0); return; }
        var rx = 1.5 + 8 * eOut(p);
        e.setAttribute('cx', m.d[0]); e.setAttribute('cy', m.d[1]); e.setAttribute('rx', f(rx)); e.setAttribute('ry', f(rx * .26));
        e.setAttribute('stroke-width', f(.5 * (1 - p) + .15)); e.setAttribute('opacity', f(.7 * (1 - p) * clamp(p / .1)));
      });
      // l'écran s'ouvre depuis le centre des rides, comme l'eau qui s'écarte
      var q = open(seg(t, .6, 1.4)), R = q * 620;
      if (R < .5) { app.g.setAttribute('opacity', 0); edge.setAttribute('opacity', 0); edge2.setAttribute('opacity', 0); }
      else {
        app.g.setAttribute('opacity', f(clamp(R / 36)));
        var d = ringPath(R, t);
        mp.setAttribute('d', d);
        var o = clamp(R / 20) * (1 - seg(q, .78, 1));
        edge.setAttribute('d', d); edge.setAttribute('stroke-width', f(3 + 5 * (1 - q))); edge.setAttribute('opacity', f(.65 * o));
        edge2.setAttribute('d', ringPath(R * .965, t + .4)); edge2.setAttribute('stroke-width', 1.4); edge2.setAttribute('opacity', f(.5 * o));
      }
      app.setRiver(eStd(seg(t, .9, 1.45)));
      app.feat.setAttribute('opacity', 1);
    }
    return { render: render };
  }

  /* =====================================================================
     C — Marée
     ===================================================================== */
  function buildC(svg, uid) {
    var L = logo(svg, uid), clip = L.clip;
    L.water.setAttribute('opacity', 0); L.fishC.removeAttribute('clip-path'); L.clipG.insertBefore(L.fishC, L.topIn);
    var wG = L.waterG;
    var back = el('path', { fill: '#04122B' }, wG), front = el('path', { fill: '#04122B' }, wG);
    var crestB = el('path', { fill: 'none', stroke: '#6FC3FF', 'stroke-width': .5, 'stroke-linejoin': 'round' }, wG);
    var crestF = el('path', { fill: 'none', stroke: '#9CC7EA', 'stroke-width': .4, 'stroke-linejoin': 'round' }, wG);
    // couches claires, par-dessus le poisson
    var eau = el('path', { fill: '#9CC7EA' }, L.topIn), tide = el('path', { fill: TINT }, L.topIn);
    var crestT = el('path', { fill: 'none', stroke: '#C7DFF3', 'stroke-width': 1.2, 'stroke-linejoin': 'round' }, L.topIn);
    var app = appLayer(svg, uid, false);
    var X0 = -135, X1 = 235, STEP = 3, YB = 420;

    function surf(x, t, level, A1, A2, l1, l2, w1, w2, ph, m) {
      var s = A1 * Math.sin(x / l1 * 6.2832 + w1 * t + ph) + A2 * Math.sin(x / l2 * 6.2832 - w2 * t + ph * 1.7 + 1.3);
      var y = level + s;
      return m < 1 ? lerp(staticY(x), y, m) : y;
    }
    function poly(fn) {
      var d = '', top = '', x;
      for (x = X0; x <= X1; x += STEP) { var y = fn(x); top += (x === X0 ? 'M' : 'L') + x + ',' + f(y); }
      return { top: top, fill: top + 'L' + X1 + ',' + YB + 'L' + X0 + ',' + YB + 'Z' };
    }
    function render(t) {
      var m = eStd(seg(t, .02, .16));
      var flood = seg(t, .55, 1.2);
      var amp = 1 + 1.6 * flood, lam = 1 + 2.4 * flood;
      var lvl = t < .6 ? lerp(73.4, 40, eIO(seg(t, .08, .6))) : lerp(40, -350, eIn(seg(t, .6, 1.24)));
      var bo = 4 * seg(t, .06, .4);
      var pb = poly(function (x) { return surf(x, t, lvl - bo, 1.5 * amp, .9 * amp, 54 * lam, 31 * lam, 5.3, 8.5, 2.1, m); });
      var pf = poly(function (x) { return surf(x, t, lvl, 1.2 * amp, .8 * amp, 46 * lam, 27 * lam, 4.6, 7.4, 0, m); });
      var cm = seg(t, .06, .4);
      back.setAttribute('d', pb.fill); back.setAttribute('fill', mix('#04122B', '#0B3D6B', cm));
      front.setAttribute('d', pf.fill); front.setAttribute('fill', mix('#04122B', '#082A4C', cm));
      crestB.setAttribute('d', pb.top); crestB.setAttribute('opacity', f(.5 * cm * (1 - flood)));
      crestF.setAttribute('d', pf.top); crestF.setAttribute('opacity', f(.3 * cm * (1 - flood)));
      // le poisson reste en ombre sous la surface
      var sh = eStd(seg(t, .12, .55));
      L.eye.setAttribute('opacity', f(1 - .85 * sh));
      var bob = Math.sin(t * 5.3) * sh * (1 - flood);
      setFish(L, 0, bob * .9, -28 + bob * 1.6);
      L.dropsG.setAttribute('opacity', f(1 - seg(t, .1, .3)));
      // l'icône s'ouvre sur tout l'écran
      var e = bez(.3, 0, .1, 1)(seg(t, .62, 1.02));
      clip.setAttribute('r', f(32 + 560 * e * e));
      L.word.setAttribute('opacity', f(1 - eStd(seg(t, .3, .6))));
      L.halo.setAttribute('opacity', f(1 - seg(t, .5, .85)));
      // l'eau claire qui chasse l'eau sombre
      var tl = lerp(385, -345, eIO(seg(t, .76, 1.38)));
      var pe = poly(function (x) { return surf(x, t, tl - 17, 2.8, 1.2, 150, 85, 2.6, 4.2, .8, 1); });
      var pt = poly(function (x) { return surf(x, t, tl, 2.4, 1.0, 170, 95, 2.2, 3.6, 3.3, 1); });
      eau.setAttribute('d', pe.fill); tide.setAttribute('d', pt.fill);
      crestT.setAttribute('d', pt.top); crestT.setAttribute('opacity', f(.9 * (1 - seg(t, 1.25, 1.4))));
      // un indice de l'app : la rivière apparaît
      app.feat.setAttribute('opacity', f(seg(t, 1.1, 1.38)));
      app.setRiver(eStd(seg(t, 1.12, 1.45)));
    }
    // l'écran de l'app se dessine par-dessus, mais seulement quand l'eau claire a tout couvert
    svg.appendChild(app.g);
    return { render: render };
  }

  /* ---------- le catalogue ---------- */
  FM.anims.push({
    id: 'lancement-bond', groupe: 'lancement', lettre: 'A', nom: 'Le bond',
    resume: 'FishMe s’efface, le poisson bondit hors de la lune, replonge avec une éclaboussure et des ondes, puis la lune grandit et devient l’écran de la carte.',
    ou: 'Premier lancement et chaque ouverture : juste après l’écran fixe de démarrage, avant la carte.',
    duree: '1,4 s puis la carte',
    swiftui: 'L’écran fixe (UILaunchScreen dans Info.plist, même bleu #0D4A85 et même image : la lune et le mot FishMe) laisse la place à une vue SwiftUI qui pose le logo exactement au même endroit et à la même taille : aucun saut. Le poisson suit un KeyframeAnimator à trois pistes (montée freinée, chute accélérée, rotation) ; les gouttes et les ondes se dessinent dans un TimelineView + Canvas, des ellipses qui grossissent en s’effaçant. À la fin, l’icône grandit avec un scaleEffect en ressort jusqu’à remplir l’écran, puis un fondu vers la carte. Avec Réduire les animations : fondu de 0,3 s du logo vers la carte, rien d’autre.',
    format: 'telephone', fond: 'nuit',
    monter: function (el0, ctx) { return mount(el0, ctx, { build: buildA, fin: 1.46, beat: 0 }, 'A'); }
  });
  FM.anims.push({
    id: 'lancement-ronds', groupe: 'lancement', lettre: 'B', nom: 'Ronds dans l’eau',
    resume: 'Le logo ne bouge presque pas : la queue touche l’eau et trois ronds s’élargissent, sortent de la lune et traversent tout l’écran bleu, puis l’écran s’ouvre comme l’eau qui s’écarte sur la carte.',
    ou: 'Premier lancement et chaque ouverture : entre l’écran fixe de démarrage et la carte.',
    duree: '1,4 s puis la carte',
    swiftui: 'Même point de départ que l’écran fixe (UILaunchScreen, même couleur, même image). Les ondes sont un TimelineView + Canvas : trois ellipses aplaties, chacune avec son retard, dont le rayon grandit par une courbe qui ralentit et dont le trait s’affine et s’efface. Le poisson s’enfonce d’un cran avec .spring(duration: 0.5, bounce: 0.4). L’ouverture est la carte en dessous avec un .mask { Circle() } qui grandit depuis le centre des ondes (scaleEffect animé), le bord légèrement ondulé par un Shape animatable. Avec Réduire les animations : simple fondu de 0,3 s vers la carte.',
    format: 'telephone', fond: 'nuit',
    monter: function (el0, ctx) { return mount(el0, ctx, { build: buildB, fin: 1.46, beat: .1 }); }
  });
  FM.anims.push({
    id: 'lancement-maree', groupe: 'lancement', lettre: 'C', nom: 'Marée',
    resume: 'L’eau sombre monte dans la lune avec deux vagues vivantes, couvre à moitié la lune (le poisson reste une ombre), puis inonde l’écran et se change en fond clair de l’app.',
    ou: 'Premier lancement et chaque ouverture : entre l’écran fixe de démarrage et la carte.',
    duree: '1,4 s puis la carte',
    swiftui: 'Départ identique à l’écran fixe (UILaunchScreen, même couleur et même image). Les vagues sont un TimelineView(.animation) + Canvas qui trace deux courbes sinus de vitesses et de tailles différentes (Path), dont le niveau monte par une valeur animée en ressort. Le disque s’ouvre sur tout l’écran avec un clipShape(Circle) dont le rayon grandit, puis une troisième vague claire (couleur de fond de l’app) monte et prend la place. Léger retour haptique avec .sensoryFeedback(.impact(weight: .light)). Avec Réduire les animations : fondu de 0,3 s vers la carte, pas de vagues.',
    format: 'telephone', fond: 'nuit',
    monter: function (el0, ctx) { return mount(el0, ctx, { build: buildC, fin: 1.46, beat: .1 }); }
  });
})();
