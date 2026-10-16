import Foundation

// Le moteur de comportement de l'aquarium de l'app (Foundation seulement : aucune image, aucune vue).
//
// Il remplace les trajectoires précalculées (`NageWidget.traversees`, boucle de 90 s) par une simulation CONTINUE :
// à chaque pas de temps fixe (1/120 s) chaque poisson décide, tourne, accélère et bat de la queue, comme un petit
// agent. Tout est déterministe par graine (espèce + identifiant) : même cartes, même aquarium au lancement.
//
// Ce qui est simulé :
//  - cap et vitesse lissés, accélérations et vitesses de virage bornées, jamais de virage instantané ;
//  - alternance nage / glisse / quasi-arrêt (planer) / coup de queue (rafale), propre à l'espèce ;
//  - errance « wander » (processus d'Ornstein-Uhlenbeck) en trois dimensions : x, y (hauteur) et z (profondeur) ;
//  - murs mous (côtés, surface, fond, vitre, fond du bac) : il tourne avant le bord, la scène reste fermée ;
//  - battement de queue couplé à la vitesse ; au planer, le cycle ralentit et se fige sur une image douce ;
//  - virage par les lacets disponibles (profil, trois-quarts, face ou dos), sens gauche/droite par miroir seulement
//    quand le poisson est de face ou de dos ;
//  - banc (cohésion, alignement, séparation, meneur) pour les espèces grégaires ; les solitaires évitent le banc ;
//    un prédateur qui bouge près des petits les fait filer doucement ;
//  - toucher un poisson : il vient voir la vitre puis repart ; toucher l'eau : une onde, les petits s'écartent.
//
// Repère « monde » : x de 0 (gauche) à 1 (droite) en largeurs d'écran ; y de 0 (haut) à 1 (bas) en hauteurs d'écran ;
// z de 0 (contre la vitre) à 1 (au fond du bac). L'écran est la projection en perspective vers un point de fuite.

/// Tous les réglages du moteur : on change une valeur ici, jamais dans la simulation.
enum ReglagesNage {
  // Temps
  /// Pas de simulation (s) : 120 Hz, l'état est donc fluide à 60 comme à 120 images par seconde.
  static let pasFixe = 1.0 / 120
  /// Un trou plus long (écran en veille, retour d'une autre app) n'est pas rattrapé : la scène reprend là où elle est.
  static let trouMax = 0.1

  // Le bac
  static let fuiteX = 0.5
  static let fuiteY = 0.45
  /// Bande de hauteur utile (y écran) : sous la surface, au-dessus des galets du fond.
  static let ySurface = 0.15
  static let yFond = 0.78
  static let zMin = 0.02
  static let zMax = 0.92
  /// Largeur de la zone où les murs mous poussent (en monde) et leur force.
  static let margeMur = 0.17
  static let margeProfondeur = 0.22
  static let forceMur = 2.4
  static let margeHauteur = 0.08

  // Allure (multiplicateurs de calme : les vitesses « réelles » de la table des espèces sont ralenties à l'écran)
  static let echelleVitesse = 0.75
  static let echelleVirage = 0.55
  /// Accélération angulaire maximale (rad/s²).
  static let accelerationAngulaire = 1.1
  /// Vitesse verticale maximale (hauteurs d'écran par seconde) et son accélération maximale.
  static let vitesseVerticaleMax = 0.011
  static let accelerationVerticale = 0.012
  /// Assiette (nez qui monte ou descend) au plus, en radians, et part de l'angle réel montrée.
  static let assietteMax = 0.20
  static let partAssiette = 0.7
  /// Roulis au plus (radians) pendant un virage.
  static let roulisMax = 0.13

  // Errance
  /// Durée de mémoire (s) et intensité de l'errance.
  static let tauErrance = 2.6
  static let sigmaErrance = 0.42
  /// Poids qui ramène le cap vers l'horizontale (gauche/droite) : les poissons nagent surtout de profil.
  static let retourHorizontal = 0.45
  /// Poids qui ramène vers la profondeur visée.
  static let tractionProfondeur = 0.9

  // Battement de queue
  static let frequenceBase = 0.35
  static let frequenceParVitesse = 2.2
  static let frequenceMax = 3.6
  /// Image du cycle sur laquelle la queue se fige quand il plane (0 = début du cycle).
  static let imageDouce = 0
  /// Rapidité du lissage de la cadence (s).
  static let lissageCadence = 0.5
  /// Battements minimes de la queue quand il plane, en images de part et d'autre, et leur cadence (Hz).
  static let flotteImages = 1.4
  static let flotteCadence = 0.55

  // Banc
  static let rayonAlignement = 0.38
  static let poidsCohesion = 1.3
  static let poidsAlignement = 0.9
  static let poidsSeparation = 2.0
  /// Les solitaires évitent le banc en deçà de ce rayon.
  static let rayonEvitement = 0.20
  static let rayonEvitementPredateur = 0.15
  /// Un prédateur qui bouge à moins de ce rayon fait filer les petits.
  static let rayonFuite = 0.28
  static let poidsFuite = 1.5
  static let vitesseFuite = 1.7

  // Toucher
  /// Durée (s) de la visite à la vitre après un toucher, et part consacrée à l'approche.
  static let dureeCuriosite = 6.5
  static let finApproche = 2.5
  static let rayonOnde = 0.35
  static let dureeEcart = 3.2
  static let ondesMax = 4
}

/// Une onde de lumière née d'un toucher dans l'eau (position en part de l'écran, instant de la simulation).
nonisolated struct Onde {
  var x = 0.0
  var y = 0.0
  var debut = -100.0
  nonisolated static let duree = 2.6
}

/// Comment une espèce se comporte. Vitesses en longueurs de corps par seconde « réelles » (ralenties à l'écran).
struct ProfilNage {
  enum Role { case banc, solitaire, predateur }
  var role: Role
  var croisiere: Double
  /// Multiple de la croisière pendant un coup de queue.
  var rafale: Double
  /// Accélération (longueurs par seconde²).
  var accel: Double
  /// Vitesse de virage (rad/s, avant `echelleVirage`).
  var virage: Double
  var nage: ClosedRange<Double>
  var glisse: ClosedRange<Double>
  var plane: ClosedRange<Double>
  /// À la fin d'une glisse : chance de planer ; chance d'un coup de queue.
  var pPlane: Double
  var pRafale: Double
  /// Bande de hauteur préférée, de 0 (fond) à 1 (surface).
  var bas: Double
  var haut: Double

