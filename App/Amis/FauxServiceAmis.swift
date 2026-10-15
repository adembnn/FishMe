#if DEBUG
import CloudKit
import Foundation

/// Faux service d'amis pour les tests et les aperçus : tout en mémoire, un interrupteur « hors ligne », aucun appel à iCloud.
actor FauxServiceAmis: ServiceAmis {
    private(set) var publiees: [CartePartagee] = []
    private(set) var tentatives = 0
    private(set) var zoneSupprimee = false
    private(set) var retires: [String] = []
    private(set) var quittes: [String] = []
    private(set) var acceptees: [String] = []
    private var horsLigne: Bool
    private var compte: EtatCompte
    private var invites: [Ami]
    private var recues: [CollectionAmi]

    init(horsLigne: Bool = false, compte: EtatCompte = .disponible, invites: [Ami] = [], recues: [CollectionAmi] = []) {
        self.horsLigne = horsLigne
        self.compte = compte
        self.invites = invites
        self.recues = recues
    }

    func regler(horsLigne: Bool) { self.horsLigne = horsLigne }
    func regler(recues: [CollectionAmi]) { self.recues = recues }

    func etatCompte() async -> EtatCompte { compte }

    func publier(_ cartes: [CartePartagee]) async throws {
        tentatives += 1
        if horsLigne { throw ErreurAmis.reseau }
        publiees.append(contentsOf: cartes)
    }

    func partagePret() async throws -> PartagePret {
        if horsLigne { throw ErreurAmis.reseau }
        let zone = CKRecordZone.ID(zoneName: "Pescedex", ownerName: CKCurrentUserDefaultName)
        let share = CKShare(recordZoneID: zone)
        share.publicPermission = .none
        return PartagePret(share: share)
    }

    func amisInvites() async throws -> [Ami] {
        if horsLigne { throw ErreurAmis.reseau }
        return invites
    }

    func collectionsRecues() async throws -> [CollectionAmi] {
        if horsLigne { throw ErreurAmis.reseau }
        return recues
    }

    func retirerInvite(_ ami: Ami) async throws {
        if horsLigne { throw ErreurAmis.reseau }
        retires.append(ami.id)
        invites.removeAll { $0.id == ami.id }
    }

    func quitterPartage(de ami: Ami) async throws {
        if horsLigne { throw ErreurAmis.reseau }
        quittes.append(ami.id)
        recues.removeAll { $0.ami.id == ami.id }
    }

    func supprimerMesCartes() async throws {
        if horsLigne { throw ErreurAmis.reseau }
        zoneSupprimee = true
        publiees = []
        invites = []
    }

    func accepter(_ invitation: InvitationRecue) async throws -> Ami {
        if horsLigne { throw ErreurAmis.reseau }
        let ami = Ami(id: "ami-\(invitation.nomAmi)", nom: invitation.nomAmi, sens: .recu)
        acceptees.append(ami.id)
        recues.append(CollectionAmi(ami: ami, cartes: []))
        return ami
    }
}
#endif
