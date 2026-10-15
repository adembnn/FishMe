//
//  BuildChallengeApp.swift
//  BuildChallenge
//

import Spark
import SwiftUI

@main
struct BuildChallengeApp: App {

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