  static let table: [String: ProfilNage] = [
    "brochet": .init(
      role: .predateur, croisiere: 0.50, rafale: 5.0, accel: 0.25, virage: 0.7,
      nage: 2...5, glisse: 6...14, plane: 4...9, pPlane: 0.45, pRafale: 0.5, bas: 0.30, haut: 0.70),
    "silure": .init(
      role: .predateur, croisiere: 0.35, rafale: 3.0, accel: 0.18, virage: 0.5,
      nage: 3...7, glisse: 6...12, plane: 5...10, pPlane: 0.5, pRafale: 0.25, bas: 0.05, haut: 0.35),
    "sandre": .init(
      role: .predateur, croisiere: 0.55, rafale: 3.5, accel: 0.25, virage: 0.8,
      nage: 3...6, glisse: 4...9, plane: 3...7, pPlane: 0.4, pRafale: 0.4, bas: 0.15, haut: 0.55),
    "perche": .init(
      role: .predateur, croisiere: 0.80, rafale: 2.2, accel: 0.5, virage: 1.5,
      nage: 3...7, glisse: 2...4, plane: 2...5, pPlane: 0.25, pRafale: 0.3, bas: 0.25, haut: 0.75),
    "black-bass": .init(
      role: .predateur, croisiere: 0.60, rafale: 3.0, accel: 0.4, virage: 1.2,
      nage: 3...7, glisse: 3...6, plane: 3...6, pPlane: 0.35, pRafale: 0.4, bas: 0.20, haut: 0.70),
    "carpe-commune": .init(
      role: .solitaire, croisiere: 0.35, rafale: 1.5, accel: 0.12, virage: 0.8,
      nage: 8...16, glisse: 3...6, plane: 3...7, pPlane: 0.3, pRafale: 0.0, bas: 0.10, haut: 0.45),
    "tanche": .init(
      role: .solitaire, croisiere: 0.30, rafale: 1.4, accel: 0.10, virage: 0.8,
      nage: 8...16, glisse: 4...8, plane: 4...8, pPlane: 0.4, pRafale: 0.0, bas: 0.05, haut: 0.30),
    "truite-fario": .init(
      role: .solitaire, croisiere: 0.70, rafale: 3.0, accel: 0.5, virage: 1.4,
      nage: 4...9, glisse: 1.5...3, plane: 1.5...3, pPlane: 0.15, pRafale: 0.25, bas: 0.30,
      haut: 0.90),
    "gardon": .init(
      role: .banc, croisiere: 0.90, rafale: 2.0, accel: 0.6, virage: 1.8,
      nage: 6...12, glisse: 1...2.5, plane: 0.8...2, pPlane: 0.1, pRafale: 0.1, bas: 0.45,
      haut: 0.95),
    "rotengle": .init(
      role: .banc, croisiere: 0.85, rafale: 2.0, accel: 0.6, virage: 1.8,
      nage: 6...12, glisse: 1...2.5, plane: 0.8...2, pPlane: 0.1, pRafale: 0.1, bas: 0.55, haut: 1.0
    ),
    "ablette": .init(
      role: .banc, croisiere: 1.10, rafale: 2.0, accel: 0.7, virage: 2.2,
      nage: 7...14, glisse: 0.8...2, plane: 0.6...1.5, pPlane: 0.08, pRafale: 0.1, bas: 0.60,
      haut: 1.0),
    "goujon": .init(
      role: .banc, croisiere: 0.70, rafale: 2.0, accel: 0.5, virage: 1.8,
      nage: 5...10, glisse: 1...2.5, plane: 1...2.5, pPlane: 0.15, pRafale: 0.1, bas: 0.05,
      haut: 0.40),
    "vandoise": .init(
      role: .banc, croisiere: 0.85, rafale: 2.2, accel: 0.6, virage: 1.6,
      nage: 6...12, glisse: 1...2.5, plane: 1...2, pPlane: 0.1, pRafale: 0.15, bas: 0.35, haut: 0.85
    ),
    "breme-commune": .init(
      role: .banc, croisiere: 0.40, rafale: 1.6, accel: 0.25, virage: 1.0,
      nage: 8...14, glisse: 2...4, plane: 2...4, pPlane: 0.25, pRafale: 0.05, bas: 0.05, haut: 0.40),
    "chevesne": .init(
      role: .banc, croisiere: 0.75, rafale: 2.0, accel: 0.5, virage: 1.5,
      nage: 6...12, glisse: 1...2.5, plane: 1...2.5, pPlane: 0.12, pRafale: 0.12, bas: 0.40,
      haut: 0.95),
  ]

  /// Profil de l'espèce ; « perche-commune » nage comme la perche ; une espèce inconnue est une solitaire calme.
  static func pour(_ slug: String) -> ProfilNage {
    if let p = table[slug] { return p }
    if slug == "perche-commune", let p = table["perche"] { return p }
    return ProfilNage(
      role: .solitaire, croisiere: 0.45, rafale: 2.0, accel: 0.3, virage: 1.0,
      nage: 5...10, glisse: 2...5, plane: 2...5, pPlane: 0.3, pRafale: 0.1, bas: 0.25, haut: 0.75)
  }
}

/// Petit générateur déterministe (xorshift64*) : même graine, même suite, d'un lancement à l'autre.
struct Hasard {
  private var etat: UInt64

  init(graine: UInt64) {
    etat = graine == 0 ? 0x9E37_79B9_7F4A_7C15 : graine
    for _ in 0..<4 { _ = suivant() }
  }

  /// Entre 0 inclus et 1 exclu.
  mutating func suivant() -> Double {
    etat ^= etat >> 12
    etat ^= etat << 25
    etat ^= etat >> 27
    let r = etat &* 2_685_821_657_736_338_717
    return Double(r >> 11) / 9_007_199_254_740_992.0
  }

  mutating func entre(_ a: Double, _ b: Double) -> Double { a + (b - a) * suivant() }
  mutating func entre(_ r: ClosedRange<Double>) -> Double { entre(r.lowerBound, r.upperBound) }

  /// Presque gaussien centré réduit (somme de quatre tirages).
  mutating func gauss() -> Double {
    (suivant() + suivant() + suivant() + suivant() - 2) * 1.732
  }

