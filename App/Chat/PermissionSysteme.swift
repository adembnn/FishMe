import UserNotifications

/// La vraie permission, via `UNUserNotificationCenter`. Rien n'est demandé ici sans appel explicite de `GestionChat.envoyer`.
/// Enregistrer l'app aux notifications à distance (`registerForRemoteNotifications`) est à brancher par A au lancement : cela
/// n'affiche aucune fenêtre (voir le rapport L24).
nonisolated struct PermissionSysteme: PermissionNotifications {
    func statut() async -> StatutNotifications {
        let reglages = await UNUserNotificationCenter.current().notificationSettings()
        switch reglages.authorizationStatus {
        case .notDetermined: return .nonDemande
        case .denied: return .refuse
        default: return .accorde // .authorized, .provisional, .ephemeral
        }
    }

    func demander() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
}
