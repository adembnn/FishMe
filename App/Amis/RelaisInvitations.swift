import CloudKit
import Observation
import UIKit

/// Garde l'invitation reçue par lien, le temps que l'écran Amis la montre (« veut partager sa collection avec toi »).
@MainActor
@Observable
final class RelaisInvitations {
    static let partage = RelaisInvitations()

    /// A ouvre Mon club, puis Amis, quand ceci n'est pas `nil`.
    private(set) var enAttente: InvitationRecue?

    func recevoir(_ metadata: CKShare.Metadata) {
        // Décision 3 : jamais le nom du compte Apple, seulement le surnom porté par le titre du partage.
        let nom = NomAmi.affiche(titre: metadata.share[CKShare.SystemFieldKey.title] as? String)
        enAttente = InvitationRecue(nomAmi: nom, metadata: metadata)
    }

    func solder() {
        enAttente = nil
    }
}

/// Branché par A : `@UIApplicationDelegateAdaptor(AdaptateurPartage.self)` dans `BuildChallengeApp.swift`.
/// SwiftUI n'a pas de rappel pour l'acceptation d'un partage : il faut un délégué de scène UIKit.
final class AdaptateurPartage: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDuPartage.self
        return configuration
    }
}

final class SceneDuPartage: NSObject, UIWindowSceneDelegate {
    /// Lancement à froid par le lien.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let metadata = connectionOptions.cloudKitShareMetadata {
            RelaisInvitations.partage.recevoir(metadata)
        }
    }

    /// App déjà ouverte.
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        RelaisInvitations.partage.recevoir(cloudKitShareMetadata)
    }
}
