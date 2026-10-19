import Foundation

/// Les motifs de signalement, liste fermée (R2 `moderation.md`) : pas de texte libre.
nonisolated enum MotifSignalementMessage: String, CaseIterable, Identifiable, Sendable {
    case choquant = "Contenu choquant ou violent"
    case harcelement = "Haine ou harcèlement"
    case sexuel = "Nudité ou contenu sexuel"
    case cruaute = "Cruauté envers un animal"
    case peche = "Pêche illégale"
    case coin = "Coin de pêche exact révélé"
    case mineur = "Personne mineure"
    case spam = "Spam ou publicité"
    case autre = "Autre"

    var id: String { rawValue }

    /// Icône SF Symbols de la ligne du menu.
    var symbole: String {
        switch self {
        case .choquant: return "exclamationmark.triangle"
        case .harcelement: return "hand.raised"
        case .sexuel: return "eye.slash"
        case .cruaute: return "pawprint"
        case .peche: return "fish"
        case .coin: return "mappin.slash"
        case .mineur: return "person.crop.circle.badge.exclamationmark"
        case .spam: return "megaphone"
        case .autre: return "ellipsis.circle"
        }
    }
}

/// Règle 1.2 d'Apple : signaler un message, vers le contact publié dans Mon club (fishme.app@gmail.com).
/// Un e-mail prérempli que le pêcheur envoie lui-même (CloudKit n'envoie aucun e-mail sans serveur : R2 `moderation.md`).
/// Le message disparaît tout de suite de son écran, qu'il envoie l'e-mail ou non.
nonisolated enum SignalementMessage {
    /// Adresse publiée. `ConfigurationChat` la reçoit de A ; celle-ci est la valeur par défaut des décisions du 19 oct.
    static let contactParDefaut = "fishme.app@gmail.com"

    /// Identifiant du message (`recordName`, introuvable sinon dans le tableau de bord), de son auteur et de sa conversation.
    /// Le texte n'est joint que pour un message d'ami : il vit dans une zone privée que l'équipe ne peut pas lire.
    /// Jamais de coordonnée : le filtre de saisie les a refusées.
    static func url(contact: String, message: MessageChat, motif: MotifSignalementMessage) -> URL? {
        var composants = URLComponents()
        composants.scheme = "mailto"
        composants.path = contact
        var corps = "Message : \(message.id.uuidString)\nAuteur : \(message.auteurId)\nConversation : \(message.conversation.id)\nMotif : \(motif.rawValue)"
        if message.conversation.type == .ami { corps += "\nTexte : \(message.texte)" }
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
