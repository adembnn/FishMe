import CloudKit
import Core
import Foundation
import Observation

/// Le cerveau de l'écran Amis : invitation, acceptation, lecture des cartes d'amis (réseau puis cache), envoi à rejouer,
/// signaler, bloquer, retirer, supprimer. Tout CloudKit passe par `ServiceAmis`.
@MainActor
@Observable
final class GestionAmis {
    enum Message: Equatable {
        case iCloudIndisponible
        case horsLigne
        case iCloudPlein
        case echec
    }

    private(set) var amis: [Ami] = []
    private(set) var collections: [CollectionAmi] = []
    private(set) var compte: EtatCompte = .disponible
    private(set) var cartesEnAttente = 0
    private(set) var partageActif = false
    private(set) var message: Message?
    private(set) var enCours = false
    /// Après une acceptation : l'écran propose « Inviter en retour » en un toucher.
    private(set) var proposerInvitationEnRetour = false
    var invitationRecue: InvitationRecue?
    /// Mes espèces, pour marquer « nouvelle » celles qu'un ami a et pas moi.
    private(set) var mesEspeces: Set<String> = []

    let configuration: ConfigurationAmis
    private let service: any ServiceAmis
    private let cache: CacheAmis
    private let file: FileEnvoi
    private let constructeur: ConstructeurCartes

    init(service: any ServiceAmis, cache: CacheAmis, file: FileEnvoi, collection: any CollectionCartes, especes: any ServiceEspeces,
         configuration: ConfigurationAmis) {
        self.service = service
        self.cache = cache
        self.file = file
        self.constructeur = ConstructeurCartes(collection: collection, especes: especes)
        self.configuration = configuration
    }

    // MARK: Lecture

    /// Le bouton « Actualiser » et l'ouverture de l'écran : rejoue l'envoi, relit les amis, met le cache à jour.
    func actualiser() async {
        enCours = true
        defer { enCours = false }
        partageActif = await file.partageActif
        mesEspeces = Set(await constructeur.collection.cartes().filter { !$0.exemple }.map(\.espece.id))
        await afficherLeCache()
        compte = await service.etatCompte()
        guard compte == .disponible else {
            message = .iCloudIndisponible
            cartesEnAttente = await file.nombreEnAttente
            return
        }
        message = nil
        await synchroniserMesCartes()
        do {
            let recues = try await service.collectionsRecues()
            // Un ami qui n'a encore aucune carte n'est pas dans le cache : on le garde dans la liste.
            let invites = ((try? await service.amisInvites()) ?? []) + recues.filter { $0.cartes.isEmpty }.map(\.ami)
            await cache.remplacer(par: recues)
            await afficherLeCache(invites: invites)
        } catch {
            signaler(erreur: error)
        }
    }

    private func afficherLeCache(invites: [Ami]? = nil) async {
        let bloques = await cache.bloques()
        let lues = await cache.collections()
        collections = lues
        var fusion: [String: Ami] = [:]
        for collection in lues { fusion[collection.ami.id] = collection.ami }
        for invite in invites ?? amis.filter(\.voitMaCollection) where !bloques.contains(invite.id) {
            if var existant = fusion[invite.id] {
                existant.sens = .reciproque
                fusion[invite.id] = existant
            } else {
                fusion[invite.id] = invite
            }
        }
        amis = fusion.values.sorted { $0.nom.localizedCompare($1.nom) == .orderedAscending }
    }

    // MARK: Mes cartes

    /// À appeler après chaque nouvelle carte (A le branche sur L4) et à chaque retour du réseau.
    /// N'envoie rien tant que la personne n'a invité personne : la zone iCloud n'existe pas avant.
    func synchroniserMesCartes() async {
        guard await file.partageActif else { return }
        await file.mettreEnAttente(await constructeur.cartesAPartager())
        await rejouerLEnvoi()
    }