  /// Empreinte stable d'un texte (FNV-1a) : pas de `Hasher`, qui change à chaque lancement.
  static func empreinte(_ texte: String) -> UInt64 {
    var h: UInt64 = 0xcbf2_9ce4_8422_2325
    for octet in texte.utf8 { h = (h ^ UInt64(octet)) &* 0x100_0000_01b3 }
    return h
  }
}

private func borner(_ v: Double, _ a: Double, _ b: Double) -> Double { min(max(v, a), b) }

/// Angle ramené entre −π et π.
private func ramener(_ a: Double) -> Double {
  var a = a.truncatingRemainder(dividingBy: 2 * .pi)
  if a > .pi { a -= 2 * .pi }
  if a < -.pi { a += 2 * .pi }
  return a
}

/// Un poisson de la scène : réglages fixes, état de la simulation, et les champs que la vue lit pour dessiner.
struct Nageur {
  enum Mode { case nage, glisse, plane, rafale }
  /// Son calendrier de présence : il entre en nageant, reste, puis repart en nageant ; absent, il n'est pas dessiné.
  enum Presence { case present, entrant, sortant, absent }

  // Fixe
  let id: String
  let nom: String
  let slug: String
  /// Longueur du corps au premier plan, en largeurs d'écran (avant la perspective).
  let largeur: Double
  let cycle: Bool
  let imagesCycle: Int
  let pas: Int
  /// Lacets rendus, profil (0) compris, du plus négatif au plus positif ; vide : pas de rendu en volume.
  let angles: [Int]
  let volume: Bool
  let profil: ProfilNage
  let decalage: Double
  let lag: Double

  // Simulation
  var x = 0.5, y = 0.4, z = 0.4
  var cap = 0.0
  var omega = 0.0
  /// Vitesse en longueurs de corps (réelles) par seconde.
  var v = 0.0
  var vy = 0.0
  var errance = 0.0
  var biais = 0.0
  var mode = Mode.nage
  var minuteur = 3.0
  var depuisMode = 0.0
  var yBut = 0.4, zBut = 0.4
  var minuteurBut = 5.0
  var decalageY = 0.0
  var phase = 0.0
  var cadence = 1.0
  var bloque = false
  var fuite = 0.0
  var fuiteDX = 0.0, fuiteDZ = 0.0
  var ecart = 0.0
  var ecartDX = 0.0, ecartDZ = 0.0
  var curiosite = 0.0
  var curiositeX = 0.5
  var lacetAffiche = 0.0
  var sensMiroir = 1.0
  var hasard: Hasard
  var etat = Presence.present
  /// Instant de la simulation avant lequel il ne change pas de présence (durées propres à chaque poisson).
  var echeance = 0.0
  /// Entrée ou sortie par l'arrière-plan (sinon par un côté), et côté (true : droite).
  var passeParLeFond = true
  var passeADroite = true

  // Pour la vue
  var sx = 0.5, sy = 0.4
  /// Taille à l'écran (perspective) : 1 au premier plan.
  var echelle = 1.0
  /// Profondeur 0...1, pour la brume et l'ordre de dessin.
  var profondeur = 0.4
  var opacite = 1.0
  /// −1 ou 1 pour un rendu en volume (miroir) ; continu entre les deux sans rendu en volume (demi-tour à plat).
  var sens = 1.0
  var lacet = 0.0
  /// Assiette en radians, positive : le nez monte.
  var assiette = 0.0
  var roulis = 0.0
  var ondulation = 0.0
  /// Numéro d'image du cycle de battement (0..<imagesCycle).
  var image = 0
  /// Lacet principal et secondaire à montrer, et poids du secondaire (0 : un seul).
  var angleA = 0
  var angleB = 0
  var poidsB = 0.0
  var selectionne = false

  /// Les deux vues rendues les plus proches d'un lacet et le poids de la seconde : la même règle que
  /// `NageWidget.melange` (la plus lourde en entier, l'autre fondue par-dessus), sans tableau à chaque image.
  mutating func melanger() {
    guard volume, angles.count > 1 else {
      angleA = 0
      angleB = 0
      poidsB = 0
      return
    }
    let l = lacetAffiche
    if l <= Double(angles[0]) {
      angleA = angles[0]
      angleB = angleA
      poidsB = 0
      return
    }
    if l >= Double(angles[angles.count - 1]) {
      angleA = angles[angles.count - 1]
      angleB = angleA
      poidsB = 0
      return
    }
    var i = 0
    while i + 2 < angles.count, Double(angles[i + 1]) <= l { i += 1 }
    let a = angles[i]
    let b = angles[i + 1]
    let w = (l - Double(a)) / Double(b - a)
    if w < 1e-3 {
      angleA = a
      angleB = a
      poidsB = 0
    } else if w > 1 - 1e-3 {
      angleA = b
      angleB = b
      poidsB = 0
    } else if w > 0.5 {
      angleA = b
      angleB = a
      poidsB = 1 - w
    } else {
      angleA = a
      angleB = b
      poidsB = w
    }
  }
}

@MainActor
final class MoteurNage {
  /// Ce que la vue sait d'un poisson avant de le lancer.
  nonisolated struct Entree: Sendable {
    let id: String
    /// Nom commun, précalculé : la vue ne le cherche jamais à chaque image.
    let nom: String
    let slug: String
    /// Longueur au premier plan en largeurs d'écran (part × échelle du placement).
    let largeur: Double
    let cycle: Bool
    let images: Int
    let pas: Int
    let angles: [Int]
  }

  private(set) var nageurs: [Nageur] = []
  private(set) var ondes = [Onde](repeating: Onde(), count: ReglagesNage.ondesMax)
  /// Temps de la simulation (s).
  private(set) var temps = 0.0

  private var dernier: Date?
  private var reste = 0.0
  private let rapport: Double
  private var meneur: Int?
  private var centreBanc = (x: 0.0, y: 0.0, z: 0.0, n: 0)
  private var prochaineOnde = 0
  private var scene: Hasard
  /// Secondes avant le prochain mouvement d'entrée ou de sortie (un seul à la fois, toutes les 8 à 20 s).
  private var evenement = 6.0
  private let calendrier: Bool

