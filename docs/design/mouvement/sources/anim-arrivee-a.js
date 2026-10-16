/* FishMe en mouvement — arrivée A « La remontée »
   La carte remonte de l'eau comme un poisson qu'on ramène. Eau en canvas, carte en DOM + CSS 3D.
   Préfixe CSS : fmRA- */
(function () {
  'use strict';
  if (!window.FM || !window.FM.anims) return;

  var PX = 'fmRA-';
  var CARD_RATIO = 100 / 69;
  var SANS = 'ui-rounded, "SF Pro Rounded", "Nunito", system-ui, sans-serif';

  /* ------------------------------------------------------------------ données */
  var RAR = {
    'commun': {
      mot: 'Commun', col: '#6B7780', tint: '#A3AFB9', glow: '156,199,234', n: 1, shape: 'circle',
      fish: 'carpe-commune', nom: 'Carpe commune', lat: 'Cyprinus carpio', cen: 71, tai: 58, frq: 62,
      foot: '18 pêches sur 29 dans le 94 · OFB', num: '007', fw: 80, fy: 33.5, panel: '#EDF0EF',
      drops: 10, ripples: 2, backA: 0.10, rays: 0
    },
    'peu-commun': {
      mot: 'Peu commun', col: '#23885A', tint: '#4CC38F', glow: '110,220,180', n: 2, shape: 'hexagon',
      fish: 'brochet', nom: 'Brochet', lat: 'Esox lucius', cen: 84, tai: 68, frq: 34,
      foot: '10 pêches sur 29 dans le 94 · OFB', num: '014', fw: 88, fy: 32.5, panel: '#ECF1F0',
      drops: 16, ripples: 3, backA: 0.18, rays: 0
    },
    'rare': {
      mot: 'Rare', col: '#5B4FD0', tint: '#9C93F4', glow: '140,150,255', n: 3, shape: 'diamond',
      fish: 'sandre', nom: 'Sandre', lat: 'Sander lucioperca', cen: 91, tai: 71, frq: 10,
      foot: '3 pêches sur 29 dans le 94 · OFB', num: '021', fw: 86, fy: 34, panel: '#EDF1F3',
      drops: 26, ripples: 4, backA: 0.26, rays: 0.7
    },
    'legendaire': {
      mot: 'Légendaire', col: '#B07A12', tint: '#E6B64C', glow: '240,196,90', n: 4, shape: 'star',
      fish: 'truite-fario', nom: 'Truite fario', lat: 'Salmo trutta', cen: 97, tai: 49, frq: 0,
      foot: 'Jamais relevée dans le 94 · OFB', num: '003', fw: 84, fy: 34, panel: '#F7F1E1',
      drops: 40, ripples: 5, backA: 0.34, rays: 1
    }
  };

  /* temps (ms) : A = la carte perce la surface, rise = durée de la remontée, flipS/flipD = retournement,
     settle = début de l'écran final */
  var TL = {
    'commun':     { A: 300,  rise: 650,  flipS: 700,  flipD: 420, settle: 1050, total: 1600 },
    'peu-commun': { A: 400,  rise: 700,  flipS: 850,  flipD: 520, settle: 1450, total: 2200 },
    'rare':       { A: 700,  rise: 800,  flipS: 1650, flipD: 600, settle: 2250, total: 3000 },
    'legendaire': { A: 1000, rise: 1000, flipS: 2700, flipD: 700, settle: 3550, total: 4500 }
  };

  /* ------------------------------------------------------------------ outils */
  function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }
  function lerp(a, b, k) { return a + (b - a) * k; }
  function smooth(x) { x = clamp(x, 0, 1); return x * x * (3 - 2 * x); }
  function easeOut(x) { x = clamp(x, 0, 1); return 1 - Math.pow(1 - x, 3); }
  function easeInOut(x) { x = clamp(x, 0, 1); return x < .5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2; }
  function spring(p, z, w0) {
    if (p <= 0) return 0;
    if (p >= 1) return 1;
    var wd = w0 * Math.sqrt(1 - z * z), e = Math.exp(-z * w0 * p);
    return 1 - e * (Math.cos(wd * p) + (z * w0 / wd) * Math.sin(wd * p));
  }
  function rng(seed) {
    var a = seed >>> 0;
    return function () {
      a |= 0; a = a + 0x6D2B79F5 | 0;
      var t = Math.imul(a ^ a >>> 15, 1 | a);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }
  function ell(c, x, y, rx, ry) {
    c.beginPath();
    if (c.ellipse) c.ellipse(x, y, Math.max(.01, rx), Math.max(.01, ry), 0, 0, Math.PI * 2);
    else c.arc(x, y, Math.max(.01, rx), 0, Math.PI * 2);
  }

  /* ------------------------------------------------------------------ badges */
  function badgeSVG(shape, fill, size, stroke) {
    var d;
    if (shape === 'circle') d = '<circle cx="12" cy="12" r="8.2"/>';
    else if (shape === 'hexagon') d = '<polygon points="12,2.6 20.2,7.3 20.2,16.7 12,21.4 3.8,16.7 3.8,7.3"/>';
    else if (shape === 'diamond') d = '<polygon points="12,1.8 22,12 12,22.2 2,12"/>';
    else {
      var pts = [];
      for (var i = 0; i < 10; i++) {
        var a = -Math.PI / 2 + i * Math.PI / 5, r = i % 2 ? 4.9 : 10.6;
        pts.push((12 + Math.cos(a) * r).toFixed(2) + ',' + (12.6 + Math.sin(a) * r).toFixed(2));
      }
      d = '<polygon points="' + pts.join(' ') + '" stroke-linejoin="round" stroke="' + fill + '" stroke-width="1.2"/>';
    }
    return '<svg viewBox="0 0 24 24" width="' + size + '" height="' + size + '" fill="' + fill + '"' +
      (stroke ? ' stroke="' + stroke + '" stroke-width="1"' : '') + ' aria-hidden="true">' + d + '</svg>';
  }

  /* ------------------------------------------------------------------ CSS */
  var CSS = [
    '.fmRA-root{position:absolute;inset:0;overflow:hidden;container-type:size;font-family:' + SANS + ';font-weight:700;color:#fff;',
    '-webkit-user-select:none;user-select:none;touch-action:pan-y;-webkit-tap-highlight-color:transparent;cursor:default}',
    '.fmRA-root *{box-sizing:border-box}',
    '.fmRA-cv{position:absolute;left:0;top:0;width:100%;height:100%;pointer-events:none}',
    '.fmRA-card{position:absolute;left:0;top:0;container-type:inline-size;will-change:transform,opacity;opacity:0;pointer-events:none}',
    '.fmRA-sh{position:absolute;inset:0;border-radius:6cqw;box-shadow:0 7cqw 11cqw rgba(2,10,24,.55),0 1.4cqw 3cqw rgba(2,10,24,.4)}',
    '.fmRA-flip{position:absolute;inset:0;transform-style:preserve-3d;will-change:transform}',
    '.fmRA-face{position:absolute;inset:0;border-radius:6cqw;overflow:hidden;-webkit-backface-visibility:hidden;backface-visibility:hidden;',
    'font-size:5cqw;line-height:1;isolation:isolate;transform:translateZ(0.1px)}',
    '.fmRA-back{transform:rotateY(180deg) translateZ(0.1px)}',
    /* illustration */
    '.fmRA-art{position:absolute;left:0;right:0;top:0;height:66%;overflow:hidden}',
    '.fmRA-bg{position:absolute;inset:0}',
    '.fmRA-fx{position:absolute;inset:0;pointer-events:none}',
    '.fmRA-bd{position:absolute;left:2.4cqw;right:2.4cqw;top:2.4cqw;bottom:-6cqw;border-radius:4cqw;border:1px solid rgba(255,255,255,.2)}',
    '.fmRA-bd2{position:absolute;left:1.1cqw;right:1.1cqw;top:1.1cqw;bottom:-6cqw;border-radius:5.2cqw;border:1px solid rgba(255,255,255,.12)}',
    '.fmRA-fw{position:absolute;transform:translateY(-50%)}',
    '.fmRA-fw img{display:block;width:100%;height:auto;filter:drop-shadow(0 .7em .55em rgba(0,0,0,.34));will-change:transform}',
    '.fmRA-cen{position:absolute;left:5.6%;top:4.3%}',
    '.fmRA-cen b{display:block;font-size:3em;font-weight:800;letter-spacing:-.045em;line-height:.9;text-shadow:0 .04em .35em rgba(0,0,0,.25)}',
    '.fmRA-cen b i{font-style:normal;font-size:.42em;letter-spacing:0;margin-left:.05em;vertical-align:baseline}',
    '.fmRA-cen span{display:inline-block;margin-top:.55em;font-size:.72em;font-weight:700;color:rgba(255,255,255,.88);letter-spacing:.005em}',
    '.fmRA-chip span{background:rgba(255,255,255,.2);padding:.32em .62em;border-radius:.45em;margin-left:-.1em}',
    /* panneau */
    '.fmRA-pan{position:absolute;left:0;right:0;bottom:0;height:40.5%;clip-path:polygon(0 0,100% 7.4%,100% 100%,0 100%)}',
    '.fmRA-pt{position:absolute;color:#0E1A26;white-space:nowrap}',
    '.fmRA-nm{left:5.6%;top:63.9%;display:flex;align-items:baseline;gap:.55em}',
    '.fmRA-nm b{font-weight:800;letter-spacing:-.025em}',
    '.fmRA-nm i{font-size:.74em;font-weight:600;font-style:italic;color:#566576}',
    '.fmRA-hr{left:5.6%;right:5.6%;top:73.4%;height:1px;background:rgba(14,26,38,.13)}',
    '.fmRA-st{top:76.2%}',
    '.fmRA-st b{display:block;font-size:1.5em;font-weight:800;letter-spacing:-.02em;line-height:1}',
    '.fmRA-st b em{font-style:normal;font-size:.56em;font-weight:700;color:#566576;margin-left:.2em;letter-spacing:0}',
    '.fmRA-st small{display:block;margin-top:.55em;font-size:.62em;font-weight:800;letter-spacing:.09em;color:#566576;text-transform:uppercase}',
    '.fmRA-sr{left:60%;width:36%;text-align:center}',
    '.fmRA-sr .fmRA-bg1{display:block;height:1.5em;margin:0 auto}',
    '.fmRA-sr .fmRA-bg1 svg{display:block;margin:0 auto}',
    '.fmRA-sr small{margin-top:.55em}',
    '.fmRA-ft{left:5.6%;top:93.2%;font-size:.66em;font-weight:600;color:#566576;line-height:1}',
    '.fmRA-no{right:5.6%;top:92.9%;font-size:.72em;font-weight:800;font-family:ui-monospace,"SF Mono",Menlo,Consolas,monospace;line-height:1;letter-spacing:.02em}',
    /* hologramme */
    '.fmRA-hl{position:absolute;inset:0;pointer-events:none;mix-blend-mode:overlay;opacity:0;',
    '-webkit-mask-image:linear-gradient(180deg,#000 58%,rgba(0,0,0,.35) 68%,rgba(0,0,0,.2));mask-image:linear-gradient(180deg,#000 58%,rgba(0,0,0,.35) 68%,rgba(0,0,0,.2));',
    'background-size:280% 280%;background-position:calc(var(--hx,.5)*100%) calc(var(--hy,.5)*100%)}',
    '.fmRA-hl.fmRA-hr1{background-image:linear-gradient(112deg,rgba(255,255,255,0) 22%,rgba(110,200,255,.85) 35%,rgba(170,140,255,.9) 44%,rgba(255,150,215,.8) 51%,rgba(255,225,150,.75) 58%,rgba(120,255,215,.55) 66%,rgba(255,255,255,0) 78%)}',
    '.fmRA-hl.fmRA-hr2{background-image:linear-gradient(112deg,rgba(255,255,255,0) 22%,rgba(255,236,170,.95) 36%,rgba(255,180,90,.85) 44%,rgba(255,255,255,.9) 51%,rgba(255,205,130,.85) 58%,rgba(255,120,150,.5) 66%,rgba(255,255,255,0) 78%)}',
    '.fmRA-ln{position:absolute;inset:0;pointer-events:none;opacity:0;mix-blend-mode:overlay;',
    'background-image:repeating-linear-gradient(118deg,rgba(255,255,255,.55) 0 1px,rgba(255,255,255,0) 1px 6px);',
    'background-size:100% 100%;background-position:calc(var(--hx,.5)*40px) 0;',
    '-webkit-mask-image:linear-gradient(112deg,transparent 15%,#000 45%,#000 55%,transparent 85%);mask-image:linear-gradient(112deg,transparent 15%,#000 45%,#000 55%,transparent 85%)}',
    '.fmRA-gl{position:absolute;inset:0;pointer-events:none;opacity:0;mix-blend-mode:screen;',
    '-webkit-mask-image:linear-gradient(180deg,#000 58%,rgba(0,0,0,.3) 68%,rgba(0,0,0,.18));mask-image:linear-gradient(180deg,#000 58%,rgba(0,0,0,.3) 68%,rgba(0,0,0,.18));',
    'background:radial-gradient(circle at calc(var(--hx,.5)*100%) calc(var(--hy,.5)*100%),rgba(255,255,255,.55),rgba(255,255,255,.16) 24%,rgba(255,255,255,0) 52%)}',
    /* dos de carte */
    '.fmRA-back svg{position:absolute;inset:0;width:100%;height:100%;display:block}',
    /* décors animés */
    '.fmRA-bub{position:absolute;border-radius:50%;border:1px solid rgba(255,255,255,.55);background:radial-gradient(circle at 32% 30%,rgba(255,255,255,.5),rgba(255,255,255,.04) 55%);',
    'animation:fmRA-bub 9s linear infinite}',
    '@keyframes fmRA-bub{0%{transform:translate(0,3em) scale(.8);opacity:0}12%{opacity:.8}50%{transform:translate(.7em,-4em) scale(1)}88%{opacity:.7}100%{transform:translate(-.4em,-9em) scale(1.12);opacity:0}}',
    '.fmRA-mote{position:absolute;border-radius:50%;background:radial-gradient(circle,rgba(255,244,205,.82),rgba(255,236,170,0) 68%);animation:fmRA-mote 8s ease-in-out infinite}',
    '@keyframes fmRA-mote{0%,100%{transform:translate(0,0) scale(1);opacity:.55}50%{transform:translate(.9em,-1.6em) scale(1.18);opacity:1}}',
    /* UI de fin */
    '.fmRA-ui{position:absolute;left:0;right:0;top:0;bottom:0;pointer-events:none}',
    '.fmRA-rw{position:absolute;left:0;right:0;display:flex;align-items:center;justify-content:center;gap:2.6cqw;opacity:0}',
    '.fmRA-rw .fmRA-bdg{display:block;width:11cqw;height:11cqw;will-change:transform}',
    '.fmRA-rw .fmRA-bdg svg{display:block;width:100%;height:100%}',
    '.fmRA-wd{font-size:8.7cqw;font-weight:800;letter-spacing:-.015em;line-height:1;will-change:transform}',
    '.fmRA-dots{position:absolute;left:0;right:0;display:flex;justify-content:center;gap:2.6cqw}',
    '.fmRA-dots i{display:block;width:3.1cqw;height:3.1cqw;border-radius:50%;opacity:0;will-change:transform}',
    '.fmRA-btn{position:absolute;left:4.1cqw;right:4.1cqw;bottom:4.2cqh;height:13.8cqw;border:0;border-radius:99px;background:#0D4A85;',
    'box-shadow:inset 0 0 0 1px rgba(156,199,234,.32),inset 0 1px 0 rgba(255,255,255,.14),0 2cqw 5cqw rgba(2,10,24,.5);',
    'color:#fff;font:800 4.5cqw ' + SANS + ';letter-spacing:.005em;opacity:0;pointer-events:auto;cursor:pointer;transition:filter .15s}',
    '.fmRA-btn:active{filter:brightness(1.12)}',
    '.fmRA-rm *{animation:none!important}'
  ].join('');

  var cssRefs = 0, cssEl = null;
  function cssGet() {
    if (!cssEl) {
      cssEl = document.createElement('style');
      cssEl.setAttribute('data-fmra', '1');
      cssEl.textContent = CSS;
      document.head.appendChild(cssEl);
    }
    cssRefs++;
  }
  function cssRelease() {
    if (--cssRefs <= 0 && cssEl) { cssEl.remove(); cssEl = null; cssRefs = 0; }
  }

  /* ------------------------------------------------------------------ la carte (réutilisable) */
  function backgroundFor(k) {
    if (k === 'commun') {
      return { bg: 'radial-gradient(130% 95% at 28% 14%,#84938D 0%,#63726D 42%,#46544F 78%,#38443F 100%)',
        extra: '<div class="' + PX + 'fx" style="background:linear-gradient(118deg,rgba(255,255,255,0) 38%,rgba(255,255,255,.07) 50%,rgba(255,255,255,0) 62%)"></div>' };
    }
    if (k === 'peu-commun') {
      return { bg: 'linear-gradient(162deg,#1D6C6A 0%,#10504F 48%,#0B3640 100%)',
        extra: '<div class="' + PX + 'fx" style="background:repeating-radial-gradient(circle at 70% 43%,rgba(255,255,255,.085) 0 .07em,rgba(255,255,255,0) .07em 1.2em);' +
          '-webkit-mask-image:radial-gradient(circle at 70% 43%,#000 6%,rgba(0,0,0,.55) 40%,transparent 82%);mask-image:radial-gradient(circle at 70% 43%,#000 6%,rgba(0,0,0,.55) 40%,transparent 82%)"></div>' +
          '<div class="' + PX + 'fx" style="background:linear-gradient(116deg,rgba(255,255,255,0) 40%,rgba(255,255,255,.07) 50%,rgba(255,255,255,0) 60%)"></div>' };
    }
    if (k === 'rare') {
      var b = '', r = rng(41);
      var spec = [[12, 62, .55], [22, 28, .35], [31, 74, .7], [47, 18, .45], [58, 54, .3], [66, 82, .5], [79, 36, .4], [88, 70, .6], [40, 88, .38], [90, 14, .3], [8, 40, .3], [72, 8, .35]];
      for (var i = 0; i < spec.length; i++) {
        var s = spec[i];
        b += '<span class="' + PX + 'bub" style="left:' + s[0] + '%;top:' + s[1] + '%;width:' + s[2] + 'em;height:' + s[2] + 'em;animation-delay:-' + (r() * 9).toFixed(2) + 's;animation-duration:' + (7 + r() * 5).toFixed(1) + 's"></span>';
      }
      return { bg: 'linear-gradient(180deg,#58AAD8 0%,#2478B6 26%,#145A9C 58%,#0D3F7C 100%)',
        extra: '<div class="' + PX + 'fx" style="background:repeating-linear-gradient(118deg,rgba(255,255,255,.06) 0 1px,rgba(255,255,255,0) 1px 7px)"></div>' +
          '<div class="' + PX + 'fx" style="background:radial-gradient(70% 55% at 50% 0%,rgba(255,255,255,.22),rgba(255,255,255,0) 70%)"></div>' + b };
    }
    var m = '', q = rng(77);
    var ms = [[78, 18, 2.6], [14, 40, 1.7], [60, 52, 3.2], [88, 46, 1.4], [30, 10, 1.2], [46, 30, 2.1], [8, 12, 2.4], [70, 34, 1.1], [24, 52, 1.5], [92, 24, 2]];
    for (var j = 0; j < ms.length; j++) {
      var t = ms[j];
      m += '<span class="' + PX + 'mote" style="left:' + t[0] + '%;top:' + t[1] + '%;width:' + t[2] + 'em;height:' + t[2] + 'em;animation-delay:-' + (q() * 8).toFixed(2) + 's;animation-duration:' + (6 + q() * 5).toFixed(1) + 's"></span>';
    }
    return { bg: 'radial-gradient(95% 75% at 28% 12%,#F2D077 0%,#D9A735 30%,#B07A12 62%,#7A5107 100%)',
      extra: '<div class="' + PX + 'fx" style="background:linear-gradient(118deg,rgba(255,250,225,0) 36%,rgba(255,250,225,.18) 50%,rgba(255,250,225,0) 64%)"></div>' + m };
  }

  function buildCard(k) {
    var d = RAR[k], A = window.FMAssets || {};
    var fishSrc = (A.poissons && A.poissons[d.fish]) || '';
    var bgf = backgroundFor(k);
    var holo = k === 'rare' || k === 'legendaire';
    var holoCls = k === 'rare' ? 'fmRA-hr1' : 'fmRA-hr2';
    var fwLeft = (100 - d.fw) / 2 + (k === 'peu-commun' ? 1 : 0);

    var front = '' +
      '<div class="' + PX + 'art">' +
        '<div class="' + PX + 'bg" style="background:' + bgf.bg + '"></div>' + bgf.extra +
        '<div class="' + PX + 'bd"></div>' + (holo ? '<div class="' + PX + 'bd2" style="border-color:rgba(255,255,255,.3)"></div>' : '') +
      '</div>' +
      '<div class="' + PX + 'fw" style="left:' + fwLeft + '%;width:' + d.fw + '%;top:' + d.fy + '%"><img class="' + PX + 'fish" alt="" src="' + fishSrc + '"></div>' +
      '<div class="' + PX + 'cen' + (holo ? ' ' + PX + 'chip' : '') + '"><b>' + d.cen + '<i>e</i></b><span>CEN · centile de taille</span></div>' +
      '<div class="' + PX + 'pan" style="background:' + d.panel + '"></div>' +
      '<div class="' + PX + 'pt ' + PX + 'nm"><b style="font-size:' + (d.nom.length <= 8 ? 1.9 : d.nom.length <= 12 ? 1.72 : 1.5) + 'em">' + d.nom + '</b><i>' + d.lat + '</i></div>' +
      '<div class="' + PX + 'pt ' + PX + 'hr"></div>' +
      '<div class="' + PX + 'pt ' + PX + 'st" style="left:5.6%"><b>' + d.tai + '<em>cm</em></b><small>TAI</small></div>' +
      '<div class="' + PX + 'pt ' + PX + 'st" style="left:35%"><b>' + d.frq + '<em>%</em></b><small>FRQ</small></div>' +
      '<div class="' + PX + 'pt ' + PX + 'st ' + PX + 'sr"><span class="' + PX + 'bg1">' + badgeSVG(d.shape, d.col, 22) + '</span><small>' + d.mot + '</small></div>' +
      '<div class="' + PX + 'pt ' + PX + 'ft">' + d.foot + '</div>' +
      '<div class="' + PX + 'pt ' + PX + 'no">n° ' + d.num + '</div>' +
      (holo ? '<div class="' + PX + 'hl ' + holoCls + '"></div><div class="' + PX + 'ln"></div><div class="' + PX + 'gl"></div>' : '');

    var path = A.poissonPath || '';
    var backBg = {
      'commun': 'radial-gradient(120% 90% at 50% 30%,#6C7B76,#41504B 75%)',
      'peu-commun': 'radial-gradient(120% 90% at 50% 30%,#1B6664,#0A3640 80%)',
      'rare': 'radial-gradient(120% 90% at 50% 30%,#2C7CBC,#0C3A74 80%)',
      'legendaire': 'radial-gradient(120% 90% at 50% 30%,#E0B042,#8A5C0A 82%)'
    }[k];
    var rings = '';
    for (var r = 12; r <= 76; r += 8) rings += '<circle cx="50" cy="72.5" r="' + r + '" fill="none" stroke="#fff" stroke-opacity="' + (0.13 - r * 0.0011).toFixed(3) + '" stroke-width=".35"/>';
    var back = '<svg viewBox="0 0 100 144.9" preserveAspectRatio="none" aria-hidden="true">' +
      '<defs><linearGradient id="fmRA-g-' + k + '" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".95"/><stop offset="1" stop-color="#C7DFF3" stop-opacity=".8"/></linearGradient></defs>' +
      rings +
      '<rect x="3.2" y="3.2" width="93.6" height="138.5" rx="4.4" fill="none" stroke="#fff" stroke-opacity=".34" stroke-width=".4"/>' +
      '<rect x="5.4" y="5.4" width="89.2" height="134.1" rx="3.4" fill="none" stroke="#fff" stroke-opacity=".16" stroke-width=".3"/>' +
      '<circle cx="50" cy="72.5" r="21" fill="#fff" fill-opacity=".09" stroke="#fff" stroke-opacity=".5" stroke-width=".5"/>' +
      '<circle cx="50" cy="72.5" r="17.6" fill="none" stroke="#fff" stroke-opacity=".2" stroke-width=".3"/>' +
      '<g transform="translate(50 72.5) scale(.3) translate(-50 -50)"><path d="' + path + '" fill="url(#fmRA-g-' + k + ')"/></g>' +
      '<text x="50" y="108" text-anchor="middle" font-family="' + SANS.replace(/"/g, '') + '" font-size="5.2" font-weight="800" letter-spacing="1.4" fill="#fff" fill-opacity=".72">FISHME</text>' +
      '</svg>';

    var root = document.createElement('div');
    root.className = PX + 'card';
    root.innerHTML = '<div class="' + PX + 'sh"></div><div class="' + PX + 'flip">' +
      '<div class="' + PX + 'face ' + PX + 'front">' + front + '</div>' +
      '<div class="' + PX + 'face ' + PX + 'back" style="background:' + backBg + '">' + back + '</div></div>';
    return {
      root: root,
      flip: root.querySelector('.' + PX + 'flip'),
      sh: root.querySelector('.' + PX + 'sh'),
      fish: root.querySelector('.' + PX + 'fish'),
      hl: root.querySelector('.' + PX + 'hl'),
      ln: root.querySelector('.' + PX + 'ln'),
      gl: root.querySelector('.' + PX + 'gl'),
      holo: holo
    };
  }

  /* ------------------------------------------------------------------ sprites */
  function glowSprite(rgb) {
    var c = document.createElement('canvas'); c.width = c.height = 64;
    var x = c.getContext('2d'), g = x.createRadialGradient(32, 32, 0, 32, 32, 32);
    g.addColorStop(0, 'rgba(' + rgb + ',1)'); g.addColorStop(.25, 'rgba(' + rgb + ',.55)'); g.addColorStop(1, 'rgba(' + rgb + ',0)');
    x.fillStyle = g; x.fillRect(0, 0, 64, 64);
    return c;
  }

  /* ------------------------------------------------------------------ animation */
  var anim = {
    id: 'arrivee-remontee',
    groupe: 'arrivee',
    lettre: 'A',
    nom: 'La remontée',
    resume: 'La carte remonte de l’eau comme un poisson qu’on ramène : l’eau s’assombrit, une lumière monte, la surface éclate, la carte se retourne.',
    ou: 'Écran de révélation de la carte, juste après avoir confirmé l’espèce d’une prise.',
    duree: '1,6 s (commun) jusqu’à 4,5 s (légendaire)',
    swiftui: 'Une KeyframeAnimator pilote trois pistes : échelle (0,9 puis 1,04 puis 1), décalage vertical en ressort, et rotation3DEffect autour de Y avec perspective, face cachée d’abord. L’eau, les gouttes et les ondes se dessinent dans un Canvas lu par une TimelineView ; le reflet holographique des cartes rares et légendaires est un shader .layerEffect nourri par CoreMotion (inclinaison de l’iPhone). Chaque temps fort a son retour : sensoryFeedback .impact léger à la percée, puis .success à la face. Un toucher saute à la carte finale. Avec Réduire les animations : fondu de 0,4 s vers la carte posée, halo fixe, aucune particule.',
    format: 'telephone',
    fond: 'nuit',
    options: [{ cle: 'rarete', valeurs: ['commun', 'peu-commun', 'rare', 'legendaire'] }],
    carte: function (rarete) { return buildCard(RAR[rarete] ? rarete : 'rare').root; },
    monter: monter
  };
  window.FM.anims.push(anim);

  function monter(el, ctx) {
    ctx = ctx || {};
    var k = (ctx.option && RAR[ctx.option.rarete]) ? ctx.option.rarete : 'rare';
    var D = RAR[k], tl = TL[k];
    var reduit = !!ctx.reduit;
    var son = typeof ctx.son === 'function' ? ctx.son : function () {};
    cssGet();

    var root = document.createElement('div');
    root.className = PX + 'root' + (reduit ? ' ' + PX + 'rm' : '');
    var cvB = document.createElement('canvas'); cvB.className = PX + 'cv';
    var cvF = document.createElement('canvas'); cvF.className = PX + 'cv';
    var card = buildCard(k);
    var ui = document.createElement('div'); ui.className = PX + 'ui';
    var dotsHtml = '';
    for (var di = 0; di < 4; di++) dotsHtml += '<i style="background:' + (di < D.n ? D.tint : 'rgba(255,255,255,.2)') + '"></i>';
    ui.innerHTML = '<div class="' + PX + 'rw"><span class="' + PX + 'bdg">' + badgeSVG(D.shape, D.tint, 44) + '</span><span class="' + PX + 'wd" style="color:' + D.tint + '">' + D.mot + '</span></div>' +
      '<div class="' + PX + 'dots">' + dotsHtml + '</div>' +
      '<button type="button" class="' + PX + 'btn">Ranger dans le Pescedex</button>';
    root.appendChild(cvB); root.appendChild(card.root); root.appendChild(cvF); root.appendChild(ui);
    el.appendChild(root);
    var rw = ui.querySelector('.' + PX + 'rw'), bdg = ui.querySelector('.' + PX + 'bdg'), wd = ui.querySelector('.' + PX + 'wd');
    var dotsEl = ui.querySelector('.' + PX + 'dots'), dots = dotsEl.querySelectorAll('i'), btn = ui.querySelector('.' + PX + 'btn');
    var bctx = cvB.getContext('2d'), fctx = cvF.getContext('2d');
    var raySprite = (function () {
      var n = 256, cv = document.createElement('canvas'); cv.width = cv.height = n; var x = cv.getContext('2d');
      if (x.createConicGradient) {
        var g = x.createConicGradient(0, n / 2, n / 2), N = 7, stops = 84;
        for (var i = 0; i <= stops; i++) {
          var u = i / stops, v = Math.pow(Math.max(0, Math.sin(u * N * Math.PI * 2 + 0.6) * 0.5 + 0.5), 3.2) * (0.7 + 0.3 * Math.sin(u * 19));
          g.addColorStop(u, 'rgba(' + D.glow + ',' + (0.28 * v).toFixed(3) + ')');
        }
        x.fillStyle = g; x.fillRect(0, 0, n, n);
        x.globalCompositeOperation = 'destination-in';
        var rg = x.createRadialGradient(n / 2, n / 2, n * 0.07, n / 2, n / 2, n / 2);
        rg.addColorStop(0, 'rgba(0,0,0,1)'); rg.addColorStop(.55, 'rgba(0,0,0,.45)'); rg.addColorStop(1, 'rgba(0,0,0,0)');
        x.fillStyle = rg; x.fillRect(0, 0, n, n);
      }
      return cv;
    })();
    var spriteGlow = glowSprite(D.glow), spriteGold = glowSprite('246,217,139'), spriteWhite = glowSprite('244,251,255');

    /* géométrie */
    var W = 0, H = 0, S = 1, dpr = 1, Cw = 0, Ch = 0, cx = 0, yFinal = 0, ySurf0 = 0;
    function layout() {
      W = root.clientWidth; H = root.clientHeight;
      if (!W || !H) return false;
      S = W / 390; dpr = Math.min(window.devicePixelRatio || 1, 2);
      [cvB, cvF].forEach(function (c) { c.width = Math.round(W * dpr); c.height = Math.round(H * dpr); });
      Cw = Math.min(W * 0.78, H * 0.52 / CARD_RATIO); Ch = Cw * CARD_RATIO;
      cx = W / 2; yFinal = H * 0.395; ySurf0 = H * 0.62;
      card.root.style.width = Cw + 'px'; card.root.style.height = Ch + 'px';
      card.root.style.perspective = Math.round(Cw * 2.7) + 'px';
      var top = yFinal + Ch / 2 + H * 0.045;
      rw.style.top = top + 'px'; rw.style.height = (H * 0.06) + 'px';
      dotsEl.style.top = (top + H * 0.075) + 'px';
      dirty = true;
      return true;
    }

    /* paramètres déterministes (unités : px à 390 de large) */
    var drops = [], motes = [], ripples = [], bobRip = [];
    (function gen() {
      var r = rng(k.length * 131 + 7), i, goldShare = k === 'legendaire' ? 0.42 : 0;
      for (i = 0; i < D.drops; i++) {
        var sg = r() < .5 ? -1 : 1, u = sg * (r() < 0.78 ? 0.55 + r() * 0.5 : r() * 0.5);
        var big = r() < 0.18;
        drops.push({
          ox: u * 0.5, // fraction de la largeur de la carte
          vx: u * (90 + r() * 200) + (r() - .5) * 40,
          vy: -(300 + r() * (k === 'legendaire' ? 760 : k === 'rare' ? 620 : 520)) * (big ? 1.05 : 1),
          r: (big ? 2.6 : 1.1) + r() * (big ? 1.6 : 1.5),
          delay: r() * 70,
          gold: r() < goldShare,
          w: r()
        });
      }
      for (i = 0; i < D.ripples; i++) ripples.push({ d: 70 + i * 135, k: 0.38 + i * 0.13, dur: 1250 + i * 160, a: 0.62 - i * 0.07 });
      if (k === 'legendaire') {
        bobRip.push({ d: 430, k: 0.1, dur: 900, a: .5 }, { d: 790, k: 0.2, dur: 1100, a: .65 }, { d: 880, k: 0.3, dur: 1300, a: .5 });
        for (i = 0; i < 38; i++) motes.push({
          x: (r() - .5) * 1.1, y: (r() - .15) * 0.5, sp: 30 + r() * 70, sw: 5 + r() * 13, sf: 1.4 + r() * 2,
          ph: r() * 6.28, sz: 1.3 + r() * 2.6, d: r() * 700, life: 1200 + r() * 700, white: r() < 0.3
        });
      }
    })();

    /* état */
    var t0 = 0, nowT = 0, lastNow = 0, paused = false, seekT = 0;
    var stopped = false, visible = true, raf = 0, dirty = true, running = false;
    var fired = {}, lastT = -1;
    var tiltX = 0, tiltY = 0, hx = 0.5, hy = 0.5;
    var ptr = { on: false, x: 0, y: 0, last: -1e9, down: false, sx: 0, sy: 0, moved: false };
    var skippedAt = -1;

    var events = [];
    if (k === 'rare') events.push({ t: 20, id: 'montee' });
    if (k === 'legendaire') { events.push({ t: 150, id: 'montee' }); events.push({ t: tl.A + 90, id: 'plouf' }); }
    events.push({ t: tl.flipS, id: 'retournement' });
    events.push({ t: tl.flipS + tl.flipD * 0.86, id: 'carte-' + k });
    var tShock = tl.flipS + tl.flipD * 0.86;
    var firedLog = [];

    /* ---------- fonctions de scène */
    function surf(t) {
      var dp = easeInOut((t - (tl.A + 100)) / (tl.rise * 1.05));
      var wa = 1 - smooth((t - (tl.A + tl.rise * 0.5)) / 750);
      return { y: ySurf0 + dp * H * 0.36, wa: wa };
    }
    function waveOff(x, t, ys) {
      var o = 3.2 * S * (Math.sin(x * 0.017 + t * 0.0016) + 0.55 * Math.sin(x * 0.043 - t * 0.0023 + 1.3) + 0.3 * Math.sin(x * 0.091 + t * 0.003));
      var dx = Math.abs(x - cx);
      for (var i = 0; i < ripples.length && i < 3; i++) {
        var age = t - tl.A - ripples[i].d;
        if (age > 0 && age < 2200) {
          var front = age / 1000 * 0.46 * W, env = Math.exp(-age / 640), q = (dx - front) / (36 * S);
          o += 6.5 * S * env * Math.exp(-q * q) * Math.cos((dx - front) / (11 * S));
        }
      }
      for (var j = 0; j < bobRip.length && j < 3; j++) {
        var ag = t - bobRip[j].d;
        if (ag > 0 && ag < 1400) {
          var fr = ag / 1000 * 0.2 * W, ev = Math.exp(-ag / 500), qq = (dx - fr) / (22 * S);
          o += 2.6 * S * ev * Math.exp(-qq * qq) * Math.cos((dx - fr) / (8 * S));
        }
      }
      return o;
    }
    var pts = [];
    function buildWave(t, ys) {
      pts.length = 0;
      var step = Math.max(5, W / 78), x;
      for (x = -step; x <= W + step; x += step) pts.push(x, ys + waveOff(x, t, ys));
    }
    function waterPath(c, bottom) {
      c.beginPath(); c.moveTo(pts[0], pts[1]);
      for (var i = 2; i < pts.length; i += 2) c.lineTo(pts[i], pts[i + 1]);
      c.lineTo(W + 20, bottom); c.lineTo(-20, bottom); c.closePath();
    }

    /* intensité de la lumière sous l'eau */
    function glowI(t) {
      var A = tl.A;
      if (t < A) {
        if (k === 'commun') return 0.35 + 0.5 * smooth(t / A);
        if (k === 'peu-commun') return 0.35 + 0.65 * smooth(t / A);
        if (k === 'rare') {
          var q = t / A;
          return 0.4 + 0.55 * Math.pow(Math.sin(q * Math.PI * 2 - 0.3) * 0.5 + 0.5, 1.4) + 0.2 * q;
        }
        var ql = t / A; // légendaire : monte avec la tension
        return 0.4 + 0.7 * smooth(ql) + 0.18 * Math.sin(t * 0.012) * ql;
      }
      return Math.max(0, (k === 'commun' ? 1.1 : 1.5) * Math.exp(-(t - A) / 380));
    }
    function dimA(t) {
      if (k === 'rare') return 0.4 * smooth(t / 520) * (1 - smooth((t - tl.A) / 320));
      if (k === 'legendaire') return 0.52 * smooth(t / 700) * (1 - smooth((t - tl.A) / 380));
      return 0;
    }

    /* état de la carte à l'instant t */
    function cardAt(t) {
      var A = tl.A, p = (t - A) / tl.rise;
      var yTop0 = ySurf0 + H * 0.045;
      var y0 = yTop0 + Ch / 2;
      var pos = spring(p, 0.62, 7.4);
      var y = lerp(y0, yFinal, pos);
      var sc = 0.9 + 0.1 * spring(p, 0.3, 15.3);
      var fp = clamp((t - tl.flipS) / tl.flipD, 0, 1);
      var fe = spring(fp, 0.78, 5.9);
      var ang = 180 * (1 - fe);
      var lift = Math.sin(Math.PI * fp);
      sc += 0.055 * lift; y -= H * 0.012 * lift;
      var rz = 0, bob = 0;
      if ((k === 'rare' || k === 'legendaire') && t > A + tl.rise * 0.8 && t < tl.flipS) {
        var hold = smooth((t - (A + tl.rise * 0.8)) / (tl.flipS - A - tl.rise * 0.8));
        bob = Math.sin(t * 0.0042) * H * 0.0055;
        var shake = smooth((t - (tl.flipS - 480)) / 480);
        rz = Math.sin(t * 0.085) * shake * (k === 'legendaire' ? 1.1 : 0.7);
        ang += Math.sin(t * 0.06) * shake * 4;
        sc += 0.012 * hold;
      }
      return { x: cx, y: y + bob, sc: sc, ang: ang, rz: rz, op: smooth((t - A) / 130), fp: fp };
    }

    /* ---------- dessin du fond */
    function drawBack(t, ss, cs) {
      var c = bctx; c.setTransform(dpr, 0, 0, dpr, 0, 0); c.clearRect(0, 0, W, H);
      var gi = glowI(t), rgb = D.glow, yS = ss.y;
      if (ss.wa > 0.004) {
        c.save(); c.globalAlpha = ss.wa;
        var g = c.createLinearGradient(0, yS - H * 0.3, 0, yS + 4);
        g.addColorStop(0, 'rgba(13,74,133,0)'); g.addColorStop(1, 'rgba(13,74,133,.5)');
        c.fillStyle = g; c.fillRect(0, yS - H * 0.3, W, H * 0.3 + 4);
        waterPath(c, H + 10);
        g = c.createLinearGradient(0, yS, 0, Math.max(H, yS + 40));
        g.addColorStop(0, '#0B3D6B'); g.addColorStop(.3, '#082A4C'); g.addColorStop(1, '#04122B');
        c.fillStyle = g; c.fill();
        c.save(); waterPath(c, H + 10); c.clip();
        /* lueur sous l'eau */
        c.globalCompositeOperation = 'lighter';
        var cy = yS + H * 0.17, rr = W * 0.62;
        c.save(); c.translate(cx, cy); c.scale(1, 0.78);
        g = c.createRadialGradient(0, 0, 0, 0, 0, rr);
        g.addColorStop(0, 'rgba(' + rgb + ',' + (1.25 * gi).toFixed(3) + ')');
        g.addColorStop(.35, 'rgba(' + rgb + ',' + (0.5 * gi).toFixed(3) + ')');
        g.addColorStop(1, 'rgba(' + rgb + ',0)');
        c.fillStyle = g; c.fillRect(-rr, -rr, rr * 2, rr * 2); c.restore();
        /* faisceau de lumière qui monte vers la surface */
        for (var cn = 0; cn < 5; cn++) {
          var fk = 1 - cn * 0.19, cw0 = W * 0.045 * fk, cw1 = W * 0.27 * fk, yb = cy + H * 0.03;
          g = c.createLinearGradient(0, yS, 0, yb);
          g.addColorStop(0, 'rgba(' + rgb + ',' + (0.085 * gi).toFixed(3) + ')'); g.addColorStop(1, 'rgba(' + rgb + ',0)');
          c.fillStyle = g; c.beginPath(); c.moveTo(cx - cw1, yS); c.lineTo(cx + cw1, yS); c.lineTo(cx + cw0, yb); c.lineTo(cx - cw0, yb); c.closePath(); c.fill();
        }
        /* caustiques */
        c.lineWidth = 1.2 * S;
        for (var i = 0; i < 6; i++) {
          var dy = yS + (0.04 + i * 0.07) * H;
          c.strokeStyle = 'rgba(156,199,234,' + ((0.05 + 0.04 * gi) * (1 - i * 0.1)).toFixed(3) + ')';
          c.beginPath();
          for (var x = -10; x <= W + 10; x += 9) {
            var yy = dy + 4.5 * S * Math.sin(x * 0.021 + t * 0.0009 * (1 + i * 0.18) + i * 2.1) + 2 * S * Math.sin(x * 0.05 - t * 0.0013 + i);
            if (x === -10) c.moveTo(x, yy); else c.lineTo(x, yy);
          }
          c.stroke();
        }
        c.restore();
        /* halo sur la surface */
        c.globalCompositeOperation = 'lighter';
        c.save(); c.translate(cx, yS); c.scale(1, 0.12);
        g = c.createRadialGradient(0, 0, 0, 0, 0, W * 0.55);
        g.addColorStop(0, 'rgba(' + rgb + ',' + (0.62 * gi).toFixed(3) + ')'); g.addColorStop(1, 'rgba(' + rgb + ',0)');
        c.fillStyle = g; c.fillRect(-W, -W * 1.2, W * 2, W * 2.4); c.restore();
        c.restore();
      }
      /* l'écran s'assombrit (rare, légendaire) */
      var dm = dimA(t);
      if (dm > 0.003) { c.fillStyle = 'rgba(2,10,22,' + dm.toFixed(3) + ')'; c.fillRect(0, 0, W, H); }
      /* lumière derrière la carte */
      if (t >= tl.A) {
        var ba = D.backA * smooth((t - tl.A) / 500);
        if (k === 'legendaire') ba *= 1 + 0.22 * Math.sin(t * 0.006) * (t < tShock ? 1 : 0) + 0.8 * Math.exp(-Math.max(0, t - tShock) / 450) * (t >= tShock ? 1 : 0);
        c.save(); c.globalCompositeOperation = 'screen';
        var rb = W * (0.9 + (k === 'legendaire' ? 0.1 : 0));
        var gg = c.createRadialGradient(cs.x, cs.y, 0, cs.x, cs.y, rb);
        gg.addColorStop(0, 'rgba(' + rgb + ',' + (ba * 1.5).toFixed(3) + ')');
        gg.addColorStop(.45, 'rgba(' + rgb + ',' + (ba * 0.55).toFixed(3) + ')');
        gg.addColorStop(1, 'rgba(' + rgb + ',0)');
        c.fillStyle = gg; c.fillRect(cs.x - rb, cs.y - rb, rb * 2, rb * 2);
        /* rayons de rareté, doux (image pré-rendue, tournée lentement) */
        if (D.rays) {
          var ra = D.rays * smooth((t - (tl.A + tl.rise * 0.5)) / (k === 'legendaire' ? 1000 : 650));
          if (ra > 0.004) {
            var R = H * 0.78;
            c.save(); c.translate(cs.x, cs.y); c.rotate(t * 0.00006 + 0.2); c.globalAlpha = ra;
            c.drawImage(raySprite, -R, -R, R * 2, R * 2); c.restore();
          }
        }
        c.restore();
      }
    }

    /* ---------- dessin du premier plan */
    function drawFront(t, ss, cs) {
      var c = fctx; c.setTransform(dpr, 0, 0, dpr, 0, 0); c.clearRect(0, 0, W, H);
      var yS = ss.y, wa = ss.wa, A = tl.A, i, g;

      /* légendaire : fil tendu et bouchon (sous l'eau teintée) */
      if (k === 'legendaire' && t < A + 320) {
        var la = 1 - smooth((t - A) / 160);
        var slack = 1 - easeInOut((t - 150) / 480);
        var bx = cx, by = yS + waveOff(bx, t, yS) - 4 * S;
        var dunk = easeInOut((t - 660) / 330);
        var tw = t > 520 && t < 700 ? Math.sin((t - 520) * 0.12) * 2 * S : 0;
        by += dunk * 44 * S + tw * (1 - dunk);
        var xTop = cx + W * 0.2, yTop = -10 * S;
        var hookY = yS + H * 0.2 + dunk * H * 0.06;
        c.save(); c.globalAlpha = la;
        c.strokeStyle = 'rgba(244,251,255,.82)'; c.lineWidth = 1.25 * S; c.lineCap = 'round';
        c.beginPath(); c.moveTo(xTop, yTop);
        var mx = (xTop + bx) / 2, my = (yTop + by - 6 * S) / 2;
        var sway = Math.sin(t * 0.004) * 8 * S * slack;
        c.quadraticCurveTo(mx - 0.1 * W * slack + sway, my + H * 0.07 * slack, bx, by - 7 * S);
        c.stroke();
        c.beginPath(); c.moveTo(bx, by + 6 * S); c.lineTo(bx + 0.5 * S, hookY); c.stroke();
        /* bouchon */
        c.save(); ell(c, bx, by, 5.4 * S, 7.4 * S); c.clip();
        c.fillStyle = '#E8571C'; c.fillRect(bx - 8 * S, by - 9 * S, 16 * S, 9 * S);
        c.fillStyle = '#F4FBFF'; c.fillRect(bx - 8 * S, by, 16 * S, 9 * S);
        g = c.createLinearGradient(bx - 5 * S, 0, bx + 5 * S, 0);
        g.addColorStop(0, 'rgba(255,255,255,.35)'); g.addColorStop(.4, 'rgba(255,255,255,0)'); g.addColorStop(1, 'rgba(4,18,43,.28)');
        c.fillStyle = g; c.fillRect(bx - 8 * S, by - 9 * S, 16 * S, 18 * S);
        c.restore();
        c.fillStyle = '#E8571C'; c.fillRect(bx - 0.9 * S, by - 12.2 * S, 1.8 * S, 5 * S);
        c.restore();
      }

      /* voile d'eau sur la carte immergée */
      if (wa > 0.004) {
        c.save(); c.globalAlpha = wa;
        waterPath(c, H + 10);
        g = c.createLinearGradient(0, yS, 0, Math.max(H, yS + 40));
        g.addColorStop(0, 'rgba(11,61,107,.34)'); g.addColorStop(.35, 'rgba(8,42,76,.5)'); g.addColorStop(1, 'rgba(4,18,43,.66)');
        c.fillStyle = g; c.fill();
        /* ligne de surface */
        var gs = c.createLinearGradient(0, 0, W, 0);
        gs.addColorStop(0, 'rgba(199,223,243,.12)'); gs.addColorStop(.5, 'rgba(199,223,243,.78)'); gs.addColorStop(1, 'rgba(199,223,243,.12)');
        c.strokeStyle = gs; c.lineWidth = 1.5 * S; c.lineJoin = 'round';
        c.beginPath(); c.moveTo(pts[0], pts[1]);
        for (i = 2; i < pts.length; i += 2) c.lineTo(pts[i], pts[i + 1]);
        c.stroke();
        c.strokeStyle = 'rgba(244,251,255,.16)'; c.lineWidth = 1 * S; c.beginPath();
        for (i = 0; i < pts.length; i += 2) { if (i === 0) c.moveTo(pts[i], pts[i + 1] - 2.4 * S); else c.lineTo(pts[i], pts[i + 1] - 2.4 * S); }
        c.stroke();

        /* ondes concentriques : s'élargissent et s'atténuent */
        var all = [], rr;
        for (i = 0; i < ripples.length; i++) all.push([A + ripples[i].d, ripples[i], 1]);
        for (i = 0; i < bobRip.length; i++) all.push([bobRip[i].d, bobRip[i], 0.4]);
        for (i = 0; i < all.length; i++) {
          var rp = all[i][1], age = t - all[i][0];
          if (age <= 0 || age > rp.dur) continue;
          var q = age / rp.dur, rad = rp.k * W * (1 - Math.pow(1 - q, 2.3));
          var al = rp.a * Math.pow(1 - q, 1.7);
          var ryc = yS + H * 0.012;
          c.lineWidth = Math.max(0.6, (2.4 - 1.6 * q) * S);
          c.strokeStyle = (k === 'legendaire' && i % 2 === 0 ? 'rgba(246,217,139,' : 'rgba(199,223,243,') + al.toFixed(3) + ')';
          ell(c, cx, ryc, rad, rad * 0.2); c.stroke();
          if (rad > 14 * S) { c.lineWidth = 0.9 * S; c.strokeStyle = 'rgba(244,251,255,' + (al * 0.45).toFixed(3) + ')'; ell(c, cx, ryc, rad * 0.9, rad * 0.9 * 0.2); c.stroke(); }
        }
        /* éclat à la percée */
        var fl = t - (A + 40);
        if (fl > 0 && fl < 360) {
          var fa = Math.pow(1 - fl / 360, 2);
          c.save(); c.globalCompositeOperation = 'lighter'; c.translate(cx, yS); c.scale(1, 0.22);
          var fg = c.createRadialGradient(0, 0, 0, 0, 0, Cw * 0.8);
          fg.addColorStop(0, 'rgba(244,251,255,' + (0.7 * fa).toFixed(3) + ')'); fg.addColorStop(.5, 'rgba(' + D.glow + ',' + (0.25 * fa).toFixed(3) + ')'); fg.addColorStop(1, 'rgba(' + D.glow + ',0)');
          c.fillStyle = fg; c.fillRect(-Cw, -Cw, Cw * 2, Cw * 2); c.restore();
        }
        c.restore();
      }

      /* gouttes en paraboles */
      var tb = A + 60;
      if (t > tb) {
        var gy = 1900 * S, yL = ySurf0 + 3 * S;
        for (i = 0; i < drops.length; i++) {
          var dr = drops[i], tau = (t - tb - dr.delay) / 1000;
          if (tau <= 0) continue;
          var x0 = cx + dr.ox * Cw, y0 = ySurf0 - 2 * S;
          var vx = dr.vx * S, vy = dr.vy * S;
          var px = x0 + vx * tau, py = y0 + vy * tau + 0.5 * gy * tau * tau;
          if (py > yL && tau > 0.05) continue;
          var life = Math.abs(vy) * 2 / gy, fade = clamp(1 - (tau - life * 0.7) / (life * 0.45), 0, 1);
          var vyc = vy + gy * tau, sp = Math.sqrt(vx * vx + vyc * vyc) || 1;
          var tail = Math.min(0.016, 0.007 + dr.r * 0.0025);
          var rr2 = dr.r * S, col = dr.gold ? (dr.w < 0.5 ? '246,217,139' : '232,184,74') : (dr.w < 0.4 ? '244,251,255' : dr.w < 0.75 ? '199,223,243' : '156,199,234');
          c.lineCap = 'round';
          c.strokeStyle = 'rgba(' + col + ',' + (0.28 * fade).toFixed(3) + ')'; c.lineWidth = rr2 * 1.1;
          c.beginPath(); c.moveTo(px, py); c.lineTo(px - vx * tail * 2.4, py - vyc * tail * 2.4); c.stroke();
          c.strokeStyle = 'rgba(' + col + ',' + (0.95 * fade).toFixed(3) + ')'; c.lineWidth = rr2 * 1.9;
          c.beginPath(); c.moveTo(px, py); c.lineTo(px - vx * tail, py - vyc * tail); c.stroke();
          if (rr2 > 2.2 * S) {
            c.fillStyle = 'rgba(255,255,255,' + (0.8 * fade).toFixed(3) + ')';
            ell(c, px - rr2 * 0.25, py - rr2 * 0.3, rr2 * 0.32, rr2 * 0.32); c.fill();
          }
        }
      }

      /* légendaire : onde de choc dorée + particules qui montent */
      if (k === 'legendaire' && t >= tShock) {
        var ts = t - tShock;
        if (ts < 900) {
          for (var s = 0; s < 2; s++) {
            var q2 = (ts - s * 110) / (s ? 760 : 820);
            if (q2 <= 0 || q2 >= 1) continue;
            var e = 1 - Math.pow(1 - q2, 3), rad2 = Cw * (0.5 + e * 1.15), a2 = Math.pow(1 - q2, 1.5);
            c.lineWidth = Math.max(0.8, (s ? 2.2 : 7) * (1 - q2) * S);
            c.strokeStyle = s ? 'rgba(255,248,225,' + (0.65 * a2).toFixed(3) + ')' : 'rgba(240,196,90,' + (0.85 * a2).toFixed(3) + ')';
            ell(c, cs.x, cs.y, rad2, rad2 * 1.0); c.stroke();
          }
        }
        for (i = 0; i < motes.length; i++) {
          var m = motes[i], age2 = ts - m.d;
          if (age2 <= 0 || age2 > m.life) continue;
          var qm = age2 / m.life;
          var mx2 = cs.x + m.x * Cw + Math.sin(age2 * 0.001 * m.sf + m.ph) * m.sw * S;
          var my2 = cs.y + m.y * Ch - m.sp * S * (age2 / 1000) - qm * qm * 30 * S;
          var ma = Math.pow(Math.sin(Math.PI * qm), 0.9) * 0.9, sz = m.sz * S * 5;
          c.globalAlpha = ma;
          c.drawImage(m.white ? spriteWhite : (i % 3 ? spriteGold : spriteGlow), mx2 - sz / 2, my2 - sz / 2, sz, sz);
        }
        c.globalAlpha = 1;
      }
    }

    /* ---------- interface de fin */
    function drawUI(t) {
      var s0 = tl.settle;
      var a = smooth((t - s0) / 360);
      var pop = spring((t - s0) / 600, 0.55, 8.2);
      rw.style.opacity = a;
      wd.style.transform = 'translateY(' + ((1 - pop) * 14 * S) + 'px) scale(' + (0.86 + 0.14 * pop) + ')';
      var pb = spring((t - s0 - 40) / 560, 0.42, 10.5);
      bdg.style.transform = 'scale(' + (0.3 + 0.7 * pb) + ') rotate(' + ((1 - pb) * -50) + 'deg)';
      for (var i = 0; i < dots.length; i++) {
        var pd = spring((t - s0 - 220 - i * 95) / 460, 0.5, 9.2);
        dots[i].style.opacity = clamp(pd * 3, 0, 1);
        dots[i].style.transform = 'scale(' + (0.2 + 0.8 * pd) + ')';
      }
      var bt = easeOut((t - s0 - 200) / 480);
      btn.style.opacity = bt;
      btn.style.transform = 'translateY(' + ((1 - bt) * 14 * S) + 'px)';
    }

    /* ---------- une image */
    function targetPose(now, t) {
      var live = ptr.on && (ptr.down || now - ptr.last < 1800);
      var tx, ty, h1, h2, amp = k === 'rare' || k === 'legendaire' ? 1 : 0.6;
      if (live) {
        var nx = clamp((ptr.x - cx) / (Cw * 0.62), -1, 1), ny = clamp((ptr.y - yFinal) / (Ch * 0.62), -1, 1);
        ty = nx * 10 * amp; tx = -ny * 10 * amp; h1 = 0.5 + nx * 0.5; h2 = 0.5 + ny * 0.5;
      } else {
        h1 = 0.5 + 0.38 * Math.sin(now / 1150); h2 = 0.5 + 0.3 * Math.sin(now / 1570 + 1.2);
        ty = (h1 - 0.5) * 2 * 5 * amp; tx = -(h2 - 0.5) * 2 * 4 * amp;
      }
      return { tx: tx, ty: ty, h1: h1, h2: h2 };
    }

    function update(t, now, dt) {
      var ss = surf(t), cs = cardAt(t);
      /* sons : seulement vers l'avant */
      if (lastT >= 0) {
        for (var e = 0; e < events.length; e++) {
          var ev = events[e];
          if (!fired[e] && t >= ev.t) { fired[e] = 1; if (lastT < ev.t || skippedAt < 0) { firedLog.push(ev.id); son(ev.id); } }
        }
      }
      lastT = t;
      /* pose 3D + hologramme + nage */
      var pose = targetPose(now, t), kk = 1 - Math.exp(-dt / 120);
      var wTilt = smooth((t - (tl.flipS + tl.flipD * 0.6)) / 400);
      tiltX = lerp(tiltX, pose.tx * wTilt, kk); tiltY = lerp(tiltY, pose.ty * wTilt, kk);
      hx = lerp(hx, pose.h1, kk); hy = lerp(hy, pose.h2, kk);
      var cr = card.root, sc = cs.sc;
      cr.style.opacity = cs.op;
      cr.style.transform = 'translate3d(' + (cs.x - Cw / 2).toFixed(2) + 'px,' + (cs.y - Ch / 2).toFixed(2) + 'px,0) scale(' + sc.toFixed(4) + ')';
      card.flip.style.transform = 'rotateX(' + tiltX.toFixed(2) + 'deg) rotateY(' + (cs.ang + tiltY).toFixed(2) + 'deg) rotateZ(' + cs.rz.toFixed(2) + 'deg)';
      card.sh.style.transform = 'scaleX(' + Math.max(0.12, Math.abs(Math.cos((cs.ang + tiltY) * Math.PI / 180))).toFixed(3) + ')';
      card.sh.style.opacity = 0.35 + 0.65 * smooth((t - tl.A) / 500);
      if (card.holo) {
        var reveal = smooth((t - (tl.flipS + tl.flipD * 0.7)) / 450);
        card.root.style.setProperty('--hx', hx.toFixed(3)); card.root.style.setProperty('--hy', hy.toFixed(3));
        var shine = reveal * (k === 'legendaire' ? 1 : 0.85);
        card.hl.style.opacity = ((k === 'rare' ? 0.75 : 0.95) * shine).toFixed(3);
        card.ln.style.opacity = (0.5 * shine).toFixed(3);
        card.gl.style.opacity = (0.5 * shine).toFixed(3);
      }
      var swimA = smooth((t - (tl.flipS + tl.flipD * 0.8)) / 500), ts = now * 0.001;
      card.fish.style.transform = 'translate(' + (Math.sin(ts * 1.5) * 0.9 * swimA).toFixed(2) + '%,' + (Math.sin(ts * 2.1 + 1) * 1.4 * swimA).toFixed(2) + '%) rotate(' + (Math.sin(ts * 1.5 + 0.6) * 1.3 * swimA).toFixed(2) + 'deg)';
      drawUI(t);
      /* canvas */
      buildWave(t, ss.y);
      var needFront = t < tl.total + 2200;
      if (needFront || dirty) drawFront(t, ss, cs);
      drawBack(t, ss, cs);
      dirty = false;
    }

    /* ---------- état final fixe (Réduire les animations) */
    function drawStatic() {
      var ss = { y: H * 2, wa: 0 }, cs = { x: cx, y: yFinal, sc: 1, ang: 0, rz: 0, op: 1 };
      card.root.style.opacity = 1;
      card.root.style.transform = 'translate3d(' + (cx - Cw / 2) + 'px,' + (yFinal - Ch / 2) + 'px,0)';
      card.flip.style.transform = 'none';
      card.sh.style.transform = 'none'; card.sh.style.opacity = 1;
      if (card.holo) {
        card.root.style.setProperty('--hx', '.38'); card.root.style.setProperty('--hy', '.3');
        card.hl.style.opacity = '.55'; card.ln.style.opacity = '.3'; card.gl.style.opacity = '.35';
      }
      rw.style.opacity = 1; bdg.style.transform = 'none'; wd.style.transform = 'none';
      for (var i = 0; i < dots.length; i++) { dots[i].style.opacity = 1; dots[i].style.transform = 'none'; }
      btn.style.opacity = 1; btn.style.transform = 'none';
      var c = bctx; c.setTransform(dpr, 0, 0, dpr, 0, 0); c.clearRect(0, 0, W, H);
      var rb = W * 0.9, gg = c.createRadialGradient(cs.x, cs.y, 0, cs.x, cs.y, rb), a = D.backA;
      gg.addColorStop(0, 'rgba(' + D.glow + ',' + (a * 1.5).toFixed(3) + ')');
      gg.addColorStop(.45, 'rgba(' + D.glow + ',' + (a * 0.55).toFixed(3) + ')'); gg.addColorStop(1, 'rgba(' + D.glow + ',0)');
      c.fillStyle = gg; c.fillRect(0, 0, W, H);
      fctx.setTransform(dpr, 0, 0, dpr, 0, 0); fctx.clearRect(0, 0, W, H);
    }

    /* ---------- boucle */
    function frame(now) {
      raf = 0;
      if (stopped || !visible) { running = false; return; }
      var dt = clamp(now - (lastNow || now), 0, 50); lastNow = now;
      nowT = now;
      var t = paused ? seekT : now - t0;
      if (W) update(t, now, dt || 16);
      raf = requestAnimationFrame(frame);
    }
    function start() {
      if (stopped || running || reduit) return;
      running = true; lastNow = 0;
      raf = requestAnimationFrame(frame);
    }
    function halt() { if (raf) cancelAnimationFrame(raf); raf = 0; running = false; }

    function begin() {
      fired = {}; lastT = -1; skippedAt = -1; firedLog.length = 0; paused = false;
      tiltX = tiltY = 0; hx = hy = 0.5;
      if (reduit) {
        root.style.transition = 'none'; root.style.opacity = 0;
        void root.offsetWidth;
        root.style.transition = 'opacity .4s ease'; root.style.opacity = 1;
        if (W) drawStatic();
        son('carte-' + k);
        return;
      }
      t0 = performance.now();
      if (W) update(0, t0, 16);
      start();
    }

    /* ---------- événements */
    function skip() {
      if (reduit || stopped) return;
      var t = paused ? seekT : performance.now() - t0, target = tl.settle + 160;
      if (t >= target) return;
      skippedAt = t;
      for (var e = 0; e < events.length; e++) {
        if (!fired[e] && events[e].t < target) {
          fired[e] = 1;
          if (events[e].id === 'carte-' + k) { firedLog.push(events[e].id); son(events[e].id); }
        }
      }
      t0 = performance.now() - target;
    }
    function rel(ev) { var r = root.getBoundingClientRect(); var sx = r.width ? W / r.width : 1; return { x: (ev.clientX - r.left) * sx, y: (ev.clientY - r.top) * sx }; }
    function onDown(ev) {
      if (ev.target && ev.target.closest && ev.target.closest('.' + PX + 'btn')) return;
      var p = rel(ev); ptr.on = true; ptr.down = true; ptr.x = p.x; ptr.y = p.y; ptr.sx = p.x; ptr.sy = p.y; ptr.moved = false; ptr.last = performance.now();
    }
    function onMove(ev) {
      var p = rel(ev); ptr.on = true; ptr.x = p.x; ptr.y = p.y; ptr.last = performance.now();
      if (Math.abs(p.x - ptr.sx) + Math.abs(p.y - ptr.sy) > 14) ptr.moved = true;
    }
    function onUp(ev) {
      if (ptr.down && !ptr.moved) skip();
      ptr.down = false;
      if (ev && ev.pointerType && ev.pointerType !== 'mouse') ptr.last = performance.now() - 1200;
    }
    function onLeave() { ptr.down = false; ptr.last = performance.now() - 1200; }
    if (!reduit) {
      root.addEventListener('pointerdown', onDown);
      root.addEventListener('pointermove', onMove);
      root.addEventListener('pointerup', onUp);
      root.addEventListener('pointercancel', onLeave);
      root.addEventListener('pointerleave', onLeave);
    }
    btn.addEventListener('pointerdown', function (e) { e.stopPropagation(); });
    btn.addEventListener('pointerup', function (e) { e.stopPropagation(); });

    var ro = null, io = null;
    if (window.ResizeObserver) {
      ro = new ResizeObserver(function () { if (layout()) { if (reduit) drawStatic(); else if (!running) { update(paused ? seekT : Math.min(performance.now() - t0, 99999), performance.now(), 16); } } });
      ro.observe(root);
    }
    if (window.IntersectionObserver) {
      io = new IntersectionObserver(function (es) {
        var v = es[es.length - 1].isIntersecting;
        if (v === visible) return;
        visible = v;
        if (v) start(); else halt();
      }, { threshold: 0 });
      io.observe(root);
    }
    layout();
    begin();

    return {
      rejouer: function () { if (stopped) return; halt(); begin(); },
      arreter: function () {
        if (stopped) return;
        stopped = true; halt();
        if (ro) ro.disconnect(); if (io) io.disconnect();
        root.removeEventListener('pointerdown', onDown); root.removeEventListener('pointermove', onMove);
        root.removeEventListener('pointerup', onUp); root.removeEventListener('pointercancel', onLeave); root.removeEventListener('pointerleave', onLeave);
        if (root.parentNode) root.parentNode.removeChild(root);
        cssRelease();
      },
      /* pour les tests : fige la scène à t ms */
      _seek: function (ms) { halt(); paused = true; seekT = ms; if (!W) layout(); lastT = -1; fired = {}; for (var e = 0; e < events.length; e++) if (events[e].t <= ms) fired[e] = 1; update(ms, ms + 1000, 2000); return firedLog.slice(); }
    };
  }
})();
