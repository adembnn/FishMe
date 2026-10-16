import AppIntents
import SwiftUI
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
func limitePoissons(_ famille: WidgetFamily) -> Int {
    InstantaneAquarium.limiteAffichee(petit: famille == .systemSmall)
}

/// Largeur d'un poisson, en part de la largeur du widget (avant son échelle).
private func partPoisson(_ famille: WidgetFamily) -> Double {
    switch famille {
    case .systemSmall: 0.44
    case .systemMedium: 0.25
    case .systemLarge: 0.30
    default: 0.24
    }
}

/// Les formats larges rangent les poissons sur 2 colonnes (moins de chevauchements).
private func colonnes(_ famille: WidgetFamily) -> Int {
    famille == .systemSmall ? 1 : 2
}

private func halo(_ rarete: Int) -> Color {
    switch rarete {
    case 3: Teintes.legendaire.opacity(0.85)
    case 2: Teintes.rare.opacity(0.8)
    default: .clear
    }
}

// MARK: - L'eau

/// Quelques rayons très légers venant de la surface.
private struct Rayons: View {
    var body: some View {
        GeometryReader { geo in
            let l = geo.size.width
            let h = geo.size.height
            ForEach(0..<3, id: \.self) { i in
                let x = l * (0.12 + 0.32 * CGFloat(i))
                Path { chemin in
                    chemin.move(to: CGPoint(x: x, y: 0))
                    chemin.addLine(to: CGPoint(x: x + l * 0.10, y: 0))
                    chemin.addLine(to: CGPoint(x: x - l * 0.02, y: h * 0.85))
                    chemin.addLine(to: CGPoint(x: x - l * 0.16, y: h * 0.85))
                    chemin.closeSubpath()
                }
                .fill(LinearGradient(colors: [.white.opacity(0.11), .white.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))
            }
        }
    }
}

/// Le fond du widget : dégradé marine, rayons, une ligne de sable.
private struct FondEau: View {
    let famille: WidgetFamily
    @Environment(\.widgetRenderingMode) private var rendu

    private var accentue: Bool { rendu == .accented }

    var body: some View {
        switch famille {
        case .accessoryRectangular, .accessoryCircular, .accessoryInline:
            Color.clear
        default:
            ZStack {
                LinearGradient(
                    colors: accentue
                        ? [Color(white: 0.30), Color(white: 0.14)]
                        : [Teintes.marine, Teintes.fond],
                    startPoint: .top, endPoint: .bottom)
                Rayons()
                GeometryReader { geo in
                    Ellipse()
                        .fill(LinearGradient(
                            colors: [Teintes.sable.opacity(accentue ? 0.25 : 0.40), Teintes.sable.opacity(0.12)],
                            startPoint: .top, endPoint: .bottom))
                        .frame(width: geo.size.width * 1.5, height: geo.size.height * 0.20)
                        .position(x: geo.size.width / 2, y: geo.size.height * 1.0)
                }
            }
        }
    }
}

// MARK: - Les poissons

private struct CoucheNage: View {
    let entree: EntreeAquarium
    let famille: WidgetFamily
    @Environment(\.widgetRenderingMode) private var rendu
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    private static func estAccessoire(_ famille: WidgetFamily) -> Bool {
        switch famille {
        case .accessoryRectangular, .accessoryCircular, .accessoryInline: true
        default: false
        }
    }

    var body: some View {
        let instantane = entree.instantane
        let placements = NageWidget.placements(
            instantane.poissons, a: entree.date, dernierRepas: instantane.dernierRepas, limite: limitePoissons(famille),
            colonnes: colonnes(famille))
        let parId = Dictionary(instantane.poissons.map { ($0.id, $0) }, uniquingKeysWith: { premier, _ in premier })
        let part = partPoisson(famille)
        let colore = rendu != .accented
        let accessoire = Self.estAccessoire(famille)
        let animePoissons = !reduireAnimations && !accessoire
        let animeDecor = animePoissons

        GeometryReader { geo in
            let l = geo.size.width
            let h = geo.size.height
            ZStack {
                // Décor animé derrière les poissons, écrans d'accueil seulement (jamais en accessoire).
                if animeDecor {
                    LumiereAnimee()
                    BullesAnimees()
                }
                ForEach(Array(placements.enumerated()), id: \.element.id) { index, placement in
                    if let poisson = parId[placement.id] {
                        // Le poisson reste entier dans le widget, même large (petit format).
                        let largeur = l * part * placement.echelle
                        let x = min(max(placement.x * l, largeur / 2 + 4), l - largeur / 2 - 4)
                        ZStack {
                            // Le halo de rareté se dessine UNE fois, derrière, hors des 16 copies animées.
                            if colore && poisson.rarete >= 2 {
                                Ellipse()
                                    .fill(RadialGradient(colors: [halo(poisson.rarete).opacity(0.55), .clear],
                                                         center: .center, startRadius: 0, endRadius: largeur * 0.55))
                                    .frame(width: largeur * 1.15, height: largeur * 0.6)
                            }
                            PoissonVivant(slug: poisson.slug, largeur: largeur,
                                          versLaDroite: placement.versLaDroite, phase: index * 3,
                                          anime: animePoissons)
                        }
                        .position(x: x, y: placement.y * h)
                    }
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
            .animation(reduireAnimations ? nil : .smooth(duration: 1.8), value: entree.date)
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
                            .resizable()
                            .scaledToFit()
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
                            .resizable()
                            .scaledToFit()
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

    init(entree: EntreeAquarium, famille: WidgetFamily, fondVisible: Bool = false) {
        self.entree = entree
        self.famille = famille
        self.fondVisible = fondVisible
    }

    private var instantane: InstantaneAquarium { entree.instantane }
    private var nombrePoissons: Int { instantane.poissons.reduce(0) { $0 + $1.nombre } }

    private var etiquette: String {
        nombrePoissons <= 1 ? "Mon aquarium, \(nombrePoissons) poisson" : "Mon aquarium, \(nombrePoissons) poissons"
    }

    var body: some View {
        if fondVisible {
            ZStack {
                FondEau(famille: famille)
                contenu
            }
        } else {
            contenu
                .containerBackground(for: .widget) { FondEau(famille: famille) }
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

    private func aquarium(verrouille: Bool, avecBouton: Bool) -> some View {
        ZStack {
            if instantane.poissons.isEmpty {
                TexteVide()
            } else {
                CoucheNage(entree: entree, famille: famille)
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
    /// La date est fixe, donc la nage aussi. `repas` : une ration vient d'être donnée (poissons en surface).
    static func exempleRendu(pro: Bool, repas: Bool = false) -> EntreeAquarium {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
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
