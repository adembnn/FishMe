import Foundation
import Observation

/// Ce que `signaler` rend à l'écran : l'e-mail prérempli (à n'ouvrir que si Mail est disponible) et la vérité sur la trace.
nonisolated struct ResultatSignalementMessage: Equatable, Sendable {
    /// Le `mailto:` prérempli, texte du message compris (le pêcheur le voit et peut le modifier avant d'envoyer).
    var url: URL?
    /// Vrai seulement si l'enregistrement `Signalement` est bien arrivé sur iCloud. Faux : gardé sur l'iPhone, il repart au retour du réseau.
    var enregistre: Bool
}

/// Le cerveau du chat : liste des conversations, conversation ouverte, envoi (filtre, file hors ligne, permission au premier
/// envoi), rafraîchissement, signaler, bloquer. Tout iCloud passe par `ServiceChat`, tout ce qui se garde par `StockChat`.
@MainActor
@Observable
final class GestionChat {
    /// Un seul avis à la fois, court. Ni accusé de lecture ni « en ligne » : CloudKit ne le sait pas.
    enum Avis: Equatable {
        case horsLigne
        case iCloudIndisponible
        case iCloudPlein
        case echec
        /// Affiché une seule fois, après le premier envoi : le chat marche sans notification.
        case notificationsRefusees
        /// Pas de profil (L21) : on lit, on n'écrit pas.
        case pasDeProfil
        /// Entre amis, l'autre pêcheur crée la conversation : mon message attend que son lien soit accepté.
        case enAttenteDeLInvitation
        /// Dit seulement quand l'enregistrement `Signalement` a réussi.
        case signalementEnregistre
        /// Message masqué ici, mais l'enregistrement n'est pas encore parti : il repartira tout seul.
        case signalementEnAttente
        /// Mode démo : conversations d'exemple, lecture seule.
        case exemple
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
    /// Vrai pour le mode démo : conversations d'exemple, rien n'est écrit.
    let exemple: Bool

    let configuration: ConfigurationChat
    private let service: any ServiceChat
    private let annuaire: any AnnuaireChat
    private let stock: StockChat
    private let permission: any PermissionNotifications
    private var titres: [ConversationID: String] = [:]
    private var profils: [ConversationID: String] = [:]
    /// Qui peut créer la zone partagée : pour un ami, celui dont l'identifiant de profil est le plus petit (un seul créateur par
    /// paire) ; pour un club, le seul fondateur. Faux pour qui n'a pas de profil ou a moins de 15 ans.
    private var peutCreer: [ConversationID: Bool] = [:]
    /// Les comptes à admettre dans la zone (l'ami ; les membres du club, si je suis le fondateur).
    private var aAdmettre: [ConversationID: [String]] = [:]
    /// Qui est qui dans chaque conversation, par identifiant de compte iCloud : sert à déduire l'auteur d'un message (jamais cru
    /// sur parole).
    private var auteurs: [ConversationID: [String: InterlocuteurChat]] = [:]
    private var abonnees: Set<ConversationID> = []
    private var listeChargee = false
    private var envoiEnCours = false
    private var verifierLien = true
    /// Faux quand l'app n'est pas au premier plan : plus de rafraîchissement de 10 s, et une alerte locale remplace l'affichage.
    private var actif = true
    private var tics = 0
    private var nouveauxEntrants = 0

    init(service: any ServiceChat, annuaire: any AnnuaireChat, stock: StockChat, permission: any PermissionNotifications,
         configuration: ConfigurationChat = ConfigurationChat(), exemple: Bool = false) {
        self.service = service
        self.annuaire = annuaire
        self.stock = stock
        self.permission = permission
        self.configuration = configuration
        self.exemple = exemple
    }

    /// Le point rouge de l'onglet : le nombre de conversations avec un message pas encore vu.
    var nonLus: Int { resumes.filter { $0.nonLu && !$0.ferme }.count }

    /// Un seul créateur par paire : le pêcheur dont l'identifiant de profil (`p-…`) est le plus petit dans l'ordre alphabétique crée
    /// la zone et la partage ; l'autre attend l'invitation. Sans profil de plus de 15 ans, personne ne crée de mon côté.
    nonisolated static func jeCree(moi: InterlocuteurChat?, ami: InterlocuteurChat) -> Bool {
        guard let moi, moi.a15Ans else { return false }
        return moi.id < ami.id
    }

    /// L'app passe au premier plan ou en arrière-plan (la vue lit `scenePhase`).
    func definirActif(_ valeur: Bool) {
        actif = valeur
    }

