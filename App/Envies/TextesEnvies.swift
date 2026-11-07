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
    static func ligneDuPescedex(nombre: Int, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        AnglaisE.f("Mes envies · %lld", locale, nombre)
    }

    /// `dd/MM`, locale `fr_FR`, fuseau de Paris (même format que `ExtensionsConseils.texteFermeture`).
    static func jourMois(_ date: Date, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.timeZone = TimeZone(identifier: "Europe/Paris")
        if locale.language.languageCode?.identifier == "fr" {
            f.dateFormat = "dd/MM"
        } else {
            f.setLocalizedDateFormatFromTemplate("MMMd")
        }
        return f.string(from: date)
    }

    /// La ligne d'ouverture, sans sa source (la source est un lien à part).
    static func ouverture(_ statut: StatutOuverture, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        switch statut {
        case .ouverte: AnglaisE.t("Ouverte aujourd'hui", locale)
        case .fermee(let date?, _): AnglaisE.f("Fermée jusqu'au %@", locale, jourMois(date, locale: locale))
        case .fermee(nil, _): AnglaisE.t("Fermée ce jour", locale)
        case .aVerifier: AnglaisE.t(verifieLArrete, locale)
        case .sansSpot: AnglaisE.t(choisirUnSpot, locale)
        }
    }

    static func source(_ statut: StatutOuverture) -> SourceRegle? {
        switch statut {
        case .ouverte(let s): s
        case .fermee(_, let s): s
        case .aVerifier, .sansSpot: nil
        }
    }

    static func libelle(_ ordre: OrdreEnvies, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        switch ordre {
        case .ouvertesDAbord: AnglaisE.t("Ouvertes d'abord", locale)
        case .recentes: AnglaisE.t("Récentes", locale)
        case .alphabetique: AnglaisE.t("A à Z", locale)
        }
    }

    static func libelleAccessibilite(ajouter: Bool, nom: String, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        ajouter ? AnglaisE.f("%@, ajouter à mes envies", locale, nom) : AnglaisE.f("%@, retirer de mes envies", locale, nom)
    }
}
