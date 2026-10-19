import Foundation
import Observation

/// Le cerveau du chat : liste des conversations, conversation ouverte, envoi (filtre, file hors ligne, permission au premier
/// envoi), rafraîchissement, signaler, bloquer. Tout iCloud passe par `ServiceChat`, tout ce qui se garde par `StockChat`.
@MainActor
@Observable
final class GestionChat {
    /// Un seul avis à la fois, court. Jamais « lu » ni « en ligne » : CloudKit ne le sait pas.
    enum Avis: Equatable {
        case horsLigne
        case iCloudIndisponible
        case iCloudPlein
        case echec
        /// Affiché une seule fois, après le premier envoi : le chat marche sans notification.
        case notificationsRefusees
        /// Pas de profil (L21) : on lit, on n'écrit pas.
        case pasDeProfil
    }

    private(set) var resumes: [ResumeConversation] = []
    private(set) var ouverte: ConversationID?
    private(set) var titreOuverte = ""
    private(set) var messagesOuverts: [MessageChat] = []
    private(set) var ouverteFermee = false
    private(set) var avis: Avis?
    /// Ami : le lien de la conversation à lui envoyer, tant qu'il ne l'a pas acceptée.
    private(set) var lienAPartager: URL?
    /// Dernier refus du filtre de saisie (`nil` = rien à dire).
    private(set) var verdictSaisie: FiltreMessage.Verdict?
    private(set) var moi: InterlocuteurChat?

    let configuration: ConfigurationChat
    private let service: any ServiceChat
    private let annuaire: any AnnuaireChat
    private let stock: StockChat
    private let permission: any PermissionNotifications
    private var titres: [ConversationID: String] = [:]
    private var profils: [ConversationID: String] = [:]
    /// Qui peut créer la zone partagée : tout pêcheur pour un ami, le seul fondateur pour un club.
    private var peutCreer: [ConversationID: Bool] = [:]
    /// Les comptes à admettre dans la zone (l'ami ; les membres du club, si je suis le fondateur).
    private var aAdmettre: [ConversationID: [String]] = [:]
    private var envoiEnCours = false
    private var verifierLien = true

    init(service: any ServiceChat, annuaire: any AnnuaireChat, stock: StockChat, permission: any PermissionNotifications,
         configuration: ConfigurationChat = ConfigurationChat()) {
        self.service = service
        self.annuaire = annuaire
        self.stock = stock
        self.permission = permission
        self.configuration = configuration
    }

    /// Le point rouge de l'onglet : le nombre de conversations avec un message pas encore vu.
    var nonLus: Int { resumes.filter { $0.nonLu && !$0.ferme }.count }

    // MARK: Liste des conversations

    /// Relit l'annuaire et le cache : instantané, hors ligne.
    func chargerListe() async {
        moi = await annuaire.moi()
        let amis = await annuaire.amis()
        let clubs = await annuaire.clubs()
        let bloques = await stock.bloques().union(await annuaire.bloques())
        var lignes: [ResumeConversation] = []
        for ami in amis {
            let conversation = ConversationID.ami(ami.idCloudKit)
            titres[conversation] = ami.surnom
            profils[conversation] = ami.id
            peutCreer[conversation] = true
            aAdmettre[conversation] = [ami.idCloudKit]
            let ferme = bloques.contains(conversation.id) || bloques.contains(ami.id)
            lignes.append(await resume(conversation, titre: ami.surnom, ferme: ferme, bloques: bloques))
        }
        for club in clubs {
            let conversation = ConversationID.club(club.id)
            titres[conversation] = club.nom
            peutCreer[conversation] = club.jeSuisFondateur
            aAdmettre[conversation] = club.jeSuisFondateur ? club.membres.map(\.idCloudKit) : []
            lignes.append(await resume(conversation, titre: club.nom, ferme: false, bloques: bloques))
        }
        resumes = lignes.sorted {
            ($0.dernier?.date ?? .distantPast) > ($1.dernier?.date ?? .distantPast)
        }
    }

    /// Tirer pour rafraîchir la liste : relit le réseau pour chaque conversation ouverte au chat, puis recharge.
    func actualiserListe() async {
        await chargerListe()
        guard await service.iCloudDisponible() else {
            avis = .iCloudIndisponible
            return
        }
        await rejouerFile()
        for ligne in resumes where !ligne.ferme {
            await tirer(ligne.conversation)
        }
        await chargerListe()
    }