    // MARK: Liste des conversations

    /// Relit l'annuaire et le cache : instantané, hors ligne.
    func chargerListe() async {
        moi = await annuaire.moi()
        let amis = await annuaire.amis()
        let clubs = await annuaire.clubs()
        let bloques = await stock.bloques().union(await annuaire.bloques())
        let marque = exemple ? "Exemple · " : ""
        let jePeuxEcrire = moi?.a15Ans == true
        var lignes: [ResumeConversation] = []
        for ami in amis {
            let conversation = ConversationID.ami(ami.idCloudKit)
            let titre = marque + ami.surnom
            titres[conversation] = titre
            profils[conversation] = ami.id
            peutCreer[conversation] = Self.jeCree(moi: moi, ami: ami)
            aAdmettre[conversation] = [ami.idCloudKit]
            auteurs[conversation] = [ami.idCloudKit: ami]
            let ferme = bloques.contains(conversation.id) || bloques.contains(ami.id)
            lignes.append(await resume(conversation, titre: titre, ferme: ferme, bloques: bloques))
        }
        for club in clubs {
            let conversation = ConversationID.club(club.id)
            let titre = marque + club.nom
            titres[conversation] = titre
            peutCreer[conversation] = club.jeSuisFondateur && jePeuxEcrire
            aAdmettre[conversation] = club.jeSuisFondateur ? club.membres.map(\.idCloudKit) : []
            auteurs[conversation] = Dictionary(club.membres.map { ($0.idCloudKit, $0) }, uniquingKeysWith: { premier, _ in premier })
            lignes.append(await resume(conversation, titre: titre, ferme: false, bloques: bloques))
        }
        resumes = lignes.sorted {
            ($0.dernier?.date ?? .distantPast) > ($1.dernier?.date ?? .distantPast)
        }
        listeChargee = true
    }

    /// Tirer pour rafraîchir la liste : relit le réseau pour chaque conversation ouverte au chat, puis recharge.
    func actualiserListe() async {
        await chargerListe()
        guard await service.iCloudDisponible() else {
            avis = exemple ? .exemple : .iCloudIndisponible
            return
        }
        await rejouerFile()
        for ligne in resumes where !ligne.ferme {
            await tirer(ligne.conversation)
        }
        await chargerListe()
        await abonnerToutes()
    }

    private func resume(_ conversation: ConversationID, titre: String, ferme: Bool, bloques: Set<String>) async -> ResumeConversation {
        let gardes = await visibles(await stock.messages(de: conversation), bloques: bloques)
        let dernier = gardes.last
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
        avis = exemple ? .exemple : nil
        verdictSaisie = nil
        lienAPartager = nil
        verifierLien = true
        tics = 0
        await rafraichirAffichage()
        await actualiser()
        await abonnerToutes()
    }

    func fermer() {
        ouverte = nil
        messagesOuverts = []
        lienAPartager = nil
        verdictSaisie = nil
    }

    /// Tirer pour rafraîchir, le retour du réseau, la notification, le retour au premier plan : relecture complète.
    func actualiser() async {
        guard let conversation = ouverte else { return }
        guard await service.iCloudDisponible() else {
            avis = exemple ? .exemple : .iCloudIndisponible
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

    /// Rafraîchissement toutes les 10 s EN PLUS de la notification (qui n'est jamais garantie), mais seulement quand l'app est au
    /// premier plan ET qu'une conversation est ouverte, et sans relire toute la zone : jeton de changement CloudKit, pas de
    /// `accountStatus`, relecture du lien toutes les minutes au plus. À lancer dans un `.task` de la vue (annulé à sa disparition).
    func surveillerOuverte() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: configuration.periode)
            if Task.isCancelled { break }
            await rafraichirPeriodique()
        }
    }

    func rafraichirPeriodique() async {
        guard actif, let conversation = ouverte, !exemple else { return }
        tics += 1
        if !(await stock.enAttente().isEmpty) { await rejouerFile() }
        await tirer(conversation, leger: true)
        if lienAPartager != nil, tics % 6 == 0 {
            lienAPartager = await lien(pour: conversation)
        }
        await rafraichirAffichage()
    }

    /// Rejoue la file d'envoi au retour du réseau. À lancer dans un `.task` de la liste, APRÈS le chargement de la liste.
    func surveillerReseau() async {
        if !listeChargee { await chargerListe() }
        for await connecte in ReseauChat.flux() where connecte {
            await rejouerFile()
            if ouverte != nil { await actualiser() }
        }
    }

