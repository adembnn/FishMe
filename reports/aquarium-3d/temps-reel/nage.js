// Nage des poissons FishMe (16 oct.) : un seul modèle de mouvement pour l'aquarium, le widget et la carte.
// Repère du poisson : tête vers +X, dos vers +Y, flancs vers ±Z, longueur 1 (mise à l'échelle par l'objet).
// 1) Ondulation du corps (dans le shader de sommets) : décalage latéral z = A * env(t) * sin(phase - 2π t / λ),
//    t = 0 à la tête, 1 au bout de la queue ; env(t) = 0.03 + 0.97 t^2.2 (la tête bouge à peine, la queue balaie).
//    A = 0.07 (fraction de la longueur), λ = 1.05 longueur ; la tête compense un peu (-12 %) pour ne pas « pagayer ».
// 2) Battement : la phase avance de 2π * f par seconde, f = 0.9 + 2.2 * vitesse / longueur (battements par seconde).
// 3) Trajectoire : le poisson vise un point au hasard dans le bac, tourne vers lui sans dépasser un virage max
//    (rad/s), accélère et ralentit en douceur ; près du but, il en choisit un autre. Les bancs suivent un meneur.
// 4) Vitesse de croisière en longueurs par seconde, par espèce (ESPECES ci-dessous) ; « fuite » x3 pendant 0,6 s.
var NAGE = (function () {
  var ESPECES = {
    // croisiere : longueurs/s ; virage : rad/s ; calme : temps passé immobile au but (s), poste : reste près du fond
    "brochet":       { croisiere: 0.30, virage: 0.7, calme: 4.0, amplitude: 0.05, bas: 0.25, haut: 0.75 },
    "carpe-commune": { croisiere: 0.45, virage: 0.9, calme: 1.5, amplitude: 0.07, bas: 0.10, haut: 0.45 },
    "truite-fario":  { croisiere: 0.70, virage: 1.4, calme: 0.6, amplitude: 0.07, bas: 0.30, haut: 0.90 },
    "sandre":        { croisiere: 0.40, virage: 0.9, calme: 2.5, amplitude: 0.06, bas: 0.15, haut: 0.55 },
    "tanche":        { croisiere: 0.35, virage: 0.8, calme: 2.5, amplitude: 0.07, bas: 0.05, haut: 0.30 },
    "perche":        { croisiere: 0.80, virage: 1.8, calme: 1.0, amplitude: 0.07, bas: 0.25, haut: 0.75 },
    "gardon":        { croisiere: 1.10, virage: 2.2, calme: 0.0, amplitude: 0.08, bas: 0.45, haut: 0.95 },
    "rotengle":      { croisiere: 1.00, virage: 2.0, calme: 0.2, amplitude: 0.08, bas: 0.55, haut: 1.00 },
    "chevesne":      { croisiere: 0.80, virage: 1.5, calme: 0.5, amplitude: 0.07, bas: 0.40, haut: 0.95 },
    "black-bass":    { croisiere: 0.55, virage: 1.4, calme: 2.0, amplitude: 0.06, bas: 0.20, haut: 0.70 },
    "breme-commune": { croisiere: 0.45, virage: 0.8, calme: 1.0, amplitude: 0.06, bas: 0.05, haut: 0.40 },
    "ablette":       { croisiere: 1.30, virage: 2.6, calme: 0.0, amplitude: 0.08, bas: 0.60, haut: 1.00 }
  };

  // Morceau de shader GLSL à insérer après « #include <begin_vertex> » (variable « transformed »).
  var GLSL = [
    "float nT = clamp(0.5 - transformed.x, 0.0, 1.0);",
    "float nEnv = 0.03 + 0.97 * pow(nT, 2.2);",
    "float nOnde = sin(uPhase - 6.2831853 * nT / 1.05);",
    "transformed.z += uAmp * (nEnv * nOnde - 0.12 * sin(uPhase) * (1.0 - nT));",
    // le poisson se courbe dans les virages (la queue reste à l'extérieur)
    "transformed.z += uCourbe * nT * nT * 0.25;"
  ].join("\n");

  function hasard(a, b) { return a + Math.random() * (b - a); }

  // Un nageur : position, cap (rad, autour de l'axe vertical), assiette (rad), vitesse (m/s)
  function Nageur(espece, longueur, bac, depart) {
    this.e = ESPECES[espece] || ESPECES["gardon"];
    this.L = longueur; this.bac = bac;
    this.p = depart.position.slice(); this.cap = depart.cap; this.assiette = 0;
    this.v = this.e.croisiere * longueur * 0.6; this.phase = Math.random() * 6.283;
    this.courbe = 0; this.attente = 0; this.fuite = 0; this.meneur = null; this.ecart = [0, 0, 0];
    this.but = null; this.choisir();
  }
  Nageur.prototype.choisir = function () {
    var b = this.bac, m = this.L * 0.6, e = this.e;
    var y0 = b.min[1] + (b.max[1] - b.min[1]) * e.bas, y1 = b.min[1] + (b.max[1] - b.min[1]) * e.haut;
    this.but = [hasard(b.min[0] + m, b.max[0] - m), hasard(Math.max(y0, b.min[1] + 0.03), Math.min(y1, b.max[1] - 0.03)),
                hasard(b.min[2] + m * 0.5, b.max[2] - m * 0.5)];
  };
  Nageur.prototype.viser = function (point) { this.but = point.slice(); this.attente = 0; };
  Nageur.prototype.effrayer = function () { this.fuite = 0.6; this.choisir(); };
  Nageur.prototype.bouche = function () {
    var c = Math.cos(this.cap), s = Math.sin(this.cap), h = this.L * 0.5;
    return [this.p[0] + c * h, this.p[1], this.p[2] - s * h];
  };
  Nageur.prototype.pas = function (dt) {
    var e = this.e, but = this.but;
    if (this.meneur) {
      var m = this.meneur;
      but = [m.p[0] + this.ecart[0], m.p[1] + this.ecart[1], m.p[2] + this.ecart[2]];
    }
    var dx = but[0] - this.p[0], dy = but[1] - this.p[1], dz = but[2] - this.p[2];
    var dh = Math.sqrt(dx * dx + dz * dz), d = Math.sqrt(dh * dh + dy * dy);
    var croisiere = e.croisiere * this.L * (this.fuite > 0 ? 3 : 1);
    var cible;
    if (this.attente > 0) {            // au repos au but : il tient son poste en ondulant doucement
      this.attente -= dt; cible = 0.06 * this.L;
      if (this.attente <= 0) this.choisir();
    } else if (!this.meneur && d < this.L * 0.4) {
      this.attente = e.calme * hasard(0.5, 1.5); cible = 0.1 * this.L;
      if (this.attente <= 0) this.choisir();
    } else {
      cible = croisiere * Math.min(1, 0.4 + d / (this.L * 2));
    }
    this.v += (cible - this.v) * Math.min(1, dt * (this.fuite > 0 ? 6 : 1.2));
    // virage vers le but, limité
    var capVoulu = Math.atan2(-dz, dx), diff = capVoulu - this.cap;
    while (diff > Math.PI) diff -= 2 * Math.PI;
    while (diff < -Math.PI) diff += 2 * Math.PI;
    var tour = Math.max(-e.virage * dt, Math.min(e.virage * dt, diff * Math.min(1, dt * 2.5)));
    if (this.v < 0.12 * this.L) tour *= 0.4;
    this.cap += tour;
    this.courbe += ((dt > 0 ? tour / dt : 0) / e.virage * 0.5 - this.courbe) * Math.min(1, dt * 4);
    var assietteVoulue = Math.max(-0.22, Math.min(0.22, Math.atan2(dy, Math.max(dh, 1e-3)) * 0.5));
    this.assiette += (assietteVoulue - this.assiette) * Math.min(1, dt * 1.5);
    var c = Math.cos(this.cap), s = Math.sin(this.cap), ca = Math.cos(this.assiette);
    this.p[0] += c * ca * this.v * dt; this.p[2] -= s * ca * this.v * dt;
    this.p[1] += Math.sin(this.assiette) * this.v * dt;
    var b = this.bac, mg = this.L * 0.45;
    for (var i = 0; i < 3; i++) this.p[i] = Math.max(b.min[i] + (i === 1 ? 0.03 : mg * (i === 2 ? 0.5 : 1)), Math.min(b.max[i] - (i === 1 ? 0.03 : mg * (i === 2 ? 0.5 : 1)), this.p[i]));
    if (this.fuite > 0) this.fuite -= dt;
    // battement : plus rapide quand il nage vite
    var f = 0.9 + 2.2 * this.v / this.L;
    this.phase += 6.2831853 * f * dt;
    this.amp = e.amplitude * (0.55 + 0.45 * Math.min(1, this.v / (e.croisiere * this.L)));
  };
  return { ESPECES: ESPECES, GLSL: GLSL, Nageur: Nageur };
})();
