import Foundation
import Network

/// Dit quand le réseau revient, pour rejouer la file d'envoi. Un événement à chaque changement d'état.
nonisolated enum SurveillanceReseau {
    static func flux() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let moniteur = NWPathMonitor()
            moniteur.pathUpdateHandler = { chemin in
                continuation.yield(chemin.status == .satisfied)
            }
            continuation.onTermination = { _ in moniteur.cancel() }
            moniteur.start(queue: DispatchQueue(label: "amis.reseau"))
        }
    }
}