    /// A l'appelle quand CloudKit signale un changement (notification silencieuse reçue). Si l'app n'est pas au premier plan et qu'un
    /// vrai message nouveau est arrivé (hors auteurs bloqués, messages masqués, conversations fermées), une alerte locale prévient.
    func traiterNotificationCloudKit() async {
        nouveauxEntrants = 0
        await actualiserListe()
        if ouverte != nil { await actualiser() }
        if nouveauxEntrants > 0, !actif { await permission.publierLocale("Nouveau message") }
    }

    private func lien(pour conversation: ConversationID) async -> URL? {
        try? await service.lienDInvitation(pour: conversation, participants: aAdmettre[conversation] ?? [],
                                           peutCreerLaZone: peutCreer[conversation] ?? false)
    }

    /// Déduit l'auteur de chaque message du compte iCloud qui l'a RÉELLEMENT écrit (`createurCloudKit`, posé par iCloud), puis de
    /// l'annuaire : `auteurId` et `surnom` du message reçu ne sont jamais crus. Compte inconnu : « Un pêcheur », bloquable.
    private func attribuer(_ recus: [MessageChat], dans conversation: ConversationID) -> [MessageChat] {
        recus.map { brut in
            guard let createur = brut.createurCloudKit else { return brut }
            var message = brut
            if createur == MessageChat.createurMoi, let moi {
                message.auteurId = moi.id
                message.surnom = moi.surnom
            } else if let connu = auteurs[conversation]?[createur] {
                message.auteurId = connu.id
                message.surnom = connu.surnom
            } else if conversation.type == .ami, createur != MessageChat.createurMoi, let ami = auteurs[conversation]?.values.first {
                // Entre amis il n'y a que deux comptes dans la zone : celui qui n'est pas moi est l'ami.
                message.auteurId = ami.id
                message.surnom = ami.surnom
            } else {
                message.auteurId = "ck:" + createur
                message.surnom = "Un pêcheur"
            }
            return message
        }
    }

