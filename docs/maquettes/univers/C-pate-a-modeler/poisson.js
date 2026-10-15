/* Poissons en pâte à modeler (SVG généré). Lumière unique : haut gauche (azimut 225).
   Le relief vient d'un filtre feDiffuseLighting sur l'alpha flouté + grain feTurbulence,
   la rareté change la matière (mat / satiné / vernis) via le filtre spéculaire. */
(function () {
  const RAR = { commun: 0, peu: 1, rare: 2, legendaire: 3 };

  // Matières : [flou, relief, constante spéculaire, exposant spéculaire, grain]
  const MAT = [
    [4.5, 5.5, 0, 0, 0.30],      // mat : grain visible, aucun reflet
    [5.0, 6.5, 0.28, 7, 0.20],   // satiné : reflet large et doux
    [5.0, 7.5, 0.8, 26, 0.12],   // vernis : reflets serrés, humides
    [5.0, 7.5, 0.85, 30, 0.12]    // vernis + paillettes (les paillettes sont dessinées à part)
  ];

  function filtre(id, m) {
    const [bl, sc, spC, spE, gr] = m;
    const spec = spC > 0
      ? `<feSpecularLighting in="bump" surfaceScale="${sc}" specularConstant="${spC}" specularExponent="${spE}" lighting-color="#fff" result="sp"><feDistantLight azimuth="225" elevation="52"/></feSpecularLighting>
         <feComposite in="sp" in2="SourceAlpha" operator="in" result="sp2"/>
         <feComposite in="sh" in2="sp2" operator="arithmetic" k1="0" k2="1" k3="1" k4="0" result="fin"/>`
      : `<feOffset in="sh" result="fin"/>`;
    return `<filter id="${id}" x="-8%" y="-14%" width="118%" height="132%" color-interpolation-filters="sRGB">
      <feGaussianBlur in="SourceAlpha" stdDeviation="${bl}" result="bl"/>
      <feTurbulence type="fractalNoise" baseFrequency=".75" numOctaves="2" seed="4" result="nz"/>
      <feColorMatrix in="nz" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 ${gr} 0" result="nzA"/>
      <feComposite in="bl" in2="nzA" operator="arithmetic" k1="0" k2="1" k3="-1" k4="0" result="bump"/>
      <feDiffuseLighting in="bump" surfaceScale="${sc}" diffuseConstant="1.3" lighting-color="#fff" result="dl"><feDistantLight azimuth="225" elevation="52"/></feDiffuseLighting>
      <feBlend in="SourceGraphic" in2="dl" mode="multiply" result="sh"/>
      ${spec}
      <feComposite in="fin" in2="SourceAlpha" operator="in"/>
    </filter>`;
  }

  function defs() {
    if (document.getElementById('defs-pate')) return;
    const s = document.createElement('div');
    s.id = 'defs-pate';
    s.setAttribute('aria-hidden', 'true');
    s.style.cssText = 'position:absolute;width:0;height:0;overflow:hidden';
    s.innerHTML = `<svg width="0" height="0"><defs>
      ${MAT.map((m, i) => filtre('puff' + i, m)).join('')}
      <filter id="ombre" x="-10%" y="-10%" width="125%" height="135%"><feDropShadow dx="5" dy="7" stdDeviation="3.5" flood-color="#2a1000" flood-opacity=".38"/></filter>
    </defs></svg>`;
    document.body.prepend(s);
  }

  // Générateur pseudo-aléatoire déterministe
  function prng(a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }

  const ESPECES = {
    brochet: {
      x0: 12, L: 288, yc: 86, Hu: 25, Hd: 26, p: .8, k: .5, ws: .42,
      dos: '#5F9A3A', ventre: '#F0E6A0', nageoire: '#EE8A3C', bord: '#B85E1E',
      queue: { len: 54, h: 34, fourche: .34 },
      fins: [{ c: 'h', a: .72, b: .9, h: 32, lean: 12, n: 4 }, { c: 'b', a: .71, b: .86, h: 26, lean: 12, n: 3 }],
      pec: { t: .27, rx: 20, ry: 8, rot: 30 }, pel: { t: .58, rx: 15, ry: 6, rot: 24 },
      oeil: { t: .105, dy: -9, r: 8.5, iris: '#F4C23A' }, ouie: .2, bouche: { t: .17, y0: 7, y1: 12 }, motif: 'haricots'
    },
    gardon: {
      x0: 24, L: 244, yc: 86, Hu: 36, Hd: 38, p: .66, k: .62, ws: .3,
      dos: '#6F8FB0', ventre: '#EFEBDC', nageoire: '#E8452E', bord: '#A82A18',
      queue: { len: 62, h: 40, fourche: .55 },
      fins: [{ c: 'h', a: .42, b: .58, h: 28, lean: 8, n: 4 }, { c: 'b', a: .66, b: .84, h: 20, lean: 8, n: 4 }],
      pec: { t: .27, rx: 20, ry: 9, rot: 36 }, pel: { t: .5, rx: 18, ry: 8, rot: 34 },
      oeil: { t: .13, dy: -8, r: 10, iris: '#FF7A3D' }, ouie: .23, bouche: { t: .09, y0: 6, y1: 8 }, motif: 'ecailles'
    },
    sandre: {
      x0: 14, L: 272, yc: 86, Hu: 25, Hd: 24, p: .76, k: .52, ws: .4,
      dos: '#7A8A55', ventre: '#E4E2C2', nageoire: '#B7B36C', bord: '#6E6A2E',
      queue: { len: 54, h: 34, fourche: .3 },
      fins: [{ c: 'h', a: .3, b: .5, h: 34, lean: 4, n: 6, pique: true }, { c: 'h', a: .57, b: .72, h: 24, lean: 6, n: 4 }, { c: 'b', a: .7, b: .83, h: 20, lean: 8, n: 3 }],
      pec: { t: .26, rx: 17, ry: 7, rot: 30 }, pel: { t: .45, rx: 14, ry: 6, rot: 24 },
      oeil: { t: .105, dy: -8, r: 10, iris: '#E9E9D8' }, ouie: .2, bouche: { t: .17, y0: 7, y1: 12 }, motif: 'barres'
    },
    perche: {
      x0: 20, L: 250, yc: 86, Hu: 28, Hd: 29, p: .68, k: .56, ws: .34,
      dos: '#6B8F34', ventre: '#EFE3A2', nageoire: '#E9512E', bord: '#A02A12',
      queue: { len: 52, h: 36, fourche: .3 },
      fins: [{ c: 'h', a: .3, b: .5, h: 32, lean: 4, n: 6, pique: true }, { c: 'h', a: .56, b: .72, h: 24, lean: 6, n: 4 }, { c: 'b', a: .68, b: .82, h: 20, lean: 8, n: 3 }],
      pec: { t: .27, rx: 18, ry: 8, rot: 32 }, pel: { t: .48, rx: 16, ry: 7, rot: 28 },
      oeil: { t: .11, dy: -8, r: 9.5, iris: '#F4C23A' }, ouie: .22, bouche: { t: .12, y0: 7, y1: 10 }, motif: 'barres'
    },
    truite: {
      x0: 14, L: 270, yc: 86, Hu: 28, Hd: 30, p: .74, k: .55, ws: .38,
      dos: '#6B6A2C', ventre: '#EBD58E', nageoire: '#B58A3C', bord: '#6A4A12',
      queue: { len: 48, h: 34, fourche: .12 },
      fins: [{ c: 'h', a: .4, b: .54, h: 26, lean: 8, n: 4 }, { c: 'b', a: .68, b: .8, h: 20, lean: 8, n: 3 }],
      pec: { t: .27, rx: 18, ry: 8, rot: 32 }, pel: { t: .52, rx: 14, ry: 6, rot: 26 },
      oeil: { t: .115, dy: -8, r: 8.5, iris: '#F2EFE2' }, ouie: .21, bouche: { t: .15, y0: 7, y1: 11 }, motif: 'truite', adipeuse: .83
    }
  };

  let n = 0;
  const f1 = v => v.toFixed(1);

  function etoile(x, y, r, cls) {
    const a = r * .22;
    return `<path class="${cls || ''}" d="M${f1(x)} ${f1(y - r)}L${f1(x + a)} ${f1(y - a)}L${f1(x + r)} ${f1(y)}L${f1(x + a)} ${f1(y + a)}L${f1(x)} ${f1(y + r)}L${f1(x - a)} ${f1(y + a)}L${f1(x - r)} ${f1(y)}L${f1(x - a)} ${f1(y - a)}Z" fill="#FFC93A" stroke="#9A6A0A" stroke-width=".9" stroke-linejoin="round"/>`;
  }

  /* poisson(espece, rarete, {paillettes}) -> chaîne SVG (viewBox 0 0 360 172) */
  function poisson(nom, rarete, opt) {
    opt = opt || {};
    defs();
    const S = Object.assign({}, ESPECES[nom]), K = nom === 'gardon' ? 1.1 : 1.3; S.Hu *= K; S.Hd *= K;
    const R = RAR[rarete] ?? 0, id = 'p' + (++n);
    const rnd = prng(nom.length * 977 + 13);
    const P = 'url(#puff' + R + ')';
    const sh = t => {
      const s = Math.sin(Math.PI * Math.pow(t, S.p));
      return Math.pow(Math.max(s, 0), S.k) * (1 - Math.pow(t, 5)) + S.ws * Math.pow(t, 5);
    };
    const X = t => S.x0 + S.L * t;
    const top = t => S.yc - S.Hu * sh(t);
    const bot = t => S.yc + S.Hd * sh(t);
    const N = 70;
    let up = '', dn = '';
    for (let i = 0; i <= N; i++) { const t = i / N; up += (i ? 'L' : 'M') + f1(X(t)) + ' ' + f1(top(t)); }
    for (let i = N; i >= 0; i--) { const t = i / N; dn += 'L' + f1(X(t)) + ' ' + f1(bot(t)); }
    const corps = up + dn + 'Z';

    // Queue
    const xb = X(1), q = S.queue, yt = top(1), yb = bot(1);
    const notch = xb + q.len * (1 - q.fourche);
    const queue = `M${f1(xb - 6)} ${f1(yt)}Q${f1(xb + q.len * .5)} ${f1(S.yc - q.h * .95)} ${f1(xb + q.len)} ${f1(S.yc - q.h)}Q${f1(notch + 4)} ${f1(S.yc - q.h * .4)} ${f1(notch)} ${f1(S.yc)}Q${f1(notch + 4)} ${f1(S.yc + q.h * .4)} ${f1(xb + q.len)} ${f1(S.yc + q.h)}Q${f1(xb + q.len * .5)} ${f1(S.yc + q.h * .95)} ${f1(xb - 6)} ${f1(yb)}Z`;
    const rayonsQueue = [-.7, -.35, 0, .35, .7].map(k => `<path d="M${f1(xb + 2)} ${f1(S.yc + k * 8)}L${f1(xb + q.len * .82)} ${f1(S.yc + k * q.h * .8)}"/>`).join('');

    // Nageoires dorsales / anales
    let nagDerriere = '', nagDevant = '';
    S.fins.forEach(f => {
      const haut = f.c === 'h';
      const yA = (haut ? top(f.a) : bot(f.a)) + (haut ? 3 : -3), yB = (haut ? top(f.b) : bot(f.b)) + (haut ? 3 : -3);
      const xA = X(f.a), xB = X(f.b);
      const sg = haut ? -1 : 1;
      const px = (xA + xB) / 2 + f.lean, py = Math.min(yA, yB) * (haut ? 1 : 0) + (haut ? 0 : Math.max(yA, yB)) + sg * f.h;
      const d = f.pique
        ? `M${f1(xA)} ${f1(yA)}L${f1(xA + (xB - xA) * .2)} ${f1(py + 2)}L${f1(xA + (xB - xA) * .4)} ${f1(yA + sg * f.h * .35)}L${f1(xA + (xB - xA) * .6)} ${f1(py + sg * 4)}L${f1(xA + (xB - xA) * .8)} ${f1(yA + sg * f.h * .4)}L${f1(xB)} ${f1(yB)}Z`
        : `M${f1(xA)} ${f1(yA)}Q${f1(xA + 2)} ${f1(py + sg * 4)} ${f1(px)} ${f1(py)}Q${f1(xB + 3)} ${f1(yB + sg * f.h * .45)} ${f1(xB)} ${f1(yB)}Z`;
      let rays = '';
      for (let i = 0; i < f.n; i++) {
        const u = f.n === 1 ? .5 : i / (f.n - 1);
        const bx = xA + (xB - xA) * u, by = yA + (yB - yA) * u;
        const ex = bx + (px - bx) * .78 + (u - .5) * 6, ey = by + (py - by) * .78;
        rays += `<path d="M${f1(bx)} ${f1(by)}L${f1(ex)} ${f1(ey)}"/>`;
      }
      const g = `<g><path d="${d}" fill="${S.nageoire}" stroke="${S.nageoire}" stroke-width="5" stroke-linejoin="round" filter="${P}"/><g class="rai" fill="none" stroke="${S.bord}" stroke-opacity=".55" stroke-width="1.4" stroke-linecap="round">${rays}</g></g>`;
      nagDerriere += g;
    });
    if (S.adipeuse) {
      const t = S.adipeuse, x = X(t), y = top(t) + 2;
      nagDerriere += `<path d="M${f1(x - 7)} ${f1(y)}Q${f1(x - 3)} ${f1(y - 14)} ${f1(x + 3)} ${f1(y - 12)}Q${f1(x + 7)} ${f1(y - 4)} ${f1(x + 8)} ${f1(y)}Z" fill="${S.bord}" stroke="${S.bord}" stroke-width="3" stroke-linejoin="round" filter="${P}"/>`;
    }
    // Nageoires devant (pectorale, pelvienne)
    const nag = (o, ytf) => {
      const x = X(o.t), y = ytf;
      return `<g transform="rotate(${o.rot} ${f1(x)} ${f1(y)})"><ellipse cx="${f1(x + o.rx * .55)}" cy="${f1(y)}" rx="${o.rx}" ry="${o.ry}" fill="${S.nageoire}" filter="${P}"/><path d="M${f1(x + 4)} ${f1(y)}L${f1(x + o.rx * 1.4)} ${f1(y)}M${f1(x + 4)} ${f1(y - 2.5)}L${f1(x + o.rx * 1.3)} ${f1(y - 3.5)}M${f1(x + 4)} ${f1(y + 2.5)}L${f1(x + o.rx * 1.3)} ${f1(y + 3.5)}" stroke="${S.bord}" stroke-opacity=".5" stroke-width="1.2" stroke-linecap="round" fill="none"/></g>`;
    };
    nagDevant = nag(S.pec, S.yc + S.Hd * .32) + nag(S.pel, S.yc + S.Hd * .86);

    // Motifs sur le corps (clippés)
    let motif = '';
    if (S.motif === 'haricots') {
      for (let r = 0; r < 3; r++) for (let i = 0; i < 12; i++) {
        const t = .24 + i * .056 + (r % 2) * .025 + rnd() * .012, y = S.yc - S.Hu * .55 * sh(t) + r * 12 * sh(t) * 1.15 - 2 + rnd() * 2;
        if (r === 2 && t > .8) continue;
        motif += `<ellipse cx="${f1(X(t))}" cy="${f1(y)}" rx="${f1(5 + rnd() * 3)}" ry="${f1(2.6 + rnd())}" transform="rotate(${f1(-8 + rnd() * 16)} ${f1(X(t))} ${f1(y)})" fill="#F3E58C" stroke="#9AB04A" stroke-width=".8"/>`;
      }
    } else if (S.motif === 'ecailles') {
      for (let r = 0; r < 5; r++) for (let i = 0; i < 9; i++) {
        const t = .24 + i * .075 + (r % 2) * .035, y = S.yc - S.Hu * .55 + r * 15;
        if (Math.abs(y - S.yc) > S.Hu * sh(t) - 6) continue;
        motif += `<path d="M${f1(X(t))} ${f1(y - 6)}q6 6 0 12" fill="none" stroke="#1d3350" stroke-opacity=".28" stroke-width="1.6" stroke-linecap="round"/><path d="M${f1(X(t) - 1)} ${f1(y - 6)}q6 6 0 12" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="1" stroke-linecap="round"/>`;
      }
    } else if (S.motif === 'barres') {
      for (let i = 0; i < 6; i++) {
        const t = .24 + i * .105, x = X(t), h = S.Hu * sh(t);
        motif += `<path d="M${f1(x - 6)} ${f1(S.yc - h - 4)}Q${f1(x + 4)} ${f1(S.yc - h * .3)} ${f1(x - 2)} ${f1(S.yc + h * .25)}Q${f1(x + 10)} ${f1(S.yc - h * .3)} ${f1(x + 8)} ${f1(S.yc - h - 4)}Z" fill="#3E4A2A" fill-opacity=".72"/>`;
      }
    } else if (S.motif === 'truite') {
      motif += `<path d="M${f1(X(.2))} ${f1(S.yc + 1)}Q${f1(X(.55))} ${f1(S.yc - 5)} ${f1(X(.97))} ${f1(S.yc + 2)}" fill="none" stroke="#F09A8A" stroke-opacity=".7" stroke-width="7" stroke-linecap="round"/>`;
      for (let i = 0; i < 34; i++) {
        const t = .2 + rnd() * .76, h = S.Hu * sh(t);
        const y = S.yc + (rnd() * 2 - 1) * h * .78 - 2;
        const rouge = rnd() > .55;
        motif += rouge
          ? `<circle cx="${f1(X(t))}" cy="${f1(y)}" r="5.2" fill="#BFE3F0" fill-opacity=".85"/><circle cx="${f1(X(t))}" cy="${f1(y)}" r="3" fill="#E5352B"/>`
          : `<circle cx="${f1(X(t))}" cy="${f1(y)}" r="2.3" fill="#2a2312" fill-opacity=".75"/>`;
      }
    }

    // Œil, bouche, ouïe : incisions faites à l'outil
    const ox = X(S.oeil.t) + 4, oy = S.yc + S.oeil.dy, r = S.oeil.r;
    const ouieX = X(S.ouie);
    const bx0 = X(.005), bx1 = X(S.bouche.t);
    const trait = `<path d="M${f1(bx0 + 1)} ${f1(S.yc + S.bouche.y0)}Q${f1((bx0 + bx1) / 2)} ${f1(S.yc + S.bouche.y1 + 3)} ${f1(bx1)} ${f1(S.yc + S.bouche.y1 - 2)}" fill="none" stroke="#2a1000" stroke-opacity=".6" stroke-width="2.2" stroke-linecap="round"/>
      <path d="M${f1(bx0 + 2)} ${f1(S.yc + S.bouche.y0 + 2.4)}Q${f1((bx0 + bx1) / 2)} ${f1(S.yc + S.bouche.y1 + 5.4)} ${f1(bx1)} ${f1(S.yc + S.bouche.y1)}" fill="none" stroke="#fff" stroke-opacity=".4" stroke-width="1.2" stroke-linecap="round"/>
      <path d="M${f1(ouieX)} ${f1(S.yc - S.Hu * .8)}Q${f1(ouieX - 15)} ${f1(S.yc)} ${f1(ouieX)} ${f1(S.yc + S.Hd * .8)}" fill="none" stroke="#2a1000" stroke-opacity=".5" stroke-width="2.4" stroke-linecap="round"/>
      <path d="M${f1(ouieX + 2)} ${f1(S.yc - S.Hu * .8)}Q${f1(ouieX - 13)} ${f1(S.yc)} ${f1(ouieX + 2)} ${f1(S.yc + S.Hd * .8)}" fill="none" stroke="#fff" stroke-opacity=".38" stroke-width="1.3" stroke-linecap="round"/>`;
    const oeil = `<g filter="${P}"><circle cx="${f1(ox)}" cy="${f1(oy)}" r="${r}" fill="#fff"/></g>
      <circle cx="${f1(ox)}" cy="${f1(oy)}" r="${f1(r * .86)}" fill="none" stroke="${S.oeil.iris}" stroke-width="${f1(r * .3)}" stroke-opacity=".9"/>
      <circle cx="${f1(ox + 1)}" cy="${f1(oy + 1.2)}" r="${f1(r * .5)}" fill="#1a0d05"/>
      <circle cx="${f1(ox - r * .22)}" cy="${f1(oy - r * .25)}" r="${f1(r * .2)}" fill="#fff"/>`;

    // Empreintes : deux pouces posés sur le dos et la queue
    const emp = `<g clip-path="url(#c${id})" opacity=".85">
      <image href="empreinte.svg" x="${f1(X(.4) - 26)}" y="${f1(S.yc - 40)}" width="52" height="70" transform="rotate(-24 ${f1(X(.4))} ${f1(S.yc)})"/>
      <image href="empreinte.svg" x="${f1(X(.72) - 20)}" y="${f1(S.yc - 6)}" width="40" height="54" transform="rotate(32 ${f1(X(.72))} ${f1(S.yc + 20)})"/></g>`;

    // Paillettes dorées (légendaire)
    let paillettes = '';
    if (R === 3 || opt.paillettes) {
      for (let i = 0; i < 16; i++) {
        const t = .12 + rnd() * .84, y = S.yc + (rnd() * 2 - 1) * S.Hu * sh(t) * .85;
        paillettes += etoile(X(t), y, 2.4 + rnd() * 2.6, 'scint s' + (i % 4));
      }
      paillettes += etoile(X(.46), S.yc - S.Hu - 6, 9, 'scint s1') + etoile(X(.88), S.yc + S.Hd - 4, 7, 'scint s3');
    }

    return `<svg class="poisson" viewBox="0 0 360 172" xmlns="http://www.w3.org/2000/svg" role="img" aria-label="${nom}">
    <defs>
      <clipPath id="c${id}"><path d="${corps}"/></clipPath>
      <linearGradient id="g${id}" x1="0" y1="0" x2="0" y2="1"><stop offset=".02" stop-color="${S.dos}"/><stop offset=".5" stop-color="${S.dos}"/><stop offset=".66" stop-color="${S.ventre}"/></linearGradient>
      <radialGradient id="l${id}" cx=".3" cy=".22" r=".85"><stop offset="0" stop-color="#fff" stop-opacity=".34"/><stop offset=".5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#3a1500" stop-opacity=".30"/></radialGradient>
    </defs>
    <g filter="url(#ombre)">
      <path d="${queue}" fill="${S.nageoire}" stroke="${S.nageoire}" stroke-width="5" stroke-linejoin="round" filter="${P}"/>
      <g fill="none" stroke="${S.bord}" stroke-opacity=".55" stroke-width="1.4" stroke-linecap="round">${rayonsQueue}</g>
      ${nagDerriere}
      <path d="${corps}" fill="url(#g${id})" stroke="url(#g${id})" stroke-width="2" stroke-linejoin="round" filter="${P}"/>
      <path d="${corps}" fill="url(#l${id})"/>
      <g clip-path="url(#c${id})">${motif}</g>
      ${emp}
      ${trait}
      ${nagDevant}
      ${oeil}
    </g>
    ${paillettes}
    </svg>`;
  }

  window.Pate = { poisson, defs, etoile };
})();
