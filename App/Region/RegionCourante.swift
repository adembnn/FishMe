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
    /// Âge minimum pour un profil public, publier et écrire (décision 9 du 7 nov. : 13 ans aux États-Unis, 15 ans en France).
    /// Simple déclaration, aucune date de naissance. ⚠ Avis juridique (COPPA) requis avant toute publication.
    nonisolated var ageMinimum: Int {
        switch self {
        case .france: 15
        case .etatsUnis: 13
        }
    }

    /// Formats de dates et de nombres de la région. La LANGUE des textes n'en dépend plus (`LangueApp`, choisie par le pêcheur).
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
        didSet { reglages.set(choix.rawValue, forKey: Self.cleChoix); appliquerLangue() }
    }

    /// Région déduite de la dernière position connue ; France tant qu'aucune position n'a été vue.
    private(set) var regionDeduite: RegionApp

    /// La langue choisie par le pêcheur (onboarding, Réglages), `nil` tant qu'il n'a rien choisi (la langue suit alors la région).
    var langueChoisie: LangueApp? {
        didSet {
            if let langueChoisie { reglages.set(langueChoisie.rawValue, forKey: LangueApp.cle) } else { reglages.removeObject(forKey: LangueApp.cle) }
            appliquerLangue()
        }
    }

    init(reglages: UserDefaults = .standard) {
        self.reglages = reglages
        self.choix = reglages.string(forKey: Self.cleChoix).flatMap(ChoixRegion.init(rawValue:)) ?? .automatique
        self.regionDeduite = reglages.string(forKey: Self.cleDeduite).flatMap(RegionApp.init(rawValue:)) ?? .france
        self.langueChoisie = LanguePersistee.choix(reglages)
        appliquerLangue()
    }

    /// La langue active : le choix du pêcheur, sinon celle de la région.
    var langue: LangueApp { langueChoisie ?? LangueApp.deLaRegion(region) }

    /// Pose la langue des noms d'espèces (lue par `EspecePechable.nom`).
    private func appliquerLangue() {
        // Seuls les réglages réels posent la langue globale des noms : les tests ont leurs propres `UserDefaults`.
        guard reglages === UserDefaults.standard, !RegionPersistee.estHoteDeTests else { return }
        LangueNoms.courante = langue.codeNoms
    }

    /// La région active : le choix explicite d'abord, sinon la région déduite.
    var region: RegionApp { choix.regionImposee ?? regionDeduite }

    /// La langue des textes (environnement SwiftUI) : celle du pêcheur, pas celle de la région.
    var locale: Locale { langue.locale }
    var systemeUnites: SystemeUnites { region.unitesParDefaut }
    var format: FormatRegion { FormatRegion(region: region) }

    /// Appelée à chaque nouvelle position de l'iPhone. `nil` (position perdue) ne change rien : on garde la dernière région connue.
    func positionConnue(_ position: Coordonnee?) {
        guard let position else { return }
        let deduite = Self.region(pour: position)
        guard deduite != regionDeduite else { return }
        regionDeduite = deduite
        reglages.set(deduite.rawValue, forKey: Self.cleDeduite)
        appliquerLangue()
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
