import SwiftUI
import Core

// Les jetons du lot Carte pointent vers App/Style/Style.swift (Palette, Police) : rien de codé en dur ici.

enum CouleursCarte {
    static let accent = Palette.marine
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
