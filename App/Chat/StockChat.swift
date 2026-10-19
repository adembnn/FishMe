import Foundation

/// Tout ce que le chat garde sur l'iPhone : les conversations lues (lisibles hors ligne), la file d'envoi (un message écrit hors
/// ligne part au retour du réseau), les masques et blocages locaux, les marques « vu ». Un seul fichier JSON, écrit en entier
/// (même principe que `FileEnvoi` du lot Amis). Aucune coordonnée n'y entre : le filtre de saisie l'a refusée avant.
actor StockChat {
    nonisolated struct Etat: Codable, Equatable, Sendable {
        /// Clé = `ConversationID.id`. Les 200 derniers messages de chaque conversation.
        var messages: [String: [MessageChat]] = [:]
        /// Messages écrits et pas encore partis, dans l'ordre d'écriture.
        var enAttente: [MessageChat] = []
        /// Identifiants d'auteurs bloqués (clubs) et clés de conversations d'amis fermées (`ConversationID.id`).
        var bloques: Set<String> = []
        /// Messages signalés : masqués pour moi.
        var masques: Set<UUID> = []
        /// Date du dernier message de l'autre vu à l'ouverture, par conversation.
        var vus: [String: Date] = [:]
        /// L'avis « les notifications sont refusées » ne s'affiche qu'une fois.
        var refusNotificationsAffiche = false
    }

    static let messagesGardes = 200

    private let fichier: URL
    private var etat: Etat

    init(dossier: URL) {
        try? FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        self.fichier = dossier.appendingPathComponent("chat.json")
        let donnees = try? Data(contentsOf: fichier)
        self.etat = donnees.flatMap { try? JSONDecoder().decode(Etat.self, from: $0) } ?? Etat()
    }

    static func dossierParDefaut() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Chat", isDirectory: true)
    }

    // MARK: Lecture

    func messages(de conversation: ConversationID) -> [MessageChat] {
        etat.messages[conversation.id] ?? []
    }

    func enAttente() -> [MessageChat] { etat.enAttente }
    func bloques() -> Set<String> { etat.bloques }
    func masques() -> Set<UUID> { etat.masques }
    func vu(_ conversation: ConversationID) -> Date? { etat.vus[conversation.id] }
    var refusNotificationsAffiche: Bool { etat.refusNotificationsAffiche }

    // MARK: Messages lus

    /// Remplace les messages partis de la conversation par ceux du réseau, et garde ceux qui attendent encore leur départ.
    func fusionner(_ recus: [MessageChat], dans conversation: ConversationID) {
        var parId: [UUID: MessageChat] = [:]
        for message in etat.messages[conversation.id] ?? [] { parId[message.id] = message }
        for message in recus { parId[message.id] = message }
        let tries = parId.values.sorted { $0.date < $1.date }
        etat.messages[conversation.id] = Array(tries.suffix(Self.messagesGardes))
        sauvegarder()
    }

    func marquerVu(_ conversation: ConversationID, jusqua date: Date) {
        etat.vus[conversation.id] = date
        sauvegarder()
    }

    // MARK: File d'envoi

    /// Écrit le message dans la file ET dans la conversation locale, état « en attente ».
    func mettreEnAttente(_ message: MessageChat) {
        var m = message
        m.etat = .enAttente
        etat.enAttente.removeAll { $0.id == m.id }
        etat.enAttente.append(m)
        remplacer(m)
        sauvegarder()
    }

    func marquerPasParti(_ id: UUID) {
        guard let index = etat.enAttente.firstIndex(where: { $0.id == id }) else { return }
        etat.enAttente[index].etat = .pasParti
        remplacer(etat.enAttente[index])
        sauvegarder()
    }

    func marquerEnvoye(_ id: UUID) {
        guard let message = etat.enAttente.first(where: { $0.id == id }) else { return }
        var envoye = message
        envoye.etat = .envoye
        etat.enAttente.removeAll { $0.id == id }
        remplacer(envoye)
        sauvegarder()
    }

    private func remplacer(_ message: MessageChat) {
        var liste = etat.messages[message.conversation.id] ?? []
        if let index = liste.firstIndex(where: { $0.id == message.id }) {
            liste[index] = message
        } else {
            liste.append(message)
        }
        etat.messages[message.conversation.id] = Array(liste.sorted { $0.date < $1.date }.suffix(Self.messagesGardes))
    }

    // MARK: Modération locale

    func masquer(_ id: UUID) {
        etat.masques.insert(id)
        sauvegarder()
    }

    func bloquer(_ cle: String) {
        etat.bloques.insert(cle)
        sauvegarder()
    }

    func debloquer(_ cle: String) {
        etat.bloques.remove(cle)
        sauvegarder()
    }

    func avertissementRefusAffiche() {
        etat.refusNotificationsAffiche = true
        sauvegarder()
    }

    /// « Supprimer mon profil » : plus rien de moi sur l'iPhone. Les blocages restent (ils protègent la personne, pas le profil).
    func effacerMesMessages(auteurId: String) {
        for (cle, liste) in etat.messages {
            etat.messages[cle] = liste.filter { $0.auteurId != auteurId }
        }
        etat.enAttente.removeAll { $0.auteurId == auteurId }
        sauvegarder()
    }

    private func sauvegarder() {
        guard let donnees = try? JSONEncoder().encode(etat) else { return }
        try? donnees.write(to: fichier, options: [.atomic, .completeFileProtection])
    }
}
