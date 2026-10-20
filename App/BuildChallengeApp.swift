//
//  BuildChallengeApp.swift
//  BuildChallenge
//

import Spark
import SwiftUI
import UIKit

/// Le délégué d'application (L8 + L24) : les invitations CloudKit passent par la scène de `AdaptateurPartage` (App/Amis/),
/// les notifications CloudKit silencieuses du chat arrivent ici. // ⚠ à vérifier (écrit sans Mac)
final class AdaptateurFishMe: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // N'affiche aucune fenêtre : la permission de notifier n'est demandée qu'au premier message envoyé (`GestionChat.envoyer`, L24).
        // Sans permission, la notification silencieuse arrive quand même et rafraîchit le chat à l'ouverture de l'app.
        application.registerForRemoteNotifications()
        return true
    }

    /// Même scène que `AdaptateurPartage` (L8) : l'acceptation d'un partage CloudKit n'a pas de rappel en SwiftUI.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDuPartage.self
        return configuration
    }

    /// Un message CloudKit silencieux (abonnement de zone de L24) : le chat se rafraîchit.
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard let recevoir = RelaisNotificationsChat.partage.recevoir else { return .noData }
        await recevoir()
        return .newData
    }
}

/// Le pont entre le délégué d'application et `ParcoursApp` (créé après le délégué). `RootView` y pose sa fermeture au démarrage.
@MainActor
final class RelaisNotificationsChat {
    static let partage = RelaisNotificationsChat()
    var recevoir: (@MainActor () async -> Void)?
}

@main
struct BuildChallengeApp: App {
    /// L8 : reçoit les invitations CloudKit (partage d'une carte entre amis). L24 : reçoit les notifications silencieuses du chat.
    @UIApplicationDelegateAdaptor(AdaptateurFishMe.self) var adaptateur

    /// L'unique appel à `Spark.configure` du projet. `RootView` le passe à `PasserelleSpark` ; `CoucheMesure` ne l'appelle
    /// qu'après l'accord du pêcheur (docs/lots.md, L6 : aucun événement avant le consentement).
    @MainActor
    static func configurerSpark() {
#if DEBUG
        let sparkApiKey = "pk_sbox_ee38865ee4418ead61c9a667377e2417"
#else
        let sparkApiKey = "pk_prod_67791fa3f5c26aa8cf4d7562624455fa"
#endif
        let configuration = Spark.Configuration.builder(apiKey: sparkApiKey).build()

        Spark.configure(configuration)
    }

    var body: some Scene {
        WindowGroup {
            RootView(configurerMesure: Self.configurerSpark)
        }
    }
}