  /// `rapport` : hauteur / largeur de l'écran.
  /// `tousPresents` : tous là d'emblée et aucun calendrier (mode « Réduire les animations »).
  init(entrees: [Entree], rapport: Double, tousPresents: Bool = false) {
    self.rapport = max(rapport, 0.5)
    self.calendrier = !tousPresents
    self.scene = Hasard(graine: entrees.reduce(UInt64(7)) { $0 &* 31 &+ Hasard.empreinte($1.id) })
    var liste: [Nageur] = []
    liste.reserveCapacity(entrees.count)
    for (rang, e) in entrees.enumerated() {
      let profil = ProfilNage.pour(e.slug)
      var hasard = Hasard(graine: Hasard.empreinte(e.slug) &+ Hasard.empreinte(e.id) &* 31)
      let tous = e.angles.isEmpty ? [] : Array(Set(e.angles + [0])).sorted()
      var n = Nageur(
        id: e.id, nom: e.nom, slug: e.slug, largeur: e.largeur, cycle: e.cycle, imagesCycle: max(e.images, 1),
        pas: e.pas, angles: tous, volume: !e.angles.isEmpty, profil: profil,
        decalage: hasard.suivant(), lag: hasard.entre(0.15, 0.9), hasard: hasard)
      // Répartis sur la largeur (nombre d'or), à des profondeurs et des hauteurs différentes.
      let fraction = (Double(rang) * 0.618_034 + 0.13).truncatingRemainder(dividingBy: 1)
      n.x = 0.24 + 0.52 * fraction
      n.z = n.hasard.entre(0.12, 0.75)
      let (yLo, yHi) = Self.bande(profil)
      n.y = n.hasard.entre(yLo, yHi)
      n.cap = (n.hasard.suivant() < 0.5 ? 0 : Double.pi) + n.hasard.entre(-0.3, 0.3)
      n.v = profil.croisiere
      n.errance = n.hasard.entre(-0.3, 0.3)
      n.biais = n.hasard.entre(-0.18, 0.18)
      n.minuteur = n.hasard.entre(profil.nage) * n.hasard.entre(0.2, 1)
      n.yBut = n.y
      n.zBut = n.z
      n.minuteurBut = n.hasard.entre(6, 16)
      n.decalageY = n.hasard.entre(-0.07, 0.07)
      n.phase = n.hasard.suivant()
      n.cadence = 1.2
      n.lacetAffiche = Self.lacetCible(cap: n.cap)
      n.sensMiroir = cos(n.cap) >= 0 ? 1 : -1
      n.echeance = n.hasard.entre(30, 100)
      liste.append(n)
    }
    // Qui est là au départ : au moins la moitié, les autres reviennent plus tard, chacun à son heure.
    if !tousPresents, liste.count > 1 {
      let absents = liste.count - min(liste.count, max((liste.count + 1) / 2, liste.count - 2))
      var rang = 0
      for i in liste.indices.reversed() where rang < absents {
        liste[i].etat = .absent
        liste[i].echeance = liste[i].hasard.entre(6, 30)
        rang += 1
      }
      evenement = scene.entre(5, 10)
    }
    // Le meneur du banc (premier grégaire présent) et ses suiveurs, posés près de lui.
    meneur = liste.firstIndex { $0.profil.role == .banc && $0.etat == .present }
    if let m = meneur {
      let chef = liste[m]
      for i in liste.indices where i != m && liste[i].profil.role == .banc && liste[i].etat == .present {
        liste[i].x = borner(chef.x + liste[i].hasard.entre(-0.14, 0.14), 0.15, 0.85)
        liste[i].z = borner(chef.z + liste[i].hasard.entre(-0.14, 0.14), 0.05, 0.85)
        liste[i].y = borner(
          chef.y + liste[i].hasard.entre(-0.06, 0.06), ReglagesNage.ySurface, ReglagesNage.yFond)
        liste[i].cap = chef.cap + liste[i].hasard.entre(-0.2, 0.2)
        liste[i].lacetAffiche = Self.lacetCible(cap: liste[i].cap)
        liste[i].sensMiroir = cos(liste[i].cap) >= 0 ? 1 : -1
      }
    }
    nageurs = liste
    for i in nageurs.indices { rendre(i) }
  }

  // MARK: Avancer

  /// À appeler à chaque image de la `TimelineView` : avance la simulation jusqu'à `date`, par pas fixes.
  func avancer(a date: Date) {
    guard let avant = dernier else {
      dernier = date
      return
    }
    dernier = date
    reste += min(max(date.timeIntervalSince(avant), 0), ReglagesNage.trouMax)
    let h = ReglagesNage.pasFixe
    var pas = 0
    while reste >= h, pas < 16 {
      reste -= h
      pas += 1
      unPas(h)
    }
    for i in nageurs.indices { rendre(i) }
  }

  // MARK: Interaction

  /// Toucher un poisson : il vient voir la vitre, plane un instant, puis repart.
  func attirer(_ index: Int) {
    guard nageurs.indices.contains(index) else { return }
    nageurs[index].curiosite = ReglagesNage.dureeCuriosite
    nageurs[index].curiositeX = borner(0.5 + (nageurs[index].x - 0.5) * 0.4, 0.3, 0.7)
  }

  func choisir(_ index: Int?) {
    for i in nageurs.indices { nageurs[i].selectionne = (i == index) }
  }

  /// Toucher l'eau (position en part de l'écran) : une onde de lumière, et les petits poissons s'écartent doucement.
  func toucherEau(x: Double, y: Double) {
    ondes[prochaineOnde] = Onde(x: x, y: y, debut: temps)
    prochaineOnde = (prochaineOnde + 1) % ondes.count
    for i in nageurs.indices {
      let dx = nageurs[i].sx - x
      let dy = (nageurs[i].sy - y) * rapport
      let d = (dx * dx + dy * dy).squareRoot()
      guard d < ReglagesNage.rayonOnde else { continue }
      let sensibilite =
        nageurs[i].profil.role == .banc ? 1.0 : (nageurs[i].profil.role == .predateur ? 0.2 : 0.45)
      let force = (1 - d / ReglagesNage.rayonOnde) * sensibilite
      guard force > nageurs[i].ecart else { continue }
      nageurs[i].ecart = force
      let norme = max(d, 0.001)
      nageurs[i].ecartDX = dx / norme
      nageurs[i].ecartDZ = 0.6
    }
  }

