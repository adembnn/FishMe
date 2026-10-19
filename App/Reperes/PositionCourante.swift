import CoreLocation
import Core
import Foundation

/// La position de l'iPhone, une seule fois, pour poser un repère « ici ». Rien n'est gardé ni écrit dans un journal.
/// Sans permission, ou sans réponse en 8 secondes : `nil`, et l'écran propose de choisir le point sur la carte.
/// ⚠ à vérifier sur un iPhone : `CLLocationUpdate.liveUpdates()` doit déclencher la demande si la permission n'est pas encore posée.
nonisolated enum PositionCourante {
    static func lire(delai: Duration = .seconds(8)) async -> Coordonnee? {
        await withTaskGroup(of: Coordonnee?.self) { groupe in
            groupe.addTask { await premierePosition() }
            groupe.addTask {
                try? await Task.sleep(for: delai)
                return nil
            }
            let premier = await groupe.next() ?? nil
            groupe.cancelAll()
            return premier
        }
    }

    private static func premierePosition() async -> Coordonnee? {
        do {
            for try await mise in CLLocationUpdate.liveUpdates() {
                if let lieu = mise.location {
                    return Coordonnee(latitude: lieu.coordinate.latitude, longitude: lieu.coordinate.longitude)
                }
                if mise.authorizationDenied || mise.authorizationDeniedGlobally || mise.authorizationRestricted { return nil }
            }
        } catch {
            return nil
        }
        return nil
    }
}
