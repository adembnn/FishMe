import CloudKit
import Foundation
import Testing
@testable import BuildChallenge

// Tests écrits sans pouvoir les exécuter (pas de Mac pour ce lot) : à lancer par Sullyvan ou Adem.

@MainActor
struct ChatTests {
    private let lea = FauxAnnuaire.amisParDefaut[0]
    private var ami: ConversationID { .ami(lea.idCloudKit) }
    private var club: ConversationID { .club(FauxAnnuaire.clubsParDefaut[0].id) }

    private func dossier() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("ChatTests-\(UUID().uuidString)")
    }

    private func gestion(service: FauxServiceChat = FauxServiceChat(), annuaire: FauxAnnuaire = FauxAnnuaire(),
                         permission: FaussePermission = FaussePermission()) -> (GestionChat, StockChat) {
        let stock = StockChat(dossier: dossier())
        return (GestionChat(service: service, annuaire: annuaire, stock: stock, permission: permission), stock)
    }

    private func message(_ conversation: ConversationID, auteur: String = "p-lea", texte: String = "Salut") -> MessageChat {
        MessageChat(id: UUID(), conversation: conversation, auteurId: auteur, surnom: "Léa", texte: texte, date: Date())
    }

    // MARK: Filtre de saisie

    @Test func motInterditRefuse() {
        #expect(FiltreMessage.verifier("quel connard") == .motInterdit)
        #expect(FiltreMessage.verifier("CONNÂRD") == .motInterdit)
        #expect(FiltreMessage.verifier("c0nnard") == .motInterdit)
        #expect(FiltreMessage.verifier("c o n n a r d") == .motInterdit)
    }

    @Test func motDePecheAccepte() {
        #expect(FiltreMessage.verifier("Un brochet de 62 cm au bassin de l'ancienne gare") == .accepte("Un brochet de 62 cm au bassin de l'ancienne gare"))
    }

    @Test func positionRefusee() {
        #expect(FiltreMessage.verifier("48.856614, 2.352222") == .position)
        #expect(FiltreMessage.verifier("https://maps.apple.com/?ll=1,2") == .position)
        #expect(FiltreMessage.verifier("lat 48.85661") == .position)
        #expect(FiltreMessage.verifier("il fait 12.5 degrés") == .accepte("il fait 12.5 degrés"))
    }

    @Test func longueurEtVide() {
        #expect(FiltreMessage.verifier("   ") == .vide)
        #expect(FiltreMessage.verifier(String(repeating: "a", count: 501)) == .tropLong)
        #expect(FiltreMessage.verifier(String(repeating: "a", count: 500)) == .accepte(String(repeating: "a", count: 500)))
    }

    // MARK: Vie privée des enregistrements

    @Test func recordsSansPosition() {
        let zone = CKRecordZone.ID(zoneName: "chat-test", ownerName: CKCurrentUserDefaultName)
        let m = message(club)
        let champsClub = Set(FabriqueRecordsChat.recordClub(m, zone: zone).allKeys())
        #expect(champsClub.isSubset(of: FabriqueRecordsChat.champsClub))
        let champsAmi = Set(FabriqueRecordsChat.recordAmi(message(ami), zone: zone).allKeys())
        #expect(champsAmi.isSubset(of: FabriqueRecordsChat.champsAmi))
        let signalement = SignalementEnAttente(id: UUID(), cible: m.id, motif: "Autre", signalePar: "p-moi", date: Date())
        #expect(Set(FabriqueRecordsChat.recordSignalement(signalement).allKeys()).isSubset(of: FabriqueRecordsChat.champsSignalement))
        for interdit in ["latitude", "longitude", "location", "lat", "lon", "lieu"] {
            #expect(!champsClub.contains(interdit) && !champsAmi.contains(interdit))
        }
    }

    @Test func recordRelu() throws {
        let zone = CKRecordZone.ID(zoneName: "chat-test", ownerName: CKCurrentUserDefaultName)
        let m = message(ami, texte: "Coucou")
        let relu = try #require(FabriqueRecordsChat.message(depuis: FabriqueRecordsChat.recordAmi(m, zone: zone), conversation: ami))
        #expect(relu.id == m.id && relu.texte == "Coucou" && relu.etat == .envoye)
    }

    // MARK: Signalement

    @Test func urlDeSignalement() throws {
        let m = message(club)
        let url = try #require(SignalementMessage.url(contact: "fishme.app@gmail.com", message: m, motif: .spam))
        let texte = url.absoluteString.removingPercentEncoding ?? ""
        #expect(url.scheme == "mailto")
        #expect(texte.contains("fishme.app@gmail.com"))
        #expect(texte.contains(m.id.uuidString))
        #expect(!texte.contains("Salut")) // le texte d'un message de club n'est pas joint
        let prive = try #require(SignalementMessage.url(contact: "fishme.app@gmail.com", message: message(ami), motif: .spam))
        #expect((prive.absoluteString.removingPercentEncoding ?? "").contains("Salut"))
    }

    @Test func signalerMasqueEtEnregistre() async throws {
        let service = FauxServiceChat()
        let (g, _) = gestion(service: service)
        let m = message(club)
        await service.recevoir(m)
        await g.ouvrir(club)
        #expect(g.messagesOuverts.contains { $0.id == m.id })
        let url = await g.signaler(m, motif: .harcelement)
        #expect(url != nil)
        #expect(!g.messagesOuverts.contains { $0.id == m.id })
        let enregistres = await service.signalements
        #expect(enregistres.count == 1 && enregistres[0].cible == m.id)
    }

    @Test func signalementHorsLigneGarde() async {
        let service = FauxServiceChat(horsLigne: true)
        let (g, stock) = gestion(service: service)
        await g.ouvrir(club)
        _ = await g.signaler(message(club), motif: .autre)
        #expect(await stock.signalementsEnAttente().count == 1)
        await service.regler(horsLigne: false)
        await g.actualiser()
        #expect(await stock.signalementsEnAttente().isEmpty)
        #expect(await service.signalements.count == 1)
    }

    // MARK: Permission de notifier

    @Test func permissionSeulementAuPremierEnvoi() async {
        let permission = FaussePermission()
        let (g, _) = gestion(permission: permission)
        await g.chargerListe()
        await g.ouvrir(ami)
        await g.actualiser()
        #expect(await permission.demandes == 0)
        #expect(await g.envoyer("Premier") == true)
        #expect(await permission.demandes == 1)
        #expect(await g.envoyer("Second") == true)
        #expect(await permission.demandes == 1)
    }

    @Test func motInterditNeDeclenchePasLaPermission() async {
        let service = FauxServiceChat()
        let permission = FaussePermission()
        let (g, _) = gestion(service: service, permission: permission)
        await g.ouvrir(ami)
        #expect(await g.envoyer("espèce de connard") == false)
        #expect(g.verdictSaisie == .motInterdit)
        #expect(await permission.demandes == 0)
        #expect(await service.tentatives == 0)
    }

    @Test func refusDesNotificationsDitUneSeuleFois() async {
        let (g, _) = gestion(permission: FaussePermission(accepte: false))
        await g.ouvrir(ami)
        _ = await g.envoyer("Un")
        #expect(g.avis == .notificationsRefusees)
        g.effacerAvis()
        _ = await g.envoyer("Deux")
        #expect(g.avis != .notificationsRefusees)
    }

    // MARK: Hors ligne

    @Test func horsLignePuisRetourDuReseau() async {
        let service = FauxServiceChat(horsLigne: true)
        let (g, _) = gestion(service: service)
        await g.ouvrir(ami)
        _ = await g.envoyer("Écrit sans réseau")
        #expect(g.messagesOuverts.last?.etat == .pasParti)
        await service.regler(horsLigne: false)
        await g.renvoyer()
        #expect(g.messagesOuverts.last?.etat == .envoye)
        let parti = await service.parConversation[ami] ?? []
        #expect(parti.contains { $0.texte == "Écrit sans réseau" })
    }

    @Test func conversationLisibleHorsLigne() async {
        let service = FauxServiceChat(messages: [ami: [message(ami, texte: "Déjà lu")]])
        let (g, _) = gestion(service: service)
        await g.ouvrir(ami)
        await service.regler(horsLigne: true)
        g.fermer()
        await g.ouvrir(ami)
        #expect(g.messagesOuverts.contains { $0.texte == "Déjà lu" })
    }

    @Test func membreSansZoneNePeutPasCreer() async {
        let annuaire = FauxAnnuaire(clubs: [ClubChat(id: "club-1", nom: "Test", jeSuisFondateur: false, membres: [])])
        let (g, _) = gestion(annuaire: annuaire)
        await g.ouvrir(club)
        _ = await g.envoyer("Bonjour")
        #expect(g.messagesOuverts.last?.etat == .pasParti)
    }

    // MARK: Bloquer, âge

    @Test func bloquerUnAmiFermeLaConversation() async {
        let (g, _) = gestion()
        await g.ouvrir(ami)
        await g.bloquer(message(ami))
        #expect(g.ouverteFermee)
        #expect(await g.envoyer("Encore") == false)
        await g.debloquer(ami)
        #expect(!g.ouverteFermee)
    }

    @Test func bloquerUnMembreMasqueSesMessagesSeulement() async {
        let hugo = message(club, auteur: "p-hugo", texte: "Du bruit")
        let lea = message(club, auteur: "p-lea", texte: "Du calme")
        let (g, _) = gestion(service: FauxServiceChat(messages: [club: [hugo, lea]]))
        await g.ouvrir(club)
        #expect(g.messagesOuverts.count == 2)
        await g.bloquer(hugo)
        #expect(g.messagesOuverts.map(\.texte) == ["Du calme"])
    }

    @Test func moinsDeQuinzeAnsLectureSeule() async {
        let jeune = InterlocuteurChat(id: "p-moi", surnom: "Moi", idCloudKit: "_moi", a15Ans: false)
        let (g, _) = gestion(annuaire: FauxAnnuaire(profil: jeune))
        await g.ouvrir(ami)
        #expect(await g.envoyer("Salut") == false)
        #expect(g.avis == .pasDeProfil)
    }

    @Test func sansProfilLectureSeule() async {
        let (g, _) = gestion(annuaire: FauxAnnuaire(profil: nil))
        await g.ouvrir(ami)
        #expect(await g.envoyer("Salut") == false)
    }

    // MARK: Cache et effacement

    @Test func stockRelu() async {
        let d = dossier()
        let premier = StockChat(dossier: d)
        let m = message(ami)
        await premier.mettreEnAttente(m)
        let second = StockChat(dossier: d)
        #expect(await second.enAttente().map(\.id) == [m.id])
        #expect(await second.messages(de: ami).first?.etat == .enAttente)
    }

    @Test func effacerMesMessages() async throws {
        let service = FauxServiceChat()
        let (g, stock) = gestion(service: service)
        await g.ouvrir(ami)
        _ = await g.envoyer("À effacer")
        try await EffaceurChat(gestion: g).effacerMesMessages()
        #expect(await service.effaces == ["p-moi"])
        #expect(await stock.messages(de: ami).isEmpty)
    }

    @Test func nonLuPuisVu() async {
        let (g, _) = gestion(service: FauxServiceChat(messages: [ami: [message(ami)]]))
        await g.actualiserListe()
        #expect(g.nonLus == 1)
        await g.ouvrir(ami)
        g.fermer()
        await g.chargerListe()
        #expect(g.nonLus == 0)
    }
}