  // MARK: Un pas de simulation

  private func unPas(_ h: Double) {
    temps += h
    // Le centre du banc (pour les solitaires qui l'évitent).
    var cx = 0.0
    var cy = 0.0
    var cz = 0.0
    var nb = 0
    for n in nageurs where n.profil.role == .banc && n.etat == .present {
      cx += n.x
      cy += n.y
      cz += n.z
      nb += 1
    }
    centreBanc = nb > 0 ? (cx / Double(nb), cy / Double(nb), cz / Double(nb), nb) : (0, 0, 0, 0)
    meneur = nageurs.firstIndex { $0.profil.role == .banc && $0.etat == .present }
    if calendrier {
      evenement -= h
      if evenement <= 0 { declencherEvenement() }
    }
    for i in nageurs.indices { avancer(i, h) }
  }

  /// Un seul mouvement à la fois, toutes les 8 à 20 s : un poisson repart OU un autre arrive, jamais plusieurs ensemble.
  /// Chacun ne bouge qu'après sa propre échéance (durées tirées par sa graine).
  private func declencherEvenement() {
    if nageurs.contains(where: { $0.etat == .entrant || $0.etat == .sortant }) { evenement = 2; return }
    let actifs = nageurs.filter { $0.etat == .present }.count
    let plancher = min(nageurs.count, max(1, (nageurs.count + 1) / 2))
    let partants = nageurs.indices.filter {
      let n = nageurs[$0]
      return n.etat == .present && n.echeance <= temps && !n.selectionne && n.curiosite <= 0 && actifs > plancher
    }
    let venants = nageurs.indices.filter { nageurs[$0].etat == .absent && nageurs[$0].echeance <= temps }
    guard !partants.isEmpty || !venants.isEmpty else { evenement = 2; return }
    let sort = venants.isEmpty || (!partants.isEmpty && scene.suivant() < 0.5)
    let liste = sort ? partants : venants
    let i = liste[min(Int(scene.suivant() * Double(liste.count)), liste.count - 1)]
    if sort { faireSortir(i) } else { faireEntrer(i) }
    evenement = scene.entre(8, 20)
  }

  /// Un côté et une profondeur d'entrée ou de sortie : le plus souvent par l'arrière-plan, parfois par un côté.
  private func faireSortir(_ i: Int) {
    var n = nageurs[i]
    n.etat = .sortant
    n.passeParLeFond = n.hasard.suivant() < 0.6
    n.passeADroite = n.x >= 0.5
    n.zBut = n.passeParLeFond ? n.zBut : n.hasard.entre(0.1, 0.45)
    n.mode = .nage
    n.minuteur = 60
    nageurs[i] = n
  }

  private func faireEntrer(_ i: Int) {
    var n = nageurs[i]
    n.etat = .entrant
    n.passeParLeFond = n.hasard.suivant() < 0.6
    let (yLo, yHi) = Self.bande(n.profil)
    n.y = n.hasard.entre(yLo, yHi)
    n.yBut = n.y
    n.vy = 0
    n.mode = .nage
    n.minuteur = 60
    n.v = n.profil.croisiere
    if n.passeParLeFond {
      n.z = 1.12
      n.x = n.hasard.entre(0.3, 0.7)
      n.cap = -Double.pi / 2 + n.hasard.entre(-0.5, 0.5)
      n.zBut = n.hasard.entre(0.25, 0.7)
    } else {
      n.passeADroite = n.hasard.suivant() < 0.5
      n.z = n.hasard.entre(0.1, 0.4)
      let s = 1 / (1 + 1.4 * n.z)
      // Hors de l'écran à la projection : tout le corps hors cadre avant d'entrer.
      let bord = n.passeADroite ? 1 + 0.5 * n.largeur * s + 0.04 : -0.5 * n.largeur * s - 0.04
      n.x = ReglagesNage.fuiteX + (bord - ReglagesNage.fuiteX) / s
      n.cap = n.passeADroite ? Double.pi : 0
      n.zBut = n.z
    }
    n.lacetAffiche = Self.lacetCible(cap: n.cap)
    n.sensMiroir = cos(n.cap) >= 0 ? 1 : -1
    n.omega = 0
    n.phase = n.hasard.suivant()
    nageurs[i] = n
  }

  private static func bande(_ p: ProfilNage) -> (Double, Double) {
    let haut = ReglagesNage.ySurface + (ReglagesNage.yFond - ReglagesNage.ySurface) * (1 - p.haut)
    let bas = ReglagesNage.ySurface + (ReglagesNage.yFond - ReglagesNage.ySurface) * (1 - p.bas)
    return (haut, bas)
  }

  /// Lacet en degrés pour un cap : 0 de profil, positif vers le fond, négatif vers la vitre.
  private static func lacetCible(cap: Double) -> Double {
    let a = atan2(abs(sin(cap)), abs(cos(cap))) * 180 / .pi
    return sin(cap) >= 0 ? a : -a
  }

  private func changerMode(_ n: inout Nageur) {
    let p = n.profil
    let r = n.hasard.suivant()
    switch n.mode {
    case .nage:
      n.mode = r < 0.8 ? .glisse : .plane
    case .glisse:
      if r < p.pRafale {
        n.mode = .rafale
      } else if r < p.pRafale + p.pPlane {
        n.mode = .plane
      } else {
        n.mode = .nage
      }
    case .plane:
      n.mode = r < p.pRafale * 0.7 ? .rafale : .nage
    case .rafale:
      n.mode = .glisse
    }
    n.depuisMode = 0
    switch n.mode {
    case .nage: n.minuteur = n.hasard.entre(p.nage)
    case .glisse: n.minuteur = n.hasard.entre(p.glisse)
    case .plane: n.minuteur = n.hasard.entre(p.plane)
    case .rafale: n.minuteur = n.hasard.entre(0.8, 1.5)
    }
  }

