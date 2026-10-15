import Foundation
import Core

/// Une lecture de la météo et de la rivière pour un spot. Ne garde que le point arrondi de `pointMeteo`, jamais le coin exact.
nonisolated struct LectureConditions: Sendable, Equatable, Codable {
    var point: Coordonnee
    var conditions: Conditions
    var meteo: MeteoBrute
    var eau: NiveauEau?
    var alerte: Alerte?
    var lueLe: Date
    /// Vrai quand la lecture vient du cache faute de réseau.
    var depuisCache: Bool = false
}

/// Marque Apple Weather : liens lus dans `WeatherService.shared.attribution`.
nonisolated struct MarqueApple: Sendable, Equatable, Codable {
    var nom: String
    var claireURL: URL
    var sombreURL: URL
    var legaleURL: URL
}

/// Source de la météo. L'implémentation réelle lit WeatherKit ; le faux sert aux tests et aux aperçus.
nonisolated protocol SourceMeteo: Sendable {
    /// `point` est toujours le résultat de `pointMeteo(spot:)`.
    func meteo(point: Coordonnee, de: Date, a: Date) async throws -> MeteoBrute
}

nonisolated protocol SourceMarque: Sendable {
    func marque() async -> MarqueApple?
}

nonisolated enum ErreurConditions: Error { case indisponible }

nonisolated enum LiensOfficiels {
    static var vigilanceMeteoFrance: URL { URL(string: "https://vigilance.meteofrance.fr")! }
    static var vigicrues: URL { URL(string: "https://www.vigicrues.gouv.fr")! }
}
