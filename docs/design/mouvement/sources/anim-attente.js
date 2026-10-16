/* FishMe en mouvement — attentes (préfixe fmA-) : groupes attente, carte, reconnaissance */
(function () {
  'use strict';
  var FM = window.FM, A = window.FMAssets;
  if (!FM || !A) return;

  var PI = Math.PI, TAU = PI * 2;
  var FONT = 'ui-rounded, "SF Pro Rounded", "Nunito", system-ui, sans-serif';
  var C = {
    marine: '#0D4A85', marineF: '#0B3D6B', nuit: '#082A4C', ombre: '#04122B', encre: '#0E1A26',
    douce: '#566576', page: '#F2F5F9', surface: '#FFFFFF', tuile: '#E7EFF8', filet: '#DCE3EB',
    sil: '#B9C8D8', eau: '#9CC7EA', eauC: '#C7DFF3', lune: '#BFE6FF', halo: '#6FC3FF',
    bouchon: '#E8571C', rare: '#5B4FD0'
  };

  /* ---------- CSS ---------- */
  var st = document.createElement('style');
  st.textContent =
    '.fmA-cv{position:absolute;left:0;top:0;width:100%;height:100%;display:block}' +
    '.fmA-pulse{animation:fmA-pulse 2.8s ease-in-out infinite}' +
    '@keyframes fmA-pulse{0%,100%{opacity:.72}50%{opacity:1}}' +
    '.fmA-cap{position:absolute;left:0;right:0;text-align:center;font:700 12.5px/1.25 ' + FONT + ';color:' + C.douce + ';letter-spacing:.1px;pointer-events:none;white-space:nowrap}';
  document.head.appendChild(st);

  /* ---------- outils ---------- */
  function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }
  function lerp(a, b, k) { return a + (b - a) * k; }
  function sstep(a, b, v) { var k = clamp((v - a) / (b - a), 0, 1); return k * k * (3 - 2 * k); }
  function eio(k) { k = clamp(k, 0, 1); return k < .5 ? 4 * k * k * k : 1 - Math.pow(-2 * k + 2, 3) / 2; }
  function eout(k) { k = clamp(k, 0, 1); return 1 - Math.pow(1 - k, 3); }
  function spring(t, z, w) {
    if (t <= 0) return 0;
    var wd = w * Math.sqrt(1 - z * z);
    return 1 - Math.exp(-z * w * t) * (Math.cos(wd * t) + (z * w / wd) * Math.sin(wd * t));
  }
  function rnd(n) { var x = Math.sin(n * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); }
  function rgba(hex, a) {
    var n = parseInt(hex.slice(1), 16);
    return 'rgba(' + (n >> 16) + ',' + ((n >> 8) & 255) + ',' + (n & 255) + ',' + a + ')';
  }
  function rr(g, x, y, w, h, r) {
    r = Math.min(r, w / 2, h / 2);
    g.beginPath(); g.moveTo(x + r, y); g.arcTo(x + w, y, x + w, y + h, r); g.arcTo(x + w, y + h, x, y + h, r);
    g.arcTo(x, y + h, x, y, r); g.arcTo(x, y, x + w, y, r); g.closePath();
  }
  function txt(g, s, x, y, size, color, align, weight) {
    g.font = (weight || 800) + ' ' + size + 'px ' + FONT;
    g.fillStyle = color; g.textAlign = align || 'left'; g.textBaseline = 'alphabetic';
    g.fillText(s, x, y);
  }
  var IMGS = {};
  function img(k) {
    if (!IMGS[k]) { var i = new Image(); i.src = A.poissons[k]; IMGS[k] = i; }
    return IMGS[k];
  }
  ['brochet', 'perche', 'sandre', 'black-bass'].forEach(img);
  var FISH = new Path2D(A.poissonPath);

  /* poisson vectoriel qui s'ondule : 3 segments articulés (tête fixe, milieu, queue) */
  function fish(g, x, y, len, ang, bend, fill, eye) {
    var k = len / 74, a1 = bend * .5, a2 = bend * .95;
    g.save(); g.translate(x, y); g.rotate(ang); g.scale(k, k); g.translate(-49, -46);
    g.fillStyle = fill;
    var seg = [[0, 35.5, 0], [30, 51.5, 1], [46, 100, 2]]; // queue, milieu, tête
    seg.forEach(function (s) {
      g.save();
      if (s[2] <= 1) { g.translate(46, 50); g.rotate(a1); g.translate(-46, -50); }
      if (s[2] === 0) { g.translate(30, 50); g.rotate(a2); g.translate(-30, -50); }
      g.beginPath(); g.rect(s[0] - (s[2] === 0 ? 4 : 0), -10, s[1] - s[0] + (s[2] === 0 ? 4 : 0), 130); g.clip();
      g.fill(FISH); g.restore();
    });
    if (eye) { g.fillStyle = eye; g.beginPath(); g.arc(74, 45, 3.6, 0, TAU); g.fill(); }
    g.restore();
  }

  /* scène canvas : DPR, ResizeObserver, IntersectionObserver, pause hors écran */
  function stage(el, ctx, o) {
    var cv = document.createElement('canvas');
    cv.className = 'fmA-cv' + (ctx.reduit ? ' fmA-pulse' : '');
    el.appendChild(cv);
    var g = cv.getContext('2d');
    var W = 0, H = 0, dpr = 1, t = 0, last = 0, raf = 0, vis = true, dead = false, noSound = false;
    var api = { sound: function (m) { if (!noSound && !ctx.reduit) ctx.son(m); } };
    function paint() {
      if (!W) return;
      g.setTransform(dpr, 0, 0, dpr, 0, 0); g.clearRect(0, 0, W, H);
      o.draw(g, ctx.reduit ? o.staticT : t, W, H, api);
    }
    function size() {
      var w = el.clientWidth, h = el.clientHeight;
      if (!w || !h) return;
      dpr = Math.min(window.devicePixelRatio || 1, 2); W = w; H = h;
      cv.width = Math.round(w * dpr); cv.height = Math.round(h * dpr);
      if (o.resize) o.resize(W, H, dpr);
      paint();
    }
    function tick(ts) {
      raf = 0; if (dead || !vis) return;
      var dt = last ? Math.min((ts - last) / 1000, .05) : 0; last = ts; t += dt;
      paint(); raf = requestAnimationFrame(tick);
    }
    function start() { if (!raf && !ctx.reduit && vis && !dead) { last = 0; raf = requestAnimationFrame(tick); } }
    var ro = new ResizeObserver(size); ro.observe(el);
    var io = null;
    if (window.IntersectionObserver) {
      io = new IntersectionObserver(function (es) {
        vis = es[es.length - 1].isIntersecting;
        if (vis) start(); else if (raf) { cancelAnimationFrame(raf); raf = 0; }
      });
      io.observe(el);
    }
    size(); start();
    return {
      rejouer: function () { t = 0; noSound = false; if (o.reset) o.reset(); paint(); start(); },
      arreter: function () {
        dead = true; if (raf) cancelAnimationFrame(raf); ro.disconnect(); if (io) io.disconnect();
        if (cv.parentNode) cv.parentNode.removeChild(cv);
        if (el._fmACap && el._fmACap.parentNode) el._fmACap.parentNode.removeChild(el._fmACap);
      },
      __seek: function (tt) { if (raf) { cancelAnimationFrame(raf); raf = 0; } vis = false; noSound = true; t = tt; paint(); }
    };
  }

  /* légende DOM sous le loader (tuiles) */
  function legende(el, texte) {
    var d = document.createElement('div'); d.className = 'fmA-cap'; d.textContent = texte;
    el.appendChild(d); el._fmACap = d; return d;
  }
  function tuileLayout(W, H) {
    var s = clamp(Math.min(W, H) / 250, .85, 1.35);
    return { s: s, cx: W / 2, cy: H * .43 };
  }
  function tuile(el, ctx, texte, draw, staticT, opts) {
    var cap = legende(el, texte), lay = null;
    var o = {
      staticT: staticT,
      resize: function (W, H) { lay = tuileLayout(W, H); cap.style.top = (lay.cy + (opts && opts.capDy || 50) * lay.s) + 'px'; cap.style.fontSize = (12 * clamp(lay.s, .95, 1.2)) + 'px'; },
      draw: function (g, t, W, H, api) { draw(g, t, lay || tuileLayout(W, H), api); }
    };
    if (opts) for (var k in opts) o[k] = opts[k];
    return stage(el, ctx, o);
  }

  /* ======================= ATTENTE A : Bouchon ======================= */
  var BODY = new Path2D('M0,-21 C9,-21 12.2,-8 11.6,0 C11,12 6,22 0,22 C-6,22 -11,12 -11.6,0 C-12.2,-8 -9,-21 0,-21 Z');
  function bouchon(g) {
    g.save(); g.clip(BODY);
    g.fillStyle = C.bouchon; g.fillRect(-14, -24, 28, 17.5);
    g.fillStyle = '#FFFFFF'; g.fillRect(-14, -6.5, 28, 11);
    g.fillStyle = C.marine; g.fillRect(-14, 4.5, 28, 20);
    var sh = g.createLinearGradient(-12, 0, 12, 0);
    sh.addColorStop(0, 'rgba(4,18,43,.2)'); sh.addColorStop(.32, 'rgba(255,255,255,0)');
    sh.addColorStop(.62, 'rgba(255,255,255,0)'); sh.addColorStop(1, 'rgba(4,18,43,.24)');
    g.fillStyle = sh; g.fillRect(-14, -24, 28, 48);
    g.fillStyle = 'rgba(255,255,255,.55)'; g.beginPath(); g.ellipse(-5.2, -13, 1.7, 5.2, -.12, 0, TAU); g.fill();
    g.fillStyle = 'rgba(255,255,255,.28)'; g.beginPath(); g.ellipse(-5, 11, 1.3, 4, .1, 0, TAU); g.fill();
    g.fillStyle = 'rgba(4,18,43,.13)'; g.fillRect(-14, -6.8, 28, .7); g.fillRect(-14, 4.2, 28, .7);
    g.restore();
    g.strokeStyle = 'rgba(11,61,107,.32)'; g.lineWidth = .8; g.stroke(BODY);
    g.strokeStyle = C.marineF; g.lineWidth = 1.7; g.lineCap = 'round';
    g.beginPath(); g.moveTo(0, -21); g.lineTo(0, -34); g.stroke();
    g.fillStyle = C.bouchon; g.beginPath(); g.arc(0, -34.2, 1.7, 0, TAU); g.fill();
  }
  function ellRipple(g, cx, cy, rx, ry, front, a, lw) {
    g.beginPath(); if (front) g.ellipse(cx, cy, rx, ry, 0, 0, PI); else g.ellipse(cx, cy, rx, ry, 0, PI, TAU);
    g.strokeStyle = rgba(C.marine, a); g.lineWidth = lw; g.stroke();
  }
  function drawBouchon(g, t, L) {
    var s = L.s, T = 1.4, p = (t / T) % 1;
    var dy = 3 * (1 - Math.cos(TAU * p)), tilt = .075 * Math.sin(TAU * p + .5);
    var cx = L.cx, wl = L.cy + 6 * s;
    // ondes : à chaque creux (p = .5), deux ellipses décalées
    var rip = [];
    var n0 = Math.floor((t - .7) / T);
    for (var n = n0 - 1; n <= n0 + 1; n++) {
      for (var i = 0; i < 2; i++) {
        var age = t - (n * T + .7 + i * .2);
        if (age >= 0 && age < 1.5) rip.push(age);
      }
    }
    function drawRip(front) {
      rip.forEach(function (age) {
        var k = age / 1.5, rx = (9 + 44 * (1 - Math.pow(1 - k, 2.2))) * s;
        ellRipple(g, cx, wl, rx, rx * .27, front, Math.pow(1 - k, 1.7) * .5, lerp(1.7, .5, k) * Math.max(.9, s * .9));
      });
    }
    function place() {
      g.translate(cx, wl - 5 * s + dy * s); g.rotate(tilt); g.scale(s, s);
    }
    var bowl = new Path2D();
    var bw = 56 * s; bowl.moveTo(cx - bw, wl); bowl.lineTo(cx + bw, wl); bowl.ellipse(cx, wl, bw, 24 * s, 0, 0, PI);
    drawRip(false);
    // au-dessus de l'eau
    g.save(); g.beginPath(); g.rect(0, 0, cx * 2, wl); g.clip(); g.save(); place(); bouchon(g); g.restore(); g.restore();
    // sous l'eau : décalé et adouci, vu à travers
    g.save(); g.clip(bowl); g.beginPath(); g.rect(0, wl, cx * 2, 100 * s); g.clip();
    g.save(); g.translate(Math.sin(t * 5.2) * .9 * s, 0); g.globalAlpha = .62; place(); bouchon(g); g.restore();
    var wg = g.createLinearGradient(0, wl, 0, wl + 24 * s);
    wg.addColorStop(0, rgba(C.eau, .62)); wg.addColorStop(.55, rgba(C.eauC, .55)); wg.addColorStop(1, rgba(C.eauC, 0));
    g.fillStyle = wg; g.fillRect(cx - bw, wl, bw * 2, 26 * s);
    g.restore();
    // surface
    g.save(); var sg = g.createLinearGradient(cx - bw, 0, cx + bw, 0);
    sg.addColorStop(0, rgba(C.marine, 0)); sg.addColorStop(.25, rgba(C.marine, .26)); sg.addColorStop(.75, rgba(C.marine, .26)); sg.addColorStop(1, rgba(C.marine, 0));
    g.strokeStyle = sg; g.lineWidth = 1.2; g.beginPath();
    for (var x = -bw; x <= bw; x += 3) {
      var y = wl + Math.sin(x * .09 - t * 3) * .5 * s + Math.sin(x * .21 + t * 2) * .3 * s;
      if (x === -bw) g.moveTo(cx + x, y); else g.lineTo(cx + x, y);
    }
    g.stroke(); g.restore();
    // ménisque autour du bouchon
    var im = 1 - Math.min(1, dy / 6) * .2;
    g.strokeStyle = 'rgba(255,255,255,.9)'; g.lineWidth = 1.1; g.beginPath(); g.ellipse(cx + 0, wl, 12.5 * s * im, 3 * s, 0, 0, PI); g.stroke();
    drawRip(true);
  }

  /* ======================= ATTENTE B : Poisson qui tourne ======================= */
  function drawPoissonTourne(g, t, L) {
    var s = L.s, cx = L.cx, cy = L.cy, R = 19 * s, len = 27 * s, P = 1.5;
    g.strokeStyle = rgba(C.marine, .09); g.lineWidth = 1.4 * s; g.setLineDash([2 * s, 4.2 * s]); g.lineCap = 'round';
    g.beginPath(); g.arc(cx, cy, R, 0, TAU); g.stroke(); g.setLineDash([]);
    function th(tt) { return -PI / 2 + TAU * tt / P; }
    // sillage en arc qui s'efface
    var th0 = th(t), N = 14;
    for (var i = 0; i < N; i++) {
      var a0 = th0 - .42 - i * .09, a1 = a0 - .1;
      g.strokeStyle = rgba(C.marine, .16 * Math.pow(1 - i / N, 1.6)); g.lineWidth = lerp(2.4, .6, i / N) * s; g.lineCap = 'round';
      g.beginPath(); g.arc(cx, cy, R, a1, a0); g.stroke();
    }
    // bulles du sillage
    var dtb = .13, k0 = Math.floor(t / dtb);
    for (var k = k0 - 5; k <= k0; k++) {
      var te = k * dtb, age = t - te; if (te < 0 || age < 0 || age > .52) continue;
      var u = age / .52, ae = th(te) - .5 * len / R * 1.05;
      var drift = (2.5 + 4 * u) * s, rr0 = R + drift * (rnd(k) > .5 ? 1 : -1) * .8;
      var bx = cx + rr0 * Math.cos(ae), by = cy + rr0 * Math.sin(ae), br = (1.1 + .9 * Math.sin(u * PI * .8) + rnd(k + 9) * .4) * s;
      g.fillStyle = 'rgba(255,255,255,' + (.75 * (1 - u)) + ')'; g.strokeStyle = rgba(C.marine, .5 * (1 - u)); g.lineWidth = .8 * s;
      g.beginPath(); g.arc(bx, by - u * 2 * s, br, 0, TAU); g.fill(); g.stroke();
    }
    var a = th(t);
    var bend = .26 * Math.sin(TAU * 2.5 * t) - .2;
    fish(g, cx + R * Math.cos(a), cy + R * Math.sin(a), len, a + PI / 2, bend, C.marine, '#FFFFFF');
  }

  /* ======================= ATTENTE C : Bulles ======================= */
  function drawBulles(g, t, L) {
    var s = L.s, cx = L.cx, surf = L.cy - 30 * s, base = L.cy + 28 * s, h = base - surf, P = 2.1;
    // colonne d'eau
    var cw = 21 * s;
    var wg = g.createLinearGradient(0, surf, 0, base + 6 * s);
    wg.addColorStop(0, rgba(C.eau, .55)); wg.addColorStop(.6, rgba(C.eauC, .5)); wg.addColorStop(1, rgba(C.eauC, .06));
    g.fillStyle = wg; rr(g, cx - cw, surf, cw * 2, h + 6 * s, 10 * s); g.fill();
    g.strokeStyle = rgba(C.marine, .1); g.lineWidth = 1; rr(g, cx - cw, surf, cw * 2, h + 6 * s, 10 * s); g.stroke();
    // surface
    var pops = [];
    function surface() {
      g.strokeStyle = rgba(C.marine, .38); g.lineWidth = 1.4 * s; g.lineCap = 'round'; g.beginPath();
      for (var x = -cw + 3 * s; x <= cw - 3 * s; x += 2) {
        var y = surf + Math.sin(x * .22 / s - t * 2.6) * .8 * s;
        if (x === -cw + 3 * s) g.moveTo(cx + x, y); else g.lineTo(cx + x, y);
      }
      g.stroke();
    }
    // source
    g.fillStyle = C.sil; g.beginPath(); g.ellipse(cx, base + 1 * s, 5.5 * s, 2 * s, 0, 0, TAU); g.fill();
    var bubs = [];
    for (var i = 0; i < 5; i++) {
      var ph = (t / P + i / 5), cyc = Math.floor(ph), p = ph - cyc, seed = cyc * 7 + i * 3.1;
      bubs.push({ p: p, seed: seed, i: i });
    }
    bubs.forEach(function (b) {
      var p = b.p, rise = .84;
      var sx = (rnd(b.seed) - .5) * 5 * s, phi = rnd(b.seed + 2) * TAU, dir = rnd(b.seed + 4) > .5 ? 1 : -1;
      if (p < rise) {
        var q = p / rise, u = .5 * q + .5 * q * q;
        var y = base - u * h, amp = (3.2 + 4 * u) * s;
        var x = cx + sx + dir * amp * Math.sin(TAU * 1.5 * u + phi) * (.35 + .65 * u);
        var r = (2 + 3.6 * Math.pow(u, .8) + rnd(b.seed + 6) * .8) * s;
        var wob = 1 + .09 * Math.sin(t * 11 + b.i * 2);
        var al = clamp(q * 10, 0, 1);
        g.save(); g.translate(x, y); g.scale(1 / wob, wob); g.globalAlpha = al;
        var gr = g.createRadialGradient(-r * .3, -r * .35, r * .1, 0, 0, r);
        gr.addColorStop(0, 'rgba(255,255,255,.95)'); gr.addColorStop(.7, 'rgba(199,223,243,.55)'); gr.addColorStop(1, 'rgba(156,199,234,.5)');
        g.fillStyle = gr; g.beginPath(); g.arc(0, 0, r, 0, TAU); g.fill();
        g.strokeStyle = rgba(C.marine, .55); g.lineWidth = Math.max(.8, .85 * s); g.stroke();
        g.strokeStyle = 'rgba(255,255,255,.95)'; g.lineWidth = Math.max(.8, r * .2); g.lineCap = 'round';
        g.beginPath(); g.arc(0, 0, r * .6, PI * 1.15, PI * 1.55); g.stroke();
        g.restore();
        b.x = x; b.r = r;
      } else {
        var qq = (p - rise) / (1 - rise), ux = cx + sx + dir * amp0() * Math.sin(TAU * 1.5 + phi), r0 = (3.6 + rnd(b.seed + 6) * .6) * s;
        function amp0() { return 7.2 * s; }
        var e = eout(qq);
        g.strokeStyle = rgba(C.marine, .5 * (1 - qq)); g.lineWidth = Math.max(.6, 1.1 * s * (1 - qq * .6));
        g.beginPath(); g.arc(ux, surf + 1 * s, r0 * (.8 + 1.1 * e), 0, TAU); g.stroke();
        // gouttelettes
        for (var d = 0; d < 4; d++) {
          var ang = -PI * (.2 + .6 * d / 3) , vv = 20 * s, tt = qq * .22;
          var dx = Math.cos(ang) * vv * tt * 1.6, dyy = Math.sin(ang) * vv * tt * 2.2 + 70 * s * tt * tt;
          g.fillStyle = rgba(C.marine, .45 * (1 - qq)); g.beginPath(); g.arc(ux + dx, surf + dyy, .9 * s, 0, TAU); g.fill();
        }
        // onde en surface
        g.strokeStyle = rgba(C.marine, .22 * (1 - qq)); g.lineWidth = .9;
        g.beginPath(); g.ellipse(ux, surf + 1 * s, (4 + 12 * e) * s, (1 + 2.6 * e) * s, 0, 0, TAU); g.stroke();
      }
    });
    surface();
  }

  /* ======================= ATTENTE D : Moulinet ======================= */
  function qb(p0, c, p2, t) {
    var u = 1 - t;
    return [u * u * p0[0] + 2 * u * t * c[0] + t * t * p2[0], u * u * p0[1] + 2 * u * t * c[1] + t * t * p2[1]];
  }
  function drawMoulinet(g, t, L) {
    var s = L.s * 1.0, P = 3.0, lt = t % P, p = lt / P;
    var ox = L.cx + 2 * s, oy = L.cy - 2 * s;
    function X(x) { return ox + x * s; } function Y(y) { return oy + y * s; }
    var P0 = [-50, 14], CC = [-8, -3], P2 = [38, -30];
    var water = 36;
    // canne (conique)
    var N = 24, left = [], right = [];
    for (var i = 0; i <= N; i++) {
      var tt = i / N, q = qb(P0, CC, P2, tt), q2 = qb(P0, CC, P2, Math.min(1, tt + .01)), q1 = qb(P0, CC, P2, Math.max(0, tt - .01));
      var dx = q2[0] - q1[0], dy = q2[1] - q1[1], dl = Math.hypot(dx, dy), nx = -dy / dl, ny = dx / dl, w = lerp(1.9, .5, tt);
      left.push([X(q[0] + nx * w), Y(q[1] + ny * w)]); right.push([X(q[0] - nx * w), Y(q[1] - ny * w)]);
    }
    g.fillStyle = C.encre; g.beginPath(); left.forEach(function (q, k) { k ? g.lineTo(q[0], q[1]) : g.moveTo(q[0], q[1]); });
    for (var j = N; j >= 0; j--) g.lineTo(right[j][0], right[j][1]); g.closePath(); g.fill();
    // poignée
    var hq = qb(P0, CC, P2, .06), hq0 = qb(P0, CC, P2, 0);
    g.strokeStyle = C.marineF; g.lineWidth = 4.2 * s; g.lineCap = 'round'; g.beginPath(); g.moveTo(X(hq0[0] - 3), Y(hq0[1] + 1.6)); g.lineTo(X(hq[0] + 8), Y(hq[1] - 3)); g.stroke();
    // guides
    var guides = [.5, .74, .93].map(function (u) { var q = qb(P0, CC, P2, u); return [q[0], q[1] - 0.4]; });
    var tip = qb(P0, CC, P2, 1);
    // moulinet
    var foot = qb(P0, CC, P2, .3), rc = [foot[0] + 3, foot[1] + 17.5], rad = 12.5;
    // lure : progression
    var fadeIn = sstep(0, .07, p), fadeOut = 1 - sstep(.93, 1, p);
    var u = eio(clamp((p - .08) / .76, 0, 1));
    var wind = u; // enroulement
    var spin = TAU * 3.2 * u + (p > .84 ? 0 : 0);
    var rw = lerp(7.4, 10.4, wind);
    // pied
    g.strokeStyle = C.marineF; g.lineWidth = 2.6 * s; g.lineCap = 'round';
    g.beginPath(); g.moveTo(X(foot[0]), Y(foot[1])); g.lineTo(X(rc[0]), Y(rc[1] - 7)); g.stroke();
    g.fillStyle = C.marineF; rr(g, X(rc[0] - 6), Y(foot[1] + 1), 12 * s, 3.2 * s, 1.6 * s); g.fill();
    // corps : flasque
    g.fillStyle = C.marine; g.beginPath(); g.arc(X(rc[0]), Y(rc[1]), rad * s, 0, TAU); g.fill();
    g.strokeStyle = 'rgba(255,255,255,.22)'; g.lineWidth = .9 * s; g.beginPath(); g.arc(X(rc[0]), Y(rc[1]), (rad - 1.1) * s, PI * 1.05, PI * 1.75); g.stroke();
    // bobine : fil enroulé
    g.fillStyle = '#FFFFFF'; g.beginPath(); g.arc(X(rc[0]), Y(rc[1]), (rw + 1.2) * s, 0, TAU); g.fill();
    g.strokeStyle = rgba(C.douce, .55); g.lineWidth = .7 * s;
    for (var ring = 0; ring < 4; ring++) { g.beginPath(); g.arc(X(rc[0]), Y(rc[1]), (rw - ring * (rw - 4.4) / 4) * s, 0, TAU); g.stroke(); }
    // rayons qui tournent
    g.save(); g.translate(X(rc[0]), Y(rc[1])); g.rotate(spin);
    g.fillStyle = C.marineF; g.beginPath(); g.arc(0, 0, 4.6 * s, 0, TAU); g.fill();
    g.fillStyle = rgba(C.marineF, .9);
    for (var sp = 0; sp < 3; sp++) {
      g.save(); g.rotate(sp * TAU / 3); rr(g, 2.5 * s, -1.1 * s, (rw - 3) * s, 2.2 * s, 1.1 * s); g.fill(); g.restore();
    }
    // manivelle
    g.strokeStyle = C.encre; g.lineWidth = 2.2 * s; g.lineCap = 'round'; g.beginPath(); g.moveTo(0, 0); g.lineTo(0, rad * s * 1.5); g.stroke();
    g.fillStyle = C.encre; g.beginPath(); g.arc(0, rad * s * 1.5 + 1.2 * s, 2.7 * s, 0, TAU); g.fill();
    g.fillStyle = '#FFFFFF'; g.beginPath(); g.arc(0, 0, 1.5 * s, 0, TAU); g.fill();
    g.restore();
    // eau
    var wy = Y(water), bw = 46 * s, wcx = X(26);
    // leurre
    var swing = Math.sin(lt * 4.4) * 1.1 * (1 - u * .4) * s;
    var dFar = 78, dNear = 11;
    var d = lerp(dFar, dNear, u), lx = X(tip[0]) + swing, ly = Y(tip[1] + d);
    var spoolPt = [X(rc[0]) + Math.cos(-.7) * rw * s, Y(rc[1]) + Math.sin(-.7) * rw * s];
    var linePts = [spoolPt].concat(guides.map(function (q) { return [X(q[0]), Y(q[1])]; })).concat([[X(tip[0]), Y(tip[1])]]);
    var la = fadeIn * fadeOut;
    g.save(); g.globalAlpha = 1;
    g.strokeStyle = rgba(C.douce, .85 * Math.max(.0, 1)); g.lineWidth = .9 * s; g.lineJoin = 'round';
    g.beginPath(); linePts.forEach(function (q, k) { k ? g.lineTo(q[0], q[1]) : g.moveTo(q[0], q[1]); });
    g.lineTo(lx, ly - 6 * s); g.stroke();
    // anneaux de guide
    g.strokeStyle = C.encre; g.lineWidth = .9 * s; guides.forEach(function (q) { g.beginPath(); g.arc(X(q[0]), Y(q[1]) + 0, 1.5 * s, 0, TAU); g.stroke(); });
    g.restore();
    // leurre : poisson, nez vers le haut
    g.save(); g.globalAlpha = la;
    g.save(); g.beginPath(); g.rect(0, 0, 9999, wy); g.clip();
    fish(g, lx, ly, 17 * s, -PI / 2 + swing * .02, .5 * Math.sin(lt * 17), C.marine, '#FFFFFF');
    g.restore();
    // sous la surface : vu à travers l'eau
    g.save(); g.beginPath(); g.rect(0, wy, 9999, 200); g.clip(); g.globalAlpha = la * .62;
    fish(g, lx + Math.sin(lt * 6) * .8 * s, ly, 17 * s, -PI / 2, .5 * Math.sin(lt * 17), C.marine, '#FFFFFF');
    g.restore(); g.restore();
    // bol d'eau
    var bowl = new Path2D(); bowl.moveTo(wcx - bw, wy); bowl.lineTo(wcx + bw, wy); bowl.ellipse(wcx, wy, bw, 22 * s, 0, 0, PI);
    g.save(); g.clip(bowl);
    var wg = g.createLinearGradient(0, wy, 0, wy + 22 * s);
    wg.addColorStop(0, rgba(C.eau, .6)); wg.addColorStop(.55, rgba(C.eauC, .5)); wg.addColorStop(1, rgba(C.eauC, 0));
    g.fillStyle = wg; g.fillRect(wcx - bw, wy, bw * 2, 24 * s); g.restore();
    var sg = g.createLinearGradient(wcx - bw, 0, wcx + bw, 0);
    sg.addColorStop(0, rgba(C.marine, 0)); sg.addColorStop(.25, rgba(C.marine, .26)); sg.addColorStop(.75, rgba(C.marine, .26)); sg.addColorStop(1, rgba(C.marine, 0));
    g.strokeStyle = sg; g.lineWidth = 1.2; g.beginPath();
    for (var x = -bw; x <= bw; x += 3) { var yy = wy + Math.sin(x * .1 / s - t * 3) * .5 * s; x === -bw ? g.moveTo(wcx + x, yy) : g.lineTo(wcx + x, yy); }
    g.stroke();
    // franchissement de la surface : onde + gouttes
    var uc = (dFar - (water - tip[1])) / (dFar - dNear); // u à la surface
    var pc = .08 + .76 * invEio(uc), ta = (p - pc) * P;
    if (ta > 0 && ta < .9) {
      var kk = ta / .9;
      g.strokeStyle = rgba(C.marine, .42 * (1 - kk)); g.lineWidth = 1.1;
      g.beginPath(); g.ellipse(lx, wy, (3 + 22 * eout(kk)) * s, (1 + 5.5 * eout(kk)) * s, 0, 0, TAU); g.stroke();
      if (ta < .5) for (var dd = 0; dd < 5; dd++) {
        var vx = (dd - 2) * 7 * s, vy = -(26 + (dd % 2) * 9) * s, tt2 = ta;
        g.fillStyle = rgba(C.marine, .55 * (1 - ta / .5)); g.beginPath();
        g.arc(lx + vx * tt2 * 2.2, wy + vy * tt2 * 2 + 120 * s * tt2 * tt2, 1.05 * s, 0, TAU); g.fill();
      }
    }
    // pointe de canne : léger rebond quand le leurre arrive
    if (p > .8 && p < .93) { /* rien : la tension se voit au fil droit */ }
  }
  function invEio(y) { // inverse de eio (cubique)
    y = clamp(y, 0, 1);
    return y < .5 ? Math.pow(y / 4, 1 / 3) : 1 - Math.pow((1 - y) * 2, 1 / 3) / 2 ;
  }

  /* ======================= CARTE : fond de carte commun ======================= */
  var RIV = (function () {
    var pts = [[-14, 118], [52, 160], [94, 226], [112, 292], [148, 346], [178, 410], [164, 476], [206, 540], [282, 568], [318, 630], [300, 692], [352, 742], [414, 772]];
    var out = [], ext = [pts[0]].concat(pts, [pts[pts.length - 1]]);
    for (var i = 1; i < ext.length - 2; i++) {
      for (var k = 0; k < 16; k++) {
        var u = k / 16, p0 = ext[i - 1], p1 = ext[i], p2 = ext[i + 1], p3 = ext[i + 2], u2 = u * u, u3 = u2 * u;
        out.push([
          .5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * u + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * u2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * u3),
          .5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * u + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * u2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * u3)
        ]);
      }
    }
    out.push(pts[pts.length - 1]);
    var cum = [0];
    for (var j = 1; j < out.length; j++) cum.push(cum[j - 1] + Math.hypot(out[j][0] - out[j - 1][0], out[j][1] - out[j - 1][1]));
    return { p: out, cum: cum, total: cum[cum.length - 1] };
  })();
  function rivAt(L) {
    var c = RIV.cum, p = RIV.p; L = clamp(L, 0, RIV.total);
    var lo = 0, hi = c.length - 1;
    while (hi - lo > 1) { var m = (lo + hi) >> 1; if (c[m] <= L) lo = m; else hi = m; }
    var k = (L - c[lo]) / Math.max(1e-6, c[hi] - c[lo]);
    return { x: lerp(p[lo][0], p[hi][0], k), y: lerp(p[lo][1], p[hi][1], k), ang: Math.atan2(p[hi][1] - p[lo][1], p[hi][0] - p[lo][0]), i: lo };
  }
  function riverWidth(L) { return lerp(6.4, 11.5, L / RIV.total); }
  function strip(g, L, wMul, fill) {
    var p = RIV.p, c = RIV.cum, left = [], right = [];
    for (var i = 0; i < p.length && c[i] <= L; i++) push(p[i][0], p[i][1], i, c[i]);
    var e = rivAt(L); if (!left.length || c[left.length - 1] < L - .01) push(e.x, e.y, Math.min(p.length - 2, e.i), L);
    function push(x, y, i, l) {
      var a = p[Math.max(0, i - 1)], b = p[Math.min(p.length - 1, i + 1)], dx = b[0] - a[0], dy = b[1] - a[1], d = Math.hypot(dx, dy) || 1, w = riverWidth(l) * wMul / 2;
      left.push([x - dy / d * w, y + dx / d * w]); right.push([x + dy / d * w, y - dx / d * w]);
    }
    if (left.length < 2) return;
    g.fillStyle = fill; g.beginPath(); left.forEach(function (q, k) { k ? g.lineTo(q[0], q[1]) : g.moveTo(q[0], q[1]); });
    for (var j = right.length - 1; j >= 0; j--) g.lineTo(right[j][0], right[j][1]); g.closePath(); g.fill();
    g.beginPath(); g.arc(e.x, e.y, riverWidth(L) * wMul / 2, 0, TAU); g.fill();
  }
  function drawRiver(g, L, alpha) {
    if (L < 1) return;
    g.save(); g.globalAlpha = alpha;
    strip(g, L, 1.5, rgba(C.eau, .34));
    strip(g, L, 1, C.eau);
    strip(g, L, .38, rgba(C.eauC, .95));
    g.restore();
  }
  var LAKE = (function () {
    var cx = 112, cy = 292, rad = [1, .93, 1.1, .97, 1.05, .9, 1.07, .98], n = rad.length, pts = [];
    for (var i = 0; i < n; i++) { var a = i / n * TAU - .5; pts.push([cx + Math.cos(a) * 62 * rad[i], cy + Math.sin(a) * 41 * rad[i]]); }
    return { cx: cx, cy: cy, pts: pts };
  })();
  function lakePath(g, sc, dx, dy) {
    var P = LAKE.pts, n = P.length;
    function T(q) { return [LAKE.cx + (q[0] - LAKE.cx) * sc + dx, LAKE.cy + (q[1] - LAKE.cy) * sc + dy]; }
    g.beginPath();
    for (var i = 0; i < n; i++) {
      var p0 = T(P[(i + n - 1) % n]), p1 = T(P[i]), p2 = T(P[(i + 1) % n]), p3 = T(P[(i + 2) % n]);
      if (i === 0) g.moveTo(p1[0], p1[1]);
      g.bezierCurveTo(p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6, p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1]);
    }
    g.closePath();
  }
  function drawLake(g, alpha) {
    g.save(); g.globalAlpha = alpha;
    lakePath(g, 1.07, 0, 0); g.fillStyle = rgba(C.eau, .32); g.fill();
    lakePath(g, 1, 0, 0); g.fillStyle = C.eau; g.fill();
    lakePath(g, .7, -5, -4); g.fillStyle = rgba(C.eauC, .9); g.fill();
    lakePath(g, 1, 0, 0); g.strokeStyle = rgba(C.marine, .1); g.lineWidth = 1; g.stroke();
    g.restore();
  }
  var STATIONS = [.1, .24, .36, .48, .6, .72, .86];
  function stationPos(i) { return rivAt(STATIONS[i] * RIV.total); }
  function drawStationDot(g, x, y, sc) {
    if (sc <= 0) return;
    g.save(); g.translate(x, y); g.scale(sc, sc);
    g.fillStyle = 'rgba(4,18,43,.16)'; g.beginPath(); g.arc(0, 1.4, 6.6, 0, TAU); g.fill();
    g.fillStyle = '#FFFFFF'; g.beginPath(); g.arc(0, 0, 6, 0, TAU); g.fill();
    g.strokeStyle = C.marine; g.lineWidth = 2.4; g.stroke();
    g.fillStyle = C.marine; g.beginPath(); g.arc(0, 0, 1.9, 0, TAU); g.fill();
    g.restore();
  }
  function drawPin(g, x, y, sc, fishLen) {
    if (sc <= 0) return;
    g.save(); g.translate(x, y); g.scale(sc, sc);
    g.shadowColor = 'rgba(4,18,43,.22)'; g.shadowBlur = 8; g.shadowOffsetY = 2;
    g.fillStyle = '#FFFFFF'; g.beginPath(); g.arc(0, -29, 14.5, 0, TAU); g.fill();
    g.beginPath(); g.moveTo(-5, -17); g.lineTo(0, -8.5); g.lineTo(5, -17); g.closePath(); g.fill();
    g.shadowColor = 'transparent'; g.shadowBlur = 0; g.shadowOffsetY = 0;
    fish(g, 0, -29, fishLen || 17, 0, .12, C.marine, '#FFFFFF');
    g.restore();
  }
  function drawUser(g, x, y, t) {
    var k = (t % 2) / 2, hr = 9 + 20 * eout(k);
    g.fillStyle = rgba(C.marine, .2 * (1 - k)); g.beginPath(); g.arc(x, y, hr, 0, TAU); g.fill();
    g.fillStyle = 'rgba(4,18,43,.2)'; g.beginPath(); g.arc(x, y + 1.5, 11, 0, TAU); g.fill();
    g.fillStyle = '#FFFFFF'; g.beginPath(); g.arc(x, y, 10.5, 0, TAU); g.fill();
    g.fillStyle = C.marine; g.beginPath(); g.arc(x, y, 7, 0, TAU); g.fill();
  }

  /* fond de carte (terre, parcelles, routes) prérendu */
  var landCache = null;
  function landBase(scale) {
    if (landCache && landCache.scale >= scale) return landCache.cv;
    var cv = document.createElement('canvas'); cv.width = Math.round(390 * scale); cv.height = Math.round(844 * scale);
    var g = cv.getContext('2d'); g.scale(scale, scale);
    g.fillStyle = C.page; g.fillRect(0, 0, 390, 844);
    var cell = 64, jit = 16, V = {};
    function v(i, j) { var k = i + ',' + j; if (!V[k]) V[k] = [i * cell + (rnd(i * 9.1 + j * 3.7) - .5) * jit * 2, j * cell + (rnd(i * 5.3 + j * 11.9) - .5) * jit * 2]; return V[k]; }
    for (var i = -1; i < 8; i++) for (var j = -1; j < 15; j++) {
      var a = v(i, j), b = v(i + 1, j), c = v(i + 1, j + 1), d = v(i, j + 1), r = rnd(i * 13 + j * 7);
      if (r < .22) { g.fillStyle = 'rgba(255,255,255,.7)'; } else if (r < .34) { g.fillStyle = 'rgba(231,239,248,.7)'; } else continue;
      g.beginPath(); g.moveTo(a[0], a[1]); g.lineTo(b[0], b[1]); g.lineTo(c[0], c[1]); g.lineTo(d[0], d[1]); g.closePath(); g.fill();
    }
    g.strokeStyle = 'rgba(220,227,235,.62)'; g.lineWidth = .7;
    for (i = -1; i < 8; i++) for (j = -1; j < 15; j++) {
      if (rnd(i * 3.3 + j * 8.1) > .26) { var p = v(i, j), q = v(i + 1, j); g.beginPath(); g.moveTo(p[0], p[1]); g.lineTo(q[0], q[1]); g.stroke(); }
      if (rnd(i * 6.7 + j * 2.9) > .26) { p = v(i, j); q = v(i, j + 1); g.beginPath(); g.moveTo(p[0], p[1]); g.lineTo(q[0], q[1]); g.stroke(); }
    }
    function road(pts) {
      g.lineCap = 'round'; g.lineJoin = 'round';
      [[7.4, C.filet], [5.2, '#FFFFFF']].forEach(function (s) {
        g.strokeStyle = s[1]; g.lineWidth = s[0]; g.beginPath();
        for (var k = 0; k < pts.length - 1; k++) {
          var p0 = pts[Math.max(0, k - 1)], p1 = pts[k], p2 = pts[k + 1], p3 = pts[Math.min(pts.length - 1, k + 2)];
          if (k === 0) g.moveTo(p1[0], p1[1]);
          g.bezierCurveTo(p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6, p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6, p2[0], p2[1]);
        }
        g.stroke();
      });
    }
    road([[-10, 612], [90, 566], [200, 622], [330, 576], [410, 520]]);
    road([[300, -10], [284, 110], [336, 250], [296, 380], [352, 480], [360, 560]]);
    road([[-10, 40], [120, 70], [250, 40], [410, 90]]);
    landCache = { scale: scale, cv: cv };
    return cv;
  }
  function phoneFit(g, W, H, dpr) {
    var s = W / 390, oy = (H - 844 * s) / 2;
    g.fillStyle = C.page; g.fillRect(0, 0, W, H);
    g.save(); g.translate(0, oy); g.scale(s, s);
    return s;
  }
  function mapLand(g, s, dpr) {
    var cv = landBase(Math.max(1, s * dpr));
    g.drawImage(cv, 0, 0, 390, 844);
  }
  function tabBar(g, alpha) {
    g.save(); g.globalAlpha = alpha == null ? 1 : alpha;
    g.shadowColor = 'rgba(4,18,43,.14)'; g.shadowBlur = 20; g.shadowOffsetY = 6;
    g.fillStyle = 'rgba(255,255,255,.94)'; rr(g, 24, 772, 342, 56, 28); g.fill();
    g.shadowColor = 'transparent'; g.shadowBlur = 0; g.shadowOffsetY = 0;
    g.fillStyle = rgba(C.tuile, 1); rr(g, 140, 778, 110, 44, 22); g.fill();
    [[84, C.sil], [195, C.marine], [306, C.sil]].forEach(function (q) {
      g.fillStyle = q[1]; rr(g, q[0] - 10, 790, 20, 20, 6); g.fill();
    });
    g.restore();
  }
  function topChip(g, alpha) {
    g.save(); g.globalAlpha = alpha == null ? 1 : alpha;
    g.shadowColor = 'rgba(4,18,43,.1)'; g.shadowBlur = 12; g.shadowOffsetY = 3;
    g.fillStyle = 'rgba(255,255,255,.95)'; rr(g, 16, 56, 156, 40, 20); g.fill();
    g.beginPath(); g.arc(350, 76, 22, 0, TAU); g.fill();
    g.shadowColor = 'transparent'; g.shadowBlur = 0; g.shadowOffsetY = 0;
    g.fillStyle = C.marine; g.beginPath(); g.arc(37, 76, 4.2, 0, TAU); g.fill();
    txt(g, 'La Marne · 94', 50, 81.5, 15, C.encre, 'left', 800);
    g.strokeStyle = C.marine; g.lineWidth = 2; g.lineJoin = 'round';
    g.beginPath(); g.moveTo(341, 70); g.lineTo(347, 68); g.lineTo(353, 70); g.lineTo(359, 68); g.lineTo(359, 82); g.lineTo(353, 84); g.lineTo(347, 82); g.lineTo(341, 84); g.closePath(); g.stroke();
    g.restore();
  }
  function statusPill(g, texte, alpha, t) {
    g.save(); g.globalAlpha = alpha;
    g.font = '800 14px ' + FONT; var w = g.measureText(texte).width + 62;
    g.shadowColor = 'rgba(4,18,43,.12)'; g.shadowBlur = 14; g.shadowOffsetY = 4;
    g.fillStyle = 'rgba(255,255,255,.96)'; rr(g, 195 - w / 2, 706, w, 40, 20); g.fill();
    g.shadowColor = 'transparent'; g.shadowBlur = 0; g.shadowOffsetY = 0;
    txt(g, texte, 195 - w / 2 + 40, 731, 14, C.encre, 'left', 800);
    // trois points d'eau
    for (var i = 0; i < 3; i++) {
      var k = ((t * 1.1 - i * .16) % 1 + 1) % 1, y = -3.2 * Math.sin(clamp(k * 1.6, 0, 1) * PI);
      g.fillStyle = C.marine; g.beginPath(); g.arc(195 - w / 2 + 16 + i * 7, 726 + y, 2, 0, TAU); g.fill();
    }
    g.restore();
  }

  /* ======================= CARTE A : Sonar ======================= */
  var USER = [232, 438], SONAR_P = 3.4, SONAR_R = 430, SONAR_LOOP = 8.2;
  var FISH_ST = [1, 3, 5];
  function drawSonar(g, t, W, H, api, dpr) {
    var s = phoneFit(g, W, H, dpr);
    var lt = t % SONAR_LOOP;
    var env = sstep(0, .5, lt) * (1 - sstep(7.4, 8.1, lt));
    mapLand(g, s, dpr);
    drawLake(g, 1); drawRiver(g, RIV.total, 1);
    var a0 = -PI / 2, ang = a0 + TAU * lt / SONAR_P;
    // anneaux de portée
    g.strokeStyle = rgba(C.marine, .07 * env); g.lineWidth = 1;
    [95, 190, 285, 380].forEach(function (r) { g.beginPath(); g.arc(USER[0], USER[1], r, 0, TAU); g.stroke(); });
    // faisceau
    if (env > .01) {
      var cg = g.createConicGradient(ang - 1.35, USER[0], USER[1]);
      var span = 1.35 / TAU;
      cg.addColorStop(0, rgba(C.marine, 0)); cg.addColorStop(span * .6, rgba(C.marine, .035 * env));
      cg.addColorStop(span, rgba(C.marine, .15 * env)); cg.addColorStop(Math.min(.999, span + .0006), rgba(C.marine, 0)); cg.addColorStop(1, rgba(C.marine, 0));
      g.fillStyle = cg; g.beginPath(); g.arc(USER[0], USER[1], SONAR_R, 0, TAU); g.fill();
      var lg = g.createLinearGradient(USER[0], USER[1], USER[0] + Math.cos(ang) * SONAR_R, USER[1] + Math.sin(ang) * SONAR_R);
      lg.addColorStop(0, rgba(C.marine, .4 * env)); lg.addColorStop(1, rgba(C.marine, 0));
      g.strokeStyle = lg; g.lineWidth = 1.6; g.lineCap = 'round'; g.beginPath(); g.moveTo(USER[0], USER[1]); g.lineTo(USER[0] + Math.cos(ang) * SONAR_R, USER[1] + Math.sin(ang) * SONAR_R); g.stroke();
    }
    // stations
    var pins = [];
    for (var i = 0; i < STATIONS.length; i++) {
      var sp = stationPos(i), phi = Math.atan2(sp.y - USER[1], sp.x - USER[0]);
      var turns = ((((phi - a0) % TAU) + TAU) % TAU) / TAU, tp = turns * SONAR_P;
      var age = lt - tp;
      if (age >= 0) {
        var sc = spring(age, .5, 17);
        drawStationDot(g, sp.x, sp.y, sc * (lt < 7.4 ? 1 : 1 - sstep(7.4, 8.1, lt)));
      }
      // pings à chaque passage du faisceau (0,3 s)
      for (var k = 0; k < 3; k++) {
        var ag = lt - (tp + k * SONAR_P);
        if (ag >= 0 && ag < .3) {
          var q = ag / .3, e = eout(q);
          g.strokeStyle = rgba(C.marine, (k ? .35 : .6) * (1 - q) * env); g.lineWidth = lerp(2.4, .6, q);
          g.beginPath(); g.arc(sp.x, sp.y, 6 + (k ? 14 : 22) * e, 0, TAU); g.stroke();
        }
      }
      var fi = FISH_ST.indexOf(i);
      if (fi >= 0) {
        var ft = lt - (SONAR_P + .55 + fi * .42);
        if (ft > 0) pins.push([sp.x, sp.y, spring(ft, .52, 16) * (1 - sstep(7.4, 8.1, lt))]);
      }
    }
    pins.forEach(function (q) { drawPin(g, q[0], q[1], q[2], 18); });
    drawUser(g, USER[0], USER[1], t);
    topChip(g); tabBar(g);
    statusPill(g, 'Je cherche les relevés OFB', 1, t);
    g.restore();
  }

  /* ======================= CARTE B : La rivière se dessine ======================= */
  var DRAW_LOOP = 7.0;
  function drawRiviere(g, t, W, H, api, dpr) {
    var s = phoneFit(g, W, H, dpr);
    var lt = t % DRAW_LOOP;
    var fade = 1 - sstep(5.9, 6.6, lt);
    mapLand(g, s, dpr);
    var u = clamp((lt - .4) / 3.9, 0, 1), eased = .45 * u + .55 * (u * u * (3 - 2 * u));
    var Ld = eased * RIV.total;
    var lakeF = .26 * RIV.total;
    // lac : s'étale dès que la pointe l'atteint
    var lt0 = lt - tAtL(lakeF - 30);
    if (lt0 > 0) {
      var rv = spring(lt0, .8, 7);
      g.save(); g.globalAlpha = fade; g.beginPath(); g.arc(LAKE.cx, LAKE.cy, 90 * clamp(rv, 0, 1.08), 0, TAU); g.clip();
      drawLake(g, 1); g.restore();
    }
    drawRiver(g, Ld, fade);
    // courant : traits clairs qui avancent une fois la rivière finie
    if (u >= 1) {
      var fl = sstep(4.3, 5, lt) * fade;
      g.save(); g.globalAlpha = .75 * fl; g.strokeStyle = '#FFFFFF'; g.lineWidth = 1.7; g.lineCap = 'round'; g.setLineDash([9, 30]); g.lineDashOffset = -lt * 34;
      g.beginPath(); RIV.p.forEach(function (q, k) { k ? g.lineTo(q[0], q[1]) : g.moveTo(q[0], q[1]); }); g.stroke(); g.restore();
    }
    // stations qui sautent derrière la pointe
    for (var i = 0; i < STATIONS.length; i++) {
      var sp = stationPos(i), ta = lt - (tAtL(STATIONS[i] * RIV.total) + .14);
      if (ta > 0) {
        g.save(); g.globalAlpha = fade; drawStationDot(g, sp.x, sp.y, spring(ta, .45, 19));
        if (ta < .45) { var q = ta / .45; g.strokeStyle = rgba(C.marine, .5 * (1 - q)); g.lineWidth = lerp(2.2, .5, q); g.beginPath(); g.arc(sp.x, sp.y, 6 + 16 * eout(q), 0, TAU); g.stroke(); }
        g.restore();
      }
    }
    // petit poisson à la pointe
    var tip, run = Math.max(0, lt - (.4 + 3.9));
    if (u < 1) tip = rivAt(Ld); else { var e0 = rivAt(RIV.total); tip = { x: e0.x + Math.cos(e0.ang) * run * 80, y: e0.y + Math.sin(e0.ang) * run * 80, ang: e0.ang }; }
    var fal = (lt > .3 ? sstep(.3, .6, lt) : 0) * (1 - sstep(4.8, 5.6, lt)) * fade;
    if (fal > .01) {
      // viser un peu en avant de la pointe, avec une légère ondulation latérale
      var wob = Math.sin(lt * 5.4) * 2.2;
      var fx = tip.x + Math.cos(tip.ang) * 5 - Math.sin(tip.ang) * wob, fy = tip.y + Math.sin(tip.ang) * 5 + Math.cos(tip.ang) * wob;
      g.save(); g.globalAlpha = fal;
      g.fillStyle = 'rgba(4,18,43,.15)'; g.beginPath(); g.ellipse(fx + 1, fy + 3, 12, 5, tip.ang, 0, TAU); g.fill();
      fish(g, fx, fy, 27, tip.ang + Math.cos(lt * 5.4) * .1, .42 * Math.sin(TAU * 2.6 * lt), C.marine, '#FFFFFF');
      g.restore();
    }
    topChip(g); tabBar(g);
    statusPill(g, 'Je trace la rivière', 1, t);
    g.restore();
  }
  function tAtL(L) { // instant où la pointe atteint L
    var f = L / RIV.total, lo = 0, hi = 1;
    for (var i = 0; i < 24; i++) { var m = (lo + hi) / 2, e = .45 * m + .55 * (m * m * (3 - 2 * m)); if (e < f) lo = m; else hi = m; }
    return .4 + 3.9 * lo;
  }

  /* ======================= CARTE C : Squelette d'eau ======================= */
  var CAU = { lw: 78, lh: 169, cv: null, g: null, img: null, mask: null, mg: null, tmp: null, tg: null };
  function cauInit() {
    if (CAU.cv) return;
    CAU.cv = document.createElement('canvas'); CAU.cv.width = CAU.lw; CAU.cv.height = CAU.lh; CAU.g = CAU.cv.getContext('2d');
    CAU.img = CAU.g.createImageData(CAU.lw, CAU.lh);
    var k = 1.5; CAU.k = k;
    CAU.mask = document.createElement('canvas'); CAU.mask.width = Math.round(390 * k); CAU.mask.height = Math.round(844 * k); CAU.mg = CAU.mask.getContext('2d');
    CAU.tmp = document.createElement('canvas'); CAU.tmp.width = CAU.mask.width; CAU.tmp.height = CAU.mask.height; CAU.tg = CAU.tmp.getContext('2d');
  }
  function skelShapes(g, fill) {
    // tuiles de carte
    var cols = 3, rows = 6, gap = 5, tw = (390 - gap * (cols + 1)) / cols, th = 108;
    if (fill) { g.fillStyle = fill; }
    for (var j = 0; j < rows; j++) for (var i = 0; i < cols; i++) {
      var x = gap + i * (tw + gap), y = 130 + j * (th + gap) - 70; if (y > 520) continue;
      rr(g, x, Math.max(y, 0), tw, th, 16); g.fill();
    }
    rr(g, 16, 56, 156, 40, 20); g.fill(); g.beginPath(); g.arc(350, 76, 22, 0, TAU); g.fill();
  }
  function skelCard(g, fillBar) {
    g.fillStyle = fillBar;
    rr(g, 40, 544, 150, 20, 10); g.fill(); rr(g, 40, 574, 230, 13, 6.5); g.fill();
    [40, 150, 260].forEach(function (x) { rr(g, x, 608, 90, 62, 18); g.fill(); });
    rr(g, 32, 692, 326, 54, 27); g.fill();
  }
  function drawSquelette(g, t, W, H, api, dpr) {
    cauInit();
    var s = phoneFit(g, W, H, dpr), P = 6.4, lt = t % P;
    var real = sstep(3.9, 4.5, lt) * (1 - sstep(5.8, 6.35, lt));
    var sk = 1 - real;
    // tuiles de carte : faibles
    g.save(); g.globalAlpha = sk;
    // la rivière en filigrane, très pâle
    g.strokeStyle = rgba(C.filet, .55); g.lineWidth = 9; g.lineCap = 'round'; g.lineJoin = 'round';
    g.beginPath(); RIV.p.forEach(function (q, k) { k ? g.lineTo(q[0], q[1]) : g.moveTo(q[0], q[1]); }); g.stroke();
    g.fillStyle = rgba(C.tuile, .78); skelShapes(g, rgba(C.tuile, .6));
    g.restore();
    // vrai contenu : carte
    if (real > 0) {
      g.save(); g.globalAlpha = real;
      mapLand(g, s, dpr); drawLake(g, 1); drawRiver(g, RIV.total, 1);
      for (var i = 0; i < STATIONS.length; i++) { var sp = stationPos(i); drawStationDot(g, sp.x, sp.y, 1); }
      drawPin(g, stationPos(2).x, stationPos(2).y, 1, 18); drawPin(g, stationPos(5).x, stationPos(5).y, 1, 18);
      topChip(g);
      g.restore();
    }
    // feuille du bas
    g.save();
    g.shadowColor = 'rgba(4,18,43,.13)'; g.shadowBlur = 26; g.shadowOffsetY = 6;
    g.fillStyle = '#FFFFFF'; rr(g, 16, 500, 358, 256, 30); g.fill();
    g.restore();
    g.fillStyle = C.filet; rr(g, 195 - 18, 511, 36, 5, 2.5); g.fill();
    g.save(); g.globalAlpha = sk; skelCard(g, C.tuile); g.restore();
    // barre d'onglets
    tabBar(g, 1);
    // vrai contenu : feuille
    if (real > 0) {
      g.save(); g.globalAlpha = real;
      txt(g, 'Le plus rare de ton spot', 40, 553, 12.5, C.douce, 'left', 700);
      txt(g, 'Sandre', 40, 584, 26, C.encre, 'left', 800);
      g.fillStyle = C.rare; g.beginPath(); g.moveTo(143, 569); g.lineTo(149, 575); g.lineTo(143, 581); g.lineTo(137, 575); g.closePath(); g.fill();
      txt(g, 'Rare', 156, 580, 14, C.rare, 'left', 800);
      ['brochet', 'perche', 'black-bass'].forEach(function (k, n) {
        var x = 40 + n * 110; g.fillStyle = C.tuile; rr(g, x, 608, 90, 62, 18); g.fill();
        var im = img(k); if (im.complete && im.naturalWidth) { var iw = 70, ih = iw * im.naturalHeight / im.naturalWidth; g.drawImage(im, x + 10, 639 - ih / 2, iw, ih); }
      });
      g.fillStyle = C.marine; rr(g, 32, 692, 326, 54, 27); g.fill();
      g.fillStyle = '#FFFFFF'; g.beginPath(); g.moveTo(98, 712); g.lineTo(98, 726); g.lineTo(110, 719); g.closePath(); g.fill();
      txt(g, 'Commencer une session', 124, 725, 16, '#FFFFFF', 'left', 800);
      g.restore();
    }
    // lumière d'eau : caustiques
    var pass = lt < 1.95 ? (lt - .15) / 1.7 : (lt - 2.05) / 1.7;
    var amp = (lt > .15 && lt < 3.75 && (lt < 1.85 || lt > 2.05) ? 1 : 0);
    if (!api._noCau && sk > .02 && lt > .1 && lt < 3.8 && (pass >= -.05 && pass <= 1.05)) {
      var tc = lt * .75 + 21, bc = lerp(-.35, 1.75, clamp(pass, 0, 1));
      var im2 = CAU.img, d = im2.data, lw = CAU.lw, lh = CAU.lh, any = false;
      for (var y = 0; y < lh; y++) {
        var py = y / lh * 844;
        for (var x = 0; x < lw; x++) {
          var px = x / lw * 390, uu = px / 390 * .5 + py / 844 * .95;
          var env = Math.exp(-Math.pow((uu - bc) / .3, 2)), o = (y * lw + x) * 4;
          if (env < .03) { d[o + 3] = 0; continue; }
          var v = caus(x / lw * 2.2, y / lw * 2.2, tc);
          any = true;
          // lumière : blanc franc dans les crêtes, eau claire dans les creux
          var hi = sstep(.1, .75, v) * .85, lo = clamp((.22 - v) / .22, 0, 1);
          if (hi > 0) { d[o] = 255; d[o + 1] = 255; d[o + 2] = 255; d[o + 3] = Math.round(255 * env * hi * 1.0); }
          else { d[o] = 120; d[o + 1] = 175; d[o + 2] = 226; d[o + 3] = Math.round(255 * env * lo * .26); }
        }
      }
      if (any) {
        CAU.g.putImageData(im2, 0, 0);
        var K = CAU.k;
        CAU.mg.setTransform(1, 0, 0, 1, 0, 0); CAU.mg.clearRect(0, 0, CAU.mask.width, CAU.mask.height); CAU.mg.setTransform(K, 0, 0, K, 0, 0); CAU.mg.fillStyle = '#000';
        skelShapes(CAU.mg); skelCard(CAU.mg, '#000'); CAU.mg.fillStyle = '#000'; skelCard(CAU.mg, '#000');
        CAU.tg.setTransform(1, 0, 0, 1, 0, 0); CAU.tg.globalCompositeOperation = 'source-over'; CAU.tg.clearRect(0, 0, CAU.tmp.width, CAU.tmp.height);
        CAU.tg.imageSmoothingEnabled = true; CAU.tg.imageSmoothingQuality = 'high';
        CAU.tg.drawImage(CAU.cv, 0, 0, CAU.tmp.width, CAU.tmp.height);
        CAU.tg.globalCompositeOperation = 'destination-in'; CAU.tg.drawImage(CAU.mask, 0, 0);
        g.save(); g.globalAlpha = sk; g.imageSmoothingEnabled = true; g.drawImage(CAU.tmp, 0, 0, 390, 844); g.restore();
      }
    }
    g.restore();
  }
  // caustiques d'eau (Hoskins, adapté)
  function caus(ux, uy, time) {
    var px = (ux * TAU) % TAU - 250, py = (uy * TAU) % TAU - 250, ix = px, iy = py, c = 1, inten = .005, N = 5;
    for (var n = 0; n < N; n++) {
      var tt = time * (1 - 3.5 / (n + 1));
      var nx = px + (Math.cos(tt - ix) + Math.sin(tt + iy)), ny = py + (Math.sin(tt - iy) + Math.cos(tt + ix));
      ix = nx; iy = ny;
      c += 1 / Math.hypot(px / (Math.sin(ix + tt) / inten), py / (Math.cos(iy + tt) / inten));
    }
    c /= N; c = 1.17 - Math.pow(c, 1.4);
    return Math.pow(Math.abs(c), 6);
  }

  /* ======================= RECONNAISSANCE A : Lecture de la photo ======================= */
  var PH = { x: 22, y: 112, w: 346, h: 420, r: 28 }, REC_LOOP = 5.2, photoCache = null;
  function photoBg(scale) {
    if (photoCache && photoCache.scale >= scale && photoCache.ready) return photoCache.cv;
    var im = img('perche');
    var cv = (photoCache && photoCache.cv) || document.createElement('canvas');
    cv.width = Math.round(PH.w * scale); cv.height = Math.round(PH.h * scale);
    var g = cv.getContext('2d');
    // flou d'arrière-plan : on dessine petit puis on agrandit
    var sm = document.createElement('canvas'); sm.width = 70; sm.height = 84; var sg = sm.getContext('2d');
    var gr = sg.createLinearGradient(0, 0, 0, 84); gr.addColorStop(0, '#47512C'); gr.addColorStop(.55, '#323A20'); gr.addColorStop(1, '#222915');
    sg.fillStyle = gr; sg.fillRect(0, 0, 70, 84);
    var cols = ['#59652F', '#3E4A22', '#6C7A38', '#2A3319', '#80703A', '#4B3F22', '#35401D', '#76853F'];
    for (var i = 0; i < 380; i++) {
      var x = rnd(i * 1.7) * 76 - 3, y = rnd(i * 2.9 + 4) * 90 - 3, l = 5 + rnd(i * 3.3) * 13, a = -PI / 2 + (rnd(i * 5.1) - .5) * 1.5;
      sg.strokeStyle = cols[i % cols.length]; sg.globalAlpha = .35 + rnd(i * 7.7) * .5; sg.lineWidth = .9 + rnd(i * 4.4) * 1.5;
      sg.beginPath(); sg.moveTo(x, y); sg.quadraticCurveTo(x + Math.cos(a) * l * .5 + 2, y + Math.sin(a) * l * .5, x + Math.cos(a) * l, y + Math.sin(a) * l); sg.stroke();
    }
    sg.globalAlpha = 1;
    g.imageSmoothingEnabled = true; g.imageSmoothingQuality = 'high'; g.drawImage(sm, 0, 0, cv.width, cv.height);
    g.save(); g.scale(scale, scale);
    // taches de soleil floues
    [[70, 90, 90, .22, '#D8D07A'], [270, 330, 70, .14, '#C3C86B'], [310, 80, 60, .12, '#B6C060']].forEach(function (b) {
      var rg = g.createRadialGradient(b[0], b[1], 0, b[0], b[1], b[2]); rg.addColorStop(0, rgba(b[4], b[3])); rg.addColorStop(1, rgba(b[4], 0));
      g.fillStyle = rg; g.fillRect(0, 0, PH.w, PH.h);
    });
    // ombre du poisson
    g.save(); g.translate(PH.w / 2 + 6, PH.h / 2 + 62); g.scale(1, .22);
    var sh = g.createRadialGradient(0, 0, 0, 0, 0, 150); sh.addColorStop(0, 'rgba(8,12,4,.6)'); sh.addColorStop(1, 'rgba(8,12,4,0)');
    g.fillStyle = sh; g.beginPath(); g.arc(0, 0, 150, 0, TAU); g.fill(); g.restore();
    // le poisson, net
    var ready = im.complete && im.naturalWidth > 0;
    if (ready) {
      var iw = 306, ih = iw * im.naturalHeight / im.naturalWidth;
      g.save(); g.translate(PH.w / 2, PH.h / 2 + 8); g.rotate(-.06);
      g.shadowColor = 'rgba(8,12,4,.5)'; g.shadowBlur = 16; g.shadowOffsetY = 12; g.drawImage(im, -iw / 2, -ih / 2, iw, ih); g.restore();
    }
    // vignette
    var vg = g.createRadialGradient(PH.w / 2, PH.h / 2, 90, PH.w / 2, PH.h / 2, 280); vg.addColorStop(0, 'rgba(10,14,6,0)'); vg.addColorStop(1, 'rgba(10,14,6,.5)');
    g.fillStyle = vg; g.fillRect(0, 0, PH.w, PH.h);
    g.restore();
    photoCache = { scale: scale, cv: cv, ready: ready };
    return cv;
  }
  function bracket(g, cx, cy, hw, hh, len, k) {
    var w = hw * k, h = hh * k;
    g.beginPath();
    [[-1, -1], [1, -1], [1, 1], [-1, 1]].forEach(function (c) {
      var x = cx + c[0] * w, y = cy + c[1] * h;
      g.moveTo(x - c[0] * len, y); g.lineTo(x, y); g.lineTo(x, y - c[1] * len);
    });
    g.stroke();
  }
  var recSoundCycle = -1;
  function drawLecture(g, t, W, H, api, dpr) {
    var s = W / 390, oy = (H - 844 * s) / 2;
    g.fillStyle = C.nuit; g.fillRect(0, 0, W, H);
    g.save(); g.translate(0, oy); g.scale(s, s);
    var cyc = Math.floor(t / REC_LOOP), lt = t - cyc * REC_LOOP;
    var out = 1 - sstep(4.55, 5.1, lt);
    if (lt < .02 || cyc !== recSoundCycle) { if (lt >= 1.75) { api.sound('bulles'); recSoundCycle = cyc; } }
    // halo doux derrière les candidats
    var hg = g.createRadialGradient(195, 690, 0, 195, 690, 260); hg.addColorStop(0, rgba(C.halo, .12 * sstep(1.6, 2.4, lt) * out)); hg.addColorStop(1, rgba(C.halo, 0));
    g.fillStyle = hg; g.fillRect(0, 440, 390, 404);
    // titre
    var lectureA = sstep(.15, .5, lt) * (1 - sstep(1.8, 2.15, lt));
    var choixA = sstep(2.0, 2.5, lt);
    g.save(); g.globalAlpha = out;
    g.globalAlpha = lectureA * out; txt(g, 'Lecture de la photo', 195, 74, 18, '#FFFFFF', 'center', 800);
    for (var d = 0; d < 3; d++) {
      var kk = ((lt * 1.2 - d * .15) % 1 + 1) % 1; g.fillStyle = rgba(C.lune, .9);
      g.beginPath(); g.arc(195 + 104 + d * 8, 74 - 2 - 3 * Math.sin(clamp(kk * 1.6, 0, 1) * PI), 1.7, 0, TAU); g.fill();
    }
    g.globalAlpha = choixA * out; txt(g, 'Touche la bonne espèce', 195, 74, 18, '#FFFFFF', 'center', 800);
    g.restore();
    // photo
    var pin = eout(clamp(lt / .5, 0, 1)), pa = pin * out, psc = lerp(.95, 1, pin);
    var dim = sstep(1.5, 2.3, lt) * .38;
    var cvp = photoBg(Math.max(1, s * dpr));
    g.save(); g.globalAlpha = pa; g.translate(PH.x + PH.w / 2, PH.y + PH.h / 2); g.scale(psc, psc); g.translate(-PH.w / 2, -PH.h / 2);
    g.shadowColor = 'rgba(4,18,43,.55)'; g.shadowBlur = 30; g.shadowOffsetY = 12; g.fillStyle = '#000'; rr(g, 0, 0, PH.w, PH.h, PH.r); g.fill();
    g.shadowColor = 'transparent'; g.shadowBlur = 0; g.shadowOffsetY = 0;
    rr(g, 0, 0, PH.w, PH.h, PH.r); g.save(); g.clip();
    g.drawImage(cvp, 0, 0, PH.w, PH.h);
    // balayage de lumière haut -> bas en 1,1 s
    var sp = clamp((lt - .45) / 1.1, 0, 1), by = lerp(-70, PH.h + 70, eio(sp)), bh = 120;
    if (sp > 0 && sp < 1) {
      g.globalCompositeOperation = 'lighter';
      var bg = g.createLinearGradient(0, by - bh, 0, by + 10);
      bg.addColorStop(0, 'rgba(111,195,255,0)'); bg.addColorStop(.7, 'rgba(143,208,255,.20)'); bg.addColorStop(1, 'rgba(191,230,255,.42)');
      g.fillStyle = bg; g.fillRect(0, by - bh, PH.w, bh + 10);
      var bg2 = g.createLinearGradient(0, by + 10, 0, by + 34); bg2.addColorStop(0, 'rgba(111,195,255,.14)'); bg2.addColorStop(1, 'rgba(111,195,255,0)');
      g.fillStyle = bg2; g.fillRect(0, by + 10, PH.w, 24);
      g.globalCompositeOperation = 'source-over';
      g.save(); g.shadowColor = C.halo; g.shadowBlur = 16; g.strokeStyle = 'rgba(244,251,255,.95)'; g.lineWidth = 2; g.lineCap = 'round';
      g.beginPath(); g.moveTo(14, by + 10); g.lineTo(PH.w - 14, by + 10); g.stroke(); g.restore();
    }
    // zone déjà lue : léger voile bleu
    if (lt > .45) { var rd = clamp(by + 10, 0, PH.h) * (sp >= 1 ? 1 : 1); g.fillStyle = rgba(C.marine, .1 * (1 - sstep(1.6, 2.4, lt))); g.fillRect(0, 0, PH.w, sp >= 1 ? PH.h : Math.max(0, by + 10)); }
    g.fillStyle = rgba(C.nuit, dim); g.fillRect(0, 0, PH.w, PH.h);
    g.restore();
    g.strokeStyle = 'rgba(255,255,255,.16)'; g.lineWidth = 1; rr(g, .5, .5, PH.w - 1, PH.h - 1, PH.r); g.stroke();
    // cadre de visée qui se resserre
    var bk = lt < 1.6 ? lerp(1.22, 1.14, sstep(.2, 1.5, lt)) : lerp(1.14, 1, clamp(spring(lt - 1.6, .55, 15), 0, 1.2));
    g.strokeStyle = rgba(C.lune, .95); g.lineWidth = 3; g.lineCap = 'round'; g.lineJoin = 'round';
    g.globalAlpha = pa * sstep(.25, .6, lt);
    bracket(g, PH.w / 2, PH.h / 2 + 6, 150, 95, 22, bk);
    g.restore();
    // candidats qui montent comme des bulles
    var cands = [['brochet', 'Brochet', 82], ['perche', 'Perche', 195], ['sandre', 'Sandre', 308]];
    var dd = 94;
    cands.forEach(function (c, i) {
      var t0 = 1.75 + i * .12, tau = lt - t0; if (tau < 0) return;
      var y = lerp(960, 690, clamp(spring(tau, .62, 10.5), 0, 1.25));
      var wob = 15 * Math.sin(TAU * 1.25 * tau + i * 1.7) * Math.exp(-2.4 * tau);
      var sc = lerp(.55, 1, clamp(spring(tau, .6, 11), 0, 1.15)), x = c[2] + wob;
      // petites bulles derrière
      for (var b = 0; b < 7; b++) {
        var te = t0 + b * .055, ab = lt - te - .06; if (ab < 0 || ab > .6) continue;
        var tb = te - t0, yb = lerp(960, 690, clamp(spring(tb, .62, 10.5), 0, 1.25)) + dd / 2 + 6, xb = c[2] + 15 * Math.sin(TAU * 1.25 * tb + i * 1.7) * Math.exp(-2.4 * tb) + (rnd(i * 9 + b) - .5) * 52;
        var ub = ab / .6, rb = (1.6 + rnd(b + i * 3) * 2.4);
        g.strokeStyle = rgba(C.lune, .7 * (1 - ub) * out); g.fillStyle = rgba(C.lune, .15 * (1 - ub) * out); g.lineWidth = 1.2;
        g.beginPath(); g.arc(xb, yb - ab * 26, rb, 0, TAU); g.fill(); g.stroke();
      }
      g.save(); g.globalAlpha = clamp(tau * 9, 0, 1) * out; g.translate(x, y); g.scale(sc, sc);
      var mid = i === 1;
      if (mid) { var hh = g.createRadialGradient(0, 0, dd / 2, 0, 0, dd / 2 + 26); hh.addColorStop(0, rgba(C.halo, .35)); hh.addColorStop(1, rgba(C.halo, 0)); g.fillStyle = hh; g.beginPath(); g.arc(0, 0, dd / 2 + 26, 0, TAU); g.fill(); }
      g.shadowColor = 'rgba(2,10,25,.5)'; g.shadowBlur = 16; g.shadowOffsetY = 6;
      g.fillStyle = C.tuile; g.beginPath(); g.arc(0, 0, dd / 2, 0, TAU); g.fill();
      g.shadowColor = 'transparent'; g.shadowBlur = 0; g.shadowOffsetY = 0;
      g.save(); g.beginPath(); g.arc(0, 0, dd / 2, 0, TAU); g.clip();
      var rg2 = g.createRadialGradient(-10, -16, 4, 0, 0, dd / 2); rg2.addColorStop(0, '#FFFFFF'); rg2.addColorStop(1, C.tuile); g.fillStyle = rg2; g.fillRect(-dd / 2, -dd / 2, dd, dd);
      var im = img(c[0]); if (im.complete && im.naturalWidth) { var iw = dd * .84, ih = iw * im.naturalHeight / im.naturalWidth; g.drawImage(im, -iw / 2, -ih / 2 - 1, iw, ih); }
      g.restore();
      g.strokeStyle = mid ? C.lune : 'rgba(191,230,255,.75)'; g.lineWidth = mid ? 3.4 : 2; g.beginPath(); g.arc(0, 0, dd / 2, 0, TAU); g.stroke();
      // reflet de bulle
      g.strokeStyle = 'rgba(255,255,255,.7)'; g.lineWidth = 2.4; g.lineCap = 'round'; g.beginPath(); g.arc(0, 0, dd / 2 - 6, PI * 1.12, PI * 1.38); g.stroke();
      g.restore();
      g.save(); g.globalAlpha = sstep(.25, .55, tau) * out; txt(g, c[1], c[2] + wob * .0, 690 + dd / 2 + 26, 15, mid ? '#FFFFFF' : 'rgba(244,251,255,.82)', 'center', 800); g.restore();
    });
    // « Autre » discret
    g.save(); g.globalAlpha = sstep(2.5, 3, lt) * out * .9;
    g.fillStyle = 'rgba(244,251,255,.1)'; rr(g, 195 - 60, 806, 120, 34, 17); g.fill();
    g.strokeStyle = 'rgba(191,230,255,.4)'; g.lineWidth = 1; rr(g, 195 - 60 + .5, 806.5, 119, 33, 16.5); g.stroke();
    txt(g, 'Autre poisson', 195, 828, 14, 'rgba(244,251,255,.9)', 'center', 800);
    g.restore();
    g.restore();
  }

  /* ======================= enregistrement ======================= */
  function push(a, wrap) {
    FM.anims.push({
      id: a.id, groupe: a.groupe, lettre: a.lettre, nom: a.nom, resume: a.resume, ou: a.ou, duree: a.duree,
      swiftui: a.swiftui, format: a.format, fond: a.fond,
      monter: function (el, ctx) { return wrap(el, ctx); }
    });
  }
  function phone(draw, staticT) {
    return function (el, ctx) {
      return stage(el, ctx, { staticT: staticT, draw: function (g, t, W, H, api) { draw(g, t, W, H, api, Math.min(window.devicePixelRatio || 1, 2)); } });
    };
  }

  push({
    id: 'attente-bouchon', groupe: 'attente', lettre: 'A', nom: 'Bouchon qui flotte',
    resume: 'Un bouchon de pêche orange et marine flotte sur l’eau : il plonge de 6 points, et deux ondes s’élargissent en s’éteignant à chaque plongée.',
    ou: 'Chargement court : ouverture d’un spot, de la fiche d’une espèce, du Pescedex.',
    duree: 'boucle 1,4 s', format: 'tuile', fond: 'clair',
    swiftui: 'Un Canvas dans un TimelineView(.animation) : le bouchon est dessiné avec des Path (corps coupé en trois bandes avec clipShape), sa hauteur suit 3 × (1 − cos) pour un va-et-vient doux de 6 pt, avec rotationEffect de 4 degrés. Les deux ondes sont des ellipses dont le rayon grandit et l’opacité baisse à chaque creux. Avec Réduire les animations : le bouchon reste immobile sur l’eau et respire d’un léger fondu d’opacité, sans onde.'
  }, function (el, ctx) { return tuile(el, ctx, 'Chargement du spot', drawBouchon, 1.9); });

  push({
    id: 'attente-poisson-tourne', groupe: 'attente', lettre: 'B', nom: 'Poisson qui tourne',
    resume: 'Un petit poisson marine nage en rond comme un indicateur d’activité, le corps qui ondule, et laisse derrière lui un sillage de petites bulles.',
    ou: 'Chargement court générique : synchronisation des amis, envoi d’une prise.',
    duree: 'boucle 1,5 s', format: 'tuile', fond: 'clair',
    swiftui: 'TimelineView + Canvas : le poisson est le Path du logo, tourné le long d’un cercle de 19 pt avec rotationEffect ; l’ondulation vient de trois tronçons du corps qui pivotent d’un angle en sinus. Le sillage est une courte trace en arc qui s’efface plus quelques cercles qui montent et disparaissent. Avec Réduire les animations : le poisson est posé sur son cercle et pulse d’un fondu lent.'
  }, function (el, ctx) { return tuile(el, ctx, 'Synchronisation', drawPoissonTourne, 1.1); });

  push({
    id: 'attente-bulles', groupe: 'attente', lettre: 'C', nom: 'Bulles qui montent',
    resume: 'Cinq bulles partent d’un point au fond, oscillent en montant, grossissent, puis éclatent en surface avec un petit anneau et quelques gouttes.',
    ou: 'Attente courte sur un fond d’eau : recherche d’espèces, calcul de la rareté.',
    duree: 'boucle 2,1 s', format: 'tuile', fond: 'clair',
    swiftui: 'Cinq cercles dans un Canvas piloté par TimelineView : chaque bulle a sa phase, monte en accélérant un peu (u = 0,5 q + 0,5 q²), oscille avec un sinus dont l’amplitude grandit, et son rayon augmente. Au sommet, un anneau (stroke) s’élargit en s’éteignant, avec trois gouttes en parabole. Avec Réduire les animations : les bulles restent figées à mi-hauteur et l’ensemble pulse très doucement.'
  }, function (el, ctx) { return tuile(el, ctx, 'Recherche des espèces', drawBulles, 1.0); });

  push({
    id: 'attente-moulinet', groupe: 'attente', lettre: 'D', nom: 'Moulinet',
    resume: 'Un moulinet vu de profil : la bobine tourne, le fil s’enroule, et un leurre en forme de poisson sort de l’eau pour monter vers le scion de la canne.',
    ou: 'Attente un peu plus longue : chargement des relevés OFB, premier lancement.',
    duree: 'boucle 3 s', format: 'tuile', fond: 'clair',
    swiftui: 'TimelineView + Canvas : la canne et le moulinet sont des Path ; la bobine se tourne avec rotationEffect proportionnel à la progression du leurre, l’épaisseur du fil enroulé grandit. Le leurre suit une courbe easeInOut le long d’un fil droit et une ondulation de corps ; au passage de la surface, une onde et trois gouttes. Avec Réduire les animations : le moulinet est fixe, le leurre à mi-course, avec un fondu doux.'
  }, function (el, ctx) { return tuile(el, ctx, 'Chargement des relevés', drawMoulinet, 1.35, { capDy: 66 }); });

  push({
    id: 'carte-sonar', groupe: 'carte', lettre: 'A', nom: 'Sonar',
    resume: 'Un faisceau de sonar marine tourne autour de ta position ; chaque station OFB qu’il croise fait un petit écho et apparaît, puis des poissons se posent sur trois stations.',
    ou: 'Carte : première ouverture d’un département, relevés OFB en cours de chargement.',
    duree: 'boucle 8 s', format: 'telephone', fond: 'clair',
    swiftui: 'Un Canvas dans un TimelineView(.animation) sur la carte : le faisceau est un AngularGradient (marine à 12 %) tourné avec rotationEffect. Quand l’angle passe sur une station, un cercle s’agrandit en 0,3 s en s’éteignant, et le point apparaît avec .spring(response: 0.35, dampingFraction: 0.5). Les poissons arrivent avec le même ressort. Avec Réduire les animations : toutes les stations et poissons sont affichés, le faisceau est supprimé, un léger fondu suffit.'
  }, phone(drawSonar, 6.3));

  push({
    id: 'carte-riviere', groupe: 'carte', lettre: 'B', nom: 'La rivière se dessine',
    resume: 'La rivière se trace de la source à l’embouchure pendant qu’un petit poisson nage à la pointe ; les stations rebondissent juste derrière lui.',
    ou: 'Carte : chargement du tracé des rivières et des stations du département.',
    duree: 'boucle 7 s', format: 'telephone', fond: 'clair',
    swiftui: 'Le tracé de rivière est un Path ; on anime trim(from: 0, to:) de 0 à 1 avec .easeInOut(duration: 3.9). Le poisson suit la pointe grâce à Path.trimmedPath et un point calculé sur la courbe, orienté par la tangente. Chaque station apparaît avec scaleEffect et .spring(response: 0.35, dampingFraction: 0.45) quand trim dépasse sa position. Avec Réduire les animations : la rivière et les stations s’affichent d’un coup en fondu.'
  }, phone(drawRiviere, 5.4));

  push({
    id: 'carte-squelette-eau', groupe: 'carte', lettre: 'C', nom: 'Squelette d’eau',
    resume: 'La carte et la fiche du bas sont des formes pâles ; une lumière d’eau, comme le soleil sous la surface, les traverse, puis le vrai contenu apparaît en fondu.',
    ou: 'Carte : toute la page avant l’arrivée des données du spot.',
    duree: 'boucle 6,4 s', format: 'telephone', fond: 'clair',
    swiftui: '.redacted(reason: .placeholder) sur la carte et la feuille du bas, puis un .layerEffect avec un shader Metal de caustiques (réseau de lumière en ondes qui glisse en diagonale, blanc dans les crêtes et bleu eau dans les creux) appliqué seulement aux formes masquées. À l’arrivée des données, transition .opacity en 0,6 s. Avec Réduire les animations : placeholders fixes avec un très léger fondu, sans lumière qui passe.'
  }, phone(drawSquelette, 0.1));

  push({
    id: 'reco-lecture-photo', groupe: 'reconnaissance', lettre: 'A', nom: 'Lecture de la photo',
    resume: 'Une bande de lumière douce balaie la photo du poisson de haut en bas, le cadre de visée se resserre, puis trois espèces candidates montent du bas comme des bulles.',
    ou: 'Après la prise de photo : analyse du poisson avant de choisir l’espèce.',
    duree: '3 s puis les choix', format: 'telephone', fond: 'nuit',
    swiftui: 'La photo est une Image dans un clipShape arrondi ; un Rectangle en dégradé, blendMode(.plusLighter), descend avec .offset animé 1,1 s en easeInOut. Le cadre de visée utilise un Path avec scaleEffect et un ressort. Les trois miniatures rondes montent avec PhaseAnimator et un .spring décalé de 0,12 s, plus un petit retour haptique .sensoryFeedback(.impact) et le son de bulles. Avec Réduire les animations : la photo, le cadre et les trois choix sont affichés d’un coup, sans balayage.'
  }, function (el, ctx) {
    recSoundCycle = -1;
    var h = stage(el, ctx, { staticT: 3.4, draw: function (g, t, W, H, api) { drawLecture(g, t, W, H, api, Math.min(window.devicePixelRatio || 1, 2)); }, reset: function () { recSoundCycle = -1; } });
    // la photo dépend de l'image : repeindre quand elle est prête
    var im = img('perche'); if (!im.complete) im.addEventListener('load', function () { photoCache = null; });
    return h;
  });
})();
