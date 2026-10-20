import Foundation

// Les trois hauteurs d'une feuille de la carte (fiche d'un coin, « Mon spot ») : moyen, grand, plein écran.
// Logique pure, sans écran : la vue ne fait que dessiner la hauteur qu'on lui donne.
// Pourquoi une feuille à nous et pas `.sheet` : la mention légale de Plans (en bas de la carte) disparaissait sous la feuille ;
// ici la carte réserve la hauteur de la feuille en bas, la mention reste au-dessus d'elle, quelle que soit la hauteur.

nonisolated enum DetentPanneau: Int, Sendable, Equatable, CaseIterable, Comparable {
    case moyen = 0, grand, pleinEcran

    /// Part de la hauteur disponible (la carte, hors barre d'onglets). Moyen laisse voir la carte et le coin touché.
    var part: Double {
        switch self {
        case .moyen: return 0.42
        case .grand: return 0.72
        case .pleinEcran: return 1.0
        }
    }

    static func < (a: DetentPanneau, b: DetentPanneau) -> Bool { a.rawValue < b.rawValue }

    func hauteur(dans total: Double) -> Double { max(0, total) * part }

    /// Le cran suivant en montant, puis retour au moyen : un toucher sur la poignée parcourt les trois hauteurs.
    var suivantEnBoucle: DetentPanneau {
        switch self {
        case .moyen: return .grand
        case .grand: return .pleinEcran
        case .pleinEcran: return .moyen
        }
    }

    var plusHaut: DetentPanneau { DetentPanneau(rawValue: min(rawValue + 1, DetentPanneau.pleinEcran.rawValue)) ?? .pleinEcran }
    var plusBas: DetentPanneau { DetentPanneau(rawValue: max(rawValue - 1, 0)) ?? .moyen }

    /// Le nom lu par VoiceOver.
    var libelle: String {
        switch self {
        case .moyen: return "hauteur moyenne"
        case .grand: return "grande hauteur"
        case .pleinEcran: return "plein écran"
        }
    }

    /// La hauteur que la carte réserve en bas pour garder sa mention légale lisible. En plein écran la carte est cachée :
    /// elle garde la réserve de « grand » pour ne pas se redimensionner.
    func reservation(dans total: Double) -> Double {
        (self == .pleinEcran ? DetentPanneau.grand : self).hauteur(dans: total)
    }
}

/// Ce que devient la feuille quand le doigt lâche la poignée.
nonisolated enum FinDeGlissement: Sendable, Equatable {
    case rester(DetentPanneau)
    case fermer
}

nonisolated enum RegleGlissement {
    /// Un glissement plus court que ce seuil (en points) n'est qu'un toucher.
    static let seuilToucher = 6.0
    /// Sous cette part du cran moyen, une feuille qui se ferme se ferme (sinon elle revient au moyen).
    static let partFermeture = 0.6

    /// `hauteur` : la hauteur de la feuille au moment où le doigt lâche (hauteur du cran de départ moins le glissement vers le bas).
    /// `vitesse` : points par seconde, positive vers le bas. Un geste vif d'une seule direction saute un cran.
    /// Sans `fermable`, la feuille ne se ferme pas (elle reste au moyen).
    static func fin(hauteur: Double, total: Double, depart: DetentPanneau, vitesse: Double, fermable: Bool) -> FinDeGlissement {
        guard total > 0 else { return .rester(depart) }
        if vitesse > 900 {
            if depart == .moyen { return fermable ? .fermer : .rester(.moyen) }
            return .rester(depart.plusBas)
        }
        if vitesse < -900 { return .rester(depart.plusHaut) }
        if fermable, hauteur < DetentPanneau.moyen.hauteur(dans: total) * partFermeture { return .fermer }
        // Le cran le plus proche de la hauteur atteinte.
        let plusProche = DetentPanneau.allCases.min { a, b in
            abs(a.hauteur(dans: total) - hauteur) < abs(b.hauteur(dans: total) - hauteur)
        }
        return .rester(plusProche ?? depart)
    }
}
