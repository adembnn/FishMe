import Core
import Foundation
import SwiftData

/// Une carte du Pescedex telle qu'elle est enregistrée sur l'iPhone. Les modèles SwiftData vivent ici, jamais dans Core.
@Model
nonisolated final class CarteEnregistree {
    @Attribute(.unique) var id: UUID
    var especeId: String
    var codeSandre: String?
    var origine: String
    var longueurCm: Double?
    var mesure: String?
    var stade: String?
    var date: Date
    var lieuFlou: String?
    /// Nom du fichier de la photo nettoyée (dossier Cartes), jamais un chemin complet.
    var nomPhoto: String?
    var gardee: Bool
    var exemple: Bool
    /// Instantané des conditions de la prise (L12), encodé ; `nil` : pas de bloc météo.
    var conditionsJSON: Data?
    var dureeSecondes: Double?

    init(prise: Prise, conditionsJSON: Data?, dureeSecondes: Double?) {
        self.id = prise.id
        self.especeId = prise.espece.id
        self.codeSandre = prise.espece.codeSandre
        self.origine = prise.origine.rawValue
        self.longueurCm = prise.longueurCm
        self.mesure = prise.mesure?.rawValue
        self.stade = prise.stade?.rawValue
        self.date = prise.date
        self.lieuFlou = prise.lieuFlou
        self.nomPhoto = prise.cheminPhoto
        self.gardee = prise.gardee
        self.exemple = prise.exemple
        self.conditionsJSON = conditionsJSON
        self.dureeSecondes = dureeSecondes
    }

    var prise: Prise {
        Prise(id: id, espece: Espece(id: especeId, codeSandre: codeSandre),
              origine: OrigineCarte(rawValue: origine) ?? .priseReelle, longueurCm: longueurCm,
              mesure: mesure.flatMap(MethodeMesure.init(rawValue:)), stade: stade.flatMap(StadeAnguille.init(rawValue:)),
              date: date, lieuFlou: lieuFlou, cheminPhoto: nomPhoto, gardee: gardee, exemple: exemple)
    }
}

/// Carte bredouille : une session finie sans prise. Rangée à part, sans rareté.
@Model
nonisolated final class BredouilleEnregistree {
    @Attribute(.unique) var id: UUID
    var debut: Date
    var fin: Date?
    var lieuFlou: String?
    var conditionsJSON: Data?

    init(id: UUID, debut: Date, fin: Date?, lieuFlou: String?, conditionsJSON: Data?) {
        self.id = id
        self.debut = debut
        self.fin = fin
        self.lieuFlou = lieuFlou
        self.conditionsJSON = conditionsJSON
    }
}

/// Ce que les vues lisent d'une carte bredouille.
nonisolated struct CarteBredouille: Sendable, Equatable, Identifiable {
    var id: UUID
    var debut: Date
    var fin: Date?
    var lieuFlou: String?
    /// Conditions du départ de la session, si L12 en a un instantané.
    var conditions: Conditions?

    var dureeSecondes: Double? { fin.map { $0.timeIntervalSince(debut) } }
}

/// Une carte avec ce qui ne tient pas dans `Prise` : instantané météo et durée de la session.
nonisolated struct CarteDetaillee: Sendable, Equatable {
    var prise: Prise
    var conditions: Conditions?
    var dureeSecondes: Double?
}
