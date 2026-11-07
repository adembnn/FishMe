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

/// Le moteur d'animation des poissons. Mesuré le 7 nov. (lot/widget-fluide, simulateur, Debug) : voir le rapport.
nonisolated enum PisteNage: String, Sendable {
    /// Une pose par poisson ; elle change au créneau suivant de la timeline.
    case statique
    /// Retenue : pose du créneau + battement de queue et ondulation, boucle de 2 s à 8 images/s (16 copies).
    case battement
    /// Piste a : déplacement sur une boucle de 10 s à 8 images/s (80 copies).
    case nage10
    /// Aperçu de l'app seulement : 160 copies (10 s à 16 images/s).
    case complete
    /// Essai Debug : `ProgressView(timerInterval:)` sur une pose figée (piste b).
    case chrono
    /// Essai Debug : entrées toutes les 10 s, glissement animé de 2 s entre deux (piste c ; hors budget Apple).
    case glisse

    var boucle: HorlogeAnimation.Boucle {
        self == .nage10 ? HorlogeAnimation.Boucle(parSeconde: 8, duree: 10) : .battement
    }

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
        return .battement
    }
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
            ProgressView(timerInterval: debut...debut.addingTimeInterval(20), countsDown: false) { EmptyView() }
                currentValueLabel: { EmptyView() }
                .progressViewStyle(.linear)
                .tint(.white)
            ProgressView(timerInterval: debut...debut.addingTimeInterval(20), countsDown: false) { EmptyView() }
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
                                                               : (piste == .nage10 ? boucle.copies : 32),
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
                case (true, .battement):
                    // Piste e (retenue) : chaque poisson à sa place du créneau (timeline), battement de queue et
                    // légère ondulation sur une boucle de 2 s à 8 images/s (16 copies, 10 chronos par copie).
                    BoucleAnimee(reference: reference, actif: true, boucle: boucle) { k in
                        scene(nageurs, l: l, h: h, phase: k, boucle: boucle.copies) { nageur in nageur.poses[nageur.repos(l: l)] }
                    }
                default:
                    scene(nageurs, l: l, h: h) { nageur in nageur.poses[nageur.repos(l: l)] }
                }
                #if DEBUG
                if animePoissons && piste == .chrono {
                    ChronoProgression(debut: entree.date)
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

    /// Tous les poissons à leur pose (ceux du fond d'abord). `phase` (0..<boucle) : image de la boucle courte,
    /// battement de queue (8 images par battement) et ondulation de quelques points ; nil : pose figée.
    private func scene(_ nageurs: [Nageur], l: CGFloat, h: CGFloat, phase: Int? = nil, boucle: Int = 16,
                       pose: (Nageur) -> NageWidget.PoseNage) -> some View {
        let dessins = nageurs.enumerated().map { Dessin(nageur: $1, pose: pose($1), rang: $0) }
            .sorted { $0.pose.profondeur > $1.pose.profondeur }
        return ZStack {
            ForEach(dessins) { d in
                let nageur = d.nageur
                let p = d.pose
                let vue = nageur.angles.isEmpty ? 0
                    : (NageWidget.melange(lacet: p.lacet, angles: nageur.angles).max { $0.poids < $1.poids }?.angle ?? 0)
                let o = Self.ondulation(phase: phase, rang: d.rang, boucle: boucle, imagesCycle: nageur.imagesCycle)
                let image: Int? = nageur.cycle ? ((p.image + o.decalageImage) % max(nageur.imagesCycle, 1)) * nageur.pas : nil
                let sensX: CGFloat = p.sens >= 0 ? 1 : -1
                ImagePoisson(slug: nageur.slug, image: image,
                             largeur: nageur.largeur * p.echelle, sens: p.sens,
                             angle: vue, volume: !nageur.angles.isEmpty)
                    .opacity(p.opacite)
                    // Il lève un peu le nez quand il monte (moitié de l'assiette de nage.js), plus l'ondulation.
                    .rotationEffect(.radians(-(p.assiette * 0.5 + o.tangage) * Double(sensX)))
                    .position(x: p.x * l + o.dx * l * sensX, y: p.y * h + o.dy * h)
            }
        }
        .frame(width: l, height: h)
    }

    /// Ondulation d'une image de la boucle courte : décalage dans le cycle de queue, petit va-et-vient (en part
    /// de la largeur et de la hauteur) et tangage (rad). Chaque poisson est décalé de 5 images : pas de nage en chœur.
    static func ondulation(phase: Int?, rang: Int, boucle: Int, imagesCycle: Int)
        -> (decalageImage: Int, dx: CGFloat, dy: CGFloat, tangage: Double) {
        guard let phase, boucle > 0 else { return (0, 0, 0, 0) }
        let k = (phase + rang * 5) % boucle
        let a = 2 * Double.pi * Double(k) / Double(boucle)
        return (k, CGFloat(cos(a)) * 0.006, CGFloat(sin(a)) * 0.012, cos(a) * 0.06)
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
            // Diagnostic (Debug seulement) : poissons reçus, images trouvées, polices de masque chargées.
            DiagnosticAquarium(instantane: instantane)
            #endif
            if instantane.poissons.isEmpty {
                // Avant la 1re prise (Adem, 16 oct.) : un gardon d'accueil nage, voilé, derrière l'invitation. Ce
                // n'est pas une prise : il n'entre ni au compte d'espèces ni dans la liste de choix.
                CoucheNage(entree: Self.entreeAccueil(entree), famille: famille, anime: true, piste: piste)
                    .opacity(0.55)
                    .accessibilityHidden(true)
                TexteVide()
            } else {
                CoucheNage(entree: entree, famille: famille, anime: true, piste: piste)
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
