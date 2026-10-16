(function () {
  'use strict';
  const $ = (s, r = document) => r.querySelector(s);
  const lire = (k, d) => { try { const v = localStorage.getItem('fm-mvt-' + k); return v == null ? d : JSON.parse(v); } catch (e) { return d; } };
  const ecrire = (k, v) => { try { localStorage.setItem('fm-mvt-' + k, JSON.stringify(v)); } catch (e) {} };

  const NOMS_GROUPES = { lancement: 'Lancement', arrivee: 'Arrivée d’une carte', attente: 'Petites attentes', carte: 'Carte qui charge', reconnaissance: 'Reconnaissance photo' };
  const RARETES = [['commun', 'Commun'], ['peu-commun', 'Peu commun'], ['rare', 'Rare'], ['legendaire', 'Légendaire']];
  const BOUCLE_AUTO = { lancement: 6500, arrivee: 9000, reconnaissance: 6500 };

  let reduit = lire('reduit', null);
  if (reduit == null) reduit = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const choix = lire('choix', {});          // groupe -> id d'animation
  FM.choixSons = lire('sons', {});           // moment -> id de son

  // Logo de l'en-tête
  if (window.FMAssets) $('#tete-logo').innerHTML = FMAssets.logoSVG;

  const toast = (t) => { const el = $('#toast'); el.textContent = t; el.classList.add('vu'); clearTimeout(toast.t); toast.t = setTimeout(() => el.classList.remove('vu'), 1800); };

  /* ---------- Scènes animées ---------- */
  const scenes = [];
  function creerFiche(a) {
    const fiche = document.createElement('article');
    fiche.className = 'var' + (a.format === 'tuile' ? ' tuile' : '');
    fiche.id = 'v-' + a.id;
    const opts = a.options && a.options.find(o => o.cle === 'rarete');
    fiche.innerHTML = `
      <div class="scene-cadre"><div class="scene ${a.format === 'tuile' ? 'tuile-sc' : 'telephone'} ${a.fond === 'clair' ? 'clair' : 'nuit'}" role="button" tabindex="0" aria-label="Rejouer ${a.nom} avec le son"></div></div>
      ${opts ? `<div class="seg" role="group" aria-label="Rareté">${RARETES.map(([k, n]) => `<button type="button" data-r="${k}" aria-pressed="${k === 'rare'}"><i class="r-${k}"></i>${n}</button>`).join('')}</div>` : ''}
      <div class="var-tete"><span class="lettre">${a.lettre}</span><h3>${a.nom}</h3></div>
      <p class="resume">${a.resume || ''}</p>
      <dl class="meta"><dt>Où</dt><dd>${a.ou || ''}</dd><dt>Durée</dt><dd>${a.duree || ''}</dd></dl>
      <details><summary>En SwiftUI</summary><p>${a.swiftui || ''}</p></details>
      <div class="actions">
        <button class="bouton" type="button" data-rejouer><svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><path d="M2.5 8a5.5 5.5 0 1 0 1.7-4"/><path d="M2.5 2.5v3h3"/></svg>Rejouer</button>
        <label class="choix"><input type="radio" name="g-${a.groupe}" id="c-${a.id}" value="${a.id}"><span>Je prends ${a.lettre}</span></label>
      </div>`;
    const sc = { a, fiche, el: fiche.querySelector('.scene'), inst: null, arme: false, rarete: 'rare', visible: false, timer: null };
    const radio = fiche.querySelector('input[type=radio]');
    radio.checked = choix[a.groupe] === a.id;
    fiche.classList.toggle('choisie', radio.checked);
    radio.addEventListener('change', () => {
      choix[a.groupe] = a.id; ecrire('choix', choix);
      document.querySelectorAll(`input[name="g-${a.groupe}"]`).forEach(r => r.closest('.var').classList.toggle('choisie', r.checked));
      majChoix(); toast(`${NOMS_GROUPES[a.groupe] || a.groupe} : ${a.lettre} retenue`);
    });
    const rejouerArme = () => { sc.arme = true; activerSonSiBesoin(); rejouer(sc); };
    fiche.querySelector('[data-rejouer]').addEventListener('click', rejouerArme);
    sc.el.addEventListener('click', () => { if (!sc.inst) return; sc.arme = true; activerSonSiBesoin(); planifier(sc); });
    sc.el.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); rejouerArme(); } });
    if (opts) fiche.querySelectorAll('.seg button').forEach(b => b.addEventListener('click', () => {
      fiche.querySelectorAll('.seg button').forEach(x => x.setAttribute('aria-pressed', x === b));
      sc.rarete = b.dataset.r; sc.arme = true; activerSonSiBesoin(); monter(sc);
    }));
    scenes.push(sc);
    return fiche;
  }

  function contexte(sc) {
    return { reduit, option: { rarete: sc.rarete }, son: (m) => { if (sc.arme) FM.son(m); } };
  }
  function monter(sc) {
    demonter(sc);
    try { sc.inst = sc.a.monter(sc.el, contexte(sc)) || null; }
    catch (e) { console.error(sc.a.id, e); sc.el.innerHTML = '<div class="scene-vide">Cette scène n’a pas pu démarrer.</div>'; }
    planifier(sc);
  }
  function demonter(sc) {
    clearTimeout(sc.timer);
    if (sc.inst && sc.inst.arreter) { try { sc.inst.arreter(); } catch (e) {} }
    sc.inst = null; sc.el.innerHTML = '';
  }
  function rejouer(sc) {
    if (!sc.inst) return monter(sc);
    try { sc.inst.rejouer && sc.inst.rejouer(); } catch (e) { console.error(e); }
    planifier(sc);
  }
  // Les scènes non-bouclées repartent seules, sans son. Un toucher les arme : le prochain passage sonne.
  function planifier(sc) {
    clearTimeout(sc.timer);
    const delai = BOUCLE_AUTO[sc.a.groupe];
    if (!delai || reduit) return;
    sc.timer = setTimeout(() => { if (!sc.visible) return planifier(sc); sc.arme = false; rejouer(sc); }, sc.arme ? 120000 : delai);
  }

  const obs = new IntersectionObserver((entrees) => {
    for (const e of entrees) {
      const sc = scenes.find(s => s.el === e.target);
      if (!sc) continue;
      sc.visible = e.isIntersecting;
      if (sc.visible && !sc.inst) monter(sc);
    }
  }, { rootMargin: '200px 0px' });

  const groupes = {};
  for (const a of FM.anims) (groupes[a.groupe] = groupes[a.groupe] || []).push(a);
  for (const g in groupes) {
    const rangee = document.querySelector(`[data-rangee="${g}"]`);
    if (!rangee) continue;
    groupes[g].sort((x, y) => x.lettre.localeCompare(y.lettre)).forEach(a => rangee.appendChild(creerFiche(a)));
  }
  document.querySelectorAll('section[data-groupe]').forEach(s => { if (!groupes[s.dataset.groupe]) s.hidden = true; });
  scenes.forEach(sc => obs.observe(sc.el));

  /* ---------- Son ---------- */
  const bSon = $('#b-son');
  function majBoutonSon() { bSon.setAttribute('aria-pressed', FM.sonActif); bSon.querySelector('span').textContent = FM.sonActif ? 'Son activé' : 'Activer le son'; }
  function activerSonSiBesoin() {
    if (FM.sonActif || !window.FMSons) return;
    try { FMSons.init(); FM.sonActif = true; majBoutonSon(); } catch (e) {}
  }
  bSon.addEventListener('click', () => {
    if (!window.FMSons) return toast('Les sons ne sont pas chargés.');
    if (FM.sonActif) { FM.sonActif = false; } else { FMSons.init(); FM.sonActif = true; FM.son('toucher'); }
    majBoutonSon();
  });

  const bReduit = $('#b-reduit');
  bReduit.setAttribute('aria-pressed', reduit);
  bReduit.addEventListener('click', () => {
    reduit = !reduit; ecrire('reduit', reduit); bReduit.setAttribute('aria-pressed', reduit);
    scenes.forEach(sc => { if (sc.inst) monter(sc); });
    toast(reduit ? 'Animations réduites, comme avec le réglage d’iPhone' : 'Animations complètes');
  });

  /* ---------- Planche des sons ---------- */
  const ICONE_JOUER = '<svg viewBox="0 0 16 16" fill="currentColor" aria-hidden="true"><path d="M4.5 2.8v10.4L13 8z"/></svg>';
  const HAPTIQUE = {
    lancement: 'Aucune', toucher: 'Sélection, très légère', retournement: 'Impact léger',
    montee: 'Vibration continue qui monte', 'carte-commun': '1 coup doux', 'carte-peu-commun': '2 coups',
    'carte-rare': 'Montée puis 1 coup franc', 'carte-legendaire': 'Montée sur 0,6 s, gros coup, traîne qui s’éteint',
    plouf: 'Impact moyen', bulles: 'Aucune', moulinet: 'Petits crans réguliers', succes: 'Succès (système)', alerte: 'Avertissement (système)'
  };
  const ondes = [];
  function dessinerOnde(cv, buf) {
    const dpr = Math.min(2, devicePixelRatio || 1), w = cv.clientWidth || 200, h = cv.clientHeight || 38;
    cv.width = w * dpr; cv.height = h * dpr;
    const c = cv.getContext('2d'); c.scale(dpr, dpr);
    const d = buf.getChannelData(0), n = Math.floor(w / 3);
    const col = getComputedStyle(document.documentElement).getPropertyValue('--marine').trim() || '#0D4A85';
    c.fillStyle = col; let max = 0.0001;
    for (let i = 0; i < d.length; i += 7) max = Math.max(max, Math.abs(d[i]));
    for (let i = 0; i < n; i++) {
      const a = Math.floor(i * d.length / n), b = Math.floor((i + 1) * d.length / n); let m = 0;
      for (let j = a; j < b; j += 3) m = Math.max(m, Math.abs(d[j]));
      const hh = Math.max(1.5, (m / max) * (h - 4));
      c.globalAlpha = .35 + .65 * (m / max);
      c.beginPath(); c.roundRect ? c.roundRect(i * 3, (h - hh) / 2, 2, hh, 1) : c.rect(i * 3, (h - hh) / 2, 2, hh); c.fill();
    }
  }
  function construireSons() {
    const zone = $('#moments'), tab = $('#tableau-moments');
    if (!window.FMSons) { zone.innerHTML = '<p>Les sons ne sont pas chargés.</p>'; return; }
    const ordre = ['carte-commun', 'carte-peu-commun', 'carte-rare', 'carte-legendaire', 'montee', 'retournement', 'lancement', 'toucher', 'plouf', 'bulles', 'moulinet', 'succes', 'alerte'];
    const moments = FMSons.moments.slice().sort((x, y) => (ordre.indexOf(x.id) + 99) % 99 - (ordre.indexOf(y.id) + 99) % 99);
    for (const m of moments) {
      const sons = FMSons.catalogue.filter(s => s.moment === m.id).sort((x, y) => x.lettre.localeCompare(y.lettre));
      if (!sons.length) continue;
      const rar = m.id.startsWith('carte-') ? m.id.slice(6) : null;
      const bloc = document.createElement('div'); bloc.className = 'moment';
      bloc.innerHTML = `<div class="moment-nom"><h3>${rar ? `<i class="r-${rar}" style="width:11px;height:11px;display:inline-block"></i>` : ''}${m.nom}</h3><p>${m.quand}</p></div><div class="sons"></div>`;
      const grille = bloc.querySelector('.sons');
      for (const s of sons) {
        const choisi = FM.sonChoisi(m.id) === s.id;
        const el = document.createElement('div'); el.className = 'son' + (choisi ? ' choisi' : '');
        el.innerHTML = `<div class="son-haut"><button class="jouer" type="button" aria-label="Écouter ${s.nom}">${ICONE_JOUER}</button>
          <div class="son-titre"><b>${s.lettre} · ${s.nom}</b><small>${String(s.duree).replace('.', ',')} s${s.defaut ? ' · <span class="reco">Recommandé</span>' : ''}</small></div></div>
          <canvas class="onde" aria-hidden="true"></canvas><p>${s.recette}</p>
          <label class="choix"><input type="radio" name="s-${m.id}" id="s-${s.id}" ${choisi ? 'checked' : ''}><span>Je prends ${s.lettre}</span></label>`;
        const bj = el.querySelector('.jouer');
        bj.addEventListener('click', () => { activerSonSiBesoin(); FMSons.init(); FMSons.jouer(s.id); bj.classList.remove('joue'); void bj.offsetWidth; bj.classList.add('joue'); });
        el.querySelector('input').addEventListener('change', () => {
          FM.choixSons[m.id] = s.id; ecrire('sons', FM.choixSons);
          grille.querySelectorAll('.son').forEach(x => x.classList.toggle('choisi', x.querySelector('input').checked));
          majChoix(); majTableau();
        });
        grille.appendChild(el);
        ondes.push([el.querySelector('canvas'), s.id]);
      }
      zone.appendChild(bloc);
    }
    // Les ondes se calculent hors ligne, sans jouer de son.
    // Les ondes se calculent hors ligne, une à la fois, sans jouer de son.
    let file = Promise.resolve();
    const obsOnde = new IntersectionObserver((es) => es.forEach(e => {
      if (!e.isIntersecting) return; obsOnde.unobserve(e.target);
      const o = ondes.find(x => x[0] === e.target);
      file = file.then(() => FMSons.rendre(o[1])).then(buf => dessinerOnde(o[0], buf)).catch((err) => console.warn('onde', o[1], err));
    }), { rootMargin: '300px 0px' });
    ondes.forEach(o => obsOnde.observe(o[0]));
    majTableau();
  }
  function majTableau() {
    if (!window.FMSons) return;
    const tab = $('#tableau-moments'); tab.innerHTML = '';
    for (const m of FMSons.moments) {
      const s = FMSons.catalogue.find(x => x.id === FM.sonChoisi(m.id)); if (!s) continue;
      const tr = document.createElement('tr');
      tr.innerHTML = `<td>${m.nom}</td><td>${s.lettre} · ${s.nom}</td><td>${HAPTIQUE[m.id] || '—'}</td><td class="n">${String(s.duree).replace('.', ',')} s</td>`;
      tab.appendChild(tr);
    }
  }

  /* ---------- Mes choix ---------- */
  function texteChoix() {
    const lignes = [];
    for (const g of ['lancement', 'arrivee', 'attente', 'carte', 'reconnaissance']) {
      const a = FM.anims.find(x => x.id === choix[g]);
      if (a) lignes.push(`${NOMS_GROUPES[g]} : ${a.lettre} « ${a.nom} »`);
    }
    const sonsChoisis = Object.keys(FM.choixSons);
    if (window.FMSons && sonsChoisis.length) {
      lignes.push('Sons :');
      for (const m of FMSons.moments) {
        if (!FM.choixSons[m.id]) continue;
        const s = FMSons.catalogue.find(x => x.id === FM.choixSons[m.id]);
        if (s) lignes.push(`  ${m.nom} : ${s.lettre} « ${s.nom} »`);
      }
    }
    return lignes.join('\n');
  }
  function majChoix() { $('#mes-choix').textContent = texteChoix() || 'Rien de choisi pour l’instant.'; }
  $('#b-copier').addEventListener('click', () => {
    const t = texteChoix(); if (!t) return toast('Choisis d’abord une variation.');
    const pre = $('#mes-choix');
    const repli = () => { const r = document.createRange(); r.selectNodeContents(pre); const s = getSelection(); s.removeAllRanges(); s.addRange(r); toast('Texte sélectionné : copie-le'); };
    try { navigator.clipboard.writeText(t).then(() => toast('Choix copiés'), repli); } catch (e) { repli(); }
  });

  construireSons();
  majChoix();
})();
