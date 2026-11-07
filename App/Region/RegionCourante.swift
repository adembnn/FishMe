import Core
import Foundation
import Observation

/// Le choix du pêcheur dans Réglages > Région. « Automatique » : la région vient de la position.
enum ChoixRegion: String, CaseIterable, Sendable, Identifiable {
    case automatique
    case france
    case etatsUnis

    var id: String { rawValue }

    /// La région imposée, ou `nil` en automatique.
    var regionImposee: RegionApp? {
        switch self {
        case .automatique: nil
        case .france: .france
        case .etatsUnis: .etatsUnis
        }
    }
}

extension RegionApp {
    /// Langue et formats de dates de la région (décision 7 du 7 nov. : la langue suit la région, pas le téléphone).
    nonisolated var locale: Locale {
        switch self {
        case .france: Locale(identifier: "fr_FR")
        case .etatsUnis: Locale(identifier: "en_US")
        }
    }
}

/// La région active de l'app (décision 7 du 7 nov.), injectée dans SwiftUI depuis `RootView`.
///
/// Ordre : 1. le choix explicite du pêcheur (Réglages), 2. la région déduite de la dernière position connue, 3. la France.
/// Vie privée : la déduction se fait sur l'iPhone, par comparaison avec des cadres géographiques grossiers (aucun géocodage,
/// aucun envoi de la position à Apple ni à personne). Seule la région déduite est gardée (« france » ou « etatsUnis »),
/// jamais les coordonnées.
@MainActor
@Observable
final class RegionCourante {
    static let cleChoix = RegionPersistee.cleChoix
    static let cleDeduite = RegionPersistee.cleDeduite

    @ObservationIgnored private let reglages: UserDefaults

    /// Le choix du pêcheur, mémorisé dans `UserDefaults` dès qu'il change.
    var choix: ChoixRegion {
        didSet { reglages.set(choix.rawValue, forKey: Self.cleChoix) }
    }

    /// Région déduite de la dernière position connue ; France tant qu'aucune position n'a été vue.
    private(set) var regionDeduite: RegionApp

    init(reglages: UserDefaults = .standard) {
        self.reglages = reglages
        self.choix = reglages.string(forKey: Self.cleChoix).flatMap(ChoixRegion.init(rawValue:)) ?? .automatique
        self.regionDeduite = reglages.string(forKey: Self.cleDeduite).flatMap(RegionApp.init(rawValue:)) ?? .france
    }

    /// La région active : le choix explicite d'abord, sinon la région déduite.
    var region: RegionApp { choix.regionImposee ?? regionDeduite }

    var locale: Locale { region.locale }
    var systemeUnites: SystemeUnites { region.unitesParDefaut }
    var format: FormatRegion { FormatRegion(region: region) }

    /// Appelée à chaque nouvelle position de l'iPhone. `nil` (position perdue) ne change rien : on garde la dernière région connue.
    func positionConnue(_ position: Coordonnee?) {
        guard let position else { return }
        let deduite = Self.region(pour: position)
        guard deduite != regionDeduite else { return }
        regionDeduite = deduite
        reglages.set(deduite.rawValue, forKey: Self.cleDeduite)
    }

    /// États-Unis si le point tombe dans l'un des cadres des États-Unis, sinon France. Les cadres sont grossiers (frontières
    /// avec le Canada et le Mexique approchées) : près d'une frontière, le pêcheur règle la région à la main.
    static func region(pour p: Coordonnee) -> RegionApp {
        cadresEtatsUnis.contains { $0.contient(p) } ? .etatsUnis : .france
    }

    struct Cadre: Sendable {
        let sud: Double, nord: Double, ouest: Double, est: Double
        func contient(_ p: Coordonnee) -> Bool {
            p.latitude >= sud && p.latitude <= nord && p.longitude >= ouest && p.longitude <= est
        }
    }

    /// 48 États contigus (frontière nord au 49e parallèle ; sud relevé de la frontière du Mexique là où elle est à peu près
    /// horizontale), Alaska, Hawaï. Territoires non couverts.
    static let cadresEtatsUnis: [Cadre] = [
        Cadre(sud: 32.7, nord: 49.0, ouest: -124.8, est: -114.7),   // Californie (Basse-Californie exclue), Oregon, Washington
        Cadre(sud: 31.4, nord: 49.0, ouest: -114.7, est: -106.6),   // Intérieur ouest, Arizona, Nouveau-Mexique
        Cadre(sud: 29.0, nord: 49.0, ouest: -106.6, est: -100.0),   // Texas ouest (frontière du Rio Grande à peu près)
        Cadre(sud: 25.8, nord: 49.0, ouest: -100.0, est: -80.0),    // Centre et Sud-Est
        Cadre(sud: 24.4, nord: 31.0, ouest: -87.7, est: -79.8),     // Floride
        Cadre(sud: 24.4, nord: 47.5, ouest: -80.0, est: -66.9),     // Floride, côte Est, Nouvelle-Angleterre
        Cadre(sud: 51.0, nord: 71.5, ouest: -170.0, est: -141.0),   // Alaska
        Cadre(sud: 54.5, nord: 60.0, ouest: -141.0, est: -130.0),   // Alaska, pointe du Sud-Est
        Cadre(sud: 18.8, nord: 22.4, ouest: -160.4, est: -154.7),   // Hawaï
    ]
}