  private func avancer(_ i: Int, _ h: Double) {
    var n = nageurs[i]
    if n.etat == .absent { return }
    let present = n.etat == .present
    let p = n.profil
    let L = n.largeur
    let unite = ReglagesNage.echelleVitesse * L
    n.depuisMode += h
    n.minuteur -= h

    // 1. Mode : nage, glisse, plane ou coup de queue. Les suiveurs du banc imitent le meneur, avec un léger retard.
    var suiveur = false
    if present, p.role == .banc, let m = meneur, m != i {
      suiveur = true
      let chef = nageurs[m]
      let voulu: Nageur.Mode = chef.mode == .rafale ? .nage : chef.mode
      if voulu != n.mode, chef.depuisMode > n.lag {
        n.mode = voulu
        n.depuisMode = 0
      }
    } else if n.minuteur <= 0 {
      changerMode(&n)
    }

    // 2. Buts lents : hauteur et profondeur visées changent toutes les 8 à 20 s.
    n.minuteurBut -= h
    if n.minuteurBut <= 0 {
      let (yLo, yHi) = Self.bande(p)
      n.yBut = n.hasard.entre(yLo, yHi)
      n.zBut = n.hasard.entre(0.12, 0.78)
      n.biais = n.hasard.entre(-0.18, 0.18)
      n.minuteurBut = n.hasard.entre(8, 20)
    }
    if suiveur, let m = meneur {
      n.yBut = nageurs[m].yBut + n.decalageY
      n.zBut = nageurs[m].zBut + n.decalageY * 2
    }

    // 3. Errance : Ornstein-Uhlenbeck sur le cap (mémoire de quelques secondes).
    let amortie = (n.mode == .plane) ? 0.4 : 1.0
    n.errance +=
      (-n.errance / ReglagesNage.tauErrance) * h
      + ReglagesNage.sigmaErrance * amortie * h.squareRoot() * n.hasard.gauss()
    n.errance = borner(n.errance, -1.2, 1.2)

    // 4. La direction voulue, somme de poussées dans le plan (x, z).
    let poidsBase = suiveur ? 0.55 : 1.0
    var dx = cos(n.cap + n.errance) * poidsBase
    var dz = sin(n.cap + n.errance) * poidsBase
    dx += (cos(n.cap) >= 0 ? 1.0 : -1.0) * ReglagesNage.retourHorizontal
    dz += (n.zBut - n.z) * ReglagesNage.tractionProfondeur + n.biais

    // Murs mous : il tourne avant le bord.
    let marge = 0.45 * L + 0.03
    let m = ReglagesNage.margeMur
    let gauche = marge + m
    let droite = 1 - marge - m
    if present, n.x < gauche {
      let k = (gauche - n.x) / m
      dx += ReglagesNage.forceMur * k * k
    }
    if present, n.x > droite {
      let k = (n.x - droite) / m
      dx -= ReglagesNage.forceMur * k * k
    }
    let mp = ReglagesNage.margeProfondeur
    if present, n.z < ReglagesNage.zMin + mp {
      let k = (ReglagesNage.zMin + mp - n.z) / mp
      dz += ReglagesNage.forceMur * k * k
    }
    if present, n.z > ReglagesNage.zMax - mp {
      let k = (n.z - (ReglagesNage.zMax - mp)) / mp
      dz -= ReglagesNage.forceMur * k * k
    }

    // Banc : cohésion, alignement, séparation (suiveurs) ; tous : séparation douce entre voisins.
    var alignX = 0.0
    var alignZ = 0.0
    var voisins = 0
    for j in nageurs.indices where j != i && nageurs[j].etat != .absent {
      let o = nageurs[j]
      let ox = n.x - o.x
      let oz = n.z - o.z
      let oy = (n.y - o.y) * 0.8
      let d = (ox * ox + oz * oz + oy * oy).squareRoot()
      let ensemble = p.role == .banc && o.profil.role == .banc && present && o.etat == .present
      let rayon = (ensemble ? 0.28 : 0.5) * (L + o.largeur) * 0.5
      if d < rayon, d > 1e-4 {
        let f = (1 - d / rayon) * ReglagesNage.poidsSeparation
        dx += ox / d * f
        dz += (abs(oz) < 0.02 ? (n.id < o.id ? 0.4 : -0.4) : oz / d) * f
      }
      if suiveur, ensemble, d < ReglagesNage.rayonAlignement {
        alignX += cos(o.cap)
        alignZ += sin(o.cap)
        voisins += 1
      }
    }
    if suiveur, let mn = meneur {
      let chef = nageurs[mn]
      let cx = chef.x - n.x
      let cz = chef.z - n.z
      let d = (cx * cx + cz * cz).squareRoot()
      if d > 1e-4 {
        let f = borner(d / 0.25, 0, 1) * ReglagesNage.poidsCohesion
        dx += cx / d * f
        dz += cz / d * f
      }
      if voisins > 0 {
        dx += alignX / Double(voisins) * ReglagesNage.poidsAlignement
        dz += alignZ / Double(voisins) * ReglagesNage.poidsAlignement
      }
    } else if centreBanc.n > 0 {
      // Les solitaires évitent le banc ; un prédateur le guette de loin.
      let cx = n.x - centreBanc.x
      let cz = n.z - centreBanc.z
      let cy = (n.y - centreBanc.y) * 0.8
      let d = (cx * cx + cz * cz + cy * cy).squareRoot()
      if p.role != .banc {
        let r =
          p.role == .predateur ? ReglagesNage.rayonEvitementPredateur : ReglagesNage.rayonEvitement
        if d < r, d > 1e-4 {
          let f = (1 - d / r) * 1.6
          dx += cx / d * f
          dz += (abs(cz) < 0.02 ? 0.4 : cz / d) * f
        } else if p.role == .predateur, d > 0.45, d > 1e-4 {
          dx -= cx / d * 0.25
          dz -= cz / d * 0.25
        }
      } else if let mn = meneur, mn == i, d > 0.4, d > 1e-4 {
        // Le meneur ne s'éloigne pas trop du reste du banc.
        dx -= cx / d * 0.4
        dz -= cz / d * 0.4
      }
    }

    // Fuite : un prédateur qui bouge près des petits les fait filer, doucement.
    var fuiteCible = 0.0
    if p.role == .banc {
      var ax = 0.0
      var az = 0.0
      for j in nageurs.indices where nageurs[j].profil.role == .predateur && nageurs[j].etat == .present {
        let o = nageurs[j]
        let ox = n.x - o.x
        let oz = n.z - o.z
        let oy = (n.y - o.y) * 0.6
        let d = (ox * ox + oz * oz + oy * oy).squareRoot()
        if d < ReglagesNage.rayonFuite, d > 1e-4, o.v > 0.35 * o.profil.croisiere {
          let f = 1 - d / ReglagesNage.rayonFuite
          fuiteCible = max(fuiteCible, f)
          ax += ox / d * f
          az += oz / d * f
        }
      }
      if fuiteCible > 0 {
        let norme = max((ax * ax + az * az).squareRoot(), 1e-4)
        n.fuiteDX += (ax / norme - n.fuiteDX) * min(1, h * 4)
        n.fuiteDZ += (az / norme - n.fuiteDZ) * min(1, h * 4)
      }
    }
    let monte = fuiteCible > n.fuite
    n.fuite += (fuiteCible - n.fuite) * min(1, h * (monte ? 2.5 : 0.6))
    if n.fuite > 0.01 {
      dx += n.fuiteDX * ReglagesNage.poidsFuite * n.fuite
      dz += n.fuiteDZ * ReglagesNage.poidsFuite * n.fuite
    }

    // Toucher dans l'eau : il s'écarte doucement, vers le large et le fond.
    if n.ecart > 0 {
      n.ecart = max(0, n.ecart - h / ReglagesNage.dureeEcart)
      dx += n.ecartDX * 1.4 * n.ecart
      dz += n.ecartDZ * 1.4 * n.ecart
    }

    // Entrée et sortie : il nage vers l'arrière-plan ou un bord (sortie), ou vers l'intérieur du bac (entrée).
    if n.etat == .sortant {
      if n.mode != .nage { n.mode = .nage }
      n.minuteur = 60
      if n.passeParLeFond {
        dx = cos(n.cap) * 0.35
        dz = 2.0
      } else {
        dx = (n.passeADroite ? 1.0 : -1.0) * 2.0
        dz = (n.zBut - n.z) * 0.8
      }
    } else if n.etat == .entrant {
      if n.mode != .nage { n.mode = .nage }
      n.minuteur = 60
      if n.passeParLeFond {
        dx = (0.5 - n.x) * 0.8
        dz = -2.0
      } else {
        dx = (n.passeADroite ? -1.0 : 1.0) * 2.0
        dz = (n.zBut - n.z) * 0.8
      }
    }

    // Curiosité : il vient voir la vitre, plane, puis repart vers le large.
    var cibleY = n.yBut
    var approche = false
    if n.curiosite > 0 {
      n.curiosite = max(0, n.curiosite - h)
      if n.curiosite > ReglagesNage.finApproche {
        let gx = n.curiositeX - n.x
        let gz = 0.03 - n.z
        let d = (gx * gx + gz * gz).squareRoot()
        if d > 1e-4 {
          dx = dx * 0.25 + gx / d * 2.5
          dz = dz * 0.25 + gz / d * 2.5
        }
        cibleY = 0.40
        approche = d > 0.07
        if !approche {
          n.mode = .plane
          n.minuteur = 1
        }
      } else {
        dx += (n.x < 0.5 ? -1 : 1) * 0.7
        dz += 1.0
        if n.mode == .plane {
          n.mode = .nage
          n.minuteur = 4
        }
      }
    }

    // 5. Cap : virage borné en vitesse ET en accélération, plus lent quand il va lentement.
    let voulu = atan2(dz, dx)
    let ecartCap = ramener(voulu - n.cap)
    let vivacite = 0.3 + 0.7 * min(1, n.v / max(p.croisiere * 0.6, 1e-3))
    let omegaMax = p.virage * ReglagesNage.echelleVirage * vivacite * (n.mode == .plane ? 0.45 : 1)
    let omegaCible = borner(ecartCap * 1.6, -omegaMax, omegaMax)
    let da = ReglagesNage.accelerationAngulaire * h
    n.omega += borner(omegaCible - n.omega, -da, da)
    n.cap = ramener(n.cap + n.omega * h)

    // 6. Vitesse : cible selon le mode, accélération bornée.
    var cible: Double
    switch n.mode {
    case .nage:
      cible = p.croisiere * (0.85 + 0.3 * (0.5 + 0.5 * sin(temps * 0.31 + n.decalage * 6.28)))
    case .glisse: cible = p.croisiere * 0.22
    case .plane: cible = p.croisiere * 0.04
    case .rafale: cible = p.croisiere * p.rafale
    }
    if suiveur, let mn = meneur {
      let chef = nageurs[mn]
      let d = ((chef.x - n.x) * (chef.x - n.x) + (chef.z - n.z) * (chef.z - n.z)).squareRoot()
      cible *= 1 + borner((d - 0.12) * 3, -0.35, 0.5)
    }
    if n.fuite > 0.01 { cible = max(cible, p.croisiere * ReglagesNage.vitesseFuite * n.fuite) }
    if n.ecart > 0 { cible = max(cible, p.croisiere * 1.3 * n.ecart) }
    if n.curiosite > 0 {
      if n.curiosite > ReglagesNage.finApproche {
        cible = approche ? p.croisiere * 0.9 : p.croisiere * 0.03
      } else {
        cible = max(cible, p.croisiere * 0.7)
      }
    }
    let accel = p.accel * (n.mode == .rafale ? 4 : 1)
    let decel = 0.14 + 0.1 * p.croisiere
    n.v = max(0, n.v + borner((cible - n.v) * 1.5, -decel, accel) * h)

    // 7. Position : cap dans le plan (x, z) ; vitesse verticale lissée vers la hauteur visée.
    let vm = n.v * unite
    n.x += vm * cos(n.cap) * h
    n.z += vm * sin(n.cap) * h
    var vyCible = borner(
      (cibleY - n.y) * 0.12, -ReglagesNage.vitesseVerticaleMax, ReglagesNage.vitesseVerticaleMax)
    vyCible *= 0.35 + 0.65 * min(1, n.v / max(p.croisiere, 1e-3))
    if n.mode == .plane { vyCible *= 0.4 }
    let mh = ReglagesNage.margeHauteur
    if n.y < ReglagesNage.ySurface + mh {
      vyCible += ReglagesNage.vitesseVerticaleMax * (ReglagesNage.ySurface + mh - n.y) / mh
    }
    if n.y > ReglagesNage.yFond - mh {
      vyCible -= ReglagesNage.vitesseVerticaleMax * (n.y - (ReglagesNage.yFond - mh)) / mh
    }
    let dv = ReglagesNage.accelerationVerticale * h
    n.vy += borner(vyCible - n.vy, -dv, dv)
    n.y += n.vy * h
    // Garde-fous : les murs mous suffisent, ces bornes ne servent qu'à ne jamais sortir du bac.
    if present {
      n.x = borner(n.x, 0.03, 0.97)
      n.z = borner(n.z, 0, 0.98)
    } else {
      n.z = borner(n.z, 0, 1.25)
      n.x = borner(n.x, -2.5, 3.5)
    }
    n.y = borner(n.y, ReglagesNage.ySurface - 0.03, ReglagesNage.yFond + 0.03)

    // 8. Battement de queue : la cadence suit la vitesse ; il plane, la queue se fige sur une image douce.
    let glisse =
      (n.mode == .glisse || n.mode == .plane) && n.fuite < 0.05 && n.ecart < 0.05
      && !(n.curiosite > ReglagesNage.finApproche && approche)
    var cadenceCible =
      glisse
      ? 0
      : min(
        ReglagesNage.frequenceBase + ReglagesNage.frequenceParVitesse * n.v,
        ReglagesNage.frequenceMax)
    let fige = glisse
    if fige { cadenceCible = n.bloque ? 0 : 0.5 }
    n.cadence += (cadenceCible - n.cadence) * min(1, h / ReglagesNage.lissageCadence)
    if !fige { n.bloque = false }
    if !n.bloque {
      n.phase += n.cadence * h
      if n.phase >= 1 {
        n.phase -= 1
        if fige {
          n.bloque = true
          n.phase = Double(ReglagesNage.imageDouce) / Double(n.imagesCycle)
        }
      }
    }

    // 9. Calendrier : fin d'une entrée (il est dans le bac) ou d'une sortie (il a quitté la vue).
    let sProj = 1 / (1 + 1.4 * borner(n.z, 0, 1.1))
    let ecranX = ReglagesNage.fuiteX + (n.x - ReglagesNage.fuiteX) * sProj
    if n.etat == .sortant {
      let dehors =
        n.passeParLeFond
        ? n.z > 1.1 : (ecranX < -0.5 * L * sProj - 0.03 || ecranX > 1 + 0.5 * L * sProj + 0.03)
      if dehors {
        n.etat = .absent
        n.echeance = temps + n.hasard.entre(15, 60)
        n.v = 0
      }
    } else if n.etat == .entrant {
      let marge = 0.45 * L + 0.03 + 0.04
      let dedans = n.passeParLeFond ? n.z < ReglagesNage.zMax - 0.04 : (n.x > marge && n.x < 1 - marge)
      if dedans {
        n.etat = .present
        n.echeance = temps + n.hasard.entre(30, 100)
        n.minuteur = n.hasard.entre(n.profil.nage)
        n.depuisMode = 0
      }
    }

    nageurs[i] = n
  }

