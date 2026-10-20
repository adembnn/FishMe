import CoreLocation
import Foundation
import Observation
import Core

/// La position de l'iPhone, « pendant l'usage » seulement. Refusée, l'app marche pareil (choix du département ou de la commune).
@Observable
final class GestionPosition: NSObject, CLLocationManagerDelegate {
    private(set) var statut: CLAuthorizationStatus
    private(set) var position: Coordonnee?
    /// Vrai si l'iPhone n'a pas pu donner de position (simulateur sans lieu, intérieur, mode avion).
    private(set) var echec = false
    /// Vrai si le pêcheur a laissé « Position précise » éteinte dans les réglages d'iOS : l'iPhone donne alors un point à plusieurs
    /// kilomètres près, ce qui fausse la carte même avec « toujours autoriser ». La carte le dit d'une icône, sans bloquer.
    private(set) var precisionReduite = false

    @ObservationIgnored private let manager: CLLocationManager
    @ObservationIgnored private let reglages: UserDefaults
    /// Une seule redemande, au premier écran de carte (Adem, 15 oct.).
    @ObservationIgnored private static let cleRedemande = "carte.redemandeFaite"

    init(reglages: UserDefaults = .standard, statutInitial: CLAuthorizationStatus? = nil) {
        let manager = CLLocationManager()
        self.manager = manager
        self.reglages = reglages
        self.statut = statutInitial ?? manager.authorizationStatus
        self.precisionReduite = statutInitial == nil && manager.accuracyAuthorization == .reducedAccuracy
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var estAutorisee: Bool { statut == .authorizedWhenInUse || statut == .authorizedAlways }
    var estRefusee: Bool { statut == .denied || statut == .restricted }
    var nAPasEteDemandee: Bool { statut == .notDetermined }

    /// Au premier écran de carte : demande la permission si elle n'a jamais été posée, lit la position si elle est donnée.
    func demanderAuPremierEcran() {
        switch statut {
        case .notDetermined:
            // La question du système compte comme la demande : un refus ici ne déclenche pas la redemande.
            reglages.set(true, forKey: Self.cleRedemande)
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        default: break
        }
    }

    /// Vrai une seule fois : la permission a été refusée plus tôt, et on la redemande ici une fois (par les réglages,
    /// car iOS ne repose pas lui-même la question après un refus).
    func doitRedemanderUneFois() -> Bool {
        guard estRefusee, !reglages.bool(forKey: Self.cleRedemande) else { return false }
        reglages.set(true, forKey: Self.cleRedemande)
        return true
    }

    /// « Autour de moi » : relit la position.
    func relire() {
        if estAutorisee { manager.requestLocation() }
    }

    /// Clé de la raison affichée par iOS pour la précision exacte temporaire. ⚠ à brancher par A (L25) : elle doit exister dans
    /// `NSLocationTemporaryUsageDescriptionDictionary` du fichier Info ; sans elle, la demande n'est pas faite (aucun plantage).
    static let cleRaisonPrecisionExacte = "CarteRecentrer"

    /// Précision réduite : demande la précision exacte pour cette utilisation seulement (API d'Apple, iOS 14 et plus).
    func demanderPrecisionExacte() {
        guard estAutorisee, precisionReduite,
              Bundle.main.object(forInfoDictionaryKey: "NSLocationTemporaryUsageDescriptionDictionary") != nil else { return }
        manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: Self.cleRaisonPrecisionExacte) { @Sendable [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.precisionReduite = self.manager.accuracyAuthorization == .reducedAccuracy
                self.manager.requestLocation()
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let nouveau = manager.authorizationStatus
        let reduite = manager.accuracyAuthorization == .reducedAccuracy
        Task { @MainActor in
            self.statut = nouveau
            self.precisionReduite = reduite
            if self.estAutorisee { self.manager.requestLocation() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Un point invalide (précision négative) ou vieux de plus de 2 minutes n'est pas la position du pêcheur : on l'ignore.
        guard let derniere = locations.last, derniere.horizontalAccuracy >= 0,
              abs(derniere.timestamp.timeIntervalSinceNow) < 120 else { return }
        let c = Coordonnee(latitude: derniere.coordinate.latitude, longitude: derniere.coordinate.longitude)
        Task { @MainActor in
            self.echec = false
            self.position = c
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Position indisponible : la carte reste utilisable, le choix de zone à la main est proposé.
        Task { @MainActor in if self.position == nil { self.echec = true } }
    }
}
