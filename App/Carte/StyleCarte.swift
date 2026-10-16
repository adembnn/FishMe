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

    var estOuverte: Bool {
        if case .ouverte = self { return true }
        return false
    }
}

/// « N pêches, dernier relevé AAAA » : chaque chiffre OFB porte son nombre de pêches et son année (aucune fausse donnée).
nonisolated func texteReleve(nPeches: Int, annee: Int?) -> String {
    let mot = nPeches > 1 ? "pêches" : "pêche"
    guard let annee else { return "\(nPeches) \(mot)" }
    return "\(nPeches) \(mot), dernier relevé \(annee)"
}
