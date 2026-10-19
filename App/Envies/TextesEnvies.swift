import Core
import Foundation

/// Les phrases de « Mes envies ». Pur texte : ni verdict, ni promesse. La ligne d'ouverture est une porte vers la source.
nonisolated enum TextesEnvies {
    static let titre = "Mes envies"
    static let jeVeuxLaPecher = "Je veux la pêcher"
    static let dansMesEnvies = "Dans mes envies"
    static let retirer = "Retirer"
    static let choisirUnSpot = "Choisis un spot pour voir l'ouverture"
    static let verifieLArrete = "Vérifie l'arrêté"
    static let conseilDuMois = "Conseil du mois"
    static let videPhrase = "Rien ici pour l'instant. Sur la fiche d'une espèce, touche « Je veux la pêcher »."

    /// « Mes envies · 3 ».
    static func ligneDuPescedex(nombre: Int) -> String { "\(titre) · \(nombre)" }

    /// `dd/MM`, locale `fr_FR`, fuseau de Paris (même format que `ExtensionsConseils.texteFermeture`).
    static func jourMois(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.timeZone = TimeZone(identifier: "Europe/Paris")
        f.dateFormat = "dd/MM"
        return f.string(from: date)
    }

    /// La ligne d'ouverture, sans sa source (la source est un lien à part).
    static func ouverture(_ statut: StatutOuverture) -> String {
        switch statut {
        case .ouverte: "Ouverte aujourd'hui"
        case .fermee(let date?, _): "Fermée jusqu'au \(jourMois(date))"
        case .fermee(nil, _): "Fermée ce jour"
        case .aVerifier: verifieLArrete
        case .sansSpot: choisirUnSpot
        }
    }

    static func source(_ statut: StatutOuverture) -> SourceRegle? {
        switch statut {
        case .ouverte(let s): s
        case .fermee(_, let s): s
        case .aVerifier, .sansSpot: nil
        }
    }

    static func libelle(_ ordre: OrdreEnvies) -> String {
        switch ordre {
        case .ouvertesDAbord: "Ouvertes d'abord"
        case .recentes: "Récentes"
        case .alphabetique: "A à Z"
        }
    }

    static func libelleAccessibilite(ajouter: Bool, nom: String) -> String {
        ajouter ? "\(nom), ajouter à mes envies" : "\(nom), retirer de mes envies"
    }
}