    private func resume(_ conversation: ConversationID, titre: String, ferme: Bool, bloques: Set<String>) async -> ResumeConversation {
        let visibles = await visibles(await stock.messages(de: conversation), bloques: bloques)
        let dernier = visibles.last
        var nonLu = false
        if let dernier, dernier.auteurId != moi?.id {
            nonLu = dernier.date > (await stock.vu(conversation) ?? .distantPast)
        }
        return ResumeConversation(conversation: conversation, titre: titre, dernier: dernier, nonLu: nonLu, ferme: ferme)
    }

    private func visibles(_ messages: [MessageChat], bloques: Set<String>) async -> [MessageChat] {
        let masques = await stock.masques()
        return messages.filter { !masques.contains($0.id) && !bloques.contains($0.auteurId) }
    }

    // MARK: Conversation ouverte

    func ouvrir(_ conversation: ConversationID) async {
        if titres[conversation] == nil { await chargerListe() }
        ouverte = conversation
        titreOuverte = titres[conversation] ?? ""
        avis = nil
        verdictSaisie = nil
        lienAPartager = nil
        verifierLien = true
        await rafraichirAffichage()
        await actualiser()
        if await permission.statut() == .accorde { try? await service.abonner(conversation) }
    }

    func fermer() {
        ouverte = nil
        messagesOuverts = []
        lienAPartager = nil
        verdictSaisie = nil
    }

    /// Tirer pour rafraîchir, la boucle de 10 s, le retour du réseau, la notification : tout passe ici.
    func actualiser() async {
        guard let conversation = ouverte else { return }
        guard await service.iCloudDisponible() else {
            avis = .iCloudIndisponible
            await rafraichirAffichage()
            return
        }
        if avis == .iCloudIndisponible || avis == .horsLigne { avis = nil }
        await rejouerFile()
        await tirer(conversation)
        if verifierLien || lienAPartager != nil {
            lienAPartager = await lien(pour: conversation)
            verifierLien = false
        }
        await rafraichirAffichage()
    }

