import AppIntents
import Foundation

// Fichier partagé par l'app et l'extension widget (dossier `Widget/` synchronisé dans les deux cibles).
// Les boutons de la Live Activity écrivent l'action demandée ; l'app la lit à l'activation (`ActionSessionEnAttente`).

nonisolated enum CleActionSession {
    static let suite = "group.ai.mwm.build.challenge.team.01"
    static let cle = "session.actionDemandee"

    static var defaults: UserDefaults { UserDefaults(suiteName: suite) ?? .standard }

    /// Format : « prise|<secondes depuis 1970> ».
    static func ecrire(_ action: String) {
        defaults.set("\(action)|\(Date().timeIntervalSince1970)", forKey: cle)
    }
}

struct PrendrePriseIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Prendre une prise"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        CleActionSession.ecrire("prise")
        return .result()
    }
}

struct PauseSessionIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Mettre la session en pause"
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        CleActionSession.ecrire("pause")
        return .result()
    }
}
