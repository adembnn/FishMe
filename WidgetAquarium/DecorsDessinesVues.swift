import Combine
import SwiftUI
import UIKit

// Décors dessinés en code : les vues. Fichier PARTAGÉ app + widget (voir DecorsDessinesBase.swift).
// - `CoucheDecor` : lumière, sol, plantes, rais, poussières, derrière les poissons (posée sur le fond d'origine filtré).
// - `CoucheDecorAvant` : avant-plan, poussières proches et bulles, devant les poissons.
// - `filtreDecor(_:)` : le filtre de couleur du fond d'origine pour un décor.
// - `FondDecorFige` : fond d'origine + filtre + décor, sans mouvement (galerie, widget).
// - `FondDecorWidget` : la même composition, rendue UNE FOIS en image (le widget n'est qu'une image fixe : ni `TimelineView`
//   ni animation continue, et pas de `Canvas` à faire archiver par WidgetKit).
//
// PERFORMANCE (exigence n°1, budget chiffré dans BudgetDecor.swift) :
//  - le dessin fixe est une IMAGE pré-rendue et mise en cache (`CacheDecor`), jamais redessinée à chaque image ;
//  - une seule `TimelineView` par couche (deux par décor au plus), 20 images par seconde au plus, 10 en mode économie
//    d'énergie, EN PAUSE quand l'écran n'est pas visible ou l'app n'est pas active ;
//  - « Réduire les animations » : une seule image fixe (aucune `TimelineView`) ;
//  - aucun flou sur une couche animée ; un seul `GeometryReader` par couche, pas d'allocation lourde dans `body` ;
//  - les deux vues sont `Equatable` : la scène de nage les réévalue à chaque image de l'écran, `equatable()` évite de
//    toucher au décor pour rien.
// ⚠ à vérifier sur Mac : tout ce fichier est écrit sans compilateur.

/// Une couche qui ne bouge pas : l'image pré-rendue si elle est en mémoire, sinon le dessin direct (le temps de la rendre,
/// hors du chemin d'affichage), puis l'image. `memoriser` faux (déjà dans un `ImageRenderer`) : toujours le dessin direct.
private struct CoucheImageVue: View {
    let skin: String
    let couche: CoucheImage
    let taille: CGSize
    let memoriser: Bool
    @Environment(\.displayScale) private var echelle
    @State private var rendue: UIImage?

    var body: some View {
        let cle = CacheDecor.cle(skin: skin, couche: couche, ecran: taille, echelle: echelle)
        Group {
            if memoriser, let image = CacheDecor.existante(cle) ?? rendue {
                Image(uiImage: image).resizable().frame(width: taille.width, height: taille.height)
            } else {
                // Dessin direct, hors du fil principal quand c'est possible ; il ne sert que jusqu'à l'image.
                Canvas(rendersAsynchronously: memoriser) { ctx, ecran in
                    DecorDessin.dessiner(&ctx, couche: couche, ecran: ecran, skin: skin)
                }
            }
        }
        .frame(width: taille.width, height: taille.height)
        .task(id: cle) {
            guard memoriser else { return }
            rendue = CacheDecor.image(skin: skin, couche: couche, ecran: taille, echelle: echelle)
        }
    }
}

/// Le mode économie d'énergie, suivi sans interroger le système à chaque image.
private struct SuiviEconomie: ViewModifier {
    @Binding var economie: Bool

    func body(content: Content) -> some View {
        content
            .onAppear { economie = ProcessInfo.processInfo.isLowPowerModeEnabled }
            .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
                .receive(on: DispatchQueue.main)) { _ in
                economie = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
    }
}

/// Les reflets du sol : des images pré-rendues qu'on fait glisser et respirer. Rien n'est recalculé.
private struct RefletsSolVue: View {
    let images: [UIImage]
    let taille: CGSize
    let t: Double

    var body: some View {
        let dim = DecorDessin.dimensionsReflets(ecran: taille)
        let origine = DecorDessin.origineReflets(ecran: taille)
        ZStack(alignment: .topLeading) {
            ForEach(0..<images.count, id: \.self) { i in
                let sens: Double = i == 0 ? 1 : -1
                let glisse: Double = Double(taille.width) * 0.2 * (i == 0 ? 1 : 0.7) * sin(t * (i == 0 ? 0.16 : 0.11) + Double(i))
                Image(uiImage: images[i])
                    .resizable()
                    .frame(width: dim.width, height: dim.height)
                    .offset(x: origine.x + CGFloat(sens * glisse), y: origine.y)
                    .opacity(0.8 + 0.2 * sin(t * 0.5 + Double(i) * 2))
            }
        }
        .frame(width: taille.width, height: taille.height, alignment: .topLeading)
    }
}

