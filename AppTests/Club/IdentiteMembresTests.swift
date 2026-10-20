import CloudKit
import Foundation
import Testing
@testable import BuildChallenge

// Résolution de l'`idCloudKit` des membres de club (L22). Écrits sans Mac : NON EXÉCUTÉS (⚠ à lancer).
// Faux CloudKit et faux résolveur seulement. Les attendus sont comptés à la main dans chaque test.

nonisolated private final class MemoireMembresFausse: MemoireProfil, @unchecked Sendable {
    var id: String?
    init(_ id: String?) { self.id = id }
    func idProfil() -> String? { id }
    func surnom() -> String? { id.map(GestionClubs.surnomTronque) }
    func retenir(id: String, surnom: String) { self.id = id }
    func oublier() { id = nil }
}

/// Une horloge que le test avance à la main.
nonisolated private final class HorlogeTestIdentite: @unchecked Sendable {
    var date = Date(timeIntervalSince1970: 1_800_000_000)
    func avancer(_ secondes: TimeInterval) { date = date.addingTimeInterval(secondes) }
}

@MainActor
struct IdentiteMembresTests {
    private let debut = Date(timeIntervalSince1970: 1_700_000_000)

    private func adhesion(_ profil: String, role: RoleMembre = .membre, rang: Double, idCloudKit: String? = nil) -> Membre {
        Membre(id: Membre.identifiant(club: "c1", profil: profil), club: "c1", profil: profil, role: role,
               depuis: debut.addingTimeInterval(rang), idCloudKit: idCloudKit)
    }

    /// Adem est fondateur de « c1 » ; Léa et Nina n'ont pas d'`idCloudKit`, Malo a le sien ; `extra` : membres en plus.
    private func monde(resolveur: FauxResolveurIdentite, horloge: HorlogeTestIdentite, cache: CacheClubsMemoire = CacheClubsMemoire(),
                       extra: [Membre] = []) async -> GestionClubs {
        let service = FauxServiceClubs()
        await service.poser(club: Club(id: "c1", nom: "Brochets", poissonId: nil, image: nil, fondateur: "p-adem", creeLe: debut),
                            membres: [adhesion("p-adem", role: .fondateur, rang: 0), adhesion("p-lea", rang: 1),
                                      adhesion("p-malo", rang: 2, idCloudKit: "_malo"), adhesion("p-nina", rang: 3)] + extra)
        let u = UUID().uuidString
        return GestionClubs(service: service, profils: FauxServiceProfil(), memoire: MemoireMembresFausse("p-adem"), cache: cache,
                            blocages: BlocagesProfils(cleBloques: "t.bl.\(u)", cleMasques: "t.ma.\(u)"),
                            masquees: CartesMasquees(cle: "t.cm.\(u)"), filtre: AucunFiltre(), resolveur: resolveur,
                            maintenant: { horloge.date })
    }

    private func membresPourChat(_ g: GestionClubs) -> [MembrePourChat] {
        g.clubsPourChat().first { $0.id == "c1" }?.membres ?? []
    }

    // MARK: Résolution

    @Test func laPageRetrouveLeCompteDesMembresSansIdentifiant() async {
        let resolveur = FauxResolveurIdentite(comptes: ["p-lea": "_lea"])
        let g = await monde(resolveur: resolveur, horloge: HorlogeTestIdentite())
        await g.charger(ouverture: true)
        let membres = membresPourChat(g)
        // moi (Adem) retiré ; il reste Léa, Malo, Nina dans l'ordre d'arrivée
        #expect(membres.map(\.profil) == ["p-lea", "p-malo", "p-nina"])
        // Léa : trouvée par son profil public ; Malo : celui de son adhésion ; Nina : profil pas encore créé
        #expect(membres.map(\.idCloudKit) == ["_lea", "_malo", nil])
        #expect(membres.map(\.enAttenteDeProfil) == [false, false, true])
        #expect(g.identites == ["p-lea": "_lea"])
        // pas d'erreur affichée pour un profil absent
        #expect(g.message == nil)
        #expect(!g.horsLigne)
    }

    @Test func unCompteDejaConnuNEstJamaisRedemandeNiRemplace() async {
        let resolveur = FauxResolveurIdentite(comptes: ["p-malo": "_autre", "p-lea": "_lea"])
        let g = await monde(resolveur: resolveur, horloge: HorlogeTestIdentite())
        await g.charger(ouverture: true)
        #expect(membresPourChat(g).map(\.idCloudKit) == ["_lea", "_malo", nil])
        // Malo (adhésion lue par CloudKit) n'est pas interrogé : Léa puis Nina seulement
        #expect(await resolveur.appels == ["p-lea", "p-nina"])
    }

    @Test func unProfilAbsentEstRedemandeApresLeDelaiOuALOuverture() async {
        let resolveur = FauxResolveurIdentite(comptes: ["p-lea": "_lea"])
        let horloge = HorlogeTestIdentite()
        let g = await monde(resolveur: resolveur, horloge: horloge)
        await g.charger(ouverture: true)
        #expect(await resolveur.appels == ["p-lea", "p-nina"]) // 2 appels
        horloge.avancer(8)
        await g.charger() // rafraîchissement de la page 8 s plus tard : Nina essayée depuis 8 s, moins de 60 s
        #expect(await resolveur.appels.count == 2)
        horloge.avancer(53) // 8 + 53 = 61 s depuis l'essai
        await g.charger()
        #expect(await resolveur.appels == ["p-lea", "p-nina", "p-nina"]) // 3 appels
        await g.charger(ouverture: true) // la page se rouvre : on retente sans attendre
        #expect(await resolveur.appels.count == 4)
        // le profil de Nina est enfin créé
        await resolveur.creer(profil: "p-nina", compte: "_nina")
        await g.charger(ouverture: true)
        #expect(membresPourChat(g).map(\.idCloudKit) == ["_lea", "_malo", "_nina"])
        #expect(await resolveur.appels.count == 5)
        #expect(g.identites == ["p-lea": "_lea", "p-nina": "_nina"])
        // plus personne à retrouver : un nouveau chargement n'appelle plus rien
        await g.charger(ouverture: true)
        #expect(await resolveur.appels.count == 5)
    }