  // MARK: Ce que la vue lit

  private func rendre(_ i: Int) {
    var n = nageurs[i]
    let z = borner(n.z, 0, 1.1)
    let s = 1 / (1 + 1.4 * z)
    n.echelle = s
    n.profondeur = min(z, 1)
    n.sx = ReglagesNage.fuiteX + (n.x - ReglagesNage.fuiteX) * s
    n.sy = ReglagesNage.fuiteY + (n.y - ReglagesNage.fuiteY) * s
    // Fondu de profondeur : arrivé du fond (ou parti vers lui), il se dissout dans la brume, jamais d'apparition brusque.
    let fond = borner((z - 0.88) / 0.2, 0, 1)
    n.opacite = (1 - 0.30 * min(z, 1)) * (1 - fond * fond * (3 - 2 * fond))

    // Lacet affiché : suit le cap, en douceur.
    let lacetVoulu = Self.lacetCible(cap: n.cap)
    let pas = ReglagesNage.pasFixe
    n.lacetAffiche += (lacetVoulu - n.lacetAffiche) * (1 - exp(-pas * 4.5))
    n.lacet = n.lacetAffiche

    // Sens : le miroir ne bascule que lorsqu'il est (presque) de face ou de dos, ou déjà bien retourné.
    let c = cos(n.cap)
    if n.volume {
      let voulu: Double = c > 0.06 ? 1 : (c < -0.06 ? -1 : n.sensMiroir)
      if voulu != n.sensMiroir, abs(n.lacetAffiche) >= 68 || abs(lacetVoulu) <= 25 {
        n.sensMiroir = voulu
      }
      n.sens = n.sensMiroir
    } else {
      // Sans rendu en volume : demi-tour à plat par l'échelle horizontale, jamais nulle.
      let plat = borner(c * 2.5, -1, 1)
      n.sens = abs(plat) < 0.12 ? (n.sensMiroir >= 0 ? 0.12 : -0.12) : plat
      n.sensMiroir = n.sens >= 0 ? 1 : -1
    }
    n.melanger()

    // Assiette : le nez suit la vitesse verticale (en pixels, donc le rapport de l'écran).
    let horizontale = max(abs(n.v * ReglagesNage.echelleVitesse * n.largeur * cos(n.cap)) * s, 0.03)
    let brute = atan2(-n.vy * rapport * s, horizontale) * ReglagesNage.partAssiette
    let cibleAssiette =
      borner(brute, -ReglagesNage.assietteMax, ReglagesNage.assietteMax) * (0.4 + 0.6 * abs(c))
    n.assiette += (cibleAssiette - n.assiette) * (1 - exp(-pas * 3))
    let cibleRoulis = borner(-n.omega * 0.3, -ReglagesNage.roulisMax, ReglagesNage.roulisMax)
    n.roulis += (cibleRoulis - n.roulis) * (1 - exp(-pas * 3))

    // Image du cycle ; au planer, battements minimes autour de l'image douce.
    let images = n.imagesCycle
    var ph = n.phase
    if n.bloque {
      let onde = sin(2 * .pi * (temps * ReglagesNage.flotteCadence + n.decalage))
      let flotte = (onde * ReglagesNage.flotteImages).rounded()
      ph = (Double(ReglagesNage.imageDouce) + flotte) / Double(images)
    }
    var k = Int((ph * Double(images)).rounded(.down)) % images
    if k < 0 { k += images }
    n.image = k
    n.ondulation = 0.022 * sin(2 * .pi * n.phase) * min(1, n.cadence / 1.2)
    nageurs[i] = n
  }
}
