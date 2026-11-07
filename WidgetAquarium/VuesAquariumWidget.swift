import AppIntents
import SwiftUI
import UIKit
import WidgetKit

// Cible widget seulement. Les vues du widget « Mon aquarium » : l'eau, les poissons, le bouton nourrir, l'écran verrouillé.
// Peu de texte (règle de la démo) : des poissons, un chiffre, une icône. Aucun lieu.
// `WidgetAquarium/` n'importe pas `App/Style` : la palette « Marine » est répétée ici, comme dans Widget/Session.

private enum Teintes {
    static let marine = Color(red: 13 / 255, green: 74 / 255, blue: 133 / 255)        // #0D4A85
    static let fond = Color(red: 8 / 255, green: 42 / 255, blue: 76 / 255)            // #082A4C
    static let rare = Color(red: 91 / 255, green: 79 / 255, blue: 208 / 255)          // #5B4FD0, violet
    static let legendaire = Color(red: 176 / 255, green: 122 / 255, blue: 18 / 255)   // #B07A12, or bruni
    static let sable = Color(red: 214 / 255, green: 190 / 255, blue: 150 / 255)
    static let nourriture = Color(red: 233 / 255, green: 201 / 255, blue: 138 / 255)
}

private let urlAquarium = URL(string: "fishme://aquarium")
private let urlPro = URL(string: "fishme://pro?source=widget")

/// Combien de poissons nagent : 3 en petit, 5 partout ailleurs (le pêcheur les choisit, 5 au plus).
/// Sert aussi au fournisseur (`AquariumWidget.swift`) pour réduire l'instantané avant la timeline.
nonisolated func limitePoissons(_ famille: WidgetFamily) -> Int {
    InstantaneAquarium.limiteAffichee(petit: famille == .systemSmall)
}

/// Largeur d'un poisson, en part de la largeur du widget (avant son échelle).
private func partPoisson(_ famille: WidgetFamily) -> Double {
    switch famille {
    case .systemSmall: 0.44
    case .systemMedium: 0.26
    case .systemLarge: 0.32
    default: 0.24
    }
}


// MARK: - L'eau

/// Le fond du widget : le décor rendu en 3D (eau, plantes, galets), ou le décor choisi (illustration ou dessin) ; un simple dégradé en rendu teinté.
private struct FondEau: View {
    let famille: WidgetFamily
    /// Décor (N1) ; `nil` = fond d'origine. L'image du décor absente du widget = repli sur `fond-<format>`.
    var skin: String? = nil
    /// Faux coupe l'animation (rendu en image : `ImageRenderer` ne fait pas tourner les chronos).
    var anime: Bool = true
    @Environment(\.widgetRenderingMode) private var rendu

    private var accentue: Bool { rendu == .accented }

    var body: some View {
        switch famille {
        case .accessoryRectangular, .accessoryCircular, .accessoryInline:
            Color.clear
        default:
            if accentue {
                // Rendu teinté : iOS impose une teinte, une photo y deviendrait une tache grise.
                LinearGradient(colors: [Color(white: 0.30), Color(white: 0.14)], startPoint: .top, endPoint: .bottom)
            } else {
                // Eau, vallisnéries, galets, roches et bois : rendus en 3D par le fil Aquarium (scene.py, v2), sans poissons.
                // Le décor choisi dans l'aquarium : son illustration si elle existe, sinon le même dessin que l'app
                // (rendu une fois en image, fichiers `DecorsDessines*.swift` partagés), sinon le fond d'origine.
                switch source {
                case .image(let nom), .repli(let nom):
                    Image(nom)
                        .resizable()
                        .scaledToFill()
                case .dessin(let id):
                    FondDecorWidget(skin: id, nomFond: FondWidget.nomRepli(format))
                }
            }
        }
    }

    private var format: FondWidget.Format {
        switch famille {
        case .systemSmall: .petit
        case .systemMedium: .moyen
        default: .grand
        }
    }

    private var source: FondWidget.Source {
        // ⚠ à vérifier : UIImage(named:) dans l'extension cherche dans son propre bundle (FondsWidget.xcassets).
        FondWidget.source(skin: skin, format: format, existe: { UIImage(named: $0) != nil })
    }
}

// MARK: - Les poissons