    /// Rafraîchissement toutes les 10 s tant que l'écran est ouvert, EN PLUS de la notification (qui n'est jamais garantie).
    /// À lancer dans un `.task` de la vue : SwiftUI l'annule quand la vue disparaît.
    func surveillerOuverte() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: configuration.periode)
            if Task.isCancelled { break }
            await actualiser()
        }
    }

    /// Rejoue la file d'envoi au retour du réseau. À lancer dans un `.task` de la liste.
    func surveillerReseau() async {
        for await connecte in ReseauChat.flux() where connecte {
            await rejouerFile()
            if ouverte != nil { await actualiser() }
        }
    }

    /// A l'appelle quand CloudKit signale un nouveau message (notification silencieuse reçue).
    func traiterNotificationCloudKit() async {
        await actualiserListe()
        if ouverte != nil { await actualiser() }
    }

    private func lien(pour conversation: ConversationID) async -> URL? {
        try? await service.lienDInvitation(pour: conversation, participants: aAdmettre[conversation] ?? [])
    }

    private func tirer(_ conversation: ConversationID) async {
        do {
            let recus = try await service.messages(de: conversation)
            await stock.fusionner(recus, dans: conversation)
        } catch {
            signalerErreur(error)
        }
    }

    private func rafraichirAffichage() async {
        guard let conversation = ouverte else { return }
        let bloques = await stock.bloques().union(await annuaire.bloques())
        ouverteFermee = bloques.contains(conversation.id) || (profils[conversation].map(bloques.contains) ?? false)
        messagesOuverts = ouverteFermee ? [] : await visibles(await stock.messages(de: conversation), bloques: bloques)
        if let dernierAutre = messagesOuverts.last(where: { $0.auteurId != moi?.id }) {
            await stock.marquerVu(conversation, jusqua: dernierAutre.date)
        }
    }

    // MARK: Envoyer

    /// Rend `true` si le message est parti dans la file (le champ de saisie peut se vider).
    /// Ordre voulu : filtre → file locale (visible tout de suite) → permission de notifier (au PREMIER envoi seulement) → réseau.
    @discardableResult
    func envoyer(_ texte: String) async -> Bool {
        guard let conversation = ouverte, !ouverteFermee else { return false }
        guard let moi else {
            avis = .pasDeProfil
            return false
        }
        switch FiltreMessage.verifier(texte) {
        case .vide:
            verdictSaisie = nil
            return false
        case .accepte(let propre):
            verdictSaisie = nil
            let message = MessageChat(id: UUID(), conversation: conversation, auteurId: moi.id, surnom: moi.surnom,
                                      texte: propre, date: Date())
            await stock.mettreEnAttente(message)
            await rafraichirAffichage()
            await demanderLaPermissionAuPremierEnvoi()
            verifierLien = true
            await rejouerFile()
            if await permission.statut() == .accorde { try? await service.abonner(conversation) }
            lienAPartager = await lien(pour: conversation)
            verifierLien = false
            await rafraichirAffichage()
            return true
        case let refus:
            verdictSaisie = refus
            return false
        }
    }

    func renvoyer() async {
        await rejouerFile()
        await rafraichirAffichage()
    }

    private func demanderLaPermissionAuPremierEnvoi() async {
        switch await permission.statut() {
        case .nonDemande:
            if await permission.demander() == false { await prevenirDuRefus() }
        case .refuse:
            await prevenirDuRefus()
        case .accorde:
            break
        }
    }

    private func prevenirDuRefus() async {
        guard await !stock.refusNotificationsAffiche else { return }
        avis = .notificationsRefusees
        await stock.avertissementRefusAffiche()
    }

    private func rejouerFile() async {
        guard !envoiEnCours else { return }
        envoiEnCours = true
        defer { envoiEnCours = false }
        let file = await stock.enAttente()
        guard !file.isEmpty else { return }
        let bloques = await stock.bloques()
        for message in file {
            if bloques.contains(message.conversation.id) {
                await stock.marquerPasParti(message.id)
                continue
            }
            do {
                try await service.envoyer(message, peutCreerLaZone: peutCreer[message.conversation] ?? false)
                await stock.marquerEnvoye(message.id)
            } catch {
                // On garde l'ordre d'écriture : les suivants attendent derrière celui-ci.
                await stock.marquerPasParti(message.id)
                signalerErreur(error)
                break
            }
        }
    }

    private func signalerErreur(_ erreur: Error) {
        switch ServiceChatCloudKit.traduire(erreur) {
        case .reseau: avis = .horsLigne
        case .iCloudIndisponible: avis = .iCloudIndisponible
        case .iCloudPlein: avis = .iCloudPlein
        case .introuvable: break // l'ami n'a pas encore accepté la conversation : le lien à lui envoyer le dit
        case .autre: avis = .echec
        }
    }

    func effacerAvis() {
        avis = nil
    }

    // MARK: Modération (décision 5, règle 1.2)

    /// « Signaler » : le message disparaît tout de suite de cet iPhone, et l'e-mail prérempli est rendu (à ouvrir par la vue).
    func signaler(_ message: MessageChat, motif: MotifSignalement) async -> URL? {
        await stock.masquer(message.id)
        await rafraichirAffichage()
        await chargerListe()
        return SignalementMessage.url(contact: configuration.contact, message: message, motif: motif)
    }

    /// « Bloquer » : en club, les messages de l'auteur sont masqués ; entre amis, la conversation se ferme.
    func bloquer(_ message: MessageChat) async {
        switch message.conversation.type {
        case .club: await stock.bloquer(message.auteurId)
        case .ami: await stock.bloquer(message.conversation.id)
        }
        await rafraichirAffichage()
        await chargerListe()
    }

    func debloquer(_ conversation: ConversationID) async {
        await stock.debloquer(conversation.id)
        if let profil = profils[conversation] { await stock.debloquer(profil) }
        await rafraichirAffichage()
        await chargerListe()
    }

    // MARK: Invitation de conversation reçue par lien

    /// A appelle ceci quand `InvitationChat.estUneConversation` est vrai (voir le rapport L24).
    func accepter(_ invitation: InvitationChat) async {
        do {
            try await service.accepterInvitation(invitation)
            await actualiserListe()
        } catch {
            signalerErreur(error)
        }
    }

    // MARK: Effacement (L21 « Supprimer mon profil »)

    func effacerMesMessages() async throws {
        guard let identite = await annuaire.moi() else { return }
        try await service.effacerMesMessages(auteurId: identite.id)
        await stock.effacerMesMessages(auteurId: identite.id)
        await chargerListe()
    }
}

/// L'adaptateur que A compose dans l'`EffaceurContenu` de L21.
nonisolated struct EffaceurChat: EffaceurMessages {
    let gestion: GestionChat

    func effacerMesMessages() async throws {
        try await gestion.effacerMesMessages()
    }
}
