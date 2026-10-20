import SwiftUI
import UIKit

// Décors dessinés en code : les vues. Fichier PARTAGÉ app + widget (voir DecorsDessinesBase.swift).
// - `CoucheDecor` : lumière, sol, plantes, rais, poussières, derrière les poissons (posée sur le fond d'origine filtré).
// - `CoucheDecorAvant` : végétation d'avant-plan, poussières proches et bulles, devant les poissons.
// - `filtreDecor(_:)` : le filtre de couleur du fond d'origine pour un décor.
// - `FondDecorFige` : fond d'origine + filtre + décor, sans mouvement (galerie, widget).
// - `FondDecorWidget` : la même composition, rendue UNE FOIS en image (le widget n'est qu'une image fixe : ni `TimelineView`
//   ni animation continue, et pas de `Canvas` à faire archiver par WidgetKit).
// Cadence : 20 images par seconde au plus (comme `CoucheFondEau`), jamais plus de 30. Les deux vues sont `Equatable` :
// la scène de nage les réévalue à chaque image de l'écran, `equatable()` évite de redessiner le décor fixe pour rien.
// ⚠ à vérifier sur Mac : tout ce fichier est écrit sans compilateur.

/// Derrière les poissons. `anime` faux (Réduire les animations, galerie, widget) : une seule image, à l'instant `tFixe`.
struct CoucheDecor: View, Equatable {
    let skin: String
    var anime: Bool = true

    var body: some View {
        if DecorDessin.reglage(skin) != nil {
            ZStack {
                // Le dessin qui ne bouge pas : tracé une seule fois, ne dépend que du décor et de la taille.
                Canvas(rendersAsynchronously: anime) { ctx, taille in
                    DecorDessin.fixeArriere(&ctx, taille: taille, skin: skin)
                }
                if anime {
                    TimelineView(.animation(minimumInterval: 1.0 / 20)) { contexte in
                        let t = contexte.date.timeIntervalSinceReferenceDate
                        Canvas(rendersAsynchronously: true) { ctx, taille in
                            DecorDessin.mobileArriere(&ctx, taille: taille, skin: skin, t: t)
                        }
                    }
                } else {
                    Canvas { ctx, taille in
                        DecorDessin.mobileArriere(&ctx, taille: taille, skin: skin, t: DecorDessin.tFixe)
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Devant les poissons : seulement ce qui ne les cache pas (herbes sur les bords, poussières, bulles).
struct CoucheDecorAvant: View, Equatable {
    let skin: String
    var anime: Bool = true

    var body: some View {
        if DecorDessin.reglage(skin) != nil {
            Group {
                if anime {
                    TimelineView(.animation(minimumInterval: 1.0 / 20)) { contexte in
                        let t = contexte.date.timeIntervalSinceReferenceDate
                        Canvas(rendersAsynchronously: true) { ctx, taille in
                            DecorDessin.mobileAvant(&ctx, taille: taille, skin: skin, t: t, bulles: true)
                        }
                    }
                } else {
                    Canvas { ctx, taille in
                        DecorDessin.mobileAvant(&ctx, taille: taille, skin: skin, t: DecorDessin.tFixe, bulles: false)
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Le filtre de couleur du décor sur le fond d'origine. `nil` ou décor sans dessin : le fond tel quel.
struct FiltreDecor: ViewModifier {
    let skin: String?

    func body(content: Content) -> some View {
        if let id = skin, let f = DecorDessin.reglage(id)?.filtre {
            content
                .hueRotation(.degrees(f.teinte))
                .saturation(f.saturation)
                .colorMultiply(Color(red: f.multiplicateur.0, green: f.multiplicateur.1, blue: f.multiplicateur.2))
                .brightness(f.eclat)
        } else {
            content
        }
    }
}

extension View {
    /// Pose le filtre de couleur d'un décor dessiné en code (voir `DecorDessin.reglage`).
    func filtreDecor(_ skin: String?) -> some View { modifier(FiltreDecor(skin: skin)) }
}

/// Le fond d'origine `nomFond`, le filtre du décor et le décor, sans aucun mouvement. Prend toute la place proposée.
struct FondDecorFige: View {
    let skin: String
    let nomFond: String

    var body: some View {
        Color.clear
            .overlay { Image(nomFond).resizable().scaledToFill().filtreDecor(skin) }
            .overlay { CoucheDecor(skin: skin, anime: false) }
            .clipped()
    }
}

/// Pour le widget : la composition est rendue une fois en image à la taille réelle, puis mise en cache.
struct FondDecorWidget: View {
    let skin: String
    let nomFond: String
    @Environment(\.displayScale) private var echelle

    // ⚠ à vérifier : variable statique modifiable, isolée au fil principal (Swift 6) ; `ImageRenderer` est @MainActor.
    private static var cache: [String: UIImage] = [:]

    var body: some View {
        GeometryReader { geo in
            if let image = Self.rendre(skin: skin, nomFond: nomFond, taille: geo.size, echelle: echelle) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                // Taille inconnue ou rendu impossible : le fond d'origine seul.
                Image(nomFond).resizable().scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        }
    }

    private static func rendre(skin: String, nomFond: String, taille: CGSize, echelle: CGFloat) -> UIImage? {
        guard taille.width > 8, taille.height > 8 else { return nil }
        let facteur = min(max(echelle, 1), 3)
        let cle = "\(skin)|\(nomFond)|\(Int(taille.width))x\(Int(taille.height))|\(facteur)"
        if let connue = cache[cle] { return connue }
        let rendu = ImageRenderer(content: FondDecorFige(skin: skin, nomFond: nomFond)
            .frame(width: taille.width, height: taille.height))
        rendu.scale = facteur
        guard let image = rendu.uiImage else { return nil }
        if cache.count >= 6 { cache.removeAll() }
        cache[cle] = image
        return image
    }
}
