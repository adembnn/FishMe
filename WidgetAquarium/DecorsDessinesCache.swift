import SwiftUI
import UIKit

// Décors dessinés en code : les images pré-rendues. Fichier PARTAGÉ app + widget (voir DecorsDessinesBase.swift).
// Règle de performance n°1 (BudgetDecor.swift) : tout ce qui ne bouge pas est rendu UNE fois en image (`ImageRenderer`)
// puis gardé en mémoire, par décor, par couche, par taille et par échelle d'écran. Le flou est appliqué à ce moment-là, une seule
// fois, jamais sur une couche animée. La graine du dessin est fixe (une graine par décor, voir `GraineDecor`) : la même clé
// donne toujours la même image.
// ⚠ à vérifier sur Mac : `ImageRenderer` avec un `Canvas`, temps du premier rendu (Instruments), mémoire.

/// Une image pré-rendue d'un décor.
nonisolated enum CoucheImage: Hashable, Sendable {
    /// Derrière les poissons : calques de lumière et dessin fixe (sol, roches, bouées floues…).
    case fixeArriere
    /// Devant les poissons : le dessin fixe de l'avant-plan (galets flous).
    case fixeAvant
    /// « Réduire les animations », galerie, widget : l'arrière complet à l'instant figé (fixe + mobile + reflets).
    case figeeArriere
    /// Idem pour l'avant (sans bulles).
    case figeeAvant
    /// Une famille de reflets du sol, qui glisse par `offset` (Été).
    case reflets(Int)
}

nonisolated extension DecorDessin {
    /// Nombre de familles de reflets pré-rendus (images qui glissent). Plafonné par `BudgetDecor.imagesMobilesMax`.
    static let nombreReflets = 2

    /// Taille en points de l'image d'une couche, pour un écran de la taille `ecran`.
    static func dimensions(_ couche: CoucheImage, ecran: CGSize) -> CGSize {
        switch couche {
        case .reflets: return dimensionsReflets(ecran: ecran)
        default: return ecran
        }
    }

    /// Dessine une couche dans `ctx`. `ecran` est la taille de l'écran (ou de la vignette, du widget) du décor.
    static func dessiner(_ ctx: inout GraphicsContext, couche: CoucheImage, ecran: CGSize, skin: String) {
        switch couche {
        case .fixeArriere:
            fixeArriere(&ctx, taille: ecran, skin: skin)
        case .fixeAvant:
            fixeAvant(&ctx, taille: ecran, skin: skin)
        case .figeeArriere:
            fixeArriere(&ctx, taille: ecran, skin: skin)
            if aDesReflets(skin) {
                for famille in 0..<nombreReflets {
                    reflets(&ctx, ecran: ecran, famille: famille, origine: origineReflets(ecran: ecran))
                }
            }
            mobileArriere(&ctx, taille: ecran, skin: skin, t: tFixe)
        case .figeeAvant:
            fixeAvant(&ctx, taille: ecran, skin: skin)
            mobileAvant(&ctx, taille: ecran, skin: skin, t: tFixe, bulles: false)
        case .reflets(let famille):
            reflets(&ctx, ecran: ecran, famille: famille, origine: .zero)
        }
    }
}

/// La mémoire des images pré-rendues. Au fil principal (`ImageRenderer` y vit).
/// Plafond en octets : les plus anciennes images sont rendues à nouveau au besoin (jamais de fuite).
@MainActor
enum CacheDecor {
    // ⚠ à vérifier : variables statiques modifiables, isolées au fil principal (Swift 6).
    private static var images: [String: UIImage] = [:]
    private static var ordre: [String] = []
    private static var octets: [String: Int] = [:]
    private static var total = 0

    /// Au plus 96 Mo d'images en mémoire (un plein écran @3x pèse environ 12 Mo).
    static let octetsMax = 96 * 1024 * 1024

    static func cle(skin: String, couche: CoucheImage, ecran: CGSize, echelle: CGFloat) -> String {
        let facteur = min(max(echelle, 1), 3)
        return "\(skin)|\(couche)|\(Int(ecran.width))x\(Int(ecran.height))|\(facteur)"
    }

    /// L'image déjà rendue, ou `nil`. N'en rend jamais une (sûre à appeler dans un `body`).
    static func existante(_ cle: String) -> UIImage? {
        guard let image = images[cle] else { return nil }
        if ordre.last != cle {
            ordre.removeAll { $0 == cle }
            ordre.append(cle)
        }
        return image
    }

    /// L'image de cette couche : celle de la mémoire, sinon elle est rendue une fois (taille et échelle donnent la clé).
    static func image(skin: String, couche: CoucheImage, ecran: CGSize, echelle: CGFloat) -> UIImage? {
        guard ecran.width > 8, ecran.height > 8, DecorDessin.reglage(skin) != nil else { return nil }
        let facteur = min(max(echelle, 1), 3)
        let clef = cle(skin: skin, couche: couche, ecran: ecran, echelle: echelle)
        if let connue = existante(clef) { return connue }
        let dim = DecorDessin.dimensions(couche, ecran: ecran)
        let contenu = Canvas { ctx, _ in
            DecorDessin.dessiner(&ctx, couche: couche, ecran: ecran, skin: skin)
        }
        .frame(width: dim.width, height: dim.height)
        let rendu = ImageRenderer(content: contenu)
        rendu.scale = facteur
        guard let image = rendu.uiImage else { return nil }
        garder(image, cle: clef, octets: Int(dim.width * facteur) * Int(dim.height * facteur) * 4)
        return image
    }

    private static func garder(_ image: UIImage, cle: String, octets poids: Int) {
        while total + poids > octetsMax, let plusAncienne = ordre.first {
            ordre.removeFirst()
            images[plusAncienne] = nil
            total -= octets[plusAncienne] ?? 0
            octets[plusAncienne] = nil
        }
        images[cle] = image
        octets[cle] = poids
        ordre.append(cle)
        total += poids
    }

    /// Vide la mémoire (alerte mémoire, changement d'apparence si besoin).
    static func vider() {
        images.removeAll()
        ordre.removeAll()
        octets.removeAll()
        total = 0
    }
}
