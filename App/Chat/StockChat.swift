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
        /// Signalements pas encore écrits dans la base de la personne de garde.
        var signalements: [SignalementEnAttente] = []
    }

    static let messagesGardes = 200

    private let fichier: URL
    private var etat: Etat
    /// Vrai tant que `chat.json` existe mais n'a pas pu être LU (iPhone verrouillé, protection des données, disque) : on n'écrit
    /// alors rien par-dessus, sinon la file d'envoi, les blocages et les signalements seraient perdus. Les changements restent
    /// en mémoire ; dès que le fichier se lit, ils sont fusionnés avec lui, puis écrits.
    private var lectureEnEchec = false

    init(dossier: URL) {
        try? FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        self.fichier = dossier.appendingPathComponent("chat.json")
        self.etat = Etat()
        switch Self.lire(fichier) {
        case .absent: break
        case .lu(let lu): self.etat = lu
        case .illisible: self.lectureEnEchec = true
        case .abime:
            // Lisible mais pas décodable : on le met de côté (jamais écrasé) et on repart d'un état vide.
            let copie = dossier.appendingPathComponent("chat.corrompu.json")
            try? FileManager.default.removeItem(at: copie)
            try? FileManager.default.moveItem(at: fichier, to: copie)
        }
    }

    private enum Lecture {
        case absent
        case lu(Etat)
        /// Le fichier existe, mais le système refuse de le lire (verrouillé) : à réessayer plus tard.
        case illisible
        case abime
    }

    private static func lire(_ fichier: URL) -> Lecture {
        guard FileManager.default.fileExists(atPath: fichier.path) else { return .absent }
        guard let donnees = try? Data(contentsOf: fichier) else { return .illisible }
        guard let etat = try? JSONDecoder().decode(Etat.self, from: donnees) else { return .abime }
        return .lu(etat)
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
    /// Pour ne signaler comme « nouveau » que ce que l'iPhone n'avait jamais vu.
    func identifiantsConnus(de conversation: ConversationID) -> Set<UUID> { Set((etat.messages[conversation.id] ?? []).map(\.id)) }
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

    func signalementsEnAttente() -> [SignalementEnAttente] { etat.signalements }

    func ajouter(_ signalement: SignalementEnAttente) {
        etat.signalements.append(signalement)
        sauvegarder()
    }

    func signalementParti(_ id: UUID) {
        etat.signalements.removeAll { $0.id == id }
        sauvegarder()
    }

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
        if lectureEnEchec {
            switch Self.lire(fichier) {
            case .lu(let disque):
                etat = Self.fusionner(disque: disque, memoire: etat)
                lectureEnEchec = false
            case .illisible:
                return // toujours verrouillé : rien n'est écrit, tout reste en mémoire
            case .absent, .abime:
                lectureEnEchec = false
            }
        }
        guard let donnees = try? JSONEncoder().encode(etat) else { return }
        // `.completeUntilFirstUserAuthentication` : une notification silencieuse réveille l'app iPhone verrouillé, après le premier
        // déverrouillage suivant le démarrage le fichier reste lisible (`.completeFileProtection` le rendait illisible verrouillé).
        try? donnees.write(to: fichier, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    /// Réunit l'état du disque et celui construit en mémoire pendant que le disque était illisible. Rien n'est perdu.
    nonisolated static func fusionner(disque: Etat, memoire: Etat) -> Etat {
        var sortie = disque
        for (cle, liste) in memoire.messages {
            var parId: [UUID: MessageChat] = [:]
            for m in sortie.messages[cle] ?? [] { parId[m.id] = m }
            for m in liste { parId[m.id] = m }
            sortie.messages[cle] = Array(parId.values.sorted { $0.date < $1.date }.suffix(messagesGardes))
        }
        for m in memoire.enAttente where !sortie.enAttente.contains(where: { $0.id == m.id }) { sortie.enAttente.append(m) }
        sortie.bloques.formUnion(memoire.bloques)
        sortie.masques.formUnion(memoire.masques)
        for (cle, date) in memoire.vus where date > (sortie.vus[cle] ?? .distantPast) { sortie.vus[cle] = date }
        sortie.refusNotificationsAffiche = sortie.refusNotificationsAffiche || memoire.refusNotificationsAffiche
        for s in memoire.signalements where !sortie.signalements.contains(where: { $0.id == s.id }) { sortie.signalements.append(s) }
        return sortie
    }
}
