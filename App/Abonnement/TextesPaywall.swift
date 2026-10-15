import Foundation
import Core

nonisolated enum UniteDuree: Sendable, Equatable {
    case jour, semaine, mois, an
}

/// Tous les textes du paywall, en fonctions pures (testables). Aucun prix n'est écrit ici : les prix arrivent de StoreKit déjà formatés (`displayPrice`).
nonisolated enum TextesPaywall {
    /// Fin du prix de lancement, affichée telle quelle. La date qui décide du produit montré vient de `offreAffichee(date:)` de Core.
    static let finTarifFondateur = "31 décembre 2026"

    static let renouvellement = "L'abonnement se renouvelle automatiquement, sauf résiliation au moins 24 h avant la fin de la période, dans les réglages de ton compte Apple."

    static func phraseLancement(prixApres: String?) -> String {
        var phrase = "Prix de lancement jusqu'au \(finTarifFondateur)."
        if let prixApres { phrase += " Ensuite \(prixApres) par an pour les nouveaux abonnés." }
        phrase += " Tu gardes ton prix tant que tu restes abonné."
        return phrase
    }

    /// « 1 semaine offerte » : durée et unité lues depuis l'offre d'introduction de StoreKit.
    static func dureeOfferte(valeur: Int, unite: UniteDuree) -> String {
        let pluriel = valeur > 1
        let mot: String
        let offert: String
        switch unite {
        case .jour: mot = pluriel ? "jours" : "jour"; offert = pluriel ? "offerts" : "offert"
        case .semaine: mot = pluriel ? "semaines" : "semaine"; offert = pluriel ? "offertes" : "offerte"
        case .mois: mot = "mois"; offert = pluriel ? "offerts" : "offert"
        case .an: mot = pluriel ? "ans" : "an"; offert = pluriel ? "offerts" : "offert"
        }
        return "\(valeur) \(mot) \(offert)"
    }

    /// Montré seulement si `isEligibleForIntroOffer` répond oui ; sinon `nil` et le paywall montre le prix seul.
    static func essaiMensuel(valeur: Int, unite: UniteDuree, prixParMois: String, eligible: Bool) -> String? {
        guard eligible else { return nil }
        return "\(dureeOfferte(valeur: valeur, unite: unite)), puis \(prixParMois) par mois"
    }

    static func titre(_ fonction: FonctionPro) -> String {
        switch fonction {
        case .septJours: return "7 jours heure par heure"
        case .meteoDuJour: return "La météo des autres spots"
        case .niveauEau: return "Le niveau de l'eau des autres spots"
        case .prevenirMoi: return "« Préviens-moi »"
        case .courbeEtNormale: return "La courbe de la rivière sur 48 h"
        case .conseilsComplets: return "Tous les conseils de chaque espèce"
        case .analyseConditions: return "Tes conditions"
        }
    }

    struct Ligne: Sendable, Equatable { let icone: String; let texte: String }

    static let gratuit: [Ligne] = [
        Ligne(icone: "map", texte: "La carte"),
        Ligne(icone: "checklist", texte: "Les règles et la liste de contrôle"),
        Ligne(icone: "book", texte: "Le Pescedex en lecture"),
        Ligne(icone: "mappin.circle", texte: "Ton spot, des sessions illimitées"),
        Ligne(icone: "cloud.bolt", texte: "Les alertes orage et crue"),
    ]

    static let pro: [Ligne] = [
        Ligne(icone: "mappin.and.ellipse", texte: "Des sessions sur d'autres spots"),
        Ligne(icone: "calendar", texte: "7 jours heure par heure"),
        Ligne(icone: "bell", texte: "« Préviens-moi »"),
        Ligne(icone: "chart.xyaxis.line", texte: "La courbe de la rivière sur 48 h"),
        Ligne(icone: "lightbulb", texte: "Tous les conseils de chaque espèce"),
        Ligne(icone: "list.bullet.clipboard", texte: "Tes conditions, après 10 sorties"),
    ]

    /// La liste Pro, avec la fonction touchée en tête (autre spot : la ligne des spots).
    static func proEnTete(_ declencheur: DeclencheurPaywall) -> [Ligne] {
        let rang: Int
        switch declencheur {
        case .finPremiereSession: return pro
        case .autreSpot: rang = 0
        case .fonction(let fonction):
            switch fonction {
            case .septJours, .meteoDuJour: rang = 1
            case .prevenirMoi: rang = 2
            case .courbeEtNormale, .niveauEau: rang = 3
            case .conseilsComplets: rang = 4
            case .analyseConditions: rang = 5
            }
        }
        var lignes = pro
        let touchee = lignes.remove(at: rang)
        return [touchee] + lignes
    }

    static let produitIntrouvable = "Les offres ne sont pas disponibles pour le moment. Vérifie ta connexion, puis réessaie."
    static let rienARestaurer = "Aucun abonnement à restaurer sur ce compte Apple."
    static let restaure = "Ton abonnement est de retour."
}

extension DeclencheurPaywall {
    /// Le mode de Core (`DecisionAcces.paywall`) vers le déclencheur ; `.aucun` n'ouvre rien.
    init?(mode: ModePaywall) {
        switch mode {
        case .aucun: return nil
        case .quiSeFerme: self = .finPremiereSession
        case .quiBloque: self = .autreSpot
        }
    }

    /// Le bouton qui ferme le paywall. Seul le déclencheur de fin de 1re session promet de continuer gratuitement.
    var texteFermeture: String {
        switch self {
        case .finPremiereSession: return "Continuer gratuitement sur mon spot"
        case .autreSpot: return "Retour à la carte"
        case .fonction: return "Pas maintenant"
        }
    }
}
