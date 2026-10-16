/* FishMe : bibliothèque de sons synthétisés (Web Audio). Aucun fichier audio, aucune bibliothèque.
   Seul global : window.FMSons. Chaque son est une fonction (ctx, dest, t0, rnd, fx)
   utilisable avec un AudioContext comme avec un OfflineAudioContext. */
(function () {
  'use strict';

  var AC = window.AudioContext || window.webkitAudioContext;
  var OAC = window.OfflineAudioContext || window.webkitOfflineAudioContext;

  /* Niveau de chaque son (calibré pour viser le pic voulu en sortie, après le master + compresseur). */
  var TRIM = {"lancement-a":1.011,"lancement-b":1.219,"lancement-c":4.591,"toucher-a":2.827,"toucher-b":2.891,"toucher-c":3.013,"retournement-a":0.852,"retournement-b":1.018,"montee-a":0.341,"montee-b":1.175,"montee-c":1.215,"carte-commun-a":2.515,"carte-commun-b":3.018,"carte-commun-c":5.176,"carte-peu-commun-a":1.855,"carte-peu-commun-b":1.443,"carte-peu-commun-c":1.146,"carte-rare-a":1.106,"carte-rare-b":1.29,"carte-rare-c":1.206,"carte-legendaire-a":0.482,"carte-legendaire-b":1.236,"carte-legendaire-c":1.565,"plouf-a":3.561,"plouf-b":2.03,"bulles-a":1.537,"bulles-b":0.998,"moulinet-a":1.776,"moulinet-b":1.316,"succes-a":1.55,"succes-b":1.468,"alerte-a":0.897,"alerte-b":0.777};
  var CIBLE = { lancement: .45, toucher: .3, retournement: .35, montee: .4, 'carte-commun': .4,
    'carte-peu-commun': .45, 'carte-rare': .5, 'carte-legendaire': .62, plouf: .4, bulles: .35,
    moulinet: .35, succes: .42, alerte: .3 };

  var HZ = { C4: 261.63, E4: 329.63, G4: 392, C5: 523.25, E5: 659.26, G5: 783.99, C6: 1046.5,
    D6: 1174.66, E6: 1318.51, G6: 1567.98, A6: 1760, C7: 2093, D7: 2349.3, E7: 2637, G7: 3135.96,
    A7: 3520, B7: 3951, C8: 4186, D8: 4698.6, E8: 5274 };

  /* ---------- briques communes ---------- */
  function env(g, t, a, pk, dec, hold) {
    var p = g.gain;
    p.setValueAtTime(0.0001, t);
    p.linearRampToValueAtTime(pk, t + a);
    if (hold) p.setValueAtTime(pk, t + a + hold);
    p.exponentialRampToValueAtTime(0.0001, t + a + (hold || 0) + dec);
  }

  function kit(ctx, dest, fx, rnd) {
    var P = rnd.p, R = rnd.r;

    function cleanup(src, nodes) {
      src.onended = function () {
        for (var i = 0; i < nodes.length; i++) { try { nodes[i].disconnect(); } catch (e) {} }
      };
    }
    function wire(last, wet, echo) {
      last.connect(dest);
      if (wet) fx.send(last, wet);
      if (echo) last.connect(echo);
    }

    /* écho avec ondulations : entrée -> délai (filtré dans la boucle) -> sortie */
    function echo(time, fb, level, wet, endAbs) {
      var inn = ctx.createGain(), d = ctx.createDelay(1), lp = ctx.createBiquadFilter(),
        f = ctx.createGain(), o = ctx.createGain();
      d.delayTime.value = time; lp.type = 'lowpass'; lp.frequency.value = 3800;
      f.gain.value = fb; o.gain.value = level;
      inn.connect(d); d.connect(lp); lp.connect(f); f.connect(d); d.connect(o); o.connect(dest);
      if (wet) fx.send(o, wet);
      fx.later(endAbs, function () {
        [inn, d, lp, f, o].forEach(function (n) { try { n.disconnect(); } catch (e) {} });
      });
      return inn;
    }

    /* oscillateur enveloppé : f -> f2 sur sw secondes */
    function tone(o) {
      var os = ctx.createOscillator(), t = o.t, a = o.a || 0.003;
      os.type = o.type || 'sine';
      os.frequency.setValueAtTime(o.f * P, t);
      if (o.f2) os.frequency.exponentialRampToValueAtTime(o.f2 * P, t + (o.sw || o.dec));
      if (o.det) os.detune.value = o.det;
      var g = ctx.createGain(); env(g, t, a, o.g, o.dec, o.hold);
      var total = a + (o.hold || 0) + o.dec;
      var nodes = [os, g], last = g; os.connect(g);
      if (o.lp) {
        var lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.Q.value = o.q || 0.7;
        if (o.fe) {
          lp.frequency.setValueAtTime(o.fe[0], t);
          lp.frequency.linearRampToValueAtTime(o.fe[1], t + o.fe[3]);
          lp.frequency.exponentialRampToValueAtTime(o.fe[2], t + total);
        } else lp.frequency.value = o.lp;
        g.connect(lp); last = lp; nodes.push(lp);
      }
      var extra = [];
      if (o.trem) { /* tremolo lent : un LFO ajoute à l'enveloppe */
        var l = ctx.createOscillator(), lg = ctx.createGain();
        l.frequency.value = o.trem[0]; lg.gain.value = o.g * o.trem[1];
        l.connect(lg); lg.connect(g.gain); l.start(t); l.stop(t + total + 0.03);
        nodes.push(l, lg); extra.push(l);
      }
      if (o.vib) { /* vibrato qui s'éteint */
        var v = ctx.createOscillator(), vg = ctx.createGain();
        v.frequency.value = o.vib[0]; vg.gain.setValueAtTime(o.vib[1] * P, t);
        vg.gain.exponentialRampToValueAtTime(0.01, t + total);
        v.connect(vg); vg.connect(os.frequency); v.start(t); v.stop(t + total + 0.03);
        nodes.push(v, vg);
      }
      wire(last, o.wet, o.echo);
      os.start(t); os.stop(t + total + 0.03); cleanup(os, nodes);
    }

    /* bruit filtré, avec balayage de fréquence */
    function noise(o) {
      var s = ctx.createBufferSource(); s.buffer = fx.noise; s.loop = true;
      var t = o.t, a = o.a || 0.003, total = a + (o.hold || 0) + o.dec;
      var fl = ctx.createBiquadFilter(); fl.type = o.type || 'bandpass'; fl.Q.value = o.q || 1;
      fl.frequency.setValueAtTime(o.f * P, t);
      if (o.f2) fl.frequency.exponentialRampToValueAtTime(o.f2 * P, t + (o.sw || total));
      var g = ctx.createGain(); env(g, t, a, o.g, o.dec, o.hold);
      s.connect(fl); fl.connect(g);
      wire(g, o.wet, o.echo);
      s.start(t, R() * 0.8); s.stop(t + total + 0.03); cleanup(s, [s, fl, g]);
    }

    /* FM : porteuse + modulateur dont l'indice retombe */
    function fm(o) {
      var t = o.t, a = o.a || 0.003, total = a + (o.hold || 0) + o.dec;
      var c = ctx.createOscillator(), m = ctx.createOscillator(), mg = ctx.createGain();
      c.frequency.value = o.fc * P; m.frequency.value = o.fc * o.ratio * P;
      mg.gain.setValueAtTime(o.idx * o.fc * P, t);
      mg.gain.exponentialRampToValueAtTime(Math.max(0.5, o.fc * 0.02), t + total * 0.7);
      m.connect(mg); mg.connect(c.frequency);
      var g = ctx.createGain(); env(g, t, a, o.g, o.dec, o.hold); c.connect(g);
      wire(g, o.wet, o.echo);
      c.start(t); m.start(t); c.stop(t + total + 0.03); m.stop(t + total + 0.03);
      cleanup(c, [c, m, mg, g]);
    }

    /* goutte : sinus 1800 -> 600 Hz en 90 ms + petit sinus aigu */
    function droplet(t, g, s, wet, ech) {
      s = s || 1;
      tone({ t: t, f: 1800 * s, f2: 600 * s, sw: 0.09, a: 0.002, dec: 0.12, g: g, wet: wet, echo: ech });
      tone({ t: t, f: 2400 * s, f2: 900 * s, sw: 0.09, a: 0.002, dec: 0.08, g: g * 0.25, wet: wet, echo: ech });
    }
    /* bulle qui éclate : sinus montant + petit clic aigu */
    function bubble(t, f0, f1, g, dec, wet) {
      tone({ t: t, f: f0, f2: f1, sw: 0.06, a: 0.003, dec: dec || 0.09, g: g, wet: wet });
      noise({ t: t, type: 'highpass', f: 3000, q: 0.7, a: 0.001, dec: 0.012, g: g * 1.4, wet: wet });
    }
    /* cliquet de moulinet */
    function click(t, g, f) {
      tone({ t: t, type: 'triangle', f: f || 1800, a: 0.001, dec: 0.025, g: g });
      noise({ t: t, type: 'bandpass', f: 4000, q: 8, a: 0.001, dec: 0.015, g: g * 4 });
    }

    return { ctx: ctx, tone: tone, noise: noise, fm: fm, droplet: droplet, bubble: bubble,
      click: click, echo: echo, wire: wire, cleanup: cleanup, R: R, P: P };
  }

  function wrap(body) {
    return function (ctx, dest, t0, rnd, fx) { body(kit(ctx, dest, fx, rnd), t0, rnd.r); };
  }

  /* ---------- les sons ---------- */
  var SONS = {};
  function def(id, moment, lettre, nom, duree, recette, defaut, body) {
    SONS[id] = { id: id, moment: moment, lettre: lettre, nom: nom, duree: duree, recette: recette,
      defaut: !!defaut, fn: wrap(body) };
  }

  /* ===== lancement ===== */
  def('lancement-a', 'lancement', 'A', 'Plouf de lune', 1.6,
    'Un petit plouf de poisson qui retombe dans l’eau, une goutte, puis une note grave et aérienne qui se pose comme un halo.', true,
    function (k, t) {
      k.noise({ t: t, type: 'bandpass', f: 2800, f2: 600, q: 1.2, a: 0.02, dec: 0.33, g: 1.6, wet: 0.4 });
      k.tone({ t: t, f: 420, f2: 110, sw: 0.14, dec: 0.2, g: 0.5, wet: 0.2 });
      k.droplet(t + 0.2, 0.3, 1.1, 0.45);
      [[220, 0.5, -5], [220, 0.5, 5], [329.6, 0.28, 0], [440, 0.22, 0]].forEach(function (n) {
        k.tone({ t: t + 0.1, f: n[0], det: n[2], a: 0.45, hold: 0.3, dec: 0.9, g: n[1] * 0.45, lp: 1400, wet: 0.6 });
      });
      k.noise({ t: t + 0.1, type: 'bandpass', f: 1800, q: 0.8, a: 0.5, dec: 0.8, g: 0.35, wet: 0.5 });
    });

  def('lancement-b', 'lancement', 'B', 'Ronds dans l’eau', 1.5,
    'Trois gouttes qui montent en gamme pentatonique, chacune suivie de son écho qui s’élargit comme un rond.', false,
    function (k, t) {
      var e = k.echo(0.22, 0.42, 0.55, 0.35, t + 2.2);
      [[HZ.C6, 0], [HZ.D6, 0.17], [HZ.G6, 0.34]].forEach(function (n, i) {
        var s = n[0] / 1800 * 1.6;
        k.tone({ t: t + n[1], f: 1800 * s, f2: 900 * s, sw: 0.07, a: 0.002, dec: 0.2, g: 0.42, wet: 0.35, echo: e });
        k.tone({ t: t + n[1], f: n[0] * 2, a: 0.002, dec: 0.28 + i * 0.1, g: 0.1, wet: 0.5, echo: e });
      });
    });

  def('lancement-c', 'lancement', 'C', 'Silence et goutte', 1.2,
    'Une seule goutte, très sobre, avec une longue queue d’eau. Presque rien, mais ça sonne.', false,
    function (k, t) {
      k.droplet(t, 0.5, 0.85, 0.7);
      k.tone({ t: t + 0.02, f: 1250, a: 0.002, dec: 0.5, g: 0.07, wet: 0.8 });
    });

  /* ===== toucher ===== */
  def('toucher-a', 'toucher', 'A', 'Bloop', 0.08,
    'Un petit « bloop » sous l’eau, 40 ms, sinus qui descend.', true,
    function (k, t) {
      k.tone({ t: t, f: 700, f2: 280, sw: 0.035, a: 0.002, dec: 0.045, g: 0.6 });
      k.noise({ t: t, type: 'lowpass', f: 1500, a: 0.001, dec: 0.012, g: 0.25 });
    });

  def('toucher-b', 'toucher', 'B', 'Goutte de verre', 0.12,
    'Un tic de goutte sur du verre : sinus aigu très court et une trace de résonance.', false,
    function (k, t) {
      k.tone({ t: t, f: 3200, f2: 2400, sw: 0.02, a: 0.001, dec: 0.025, g: 0.5 });
      k.fm({ t: t, fc: 2200, ratio: 2.76, idx: 0.8, a: 0.001, dec: 0.08, g: 0.18, wet: 0.2 });
    });

  def('toucher-c', 'toucher', 'C', 'Clic de bois', 0.08,
    'Un clic sec et doux, comme un moulinet en bois.', false,
    function (k, t) {
      k.tone({ t: t, type: 'triangle', f: 900, f2: 500, sw: 0.02, a: 0.001, dec: 0.025, g: 0.5 });
      k.noise({ t: t, type: 'bandpass', f: 1800, q: 4, a: 0.001, dec: 0.012, g: 1.4 });
      k.tone({ t: t, f: 220, a: 0.002, dec: 0.03, g: 0.3 });
    });

  /* ===== retournement ===== */
  def('retournement-a', 'retournement', 'A', 'Carte et bruit sourd', 0.3,
    'Un froissement de carte qui glisse, puis un petit choc mat quand elle retombe.', true,
    function (k, t) {
      k.noise({ t: t, type: 'bandpass', f: 3500, f2: 1200, q: 1, a: 0.06, dec: 0.12, g: 1.3 });
      k.tone({ t: t + 0.14, f: 180, f2: 80, sw: 0.1, a: 0.004, dec: 0.12, g: 0.55 });
      k.noise({ t: t + 0.14, type: 'lowpass', f: 700, a: 0.002, dec: 0.04, g: 0.5 });
    });

  def('retournement-b', 'retournement', 'B', 'Glisse d’eau', 0.4,
    'Un souffle d’eau filtré qui monte puis redescend, mouillé de réverbération, et une goutte à la fin.', false,
    function (k, t) {
      k.noise({ t: t, type: 'bandpass', f: 500, f2: 3500, q: 3, sw: 0.15, a: 0.1, dec: 0.18, g: 2.2, wet: 0.55 });
      k.noise({ t: t + 0.14, type: 'bandpass', f: 3500, f2: 800, q: 2, a: 0.01, dec: 0.12, g: 0.9, wet: 0.5 });
      k.droplet(t + 0.2, 0.25, 1.2, 0.4);
    });

  /* ===== montée ===== */
  def('montee-a', 'montee', 'A', 'Eau sous pression', 1.0,
    'Un souffle d’eau filtré qui monte et s’éclaircit, avec un grondement grave qui gonfle dessous.', true,
    function (k, t) {
      k.noise({ t: t, type: 'bandpass', f: 300, f2: 4500, q: 3, sw: 0.95, a: 0.9, dec: 0.06, g: 2.4, wet: 0.2 });
      k.tone({ t: t, f: 90, f2: 200, sw: 0.95, a: 0.9, dec: 0.06, g: 0.3, lp: 600 });
      k.noise({ t: t + 0.4, type: 'highpass', f: 5000, q: 0.7, a: 0.5, dec: 0.06, g: 0.3 });
    });

  def('montee-b', 'montee', 'B', 'Fil qui se tend', 1.2,
    'Le cliquet d’un moulinet qui accélère, puis le fil tendu qui vibre en montant.', false,
    function (k, t) {
      var x = 0, step = 0.11, i = 0;
      while (x < 0.8) { k.click(t + x, 0.12 + i * 0.012, 1500 + i * 70); x += step; step = Math.max(0.028, step * 0.84); i++; }
      k.tone({ t: t + 0.86, type: 'triangle', f: 300, f2: 640, sw: 0.18, a: 0.004, dec: 0.32, g: 0.4, lp: 3000, vib: [26, 22], wet: 0.2 });
      k.tone({ t: t + 0.86, f: 1280, a: 0.004, dec: 0.2, g: 0.06 });
    });

  def('montee-c', 'montee', 'C', 'Bulles qui accélèrent', 1.0,
    'Des bulles qui remontent de plus en plus vite et de plus en plus haut.', false,
    function (k, t) {
      var x = 0, step = 0.15, i = 0;
      while (x < 0.85) {
        var f = 450 + i * 90;
        k.bubble(t + x, f, f * 2.6, 0.13 + i * 0.012, 0.08, 0.2);
        x += step; step = Math.max(0.035, step * 0.8); i++;
      }
    });

  /* ===== carte commune ===== */
  def('carte-commun-a', 'carte-commun', 'A', 'Goutte', 0.45,
    'Une goutte, deux petites notes claires (sol et do aigus) et un minuscule tic cristallin.', true,
    function (k, t) {
      k.droplet(t, 0.4, 1, 0.25);
      k.tone({ t: t + 0.02, f: HZ.G6, a: 0.003, dec: 0.28, g: 0.22, wet: 0.3 });
      k.tone({ t: t + 0.09, f: HZ.C7, a: 0.003, dec: 0.3, g: 0.2, wet: 0.3 });
      k.noise({ t: t + 0.09, type: 'highpass', f: 6000, a: 0.001, dec: 0.01, g: 0.3 });
    });

  def('carte-commun-b', 'carte-commun', 'B', 'Bulle', 0.45,
    'Une bulle qui éclate en montant, puis trois étincelles aiguës.', false,
    function (k, t) {
      k.bubble(t, 400, 1400, 0.45, 0.1, 0.2);
      [HZ.G7, HZ.B7, HZ.D8].forEach(function (f, i) {
        k.tone({ t: t + 0.05 + i * 0.045, f: f, a: 0.002, dec: 0.1 + 0.03 * i, g: 0.11, wet: 0.35 });
      });
    });

  def('carte-commun-c', 'carte-commun', 'C', 'Clic', 0.45,
    'Un tic de verre brillant, suivi d’un court miroitement.', false,
    function (k, t) {
      k.tone({ t: t, f: 4200, f2: 3600, sw: 0.02, a: 0.001, dec: 0.03, g: 0.4 });
      k.noise({ t: t, type: 'highpass', f: 5000, a: 0.001, dec: 0.01, g: 0.3 });
      k.fm({ t: t + 0.01, fc: HZ.G6, ratio: 3.01, idx: 0.9, a: 0.003, dec: 0.34, g: 0.2, wet: 0.35 });
    });

  /* ===== carte peu commune ===== */
  def('carte-peu-commun-a', 'carte-peu-commun', 'A', 'Carillon de verre', 0.7,
    'Deux notes de cloche (FM) comme une goutte sur du verre, la seconde plus haute.', true,
    function (k, t) {
      k.fm({ t: t, fc: 880, ratio: 2, idx: 3, a: 0.003, dec: 0.45, g: 0.38, wet: 0.35 });
      k.fm({ t: t + 0.12, fc: 1318, ratio: 2, idx: 3, a: 0.003, dec: 0.5, g: 0.34, wet: 0.4 });
      k.noise({ t: t, type: 'highpass', f: 5000, a: 0.001, dec: 0.01, g: 0.25 });
    });

  def('carte-peu-commun-b', 'carte-peu-commun', 'B', 'Double rond', 0.7,
    'Deux gouttes, la seconde une quinte plus haut, chacune prolongée par un écho en cercles.', false,
    function (k, t) {
      var e = k.echo(0.16, 0.35, 0.5, 0.3, t + 1.6);
      k.droplet(t, 0.42, 1.0, 0.3, e);
      k.droplet(t + 0.13, 0.4, 1.5, 0.3, e);
    });

  def('carte-peu-commun-c', 'carte-peu-commun', 'C', 'Marimba', 0.7,
    'Deux notes de bois chaud, comme un marimba : un sinus et un harmonique qui s’éteint très vite.', false,
    function (k, t) {
      [[HZ.C6, 0], [HZ.G6, 0.12]].forEach(function (n) {
        k.tone({ t: t + n[1], f: n[0], a: 0.002, dec: 0.4, g: 0.42, wet: 0.2 });
        k.tone({ t: t + n[1], f: n[0] * 4, a: 0.001, dec: 0.06, g: 0.2, wet: 0.1 });
        k.noise({ t: t + n[1], type: 'bandpass', f: 2500, q: 3, a: 0.001, dec: 0.01, g: 0.5 });
      });
    });

  /* ===== carte rare ===== */
  def('carte-rare-a', 'carte-rare', 'A', 'Arpège d’eau', 1.2,
    'Un court souffle qui monte, puis cinq notes d’arpège (do mi sol do mi) en triangle doublé à l’octave, avec écho et réverbération.', true,
    function (k, t) {
      k.noise({ t: t, type: 'bandpass', f: 1200, f2: 6500, q: 2, a: 0.14, dec: 0.02, g: 1.2, wet: 0.2 });
      var e = k.echo(0.15, 0.35, 0.5, 0.3, t + 2.5);
      [HZ.C6, HZ.E6, HZ.G6, HZ.C7, HZ.E7].forEach(function (f, i) {
        var s = t + 0.15 + i * 0.07, last = i === 4;
        k.tone({ t: s, type: 'triangle', f: f, a: 0.004, dec: last ? 0.7 : 0.3, g: 0.32, wet: 0.45, echo: e });
        k.tone({ t: s, f: f * 2, a: 0.004, dec: last ? 0.55 : 0.22, g: 0.14, wet: 0.45, echo: e });
      });
    });

  def('carte-rare-b', 'carte-rare', 'B', 'Ricochet', 1.2,
    'Un galet qui ricoche : quatre gouttes de plus en plus rapprochées et de plus en plus hautes, puis un miroitement qui s’étire.', false,
    function (k, t) {
      [[0, 900], [0.2, 1250], [0.35, 1700], [0.46, 2300]].forEach(function (n, i) {
        k.droplet(t + n[0], 0.34 + i * 0.03, n[1] / 1800, 0.3);
        k.noise({ t: t + n[0], type: 'highpass', f: 4000, a: 0.001, dec: 0.012, g: 0.25 });
      });
      [HZ.G7, HZ.C8, HZ.E8, 6272].forEach(function (f, i) {
        k.tone({ t: t + 0.56 + i * 0.045, f: f, a: 0.02, dec: 0.55, g: 0.1, trem: [6, 0.6], wet: 0.5 });
      });
      k.tone({ t: t + 0.5, f: HZ.C7, a: 0.01, dec: 0.6, g: 0.12, wet: 0.5 });
    });

  def('carte-rare-c', 'carte-rare', 'C', 'Cristal', 1.3,
    'Un groupe de cloches de verre (FM) qui s’empilent, avec des harmoniques aiguës qui scintillent doucement.', false,
    function (k, t) {
      k.fm({ t: t, fc: 784, ratio: 2, idx: 1.5, a: 0.004, dec: 0.9, g: 0.2, wet: 0.5 });
      [[HZ.G6, 0], [HZ.C7, 0.06], [HZ.E7, 0.12], [HZ.G7, 0.2]].forEach(function (n) {
        k.fm({ t: t + n[1], fc: n[0], ratio: 3.5, idx: 1.2, a: 0.003, dec: 0.9, g: 0.22, wet: 0.6 });
      });
      k.tone({ t: t + 0.05, f: HZ.C8, a: 0.03, dec: 0.95, g: 0.09, trem: [5, 0.5], wet: 0.6 });
      k.tone({ t: t + 0.1, f: HZ.E8, a: 0.03, dec: 0.9, g: 0.07, trem: [5.5, 0.5], wet: 0.6 });
    });

  /* ===== carte légendaire ===== */
  def('carte-legendaire-a', 'carte-legendaire', 'A', 'Grande gerbe', 2.5,
    'Un souffle qui monte, une grande gerbe d’eau avec un grondement grave, une fanfare de quatre notes (do sol do mi) tenue sur la dernière, puis un arpège scintillant et des bulles qui remontent.', true,
    function (k, t) {
      k.noise({ t: t, type: 'bandpass', f: 400, f2: 5000, q: 2, a: 0.27, dec: 0.03, g: 1.6, wet: 0.2 });
      var s = t + 0.3;
      k.noise({ t: s, type: 'lowpass', f: 3000, f2: 500, q: 0.7, sw: 0.7, a: 0.01, dec: 0.85, g: 1.6, wet: 0.35 });
      k.tone({ t: s, f: 90, f2: 45, sw: 0.5, a: 0.005, dec: 0.75, g: 0.9 });
      [[HZ.C5, 0], [HZ.G5, 0.13], [HZ.C6, 0.26], [HZ.E6, 0.39]].forEach(function (n, i) {
        var last = i === 3;
        [-7, 7].forEach(function (d) {
          k.tone({ t: s + 0.05 + n[1], type: 'sawtooth', f: n[0], det: d, a: 0.012, hold: last ? 1.0 : 0.06,
            dec: last ? 0.55 : 0.28, g: 0.12, lp: 3500, wet: 0.35 });
        });
      });
      [HZ.C7, HZ.E7, HZ.G7, HZ.C8, HZ.E8].forEach(function (f, i) {
        k.tone({ t: t + 1.3 + i * 0.075, type: 'triangle', f: f, a: 0.004, dec: 0.4, g: 0.1, wet: 0.5 });
      });
      for (var i = 0; i < 7; i++) k.bubble(t + 1.7 + i * 0.09, 500 + i * 140, 1400 + i * 200, 0.1, 0.09, 0.35);
    });

  def('carte-legendaire-b', 'carte-legendaire', 'B', 'Lune pleine', 2.8,
    'Plus lent et plus magique : un accord majeur de voix douces qui se lève, une cascade de cloches qui descend puis remonte, et un léger plouf.', false,
    function (k, t) {
      k.noise({ t: t + 0.15, type: 'lowpass', f: 2000, f2: 400, q: 0.7, sw: 0.5, a: 0.02, dec: 0.55, g: 0.7, wet: 0.5 });
      [HZ.C4, HZ.E4, HZ.G4, HZ.C5, HZ.E5].forEach(function (f, i) {
        [-6, 0, 6].forEach(function (d) {
          k.tone({ t: t + 0.1, type: i % 2 ? 'triangle' : 'sine', f: f, det: d, a: 0.65, hold: 1.1, dec: 0.95,
            g: 0.075, lp: 2200, wet: 0.5 });
        });
      });
      k.noise({ t: t + 0.1, type: 'bandpass', f: 1200, q: 1.2, a: 0.7, hold: 0.8, dec: 0.8, g: 0.4, wet: 0.6 });
      [HZ.G7, HZ.E7, HZ.C7, HZ.G6].forEach(function (f, i) {
        k.fm({ t: t + 0.3 + i * 0.1, fc: f, ratio: 2, idx: 1.5, a: 0.003, dec: 0.5, g: 0.2, wet: 0.55 });
      });
      [HZ.G6, HZ.C7, HZ.E7, HZ.G7, HZ.C8].forEach(function (f, i) {
        k.fm({ t: t + 1.0 + i * 0.11, fc: f, ratio: 2, idx: 1.5, a: 0.003, dec: i === 4 ? 1.3 : 0.55,
          g: 0.2 + i * 0.01, wet: 0.6 });
      });
    });

  def('carte-legendaire-c', 'carte-legendaire', 'C', 'Trophée', 2.2,
    'Un coup de timbale grave, un accord de cuivres éclatant (do majeur) puis une pluie d’étincelles qui monte.', false,
    function (k, t) {
      k.tone({ t: t, f: 110, f2: 55, sw: 0.3, a: 0.004, dec: 0.7, g: 1 });
      k.tone({ t: t, type: 'triangle', f: 220, f2: 110, sw: 0.2, a: 0.004, dec: 0.3, g: 0.3 });
      k.noise({ t: t, type: 'lowpass', f: 300, a: 0.002, dec: 0.15, g: 1.5 });
      [HZ.C4, HZ.E4, HZ.G4, HZ.C5].forEach(function (f) {
        [-8, 8].forEach(function (d) {
          k.tone({ t: t + 0.03, type: 'sawtooth', f: f, det: d, a: 0.025, hold: 0.3, dec: 0.55, g: 0.12,
            lp: 1500, fe: [600, 4000, 1500, 0.09], q: 1.2, wet: 0.3 });
        });
      });
      var pent = [HZ.C7, HZ.D7, HZ.E7, HZ.G7, HZ.A7, HZ.C8, HZ.D8];
      for (var i = 0; i < 12; i++) {
        var f = pent[Math.min(6, Math.floor(i * 0.5 + k.R() * 2))];
        k.tone({ t: t + 0.32 + i * 0.085, type: i % 3 ? 'sine' : 'triangle', f: f, a: 0.002, dec: 0.3,
          g: 0.09 + k.R() * 0.03, wet: 0.5 });
      }
      k.fm({ t: t + 1.35, fc: HZ.C7, ratio: 3.5, idx: 1, a: 0.004, dec: 0.7, g: 0.16, wet: 0.6 });
    });

  /* ===== plouf ===== */
  def('plouf-a', 'plouf', 'A', 'Plouf de bouchon', 0.4,
    'Le bouchon tombe : un sinus qui plonge, un souffle d’eau sourd, et une petite goutte juste après.', true,
    function (k, t) {
      k.tone({ t: t, f: 500, f2: 120, sw: 0.12, a: 0.003, dec: 0.16, g: 0.6, wet: 0.15 });
      k.noise({ t: t, type: 'lowpass', f: 1200, a: 0.004, dec: 0.1, g: 0.9, wet: 0.15 });
      k.droplet(t + 0.06, 0.2, 1.0, 0.3);
    });

  def('plouf-b', 'plouf', 'B', 'Gloup', 0.5,
    'Plus lourd : un « gloup » grave qui s’ouvre en bulle, comme une grosse prise qui happe.', false,
    function (k, t) {
      k.tone({ t: t, f: 300, f2: 70, sw: 0.2, a: 0.004, dec: 0.25, g: 0.7, wet: 0.15 });
      k.tone({ t: t + 0.09, f: 150, f2: 520, sw: 0.1, a: 0.004, dec: 0.13, g: 0.4, wet: 0.2 });
      k.noise({ t: t, type: 'lowpass', f: 600, a: 0.005, dec: 0.15, g: 0.9 });
    });

  /* ===== bulles ===== */
  def('bulles-a', 'bulles', 'A', 'Bulles légères', 0.7,
    'Sept à neuf bulles à des moments aléatoires, dont la hauteur monte.', true,
    function (k, t, r) {
      var n = 7 + Math.floor(r() * 3);
      for (var i = 0; i < n; i++) {
        var at = (i / n) * 0.5 + r() * 0.05, f = 500 + (i / n) * 600 + r() * 150;
        k.bubble(t + at, f, f * 2.8, 0.12 + r() * 0.1, 0.09, 0.25);
      }
    });

  def('bulles-b', 'bulles', 'B', 'Bulles graves', 0.7,
    'Moins de bulles, plus profondes et plus rondes.', false,
    function (k, t, r) {
      for (var i = 0; i < 4; i++) {
        var f = 250 + i * 60 + r() * 60;
        k.bubble(t + i * 0.13 + r() * 0.05, f, f * 2.4, 0.2 + r() * 0.08, 0.14, 0.3);
      }
    });

  /* ===== moulinet ===== */
  def('moulinet-a', 'moulinet', 'A', 'Cliquet qui ralentit', 0.6,
    'Six à dix clics de cliquet de plus en plus espacés, comme un moulinet qui s’arrête.', true,
    function (k, t, r) {
      var n = 6 + Math.floor(r() * 5), x = 0, step = 0.03;
      for (var i = 0; i < n; i++) {
        k.click(t + x, 0.3 - i * 0.015, 1750 + r() * 150);
        x += step; step *= 1.22;
      }
    });

  def('moulinet-b', 'moulinet', 'B', 'Bobine lisse', 0.7,
    'Un ronronnement rapide de bobine : bruit filtré haché par un tremblement qui ralentit à la fin.', false,
    function (k, t) {
      /* remplacé plus bas (a besoin du tampon de bruit) */
    });

  /* ===== succès ===== */
  def('succes-a', 'succes', 'A', 'Deux notes douces', 0.8,
    'Deux notes de carillon doux qui montent (sol puis do).', true,
    function (k, t) {
      k.fm({ t: t, fc: HZ.G5, ratio: 2, idx: 1.2, a: 0.004, dec: 0.5, g: 0.38, wet: 0.35 });
      k.fm({ t: t + 0.13, fc: HZ.C6, ratio: 2, idx: 1.2, a: 0.004, dec: 0.6, g: 0.38, wet: 0.4 });
    });

  def('succes-b', 'succes', 'B', 'Goutte et tierce', 0.8,
    'Une goutte, puis une tierce majeure chaude (do et mi) qui se pose.', false,
    function (k, t) {
      k.droplet(t, 0.3, 1.0, 0.3);
      k.tone({ t: t + 0.09, type: 'triangle', f: HZ.C6, a: 0.01, dec: 0.6, g: 0.28, lp: 3500, wet: 0.45 });
      k.tone({ t: t + 0.09, type: 'triangle', f: HZ.E6, a: 0.01, dec: 0.55, g: 0.22, lp: 3500, wet: 0.45 });
      k.tone({ t: t + 0.09, f: HZ.C7, a: 0.01, dec: 0.4, g: 0.06, wet: 0.5 });
    });

  /* ===== alerte ===== */
  def('alerte-a', 'alerte', 'A', 'Deux cloches basses', 1.2,
    'Deux cloches douces et graves qui descendent (la puis fa). Rien d’agressif.', true,
    function (k, t) {
      k.fm({ t: t, fc: 440, ratio: 2, idx: 1.5, a: 0.01, dec: 0.8, g: 0.45, wet: 0.35 });
      k.fm({ t: t + 0.35, fc: 349.2, ratio: 2, idx: 1.5, a: 0.01, dec: 0.85, g: 0.45, wet: 0.4 });
    });

  def('alerte-b', 'alerte', 'B', 'Triple pulsation', 0.9,
    'Trois pulsations assourdies, comme un battement sous l’eau.', false,
    function (k, t) {
      for (var i = 0; i < 3; i++)
        k.tone({ t: t + i * 0.2, f: 330, a: 0.012, dec: 0.13, g: 0.5, lp: 800, wet: 0.2 });
    });

  /* moulinet-b : écrit à part car il a besoin du tampon de bruit */
  SONS['moulinet-b'].fn = function (ctx, dest, t0, rnd, fx) {
    var k = kit(ctx, dest, fx, rnd), t = t0, dur = 0.6, a = 0.04;
    var s = ctx.createBufferSource(); s.buffer = fx.noise; s.loop = true;
    var fl = ctx.createBiquadFilter(); fl.type = 'bandpass'; fl.Q.value = 3;
    fl.frequency.setValueAtTime(1500 * rnd.p, t);
    fl.frequency.exponentialRampToValueAtTime(2800 * rnd.p, t + 0.35);
    fl.frequency.exponentialRampToValueAtTime(900 * rnd.p, t + dur);
    var am = ctx.createGain(); am.gain.value = 0.5;
    var lfo = ctx.createOscillator(), lg = ctx.createGain();
    lfo.frequency.setValueAtTime(75, t); lfo.frequency.exponentialRampToValueAtTime(26, t + dur);
    lg.gain.value = 0.45; lfo.connect(lg); lg.connect(am.gain);
    var g = ctx.createGain(); env(g, t, a, 2.6, dur - a);
    s.connect(fl); fl.connect(am); am.connect(g);
    k.wire(g, 0.15);
    s.start(t, rnd.r() * 0.8); lfo.start(t); s.stop(t + dur + 0.03); lfo.stop(t + dur + 0.03);
    k.cleanup(s, [s, fl, am, g, lfo, lg]);
    k.tone({ t: t + 0.02, type: 'triangle', f: 140, f2: 90, sw: dur, a: 0.04, dec: dur - 0.04, g: 0.08, lp: 400 });
  };

  /* ---------- moteur ---------- */
  function mulberry(seed) {
    return function () {
      seed |= 0; seed = seed + 0x6D2B79F5 | 0;
      var t = Math.imul(seed ^ seed >>> 15, 1 | seed);
      t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
      return ((t ^ t >>> 14) >>> 0) / 4294967296;
    };
  }
  function hash(s) { var h = 2166136261; for (var i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); } return h >>> 0; }

  function noiseBuffer(c) {
    var n = Math.floor(c.sampleRate * 2), b = c.createBuffer(1, n, c.sampleRate), d = b.getChannelData(0), r = mulberry(7);
    for (var i = 0; i < n; i++) d[i] = r() * 2 - 1;
    return b;
  }
  /* réverbération synthétique : bruit qui décroît (~1,6 s) et s'assombrit */
  function impulse(c) {
    var sr = c.sampleRate, n = Math.floor(1.6 * sr), pre = Math.floor(0.008 * sr),
      b = c.createBuffer(1, n, sr), d = b.getChannelData(0), r = mulberry(99), y = 0;
    for (var i = pre; i < n; i++) {
      var u = (i - pre) / (n - pre), cf = 0.85 - 0.72 * u;
      y += ((r() * 2 - 1) - y) * cf;
      d[i] = y * Math.exp(-6.9 * u);
    }
    return b;
  }

  function chaine(c, vol) {
    var master = c.createGain(); master.gain.value = 0.5 * vol;
    var comp = c.createDynamicsCompressor();
    comp.threshold.value = -12; comp.ratio.value = 4; comp.knee.value = 10;
    comp.attack.value = 0.003; comp.release.value = 0.25;
    master.connect(comp); comp.connect(c.destination);
    var conv = c.createConvolver(); conv.buffer = impulse(c); conv.connect(master);
    return { master: master, comp: comp, rev: conv, noise: noiseBuffer(c) };
  }

  function lancer(c, ch, id, rnd, t0, offline) {
    var S = SONS[id], tr = rnd.g * (TRIM[id] || 1);
    var out = c.createGain(); out.gain.value = tr; out.connect(ch.master);
    var sendIn = c.createGain(); sendIn.gain.value = tr; sendIn.connect(ch.rev);
    var made = [out, sendIn];
    var fx = {
      noise: ch.noise, offline: offline,
      send: function (node, amt) { var g = c.createGain(); g.gain.value = amt; node.connect(g); g.connect(sendIn); made.push(g); },
      later: function (abs, fn) { if (!offline) setTimeout(fn, Math.max(0, abs - c.currentTime) * 1000 + 150); }
    };
    S.fn(c, out, t0, rnd, fx);
    fx.later(t0 + S.duree + 2.8, function () { made.forEach(function (n) { try { n.disconnect(); } catch (e) {} }); });
  }

  var live = null, volume = 1;

  var API = {
    catalogue: [], moments: [],
    _trim: TRIM,
    init: function () {
      if (!AC) return;
      if (!live) {
        var c = new AC();
        live = chaine(c, volume); live.ctx = c;
      }
      if (live.ctx.state === 'suspended') live.ctx.resume();
    },
    jouer: function (id) {
      if (!SONS[id] || !AC) return;
      API.init();
      var r = Math.random;
      var rnd = { p: 1 + (r() * 2 - 1) * 0.03, g: Math.pow(10, (r() * 2 - 1) / 20), r: r };
      lancer(live.ctx, live, id, rnd, live.ctx.currentTime + 0.03, false);
    },
    rendre: function (id) {
      var S = SONS[id];
      if (!S) return Promise.reject(new Error('son inconnu : ' + id));
      var oc = new OAC(1, Math.ceil(44100 * (S.duree + 0.4)), 44100);
      var ch = chaine(oc, 1);
      lancer(oc, ch, id, { p: 1, g: 1, r: mulberry(hash(id)) }, 0.01, true);
      return oc.startRendering();
    },
    versWav: function (buf) {
      var n = buf.length, nc = buf.numberOfChannels, sr = buf.sampleRate, ab = new ArrayBuffer(44 + n * 2), v = new DataView(ab);
      function s(o, str) { for (var i = 0; i < str.length; i++) v.setUint8(o + i, str.charCodeAt(i)); }
      s(0, 'RIFF'); v.setUint32(4, 36 + n * 2, true); s(8, 'WAVE'); s(12, 'fmt ');
      v.setUint32(16, 16, true); v.setUint16(20, 1, true); v.setUint16(22, 1, true);
      v.setUint32(24, sr, true); v.setUint32(28, sr * 2, true); v.setUint16(32, 2, true); v.setUint16(34, 16, true);
      s(36, 'data'); v.setUint32(40, n * 2, true);
      var chs = []; for (var c = 0; c < nc; c++) chs.push(buf.getChannelData(c));
      for (var i = 0; i < n; i++) {
        var x = 0; for (var j = 0; j < nc; j++) x += chs[j][i]; x /= nc;
        x = Math.max(-1, Math.min(1, x));
        v.setInt16(44 + i * 2, x < 0 ? x * 0x8000 : x * 0x7FFF, true);
      }
      return new Blob([ab], { type: 'audio/wav' });
    },
    volume: function (v) {
      volume = Math.max(0, Math.min(1, +v || 0));
      if (live) live.master.gain.value = 0.5 * volume;
    }
  };

  API.moments = [
    { id: 'lancement', nom: 'Lancement', quand: 'Au lancement de l’app, quand la lune apparaît et que le poisson bondit.' },
    { id: 'toucher', nom: 'Toucher', quand: 'À chaque toucher d’un bouton ou d’un onglet.' },
    { id: 'retournement', nom: 'Retournement', quand: 'Quand une carte se retourne pour montrer le verso (la photo).' },
    { id: 'montee', nom: 'Montée', quand: 'Juste avant la révélation d’une prise, pendant la tension.' },
    { id: 'carte-commun', nom: 'Carte commune', quand: 'À l’arrivée d’une carte commune, très court car il revient souvent.' },
    { id: 'carte-peu-commun', nom: 'Carte peu commune', quand: 'À l’arrivée d’une carte peu commune.' },
    { id: 'carte-rare', nom: 'Carte rare', quand: 'À l’arrivée d’une carte rare, avec le reflet holographique.' },
    { id: 'carte-legendaire', nom: 'Carte légendaire', quand: 'À l’arrivée d’une carte légendaire, le moment le plus fort de l’app.' },
    { id: 'plouf', nom: 'Plouf', quand: 'Quand le bouchon tombe dans l’eau au début d’une session de pêche.' },
    { id: 'bulles', nom: 'Bulles', quand: 'Quand des bulles remontent, par exemple pendant l’attente ou l’analyse de la photo.' },
    { id: 'moulinet', nom: 'Moulinet', quand: 'Quand on remonte la ligne ou qu’on fait défiler la toise.' },
    { id: 'succes', nom: 'Succès', quand: 'Quand la prise est confirmée et enregistrée dans le Pescedex.' },
    { id: 'alerte', nom: 'Alerte', quand: 'Quand une alerte orage ou crue apparaît. Volontairement douce.' }
  ];
  Object.keys(SONS).forEach(function (id) {
    var S = SONS[id];
    if (!TRIM[id]) TRIM[id] = 1;
    API.catalogue.push({ id: S.id, moment: S.moment, lettre: S.lettre, nom: S.nom, duree: S.duree, recette: S.recette, defaut: S.defaut });
  });
  API._cible = CIBLE;

  window.FMSons = API;
})();
