import SwiftUI
import UIKit
import Core

// Les jetons du lot Carte pointent vers App/Style/Style.swift (Palette, Police) : rien de codé en dur ici.

enum CouleursCarte {
    static let accent = Palette.marine
    /// Les spots d'eau (cours d'eau, plans d'eau) : un aqua à part, pour ne pas les confondre avec les stations OFB (marine).
    /// Fond sombre en mode clair (texte blanc lisible), fond clair en mode sombre (glyphe `Palette.surMarine`).
    static let aqua = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.31, green: 0.82, blue: 0.83, alpha: 1)
            : UIColor(red: 0.03, green: 0.46, blue: 0.54, alpha: 1)
    })
    /// La pastille de fréquentation (planche, proposition C « Silhouettes »). Gris, ambre et bleu nuit : jamais de rouge ni de vert
    /// seuls, la forme (1, 2, 3 silhouettes) porte l'information. ⚠ `Style.swift` n'a pas l'ambre de la planche (#B97A0A) : valeurs locales.
    static let frequentationCalme = Palette.commun
    static let frequentationMoyenne = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0xE0 / 255, green: 0xAE / 255, blue: 0x45 / 255, alpha: 1)
            : UIColor(red: 0xB9 / 255, green: 0x7A / 255, blue: 0x0A / 255, alpha: 1)
    })
    static let frequentationForte = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0xA9 / 255, green: 0xD0 / 255, blue: 0xF5 / 255, alpha: 1)
            : UIColor(red: 0x08 / 255, green: 0x2A / 255, blue: 0x4C / 255, alpha: 1)
    })
    static let encreDouce = Palette.encreDouce
    static let filet = Palette.filet
    /// Orange : alertes seulement (espèce fermée, règle non respectée).
    static let alerte = Palette.alerte
    /// À vérifier sur place : pas une alerte, donc encre douce et jamais orange.
    static let attention = Palette.encreDouce

    static func rarete(_ niveau: NiveauRarete) -> Color {
        switch niveau {
        case .commun: return Palette.commun
        case .peuCommun: return Palette.peuCommun
        case .rare: return Palette.rare
        case .legendaire: return Palette.legendaire
        case .nonMesuree: return Palette.encreDouce
        }
    }
}

enum PolicesCarte {
    static func titre() -> Font { Police.titre }
    static func corps() -> Font { Police.corps }
    static func detail() -> Font { Police.detail }
    static func legende() -> Font { Police.legende }
}

extension NiveauRarete {
    /// Une forme par niveau (rond, hexagone, losange, étoile) : la rareté se lit sans la couleur.
    var symboleSF: String {
        switch self {
        case .commun, .nonMesuree: return "circle.fill"
        case .peuCommun: return "hexagon.fill"
        case .rare: return "diamond.fill"
        case .legendaire: return "star.fill"
        }
    }

    /// Du moins rare (0) au plus rare (4) : sert à choisir « le plus rare de ton spot ».
    nonisolated var rang: Int {
        switch self {
        case .nonMesuree: return 0
        case .commun: return 1
        case .peuCommun: return 2
        case .rare: return 3
        case .legendaire: return 4
        }
    }

    var libelle: String {
        switch self {
        case .commun: return "Commun"
        case .peuCommun: return "Peu commun"
        case .rare: return "Rare"
        case .legendaire: return "Légendaire"
        case .nonMesuree: return "Rareté non mesurée"
        }
    }
}

extension OuvertureDuJour {
    /// « ouverte aujourd'hui » ou « fermée jusqu'au 25/04 » ; sans date connue, « fermée ».
    var texte: String {
        switch self {
        case .ouverte: return "ouverte aujourd'hui"
        case .fermee(let date):
            guard let date else { return "fermée" }
            return "fermée jusqu'au " + date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).locale(Locale(identifier: "fr_FR")))
        }
    }

    nonisolated var estOuverte: Bool {
        if case .ouverte = self { return true }
        return false
    }
}

/// Le sigle OFB, dit une fois en toutes lettres au débutant.
nonisolated enum TexteOFB {
    static let nomComplet = "Office français de la biodiversité (OFB)"
    static let explication = "Relevés de l'Office français de la biodiversité (OFB) : des pêches scientifiques dans les rivières."
}

/// Libellé et aide de la catégorie piscicole de l'eau (jamais une simple pastille « ? »).
nonisolated enum TexteCategorie {
    static func libelle(_ c: Categorie) -> String {
        switch c {
        case .premiere: "1re catégorie"
        case .deuxieme: "2e catégorie"
        case .inconnue: "catégorie inconnue"
        }
    }
    static let aide = "1re catégorie : surtout des truites. 2e catégorie : surtout des carnassiers (brochet, sandre) et des poissons blancs."
}

/// « N pêches, dernier relevé AAAA » : chaque chiffre OFB porte son nombre de pêches et son année (aucune fausse donnée).
nonisolated func texteReleve(nPeches: Int, annee: Int?) -> String {
    let mot = nPeches > 1 ? "pêches" : "pêche"
    guard let annee else { return "\(nPeches) \(mot)" }
    return "\(nPeches) \(mot), dernier relevé \(annee)"
}
