import AppIntents
import SwiftUI
import UIKit
import WidgetKit

// Cible widget seulement. Les vues du widget « Ma carte » : la carte à collectionner, recto et verso, SANS aucun texte.
// Dessin repris de la classe .fc de docs/design/fishme-ds.css (ratio 69/100, rayon 6 %, fenêtre colorée par rareté,
// poisson incliné de 12°, liseré intérieur, dos marine avec silhouette) ; le recto n'a ni nom ni chiffre.
// `WidgetAquarium/` n'importe pas `App/Style` : la palette « Marine » est répétée ici, comme dans VuesAquariumWidget.
// La famille arrive en paramètre : aucune sous-vue ne lit l'environnement `widgetFamily`.

private enum Teintes {
    static let marine = Color(red: 13 / 255, green: 74 / 255, blue: 133 / 255)        // #0D4A85
    static let nuit = Color(red: 8 / 255, green: 42 / 255, blue: 76 / 255)            // #082A4C
    static let encre = Color(red: 14 / 255, green: 26 / 255, blue: 38 / 255)          // #0E1A26
    static let papier = Color(red: 233 / 255, green: 237 / 255, blue: 235 / 255)      // #E9EDEB
    static let commun = Color(red: 107 / 255, green: 119 / 255, blue: 128 / 255)      // #6B7780, ardoise
    static let peuCommun = Color(red: 35 / 255, green: 136 / 255, blue: 90 / 255)     // #23885A, vert
    static let rare = Color(red: 91 / 255, green: 79 / 255, blue: 208 / 255)          // #5B4FD0, violet
    static let legendaire = Color(red: 176 / 255, green: 122 / 255, blue: 18 / 255)   // #B07A12, or bruni

    static func rarete(_ niveau: Int) -> Color {
        switch niveau {
        case 3: legendaire
        case 2: rare
        case 1: peuCommun
        default: commun
        }
    }
}

/// Largeur sur hauteur de la carte (design : 69/100).
private let rapportCarte: CGFloat = 69.0 / 100.0

private func hex(_ v: UInt32, _ opacite: Double = 1) -> Color {
    Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255,
          blue: Double(v & 0xFF) / 255, opacity: opacite)
}

/// Direction d'un dégradé CSS (`linear-gradient(160deg, …)`) en points de départ et d'arrivée dans le carré unité.
private func axe(_ degres: Double) -> (UnitPoint, UnitPoint) {
    let a = degres * .pi / 180
    let dx = sin(a) / 2
    let dy = -cos(a) / 2
    return (UnitPoint(x: 0.5 - dx, y: 0.5 - dy), UnitPoint(x: 0.5 + dx, y: 0.5 + dy))
}

// MARK: - Retournement

/// Un demi-tour autour de l'axe vertical : la face qui part tourne jusqu'à 90°, la face qui arrive part de -90°.
private struct Retournement: ViewModifier {
    var angle: Double
    func body(content: Content) -> some View {
        content.rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
    }
}

private extension AnyTransition {
    static var retourner: AnyTransition {
        .asymmetric(
            insertion: .modifier(active: Retournement(angle: -90), identity: Retournement(angle: 0)),
            removal: .modifier(active: Retournement(angle: 90), identity: Retournement(angle: 0))
        )
    }
}

// MARK: - La vue du widget

struct VueCarteWidget: View {
    let entree: EntreeCarte
    let famille: WidgetFamily
    let fondVisible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    init(entree: EntreeCarte, famille: WidgetFamily, fondVisible: Bool = false) {
        self.entree = entree
        self.famille = famille
        self.fondVisible = fondVisible
    }

    var body: some View {
        if fondVisible {
            ZStack {
                FondCarte()
                contenu
            }
        } else {
            contenu
                .containerBackground(for: .widget) { FondCarte() }
        }
    }

    private var marge: CGFloat { famille == .systemLarge ? 16 : 12 }

