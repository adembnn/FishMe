/* FishMe en mouvement — groupe « arrivee », variations B « Le dos de la carte » et C « Bulle ».
   Préfixe CSS : fmRB-. Aucune dépendance. Une scène = une pure fonction du temps (render(t)),
   ce qui rend le saut au état final (toucher) et la boucle d'inactivité exacts. */
(function () {
  'use strict';
  var FM = window.FM, ASSETS = window.FMAssets;
  if (!FM || !ASSETS) return;
  var P = 'fmRB-';
  var FONT = 'ui-rounded, "SF Pro Rounded", "Nunito", system-ui, sans-serif';
  var uidN = 0;

  /* ---------- utilitaires ---------- */
  function c01(x) { return x < 0 ? 0 : x > 1 ? 1 : x; }
  function lerp(a, b, u) { return a + (b - a) * u; }
  function prog(t, a, b) { return c01((t - a) / (b - a)); }
  function sstep(u) { u = c01(u); return u * u * (3 - 2 * u); }
  function eIO(u) { u = c01(u); return u < .5 ? 4 * u * u * u : 1 - Math.pow(-2 * u + 2, 3) / 2; }
  function eO3(u) { u = c01(u); return 1 - Math.pow(1 - u, 3); }
  function eO2(u) { u = c01(u); return 1 - (1 - u) * (1 - u); }
  function eI2(u) { u = c01(u); return u * u; }
  function mulberry(a) {
    return function () {
      a |= 0; a = a + 0x6D2B79F5 | 0;
      var t = Math.imul(a ^ a >>> 15, 1 | a);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }
  /* ressort sous-amorti de 0 vers 1 (u de 0 à 1) */
  function spring(u, z, w) {
    if (u <= 0) return 0;
    var s = Math.sqrt(1 - z * z), wd = w * s;
    return 1 - Math.exp(-z * w * u) * (Math.cos(wd * u) + (z / s) * Math.sin(wd * u));
  }
  function mk(tag, cls, html) {
    var e = document.createElement(tag);
    if (cls) e.className = cls.split(' ').map(function (c) { return P + c; }).join(' ');
    if (html != null) e.innerHTML = html;
    return e;
  }
  function rgba(rgb, a) { return 'rgba(' + rgb + ',' + a + ')'; }

  /* ---------- raretés ---------- */
  var RAR = {
    'commun': {
      mot: 'Commun', n: 1, shape: 'rond', col: '#6B7780', txt: '#B9C4CD', glow: '156,170,182', tint: '#DCEBF7', tintRgb: '220,235,247',
      esp: 'carpe-commune', fw: 80, nom: 'Carpe commune', lat: 'Cyprinus carpio', cen: '52', tai: '58', frq: '61', pech: 18, num: '007', D: 1600
    },
    'peu-commun': {
      mot: 'Peu commun', n: 2, shape: 'hexagone', col: '#23885A', txt: '#46CC8C', glow: '62,200,140', tint: '#A6F0CF', tintRgb: '166,240,207',
      esp: 'brochet', fw: 87, nom: 'Brochet', lat: 'Esox lucius', cen: '84', tai: '68', frq: '34', pech: 10, num: '014', D: 2200
    },
    'rare': {
      mot: 'Rare', n: 3, shape: 'losange', col: '#5B4FD0', txt: '#9B90FF', glow: '124,107,255', tint: '#C6BEFF', tintRgb: '198,190,255',
      esp: 'sandre', fw: 87, nom: 'Sandre', lat: 'Sander lucioperca', cen: '91', tai: '71', frq: '10', pech: 3, num: '021', D: 3000
    },
    'legendaire': {
      mot: 'Légendaire', n: 4, shape: 'etoile', col: '#B07A12', txt: '#EDB944', glow: '240,184,66', tint: '#FFE7A6', tintRgb: '255,231,166',
      esp: 'truite-fario', fw: 87, nom: 'Truite fario', lat: 'Salmo trutta fario', cen: '97', tai: '47', frq: '0', pech: 0, num: '003', D: 4500
    }
  };

  function badge(shape, col, size, extra) {
    var f = 'fill="' + col + '"', body;
    if (shape === 'rond') body = '<circle cx="12" cy="12" r="9" ' + f + '/>';
    else if (shape === 'hexagone') body = '<polygon points="12,2 20.7,7 20.7,17 12,22 3.3,17 3.3,7" ' + f + '/>';
    else if (shape === 'losange') body = '<polygon points="12,1.5 21.5,12 12,22.5 2.5,12" ' + f + '/>';
    else {
      var pts = [];
      for (var i = 0; i < 10; i++) {
        var r = i % 2 ? 5.1 : 11.6, a = -Math.PI / 2 + i * Math.PI / 5;
        pts.push((12 + Math.cos(a) * r).toFixed(2) + ',' + (12.6 + Math.sin(a) * r).toFixed(2));
      }
      body = '<polygon points="' + pts.join(' ') + '" ' + f + ' stroke-linejoin="round" stroke="' + col + '" stroke-width="1"/>';
    }
    return '<svg viewBox="0 0 24 24" width="' + size + '" height="' + size + '" style="display:block;' + (extra || '') + '">' + body + '</svg>';
  }

  /* ---------- CSS (une seule balise) ---------- */
  var CSS_DONE = false;
  function injectCSS() {
    if (CSS_DONE || document.getElementById('fmRB-style')) { CSS_DONE = true; return; }
    CSS_DONE = true;
    var f = FONT;
    var css = [
      '.fmRB-root{position:absolute;inset:0;overflow:hidden;font-family:' + f + ';color:#fff;-webkit-user-select:none;user-select:none;-webkit-tap-highlight-color:transparent;cursor:pointer}',
      '.fmRB-cv{position:absolute;left:0;top:0;width:100%;height:100%;pointer-events:none}',
      '.fmRB-stage{position:absolute;left:0;top:0;width:0;height:0}',
      '.fmRB-ground{position:absolute;border-radius:50%;background:radial-gradient(closest-side,rgba(2,9,22,.62),rgba(2,9,22,0));pointer-events:none}',
      '.fmRB-aura{position:absolute;pointer-events:none;border-radius:6em}',
      '.fmRB-lift{position:absolute;left:-50em;top:-72.465em;width:100em;height:144.93em;transform-style:preserve-3d}',
      '.fmRB-flip{position:absolute;inset:0;transform-style:preserve-3d}',
      '.fmRB-face{position:absolute;inset:0;border-radius:6em;overflow:hidden;-webkit-backface-visibility:hidden;backface-visibility:hidden;box-shadow:0 1.6em 4.2em rgba(2,9,22,.55),0 .25em .7em rgba(2,9,22,.4)}',
      '.fmRB-flipped{transform:rotateY(180deg)}',
      /* recto */
      '.fmRB-front{background:#E9EEEC}',
      '.fmRB-art{position:absolute;left:0;top:0;width:100%;height:63%;overflow:hidden}',
      '.fmRB-r-commun .fmRB-art{background:radial-gradient(120% 90% at 78% 30%,rgba(190,208,205,.22),rgba(190,208,205,0) 60%),linear-gradient(168deg,#76878A 0%,#586A6D 52%,#3F4F53 100%)}',
      '.fmRB-r-peu-commun .fmRB-art{background:linear-gradient(170deg,#216F6A 0%,#175552 50%,#0B3837 100%)}',
      '.fmRB-r-rare .fmRB-art{background:linear-gradient(178deg,#63B1DE 0%,#2F7DBC 28%,#16508A 62%,#0A2E62 100%)}',
      '.fmRB-r-legendaire .fmRB-art{background:radial-gradient(90% 70% at 74% 26%,#F3CC62 0%,#D6A22B 30%,#B07A12 62%,#6E4807 100%)}',
      '.fmRB-vig{position:absolute;inset:0;background:radial-gradient(130% 100% at 50% 45%,rgba(0,0,0,0) 55%,rgba(0,0,0,.28) 100%)}',
      '.fmRB-hatch{position:absolute;inset:0;background:repeating-linear-gradient(118deg,rgba(255,255,255,.045) 0 .22em,rgba(255,255,255,0) .22em 1.5em)}',
      '.fmRB-rings{position:absolute;left:0;top:0;width:100%;height:100%;transform-origin:72% 36%}',
      '.fmRB-bub{position:absolute;border-radius:50%;border:.22em solid rgba(255,255,255,.55);background:radial-gradient(circle at 32% 30%,rgba(255,255,255,.55),rgba(255,255,255,0) 45%)}',
      '.fmRB-mote{position:absolute;border-radius:50%;background:radial-gradient(closest-side,rgba(255,238,176,.95),rgba(255,226,140,.35) 55%,rgba(255,226,140,0))}',
      '.fmRB-fish{position:absolute;left:50%;top:52%;height:auto;filter:drop-shadow(0 1.1em 1.3em rgba(0,0,0,.42));pointer-events:none}',
      '.fmRB-cen{position:absolute;left:.3765em;top:.188em;font-weight:800;font-size:17em;line-height:1;letter-spacing:-.03em;text-shadow:0 .08em .5em rgba(0,0,0,.22);white-space:nowrap}',
      '.fmRB-cen i{font-style:normal;font-size:.38em;letter-spacing:0;margin-left:.06em;font-weight:800}',
      '.fmRB-cenl{position:absolute;left:2.339em;top:7.322em;font-size:2.95em;font-weight:700;opacity:.9;white-space:nowrap;text-shadow:0 .05em .3em rgba(0,0,0,.25)}',
      '.fmRB-panel{position:absolute;left:0;right:0;top:58%;bottom:0;background:linear-gradient(180deg,#F2F5F3,#E4E9E8);clip-path:polygon(0 0,100% 7%,100% 100%,0 100%);color:#0E1A26}',
      '.fmRB-nm{position:absolute;left:7em;top:7.6em;display:flex;align-items:baseline;gap:2.4em;white-space:nowrap}',
      '.fmRB-nm b{font-size:10em;font-weight:800;letter-spacing:-.02em;line-height:1}',
      '.fmRB-nm em{font-size:3.5em;font-weight:600;color:#566576;font-style:italic}',
      '.fmRB-rule{position:absolute;left:7em;right:7em;top:23.2em;height:.28em;background:#D3DBE0;border-radius:1em}',
      '.fmRB-st{position:absolute;top:26.3em;white-space:nowrap}',
      '.fmRB-st b{font-size:8.4em;font-weight:800;line-height:1;letter-spacing:-.01em}',
      '.fmRB-st b small{font-size:.42em;font-weight:700;margin-left:.35em;color:#2B3A48}',
      '.fmRB-st span{display:block;margin-top:1.3em;font-size:2.7em;font-weight:700;letter-spacing:.09em;color:#566576}',
      '.fmRB-foot{position:absolute;left:2.414em;bottom:1.862em;font-size:2.9em;font-weight:600;color:#566576;white-space:nowrap}',
      '.fmRB-num{position:absolute;right:2.258em;bottom:1.677em;font-size:3.1em;font-weight:800;color:#0E1A26;font-family:ui-monospace,"SF Mono",Menlo,Consolas,monospace;letter-spacing:.02em}',
      '.fmRB-frame{position:absolute;inset:1.7em;border-radius:4.4em;pointer-events:none;border:.24em solid rgba(255,255,255,.3)}',
      '.fmRB-frame2{position:absolute;inset:2.8em;border-radius:3.4em;pointer-events:none;border:.14em solid rgba(255,255,255,.22)}',
      '.fmRB-holo{position:absolute;inset:0;pointer-events:none;mix-blend-mode:screen;opacity:0}',
      '.fmRB-glare{position:absolute;inset:0;pointer-events:none;mix-blend-mode:soft-light;opacity:0}',
      '.fmRB-shine{position:absolute;inset:0;pointer-events:none;opacity:0;mix-blend-mode:soft-light}',
      '.fmRB-edge{position:absolute;inset:0;border-radius:6em;padding:1.15em;pointer-events:none;opacity:0;box-sizing:border-box;-webkit-mask:linear-gradient(#000 0 0) content-box,linear-gradient(#000 0 0);-webkit-mask-composite:xor;mask:linear-gradient(#000 0 0) content-box exclude,linear-gradient(#000 0 0)}',
      '.fmRB-shade{position:absolute;inset:0;background:#02091A;opacity:0;pointer-events:none}',
      /* dos */
      '.fmRB-back{background:transparent;overflow:visible}',
      '.fmRB-half{position:absolute;top:0;height:100%;width:50%;overflow:hidden}',
      '.fmRB-hl{left:0;border-radius:6em 0 0 6em}',
      '.fmRB-hr{left:50%;border-radius:0 6em 6em 0}',
      '.fmRB-bart{position:absolute;top:0;width:200%;height:100%;border-radius:6em;overflow:hidden;background:#0B3D6B}',
      '.fmRB-hl .fmRB-bart{left:0}',
      '.fmRB-hr .fmRB-bart{left:-100%}',
      '.fmRB-bglow{position:absolute;inset:0;border-radius:6em;pointer-events:none}',
      '.fmRB-seam{position:absolute;left:50%;top:0;height:100%;transform-origin:50% 50%;pointer-events:none;-webkit-mask-image:linear-gradient(transparent 2%,#000 22%,#000 78%,transparent 98%);mask-image:linear-gradient(transparent 2%,#000 22%,#000 78%,transparent 98%);filter:drop-shadow(0 0 1.1em rgba(255,255,255,.9))}',
      '.fmRB-spill{position:absolute;left:50%;top:0;height:100%;width:56em;margin-left:-28em;pointer-events:none;mix-blend-mode:screen;opacity:0;-webkit-mask-image:linear-gradient(transparent 0,#000 25%,#000 75%,transparent 100%);mask-image:linear-gradient(transparent 0,#000 25%,#000 75%,transparent 100%)}',
      '.fmRB-photo{position:absolute;overflow:hidden;pointer-events:none;background:#7E9AA0}',
      '.fmRB-flash{position:absolute;inset:0;pointer-events:none;opacity:0}',
      /* bulle */
      '.fmRB-bubble{position:absolute;left:0;top:0;pointer-events:none;will-change:transform}',
      '.fmRB-btint{position:absolute;inset:0;border-radius:50%}',
      '.fmRB-brim{position:absolute;inset:0;border-radius:50%;overflow:hidden;-webkit-mask:radial-gradient(closest-side,transparent calc(100% - 8px),#000 calc(100% - 3.6px),#000 calc(100% - .4px),transparent 100%);mask:radial-gradient(closest-side,transparent calc(100% - 8px),#000 calc(100% - 3.6px),#000 calc(100% - .4px),transparent 100%)}',
      '.fmRB-birid{position:absolute;left:-30%;top:-30%;width:160%;height:160%}',
      '.fmRB-bhl1{position:absolute;left:13%;top:7%;width:36%;height:21%;border-radius:50%;background:radial-gradient(ellipse at 42% 42%,rgba(255,255,255,.9),rgba(255,255,255,0) 70%);transform:rotate(-34deg);filter:blur(1.2px)}',
      '.fmRB-bhl2{position:absolute;left:63%;top:80%;width:20%;height:9%;border-radius:50%;background:radial-gradient(ellipse at 50% 50%,rgba(255,255,255,.4),rgba(255,255,255,0) 70%);transform:rotate(-38deg);filter:blur(1px)}',
      '.fmRB-bhl3{position:absolute;inset:5%;border-radius:50%;border:2px solid transparent;border-top-color:rgba(255,255,255,.28);border-left-color:rgba(255,255,255,.14);transform:rotate(-14deg);filter:blur(.8px)}',
      /* interface */
      '.fmRB-ui{position:absolute;inset:0;pointer-events:none}',
      '.fmRB-word{position:absolute;left:0;right:0;display:flex;align-items:center;justify-content:center;gap:12em;opacity:0;white-space:nowrap}',
      '.fmRB-word span{font-size:34em;font-weight:800;letter-spacing:-.01em;line-height:1}',
      '.fmRB-dots{position:absolute;left:0;right:0;display:flex;justify-content:center;gap:9em}',
      '.fmRB-dot{width:12em;height:12em;border-radius:50%;opacity:0}',
      '.fmRB-btnw{position:absolute;left:16em;right:16em;height:54em;pointer-events:none;opacity:0}',
      '.fmRB-btn{display:block;width:100%;height:100%;border-radius:999px;border:1px solid rgba(156,199,234,.3);background:#0D4A85;color:#fff;font:800 17em/1 ' + f + ';pointer-events:inherit;cursor:pointer;box-shadow:0 8em 22em rgba(2,9,22,.55),inset 0 1px 0 rgba(255,255,255,.14);padding:0}',
      '.fmRB-btn:active{filter:brightness(1.12)}'
    ].join('\n');
    var st = document.createElement('style');
    st.id = 'fmRB-style';
    st.textContent = css;
    document.head.appendChild(st);
  }

  /* ---------- sprites de lumière ---------- */
  var spriteCache = {};
  function sprite(rgb) {
    if (spriteCache[rgb]) return spriteCache[rgb];
    var c = document.createElement('canvas'); c.width = c.height = 64;
    var x = c.getContext('2d'), g = x.createRadialGradient(32, 32, 0, 32, 32, 32);
    g.addColorStop(0, 'rgba(' + rgb + ',1)'); g.addColorStop(.25, 'rgba(' + rgb + ',.55)'); g.addColorStop(1, 'rgba(' + rgb + ',0)');
    x.fillStyle = g; x.fillRect(0, 0, 64, 64);
    return spriteCache[rgb] = c;
  }

  /* ---------- le recto de la carte (fidèle à P24 A) ---------- */
  function makeFront(rk, flipped) {
    var R = RAR[rk], seed = mulberry(rk.length * 977 + 5);
    var d = mk('div', 'face front r-' + rk + (flipped ? ' flipped' : ''));
    var art = mk('div', 'art');
    var parts = { rings: null, bubs: [], motes: [] };
    art.appendChild(mk('div', 'vig'));
    if (rk === 'peu-commun') {
      var s = '<svg class="' + P + 'rings" viewBox="0 0 100 91.3" preserveAspectRatio="none">';
      for (var i = 0; i < 17; i++) s += '<circle cx="72" cy="33" r="' + (3.5 + i * 4.6).toFixed(1) + '" fill="none" stroke="#fff" stroke-opacity="' + (0.17 * Math.pow(1 - i / 18, 1.35)).toFixed(3) + '" stroke-width=".28"/>';
      s += '</svg>';
      var wrap = mk('div', '', s); wrap.style.cssText = 'position:absolute;inset:0';
      art.appendChild(wrap); parts.rings = wrap.firstChild;
    }
    if (rk === 'rare') {
      art.appendChild(mk('div', 'hatch'));
      for (var j = 0; j < 12; j++) {
        var b = mk('div', 'bub'), sz = .9 + seed() * 2.3;
        b.style.width = b.style.height = sz + 'em';
        b.style.left = (6 + seed() * 88) + 'em'; b.style.top = '0';
        art.appendChild(b);
        parts.bubs.push({ e: b, x: 6 + seed() * 88, y0: seed() * 100, v: 3.2 + seed() * 4.4, sw: .6 + seed() * 1.4, ph: seed() * 6.28 });
      }
    }
    if (rk === 'legendaire') {
      for (var k = 0; k < 9; k++) {
        var m = mk('div', 'mote'), ms = 5 + seed() * 12;
        m.style.width = m.style.height = ms + 'em';
        art.appendChild(m);
        parts.motes.push({ e: m, x: 8 + seed() * 84, y: 6 + seed() * 78, ph: seed() * 6.28, sp: .4 + seed() * .7, a: .35 + seed() * .55 });
      }
    }
    var fish = document.createElement('img');
    fish.className = P + 'fish'; fish.src = ASSETS.poissons[R.esp]; fish.alt = ''; fish.draggable = false;
    fish.style.width = R.fw + 'em'; fish.style.marginLeft = (-R.fw / 2) + 'em';
    fish.style.transform = 'translateY(-50%) rotate(-2.5deg)';
    art.appendChild(fish);
    art.appendChild(mk('div', 'cen', R.cen + '<i>e</i>'));
    art.appendChild(mk('div', 'cenl', 'CEN · centile de taille'));
    var holo = mk('div', 'holo');
    if (rk === 'rare' || rk === 'legendaire') art.appendChild(holo);
    d.appendChild(art);

    var panel = mk('div', 'panel');
    var nmE = mk('div', 'nm', '<b>' + R.nom + '</b><em>' + R.lat + '</em>');
    if (R.nom.length > 11) { nmE.firstChild.style.fontSize = '8em'; nmE.lastChild.style.fontSize = '3em'; nmE.style.gap = '2em'; nmE.style.top = '8.6em'; }
    panel.appendChild(nmE);
    panel.appendChild(mk('div', 'rule'));
    var s1 = mk('div', 'st', '<b>' + R.tai + '<small>cm</small></b><span>TAI</span>'); s1.style.left = '7em';
    var s2 = mk('div', 'st', '<b>' + R.frq + '<small>%</small></b><span>FRQ</span>'); s2.style.left = '36.5em';
    var s3 = mk('div', 'st', '<div style="height:8.4em;display:flex;align-items:center;justify-content:center">' + badge(R.shape, R.col, 62 / 8.4 + 'em' ) + '</div><span>' + R.mot.toUpperCase() + '</span>');
    s3.style.left = '66em'; s3.style.width = '27em'; s3.style.textAlign = 'center';
    s3.firstChild.firstChild.setAttribute('width', '7.6em'); s3.firstChild.firstChild.setAttribute('height', '7.6em');
    panel.appendChild(s1); panel.appendChild(s2); panel.appendChild(s3);
    panel.appendChild(mk('div', 'foot', R.pech + ' pêche' + (R.pech > 1 ? 's' : '') + ' sur 29 dans le 94 · OFB'));
    panel.appendChild(mk('div', 'num', 'n° ' + R.num));
    d.appendChild(panel);

    var fr = mk('div', 'frame');
    if (rk === 'rare' || rk === 'legendaire') fr.style.borderColor = 'rgba(255,255,255,.6)';
    else if (rk === 'peu-commun') fr.style.borderColor = 'rgba(255,255,255,.26)';
    d.appendChild(fr);
    if (rk === 'rare' || rk === 'legendaire') d.appendChild(mk('div', 'frame2'));
    var glare = mk('div', 'glare');
    if (rk === 'rare' || rk === 'legendaire') d.appendChild(glare);
    var shine = mk('div', 'shine');
    shine.style.background = 'linear-gradient(105deg,rgba(255,255,255,0) 38%,rgba(255,255,255,.95) 50%,rgba(255,255,255,0) 62%) 0 0/260% 100% no-repeat';
    d.appendChild(shine);
    var edge = mk('div', 'edge');
    if (rk === 'legendaire') {
      edge.style.background = 'linear-gradient(105deg,rgba(255,240,190,0) 43%,rgba(255,252,232,1) 50%,rgba(255,240,190,0) 57%) 0 0/300% 100% no-repeat,linear-gradient(rgba(255,226,150,.3),rgba(255,226,150,.3))';
      d.appendChild(edge);
    }
    var shade = mk('div', 'shade'); d.appendChild(shade);
    if (rk === 'rare') {
      holo.style.background = 'linear-gradient(112deg,rgba(0,0,0,0) 14%,rgba(110,225,255,.55) 34%,rgba(160,140,255,.6) 48%,rgba(255,160,235,.35) 58%,rgba(120,230,255,.45) 68%,rgba(0,0,0,0) 86%) 0 0/280% 280% no-repeat';
    } else if (rk === 'legendaire') {
      holo.style.background = 'linear-gradient(112deg,rgba(0,0,0,0) 14%,rgba(255,236,170,.6) 34%,rgba(255,255,255,.7) 46%,rgba(255,190,90,.55) 58%,rgba(255,225,160,.4) 68%,rgba(0,0,0,0) 86%) 0 0/280% 280% no-repeat';
    }
    glare.style.background = 'radial-gradient(circle at var(--hx,50%) var(--hy,30%),rgba(255,255,255,.95),rgba(255,255,255,0) 52%)';
    return { el: d, art: art, parts: parts, holo: holo, glare: glare, shine: shine, edge: edge, shade: shade, fish: fish };
  }

  function frontIdle(F, t, rk) {
    var p = F.parts, i, o;
    if (p.rings) p.rings.style.transform = 'scale(' + (1 + .022 * Math.sin(t / 1500)).toFixed(4) + ')';
    for (i = 0; i < p.bubs.length; i++) {
      o = p.bubs[i];
      var yy = (((o.y0 - t / 1000 * o.v) % 100) + 100) % 100;
      var a = Math.sin(Math.PI * yy / 100);
      o.e.style.transform = 'translate(' + (Math.sin(t / 900 * o.sw + o.ph) * 1.2).toFixed(2) + 'em,' + (yy * .98).toFixed(2) + 'em)';
      o.e.style.opacity = (a * .85).toFixed(3);
    }
    for (i = 0; i < p.motes.length; i++) {
      o = p.motes[i];
      var pulse = .55 + .45 * Math.sin(t / 1000 * o.sp * 2 + o.ph);
      o.e.style.left = (o.x + Math.sin(t / 2300 * o.sp + o.ph) * 3).toFixed(2) + 'em';
      o.e.style.top = (o.y - ((t / 1000 * o.sp * 2.4) % 6) ).toFixed(2) + 'em';
      o.e.style.opacity = (o.a * pulse).toFixed(3);
    }
  }

  /* ---------- le dos de la carte (SVG gravé) ---------- */
  function backSVG(uid) {
    var id = 'fmRBb' + uid;
    var s = '<svg viewBox="0 0 100 144.93" width="100%" height="100%" preserveAspectRatio="none" style="position:absolute;left:0;top:0;display:block">';
    s += '<defs>' +
      '<radialGradient id="' + id + 'bg" cx="50%" cy="46%" r="78%"><stop offset="0" stop-color="#14609F"/><stop offset=".5" stop-color="#0B3D6B"/><stop offset="1" stop-color="#06284A"/></radialGradient>' +
      '<radialGradient id="' + id + 'md" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#0E4F8C"/><stop offset="1" stop-color="#082F57"/></radialGradient>' +
      '<radialGradient id="' + id + 'mn" cx="42%" cy="38%" r="68%"><stop offset="0" stop-color="#B9DDF6"/><stop offset=".7" stop-color="#6EA8D6"/><stop offset="1" stop-color="#3F7DB4"/></radialGradient>' +
      '<radialGradient id="' + id + 'hl" cx="50%" cy="50%" r="50%"><stop offset=".55" stop-color="#6FC3FF" stop-opacity=".30"/><stop offset="1" stop-color="#6FC3FF" stop-opacity="0"/></radialGradient>' +
      '<clipPath id="' + id + 'cl"><circle cx="50" cy="70" r="27.6"/></clipPath></defs>';
    s += '<rect width="100" height="144.93" fill="url(#' + id + 'bg)"/>';
    /* guilloché : deux jeux de vagues qui se croisent */
    var g1 = '', g2 = '', k, x, d1, d2, y;
    for (k = 0; k < 46; k++) {
      d1 = ''; d2 = '';
      for (x = -2; x <= 102; x += 2) {
        y = 1.6 + k * 3.2 + 1.9 * Math.sin(x * .17 + k * .36);
        d1 += (x < 0 ? 'M' : 'L') + x + ',' + y.toFixed(2);
        y = 1.6 + k * 3.2 + 1.9 * Math.sin(x * .17 - k * .36 + 1.2);
        d2 += (x < 0 ? 'M' : 'L') + x + ',' + y.toFixed(2);
      }
      g1 += '<path d="' + d1 + '"/>'; g2 += '<path d="' + d2 + '"/>';
    }
    s += '<g fill="none" stroke="#9CC7EA" stroke-width=".15" stroke-opacity=".17">' + g1 + '</g>';
    s += '<g fill="none" stroke="#C7DFF3" stroke-width=".12" stroke-opacity=".10">' + g2 + '</g>';
    /* rosette */
    var ros = '';
    for (k = 0; k < 54; k++) ros += '<ellipse cx="50" cy="70" rx="35" ry="10.5" transform="rotate(' + (k * 180 / 54).toFixed(2) + ' 50 70)"/>';
    s += '<circle cx="50" cy="70" r="37" fill="#062442" fill-opacity=".48"/>';
    s += '<g fill="none" stroke="#9CC7EA" stroke-width=".12" stroke-opacity=".30">' + ros + '</g>';
    s += '<circle cx="50" cy="70" r="36.2" fill="none" stroke="#C7DFF3" stroke-opacity=".30" stroke-width=".28"/>';
    s += '<circle cx="50" cy="70" r="29.4" fill="none" stroke="#C7DFF3" stroke-opacity=".38" stroke-width=".3"/>';
    s += '<circle cx="50" cy="70" r="28.4" fill="url(#' + id + 'md)"/>';
    /* logo gravé : lune, eau, poisson bondissant */
    s += '<g clip-path="url(#' + id + 'cl)"><g transform="translate(20 40) scale(.6)">';
    s += '<circle cx="50" cy="48" r="46" fill="url(#' + id + 'hl)"/>';
    s += '<circle cx="50" cy="48" r="32" fill="url(#' + id + 'mn)" fill-opacity=".92"/>';
    var rr = '';
    for (k = 1; k <= 9; k++) rr += '<circle cx="50" cy="48" r="' + (32 - k * 3.1).toFixed(1) + '"/>';
    s += '<g fill="none" stroke="#EAF6FF" stroke-opacity=".22" stroke-width=".42">' + rr + '</g>';
    s += '<path d="M0,74 C20,70 34,72 50,76 C66,72 80,70 100,74 L100,100 L0,100 Z" fill="#051D3A"/>';
    var wl = '';
    for (k = 0; k < 5; k++) wl += '<path d="M0,' + (78 + k * 4.4) + ' C20,' + (74 + k * 4.4) + ' 34,' + (76 + k * 4.4) + ' 50,' + (80 + k * 4.4) + ' C66,' + (76 + k * 4.4) + ' 80,' + (74 + k * 4.4) + ' 100,' + (78 + k * 4.4) + '"/>';
    s += '<path d="M0,74 C20,70 34,72 50,76 C66,72 80,70 100,74" fill="none" stroke="#BFE6FF" stroke-opacity=".6" stroke-width=".8"/>';
    s += '<g fill="none" stroke="#9CC7EA" stroke-opacity=".28" stroke-width=".5">' + wl + '</g>';
    var ft = 'translate(50 46) rotate(-28) scale(.76 .46) translate(-50 -50)';
    s += '<g transform="' + ft + '"><path d="' + ASSETS.poissonPath + '" fill="#EAF6FF" fill-opacity=".22" transform="translate(1.6 2.4)"/></g>';
    s += '<g transform="' + ft + '"><path d="' + ASSETS.poissonPath + '" fill="#03142B" stroke="#BFE6FF" stroke-opacity=".7" stroke-width="1.3" vector-effect="non-scaling-stroke"/><circle cx="74" cy="45" r="3.6" fill="#BFE6FF"/></g>';
    s += '<g fill="#BFE6FF" fill-opacity=".8"><circle cx="20.5" cy="69" r="1.7"/><circle cx="16.5" cy="65" r="1.2"/><circle cx="36" cy="68.5" r="1.2"/></g>';
    s += '</g></g>';
    s += '<circle cx="50" cy="70" r="27.6" fill="none" stroke="#DFF1FF" stroke-opacity=".5" stroke-width=".4"/>';
    /* cadres et coins */
    s += '<rect x="3.4" y="3.4" width="93.2" height="138.13" rx="4.4" fill="none" stroke="#9CC7EA" stroke-opacity=".5" stroke-width=".36"/>';
    s += '<rect x="5.2" y="5.2" width="89.6" height="134.53" rx="3.2" fill="none" stroke="#9CC7EA" stroke-opacity=".22" stroke-width=".22"/>';
    var cs = [[8.6, 8.6, 0], [91.4, 8.6, 90], [91.4, 136.33, 180], [8.6, 136.33, 270]];
    for (k = 0; k < 4; k++) s += '<g transform="translate(' + cs[k][0] + ' ' + cs[k][1] + ') rotate(' + cs[k][2] + ')" fill="none" stroke="#C7DFF3" stroke-opacity=".5" stroke-width=".3"><path d="M-2.6,-2.6 L-2.6,2.6 M-2.6,-2.6 L2.6,-2.6"/><circle r="1.1"/></g>';
    s += '<text x="50" y="131" text-anchor="middle" font-family=\'' + FONT.replace(/"/g, '&quot;') + '\' font-weight="800" font-size="3.6" letter-spacing="1.6" fill="#9CC7EA" fill-opacity=".62">FISHME</text>';
    s += '<text x="50" y="16.6" text-anchor="middle" font-family=\'' + FONT.replace(/"/g, '&quot;') + '\' font-weight="800" font-size="2.6" letter-spacing="1.4" fill="#9CC7EA" fill-opacity=".4">PESCEDEX</text>';
    s += '</svg>';
    return s;
  }

  /* ---------- la « photo » de l'utilisateur (stand-in flou) ---------- */
  function photoSVG(uid, rk) {
    var id = 'fmRBp' + uid;
    var fish = ASSETS.poissons[RAR[rk].esp], fw = rk === 'commun' ? 270 : 330, fh = fw * ({ 'commun': .516, 'peu-commun': .298, 'rare': .416, 'legendaire': .426 })[rk];
    return '<svg viewBox="0 0 390 844" width="100%" height="100%" preserveAspectRatio="xMidYMid slice" style="display:block"><defs>' +
      '<linearGradient id="' + id + 's" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8FAABB"/><stop offset=".55" stop-color="#C9D6D8"/><stop offset="1" stop-color="#E7E5D6"/></linearGradient>' +
      '<linearGradient id="' + id + 'w" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8CA6A6"/><stop offset="1" stop-color="#3D5559"/></linearGradient>' +
      '<linearGradient id="' + id + 'j" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#31485A"/><stop offset="1" stop-color="#16232F"/></linearGradient>' +
      '<radialGradient id="' + id + 'v" cx="50%" cy="46%" r="75%"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".55"/></radialGradient>' +
      '<filter id="' + id + 'b1" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="7"/></filter>' +
      '<filter id="' + id + 'b2"><feGaussianBlur stdDeviation="1.1"/></filter>' +
      '<filter id="' + id + 'n"><feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" seed="3"/><feColorMatrix values="0 0 0 0 .5  0 0 0 0 .5  0 0 0 0 .5  0 0 0 .5 0"/></filter></defs>' +
      '<rect width="390" height="844" fill="url(#' + id + 's)"/>' +
      '<g filter="url(#' + id + 'b1)"><path d="M-20,360 C40,300 90,330 140,310 C200,280 250,330 300,300 C340,285 380,300 420,320 L420,420 L-20,420Z" fill="#4A6663"/><path d="M-20,390 C60,350 120,372 200,356 C280,342 340,372 420,360 L420,430 L-20,430Z" fill="#355150"/>' +
      '<circle cx="70" cy="200" r="38" fill="#fff" fill-opacity=".22"/><circle cx="318" cy="150" r="26" fill="#fff" fill-opacity=".18"/><circle cx="250" cy="250" r="16" fill="#fff" fill-opacity=".15"/></g>' +
      '<rect y="404" width="390" height="440" fill="url(#' + id + 'w)"/>' +
      '<g filter="url(#' + id + 'b2)" stroke="#E6F1F2" stroke-opacity=".28" stroke-width="2" fill="none"><path d="M10,430 H120 M180,448 H340 M40,474 H190 M240,500 H380"/></g>' +
      /* le pêcheur : épaules, cou, menton, casquette */
      '<g filter="url(#' + id + 'b2)"><path d="M-30,844 L-30,640 C-20,560 70,520 140,505 L250,505 C320,520 410,560 420,640 L420,844Z" fill="url(#' + id + 'j)"/>' +
      '<path d="M150,505 C160,540 230,540 240,505 L236,470 L154,470Z" fill="#B98666"/>' +
      '<ellipse cx="195" cy="385" rx="72" ry="92" fill="#C79A7A"/>' +
      '<path d="M120,370 C118,300 160,262 205,262 C252,262 276,300 272,368 C250,338 150,338 120,370Z" fill="#1F3B45"/>' +
      '<path d="M112,372 C150,350 250,350 300,376 C290,386 160,380 112,372Z" fill="#162B33"/>' +
      '<path d="M150,372 C170,382 230,382 250,372 L246,396 C220,404 180,404 154,396Z" fill="#000" fill-opacity=".18"/>' +
      '<path d="M170,452 C185,462 207,462 222,452" stroke="#7B4B3A" stroke-width="3.5" fill="none" stroke-linecap="round"/></g>' +
      /* poisson tenu, mains */
      '<g filter="url(#' + id + 'b2)"><g transform="translate(195 640) rotate(-9)"><image href="' + fish + '" x="' + (-fw / 2) + '" y="' + (-fh / 2) + '" width="' + fw + '" height="' + fh + '"/></g>' +
      '<ellipse cx="128" cy="668" rx="34" ry="26" fill="#C79A7A" transform="rotate(-20 128 668)"/><ellipse cx="266" cy="622" rx="30" ry="24" fill="#B98666" transform="rotate(-8 266 622)"/></g>' +
      '<rect width="390" height="844" fill="url(#' + id + 'v)"/>' +
      '<rect width="390" height="844" filter="url(#' + id + 'n)" opacity=".16"/></svg>';
  }

  /* ---------- base commune ---------- */
  function base(el, ctx, kind, cfg) {
    injectCSS();
    var rk = (ctx && ctx.option && ctx.option.rarete) || 'rare';
    if (!RAR[rk]) rk = 'rare';
    var R = RAR[rk];
    var S = { rk: rk, R: R, kind: kind, cfg: cfg, D: R.D, t: 0, alive: true, visible: true, fired: {}, last: 0, raf: 0, uid: ++uidN, reduit: !!(ctx && ctx.reduit) };
    S.static = S.reduit;
    S.rng = mulberry(7 + rk.length * 31 + (kind === 'B' ? 1 : 2));

    var root = mk('div', 'root r-' + rk);
    S.root = root;
    S.cvB = mk('canvas', 'cv'); S.cvF = mk('canvas', 'cv');
    S.xB = S.cvB.getContext('2d'); S.xF = S.cvF.getContext('2d');
    S.stage = mk('div', 'stage');
    S.ground = mk('div', 'ground'); S.aura = mk('div', 'aura');
    S.lift = mk('div', 'lift'); S.flip = mk('div', 'flip');
    S.front = makeFront(rk, kind === 'B');
    S.flash = mk('div', 'flash');
    S.ui = mk('div', 'ui');
    S.word = mk('div', 'word', badge(R.shape, R.txt, 44, 'width:44em;height:44em;flex:none') + '<span style="color:' + R.txt + '">' + R.mot + '</span>');
    S.word.firstChild.setAttribute('width', '44em'); S.word.firstChild.setAttribute('height', '44em');
    S.dots = mk('div', 'dots');
    S.dotEls = [];
    for (var i = 0; i < 4; i++) {
      var dd = mk('div', 'dot');
      dd.style.background = i < R.n ? R.txt : 'rgba(255,255,255,.2)';
      if (i < R.n && R.n >= 3) dd.style.boxShadow = '0 0 ' + (6) + 'em ' + rgba(R.glow, .6);
      S.dots.appendChild(dd); S.dotEls.push(dd);
    }
    S.btnw = mk('div', 'btnw'); S.btn = mk('button', 'btn', 'Ranger dans le Pescedex'); S.btn.type = 'button';
    S.btnw.appendChild(S.btn);
    S.ui.appendChild(S.word); S.ui.appendChild(S.dots); S.ui.appendChild(S.btnw);

    S.flip.appendChild(S.front.el);
    S.lift.appendChild(S.flip);
    S.stage.appendChild(S.ground); S.stage.appendChild(S.aura); S.stage.appendChild(S.lift);
    root.appendChild(S.cvB); root.appendChild(S.stage); root.appendChild(S.cvF);
    root.appendChild(S.flash); root.appendChild(S.ui);
    el.appendChild(root);

    /* inclinaison suivie au doigt ou au pointeur, dérive douce sinon */
    S.tilt = { nx: 0, ny: 0, tx: 0, ty: 0, last: -1e9 };
    function pm(e) {
      var r = root.getBoundingClientRect(), sx = r.width / (S.W || r.width || 1);
      var px = (e.clientX - r.left) / (sx || 1), py = (e.clientY - r.top) / (sx || 1);
      S.tilt.tx = Math.max(-1, Math.min(1, (px - S.cx) / (S.cw * .75)));
      S.tilt.ty = Math.max(-1, Math.min(1, (py - S.cy) / (S.ch * .6)));
      S.tilt.last = performance.now();
    }
    function pl() { S.tilt.last = -1e9; }
    function pd(e) { pm(e); S.skip(); }
    root.addEventListener('pointermove', pm);
    root.addEventListener('pointerleave', pl);
    root.addEventListener('pointerdown', pd);
    S.btn.addEventListener('pointerdown', function (e) { e.stopPropagation(); });
    S.btn.addEventListener('click', function (e) { e.stopPropagation(); });

    S.layout = function () {
      var W = el.clientWidth || 390, H = el.clientHeight || 844;
      S.W = W; S.H = H;
      var u = Math.min(W / 390, H / 844); S.u = u;
      var cw = Math.min(W * .76, H * .5 / 1.4493); S.cw = cw; S.ch = cw * 1.4493;
      S.cx = W / 2; S.cy = H * .395;
      root.style.fontSize = u + 'px';
      S.stage.style.transform = 'translate(' + S.cx + 'px,' + S.cy + 'px)';
      S.stage.style.perspective = (cw * 3.4) + 'px';
      S.lift.style.fontSize = (cw / 100) + 'px';
      S.ground.style.cssText += ';width:' + (cw * 1.05) + 'px;height:' + (cw * .26) + 'px;left:' + (-cw * .525) + 'px;top:' + (S.ch / 2 + cw * .11) + 'px';
      S.aura.style.cssText += ';width:' + cw + 'px;height:' + S.ch + 'px;left:' + (-cw / 2) + 'px;top:' + (-S.ch / 2) + 'px;border-radius:' + (cw * .06) + 'px';
      var dpr = Math.min(2, window.devicePixelRatio || 1); S.dpr = dpr;
      [S.cvB, S.cvF].forEach(function (c, i) {
        c.width = Math.round(W * dpr); c.height = Math.round(H * dpr);
        (i ? S.xF : S.xB).setTransform(dpr, 0, 0, dpr, 0, 0);
      });
      var bot = S.cy + S.ch / 2;
      var wy = Math.min(H - 150 * u, bot + 63 * u);
      S.word.style.top = (wy - 24 * u) + 'px'; S.word.style.height = 48 * u + 'px';
      S.dots.style.top = (wy + 60 * u - 6 * u) + 'px';
      S.btnw.style.bottom = Math.max(18, 36 * u) + 'px';
      if (S.onLayout) S.onLayout();
      S.render(S.t);
    };

    /* événements sonores */
    S.fire = function () {
      var ev = S.events || [];
      for (var i = 0; i < ev.length; i++) {
        if (!S.fired[i] && S.t >= ev[i].t) { S.fired[i] = 1; try { ctx.son(ev[i].id); } catch (e) { } }
      }
    };

    /* interface finale : mot de rareté, badge, points, bouton */
    S.uiRender = function (t) {
      var a = S.uiA, b = S.D;
      var w = sstep(prog(t, a, a + (b - a) * .55));
      S.word.style.opacity = w; S.word.style.transform = 'translateY(' + ((1 - eO3(prog(t, a, a + (b - a) * .55))) * 14).toFixed(2) + 'em) scale(' + lerp(.9, 1, eO3(prog(t, a, a + (b - a) * .7))).toFixed(3) + ')';
      for (var i = 0; i < 4; i++) {
        var p = prog(t, a + 60 + i * 90, a + 60 + i * 90 + 260);
        var sc = i < R.n ? (p < 1 ? lerp(.2, 1, spring(p, .5, 10)) : 1) : 1;
        S.dotEls[i].style.opacity = i < R.n ? c01(p * 2) : c01(p * 2) * .9;
        S.dotEls[i].style.transform = 'scale(' + sc.toFixed(3) + ')';
      }
      var pb = prog(t, a + (b - a) * .35, b);
      S.btnw.style.opacity = sstep(pb); S.btnw.style.transform = 'translateY(' + ((1 - eO3(pb)) * 18).toFixed(2) + 'em)';
      S.btnw.style.pointerEvents = pb > .6 ? 'auto' : 'none';
    };

    /* inclinaison + reflet holographique */
    S.stepTilt = function (t, amt) {
      var T = S.tilt, now = performance.now();
      var tx, ty;
      if (S.static) { tx = .32; ty = -.18; T.nx = tx; T.ny = ty; }
      else {
        if (now - T.last < 1600) { tx = T.tx; ty = T.ty; }
        else { tx = .62 * Math.sin(t / 1900); ty = .5 * Math.sin(t / 2700 + 1.1); }
        T.nx += (tx - T.nx) * .1; T.ny += (ty - T.ny) * .1;
      }
      var nx = T.nx * amt, ny = T.ny * amt;
      S.rotY = nx * 9; S.rotX = -ny * 7;
      var F = S.front;
      if (S.rk === 'rare' || S.rk === 'legendaire') {
        var ho = (S.rk === 'rare' ? .8 : .6) * amt;
        F.holo.style.opacity = ho.toFixed(3);
        F.holo.style.backgroundPosition = (50 + T.nx * 55).toFixed(1) + '% ' + (50 + T.ny * 55).toFixed(1) + '%';
        F.glare.style.opacity = ((S.rk === 'rare' ? .32 : .2) * amt).toFixed(3);
        F.glare.style.setProperty('--hx', (50 + T.nx * 42).toFixed(1) + '%');
        F.glare.style.setProperty('--hy', (34 + T.ny * 34).toFixed(1) + '%');
      }
    };

    S.skip = function () {
      if (S.reduit || S.t >= S.D) return;
      S.t = S.D;
      var ev = S.events || [];
      for (var i = 0; i < ev.length; i++) {
        if (!S.fired[i]) { S.fired[i] = 1; if (/^carte-/.test(ev[i].id)) { try { ctx.son(ev[i].id); } catch (e) { } } }
      }
      S.render(S.t);
    };

    function frame(now) {
      S.raf = 0;
      if (!S.alive || !S.visible || S.reduit) return;
      var dt = S.last ? Math.min(now - S.last, 50) : 16.7;
      S.last = now;
      S.t += dt;
      S.fire();
      S.render(S.t);
      S.raf = requestAnimationFrame(frame);
    }
    S.start = function () { if (!S.raf && S.alive && S.visible && !S.reduit) { S.last = 0; S.raf = requestAnimationFrame(frame); } };
    S.reset = function () {
      S.t = 0; S.fired = {}; S.tilt.nx = S.tilt.ny = 0; S.tilt.last = -1e9; S.last = 0;
      if (S.onReset) S.onReset();
      if (S.reduit) {
        root.style.transition = 'none'; root.style.opacity = '0'; S.render(S.D + 5000);
        void root.offsetWidth; root.style.transition = 'opacity 400ms ease'; root.style.opacity = '1';
        S.btnw.style.pointerEvents = 'auto';
      } else { S.render(0); S.start(); }
    };

    S.ro = new ResizeObserver(function () { if (S.alive) S.layout(); });
    S.ro.observe(el);
    if ('IntersectionObserver' in window) {
      S.io = new IntersectionObserver(function (en) {
        S.visible = en[en.length - 1].isIntersecting;
        if (S.visible) S.start(); else { if (S.raf) cancelAnimationFrame(S.raf); S.raf = 0; }
      });
      S.io.observe(el);
    }
    S.stop = function () {
      S.alive = false; if (S.raf) cancelAnimationFrame(S.raf); S.raf = 0;
      if (S.ro) S.ro.disconnect(); if (S.io) S.io.disconnect();
      root.removeEventListener('pointermove', pm); root.removeEventListener('pointerleave', pl); root.removeEventListener('pointerdown', pd);
      if (root.parentNode) root.parentNode.removeChild(root);
    };
    S.api = {
      rejouer: function () { S.reset(); },
      arreter: function () { S.stop(); },
      _seek: function (ms) { S.alive = true; if (S.raf) cancelAnimationFrame(S.raf); S.raf = 0; S.reduit = true && S.reduit; S.t = ms; S.render(ms); },
      _S: S
    };
    return S;
  }

  /* dessin d'une grande lueur douce */
  function glowDot(c, rgb, x, y, r, a) {
    c.globalAlpha = a; c.drawImage(sprite(rgb), x - r, y - r, r * 2, r * 2); c.globalAlpha = 1;
  }

  function rayBurst(c, cx, cy, rot, len, intensity, rgb, count) {
    if (intensity <= .003) return;
    c.save(); c.translate(cx, cy); c.globalCompositeOperation = 'lighter';
    for (var i = 0; i < count; i++) {
      var a = rot + i * Math.PI * 2 / count, w = (i % 2 ? .05 : .085) * (.7 + .3 * Math.sin(rot * 3 + i));
      var L = len * (i % 3 === 0 ? 1 : i % 3 === 1 ? .78 : .6);
      c.save(); c.rotate(a);
      var g = c.createLinearGradient(0, 0, L, 0);
      g.addColorStop(0, 'rgba(' + rgb + ',' + (.55 * intensity) + ')'); g.addColorStop(.55, 'rgba(' + rgb + ',' + (.2 * intensity) + ')'); g.addColorStop(1, 'rgba(' + rgb + ',0)');
      c.fillStyle = g; c.beginPath(); c.moveTo(0, 0); c.lineTo(L, -L * w); c.lineTo(L, L * w); c.closePath(); c.fill();
      c.restore();
    }
    c.restore();
  }

  /* ======================================================================
     B — Le dos de la carte
     ====================================================================== */
  var BT = {
    'commun':     { ph: 420, shk: null, seam: [700, 870], flip: [820, 1420], gap: 1.6 },
    'peu-commun': { ph: 450, shk: [520, 1020, 1.6, 1], seam: [1110, 1390], flip: [1330, 1980], gap: 2.2 },
    'rare':       { ph: 450, shk: [620, 1650, 3, 2], seam: [1690, 2050], flip: [2000, 2720], gap: 3.2 },
    'legendaire': { ph: 520, shk: [680, 2780, 6.2, 4], seam: [2840, 3300], flip: [3250, 4020], gap: 4.4 }
  };

  function monterB(el, ctx) {
    var S = base(el, ctx, 'B');
    var rk = S.rk, R = S.R, T = BT[rk], uid = S.uid;
    var fl = T.flip;
    /* instant où la carte passe à 90° (le recto apparaît) */
    var cross = fl[1];
    for (var q = 0; q <= 400; q++) { if (180 * spring(q / 400, .62, 10) >= 90) { cross = lerp(fl[0], fl[1], q / 400); break; } }
    S.cross = cross; S.uiA = Math.min(fl[1] - 150, S.D - 330);
    S.events = [];
    if (rk === 'rare' || rk === 'legendaire') S.events.push({ t: T.shk[0], id: 'montee' });
    S.events.push({ t: fl[0] + 20, id: 'retournement' });
    S.events.push({ t: cross, id: 'carte-' + rk });

    /* dos : deux moitiés qui s'écartent sur la ligne de lumière */
    var back = mk('div', 'face back');
    var seam = mk('div', 'seam'), spill = mk('div', 'spill');
    var hl = mk('div', 'half hl'), hr = mk('div', 'half hr');
    var bsvg = backSVG(uid), ba1 = mk('div', 'bart', bsvg), ba2 = mk('div', 'bart', bsvg.replace(/fmRBb(\d+)/g, 'fmRBc$1'));
    var bg1 = mk('div', 'bglow'), bg2 = mk('div', 'bglow');
    var sh1 = mk('div', 'shade'); var shb = mk('div', 'shade');
    ba1.appendChild(bg1); ba2.appendChild(bg2);
    hl.appendChild(ba1); hr.appendChild(ba2);
    back.appendChild(seam); back.appendChild(hl); back.appendChild(hr); back.appendChild(spill); back.appendChild(shb);
    S.flip.insertBefore(back, S.front.el);
    spill.style.background = 'linear-gradient(90deg,rgba(' + R.tintRgb + ',0),rgba(' + R.tintRgb + ',.5) 50%,rgba(' + R.tintRgb + ',0))';
    seam.style.background = 'linear-gradient(90deg,rgba(' + R.tintRgb + ',.0),rgba(' + R.tintRgb + ',.95) 22%,#fff 50%,rgba(' + R.tintRgb + ',.95) 78%,rgba(' + R.tintRgb + ',0))';
    S.flash.style.background = rk === 'legendaire'
      ? 'radial-gradient(circle at 50% 39.5%,rgba(255,248,222,1) 0,rgba(255,214,120,.78) 24%,rgba(240,184,66,.28) 52%,rgba(240,184,66,0) 78%)'
      : 'radial-gradient(circle at 50% 39.5%,rgba(236,230,255,.9) 0,rgba(150,130,255,.45) 30%,rgba(124,107,255,0) 70%)';

    /* la photo */
    var photo = mk('div', 'photo', photoSVG(uid, rk));
    var shot = mk('div', 'flash'); shot.style.background = '#fff';
    S.root.insertBefore(photo, S.flash);
    var motes = [];
    var rnd = mulberry(91);
    for (var m = 0; m < 38; m++) motes.push({ x: (rnd() - .5) * 1.2, y: .1 + rnd() * .5, v: 28 + rnd() * 70, sw: 6 + rnd() * 14, f: .7 + rnd() * 1.4, r: 1.4 + rnd() * 3.4, life: 2300 + rnd() * 2400, b: rnd() * 1500, ph: rnd() * 6.28 });
    var spk = [];
    for (var s2 = 0; s2 < 36; s2++) spk.push({ x: rnd(), y: rnd(), r: .5 + rnd() * 1.3, a: .15 + rnd() * .35, ph: rnd() * 6.28, sp: .3 + rnd() });

    S.onLayout = function () {
      photo.style.fontSize = S.u + 'px';
    };

    S.render = function (t) {
      var W = S.W, H = S.H, u = S.u, cw = S.cw, ch = S.ch, cx = S.cx, cy = S.cy, c = S.xB, f = S.xF, tt = S.static ? 6000 : t;
      var done = t >= S.D;
      c.clearRect(0, 0, W, H); f.clearRect(0, 0, W, H);

      /* fond : halo marine derrière la carte + poussière d'eau */
      var bgA = .22 + .1 * sstep(prog(t, 0, 600));
      var gr = c.createRadialGradient(cx, cy, cw * .1, cx, cy, Math.max(W, H) * .62);
      gr.addColorStop(0, 'rgba(13,74,133,' + (bgA * 1.7) + ')'); gr.addColorStop(.5, 'rgba(13,74,133,' + (bgA * .6) + ')'); gr.addColorStop(1, 'rgba(4,18,43,.55)');
      c.fillStyle = gr; c.fillRect(0, 0, W, H);
      for (var i = 0; i < spk.length; i++) {
        var p = spk[i], tw = .5 + .5 * Math.sin(tt / 1000 * p.sp * 2 + p.ph);
        c.fillStyle = 'rgba(199,223,243,' + (p.a * tw) + ')';
        c.beginPath(); c.arc(p.x * W + Math.sin(tt / 4000 + p.ph) * 6 * u, ((p.y * H - tt / 1000 * 6 * u * p.sp) % H + H) % H, p.r * u, 0, 6.2832); c.fill();
      }

      /* temps clés */
      var shkE = 0, ang = 0, sx = 0, scl = 1;
      if (T.shk) {
        var a = T.shk[0], b = T.shk[1], amp = T.shk[2], cyc = T.shk[3], us = prog(t, a, b);
        if (t >= a && t <= b) {
          var env = rk === 'legendaire' ? (.32 + .68 * us) * (1 - sstep((us - .9) / .1)) : Math.pow(Math.sin(Math.PI * us), .8);
          var ph = Math.PI * 2 * cyc * (rk === 'legendaire' ? us * (.7 + .6 * us) : us);
          ang = amp * env * Math.sin(ph); sx = ang * .22;
          if (rk === 'legendaire') scl = 1 + .028 * sstep(us);
          if (rk === 'peu-commun') ang = amp * env * Math.sin(ph);
        }
        shkE = sstep(prog(t, a, b));
        if (rk === 'peu-commun') shkE = 0;
      }
      /* intensité du halo */
      var eBuild = rk === 'legendaire' ? shkE * (.8 + .2 * Math.sin(t / 95 * (1 + shkE))) : rk === 'rare' ? shkE * .55 : 0;
      var uf = prog(t, fl[0], fl[1]);
      var burst = t >= cross ? Math.exp(-(t - cross) / (rk === 'legendaire' ? 900 : 650)) : 0;
      var rest = (rk === 'rare' || rk === 'legendaire') ? .28 : (rk === 'peu-commun' ? .12 : .06);
      var eAura = Math.max(eBuild * (1 - sstep(prog(t, fl[0], cross))), 0);
      var auraT = eAura + (t >= fl[0] ? sstep(prog(t, fl[0], fl[1])) * rest + burst * .8 : 0);
      if (S.static) auraT = rest;
      /* dos : lueur de bord */
      var gl = eBuild * (1 - sstep(prog(t, fl[0] - 60, fl[0] + 140)));
      var bs = gl > .01 ? 'inset 0 0 ' + (4 + gl * 10).toFixed(2) + 'em ' + (gl * 1.8).toFixed(2) + 'em ' + rgba(R.glow, (gl * .9).toFixed(3)) + ',inset 0 0 ' + (gl * 2.4).toFixed(2) + 'em ' + rgba(R.glow, (gl * .8).toFixed(3)) : 'none';
      bg1.style.boxShadow = bs; bg2.style.boxShadow = bs;

      /* ligne de lumière + écartement des moitiés */
      var us2 = prog(t, T.seam[0], T.seam[1]);
      var close = 1 - sstep(prog(t, fl[0], fl[0] + 110));
      var gap = T.gap * sstep(prog(us2, .35, 1)) * close;
      var sy = eO3(prog(us2, 0, .55)) * (t < fl[0] + 140 ? 1 : 0);
      var seamOn = (t >= T.seam[0] && t < fl[0] + 200) ? 1 : 0;
      seam.style.opacity = seamOn ? Math.min(1, sy * 1.4) * (1 - sstep(prog(t, fl[0] + 20, fl[0] + 170))) : 0;
      seam.style.width = (gap + .5).toFixed(2) + 'em';
      seam.style.marginLeft = (-(gap + .5) / 2).toFixed(2) + 'em';
      seam.style.transform = 'scaleY(' + Math.max(.001, sy).toFixed(3) + ')';
      spill.style.opacity = seamOn ? (sstep(prog(us2, .15, 1)) * (1 - sstep(prog(t, fl[0] + 30, fl[0] + 190)))).toFixed(3) : 0;
      hl.style.transform = 'translateX(' + (-gap / 2).toFixed(2) + 'em)';
      hr.style.transform = 'translateX(' + (gap / 2).toFixed(2) + 'em)';

      /* photo qui rétrécit vers le dos */
      var up = prog(t, 0, T.ph), e = eIO(up);
      var pw = lerp(W, cw, e), ph2 = lerp(H, ch, e), rad = lerp(0, cw * .06, e);
      var px = cx - pw / 2 + (0) * 0, py = lerp(0, cy - ch / 2, e);
      var fade = 1 - sstep(prog(t, T.ph - 40, T.ph + 130));
      if (fade > .001 && !S.static) {
        photo.style.display = 'block';
        photo.style.width = pw.toFixed(1) + 'px'; photo.style.height = ph2.toFixed(1) + 'px';
        photo.style.left = (lerp(0, cx - cw / 2, e)).toFixed(1) + 'px'; photo.style.top = py.toFixed(1) + 'px';
        photo.style.borderRadius = rad.toFixed(1) + 'px';
        var sc = 1 - .04 * sstep(prog(t, T.ph - 40, T.ph + 130));
        photo.style.transform = 'scale(' + sc.toFixed(4) + ')'; photo.style.opacity = fade.toFixed(3);
        photo.style.filter = fade < 1 ? 'blur(' + ((1 - fade) * 5).toFixed(2) + 'px)' : 'none';
        photo.style.boxShadow = '0 ' + (e * 14 * u).toFixed(1) + 'px ' + (e * 34 * u).toFixed(1) + 'px rgba(2,9,22,' + (.55 * e).toFixed(2) + ')';
      } else photo.style.display = 'none';
      /* le dos sous la photo : il se pose avec un léger rebond */
      var bk = sstep(prog(t, T.ph * .55, T.ph + 80));
      var land = t > T.ph ? 1 + .035 * Math.exp(-(t - T.ph) / 120) * Math.cos((t - T.ph) / 40) : 1;
      var liftOp = S.static ? 1 : bk;
      S.lift.style.opacity = liftOp.toFixed(3);

      /* retournement */
      var th = 180 * (t < fl[0] ? 0 : spring(prog(t, fl[0], fl[1]), .62, 10));
      if (S.static) th = 180;
      var tiltAmt = S.static ? 1 : sstep(prog(t, fl[1] - 200, fl[1] + 500));
      S.stepTilt(tt, tiltAmt);
      var pop = 1 + .075 * Math.sin(Math.PI * c01((t - fl[0]) / (fl[1] - fl[0]))) * (rk === 'commun' ? .6 : 1);
      var yl = (S.static ? 0 : -(Math.sin(Math.PI * c01((t - fl[0]) / (fl[1] - fl[0]))) * 1.8 * u));
      var floatY = (done || S.static) && !S.static ? Math.sin(tt / 1300) * 1.4 * u : 0;
      S.lift.style.transform = 'translate(' + sx.toFixed(2) + 'em,' + (yl + floatY).toFixed(2) + 'px) rotate(' + ang.toFixed(3) + 'deg) scale(' + (scl * pop * land).toFixed(4) + ')';
      S.flip.style.transform = 'rotateX(' + (S.rotX || 0).toFixed(2) + 'deg) rotateY(' + (th + (S.rotY || 0)).toFixed(2) + 'deg)';
      var cs = Math.abs(Math.cos(th * Math.PI / 180));
      var shd = ((1 - cs) * .5).toFixed(3);
      shb.style.opacity = shd; S.front.shade.style.opacity = shd;
      /* éclat qui balaie le recto à l'arrivée */
      var sw = prog(t, cross - 40, cross + 700);
      S.front.shine.style.opacity = (sw > 0 && sw < 1 && !S.static) ? (Math.sin(Math.PI * sw) * (rk === 'commun' ? .45 : .8)).toFixed(3) : 0;
      S.front.shine.style.backgroundPosition = (lerp(100, 0, eIO(sw))) + '% 0';

      /* halo autour de la carte */
      var aur = c01(auraT);
      S.aura.style.opacity = '1';
      S.aura.style.boxShadow = aur > .005 ? '0 0 ' + (cw * (.12 + aur * .3)).toFixed(1) + 'px ' + (cw * aur * .05).toFixed(1) + 'px ' + rgba(R.glow, (aur * (rk === 'commun' ? .3 : .55)).toFixed(3)) : 'none';
      var gsc = 1 - .1 * Math.sin(Math.PI * c01((t - fl[0]) / (fl[1] - fl[0])));
      S.ground.style.opacity = (liftOp * (.9 - .25 * Math.sin(Math.PI * c01((t - fl[0]) / (fl[1] - fl[0]))))).toFixed(3);
      S.ground.style.transform = 'scale(' + gsc.toFixed(3) + ')';

      /* rayons violets (rare) */
      if (rk === 'rare') {
        var ray = Math.max(.34 * shkE * (1 - sstep(prog(t, fl[0], cross))), 0) + (t >= fl[0] ? sstep(prog(t, fl[0], cross)) * .3 : 0);
        ray = Math.max(ray, burst * 1.15) + (t >= cross ? .12 * (1 - burst) * (S.static ? 0 : 1) : 0);
        if (S.static) ray = .16;
        rayBurst(c, cx, cy, tt / 5200 + .3, ch * (.9 + .55 * Math.max(burst, shkE * .6)), c01(ray), '160,140,255', 14);
        glowDot(c, '124,107,255', cx, cy, cw * (.9 + burst * .5), c01(ray * .55));
      }
      if (rk === 'legendaire') {
        glowDot(c, '240,184,66', cx, cy, cw * (.95 + burst * .6), c01(auraT * .5));
        if (shkE > 0) rayBurst(c, cx, cy, tt / 7000, ch * .8, .12 * shkE * (1 - sstep(prog(t, fl[0], cross))), '255,220,130', 10);
      }

      /* éclat doré, onde de choc, braises montantes */
      if (rk === 'legendaire' || rk === 'rare') {
        var fa = t < cross - 90 ? 0 : t < cross ? (t - (cross - 90)) / 90 : Math.exp(-(t - cross) / (rk === 'legendaire' ? 360 : 240));
        if (S.static) fa = 0;
        S.flash.style.opacity = (fa * (rk === 'legendaire' ? .95 : .5)).toFixed(3);
      }
      if (rk === 'legendaire' && !S.static && t >= cross) {
        f.save(); f.globalCompositeOperation = 'lighter';
        for (var w = 0; w < 2; w++) {
          var pw2 = prog(t, cross + w * 130, cross + w * 130 + 1000);
          if (pw2 > 0 && pw2 < 1) {
            var rr = lerp(cw * .35, Math.max(W, H) * .85, eO3(pw2));
            f.strokeStyle = 'rgba(255,214,120,' + ((1 - pw2) * (w ? .5 : .95)) + ')'; f.lineWidth = Math.max(.6, (w ? 5 : 9) * u * (1 - pw2));
            f.beginPath(); f.ellipse(cx, cy, rr, rr * 1.04, 0, 0, 6.2832); f.stroke();
            f.strokeStyle = 'rgba(255,244,205,' + ((1 - pw2) * .35) + ')'; f.lineWidth = Math.max(.4, 2.4 * u * (1 - pw2));
            f.beginPath(); f.ellipse(cx, cy, rr * .985, rr * 1.025, 0, 0, 6.2832); f.stroke();
          }
        }
        f.restore();
      }
      if (rk === 'legendaire' && (S.static || t >= cross)) {
        f.save(); f.globalCompositeOperation = 'lighter';
        for (var k2 = 0; k2 < motes.length; k2++) {
          var mo = motes[k2], age = S.static ? (mo.b + mo.life * .4) : (t - cross - mo.b * .5);
          if (age < 0) continue;
          var fr = (age % mo.life) / mo.life;
          var al = Math.sin(Math.PI * fr) * (.55 + .45 * Math.sin(age / 130 * mo.f + mo.ph));
          var mx = cx + mo.x * cw * .6 + Math.sin(age / 1000 * mo.f * 2 + mo.ph) * mo.sw * u;
          var my = cy + ch * (mo.y - .15) - (age % mo.life) / 1000 * mo.v * u * 1.7;
          glowDot(f, '255,222,140', mx, my, mo.r * 3.4 * u, c01(al));
        }
        f.restore();
        /* balayage lent de l'éclat sur le bord */
        var sp = S.static ? -1 : (t - (cross + 260)) / 1600;
        if (sp >= 0) { sp = sp % 3.4; }
        var eo = (sp >= 0 && sp < 1) ? Math.sin(Math.PI * sp) : 0;
        S.front.edge.style.opacity = eo.toFixed(3);
        S.front.edge.style.backgroundPosition = (lerp(86, 14, eIO(sp < 0 ? 0 : sp)) + '% 0, 0 0');
      }
      frontIdle(S.front, tt, rk);
      S.uiRender(S.static ? S.D + 99 : t);
    };

    S.onReset = function () { S.flash.style.opacity = 0; };
    S.layout();
    S.reset();
    return S.api;
  }

  /* ======================================================================
     C — Bulle
     ====================================================================== */
  var CT = {
    'commun':     { rise: 950, pop: 1180, n: 7, drops: 28, sp: 1.0, ring: 1 },
    'peu-commun': { rise: 1450, pop: 1750, n: 12, drops: 44, sp: 1.0, ring: 1 },
    'rare':       { rise: 2150, pop: 2520, n: 19, drops: 70, sp: 1.1, ring: 2 },
    'legendaire': { rise: 3300, pop: 3900, n: 30, drops: 120, sp: 1.15, ring: 3 }
  };
  var BTINT = {
    'commun': ['rgba(220,238,255,.95)', 'rgba(150,200,240,.55)', 'rgba(255,255,255,.9)', 'rgba(170,215,250,.5)'],
    'peu-commun': ['rgba(190,255,225,.95)', 'rgba(110,220,185,.55)', 'rgba(235,255,245,.9)', 'rgba(120,225,200,.5)'],
    'rare': ['rgba(180,170,255,.95)', 'rgba(120,200,255,.6)', 'rgba(235,225,255,.9)', 'rgba(150,140,255,.55)'],
    'legendaire': ['rgba(255,226,140,1)', 'rgba(244,160,70,.85)', 'rgba(255,248,215,1)', 'rgba(206,238,176,.85)', 'rgba(255,200,95,.95)', 'rgba(255,170,150,.8)', 'rgba(255,236,170,1)', 'rgba(210,140,40,.75)']
  };

  function monterC(el, ctx) {
    var S = base(el, ctx, 'C');
    var rk = S.rk, R = S.R, T = CT[rk];
    S.uiA = Math.min(T.pop + 220, S.D - 340);
    S.events = [{ t: 0, id: 'bulles' }];
    if (rk === 'legendaire') S.events.push({ t: T.rise - 700, id: 'montee' });
    S.events.push({ t: T.pop, id: 'carte-' + rk });

    S.front.el.classList.remove(P + 'flipped');
    var bubble = mk('div', 'bubble');
    var btint = mk('div', 'btint'), brim = mk('div', 'brim'), birid = mk('div', 'birid');
    brim.appendChild(birid);
    var h1 = mk('div', 'bhl1'), h2 = mk('div', 'bhl2'), h3 = mk('div', 'bhl3');
    bubble.appendChild(btint); bubble.appendChild(brim); bubble.appendChild(h3); bubble.appendChild(h1); bubble.appendChild(h2);
    S.stage.appendChild(bubble);
    var rimStops = BTINT[rk];
    var conic = rimStops.concat(rimStops[0]);
    var cs = conic.map(function (c, i) { return c + ' ' + Math.round(i / (conic.length - 1) * 100) + '%'; }).join(',');
    birid.style.background = 'conic-gradient(' + cs + ')';
    var rim2 = rk === 'legendaire' ? 'rgba(255,214,120,.9)' : rk === 'rare' ? 'rgba(160,150,255,.8)' : rk === 'peu-commun' ? 'rgba(140,235,200,.8)' : 'rgba(210,235,255,.85)';
    btint.style.background = 'radial-gradient(closest-side,rgba(156,199,234,0) 56%,' + (rk === 'legendaire' ? 'rgba(255,200,100,.16)' : rk === 'rare' ? 'rgba(150,140,255,.15)' : rk === 'peu-commun' ? 'rgba(120,225,190,.14)' : 'rgba(111,195,255,.14)') + ' 82%,' + (rk === 'legendaire' ? 'rgba(255,214,130,.34)' : 'rgba(199,223,243,.28)') + ' 97%,rgba(255,255,255,0) 100%),radial-gradient(circle at 68% 80%,rgba(199,223,243,.22),rgba(199,223,243,0) 40%)';
    brim.style.boxShadow = 'none';
    var bglow = rk === 'legendaire' ? '0 0 26px rgba(240,184,66,.4)' : '0 0 18px rgba(111,195,255,.2)';
    bubble.style.filter = 'drop-shadow(' + bglow.replace(/ rgba/, ' rgba') + ')';

    /* bulles autour */
    var rnd = mulberry(2024 + rk.length), sb = [];
    for (var i = 0; i < T.n; i++) {
      var big = rnd() < .18;
      sb.push({
        r: big ? 14 + rnd() * 14 : 3 + rnd() * 10.5,
        x: .5 + (rnd() + rnd() - 1) * .56,
        d: rnd() * T.rise * .88, v: (210 + rnd() * 300) * T.sp,
        A: 4 + rnd() * 11, f: 1.0 + rnd() * 1.6, ph: rnd() * 6.28, front: rnd() < .22
      });
    }
    var plank = [];
    for (var j = 0; j < 46; j++) plank.push({ x: rnd(), y: rnd(), r: .5 + rnd() * 1.1, a: .12 + rnd() * .3, ph: rnd() * 6.28, sp: .3 + rnd() * .9 });
    /* gouttes du éclatement */
    var drops = [], dr = mulberry(555);
    for (var k = 0; k < T.drops; k++) {
      var an = dr() * 6.2832, q2 = dr(), spd = 70 + Math.pow(q2, 1.6) * 520 * (rk === 'legendaire' ? 1.1 : 1);
      drops.push({ a: an, s: spd, r: .8 + dr() * 2.6, life: 500 + dr() * 700, up: 20 + dr() * 190, k: .5 + dr() * .5, gold: rk === 'legendaire' && dr() < .6, rare: rk === 'rare' && dr() < .4 });
    }
    var motes = [];
    for (var m = 0; m < 34; m++) motes.push({ x: (dr() - .5) * 1.1, y: .08 + dr() * .6, v: 26 + dr() * 64, sw: 6 + dr() * 14, f: .7 + dr() * 1.4, r: 1.3 + dr() * 3.2, life: 2300 + dr() * 2300, b: dr() * 1400, ph: dr() * 6.28 });

    function bubPath(t) {
      var u = S.u, W = S.W, H = S.H;
      var pr = prog(t, 0, T.rise);
      var e = 1 - Math.pow(1 - pr, 1.9);
      var y0 = H + S.ch * .5 - S.cy;
      var sw = prog(t, T.rise, T.pop);
      var wob = (S.W * .062) * Math.pow(1 - pr, .8) + 3 * u * (1 - sw);
      var bx = wob * Math.sin(2 * Math.PI * 1.15 * t / 1000 + .6) + Math.sin(t / 700) * 2.4 * u * (1 - sw);
      var by = lerp(y0, 0, e) + Math.sin(2 * Math.PI * .7 * t / 1000) * 3 * u * pr * (1 - sw);
      var s = lerp(.42, 1, eO2(pr));
      var q = (.03 + .07 * sw * sw) * Math.sin(2 * Math.PI * (2.6 + sw * 6) * t / 1000);
      var pulse = 1 + .08 * eI2(sw);
      return { x: bx, y: by, sx: s * pulse * (1 + q), sy: s * pulse * (1 - q), s: s, sw: sw, rot: Math.sin(t / 560) * 5 * (1 - pr * .5) };
    }

    S.render = function (t) {
      var W = S.W, H = S.H, u = S.u, cw = S.cw, ch = S.ch, cx = S.cx, cy = S.cy, c = S.xB, f = S.xF, tt = S.static ? 6000 : t;
      c.clearRect(0, 0, W, H); f.clearRect(0, 0, W, H);
      var popped = t >= T.pop, tp = t - T.pop;

      /* eau sombre : dégradé, rais de lumière, plancton */
      var g = c.createLinearGradient(0, 0, 0, H);
      g.addColorStop(0, '#0C4272'); g.addColorStop(.38, '#082F55'); g.addColorStop(1, '#04122B');
      c.fillStyle = g; c.fillRect(0, 0, W, H);
      c.save(); c.globalCompositeOperation = 'lighter';
      for (var s = 0; s < 4; s++) {
        var sx = W * (.12 + s * .27) + Math.sin(tt / 2600 + s * 1.7) * W * .05, wd = W * (.1 + .05 * (s % 2));
        var sg = c.createLinearGradient(0, 0, 0, H * .85);
        sg.addColorStop(0, 'rgba(156,199,234,' + (.075 + .02 * Math.sin(tt / 1900 + s)) + ')'); sg.addColorStop(1, 'rgba(156,199,234,0)');
        c.fillStyle = sg; c.beginPath();
        c.moveTo(sx - wd * .4, 0); c.lineTo(sx + wd * .4, 0); c.lineTo(sx + wd * 1.6 + W * .12, H * .85); c.lineTo(sx - wd * .9 + W * .12, H * .85); c.closePath(); c.fill();
      }
      c.restore();
      for (var i = 0; i < plank.length; i++) {
        var p = plank[i], tw = .5 + .5 * Math.sin(tt / 1000 * p.sp * 2 + p.ph);
        c.fillStyle = 'rgba(199,223,243,' + (p.a * tw) + ')';
        c.beginPath(); c.arc(p.x * W + Math.sin(tt / 3500 + p.ph) * 7 * u, ((p.y * H - tt / 1000 * 5 * u * p.sp) % H + H) % H, p.r * u, 0, 6.2832); c.fill();
      }

      /* petites bulles */
      for (var b = 0; b < sb.length; b++) {
        var o = sb[b], tau = t - o.d;
        if (S.static) tau = 100000;
        if (tau < 0) continue;
        var period = ((H + 80 * u) / (o.v * u) * 1000) + 600;
        var loopOk = b < 5;
        if (tau * o.v * u / 1000 > H + 60 * u) { if (!loopOk || t < T.pop) continue; tau = tau % period; }
        if (S.static && b > 4) continue;
        var by2 = H + o.r * u - o.v * u * tau / 1000, gr = Math.min(1, tau / 4000);
        var rr = o.r * u * (1 + .3 * (1 - by2 / H));
        var bx2 = o.x * W + Math.sin(tau / 1000 * o.f * 2 + o.ph) * o.A * u * (1 + (1 - by2 / H) * .5);
        var fadeIn = c01(tau / 220);
        drawBub(o.front ? f : c, bx2, by2, rr, fadeIn * (o.front ? .55 : .85), rk, tau);
      }

      /* la grande bulle */
      var bp = bubPath(t), bw = cw * 1.2, bh = ch * 1.1;
      var inBub = t < T.pop + 70;
      var rise = prog(t, 0, T.rise);
      if (S.static) { bubble.style.display = 'none'; }
      else if (inBub) {
        bubble.style.display = 'block';
        var burstP = c01((t - T.pop) / 70);
        bubble.style.width = bw + 'px'; bubble.style.height = bh + 'px';
        bubble.style.transform = 'translate(' + (bp.x - bw / 2).toFixed(1) + 'px,' + (bp.y - bh / 2).toFixed(1) + 'px) scale(' + (bp.sx * (1 + .1 * burstP)).toFixed(4) + ',' + (bp.sy * (1 + .1 * burstP)).toFixed(4) + ')';
        bubble.style.opacity = (c01(rise * 6 + .2) * (1 - burstP)).toFixed(3);
        birid.style.transform = 'rotate(' + (t / 40 + bp.x).toFixed(1) + 'deg)';
        var rimA = rk === 'legendaire' ? 1 : .8;
        brim.style.opacity = (rimA * (.85 + .15 * bp.sw)).toFixed(3);
      } else bubble.style.display = 'none';

      /* la carte dans la bulle, puis libre */
      var cs, cbx, cby, crot, blur, cop, cl = c01(rise * 5);
      if (S.static) { cs = 1; cbx = 0; cby = 0; crot = 0; blur = 0; cop = 1; }
      else if (!popped) {
        cs = .76 * bp.s * (1 + .08 * eI2(bp.sw)); cbx = bp.x; cby = bp.y; crot = bp.rot; cop = .92 * cl;
        blur = lerp(10, 5.5, eO2(rise)) * u * (1 - .35 * bp.sw);
      } else {
        var us = tp / 620;
        var sp = us >= 1 ? 1 : spring(us, .5, 11);
        cs = lerp(.76 * (1 + .08), 1, sp); cbx = 0; crot = 0; cop = 1;
        cby = -17 * u * Math.exp(-tp / 330) * Math.sin(2 * Math.PI * tp / 700) * (1 + (rk === 'legendaire' ? .3 : 0)) - 0;
        blur = 7 * u * Math.exp(-tp / 55);
        if (blur < .12) blur = 0;
      }
      S.lift.style.transform = 'translate(' + cbx.toFixed(2) + 'px,' + cby.toFixed(2) + 'px) rotate(' + crot.toFixed(2) + 'deg) scale(' + cs.toFixed(4) + ')';
      S.lift.style.opacity = cop.toFixed(3);
      S.lift.style.filter = blur > 0 ? 'blur(' + blur.toFixed(2) + 'px) saturate(1.1)' : 'none';
      var tiltAmt = S.static ? 1 : sstep(prog(t, T.pop + 120, T.pop + 760));
      S.stepTilt(tt, tiltAmt);
      S.flip.style.transform = 'rotateX(' + (S.rotX || 0).toFixed(2) + 'deg) rotateY(' + (S.rotY || 0).toFixed(2) + 'deg)';
      if (popped && !S.static && tp < 60 + 1) S.front.shine.style.opacity = 0;
      var shn = prog(t, T.pop + 60, T.pop + 800);
      S.front.shine.style.opacity = (shn > 0 && shn < 1 && !S.static) ? (Math.sin(Math.PI * shn) * (rk === 'commun' ? .4 : .75)).toFixed(3) : 0;
      S.front.shine.style.backgroundPosition = lerp(100, 0, eIO(shn)) + '% 0';

      /* halo et ombre */
      var halo = S.static ? .3 : (popped ? sstep(prog(t, T.pop, T.pop + 500)) * (rk === 'commun' ? .25 : rk === 'peu-commun' ? .35 : .55) + Math.exp(-tp / 500) * .5 : 0);
      S.aura.style.boxShadow = halo > .01 ? '0 0 ' + (cw * (.14 + halo * .2)).toFixed(1) + 'px ' + (cw * halo * .04).toFixed(1) + 'px ' + rgba(R.glow, c01(halo * (rk === 'commun' ? .5 : .85)).toFixed(3)) : 'none';
      S.aura.style.transform = S.lift.style.transform; S.aura.style.opacity = S.static ? 1 : (popped ? 1 : 0);
      S.ground.style.opacity = S.static ? .9 : (popped ? (sstep(prog(t, T.pop, T.pop + 300)) * .9).toFixed(3) : 0);
      S.ground.style.transform = 'scale(' + (1 - (-cby > 0 ? Math.min(.2, -cby / (60 * u)) : 0)).toFixed(3) + ')';

      /* éclatement : anneau, éclaboussure, éclat */
      if (popped && !S.static) {
        var cxb = cx + bp.x * 0, cyb = cy; /* la bulle éclate à sa dernière position */
        var ep = bubPath(T.pop);
        var ex = cx + ep.x, ey = cy + ep.y, rx = bw / 2 * ep.sx * 1.1, ry = bh / 2 * ep.sy * 1.1;
        var ringN = T.ring, ringRgb = rk === 'legendaire' ? '255,218,130' : rk === 'rare' ? '175,165,255' : rk === 'peu-commun' ? '150,240,205' : '215,238,255';
        f.save(); f.globalCompositeOperation = 'lighter';
        for (var rg = 0; rg < ringN; rg++) {
          var pr2 = prog(tp, rg * 90, rg * 90 + 640 + rg * 100);
          if (pr2 <= 0 || pr2 >= 1) continue;
          var ee = eO3(pr2), ex2 = 1 + (.26 + rg * .13) * ee;
          f.strokeStyle = 'rgba(' + ringRgb + ',' + ((1 - pr2) * (rg ? .55 : .95)) + ')';
          f.lineWidth = Math.max(.5, (rg ? 3 : 5.2) * u * (1 - pr2));
          f.beginPath(); f.ellipse(ex, ey, rx * ex2, ry * ex2, 0, 0, 6.2832); f.stroke();
        }
        var fl = Math.exp(-tp / 70);
        if (fl > .02) {
          var fg = f.createRadialGradient(ex, ey, 0, ex, ey, Math.max(rx, ry));
          fg.addColorStop(0, 'rgba(' + ringRgb + ',' + (fl * .32) + ')'); fg.addColorStop(1, 'rgba(' + ringRgb + ',0)');
          f.fillStyle = fg; f.fillRect(0, 0, W, H);
        }
        /* gouttes en parabole */
        var G = 1250 * u;
        for (var d = 0; d < drops.length; d++) {
          var dd = drops[d], tau2 = tp / 1000, life = dd.life / 1000;
          if (tau2 > life) continue;
          var nx = Math.cos(dd.a), ny = Math.sin(dd.a);
          var x0 = ex + nx * rx * dd.k, y0 = ey + ny * ry * dd.k;
          var vx = nx * dd.s * u, vy = ny * dd.s * u - dd.up * u;
          var X = x0 + vx * tau2, Y = y0 + vy * tau2 + .5 * G * tau2 * tau2;
          var vyi = vy + G * tau2, sp2 = Math.hypot(vx, vyi);
          var al = Math.pow(1 - tau2 / life, .8);
          var col = dd.gold ? '255,222,140' : dd.rare ? '190,180,255' : '225,242,255';
          f.strokeStyle = 'rgba(' + col + ',' + (al * .95) + ')'; f.lineWidth = dd.r * u * (1 - .4 * tau2 / life); f.lineCap = 'round';
          var tl = Math.min(.016, .006 + sp2 / 90000);
          f.beginPath(); f.moveTo(X, Y); f.lineTo(X - vx * tl, Y - vyi * tl); f.stroke();
          f.fillStyle = 'rgba(255,255,255,' + (al * .7) + ')'; f.beginPath(); f.arc(X, Y, dd.r * u * .45, 0, 6.2832); f.fill();
        }
        f.restore();
        if (rk === 'legendaire') {
          f.save(); f.globalCompositeOperation = 'lighter';
          for (var k2 = 0; k2 < motes.length; k2++) {
            var mo = motes[k2], age = t - T.pop - mo.b * .4;
            if (age < 0) continue;
            var fr = (age % mo.life) / mo.life;
            var al2 = Math.sin(Math.PI * fr) * (.55 + .45 * Math.sin(age / 130 * mo.f + mo.ph));
            var mx = cx + mo.x * cw * .6 + Math.sin(age / 1000 * mo.f * 2 + mo.ph) * mo.sw * u;
            var my = cy + ch * (mo.y - .15) - (age % mo.life) / 1000 * mo.v * u * 1.7;
            glowDot(f, '255,222,140', mx, my, mo.r * 3.4 * u, c01(al2));
          }
          f.restore();
        }
      } else if (S.static && rk === 'legendaire') {
        f.save(); f.globalCompositeOperation = 'lighter';
        for (var k3 = 0; k3 < 14; k3++) { var mo2 = motes[k3]; glowDot(f, '255,222,140', cx + mo2.x * cw * .62, cy + ch * (mo2.y - .2), mo2.r * 3 * u, .55); }
        f.restore();
      }
      /* éclat doré qui court sur le bord (légendaire) */
      if (rk === 'legendaire') {
        var sp3 = S.static ? -1 : (t - (T.pop + 380)) / 1700;
        if (sp3 >= 0) sp3 = sp3 % 3.2;
        S.front.edge.style.opacity = (sp3 >= 0 && sp3 < 1) ? Math.sin(Math.PI * sp3).toFixed(3) : 0;
        S.front.edge.style.backgroundPosition = lerp(86, 14, eIO(Math.max(0, sp3))) + '% 0, 0 0';
      }
      frontIdle(S.front, tt, rk);
      S.uiRender(S.static ? S.D + 99 : t);
    };

    function drawBub(c, x, y, r, a, rk, tau) {
      if (r < .6) return;
      c.save(); c.globalAlpha = a;
      var rimC = rk === 'legendaire' ? '255,228,150' : rk === 'rare' ? '200,196,255' : rk === 'peu-commun' ? '190,250,225' : '225,242,255';
      var g = c.createRadialGradient(x, y, r * .5, x, y, r);
      g.addColorStop(0, 'rgba(' + rimC + ',0)'); g.addColorStop(.8, 'rgba(' + rimC + ',.10)'); g.addColorStop(.96, 'rgba(' + rimC + ',.42)'); g.addColorStop(1, 'rgba(' + rimC + ',.12)');
      c.fillStyle = g; c.beginPath(); c.arc(x, y, r, 0, 6.2832); c.fill();
      c.strokeStyle = 'rgba(' + rimC + ',.55)'; c.lineWidth = Math.max(.6, r * .07);
      c.beginPath(); c.arc(x, y, r * .985, 0, 6.2832); c.stroke();
      c.strokeStyle = 'rgba(255,255,255,.85)'; c.lineWidth = Math.max(.8, r * .13); c.lineCap = 'round';
      c.beginPath(); c.arc(x, y, r * .7, Math.PI * 1.08, Math.PI * 1.46); c.stroke();
      c.strokeStyle = 'rgba(255,255,255,.28)'; c.lineWidth = Math.max(.6, r * .08);
      c.beginPath(); c.arc(x, y, r * .72, Math.PI * .1, Math.PI * .3); c.stroke();
      c.restore();
    }

    S.onReset = function () { };
    S.layout();
    S.reset();
    return S.api;
  }

  /* ---------- déclarations ---------- */
  var OPT = [{ cle: 'rarete', valeurs: ['commun', 'peu-commun', 'rare', 'legendaire'] }];
  FM.anims.push({
    id: 'arrivee-dos-carte', groupe: 'arrivee', lettre: 'B', nom: 'Le dos de la carte',
    resume: 'Ta photo rétrécit et vient se glisser dans le dos de la carte (bleu marine, lune et poisson gravés). Le dos tremble, une ligne de lumière s’ouvre, puis la carte se retourne et montre le poisson.',
    ou: 'E6, révélation de la carte juste après la confirmation de la prise.',
    duree: '1,6 s (commun) à 4,5 s (légendaire)',
    swiftui: 'La photo rétrécit avec matchedGeometryEffect vers le dos de la carte. Le tremblement est un PhaseAnimator (rare : 3° deux fois, légendaire : plus fort avec une lueur de bord qui monte). Le retournement est un KeyframeAnimator sur rotation3DEffect (axe Y, perspective 0,6) avec un ressort ; le recto remplace le dos à 90°. Les rayons et les braises sont un Canvas dans un TimelineView. Le reflet holographique est un .layerEffect (shader Metal) piloté par CoreMotion. Chaque temps fort a son sensoryFeedback (.impact pour le tremblement, .success à l’arrivée). Avec Réduire les animations : fondu de 0,4 s vers la carte face visible, lueur fixe.',
    format: 'telephone', fond: 'nuit', options: OPT,
    monter: monterB
  });
  FM.anims.push({
    id: 'arrivee-bulle', groupe: 'arrivee', lettre: 'C', nom: 'Bulle',
    resume: 'Une grande bulle monte du fond d’une eau sombre, entourée de petites bulles. La carte est dedans, floue. La bulle grossit, éclate en gouttelettes, et la carte reste là, qui flotte un instant.',
    ou: 'E6, révélation de la carte juste après la confirmation de la prise.',
    duree: '1,6 s (commun) à 4,5 s (légendaire)',
    swiftui: 'La bulle est une vue ovale animée par un KeyframeAnimator (montée, balancement, gonflement). Les petites bulles et les gouttelettes sont un Canvas dans un TimelineView (trajectoires en parabole). La carte est floue avec .blur(radius:) qui tombe à zéro à l’éclatement, puis un ressort la fait grossir. Le bord doré irisé du légendaire est un dégradé angulaire qui tourne. Reflet holographique en .layerEffect avec CoreMotion. sensoryFeedback : .impact léger à l’éclatement, .success à la fin. Avec Réduire les animations : fondu de 0,4 s vers la carte posée, lueur fixe.',
    format: 'telephone', fond: 'nuit', options: OPT,
    monter: monterC
  });
})();
