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

/// Le fond du widget : le décor rendu en 3D (eau, plantes, galets) ; un simple dégradé en rendu teinté.
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
                Image(nomFond)
                    .resizable()
                    .scaledToFill()
            }
        }
    }

    private var nomFond: String {
        let format: FondWidget.Format = switch famille {
        case .systemSmall: .petit
        case .systemMedium: .moyen
        default: .grand
        }
        // ⚠ à vérifier : UIImage(named:) dans l'extension cherche dans son propre bundle (FondsWidget.xcassets).
        return FondWidget.nomImage(skin: skin, format: format, existe: { UIImage(named: $0) != nil })
    }
}

// MARK: - Les poissons

private struct CoucheNage: View {
    let entree: EntreeAquarium
    let famille: WidgetFamily
    /// Faux : poissons figés (tests d'image, repli sans animation).
    var anime: Bool = true
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
        /// Lacets rendus en volume (fil Aquarium) ; vide : le profil aplati horizontalement.
        let angles: [Int]
        let poses: [NageWidget.PoseNage]
        var id: String { placement.id }
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
        let creneau = Int((entree.date.timeIntervalSince1970 / NageWidget.pas).rounded(.down))

        GeometryReader { geo in
            let l = geo.size.width
            let h = geo.size.height
            // Pleine eau : chaque poisson traverse en perspective (NageWidget.traversees), calculé une fois par poisson.
            let nageurs: [Nageur] = placements.compactMap { placement in
                guard let poisson = parId[placement.id] else { return nil }
                let longueur = part * placement.echelle
                let battement = NageWidget.cycleUtilise(disponibles: PoissonVivant.imagesDisponibles(poisson.slug))
                return Nageur(placement: placement, slug: poisson.slug, largeur: l * longueur,
                              cycle: battement.images > 0, pas: battement.pas,
                              angles: battement.images > 0 ? PoissonVivant.anglesDisponibles(poisson.slug) : [],
                              // Pleine eau (Adem, 16 oct. 07h) : traversées en perspective, sorties par les bords.
                              poses: NageWidget.traversees(id: poisson.id, slug: poisson.slug, creneau: creneau,
                                                           nombre: HorlogeAnimation.nombreImages,
                                                           imagesCycle: max(battement.images, 1), longueur: longueur,
                                                           rapport: Double(h / max(l, 1))))
            }
            ZStack {
                // 160 copies (10 s à 16 images/s) ; chaque copie dessine TOUS les poissons à leur place de cet instant
                // (sans l'eau : c'est le fond du widget), et deux masques chronos n'en laissent voir qu'une à la fois.
                ImagesAnimees(reference: reference, actif: animePoissons) { j in
                    ZStack {
                        // Les poissons du fond d'abord : ceux de devant passent par-dessus.
                        let ordre = nageurs.sorted { $0.poses[j].profondeur > $1.poses[j].profondeur }
                        ForEach(ordre) { nageur in
                            let pose = nageur.poses[j]
                            // Le lacet rendu le plus proche, une seule image (plus de fondu entre deux) : la moitié
                            // moins d'images à garder en mémoire dans l'extension.
                            let vue = nageur.angles.isEmpty ? 0
                                : (NageWidget.melange(lacet: pose.lacet, angles: nageur.angles)
                                    .max { $0.poids < $1.poids }?.angle ?? 0)
                            ImagePoisson(slug: nageur.slug, image: nageur.cycle ? pose.image * nageur.pas : nil,
                                         largeur: nageur.largeur * pose.echelle, sens: pose.sens,
                                         angle: vue, volume: !nageur.angles.isEmpty)
                                .opacity(pose.opacite)
                                // Il lève un peu le nez quand il monte (moitié de l'assiette de nage.js).
                                .rotationEffect(.radians(-pose.assiette * 0.5 * (pose.sens > 0 ? 1 : -1)))
                                .position(x: pose.x * l, y: pose.y * h)
                        }
                    }
                    .frame(width: l, height: h)
                }
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
        }
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
    /// Faux : poissons figés (tests d'image). Vrai par défaut.
    let anime: Bool

    init(entree: EntreeAquarium, famille: WidgetFamily, fondVisible: Bool = false, anime: Bool = true) {
        self.entree = entree
        self.famille = famille
        self.fondVisible = fondVisible
        self.anime = anime
    }

    private var instantane: InstantaneAquarium { entree.instantane }
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
                CoucheNage(entree: Self.entreeAccueil(entree), famille: famille, anime: anime)
                    .opacity(0.55)
                    .accessibilityHidden(true)
                TexteVide()
            } else {
                CoucheNage(entree: entree, famille: famille, anime: anime)
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
        Text("\(slugs.count) p · img \(manquants.isEmpty ? "ok" : "KO " + manquants.joined(separator: ",")) · polices \(PolicesMasque.disponibles ? "ok" : "KO")")
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
