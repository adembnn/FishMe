import Foundation
import Core

// « Y aller » (décision 9 du 19 oct.) : Plans, Waze, Google Maps. Seules les applications installées sont proposées ;
// au premier toucher une feuille demande laquelle, avec « Toujours utiliser » ; la préférence se change dans les réglages.
// Ce qui part vers l'application est la coordonnée de la station (le coin), jamais celle du pêcheur : aucune fonction d'ici
// ne reçoit la position de l'iPhone. Logique pure et testable ; l'ouverture réelle est dans `LanceurItineraire` (vue).

nonisolated enum ApplicationItineraire: String, Sendable, Equatable, Hashable, CaseIterable, Identifiable {
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

    /// Un symbole du système par application (aucune image de marque embarquée ici).
    var symbole: String {
        switch self {
        case .plans: return "map.fill"
        case .waze: return "car.fill"
        case .googleMaps: return "location.north.fill"
        }
    }

    /// Le schéma à tester avec `canOpenURL` ; `nil` pour Plans, toujours là. Les schémas `waze` et `comgooglemaps` doivent être
    /// déclarés dans `LSApplicationQueriesSchemes` (fichier Info, à L25) : sinon `canOpenURL` répond non et seul Plans est proposé.
    var schemeATester: String? {
        switch self {
        case .plans: return nil
        case .waze: return "waze"
        case .googleMaps: return "comgooglemaps"
        }
    }

    /// L'adresse à ouvrir pour aller à la coordonnée de la station en voiture ; `nil` pour Plans (ouvert par MapKit).
    func url(vers c: Coordonnee) -> URL? {
        let lat = ApplicationItineraire.decimal(c.latitude)
        let lon = ApplicationItineraire.decimal(c.longitude)
        switch self {
        case .plans: return nil
        case .waze: return URL(string: "waze://?ll=\(lat),\(lon)&navigate=yes")
        case .googleMaps: return URL(string: "comgooglemaps://?daddr=\(lat),\(lon)&directionsmode=driving")
        }
    }

    /// Cinq décimales (environ 1 m), point décimal quel que soit le réglage de langue de l'iPhone.
    private static func decimal(_ v: Double) -> String {
        String(format: "%.5f", locale: Locale(identifier: "en_US_POSIX"), v)
    }

    /// Les applications installées, Plans toujours en premier. `peutOuvrir` est `canOpenURL` (injecté pour les tests).
    static func installees(peutOuvrir: (URL) -> Bool) -> [ApplicationItineraire] {
        allCases.filter { app in
            guard let scheme = app.schemeATester, let url = URL(string: "\(scheme)://") else { return true }
            return peutOuvrir(url)
        }
    }
}

/// Ce que « Y aller » fait au toucher.
nonisolated enum DecisionYAller: Sendable, Equatable {
    /// Ouvre tout de suite cette application (préférence mémorisée, ou Plans seul).
    case ouvrir(ApplicationItineraire)
    /// Demande laquelle (feuille avec « Toujours utiliser »).
    case demander([ApplicationItineraire])

    /// - Une préférence mémorisée et installée : ouverture directe (le 2e toucher).
    /// - Aucune autre application que Plans : Plans directement, sans feuille et sans « Toujours utiliser » (le dialogue ne ment pas).
    /// - Sinon : la feuille, avec les applications installées.
    static func decider(installees: [ApplicationItineraire], preference: ApplicationItineraire?) -> DecisionYAller {
        if let preference, installees.contains(preference) { return .ouvrir(preference) }
        if installees.filter({ $0 != .plans }).isEmpty { return .ouvrir(.plans) }
        return .demander(installees)
    }
}

/// La préférence « toujours utiliser », gardée sur l'iPhone (Réglages de l'app). Absente : on demande.
nonisolated enum PreferenceItineraire {
    static let cle = "carte.applicationItineraire"

    static func lire(_ reglages: UserDefaults = .standard) -> ApplicationItineraire? {
        reglages.string(forKey: cle).flatMap { ApplicationItineraire(rawValue: $0) }
    }

    /// `nil` efface la préférence : « Y aller » redemande.
    static func ecrire(_ application: ApplicationItineraire?, _ reglages: UserDefaults = .standard) {
        if let application { reglages.set(application.rawValue, forKey: cle) } else { reglages.removeObject(forKey: cle) }
    }
}