    private func rejouerLEnvoi() async {
        let aEnvoyer = await file.enAttente()
        cartesEnAttente = aEnvoyer.count
        guard !aEnvoyer.isEmpty else { return }
        do {
            try await service.publier(aEnvoyer)
            await file.marquerEnvoyees(aEnvoyer.map(\.id))
            cartesEnAttente = 0
        } catch {
            signaler(erreur: error)
        }
    }

    /// Surveille le réseau : au retour, la file d'envoi repart seule.
    func surveillerLeReseau() async {
        var etaitConnecte = true
        for await connecte in SurveillanceReseau.flux() {
            if connecte && !etaitConnecte { await synchroniserMesCartes() }
            etaitConnecte = connecte
        }
    }

    // MARK: Inviter

    /// Appelé par le lien de partage : crée la zone et le partage, puis lance l'envoi de toutes les cartes.
    func preparerLePartage() async throws -> PartagePret {
        let pret = try await service.partagePret()
        await file.activerPartage()
        partageActif = true
        Task { await synchroniserMesCartes() }
        return pret
    }

    // MARK: Accepter

    func accepterLInvitation() async {
        guard let invitation = invitationRecue else { return }
        do {
            _ = try await service.accepter(invitation)
            invitationRecue = nil
            RelaisInvitations.partage.solder()
            proposerInvitationEnRetour = !partageActif
            await actualiser()
        } catch {
            signaler(erreur: error)
        }
    }

    func refuserLInvitation() {
        invitationRecue = nil
        RelaisInvitations.partage.solder()
    }

    func fermerLaProposition() {
        proposerInvitationEnRetour = false
    }

    // MARK: Règle 1.2 : signaler, bloquer, retirer, supprimer

    func urlDeSignalement(ami: Ami, carte: CartePartagee? = nil) -> URL? {
        Signalement.url(contact: configuration.contact, ami: ami, carte: carte)
    }

    /// Retire un ami : il ne voit plus mes cartes, et je ne vois plus les siennes.
    func retirer(_ ami: Ami) async {
        await couper(ami)
    }

    /// Bloque un ami : comme retirer, et ses cartes restent masquées même s'il m'invite de nouveau.
    func bloquer(_ ami: Ami) async {
        await cache.bloquer(ami.id)
        await couper(ami)
    }

    private func couper(_ ami: Ami) async {
        do {
            if ami.voitMaCollection { try await service.retirerInvite(ami) }
            if ami.jeVoisSaCollection { try await service.quitterPartage(de: ami) }
        } catch {
            signaler(erreur: error)
            return
        }
        amis.removeAll { $0.id == ami.id }
        collections.removeAll { $0.id == ami.id }
    }

    // MARK: Données d'affichage (Core, jamais recalculées ici)

    func espece(_ id: String) -> EspecePechable? {
        constructeur.especes.especesPechables().first { $0.espece.id == id }
    }

    /// Le M de « 7 sur les 11 relevées dans le 94 » : même règle que le compteur du Pescedex (L4).
    func especesReleveesDans(_ departement: String) -> Int {
        let zone = Departement(code: departement)
        return constructeur.especes.especesPechables().filter {
            JetonAmis.estReleveeDansLaZone(constructeur.especes.rarete(espece: $0.espece, departement: zone))
        }.count
    }

    /// Supprime la zone iCloud : toutes mes cartes partagées disparaissent chez mes amis. Le Pescedex local reste intact.
    func supprimerMesCartesPartagees() async {
        do {
            try await service.supprimerMesCartes()
            await file.toutOublier()
            partageActif = false
            cartesEnAttente = 0
            amis.removeAll { !$0.jeVoisSaCollection }
            amis = amis.map { var a = $0; a.sens = .recu; return a }
        } catch {
            signaler(erreur: error)
        }
    }

    private func signaler(erreur: Error) {
        switch ServiceAmisCloudKit.traduire(erreur) {
        case .reseau: message = .horsLigne
        case .iCloudIndisponible: message = .iCloudIndisponible
        case .iCloudPlein: message = .iCloudPlein
        default: message = .echec
        }
    }
}
