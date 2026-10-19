import Foundation
import Network

/// Dit quand le réseau revient, pour rejouer la file d'envoi (même principe que `SurveillanceReseau` du lot Amis, recopié :
/// un dossier de l'app n'importe pas un autre). Un événement à chaque changement d'état.
nonisolated enum ReseauChat {
    static func flux() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let moniteur = NWPathMonitor()
            moniteur.pathUpdateHandler = { chemin in
                continuation.yield(chemin.status == .satisfied)
            }
            continuation.onTermination = { _ in moniteur.cancel() }
            moniteur.start(queue: DispatchQueue(label: "chat.reseau"))
        }
    }
}
