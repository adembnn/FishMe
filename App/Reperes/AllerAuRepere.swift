import Core
import Foundation

/// Les applications d'itinéraire. La décision 9 du 19 oct. envoie la coordonnée d'une station, jamais celle du pêcheur ; un repère
/// est la coordonnée du pêcheur : Plans (Apple) part sans question, Waze et Google Maps seulement après une ligne de confirmation,
/// à chaque fois (décision 4 de la fiche N6, par défaut, à confirmer par Adem).
nonisolated enum DestinationRepere: String, CaseIterable, Identifiable, Sendable {
    case plans
    case waze
    case googleMaps

    var id: String { rawValue }

    var nom: String {
        switch self {
        case .plans: return "Plans"
        case .waze: return "Waze"
        case .googleMaps: return "Google Maps"
        }
    }

    /// Une application tierce reçoit la coordonnée : il faut le dire avant.
    var demandeConfirmation: Bool { self != .plans }
}

nonisolated enum AllerAuRepere {
    /// L'adresse à ouvrir. Aucune coordonnée n'est écrite dans un journal, envoyée à un serveur de FishMe ou copiée dans le presse-papiers.
    static func url(pour destination: DestinationRepere, position: Coordonnee) -> URL? {
        let lat = decimal(position.latitude), lon = decimal(position.longitude)
        switch destination {
        case .plans: return URL(string: "https://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d")
        case .waze: return URL(string: "waze://?ll=\(lat),\(lon)&navigate=yes")
        case .googleMaps: return URL(string: "comgooglemaps://?daddr=\(lat),\(lon)&directionsmode=driving")
        }
    }

    /// Point décimal et 6 décimales, quelle que soit la langue de l'iPhone.
    static func decimal(_ valeur: Double) -> String {
        String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), valeur)
    }
}
