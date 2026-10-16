import Foundation

// Logique PURE de la nage des poissons du widget aquarium : Foundation seulement, testable sous Linux.
// Tout est déterministe (même entrée, même sortie, d'un lancement à l'autre) : pas de Hasher, pas de hasard.
// Fichier à ajouter à la cible widget (et au paquet de tests, voir AppTests/WidgetAquarium/lancer-tests.sh).

/// Où un poisson se tient dans la zone d'eau à un instant donné.
nonisolated public struct PlacementPoisson: Hashable, Sendable, Identifiable {
    /// = `Poisson.id`.
    public var id: String
    /// 0...1, gauche → droite de la zone d'eau (centre du poisson).
    public var x: Double
    /// 0...1, 0 = surface, 1 = fond.
    public var y: Double
    /// Les images regardent vers la droite ; `false` = image en miroir.
    public var versLaDroite: Bool
    /// 0.75...1.25.
    public var echelle: Double
    public var auRepas: Bool

    public init(id: String, x: Double, y: Double, versLaDroite: Bool, echelle: Double, auRepas: Bool) {
        self.id = id
        self.x = x
        self.y = y
        self.versLaDroite = versLaDroite
        self.echelle = echelle
        self.auRepas = auRepas
    }
}

nonisolated public enum NageWidget {
    /// Un poisson change de place toutes les 20 minutes.
    public static let pas: TimeInterval = 20 * 60
    /// Pendant 10 minutes après une ration, les poissons restent en surface.
    public static let dureeRepas: TimeInterval = 10 * 60
    /// La timeline couvre 6 heures.
    public static let horizon: TimeInterval = 6 * 3600

    // MARK: - Positions

    public static func placements(_ poissons: [InstantaneAquarium.Poisson], a instant: Date,
                                  dernierRepas: Date?, limite: Int, colonnes: Int = 1) -> [PlacementPoisson] {
        let gardes = Array(poissons.prefix(max(limite, 0)))
        let n = gardes.count
        guard n > 0 else { return [] }
        let creneau = creneauDe(instant)
        let repas = repasEnCours(a: instant, dernierRepas: dernierRepas)
        // Widgets larges : les poissons se partagent 2 colonnes (et changent de côté à chaque créneau),
        // ce qui double la hauteur de chaque couloir et évite qu'ils se chevauchent.
        let c = min(max(colonnes, 1), n)
        let rangees = (n + c - 1) / c

        return gardes.enumerated().map { index, poisson in
            let echelle = echelleDe(poisson)
            // Les poissons nagent au-dessus des galets du fond (le bas du décor). Au repas, ils gardent leurs couloirs
            // mais montent dans la moitié haute, vers la nourriture.
            let haut = repas ? 0.08 : 0.14
            let bas = repas ? 0.50 : 0.70
            let x = xNage(poisson.id, creneau, colonne: (index + creneau) % c, sur: c)
            let avant = xNage(poisson.id, creneau - 1, colonne: (index + creneau - 1) % c, sur: c)
            let versLaDroite = repas ? x < 0.5 : x > avant
            return PlacementPoisson(id: poisson.id, x: x,
                                    y: yNage(poisson.id, creneau, index: index / c, sur: rangees, de: haut, a: bas),
                                    versLaDroite: versLaDroite, echelle: echelle, auRepas: repas)
        }
    }

    public static func dates(depuis: Date, dernierRepas: Date?) -> [Date] {
        let fin = depuis.addingTimeInterval(horizon)
        var resultat = [depuis]
        var k = creneauDe(depuis) + 1
        while true {
            let frontiere = Date(timeIntervalSince1970: Double(k) * pas)
            if frontiere > fin { break }
            resultat.append(frontiere)
            k += 1
        }
        if let dernierRepas, repasEnCours(a: depuis, dernierRepas: dernierRepas) {
            resultat.append(dernierRepas.addingTimeInterval(dureeRepas))
        }
        resultat.sort()
        var sansDoublon: [Date] = []
        for date in resultat where sansDoublon.last != date { sansDoublon.append(date) }
        return sansDoublon
    }

    // MARK: - Nage (la boucle de 10 s)

    // Même nage que l'aquarium 3D (reports/aquarium-3d/temps-reel/nage.js et NAGE.md, lot/aquarium ecbe9a9) :
    // le poisson vise un but tiré au hasard dans sa bande de hauteur, tourne vers lui sans dépasser son virage,
    // accélère et freine en douceur, se repose au but (`calme`), puis repart. Le battement de queue accélère avec
    // la vitesse (f = 0.9 + 2.2 × vitesse / longueur). Le widget évalue cette nage à 160 instants (10 s à 16 images/s)
    // et en fait une boucle : dans un long trajet, le morceau où il revient à son point de départ (même cap, même
    // vitesse), ramené à 10 s, puis un léger recalage pour que la fin rejoigne exactement le début.

    /// Réglages d'une espèce (table ESPECES de nage.js). Vitesses en longueurs par seconde, virage en rad/s,
    /// repos au but en secondes, amplitude en part de la longueur, bande de hauteur de 0 (fond) à 1 (surface).
    public struct EspeceNage: Equatable, Sendable {
        public let croisiere: Double
        public let virage: Double
        public let calme: Double
        public let amplitude: Double
        public let bas: Double
        public let haut: Double
    }

    public static let especes: [String: EspeceNage] = [
        "brochet": .init(croisiere: 0.30, virage: 0.7, calme: 4.0, amplitude: 0.05, bas: 0.25, haut: 0.75),
        "carpe-commune": .init(croisiere: 0.45, virage: 0.9, calme: 1.5, amplitude: 0.07, bas: 0.10, haut: 0.45),
        "truite-fario": .init(croisiere: 0.70, virage: 1.4, calme: 0.6, amplitude: 0.07, bas: 0.30, haut: 0.90),
        "sandre": .init(croisiere: 0.40, virage: 0.9, calme: 2.5, amplitude: 0.06, bas: 0.15, haut: 0.55),
        "tanche": .init(croisiere: 0.35, virage: 0.8, calme: 2.5, amplitude: 0.07, bas: 0.05, haut: 0.30),
        "perche": .init(croisiere: 0.80, virage: 1.8, calme: 1.0, amplitude: 0.07, bas: 0.25, haut: 0.75),
        "gardon": .init(croisiere: 1.10, virage: 2.2, calme: 0.0, amplitude: 0.08, bas: 0.45, haut: 0.95),
        "rotengle": .init(croisiere: 1.00, virage: 2.0, calme: 0.2, amplitude: 0.08, bas: 0.55, haut: 1.00),
        "chevesne": .init(croisiere: 0.80, virage: 1.5, calme: 0.5, amplitude: 0.07, bas: 0.40, haut: 0.95),
        "black-bass": .init(croisiere: 0.55, virage: 1.4, calme: 2.0, amplitude: 0.06, bas: 0.20, haut: 0.70),
        "breme-commune": .init(croisiere: 0.45, virage: 0.8, calme: 1.0, amplitude: 0.06, bas: 0.05, haut: 0.40),
        "ablette": .init(croisiere: 1.30, virage: 2.6, calme: 0.0, amplitude: 0.08, bas: 0.60, haut: 1.00),
    ]

    /// Réglages de l'espèce ; une espèce absente de la table nage comme le gardon (comme dans nage.js).
    public static func espece(_ slug: String) -> EspeceNage {
        if let e = especes[slug] { return e }
        if slug == "perche-commune" { return especes["perche"]! }
        return especes["gardon"]!
    }

    /// Où est le poisson, vers où il regarde et quelle image de battement montrer, à une copie de la boucle.
    public struct PoseNage: Equatable, Sendable {
        /// Centre, en part de la largeur et de la hauteur du widget.
        public let x: Double
        public let y: Double
        /// Échelle horizontale : 1 = nage vers la droite, −1 = vers la gauche ; entre les deux, il fait demi-tour
        /// (il vient vers nous ou s'éloigne), comme dans l'aquarium 3D vu de face.
        public let sens: Double
        /// Image du cycle de battement de queue (0..<imagesCycle).
        public let image: Int
        /// Profondeur dans le bac, 0 = contre la vitre, 1 = au fond (les poissons du fond sont dessinés d'abord).
        public let profondeur: Double
        /// Assiette en radians (positive : il monte), au plus ±0,22.
        public let assiette: Double
        /// Taille à l'écran (perspective) : 1 = au premier plan ; plus petit quand il est loin.
        public var echelle: Double = 1
        /// Opacité : un poisson qui arrive du fond de l'océan apparaît peu à peu.
        public var opacite: Double = 1
        /// Vue rendue en volume, si l'espèce en a (images `<slug>-vue-<vue>-<k>`) : 0 = de profil,
        /// 1 = trois-quarts, il part vers le fond ; 2 = trois-quarts, il vient vers nous.
        public var vue: Int = 0
        /// Lacet en degrés : 0 = de profil, positif = il s'éloigne vers le fond, négatif = il vient vers nous.
        /// Il varie en continu : les vues rendues se fondent l'une dans l'autre (`melange`), sans saut.
        public var lacet: Double = 0
    }

    /// Les vues rendues à mélanger pour un lacet : celle juste en dessous et celle juste au-dessus (le profil, 0,
    /// est toujours là), avec leurs poids (somme 1), la plus lourde d'abord. Un fondu continu, jamais de saut.
    public static func melange(lacet: Double, angles: [Int]) -> [(angle: Int, poids: Double)] {
        let tous = Array(Set(angles + [0])).sorted()
        guard let premier = tous.first, let dernier = tous.last else { return [(0, 1)] }
        if lacet <= Double(premier) { return [(premier, 1)] }
        if lacet >= Double(dernier) { return [(dernier, 1)] }
        guard let i = tous.lastIndex(where: { Double($0) <= lacet }), i + 1 < tous.count else { return [(0, 1)] }
        let a = tous[i], b = tous[i + 1]
        let w = (lacet - Double(a)) / Double(b - a)
        if w < 1e-3 { return [(a, 1)] }
        if w > 1 - 1e-3 { return [(b, 1)] }
        return w > 0.5 ? [(b, w), (a, 1 - w)] : [(a, 1 - w), (b, w)]
    }

    /// Une boucle de `nombre` poses (10 s), pour un poisson.
    /// - `longueur` : longueur du poisson en part de la largeur du widget ; `rapport` : hauteur / largeur du widget.
    /// - `haut`, `bas` : la zone où il nage, en part de la hauteur (surface, fond).
    /// - `centre` : où sa boucle doit se tenir de préférence (part de la largeur et de la hauteur) ; donner à chaque
    ///   poisson un centre différent (son couloir de `placements`) évite qu'ils nagent tous au même endroit.
    public static func boucle(id: String, slug: String, creneau: Int = 0, nombre: Int = 80,
                              duree: TimeInterval = 10, imagesCycle: Int = 8, longueur: Double, rapport: Double,
                              haut: Double = 0.12, bas: Double = 0.72, repas: Bool = false,
                              centre: (x: Double, y: Double)? = nil) -> [PoseNage] {
        let n = max(nombre, 1)
        let e = espece(slug)
        let dt = duree / Double(n)
        let bac = Bac(largeur: 1, haut: haut * rapport, bas: bas * rapport, profondeur: 0.8 * longueur,
                      bandeBas: repas ? 0.80 : e.bas, bandeHaut: repas ? 1.0 : e.haut)

        // On fait nager le poisson 40 s (plusieurs départs, déterministes), puis on cherche dans ce trajet un moment
        // où il revient presque au même point, avec le même cap et la même vitesse, entre 6 et 16 s plus tard
        // (une récurrence). Ce morceau devient la boucle, ramené à 10 s (vitesse ajustée d'au plus ×1,6).
        let pasEchantillon = 1.0 / 16
        let echantillons = Int(40 / pasEchantillon)
        var meilleure: (etats: [Etat], debut: Int, longueur: Int) = ([], 0, 1)
        var meilleurEcart = Double.infinity
        for essai in 0..<8 {
            var graine = UInt64(hasard(id, creneau, "nage-\(essai)") * 9_007_199_254_740_992)
            var nageur = Nageur(e: e, L: longueur, bac: bac, graine: &graine)
            for _ in 0..<48 { nageur.pas(pasEchantillon, graine: &graine) }   // 3 s d'élan
            var etats: [Etat] = []
            etats.reserveCapacity(echantillons + 1)
            for _ in 0...echantillons {
                etats.append(nageur.etat)
                nageur.pas(pasEchantillon, graine: &graine)
            }
            // Chemin cumulé, pour exiger que le poisson nage vraiment pendant la boucle.
            var cumul = [0.0]
            for k in 0..<echantillons {
                cumul.append(cumul[k] + hypot(etats[k + 1].x - etats[k].x, etats[k + 1].z - etats[k].z))
            }
            // Sommes cumulées des positions, pour le centre de chaque morceau.
            var sx = [0.0], sy = [0.0]
            for k in 0...echantillons { sx.append(sx[k] + etats[k].x); sy.append(sy[k] + etats[k].y) }
            for i in stride(from: 0, to: echantillons - 96, by: 2) {
                for duree in stride(from: 96, through: min(256, echantillons - i), by: 2) {
                    let a = etats[i], b = etats[i + duree]
                    var loin = 0.0
                    if let centre {
                        let mx = (sx[i + duree] - sx[i]) / Double(duree), my = (sy[i + duree] - sy[i]) / Double(duree)
                        loin = hypot(mx - centre.x, my - centre.y * rapport) / longueur
                    }
                    let t = Double(duree) * pasEchantillon
                    let manque = max(0, 0.5 * e.croisiere * longueur * t - (cumul[i + duree] - cumul[i])) / longueur
                    let ecart = 3 * manque + 1.5 * loin + hypot(b.x - a.x, b.y - a.y) / longueur
                        + 0.5 * abs(b.z - a.z) / longueur + 1.5 * abs(angle(b.cap - a.cap))
                        + abs(b.v - a.v) / (e.croisiere * longueur) + 0.02 * abs(t - 10)
                    if ecart < meilleurEcart { meilleurEcart = ecart; meilleure = (etats, i, duree) }
                }
            }
        }

        // Rééchantillonnage sur `n` copies, et recalage : la fin rejoint le début, réparti sur la boucle.
        let (etats, i0, nb) = meilleure
        let accel = Double(nb) * pasEchantillon / duree
        func etatA(_ u: Double) -> Etat {
            let pos = Double(i0) + u * Double(nb)
            let k = min(Int(pos), etats.count - 2), f = pos - Double(k)
            let a = etats[k], b = etats[k + 1]
            return Etat(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f, z: a.z + (b.z - a.z) * f,
                        cap: a.cap + angle(b.cap - a.cap) * f, assiette: a.assiette + (b.assiette - a.assiette) * f,
                        v: (a.v + (b.v - a.v) * f) * accel)
        }
        let debut = etats[i0], fin = etats[i0 + nb]
        let dx = debut.x - fin.x, dy = debut.y - fin.y, dz = debut.z - fin.z, dcap = angle(debut.cap - fin.cap)
        let poses = (0..<n).map { etatA(Double($0) / Double(n)) }
        // Battement : un nombre entier de cycles sur la boucle, pour que l'image de fin rejoigne celle du début.
        let cycles = poses.reduce(0) { $0 + frequence($1.v, longueur) * dt }
        let echelleCycles = max(cycles.rounded(), 1) / max(cycles, 1e-6)
        var phase = hasard(id, creneau, "battement")
        let m = Double(max(imagesCycle, 1))
        return (0..<n).map { j in
            let etat = poses[j]
            let u = Double(j) / Double(n)
            let x = min(max(etat.x + dx * u, longueur * 0.45), 1 - longueur * 0.45)
            let y = min(max(etat.y + dy * u, bac.haut + 0.01), bac.bas - 0.01)
            let z = min(max(etat.z + dz * u, 0), bac.profondeur)
            // Une image plate ne se voit pas de face : on aplatit le cap (le poisson paraît de profil sauf au
            // milieu d'un demi-tour), et il n'est jamais plus étroit que 18 % de sa largeur.
            let cap = etat.cap + dcap * u
            var sens = cos(cap) / max(hypot(cos(cap), 0.35 * sin(cap)), 1e-6)
            if abs(sens) < 0.28 { sens = sens < 0 ? -0.28 : 0.28 }  // raccourci minimal de NAGE-3D.md
            let image = Int((phase * m).rounded(.down)) % max(imagesCycle, 1)
            phase = (phase + frequence(etat.v, longueur) * dt * echelleCycles).truncatingRemainder(dividingBy: 1)
            let p = bac.profondeur > 0 ? z / bac.profondeur : 0
            return PoseNage(x: x, y: y / max(rapport, 1e-6), sens: sens, image: image,
                            profondeur: p, assiette: etat.assiette, echelle: 1.04 - 0.12 * p)
        }
    }

    // MARK: - Pleine eau (Adem, 16 oct. 07h)

    // Un océan sans décor, vu en perspective : les poissons ne font plus demi-tour contre les bords, ils traversent
    // le widget, en sortent et reviennent ailleurs (un autre bord, une autre hauteur, ou du fond de l'océan).
    // Un widget ne peut pas dessiner hors de son cadre : le poisson sort par le bord et disparaît, puis rentre ailleurs.
    // Monde : X en largeurs de widget, Y en largeurs (0 = haut), Z de 0 (premier plan) à 1 (loin). Point de fuite au
    // centre ; à la profondeur z, tout est réduit de 1 / (1 + 1.4 z) (0,42 au plus loin).

    /// Réduction de perspective à la profondeur z.
    static func perspective(_ z: Double) -> Double { 1 / (1 + 1.4 * min(max(z, -0.25), 1)) }

    /// Une boucle de `nombre` poses (10 s) en pleine eau : une ou plusieurs traversées, chacune d'un point hors du
    /// widget à un autre. `longueur` : longueur du poisson au premier plan, en part de la largeur ; `rapport` : h / l.
    public static func traversees(id: String, slug: String, creneau: Int = 0, nombre: Int = 160,
                                  duree: TimeInterval = 10, imagesCycle: Int = 8, longueur: Double,
                                  rapport: Double) -> [PoseNage] {
        let n = max(nombre, 1)
        let e = espece(slug)
        var graine = UInt64(hasard(id, creneau, "pleine-eau") * 9_007_199_254_740_992)
        let h = max(rapport, 0.1)
        let fuite = (x: 0.5, y: h * 0.45)
        // Vitesse visée à l'écran (largeurs par seconde) : celle de l'espèce, lisible dans un petit cadre.
        let vise = min(max(e.croisiere * longueur * 1.8, 0.11), 0.32)
        let k = max(1, min(3, Int((duree * vise / 1.4).rounded(.down))))
        let tranche = duree / Double(k)

        // Les traversées : départ et arrivée hors du cadre (à l'écran), à une profondeur donnée.
        struct Traversee { var a: (x: Double, y: Double, z: Double); var b: (x: Double, y: Double, z: Double)
                           var c: (x: Double, y: Double, z: Double); var duFond: Bool }
        func monde(_ ex: Double, _ ey: Double, _ z: Double) -> (x: Double, y: Double, z: Double) {
            let s = perspective(z)
            return (fuite.x + (ex - fuite.x) / s, fuite.y + (ey - fuite.y) / s, z)
        }
        var chemins: [Traversee] = []
        var versLaDroite = entre(0, 1, &graine) < 0.5
        for _ in 0..<k {
            // Trois sortes de passage : il sort du fond et vient vers nous, il part vers le fond depuis un bord,
            // ou il traverse en changeant de profondeur. z < 0 : tout près de la vitre, plus grand que nature.
            let sorte = entre(0, 1, &graine)
            let duFond = sorte < 0.25, versLeFond = !duFond && sorte < 0.5
            let za = duFond ? 1.0 : (versLeFond ? entre(-0.25, 0.2, &graine) : entre(-0.2, 0.85, &graine))
            let zb = duFond ? entre(-0.25, 0.3, &graine)
                : (versLeFond ? 1.0 : min(max(za + entre(-0.5, 0.5, &graine), -0.25), 0.9))
            let marge = { (z: Double) in longueur * perspective(z) * 0.6 }
            let gauche = { (z: Double) in -marge(z) }, droite = { (z: Double) in 1 + marge(z) }
            // Départ : un bord (gauche ou droite), à n'importe quelle hauteur, coins compris ; ou au loin, dans l'eau.
            let ex0 = duFond ? entre(0.25, 0.75, &graine) : (versLaDroite ? gauche(za) : droite(za))
            let ey0 = duFond ? entre(h * 0.25, h * 0.75, &graine) : entre(-0.05 * h, 1.05 * h, &graine)
            // Arrivée : le bord d'en face, ou parfois le haut ou le bas (il plonge ou remonte en sortant).
            let tirage = entre(0, 1, &graine)
            var ex1 = versLaDroite ? droite(zb) : gauche(zb)
            var ey1 = entre(-0.05 * h, 1.05 * h, &graine)
            if versLeFond {
                // Il s'enfonce vers le point de fuite et se perd dans le bleu.
                ex1 = entre(0.3, 0.7, &graine); ey1 = entre(h * 0.3, h * 0.7, &graine)
            } else if tirage < 0.2 {
                ex1 = entre(0.55, 0.95, &graine); if !versLaDroite { ex1 = 1 - ex1 }
                ey1 = tirage < 0.1 ? -marge(zb) : h + marge(zb)
            }
            let a = monde(ex0, ey0, za), b = monde(ex1, ey1, zb)
            // Point de contrôle : une courbe douce, un peu au-dessus ou au-dessous de la ligne droite.
            let mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2
            let c = (x: mx, y: my + entre(-0.25, 0.25, &graine) * h, z: (a.z + b.z) / 2)
            chemins.append(Traversee(a: a, b: b, c: c, duFond: duFond))
            if entre(0, 1, &graine) < 0.6 { versLaDroite.toggle() }
        }

        func point(_ t: Traversee, _ u: Double) -> (x: Double, y: Double, z: Double) {
            let v = 1 - u
            return (v * v * t.a.x + 2 * v * u * t.c.x + u * u * t.b.x,
                    v * v * t.a.y + 2 * v * u * t.c.y + u * u * t.b.y,
                    v * v * t.a.z + 2 * v * u * t.c.z + u * u * t.b.z)
        }
        // Avance douce le long de la courbe (légère accélération puis croisière), et ondulation verticale.
        let ondule = entre(0, 2 * .pi, &graine)
        var etats: [(x: Double, y: Double, z: Double, vx: Double, vy: Double, vz: Double, vitesse: Double)] = []
        for j in 0...n {
            let t = Double(j) / Double(n) * duree
            let i = min(Int(t / tranche), k - 1)
            let u = min(max((t - Double(i) * tranche) / tranche, 0), 1)
            let du = 1e-3
            let p0 = point(chemins[i], u), p1 = point(chemins[i], min(u + du, 1)), pm = point(chemins[i], max(u - du, 0))
            let dt = (min(u + du, 1) - max(u - du, 0)) * tranche
            let houle = 0.012 * sin(2 * .pi * t / 3.3 + ondule)
            let vx = (p1.x - pm.x) / dt, vy = (p1.y - pm.y) / dt, vz = (p1.z - pm.z) / dt
            etats.append((p0.x, p0.y + houle, p0.z, vx, vy, vz, (vx * vx + vy * vy).squareRoot()))
        }
        // Battement : nombre entier de cycles sur la boucle.
        let dt = duree / Double(n)
        let cycles = etats.prefix(n).reduce(0) { $0 + frequence($1.vitesse, longueur) * dt }
        let echelleCycles = max(cycles.rounded(), 1) / max(cycles, 1e-6)
        var phase = hasard(id, creneau, "battement")
        let m = Double(max(imagesCycle, 1))
        return (0..<n).map { j in
            let q = etats[j]
            let s = perspective(q.z)
            let ex = fuite.x + (q.x - fuite.x) * s, ey = fuite.y + (q.y - fuite.y) * s
            // Cap : surtout de profil ; il ne s'amincit que s'il fonce vers nous ou s'éloigne.
            let cap = atan2(-q.vz * 0.6, q.vx)
            var sens = cos(cap) / max(hypot(cos(cap), 0.35 * sin(cap)), 1e-6)
            if abs(sens) < 0.28 { sens = sens < 0 ? -0.28 : 0.28 }  // raccourci minimal de NAGE-3D.md
            let assiette = min(max(atan2(-q.vy, abs(q.vx) + 1e-6) * 0.6, -0.22), 0.22)
            let image = Int((phase * m).rounded(.down)) % max(imagesCycle, 1)
            phase = (phase + frequence(q.vitesse, longueur) * dt * echelleCycles).truncatingRemainder(dividingBy: 1)
            // Il sort du bleu lointain peu à peu (au-delà de z = 0,7), et se perd un peu dans l'eau au loin.
            let opacite = min(1, max(0, (1 - q.z) / 0.3) * (1 - 0.25 * max(q.z, 0)))
            // Au-delà de 22,5° du profil, la vue trois-quarts (vers le fond ou vers nous).
            let lacet = atan2(q.vz * 0.6, abs(q.vx)) * 180 / .pi
            let vue = abs(lacet) > 22.5 ? (lacet > 0 ? 1 : 2) : 0
            return PoseNage(x: ex, y: ey / h, sens: sens, image: image, profondeur: q.z, assiette: assiette,
                            echelle: s, opacite: opacite, vue: vue, lacet: lacet)
        }
    }

    /// Images par battement de queue au plus : 16 avec les rendus en volume. À 8 si la mémoire ou la timeline
    /// ne suivent pas : on ne garde alors que les images paires.
    public static let imagesParBattementMax = 8

    /// Combien d'images du battement on montre, et le pas entre deux numéros d'image, pour une espèce qui en a
    /// `disponibles` (16 pour les rendus en volume, 8 pour les anciens, 0 sans cycle).
    public static func cycleUtilise(disponibles: Int, plafond: Int = imagesParBattementMax) -> (images: Int, pas: Int) {
        guard disponibles > 0 else { return (0, 1) }
        var pas = 1
        while disponibles / pas > max(plafond, 1), disponibles % (pas * 2) == 0 { pas *= 2 }
        return (disponibles / pas, pas)
    }

    /// Battements par seconde (nage.js), plafonnés à 3,5 : au-delà, 8 images par seconde ne suivent plus.
    static func frequence(_ v: Double, _ L: Double) -> Double {
        min(0.9 + 2.2 * v / max(L, 1e-6), 3.5)
    }

    /// Angle ramené entre −π et π.
    static func angle(_ a: Double) -> Double {
        var a = a.truncatingRemainder(dividingBy: 2 * .pi)
        if a > .pi { a -= 2 * .pi }
        if a < -.pi { a += 2 * .pi }
        return a
    }

    /// Le bac en unités de largeur du widget : x de 0 à 1, y vers le bas (0 = haut du widget), z vers le fond.
    struct Bac {
        let largeur: Double
        let haut: Double
        let bas: Double
        let profondeur: Double
        /// Bande de hauteur de l'espèce, 0 = fond, 1 = surface (comme `bas`/`haut` dans nage.js).
        let bandeBas: Double
        let bandeHaut: Double
    }

    struct Etat {
        var x: Double, y: Double, z: Double, cap: Double, assiette: Double, v: Double
    }

    /// Portage de `Nageur.pas(dt)` de nage.js, en 2D vue de face (x, y) plus la profondeur z. Le cap est l'angle
    /// autour de la verticale : cos(cap) vers la droite, −sin(cap) vers le fond.
    struct Nageur {
        let e: EspeceNage
        let L: Double
        let bac: Bac
        var x: Double, y: Double, z: Double
        var cap: Double
        var assiette = 0.0
        var v: Double
        var attente = 0.0
        var but: (x: Double, y: Double, z: Double) = (0, 0, 0)

        init(e: EspeceNage, L: Double, bac: Bac, graine: inout UInt64) {
            self.e = e
            self.L = L
            self.bac = bac
            x = 0; y = 0; z = 0; cap = 0
            v = e.croisiere * L * 0.6
            let depart = Self.tirerBut(e: e, L: L, bac: bac, graine: &graine)
            x = depart.x; y = depart.y; z = depart.z
            cap = Double(aleatoire(&graine)) * 2 * .pi
            but = Self.tirerBut(e: e, L: L, bac: bac, graine: &graine)
        }

        var etat: Etat { Etat(x: x, y: y, z: z, cap: cap, assiette: assiette, v: v) }

        static func tirerBut(e: EspeceNage, L: Double, bac: Bac, graine: inout UInt64) -> (x: Double, y: Double, z: Double) {
            let m = L * 0.6
            let hauteur = bac.bas - bac.haut
            // y vers le bas : la bande 0 (fond) est en `bas`, la bande 1 (surface) en `haut`.
            let y0 = max(bac.bas - hauteur * bac.bandeHaut, bac.haut + 0.01)
            let y1 = min(bac.bas - hauteur * bac.bandeBas, bac.bas - 0.01)
            return (entre(m, bac.largeur - m, &graine), entre(y0, max(y1, y0), &graine),
                    entre(0, bac.profondeur, &graine))
        }

        mutating func pas(_ dt: Double, graine: inout UInt64) {
            // Sous-pas de 1/32 s : le virage limité et les lissages restent stables.
            let sous = max(Int((dt * 32).rounded(.up)), 1)
            for _ in 0..<sous { petitPas(dt / Double(sous), graine: &graine) }
        }

        private mutating func petitPas(_ dt: Double, graine: inout UInt64) {
            let dx = but.x - x, dy = y - but.y, dz = but.z - z     // dy positif : le but est plus haut
            let dh = (dx * dx + dz * dz).squareRoot()
            let d = (dh * dh + dy * dy).squareRoot()
            let croisiere = e.croisiere * L
            var cible: Double
            if attente > 0 {
                // Au repos au but : il tient son poste en ondulant doucement.
                attente -= dt
                cible = 0.06 * L
                if attente <= 0 { but = Self.tirerBut(e: e, L: L, bac: bac, graine: &graine) }
            } else if d < L * 0.4 {
                attente = e.calme * entre(0.5, 1.5, &graine)
                cible = 0.1 * L
                if attente <= 0 { but = Self.tirerBut(e: e, L: L, bac: bac, graine: &graine) }
            } else {
                cible = croisiere * min(1, 0.4 + d / (L * 2))
            }
            v += (cible - v) * min(1, dt * 1.2)
            // Virage vers le but, limité.
            let capVoulu = atan2(-dz, dx)
            let diff = NageWidget.angle(capVoulu - cap)
            var tour = max(-e.virage * dt, min(e.virage * dt, diff * min(1, dt * 2.5)))
            if v < 0.12 * L { tour *= 0.4 }
            cap = NageWidget.angle(cap + tour)
            let assietteVoulue = max(-0.22, min(0.22, atan2(dy, max(dh, 1e-3)) * 0.5))
            assiette += (assietteVoulue - assiette) * min(1, dt * 1.5)
            let c = cos(cap), s = sin(cap), ca = cos(assiette)
            x += c * ca * v * dt
            z -= s * ca * v * dt
            y -= sin(assiette) * v * dt
            let mg = L * 0.45
            x = min(max(x, mg), bac.largeur - mg)
            y = min(max(y, bac.haut + 0.01), bac.bas - 0.01)
            z = min(max(z, 0), bac.profondeur)
        }
    }

    /// Générateur SplitMix64 : même graine, même suite, sur toutes les plateformes.
    static func aleatoire(_ etat: inout UInt64) -> Double {
        etat &+= 0x9e3779b97f4a7c15
        var z = etat
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        z ^= z >> 31
        return Double(z >> 11) / 9_007_199_254_740_992.0
    }

    static func entre(_ a: Double, _ b: Double, _ graine: inout UInt64) -> Double {
        a + aleatoire(&graine) * (b - a)
    }

    // MARK: - Détails

    private static func creneauDe(_ instant: Date) -> Int {
        Int((instant.timeIntervalSince1970 / pas).rounded(.down))
    }

    private static func repasEnCours(a instant: Date, dernierRepas: Date?) -> Bool {
        guard let dernierRepas else { return false }
        let ecart = instant.timeIntervalSince(dernierRepas)
        return ecart >= 0 && ecart < dureeRepas
    }

    /// Position horizontale entre 0.18 et 0.82. Sur 2 colonnes, chaque poisson reste près du centre de sa moitié
    /// (0.25 ou 0.75, à ±0.06 près) : deux voisins de rangée sont à 0.38 l'un de l'autre au moins, plus qu'un poisson.
    private static func xNage(_ id: String, _ creneau: Int, colonne: Int, sur c: Int) -> Double {
        guard c > 1 else { return 0.18 + 0.64 * hasard(id, creneau, "x") }
        let centre = (Double((colonne % c + c) % c) + 0.5) / Double(c)
        let x = centre + (hasard(id, creneau, "x") - 0.5) * 0.12
        return min(max(x, 0.18), 0.82)
    }

    /// Couloir vertical de l'index `index` parmi `sur`, réparti entre `haut` et `bas`, avec un petit décalage dedans.
    private static func yNage(_ id: String, _ creneau: Int, index: Int, sur n: Int, de haut: Double, a bas: Double) -> Double {
        let largeur = (bas - haut) / Double(n)
        let centre = haut + largeur * (Double(index) + 0.5)
        return centre + (hasard(id, creneau, "y") - 0.5) * largeur * 0.3
    }

    private static func echelleDe(_ poisson: InstantaneAquarium.Poisson) -> Double {
        let ecart = (hasard(poisson.id, 0, "echelle") - 0.5) * 0.1
        return min(max(0.9 + 0.1 * Double(poisson.rarete) + ecart, 0.75), 1.25)
    }

    /// Nombre pseudo-aléatoire dans [0, 1), stable : FNV-1a 64 bits sur « id, sel, créneau », puis mélange final.
    static func hasard(_ id: String, _ creneau: Int, _ sel: String) -> Double {
        var h: UInt64 = 0xcbf29ce484222325
        func melanger(_ octet: UInt8) {
            h ^= UInt64(octet)
            h = h &* 0x100000001b3
        }
        for o in id.utf8 { melanger(o) }
        melanger(0xff)
        for o in sel.utf8 { melanger(o) }
        melanger(0xff)
        let c = UInt64(bitPattern: Int64(creneau))
        for i in 0..<8 { melanger(UInt8(truncatingIfNeeded: c >> (8 * UInt64(i)))) }
        // Mélange final (FNV varie peu sur les derniers octets).
        h ^= h >> 33
        h = h &* 0xff51afd7ed558ccd
        h ^= h >> 33
        return Double(h >> 11) / 9007199254740992.0
    }
}
