import Core
import Foundation

/// Ce qui sort de l'iPhone vers un ami : les seuls champs autorisés (`docs/reports/amis.md`, « Schéma »).
/// Aucune coordonnée, aucun nom de coin, aucun texte libre, aucun pseudo, aucune météo. Le lieu s'arrête au département.
/// Ce type est l'entrée unique du service d'amis : ce qu'il ne porte pas ne peut pas partir.
nonisolated struct CartePartagee: Sendable, Equatable, Hashable, Codable, Identifiable {
    var id: UUID
    /// Identifiant de l'espèce dans la liste de Core (`brochet`).
    var espece: String
    var rarete: NiveauRarete
    var date: Date
    var tailleCm: Double?
    var bredouille: Bool
    /// Code du département seulement (« 94 »), jamais l'eau ni un point.
    var departement: String?
    /// PNG de la carte, sans GPS. `nil` pour une carte déclarée (sans photo). Jamais écrit dans le JSON de la file d'envoi.
    var image: Data? = nil

    enum CodingKeys: String, CodingKey {
        case id, espece, rarete, date, tailleCm, bredouille, departement
    }

    /// Pour un ami, seuls le mois et l'année comptent (comme sur l'image partagée) : le premier du mois, à Paris.
    /// Sans effet sur une date déjà arrondie ; une ancienne carte à date exacte est donc arrondie à l'envoi.
    static func moisEtAnnee(_ date: Date) -> Date {
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = TimeZone(identifier: "Europe/Paris") ?? .gmt
        let composants = calendrier.dateComponents([.year, .month], from: date)
        return calendrier.date(from: composants) ?? date
    }

    /// Les noms des champs, figés : un test compare cette liste à la structure réelle.
    static let champsAutorises: Set<String> = ["id", "espece", "rarete", "date", "tailleCm", "bredouille", "departement", "image"]
}

/// Un ami, par l'identifiant CloudKit de son compte (jamais un texte saisi). Son nom est celui de son compte Apple.
nonisolated struct Ami: Sendable, Equatable, Hashable, Identifiable {
    nonisolated enum Sens: Sendable, Equatable, Hashable {
        /// Je l'ai invité : il voit ma collection.
        case invite
        /// Il m'a invité : je vois la sienne.
        case recu
        case reciproque
    }

    var id: String
    var nom: String
    var sens: Sens
    /// Invitation envoyée, pas encore acceptée.
    var enAttente: Bool = false

    var voitMaCollection: Bool { sens == .invite || sens == .reciproque }
    var jeVoisSaCollection: Bool { sens == .recu || sens == .reciproque }
}

/// Les cartes d'un ami, telles que la dernière lecture (ou le cache) les donne.
nonisolated struct CollectionAmi: Sendable, Equatable, Identifiable {
    var ami: Ami
    var cartes: [CartePartagee]
    var id: String { ami.id }
}

nonisolated enum EtatCompte: Sendable, Equatable {
    case disponible
    /// Pas connecté à iCloud, ou iCloud restreint : un message clair, le Pescedex local reste intact.
    case indisponible
}

nonisolated enum ErreurAmis: Error, Equatable {
    case iCloudIndisponible
    /// Pas de réseau, ou service occupé : l'envoi reste dans la file et sera rejoué.
    case reseau
    case iCloudPlein
    case imageRefusee
    case invitationInvalide
    case introuvable
    case autre
}
