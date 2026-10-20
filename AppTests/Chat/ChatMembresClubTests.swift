import Foundation
import Testing
@testable import BuildChallenge

// Membres de club sans compte iCloud connu (L22 -> L24). Écrits sans Mac : NON EXÉCUTÉS (⚠ à lancer).
// Services factices seulement : aucun appel à iCloud. Les attendus sont comptés à la main dans chaque test.

@MainActor
struct ChatMembresClubTests {
    private let lea = MembrePourChat(profil: "p-lea", surnom: "Léa", idCloudKit: "_lea")
    private let nina = MembrePourChat(profil: "p-nina", surnom: "Nina", idCloudKit: nil)
    private let demo = MembrePourChat(profil: "demo-e1", surnom: "Adem", idCloudKit: nil, estExemple: true)

    private func dossier() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("ChatMembresClub-\(UUID().uuidString)")
    }

    private func clubChat(fondateur: Bool, _ membres: [MembrePourChat]) -> ClubChat {
        ClubChat(ClubPourChat(id: "club-x", nom: "X", jeSuisFondateur: fondateur, membres: membres))
    }

    // MARK: Adaptateur L22 -> L24

    @Test func lAdaptateurGardeTousLesMembresEtMarqueCeuxQuiAttendent() {
        let club = ClubChat(ClubPourChat(id: "c1", nom: "Brochets", jeSuisFondateur: true, membres: [lea, nina, demo]))
        #expect(club.id == "c1" && club.nom == "Brochets" && club.jeSuisFondateur)
        // 3 membres listés, dans l'ordre reçu
        #expect(club.membres.map(\.id) == ["p-lea", "p-nina", "demo-e1"])
        // compte inconnu -> identifiant vide
        #expect(club.membres.map(\.idCloudKit) == ["_lea", "", ""])
        #expect(club.membres.map(\.estExemple) == [false, false, true])
        #expect(club.membres.map(\.admissible) == [true, false, false])
        #expect(club.membres.map(\.enAttenteDeProfil) == [false, true, false])
    }

    // MARK: Qui est admis

    @Test func seuleUneVraiePersonneAuCompteConnuEstAdmise() {
        let club = clubChat(fondateur: true, [lea, nina, demo])
        // Nina (compte inconnu) et Adem (démo) sont écartés ; Léa seule reste
        #expect(GestionChat.comptesAAdmettre(club: club, moi: nil) == ["_lea"])
        #expect(GestionChat.surnomsEnAttente(club: club, moi: nil) == ["Nina"])
    }

    @Test func unNonFondateurNAdmetPersonne() {
        let club = clubChat(fondateur: false, [lea, nina])
        #expect(GestionChat.comptesAAdmettre(club: club, moi: nil).isEmpty)
        #expect(GestionChat.surnomsEnAttente(club: club, moi: nil).isEmpty)
    }

    @Test func pasDeDoublonNiMoiDansLAdmission() {
        let moiClub = MembrePourChat(profil: "p-alice", surnom: "Alice", idCloudKit: "_alice")
        let doublon = MembrePourChat(profil: "p-lea2", surnom: "Léa bis", idCloudKit: "_lea")
        let club = clubChat(fondateur: true, [lea, doublon, moiClub, nina])
        let moi = InterlocuteurChat(id: "p-alice", surnom: "Alice", idCloudKit: "_alice")
        // _lea deux fois -> une seule ; Alice (moi) retirée ; Nina n'a pas de compte
        #expect(GestionChat.comptesAAdmettre(club: club, moi: moi) == ["_lea"])
        #expect(GestionChat.surnomsEnAttente(club: club, moi: moi) == ["Nina"])
    }

    @Test func unMembreAuIdentifiantVideNeBloquePasLesAutres() async {
        let service = FauxServiceChat()
        let annuaire = FauxAnnuaire(clubs: [clubChat(fondateur: true, [lea, nina, demo])])
        let g = GestionChat(service: service, annuaire: annuaire, stock: StockChat(dossier: dossier()), permission: FaussePermission())
        let conversation = ConversationID.club("club-x")
        await g.ouvrir(conversation)
        // seul « _lea » est demandé à l'invitation : ni la chaîne vide, ni la démo
        #expect(await service.participantsDemandes[conversation] == ["_lea"])
        #expect(g.surnomsEnAttente(de: conversation) == ["Nina"])
        #expect(g.avis == nil)
    }

    @Test func leProfilArriveEtLeMembreEstAdmisALaRelecture() async {
        let service = FauxServiceChat()
        let annuaire = FauxAnnuaire(clubs: [clubChat(fondateur: true, [lea, nina])])
        let g = GestionChat(service: service, annuaire: annuaire, stock: StockChat(dossier: dossier()), permission: FaussePermission())
        let conversation = ConversationID.club("club-x")
        await g.ouvrir(conversation)
        #expect(await service.participantsDemandes[conversation] == ["_lea"])
        // le profil de Nina est lu : son compte est connu
        let ninaPrete = MembrePourChat(profil: "p-nina", surnom: "Nina", idCloudKit: "_nina")
        await annuaire.definir(clubs: [clubChat(fondateur: true, [lea, ninaPrete])])
        await g.actualiserListe()
        await g.actualiser() // la liste des comptes à admettre a changé : le lien est redemandé sans rouvrir la conversation
        // ordre de la liste : Léa puis Nina ; plus personne en attente ; l'annuaire a été prié de réessayer une fois
        #expect(await service.participantsDemandes[conversation] == ["_lea", "_nina"])
        #expect(g.surnomsEnAttente(de: conversation).isEmpty)
        #expect(await annuaire.actualisationsClubs == 1)
    }

    // MARK: Démo

    @Test func leClubExempleNAdmetPersonne() async {
        let g = GestionChat.exemple()
        await g.chargerListe()
        let club = DonneesExempleChat.club
        // 2 membres d'exemple (Léa, Hugo) : aucun n'est admissible, aucun n'est « en attente »
        #expect(club.membres.count == 2)
        #expect(club.membres.allSatisfy { !$0.admissible && !$0.enAttenteDeProfil })
        #expect(GestionChat.comptesAAdmettre(club: club, moi: nil).isEmpty)
        #expect(g.surnomsEnAttente(de: DonneesExempleChat.conversationClub).isEmpty)
    }

    @Test func unMembreDeLaDemoLocaleNEstJamaisAdmisMemeFondateur() {
        let club = clubChat(fondateur: true, [demo])
        #expect(GestionChat.comptesAAdmettre(club: club, moi: nil).isEmpty)
        // et il n'est pas non plus « en attente » : il n'aura jamais de profil
        #expect(GestionChat.surnomsEnAttente(club: club, moi: nil).isEmpty)
    }
}