    private func tirer(_ conversation: ConversationID, leger: Bool = false) async {
        if !listeChargee { await chargerListe() }
        do {
            let brut: [MessageChat]
            if leger {
                brut = try await service.changements(de: conversation)
            } else {
                brut = try await service.messages(de: conversation)
            }
            let recus = attribuer(brut, dans: conversation)
            let connus = await stock.identifiantsConnus(de: conversation)
            let bloques = await stock.bloques().union(await annuaire.bloques())
            let masques = await stock.masques()
            let ferme = bloques.contains(conversation.id) || (profils[conversation].map(bloques.contains) ?? false)
            if !ferme {
                nouveauxEntrants += recus.filter {
                    !connus.contains($0.id) && $0.auteurId != moi?.id && !bloques.contains($0.auteurId) && !masques.contains($0.id)
                }.count
            }
            await stock.fusionner(recus, dans: conversation)
            if avis == .horsLigne { avis = nil }
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

    // MARK: Abonnements

    /// Abonne toutes les conversations de la liste dès que la permission est accordée (et non la seule conversation ouverte) : un
    /// destinataire qui n'a encore jamais écrit est prévenu. Celles dont la zone n'existe pas encore chez moi sont réessayées au
    /// prochain passage.
    private func abonnerToutes() async {
        guard !exemple, await permission.statut() == .accorde else { return }
        for conversation in titres.keys where !abonnees.contains(conversation) {
            do {
                try await service.abonner(conversation)
                abonnees.insert(conversation)
            } catch {
                continue // `.introuvable` : zone pas encore là (invitation pas acceptée) ; réseau : plus tard
            }
        }
    }

    // MARK: Envoyer

    /// Rend `true` si le message est parti dans la file (le champ de saisie peut se vider).
    /// Ordre voulu : filtre → file locale (visible tout de suite) → permission de notifier (au PREMIER envoi seulement) → réseau.
    @discardableResult
    func envoyer(_ texte: String) async -> Bool {
        guard let conversation = ouverte, !ouverteFermee else { return false }
        if exemple {
            avis = .exemple
            return false
        }
        // Écrire exige un profil et d'avoir déclaré 15 ans ou plus (L21) ; sinon la conversation se lit seulement.
        guard let moi, moi.a15Ans else {
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
            await demanderLaPermission()
            verifierLien = true
            await rejouerFile()
            await abonnerToutes()
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

    /// La fenêtre d'iOS : au premier message envoyé OU à l'acceptation d'un lien de conversation (gestes voulus par la personne),
    /// jamais au lancement ni à l'ouverture de l'onglet.
    private func demanderLaPermission() async {
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

    /// Écrit dans la base de la personne de garde les signalements qui n'y sont pas encore (hors ligne : au retour du réseau).
    /// Une erreur arrête la boucle sans rien effacer : le signalement reste dans le stock et repart au prochain passage.
    private func rejouerSignalements() async {
        for signalement in await stock.signalementsEnAttente() {
            do {
                try await service.enregistrerSignalement(signalement)
                await stock.signalementParti(signalement.id)
            } catch {
                return
            }
        }
    }

    private func rejouerFile() async {
        if !listeChargee { await chargerListe() } // sans cela `peutCreer` est vide et un message d'ami serait marqué « pas parti »
        await rejouerSignalements()
        guard !exemple, !envoiEnCours else { return }
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
                await stock.marquerPasParti(message.id)
                signalerErreur(error)
                // Panne générale (réseau, compte, iCloud plein) : les suivants échoueraient aussi, on s'arrête là. Sinon (zone pas
                // encore acceptée, erreur propre à ce message) : ce message seul reste « pas parti », les suivants partent.
                switch ServiceChatCloudKit.traduire(error) {
                case .reseau, .iCloudIndisponible, .iCloudPlein: return
                case .introuvable, .autre: continue
                }
            }
        }
    }

    private func signalerErreur(_ erreur: Error) {
        switch ServiceChatCloudKit.traduire(erreur) {
        case .reseau: avis = .horsLigne
        case .iCloudIndisponible: avis = .iCloudIndisponible
        case .iCloudPlein: avis = .iCloudPlein
        case .introuvable: if avis == nil { avis = .enAttenteDeLInvitation }
        case .autre: avis = .echec
        }
    }

    func effacerAvis() {
        avis = nil
    }

    // MARK: Modération (décision 5, règle 1.2)

    /// « Signaler » : le message disparaît tout de suite de cet iPhone. Le texte du message est copié dans l'enregistrement
    /// `Signalement` (500 caractères au plus) ET joint au `mailto:` : l'équipe doit pouvoir le lire, les conversations étant en
    /// zone partagée (décision de Titouan, 19 oct.). « Signalé » n'est dit que si l'enregistrement a réussi ; sinon il reste sur
    /// l'iPhone et repart au retour du réseau.
    func signaler(_ message: MessageChat, motif: MotifSignalementMessage) async -> ResultatSignalementMessage {
        await stock.masquer(message.id)
        if exemple {
            avis = .exemple
            await rafraichirAffichage()
            await chargerListe()
            return ResultatSignalementMessage(url: nil, enregistre: false)
        }
        let signalement = SignalementMessageEnAttente(id: UUID(), cible: message.id, motif: motif.rawValue,
                                               signalePar: moi?.id ?? "inconnu", date: Date(),
                                               texte: String(message.texte.prefix(FabriqueRecordsChat.texteSignalementMax)))
        await stock.ajouter(signalement)
        await rejouerSignalements()
        let enregistre = !(await stock.signalementsEnAttente().contains { $0.id == signalement.id })
        avis = enregistre ? .signalementEnregistre : .signalementEnAttente
        await rafraichirAffichage()
        await chargerListe()
        return ResultatSignalementMessage(url: SignalementMessage.url(contact: configuration.contact, message: message, motif: motif),
                                   enregistre: enregistre)
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

    /// A appelle ceci quand `InvitationChat.estUneConversation` est vrai (voir le rapport L24). Le destinataire vient de faire un geste
    /// voulu (toucher le lien) : c'est là que la permission de notifier est demandée et que les conversations sont abonnées, pas
    /// seulement à l'envoi.
    func accepter(_ invitation: InvitationChat) async {
        do {
            try await service.accepterInvitation(invitation)
            await chargerListe()
            await demanderLaPermission()
            abonnees = []
            await actualiserListe() // rejoue aussi la file : un message écrit avant l'acceptation part maintenant
        } catch {
            if ServiceChatCloudKit.traduire(error) == .introuvable { avis = .echec } else { signalerErreur(error) }
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

/// L'adaptateur que A compose dans l'`EffaceurContenu` de L21 (`RegistreEffaceurs.partage.ajouter(...)`).
nonisolated struct EffaceurChat: EffaceurContenu {
    let gestion: GestionChat

    func effacerMesMessages() async throws {
        try await gestion.effacerMesMessages()
    }

    /// Même signature que `EffaceurContenu.effacerContenu(deProfil:)` de L21.
    func effacerContenu(deProfil profilID: String) async throws {
        try await gestion.effacerMesMessages()
    }
}
