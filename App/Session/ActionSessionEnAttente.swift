import Foundation

/// Lit (puis efface) l'action demandée depuis la Live Activity (« prise » ou « pause »).
/// Même clé et même suite que `Widget/Session/IntentsSession.swift` (l'app n'importe pas `Widget/` : valeurs répétées).
enum ActionSessionEnAttente {
    private static let suite = "group.ai.mwm.build.challenge.team.01"
    private static let cle = "session.actionDemandee"
    private static var defaults: UserDefaults { UserDefaults(suiteName: suite) ?? .standard }

    /// « prise », « pause », ou nil. Ignore une demande vieille de plus de 10 minutes.
    static func lire() -> String? {
        guard let brut = defaults.string(forKey: cle) else { return nil }
        let morceaux = brut.split(separator: "|", maxSplits: 1).map(String.init)
        guard let action = morceaux.first, ["prise", "pause"].contains(action) else { return nil }
        if morceaux.count == 2, let t = Double(morceaux[1]),
           Date().timeIntervalSince1970 - t > 600 { return nil }
        return action
    }

    static func effacer() {
        defaults.removeObject(forKey: cle)
    }
}
