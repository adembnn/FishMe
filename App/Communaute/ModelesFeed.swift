import Core
import Foundation

// Types du fil (lot L23). Les noms portent « Feed » pour ne pas heurter ceux d'Amis, Club ou des lots L21, L22, L24.
// Le schéma des enregistrements CloudKit est celui de `docs/reports/reseau/schema.md` (R2, 19 oct.).

nonisolated enum GenreMedia: String, Sendable, Codable {
    case photo, video
}

/// Ce que le pêcheur a choisi de montrer comme lieu. Les valeurs brutes sont celles du champ `lieuMode`.
nonisolated enum ModeLieu: String, Sendable, Codable, CaseIterable {
    case coursEau = "cours-eau"
    case departement
    case aucun
}

nonisolated enum SectionFeed: String, Sendable, CaseIterable, Identifiable {
    case clubs, amis, region
    var id: String { rawValue }
    var titre: String {
        switch self {
        case .clubs: "Tes clubs"
        case .amis: "Tes amis"
        case .region: "Dans ta région"
        }
    }
    var symbole: String {
        switch self {
        case .clubs: "person.3.fill"
        case .amis: "person.2.fill"
        case .region: "map.fill"
        }
    }
}

/// Une publication, telle que le fil l'affiche. Aucune coordonnée : le lieu est le texte choisi à la publication.
nonisolated struct PublicationFeed: Sendable, Equatable, Identifiable {
    var id: String
    /// `recordName` du profil de l'auteur. À aligner L21 : le surnom affiché et l'avatar viennent de `Profil`.
    var auteurNom: String
    var genre: GenreMedia
    var dureeS: Int
    var legende: String
    var lieuMode: ModeLieu
    /// « La Marne · 94 » seulement si `lieuMode` vaut `coursEau`. Texte affiché, jamais interrogé.
    var lieuTexte: String
    /// Code du département (« 94 ») ; vide si `lieuMode` vaut `aucun`.
    var departement: String
    var espece: String?
    var rarete: NiveauRarete?
    var tailleCm: Double?
    /// `recordName` du club ; vide si la publication n'est pour aucun club.
    var club: String
    var creeLe: Date
    /// Fichier local de la vignette (téléchargé ou en cache).
    var vignette: URL?
    var nbLikes: Int = 0
    var aime: Bool = false
    /// Publication d'exemple du mode démo : marquée « Exemple », lecture seule, jamais envoyée ni gardée en cache.
    var exemple = false

    /// Le nom lisible de l'auteur (À aligner L21 : `surnomAffiche`). Le `recordName` est `p-` + surnom normalisé.
    var auteurAffiche: String { AuteurFeed.nomLisible(auteurNom) }

    /// Exactement le lieu choisi par le pêcheur, ou rien.
    var lieuAffiche: String? {
        switch lieuMode {
        case .coursEau: lieuTexte.isEmpty ? nil : lieuTexte
        case .departement: departement.isEmpty ? nil : "Département \(departement)"
        case .aucun: nil
        }
    }
}

nonisolated enum AuteurFeed {
    static func nomLisible(_ recordName: String) -> String {
        recordName.hasPrefix("p-") ? String(recordName.dropFirst(2)) : recordName
    }
}

nonisolated struct CommentaireFeed: Sendable, Equatable, Identifiable {
    var id: String
    var publication: String
    var auteurNom: String
    var texte: String
    var creeLe: Date
    var auteurAffiche: String { AuteurFeed.nomLisible(auteurNom) }
}

/// La carte du Pescedex liée à une publication (espèce, rareté, taille) : jamais de lieu exact.
nonisolated struct CarteLiee: Sendable, Equatable {
    var espece: String
    var rarete: NiveauRarete
    var tailleCm: Double?
}

/// Liste fermée (`moderation.md`) : pas de texte libre. Même liste, mêmes mots et mêmes valeurs brutes que `MotifSignalement` de L21
/// (profils) : l'énumération reste propre à L23 (pas de dépendance entre lots), alignée sur ses libellés.
nonisolated enum MotifSignalementPublication: String, Sendable, CaseIterable, Identifiable {
    case choquant, harcelement, nudite, cruaute, pecheIllegale, coinExact, mineur, spam, autre
    var id: String { rawValue }
    var titre: String {
        switch self {
        case .choquant: "Contenu choquant ou violent"
        case .harcelement: "Haine ou harcèlement"
        case .nudite: "Nudité ou contenu sexuel"
        case .cruaute: "Cruauté envers un animal"
        case .pecheIllegale: "Pêche illégale"
        case .coinExact: "Coin de pêche exact révélé"
        case .mineur: "Personne mineure sans accord"
        case .spam: "Spam ou publicité"
        case .autre: "Autre"
        }
    }
    var symbole: String {
        switch self {
        case .choquant: "exclamationmark.triangle"
        case .harcelement: "bubble.left.and.exclamationmark.bubble.right"
        case .nudite: "eye.slash"
        case .cruaute: "pawprint"
        case .pecheIllegale: "scalemass"
        case .coinExact: "mappin.slash"
        case .mineur: "person.crop.circle.badge.exclamationmark"
        case .spam: "megaphone"
        case .autre: "flag"
        }
    }
}

nonisolated enum TypeCible: String, Sendable {
    case publication, commentaire
}

nonisolated struct SignalementFeed: Sendable, Equatable {
    var id: String = UUID().uuidString
    var cible: String
    var typeCible: TypeCible
    var motif: MotifSignalementPublication
    var signalePar: String
    /// Sert à l'e-mail seulement ; jamais écrit dans l'enregistrement.
    var auteurCible: String
    /// Le texte signalé (légende ou commentaire), joint à l'e-mail seulement ; jamais écrit dans l'enregistrement.
    var extrait: String = ""
}

/// Ce qui s'est vraiment passé. « Signalé » ne se dit que si l'enregistrement `Signalement` a réussi.
nonisolated enum IssueSignalement: Sendable, Equatable {
    /// La trace est écrite. `courriel` : l'e-mail prérempli, seulement si Mail est disponible ; il n'est jamais dit « envoyé ».
    case enregistre(courriel: URL?)
    /// L'écriture a échoué : le signalement est dans la file de reprise, rejouée au prochain chargement. Même e-mail possible.
    case pasEnregistre(courriel: URL?)
    /// Mode démo : masqué chez toi, rien n'est envoyé.
    case exemple

    var courriel: URL? {
        switch self {
        case .enregistre(let url), .pasEnregistre(let url): url
        case .exemple: nil
        }
    }
}

nonisolated enum ErreurFeed: Error, Equatable {
    case iCloudIndisponible
    /// Pas de réseau, ou service occupé.
    case reseau
    case iCloudPlein
    case introuvable
    case refuse
    /// Publications d'exemple (mode démo) : on lit, on n'écrit rien.
    case lectureSeule
    case autre
}