/// Derrière les poissons. `anime` faux (Réduire les animations, galerie, widget) : une seule image, à l'instant `tFixe`.
struct CoucheDecor: View, Equatable {
    let skin: String
    var anime: Bool = true
    /// Faux dans un `ImageRenderer` (widget) : pas de cache imbriqué.
    var memoriser: Bool = true

    @Environment(\.displayScale) private var echelle
    @Environment(\.scenePhase) private var phase
    @State private var visible = false
    @State private var economie = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var reflets: [UIImage] = []

    static func == (a: CoucheDecor, b: CoucheDecor) -> Bool {
        a.skin == b.skin && a.anime == b.anime && a.memoriser == b.memoriser
    }

    var body: some View {
        if DecorDessin.reglage(skin) != nil {
            GeometryReader { geo in
                let taille = geo.size
                ZStack(alignment: .topLeading) {
                    // Le dessin qui ne bouge pas : une image, rendue une seule fois par décor, taille et échelle.
                    CoucheImageVue(skin: skin, couche: anime ? .fixeArriere : .figeeArriere, taille: taille, memoriser: memoriser)
                    if anime { animee(taille) }
                }
                .frame(width: taille.width, height: taille.height, alignment: .topLeading)
                .task(id: "\(Int(taille.width))x\(Int(taille.height))|\(echelle)|\(anime)") {
                    chargerReflets(taille)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { visible = true }
            .onDisappear { visible = false }
            .modifier(SuiviEconomie(economie: $economie))
        }
    }

    /// Ce qui bouge : une seule `TimelineView`, en pause hors écran, 20 (10 en économie) images par seconde au plus.
    private func animee(_ taille: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: BudgetDecor.intervalle(economie: economie),
                                paused: !(visible && phase == .active))) { contexte in
            let t = contexte.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .topLeading) {
                if reflets.count == DecorDessin.nombreReflets {
                    RefletsSolVue(images: reflets, taille: taille, t: t)
                }
                Canvas(rendersAsynchronously: true) { ctx, ecran in
                    DecorDessin.mobileArriere(&ctx, taille: ecran, skin: skin, t: t, economie: economie)
                }
            }
        }
    }

    private func chargerReflets(_ taille: CGSize) {
        guard anime, memoriser, DecorDessin.aDesReflets(skin) else { return }
        var images: [UIImage] = []
        for i in 0..<DecorDessin.nombreReflets {
            if let image = CacheDecor.image(skin: skin, couche: .reflets(i), ecran: taille, echelle: echelle) { images.append(image) }
        }
        if images.count == DecorDessin.nombreReflets { reflets = images }
    }
}

/// Devant les poissons : seulement ce qui ne les cache pas (herbes sur les bords, galets flous, poussières, bulles, bokeh).
struct CoucheDecorAvant: View, Equatable {
    let skin: String
    var anime: Bool = true
    var memoriser: Bool = true

    @Environment(\.scenePhase) private var phase
    @State private var visible = false
    @State private var economie = ProcessInfo.processInfo.isLowPowerModeEnabled

    static func == (a: CoucheDecorAvant, b: CoucheDecorAvant) -> Bool {
        a.skin == b.skin && a.anime == b.anime && a.memoriser == b.memoriser
    }

    var body: some View {
        if DecorDessin.reglage(skin) != nil {
            GeometryReader { geo in
                let taille = geo.size
                ZStack(alignment: .topLeading) {
                    if !anime {
                        CoucheImageVue(skin: skin, couche: .figeeAvant, taille: taille, memoriser: memoriser)
                    } else {
                        if DecorDessin.aUnAvantFixe(skin) {
                            CoucheImageVue(skin: skin, couche: .fixeAvant, taille: taille, memoriser: memoriser)
                        }
                        TimelineView(.animation(minimumInterval: BudgetDecor.intervalle(economie: economie),
                                                paused: !(visible && phase == .active))) { contexte in
                            let t = contexte.date.timeIntervalSinceReferenceDate
                            Canvas(rendersAsynchronously: true) { ctx, ecran in
                                DecorDessin.mobileAvant(&ctx, taille: ecran, skin: skin, t: t, bulles: !economie, economie: economie)
                            }
                        }
                    }
                }
                .frame(width: taille.width, height: taille.height, alignment: .topLeading)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { visible = true }
            .onDisappear { visible = false }
            .modifier(SuiviEconomie(economie: $economie))
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
    /// Vrai dans l'app (galerie) : l'image du décor est mise en cache. Faux dans le widget (déjà dans un `ImageRenderer`).
    var memoriser: Bool = false

    var body: some View {
        Color.clear
            .overlay { Image(nomFond).resizable().scaledToFill().filtreDecor(skin) }
            .overlay { CoucheDecor(skin: skin, anime: false, memoriser: memoriser).equatable() }
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