/// Le moteur d'animation des poissons. Mesuré le 7 nov. (lot/widget-fluide, simulateur iPhone 17 iOS 27.2, Debug,
/// petit format, 3 poissons ; pic = `phys_footprint_peak` de l'extension ; statique = 27 Mo) :
/// ce qui coûte, ce sont les IMAGES distinctes (chaque image de queue en plus : ~5 Mo de pic), pas les copies ni
/// les chronos. Détail : WidgetAquarium/Polices/LISEZMOI.md, « Mesures du 7 nov. ».
nonisolated enum PisteNage: String, Sendable {
    /// Une pose par poisson ; elle change au créneau suivant de la timeline (20 min). Repli : Réduire les
    /// animations, écran verrouillé, rendu teinté, widget verrouillé non Pro.
    case statique
    /// Essai : 16 copies, 16 images de queue, masques en union de 5 chronos. Pic 67 Mo : placeholder gris.
    case battement
    /// Piste a : déplacement sur une boucle de 10 s à 8 images/s (80 copies). Pic 70 Mo : placeholder gris.
    case nage10
    /// Aperçu de l'app seulement : 160 copies (10 s à 16 images/s).
    case complete
    /// Essai Debug : `ProgressView(timerInterval:)` (la barre avance seule) et effet de symbole (immobile).
    case chrono
    /// Essai Debug : entrées toutes les 10 s, `.animation` de 2 s entre deux (piste c) : saut sans glissement, pic 38 Mo.
    case glisse
    /// Essai : comme `battement`, 4 images de queue. Pic 56 Mo : placeholder gris.
    case ondule
    /// Essai : masques en police de parité (2 chronos par copie), 4 images de queue, 16 copies. Pic 45 Mo.
    case parite
    /// Essais : comme `parite` à 6, 4, 2 ou 1 image(s)/s (pics 44, 46, 35, 35 Mo).
    case parite6, parite4, parite2, parite1
    /// UNE image par poisson, la nage par transformations (va-et-vient, tangage, corps qui respire), boucle de
    /// 2 s en polices de parité : 8, 12 ou 16 images/s (16, 24, 32 copies) ; pics 29, 31, 32 Mo. `fixe24` : retenue.
    case fixe16, fixe24, fixe32
    /// LA BALADE : une image par poisson (léger), mais chaque poisson suit sa traversée de 10 s (NageWidget.traversees) :
    /// 120 copies (12 images/s), polices de chiffres (2 chronos par copie), pose de trajet + ondulation courte (8 images).
    case balade
    /// Mêmes balades à 4 et 6 images/s (40 et 60 copies) : moins de mémoire (mesuré : ~0,35 Mo par copie).
    case balade4, balade6
    /// LA PISTE RETENUE (7 nov.) : balancement gauche-droite LENT et fluide. Taille constante (pas de perspective : une seule
    /// image rastérisée par poisson), un aller-retour de 10 s (5 s pour un poisson sur deux), demi-tour quand il change de
    /// sens, petit va-et-vient vertical et tangage. Mouvement lent = peu d'images suffisent : 3 images/s sur 10 s = 30
    /// copies (`douce`) ou 4 images/s = 40 copies (`douce4`).
    case douce, douce4
    /// Essai : un calque par poisson (copies à sa taille). Pic 48 Mo : placeholder gris.
    case calques
    /// LA PISTE LÉGÈRE (7 nov., après le lag constaté sur iPhone) : UN SEUL poisson animé, dans un petit cadre à sa taille
    /// (les 16 copies et leurs masques chronos sont minuscules au lieu de couvrir le widget), une seule image, boucle de
    /// 2 s à 8 images/s, un chrono par masque (polices de parité). Les autres poissons restent figés, dessinés une fois.
    case solo

    var boucle: HorlogeAnimation.Boucle {
        switch self {
        case .nage10: HorlogeAnimation.Boucle(parSeconde: 8, duree: 10)
        case .parite6: HorlogeAnimation.Boucle(parSeconde: 6, duree: 2)
        case .parite4: HorlogeAnimation.Boucle(parSeconde: 4, duree: 2)
        case .parite2: HorlogeAnimation.Boucle(parSeconde: 2, duree: 2)
        case .parite1: HorlogeAnimation.Boucle(parSeconde: 1, duree: 2)
        case .fixe24: HorlogeAnimation.Boucle(parSeconde: 12, duree: 2)
        case .balade: HorlogeAnimation.Boucle(parSeconde: 12, duree: 10)
        case .balade4: HorlogeAnimation.Boucle(parSeconde: 4, duree: 10)
        case .balade6: HorlogeAnimation.Boucle(parSeconde: 6, duree: 10)
        case .douce: HorlogeAnimation.Boucle(parSeconde: 3, duree: 10)
        case .douce4: HorlogeAnimation.Boucle(parSeconde: 4, duree: 10)
        case .fixe32: HorlogeAnimation.Boucle(parSeconde: 16, duree: 2)
        default: .battement
        }
    }

    /// Images de queue distinctes par poisson sur une boucle (0 : toutes, comme `battement`).
    var imagesQueue: Int {
        switch self {
        case .ondule, .parite, .parite6, .parite4, .calques: 4
        case .parite2, .parite1: 2
        case .fixe16, .fixe24, .fixe32, .balade, .balade4, .balade6, .solo: 1
        case .douce, .douce4: 2
        default: 0
        }
    }

    var estBalade: Bool { self == .balade || self == .balade4 || self == .balade6 }

    var parite: Bool { [.parite, .parite6, .parite4, .parite2, .parite1, .fixe16, .fixe24, .fixe32, .calques, .solo].contains(self) }

    /// Durée d'un créneau de positions (20 min ; 10 s pour l'essai `glisse`).
    var pasCreneau: TimeInterval { self == .glisse ? 10 : NageWidget.pas }

    /// La piste du vrai widget. En Debug, un fichier `piste-widget.txt` dans l'App Group la remplace (essais).
    static var widget: PisteNage {
        #if DEBUG
        if let url = DepotAquariumWidget.url()?.deletingLastPathComponent().appendingPathComponent("piste-widget.txt"),
           let texte = try? String(contentsOf: url, encoding: .utf8),
           let lue = PisteNage(rawValue: texte.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return lue
        }
        #endif
        return .solo
    }

    #if DEBUG
    /// Debug : les témoins (texte, carrés de chronos) ne s'affichent que si un fichier `diagnostic-widget.txt` existe dans l'App Group.
    static var diagnosticActif: Bool {
        guard let url = DepotAquariumWidget.url()?.deletingLastPathComponent().appendingPathComponent("diagnostic-widget.txt") else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    #endif
}

#if DEBUG
/// Essai piste b : une barre `ProgressView(timerInterval:)` (le système la fait avancer seul) et la même dans un
/// style personnalisé qui place un poisson à `fractionCompleted` : bouge-t-il dans l'hôte des widgets ?
private struct ChronoProgression: View {
    let debut: Date

    private struct StylePoisson: ProgressViewStyle {
        func makeBody(configuration: Configuration) -> some View {
            GeometryReader { geo in
                Image(systemName: "fish.fill")
                    .foregroundStyle(.orange)
                    .position(x: geo.size.width * (configuration.fractionCompleted ?? 0), y: geo.size.height / 2)
            }
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            ProgressView(timerInterval: debut...debut.addingTimeInterval(60), countsDown: false) { EmptyView() }
                currentValueLabel: { EmptyView() }
                .progressViewStyle(.linear)
                .tint(.white)
            ProgressView(timerInterval: debut...debut.addingTimeInterval(60), countsDown: false) { EmptyView() }
                currentValueLabel: { EmptyView() }
                .progressViewStyle(StylePoisson())
                .frame(height: 20)
            // Piste d : effet de symbole répété (bouge-t-il hors de l'app ?).
            Image(systemName: "fish.fill")
                .font(.title)
                .foregroundStyle(.yellow)
                .symbolEffect(.wiggle, options: .repeat(.continuous))
            Spacer()
        }
        .padding(8)
    }
}
#endif

private struct CoucheNage: View {
    let entree: EntreeAquarium
    let famille: WidgetFamily
    /// Faux : poissons figés (tests d'image, repli sans animation).
    var anime: Bool = true
    /// Moteur d'animation (voir `PisteNage`) : `.battement` dans le vrai widget, `.complete` dans l'aperçu de l'app.
    var piste: PisteNage = .battement
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @Environment(\.widgetRenderingMode) private var rendu

    private static func estAccessoire(_ famille: WidgetFamily) -> Bool {
        switch famille {
        case .accessoryRectangular, .accessoryCircular, .accessoryInline: true
        default: false
        }
    }

    /// Un poisson prêt à nager : son espèce, sa largeur à l'écran et sa boucle de 10 s (une pose par copie).
    private struct Nageur: Identifiable {
        let placement: PlacementPoisson
        let slug: String
        let largeur: CGFloat
        let cycle: Bool
        /// Pas entre deux numéros d'image du battement (2 : images paires seulement).
        let pas: Int
        /// Images par battement réellement utilisées (8 au plus ; 0 : image fixe).
        var imagesCycle: Int = 0
        /// Lacets rendus en volume (fil Aquarium) ; vide : le profil aplati horizontalement.
        let angles: [Int]
        let poses: [NageWidget.PoseNage]
        var id: String { placement.id }

        /// Numéro de la pose montrée quand rien ne s'anime (j < 0). La pose 0 d'une traversée part hors du cadre :
        /// on prend la pose où le poisson se voit le mieux (opaque, de loin le plus grand, le plus dans le cadre,
        /// de préférence dans les 2/3 hauts : le bouton nourrir est en bas à droite). `l` : largeur du widget.
        func repos(l: CGFloat) -> Int {
            func score(_ p: NageWidget.PoseNage) -> Double {
                let demi = Double(largeur / max(l, 1)) * p.echelle / 2
                let partX = max(0, min(p.x + demi, 1) - max(p.x - demi, 0)) / max(2 * demi, 1e-6)
                let partY = (p.y > 0.08 && p.y < 0.62) ? 1.0 : ((p.y > 0 && p.y < 1.1) ? 0.5 : 0)
                return p.opacite * partX * partY * p.echelle
            }
            var meilleur = poses.count / 2
            var points = 0.0
            for (j, pose) in poses.enumerated() where score(pose) > points + 1e-9 { meilleur = j; points = score(pose) }
            return meilleur
        }
    }

    var body: some View {
        let instantane = entree.instantane
        // Les placements donnent à chaque poisson son coin de l'aquarium (couloir et côté) : sa nage s'y tient.
        let placements = NageWidget.placements(
            instantane.poissons, a: entree.date, dernierRepas: instantane.dernierRepas, limite: limitePoissons(famille),
            colonnes: famille == .systemSmall ? 1 : 2)
        let parId = Dictionary(instantane.poissons.map { ($0.id, $0) }, uniquingKeysWith: { premier, _ in premier })
        let part = partPoisson(famille)
        // Rendu teinté : iOS remplace le fond, les copies (qui portent l'eau) le cacheraient. Poissons fixes.
        let animePoissons = anime && !reduireAnimations && !Self.estAccessoire(famille) && rendu != .accented
        let reference = HorlogeAnimation.reference(pour: entree.date)
        let creneau = Int((entree.date.timeIntervalSince1970 / piste.pasCreneau).rounded(.down))

        GeometryReader { geo in
            let l = geo.size.width
            let h = geo.size.height
            let boucle = piste.boucle
            // Pleine eau : chaque poisson traverse en perspective (NageWidget.traversees), calculé une fois par poisson.
            let nageurs: [Nageur] = placements.compactMap { placement in
                guard let poisson = parId[placement.id] else { return nil }
                let longueur = part * placement.echelle
                let battement = NageWidget.cycleUtilise(disponibles: PoissonVivant.imagesDisponibles(poisson.slug))
                return Nageur(placement: placement, slug: poisson.slug, largeur: l * longueur,
                              cycle: battement.images > 0, pas: battement.pas, imagesCycle: battement.images,
                              angles: battement.images > 0 ? PoissonVivant.anglesDisponibles(poisson.slug) : [],
                              // Pleine eau (Adem, 16 oct. 07h) : traversées en perspective, sorties par les bords.
                              poses: NageWidget.traversees(id: poisson.id, slug: poisson.slug, creneau: creneau,
                                                           nombre: piste == .complete ? HorlogeAnimation.nombreImages
                                                               : ((piste == .nage10 || piste.estBalade) ? boucle.copies : 32),
                                                           imagesCycle: max(battement.images, 1), longueur: longueur,
                                                           rapport: Double(h / max(l, 1))))
            }
            ZStack {
                switch (animePoissons, piste) {
                case (true, .complete):
                    // Aperçu de l'app seulement : 160 copies (10 s à 16 images/s) de TOUS les poissons, masquées par
                    // des chronos. Trop lourd pour l'extension (placeholder gris, 7 nov.).
                    ImagesAnimees(reference: reference, actif: true) { j in
                        scene(nageurs, l: l, h: h) { nageur in nageur.poses[j < 0 ? nageur.repos(l: l) : j] }
                    }
                case (true, .nage10):
                    // Piste a : boucle de 10 s à 8 images/s (80 copies), avec déplacement.
                    BoucleAnimee(reference: reference, actif: true, boucle: boucle) { j in
                        scene(nageurs, l: l, h: h) { nageur in nageur.poses[j < 0 ? nageur.repos(l: l) : j] }
                    }
                case (true, .balade), (true, .balade4), (true, .balade6):
                    // Les poissons se baladent : à chaque copie k, la pose k de leur traversée (une seule image de queue par
                    // poisson : léger), avec une ondulation courte (8 images) pour le corps qui respire.
                    BoucleAnimee(reference: reference, actif: true, boucle: boucle, parite: false) { k in
                        scene(nageurs, l: l, h: h, phase: k < 0 ? nil : k % 8, boucle: 8, queue: 1) { nageur in
                            nageur.poses[k < 0 ? nageur.repos(l: l) : min(k, nageur.poses.count - 1)]
                        }
                    }
                case (true, .battement), (true, .ondule), (true, .parite), (true, .parite6), (true, .parite4), (true, .parite2),
                     (true, .parite1), (true, .fixe16), (true, .fixe24), (true, .fixe32), (true, .douce), (true, .douce4):
                    // Piste e : chaque poisson à sa place du créneau (timeline), battement de queue et légère
                    // ondulation sur une boucle de 2 s (16 copies à 8 images/s, ou 12 à 6 images/s).
                    BoucleAnimee(reference: reference, actif: true, boucle: boucle, parite: piste.parite) { k in
                        scene(nageurs, l: l, h: h, phase: k, boucle: boucle.copies, queue: piste.imagesQueue) { nageur in
                            nageur.poses[nageur.repos(l: l)]
                        }
                    }
                case (true, .solo):
                    // Un poisson animé (le premier) dans un cadre minuscule ; les autres figés, dessinés une seule fois.
                    scene(Array(nageurs.dropFirst()), l: l, h: h) { nageur in nageur.poses[nageur.repos(l: l)] }
                    ForEach(dessins(Array(nageurs.prefix(1))) { nageur in nageur.poses[nageur.repos(l: l)] }) { d in
                        calque(d, reference: reference, boucle: boucle, l: l, h: h, queue: 3, facteur: (2.0, 1.2))
                    }
                case (true, .calques):
                    // Un calque par poisson : ses copies ne couvrent que lui (masques à sa taille).
                    ForEach(dessins(nageurs) { nageur in nageur.poses[nageur.repos(l: l)] }) { d in
                        calque(d, reference: reference, boucle: boucle, l: l, h: h)
                    }
                default:
                    scene(nageurs, l: l, h: h) { nageur in nageur.poses[nageur.repos(l: l)] }
                }
                #if DEBUG
                if animePoissons && piste == .chrono {
                    ChronoProgression(debut: .now)
                }
                #endif
                // Quelques paillettes de nourriture près de la surface.
                ForEach(placements.filter(\.auRepas)) { placement in
                    ForEach(0..<3, id: \.self) { k in
                        Circle()
                            .fill(Teintes.nourriture.opacity(0.9))
                            .frame(width: 3, height: 3)
                            .position(x: placement.x * l + CGFloat(k - 1) * 7,
                                      y: h * 0.06 + CGFloat(k) * 5)
                    }
                }
            }
            // Changement de créneau (timeline) : les poissons glissent 2 s vers leur nouvelle place (2 s = plafond
            // des animations de widget, doc Apple « Animating data updates in widgets »).
            .animation(reduireAnimations ? nil : .easeInOut(duration: 2), value: creneau)
        }
    }

    /// Un poisson à dessiner dans une copie : sa pose et son rang (pour décaler les battements entre poissons).
    private struct Dessin: Identifiable {
        let nageur: Nageur
        let pose: NageWidget.PoseNage
        let rang: Int
        var id: String { nageur.id }
    }

    /// Les poissons à leur pose, ceux du fond d'abord.
    private func dessins(_ nageurs: [Nageur], pose: (Nageur) -> NageWidget.PoseNage) -> [Dessin] {
        nageurs.enumerated().map { Dessin(nageur: $1, pose: pose($1), rang: $0) }
            .sorted { $0.pose.profondeur > $1.pose.profondeur }
    }

    /// Tous les poissons à leur pose (ceux du fond d'abord). `phase` (0..<boucle) : image de la boucle courte,
    /// battement de queue et ondulation de quelques points ; nil : pose figée. `queue` : images de queue distinctes
    /// par boucle (0 : une par copie).
    private func scene(_ nageurs: [Nageur], l: CGFloat, h: CGFloat, phase: Int? = nil, boucle: Int = 16, queue: Int = 0,
                       pose: (Nageur) -> NageWidget.PoseNage) -> some View {
        ZStack {
            ForEach(dessins(nageurs, pose: pose)) { d in
                poisson(d, phase: phase, boucle: boucle, queue: queue)
                    .position(x: d.pose.x * l, y: d.pose.y * h)
            }
        }
        .frame(width: l, height: h)
    }

    /// Un poisson à sa pose, centré sur son point (le placement se fait autour) ; décalé par l'ondulation.
    private func poisson(_ d: Dessin, phase: Int?, boucle: Int, queue: Int) -> some View {
        let nageur = d.nageur
        let p = d.pose
        let vue = nageur.angles.isEmpty ? 0
            : (NageWidget.melange(lacet: p.lacet, angles: nageur.angles).max { $0.poids < $1.poids }?.angle ?? 0)
        let o = Self.ondulation(phase: phase, rang: d.rang, boucle: boucle, imagesCycle: nageur.imagesCycle, queue: queue)
        // queue == 1 : UNE image par poisson sur toute la boucle (la pose de trajet ne change pas l'image : mémoire).
        let imageDePose = queue >= 1 ? (nageur.poses.first?.image ?? 0) : p.image
        let image: Int? = nageur.cycle ? ((imageDePose + o.decalageImage) % max(nageur.imagesCycle, 1)) * nageur.pas : nil
        let sensEff = o.sens ?? p.sens   // balancement : il regarde dans le sens où il nage
        let sensX: CGFloat = sensEff >= 0 ? 1 : -1
        return ImagePoisson(slug: nageur.slug, image: image,
                            largeur: nageur.largeur * p.echelle, sens: sensEff,
                            angle: vue, volume: !nageur.angles.isEmpty)
            .scaleEffect(x: 1 - o.flex, y: 1 + o.flex * 0.4)
            .opacity(p.opacite)
            // Il lève un peu le nez quand il monte (moitié de l'assiette de nage.js), plus l'ondulation.
            .rotationEffect(.radians(-(p.assiette * 0.5 + o.tangage) * Double(sensX)))
            .offset(x: o.dx * nageur.largeur * 4 * (o.sens == nil ? sensX : 1), y: o.dy * nageur.largeur * 2)
    }

    /// Un calque par poisson : `boucle.copies` copies de CE poisson seul, dans un cadre à sa taille ; les masques
    /// chronos n'ont que cette taille (au lieu de celle du widget).
    private func calque(_ d: Dessin, reference: Date, boucle: HorlogeAnimation.Boucle, l: CGFloat, h: CGFloat,
                        queue: Int = 4, facteur: (CGFloat, CGFloat) = (1.3, 0.9)) -> some View {
        let largeur = d.nageur.largeur * d.pose.echelle
        return BoucleAnimee(reference: reference, actif: true, boucle: boucle, parite: true) { k in
            poisson(d, phase: k < 0 ? nil : k, boucle: boucle.copies, queue: queue)
                .frame(width: largeur * facteur.0, height: largeur * facteur.1)
        }
        .frame(width: largeur * facteur.0, height: largeur * facteur.1)
        .position(x: d.pose.x * l, y: d.pose.y * h)
    }

    /// Ondulation d'une image de la boucle courte : décalage dans le cycle de queue, petit va-et-vient (en part
    /// de la largeur et de la hauteur) et tangage (rad). Chaque poisson est décalé de 5 images : pas de nage en chœur.
    /// `queue` > 0 : seulement `queue` images de queue distinctes (réparties sur le cycle), donc moins d'images
    /// en mémoire ; la queue bat alors `boucle / queue` fois par boucle. dx et dy sont en part de la LONGUEUR du
    /// poisson (×4 et ×2 à l'emploi), pour rester dans son calque.
    static func ondulation(phase: Int?, rang: Int, boucle: Int, imagesCycle: Int, queue: Int = 0)
        -> (decalageImage: Int, dx: CGFloat, dy: CGFloat, tangage: Double, flex: CGFloat, sens: Double?) {
        guard let phase, boucle > 0 else { return (0, 0, 0, 0, 0, nil) }
        if queue == 2 {
            // Balancement lent : un aller-retour par boucle (10 s) pour les rangs pairs, deux (5 s) pour les impairs, décalés
            // entre poissons. dx est en part de la longueur du poisson ×4 à l'emploi : amplitude 0,45 ou 0,3 longueur.
            let m = rang % 2 == 0 ? 1.0 : 2.0
            let amplitude = rang % 2 == 0 ? 0.45 : 0.3
            let a = 2 * Double.pi * m * Double(phase) / Double(boucle) + Double(rang) * 2.1
            let b = a + 1.3
            // Demi-tour : l'échelle horizontale passe de +1 à −1 près des extrémités (comme l'aquarium 3D vu de face).
            let sens = max(-1.0, min(1.0, 2.5 * cos(a)))
            return (0, CGFloat(sin(a) * amplitude / 4), CGFloat(sin(b)) * 0.03, cos(b) * 0.05, 0, sens)
        }
        let k = (phase + rang * boucle / 3) % boucle
        let a = 2 * Double.pi * Double(k) / Double(boucle)
        if queue == 3 {
            // Piste `solo` : glissade douce d'un côté à l'autre (±0,25 longueur en 2 s), le corps qui respire, un léger
            // tangage. Il regarde toujours dans son sens de repos (pas de demi-tour : tout tient dans un petit cadre).
            return (0, CGFloat(sin(a)) * 0.06, CGFloat(sin(2 * a)) * 0.012, cos(a) * 0.05, CGFloat(sin(2 * a)) * 0.05, nil)
        }
        if queue == 1 {
            // Une seule image par poisson (mesuré : chaque image de queue en plus coûte ~5 Mo de pic pour 3 poissons).
            // La nage vient des transformations, gratuites : va-et-vient, montée et descente, tangage, et la largeur
            // qui respire 2 fois par boucle (le corps qui ondule).
            return (0, CGFloat(cos(a)) * 0.012, CGFloat(sin(a)) * 0.02, cos(a) * 0.07, CGFloat(sin(2 * a)) * 0.04, nil)
        }
        let image = queue > 0 ? (k % queue) * max(imagesCycle, 1) / queue : k
        return (image, CGFloat(cos(a)) * 0.006, CGFloat(sin(a)) * 0.012, cos(a) * 0.06, 0, nil)
    }
}

// MARK: - Les vues par famille

private struct TexteVide: View {
    var body: some View {
        Text("Ta 1re prise nagera ici")
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
    }
}

private struct PastillePro: View {
    var body: some View {
        Label("FishMe Pro", systemImage: "lock.fill")
            .font(.system(.footnote, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct BoutonNourrir: View {
    let rations: Int

    var body: some View {
        Button(intent: NourrirAquariumIntent()) {
            HStack(spacing: 5) {
                Image(systemName: "circle.grid.2x2.fill")
                Text("\(rations)").monospacedDigit()
            }
            .font(.system(.footnote, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .buttonStyle(.plain)
        .opacity(rations > 0 ? 1 : 0.45)
        .accessibilityLabel("Nourrir les poissons, \(rations) rations")
    }
}

private struct ChiffreEspeces: View {
    let especes: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "fish.fill")
            Text("\(especes)").monospacedDigit()
        }
        .font(.system(.footnote, design: .rounded, weight: .bold))
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 2)
    }
}

/// Écran verrouillé : une teinte unique imposée par iOS, donc des silhouettes.
private struct VueEcranVerrouille: View {
    let instantane: InstantaneAquarium
    let circulaire: Bool

    var body: some View {
        if circulaire {
            ZStack {
                AccessoryWidgetBackground()
                if let premier = instantane.poissons.first {
                    VStack(spacing: 1) {
                        Image("\(premier.slug)-silhouette")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.primary)
                            .widgetAccentable()
                            .frame(width: 30, height: 18)
                        Text("\(instantane.especes)")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .monospacedDigit()
                    }
                } else {
                    Image(systemName: "fish")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                }
            }
        } else {
            HStack(spacing: 8) {
                if instantane.poissons.isEmpty {
                    Image(systemName: "fish")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                } else {
                    ForEach(Array(instantane.poissons.prefix(3))) { poisson in
                        Image("\(poisson.slug)-silhouette")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.primary)
                            .widgetAccentable()
                            .frame(height: 24)
                    }
                    Spacer(minLength: 0)
                    Text("\(instantane.especes)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

/// La vue du widget. La famille arrive en paramètre (jamais lue dans l'environnement) : la vue se rend aussi
/// hors widget (tests d'image). `fondVisible` dessine l'eau derrière la vue ; sinon c'est `containerBackground`.
struct VueAquariumWidget: View {
    let entree: EntreeAquarium
    let famille: WidgetFamily
    let fondVisible: Bool
    /// nil (défaut, donc le vrai widget) : la piste retenue, `PisteNage.widget` (boucle courte de 16 copies ; repli
    /// statique pour « Réduire les animations », l'écran verrouillé et le rendu teinté, géré par CoucheNage).
    /// Vrai : animation complète (160 copies), seulement pour l'aperçu de l'app (`ApercuAnimationAquarium`) : elle
    /// gardait l'extension en placeholder gris (7 nov.). Faux : poses figées (tests d'image : `ImageRenderer` rend
    /// les chronos vides, donc des copies masquées invisibles).
    let anime: Bool?

    init(entree: EntreeAquarium, famille: WidgetFamily, fondVisible: Bool = false, anime: Bool? = nil) {
        self.entree = entree
        self.famille = famille
        self.fondVisible = fondVisible
        self.anime = anime
    }

    private var instantane: InstantaneAquarium { entree.instantane }
    /// Aperçu de l'app : animation complète ; vrai widget : la piste retenue (repli statique géré par CoucheNage).
    private var piste: PisteNage {
        switch anime {
        case .some(true): .complete
        case .some(false): .statique
        case nil: PisteNage.widget
        }
    }
    private var nombrePoissons: Int { instantane.poissons.reduce(0) { $0 + $1.nombre } }

    private var etiquette: String {
        nombrePoissons <= 1 ? "Mon aquarium, \(nombrePoissons) poisson" : "Mon aquarium, \(nombrePoissons) poissons"
    }

    var body: some View {
        if fondVisible {
            ZStack {
                FondEau(famille: famille, skin: instantane.skinEffectif)
                contenu
            }
        } else {
            contenu
                .containerBackground(for: .widget) { FondEau(famille: famille, skin: instantane.skinEffectif) }
        }
    }

    @ViewBuilder
    private var contenu: some View {
        switch famille {
        case .accessoryRectangular:
            VueEcranVerrouille(instantane: instantane, circulaire: false)
                .widgetURL(urlAquarium)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(etiquette)
        case .accessoryCircular:
            VueEcranVerrouille(instantane: instantane, circulaire: true)
                .widgetURL(urlAquarium)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(etiquette)
        case .systemSmall:
            aquarium(verrouille: false, avecBouton: false)
                .widgetURL(urlAquarium)
        default:
            // Moyen, grand, très grand : Pro.
            let verrouille = !instantane.estPro && !instantane.poissons.isEmpty
            aquarium(verrouille: verrouille, avecBouton: instantane.estPro)
                .widgetURL(verrouille ? urlPro : urlAquarium)
        }
    }

    /// L'entrée de l'état vide : un seul gardon, commun, qui n'appartient à aucune prise.
    static func entreeAccueil(_ entree: EntreeAquarium) -> EntreeAquarium {
        var accueil = entree.instantane
        accueil.poissons = [InstantaneAquarium.Poisson(id: "accueil", slug: "gardon", rarete: 0, relache: true, nombre: 0)]
        return EntreeAquarium(date: entree.date, instantane: accueil)
    }

    private func aquarium(verrouille: Bool, avecBouton: Bool) -> some View {
        ZStack {
            #if DEBUG
            // Diagnostic (Debug seulement, si diagnostic-widget.txt existe dans l'App Group) : poissons reçus, images, polices.
            if PisteNage.diagnosticActif { DiagnosticAquarium(instantane: instantane) }
            #endif
            if instantane.poissons.isEmpty {
                // Avant la 1re prise (Adem, 16 oct.) : un gardon d'accueil nage, voilé, derrière l'invitation. Ce
                // n'est pas une prise : il n'entre ni au compte d'espèces ni dans la liste de choix.
                CoucheNage(entree: Self.entreeAccueil(entree), famille: famille, anime: true, piste: piste)
                    .opacity(0.55)
                    .accessibilityHidden(true)
                TexteVide()
            } else {
                // Verrouillé (non Pro) : flouté et immobile (un flou sur 24 copies animées coûterait pour rien).
                CoucheNage(entree: entree, famille: famille, anime: !verrouille, piste: verrouille ? .statique : piste)
                    .blur(radius: verrouille ? 9 : 0)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(etiquette)
                if famille == .systemSmall {
                    ChiffreEspeces(especes: instantane.especes)
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
                if verrouille {
                    PastillePro()
                }
                if avecBouton {
                    BoutonNourrir(rations: instantane.rations)
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
            }
        }
    }
}

#if DEBUG
extension EntreeAquarium {
    /// Un aquarium d'exemple pour rendre des images (tests, aperçus) : 5 poissons aux vrais noms d'images.
    /// La date est fixe par défaut, donc la nage aussi. `repas` : une ration vient d'être donnée (poissons en surface).
    /// Pour voir l'animation (aperçus), passer `date: .now` : le chrono des masques part de 60 s avant cette date ;
    /// une date lointaine donnerait un chrono trop long pour son cadre.
    static func exempleRendu(pro: Bool, repas: Bool = false,
                             date: Date = Date(timeIntervalSince1970: 1_800_000_000)) -> EntreeAquarium {
        let instantane = InstantaneAquarium(
            poissons: [
                .init(id: "ex-brochet", slug: "brochet", rarete: 3, relache: true, nom: "Brochet"),
                .init(id: "ex-truite", slug: "truite-fario", rarete: 2, relache: true, nom: "Truite fario"),
                .init(id: "ex-sandre", slug: "sandre", rarete: 2, relache: false, nom: "Sandre"),
                .init(id: "ex-perche", slug: "perche-commune", rarete: 1, relache: true, nom: "Perche commune"),
                .init(id: "ex-blackbass", slug: "black-bass", rarete: 0, relache: true, nom: "Black-bass"),
            ],
            especes: 12, rations: 3, estPro: pro,
            dernierRepas: repas ? date.addingTimeInterval(-120) : nil,
            misAJour: date
        )
        return EntreeAquarium(date: date, instantane: instantane)
    }
}
#endif

#if DEBUG
/// Debug seulement : une ligne en bas à gauche, pour savoir d'un coup d'œil pourquoi un poisson ne se voit pas.
private struct DiagnosticAquarium: View {
    let instantane: InstantaneAquarium

    var body: some View {
        let slugs = instantane.poissons.map(\.slug)
        let manquants = slugs.filter { !PoissonVivant.imageDisponible($0) }
        // Témoins (essais lot widget-fluide) : un chrono simple, un carré masqué par la police « chiffre 0 »
        // (plein 1 s sur 10) et un par la police de parité 0 (plein 1 s sur 2). S'ils ne bougent pas, l'hôte ne
        // fait pas tourner les chronos.
        // Référence 62 s avant : au rendu, le chiffre des unités vaut 2 (orange vide, vert plein, bleu vide).
        let ref = Date.now.addingTimeInterval(-62)
        HStack(spacing: 4) {
            Text(ref, style: .timer).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.yellow)
            Color.orange.frame(width: 14, height: 14)
                .mask(MasqueClignotant(chiffre: 0, reference: ref, decalage: 0))
            Color.green.frame(width: 14, height: 14)
                .mask(MasqueClignotant(chiffre: 0, reference: ref, decalage: 0, police: PolicesMasque.pair(0)))
            Color.blue.frame(width: 14, height: 14)
                .mask(MasqueClignotant(chiffre: 0, reference: ref, decalage: 0, police: PolicesMasque.pair(1)))
            Text(PolicesMasque.pairesDisponibles ? "P" : "p").font(.system(size: 9, weight: .bold)).foregroundStyle(.yellow)
        }
        .padding(3)
        .background(.black.opacity(0.6))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(6)
        Text("\(slugs.count) p · img \(manquants.isEmpty ? "ok" : "KO " + manquants.joined(separator: ",")) · polices \(PolicesMasque.disponibles ? "ok" : "KO") · \(PisteNage.widget.rawValue)")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.yellow)
            .padding(4)
            .background(.black.opacity(0.6))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(6)
            .allowsHitTesting(false)
    }
}
#endif