    @Test func uneErreurReseauNeCompteNiNeConclut() async {
        let resolveur = FauxResolveurIdentite(comptes: ["p-lea": "_lea", "p-nina": "_nina"], horsLigne: true)
        let g = await monde(resolveur: resolveur, horloge: HorlogeTestIdentite())
        await g.charger(ouverture: true)
        // le réseau tombe au premier appel : on s'arrête là, tous attendent, aucune erreur dite
        #expect(await resolveur.appels == ["p-lea"])
        #expect(membresPourChat(g).map(\.idCloudKit) == [nil, "_malo", nil])
        #expect(g.message == nil)
        await resolveur.regler(horsLigne: false)
        await g.charger() // même instant, sans ouverture : rien n'a été compté comme essai
        #expect(membresPourChat(g).map(\.idCloudKit) == ["_lea", "_malo", "_nina"])
        #expect(await resolveur.appels == ["p-lea", "p-lea", "p-nina"])
    }

    // MARK: Démo

    @Test func unMembreDeLaDemoNEstNiResoluNiEnAttente() async {
        let resolveur = FauxResolveurIdentite(comptes: ["demo-e1": "_pirate"])
        let g = await monde(resolveur: resolveur, horloge: HorlogeTestIdentite(), extra: [adhesion("demo-e1", rang: 4)])
        await g.charger(ouverture: true)
        let membres = membresPourChat(g)
        #expect(membres.map(\.profil) == ["p-lea", "p-malo", "p-nina", "demo-e1"])
        let adem = membres[3]
        #expect(adem.estExemple)
        #expect(adem.idCloudKit == nil)
        #expect(!adem.enAttenteDeProfil)
        // jamais demandé au résolveur, même si une table de test lui prête un compte
        #expect(await resolveur.appels == ["p-lea", "p-nina"])
        #expect(g.identites["demo-e1"] == nil)
        // et côté chat, même fondateur : seuls Malo (compte de son adhésion) est admis ; Léa et Nina n'ont pas de compte ici
        let club = ClubChat(g.clubsPourChat()[0])
        #expect(GestionChat.comptesAAdmettre(club: ClubChat(id: club.id, nom: club.nom, jeSuisFondateur: true, membres: club.membres),
                                             moi: nil) == ["_malo"])
    }

    // MARK: Mémoire

    @Test func leCompteVerifieSurvitAuRedemarrage() async {
        let cache = CacheClubsMemoire()
        let resolveur = FauxResolveurIdentite(comptes: ["p-lea": "_lea"])
        let g = await monde(resolveur: resolveur, horloge: HorlogeTestIdentite(), cache: cache)
        await g.charger(ouverture: true)
        #expect(g.identites == ["p-lea": "_lea"])
        // un autre lancement : même fichier, aucun réseau, aucun résolveur
        let u = UUID().uuidString
        let relance = GestionClubs(service: FauxServiceClubs(horsLigne: true), profils: FauxServiceProfil(),
                                   memoire: MemoireMembresFausse("p-adem"), cache: cache,
                                   blocages: BlocagesProfils(cleBloques: "t.bl.\(u)", cleMasques: "t.ma.\(u)"),
                                   masquees: CartesMasquees(cle: "t.cm.\(u)"), filtre: AucunFiltre())
        #expect(membresPourChat(relance).map(\.idCloudKit) == ["_lea", "_malo", nil])
    }

    @Test func unFichierDeCacheAncienSansIdentitesSeRelit() throws {
        let ancien = #"{"clubs":[],"membres":{},"cartes":{},"profils":{},"enregistreLe":0}"#
        let etat = try JSONDecoder().decode(EtatCacheClubs.self, from: Data(ancien.utf8))
        #expect(etat.identites == nil)
    }

    // MARK: Règles pures

    @Test func seulUnCreateurUtilisableEstRetenu() {
        #expect(IdentiteMembre.createurUtilisable("_abc") == "_abc")
        #expect(IdentiteMembre.createurUtilisable("") == nil)
        #expect(IdentiteMembre.createurUtilisable(nil) == nil)
        #expect(IdentiteMembre.createurUtilisable(CKCurrentUserDefaultName) == nil) // l'alias du propriétaire ne désigne personne
    }

    @Test func seulsLesIdentifiantsDemoSontDesExemples() {
        #expect(IdentiteMembre.estExemple("demo-e1"))
        #expect(!IdentiteMembre.estExemple("p-demo-e1")) // un vrai surnom « demo-e1 » est un profil, pas la démo
        #expect(!IdentiteMembre.estExemple("p-lea"))
    }

    @Test func uneChaineVideEstTraiteeCommeInconnue() {
        let vide = adhesion("p-a", rang: 0, idCloudKit: "")
        #expect(IdentiteMembre.idCloudKit(de: vide, verifies: [:]) == nil)
        #expect(IdentiteMembre.idCloudKit(de: vide, verifies: ["p-a": "_a"]) == "_a")
        let connu = adhesion("p-a", rang: 0, idCloudKit: "_direct")
        #expect(IdentiteMembre.idCloudKit(de: connu, verifies: ["p-a": "_a"]) == "_direct")
    }
}