    private var contenu: some View {
        GeometryReader { geo in
            let dispo = CGSize(width: max(geo.size.width - 2 * marge, 1), height: max(geo.size.height - 2 * marge, 1))
            // La plus grande carte au bon format qui tient dans le widget, centrée.
            let largeur = min(dispo.width, dispo.height * rapportCarte)
            let taille = CGSize(width: largeur, height: largeur / rapportCarte)
            ZStack {
                if let carte = entree.carte {
                    Button(intent: RetournerCarteIntent(idCarte: carte.id)) {
                        faceAnimee(carte: carte, taille: taille)
                    }
                    .buttonStyle(.plain)
                } else {
                    EmplacementVide(taille: taille)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func faceAnimee(carte: InstantaneCartes.Carte, taille: CGSize) -> some View {
        ZStack {
            if entree.verso {
                VersoCarte(carte: carte, photo: entree.photo, taille: taille)
                    .id("verso")
                    .transition(reduireAnimations ? .opacity : .retourner)
            } else {
                RectoCarte(carte: carte, taille: taille)
                    .id("recto")
                    .transition(reduireAnimations ? .opacity : .retourner)
            }
        }
        .frame(width: taille.width, height: taille.height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Carte du Pescedex")
        .accessibilityHint("Touche pour retourner la carte")
    }
}

/// Le fond derrière la carte : de l'eau marine sombre, sans motif (la carte est le sujet).
private struct FondCarte: View {
    var body: some View {
        LinearGradient(colors: [Teintes.marine, Teintes.nuit], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Cadre commun

/// Forme, ombre et liseré de rareté communs au recto et au verso : les deux faces ont exactement la même taille.
private struct CadreCarte<Contenu: View>: View {
    let rarete: Int
    let taille: CGSize
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        let l = taille.width
        let forme = RoundedRectangle(cornerRadius: l * 0.06, style: .continuous)
        let couleur = Teintes.rarete(rarete)
        contenu()
            .frame(width: taille.width, height: taille.height)
            .clipShape(forme)
            // Liseré de rareté : fin, à l'extérieur du dessin, comme le contour .fc du design.
            .overlay { forme.strokeBorder(couleur.opacity(rarete == 0 ? 0.55 : 0.95), lineWidth: max(l * 0.012, 1)) }
            .overlay { forme.strokeBorder(Color.black.opacity(0.10), lineWidth: 0.5) }
            // Halo : discret pour un commun, plus net pour un rare ou un légendaire.
            .shadow(color: couleur.opacity([0.0, 0.25, 0.5, 0.65][min(max(rarete, 0), 3)]), radius: min(l * 0.06, 9))
            .shadow(color: Color.black.opacity(0.35), radius: l * 0.04, y: l * 0.03)
    }
}

/// Des ronds concentriques très légers, comme des rides à la surface de l'eau (.win::before du design).
private struct Rides: View {
    var opacite: Double
    var body: some View {
        GeometryReader { geo in
            let l = geo.size.width
            let centre = CGPoint(x: l * 0.74, y: geo.size.height * 0.26)
            ZStack {
                ForEach(1..<22, id: \.self) { i in
                    let r = l * 0.05 * CGFloat(i)
                    Ellipse()
                        .stroke(Color.white.opacity(0.55), lineWidth: max(l * 0.004, 0.5))
                        .frame(width: r * 2, height: r * 2)
                        .position(centre)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(opacite)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Recto

/// La fenêtre colorée de la rareté (fond du recto), sans le poisson.
private struct FenetreRarete: View {
    let rarete: Int

    var body: some View {
        switch rarete {
        case 3:
            // Légendaire : or, avec des taches claires.
            ZStack {
                LinearGradient(colors: [hex(0xE3B654), hex(0xB8862A), hex(0xD9A845)],
                               startPoint: axe(150).0, endPoint: axe(150).1)
                bokeh(0.20, 0.30, 0.06, 0xF6D98A)
                bokeh(0.70, 0.18, 0.05, 0xFBE3A0)
                bokeh(0.55, 0.60, 0.07, 0xF2CF78)
                bokeh(0.85, 0.70, 0.06, 0xE9BD5A)
            }
        case 2:
            // Rare : argent irisé.
            ZStack {
                LinearGradient(stops: [.init(color: hex(0xDCE3E8), location: 0), .init(color: hex(0xAFBCC6), location: 0.45),
                                       .init(color: hex(0xC9D2D8), location: 0.6), .init(color: hex(0x8497A3), location: 1)],
                               startPoint: axe(160).0, endPoint: axe(160).1)
                LinearGradient(stops: [.init(color: .clear, location: 0.30), .init(color: hex(0xAAD7FF, 0.55), location: 0.45),
                                       .init(color: hex(0xFFD2E6, 0.25), location: 0.52), .init(color: .clear, location: 0.62)],
                               startPoint: axe(125).0, endPoint: axe(125).1)
                    .blendMode(.softLight)
            }
        case 1:
            // Peu commun : vert profond, reflet vert d'eau.
            ZStack {
                hex(0x17403F)
                Rides(opacite: 0.3)
                LinearGradient(stops: [.init(color: .clear, location: 0.38), .init(color: hex(0xBEFFEB, 0.22), location: 0.47),
                                       .init(color: .clear, location: 0.56)],
                               startPoint: axe(118).0, endPoint: axe(118).1)
            }
        default:
            // Commun : ardoise, avec des rides.
            ZStack {
                hex(0x5F7775)
                Rides(opacite: 0.3)
            }
        }
    }

    private func bokeh(_ x: Double, _ y: Double, _ rayon: Double, _ couleur: UInt32) -> some View {
        GeometryReader { geo in
            let r = geo.size.width * rayon * 1.6
            Circle()
                .fill(RadialGradient(colors: [hex(couleur), hex(couleur, 0)], center: .center, startRadius: 0, endRadius: r))
                .frame(width: r * 2, height: r * 2)
                .position(x: geo.size.width * x, y: geo.size.height * y)
        }
    }
}

struct RectoCarte: View {
    let carte: InstantaneCartes.Carte
    let taille: CGSize

    var body: some View {
        let l = taille.width
        let h = taille.height
        let forme = RoundedRectangle(cornerRadius: l * 0.044, style: .continuous)
        CadreCarte(rarete: carte.rarete, taille: taille) {
            ZStack(alignment: .topLeading) {
                FenetreRarete(rarete: carte.rarete)
                // Le poisson : incliné de 12°, il regarde vers la droite ; ombre portée vers le bas-gauche.
                Image(carte.slug)
                    .resizable()
                    .widgetAccentedRenderingMode(.desaturated)
                    .scaledToFit()
                    .frame(width: l * 0.88)
                    .rotationEffect(.degrees(-12))
                    .shadow(color: .black.opacity(0.35), radius: l * 0.02, x: -l * 0.015, y: l * 0.025)
                    .offset(x: l * 0.08, y: h * 0.22)
                // Reflet discret : rare et légendaire seulement.
                if carte.rarete >= 2 {
                    LinearGradient(stops: [.init(color: .clear, location: 0.30), .init(color: .white.opacity(0.55), location: 0.45),
                                           .init(color: hex(0xB3D6FF, 0.45), location: 0.55), .init(color: .clear, location: 0.70)],
                                   startPoint: axe(125).0, endPoint: axe(125).1)
                        .blendMode(.plusLighter)
                        .opacity(0.35)
                        .allowsHitTesting(false)
                }
                // Liseré intérieur (.in du design) ; double pour rare et légendaire.
                if carte.rarete >= 2 {
                    forme.strokeBorder(Color.white.opacity(0.9), lineWidth: 1).padding(l * 0.018)
                    forme.strokeBorder(Teintes.rarete(carte.rarete).opacity(0.7), lineWidth: max(l * 0.008, 1)).padding(l * 0.026)
                } else {
                    forme.strokeBorder(Color.white.opacity(0.28), lineWidth: 1).padding(l * 0.024)
                }
            }
        }
    }
}

// MARK: - Verso

struct VersoCarte: View {
    let carte: InstantaneCartes.Carte
    let photo: UIImage?
    let taille: CGSize

    var body: some View {
        CadreCarte(rarete: carte.rarete, taille: taille) {
            if let photo {
                // La vraie photo du pêcheur, rognée dans la carte.
                Color.clear
                    .overlay {
                        Image(uiImage: photo)
                            .resizable()
                            .widgetAccentedRenderingMode(.desaturated)
                            .scaledToFill()
                    }
                    .clipped()
                    .background(Teintes.papier)
            } else {
                DosCarte(slug: carte.slug, taille: taille)
            }
        }
    }
}

/// Le dos de carte (.fc.dos du design) : marine, rides, silhouette du poisson en filigrane. Aucun texte.
private struct DosCarte: View {
    let slug: String
    let taille: CGSize

    var body: some View {
        let l = taille.width
        let forme = RoundedRectangle(cornerRadius: l * 0.044, style: .continuous)
        ZStack {
            Teintes.marine
            Rides(opacite: 0.18)
            Image("\(slug)-silhouette")
                .renderingMode(.template)
                .resizable()
                .widgetAccentedRenderingMode(.desaturated)
                .scaledToFit()
                .foregroundStyle(Color.white.opacity(0.4))
                .frame(width: l * 0.68)
            forme.strokeBorder(Color.white.opacity(0.28), lineWidth: 1).padding(l * 0.024)
        }
    }
}

// MARK: - Aucune carte

/// Pas encore de carte : un emplacement en pointillés, sans texte.
private struct EmplacementVide: View {
    let taille: CGSize

    var body: some View {
        let l = taille.width
        RoundedRectangle(cornerRadius: l * 0.06, style: .continuous)
            .strokeBorder(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
            .frame(width: taille.width, height: taille.height)
            .overlay {
                Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                    .resizable()
                    .widgetAccentedRenderingMode(.desaturated)
                    .scaledToFit()
                    .frame(width: l * 0.28)
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Aucune carte pour l'instant")
    }
}
