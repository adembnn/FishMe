import CoreLocation
import Foundation
import Observation
import Core

/// La position de l'iPhone, « pendant l'usage » seulement. Refusée, l'app marche pareil (choix du département ou de la commune).
@Observable
final class GestionPosition: NSObject, CLLocationManagerDelegate {
    private(set) var statut: CLAuthorizationStatus
    private(set) var position: Coordonnee?

    @ObservationIgnored private let manager: CLLocationManager
    @ObservationIgnored private let reglages: UserDefaults
    /// Une seule redemande, au premier écran de carte (Adem, 15 oct.).
    @ObservationIgnored private static let cleRedemande = "carte.redemandeFaite"

    init(reglages: UserDefaults = .standard) {
        let manager = CLLocationManager()
        self.manager = manager
        self.reglages = reglages
        self.statut = manager.authorizationStatus
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

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let nouveau = manager.authorizationStatus
        Task { @MainActor in
            self.statut = nouveau
            if self.estAutorisee { self.manager.requestLocation() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let derniere = locations.last else { return }
        let c = Coordonnee(latitude: derniere.coordinate.latitude, longitude: derniere.coordinate.longitude)
        Task { @MainActor in self.position = c }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Position indisponible : la carte reste utilisable, le choix de zone à la main est proposé.
    }
}
