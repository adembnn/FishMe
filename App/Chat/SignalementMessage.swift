import Foundation

/// Les motifs de signalement : UNE SEULE énumération, celle de L21 (`App/Profil/MotifSignalement.swift`).
typealias MotifSignalementMessage = MotifSignalement

/// Règle 1.2 d'Apple : signaler un message, vers le contact publié dans Mon club (fishme.app@gmail.com).
/// Un e-mail prérempli que le pêcheur envoie lui-même (CloudKit n'envoie aucun e-mail sans serveur : R2 `moderation.md`). La trace
/// fiable est l'enregistrement `Signalement` (voir `GestionChat.signaler`) ; l'e-mail n'est ouvert que si Mail est disponible.
/// Le message disparaît tout de suite de son écran, qu'il envoie l'e-mail ou non.
nonisolated enum SignalementMessage {
    /// Adresse publiée. `ConfigurationChat` la reçoit de A ; celle-ci est la valeur par défaut des décisions du 19 oct.
    static let contactParDefaut = "fishme.app@gmail.com"

    /// Identifiant du message (`recordName`, introuvable sinon dans le tableau de bord), de son auteur et de sa conversation, plus
    /// le TEXTE du message, ami ou club : les conversations sont en zone partagée, l'équipe ne peut pas les lire autrement
    /// (décision de Titouan, 19 oct.). Le pêcheur voit et peut modifier l'e-mail avant de l'envoyer. Le même texte est copié dans
    /// l'enregistrement `Signalement`. À DIRE dans la politique de confidentialité et les CGU (art. 8).
    /// Jamais de coordonnée : le filtre de saisie les a refusées.
    static func url(contact: String, message: MessageChat, motif: MotifSignalementMessage) -> URL? {
        var composants = URLComponents()
        composants.scheme = "mailto"
        composants.path = contact
        let texte = String(message.texte.prefix(FabriqueRecordsChat.texteSignalementMax))
        let corps = "Message : \(message.id.uuidString)\nAuteur : \(message.auteurId)\nConversation : \(message.conversation.id)\nMotif : \(motif.rawValue)\nTexte : \(texte)"
        composants.queryItems = [
            URLQueryItem(name: "subject", value: "Signalement d'un message"),
            URLQueryItem(name: "body", value: corps),
        ]
        return composants.url
    }
}

/// Réglages donnés par A dans RootView.swift.
nonisolated struct ConfigurationChat: Sendable {
    var contact: String = SignalementMessage.contactParDefaut
    /// Rafraîchissement de la conversation ouverte, en plus de la notification (fiche L24 : 10 s).
    var periode: Duration = .seconds(10)
}
