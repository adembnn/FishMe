import Core
import Foundation
import UserNotifications

/// Le rappel de la carte de pêche. Propre à ce dossier : `Notifieur` de `App/Conditions/` n'est pas réutilisé.
nonisolated protocol NotifieurCartePeche: Sendable {
    /// Demande la permission d'iOS. Appelée seulement au basculement de « Me prévenir 30 jours avant », jamais au lancement.
    func demanderPermission() async -> Bool
    /// Programme une notification non répétitive ce jour-là, à cette heure locale. Rend `false` si elle n'a pas pu l'être.
    func programmer(id: String, jour: JourCivil, heure: Int, titre: String, corps: String) async -> Bool
    func annuler(id: String) async
    /// Les identifiants des notifications de la carte encore en attente (pour les tests).
    func enAttente() async -> [String]
}

nonisolated struct NotifieurCartePecheSysteme: NotifieurCartePeche {
    static let prefixe = "cartepeche-"

    init() {}

    func demanderPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func programmer(id: String, jour: JourCivil, heure: Int, titre: String, corps: String) async -> Bool {
        let contenu = UNMutableNotificationContent()
        contenu.title = titre
        contenu.body = corps
        contenu.sound = .default
        // Composantes locales : 9 h sur l'iPhone du pêcheur, quel que soit le fuseau.
        var composantes = DateComponents()
        composantes.year = jour.annee
        composantes.month = jour.mois
        composantes.day = jour.jour
        composantes.hour = heure
        composantes.minute = 0
        let declencheur = UNCalendarNotificationTrigger(dateMatching: composantes, repeats: false)
        do {
            try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: contenu, trigger: declencheur))
            return true
        } catch {
            return false
        }
    }

    func annuler(id: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func enAttente() async -> [String] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.prefixe) }
    }
}
