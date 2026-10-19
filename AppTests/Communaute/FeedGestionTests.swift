import Core
import Foundation
import Testing
@testable import BuildChallenge

// Tests du lot L23 (gestion du fil). Écrits sans compilateur : non exécutés à ce jour.

@MainActor
struct FeedGestionTests {
    private func gestion(service: FauxServiceFeed, source: SourceContexteFausse = SourceContexteFausse(), mail: Bool = true,
                         avecExemple: Bool = false) throws -> (GestionFeed, CacheFeed) {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = CacheFeed(conteneur: try CacheFeed.creerConteneur(enMemoire: true), dossierImages: dossier)
        return (GestionFeed(service: service, cache: cache, source: source, exemple: avecExemple ? ServiceFeedExemple() : nil,
                            mailDisponible: { mail }), cache)
    }

    private func jeu() -> [PublicationFeed] {
        [DemoFeed.publication("a1", auteur: "p-gros-brochet", club: "club-1", ilYa: 5),
         DemoFeed.publication("a2", auteur: "p-autre", mode: .departement, club: "", ilYa: 40),
         DemoFeed.publication("a3", auteur: "p-sans-lieu", mode: .aucun, club: "", ilYa: 90)]
    }

    @Test func lesTroisSectionsChargentLesBonnesPublications() async throws {
        let (g, _) = try gestion(service: FauxServiceFeed(publications: jeu()))
        await g.actualiser()
        #expect(g.etat(.clubs).publications.map(\.id) == ["a1"])
        #expect(g.etat(.amis).publications.map(\.id) == ["a1"])
        // a2 : département 94 ; a3 : « aucun lieu », jamais dans la région.
        #expect(g.etat(.region).publications.map(\.id).contains("a2"))
        #expect(!g.etat(.region).publications.map(\.id).contains("a3"))
    }

    @Test func voirPlusCharge20DePlus() async throws {
        let beaucoup = (0..<45).map { DemoFeed.publication("p\($0)", ilYa: Double($0)) }
        let (g, _) = try gestion(service: FauxServiceFeed(publications: beaucoup))
        await g.actualiser()
        #expect(g.etat(.clubs).publications.count == 20)
        #expect(g.etat(.clubs).encore)
        await g.voirPlus(.clubs)
        #expect(g.etat(.clubs).publications.count == 40)
    }

    @Test func uneSectionEntierementMasqueeNeFaitPasBoucler() async throws {
        // 25 publications d'un auteur bloqué (les plus récentes), puis 20 d'un auteur normal : la première page est entièrement masquée.
        let bloquees = (0..<25).map { DemoFeed.publication("b\($0)", auteur: "p-bloque", ilYa: Double($0)) }
        let bonnes = (25..<45).map { DemoFeed.publication("o\($0)", auteur: "p-ok", ilYa: Double($0)) }
        let service = FauxServiceFeed(publications: bloquees + bonnes)
        let (g, _) = try gestion(service: service)
        await g.bloquer("p-bloque")
        await g.actualiser()
        // La première page (20 bloquées) n'est pas rejouée : le curseur avance sur la dernière REÇUE, la page suivante arrive.
        #expect(g.etat(.clubs).publications.count == 15)
        #expect(g.etat(.clubs).publications.allSatisfy { $0.auteurNom == "p-ok" })
        #expect(g.etat(.clubs).encore)
        await g.voirPlus(.clubs)
        #expect(g.etat(.clubs).publications.count == 20)
        #expect(!g.etat(.clubs).encore)
        // Les pages lues sont en nombre fini.
        #expect(await service.appelsPage <= 3 * (GestionFeed.pagesMaxParChargement + 1))
    }

    @Test func toutBloqueLaSectionResteVideEtFinit() async throws {
        let toutes = (0..<45).map { DemoFeed.publication("b\($0)", auteur: "p-bloque", ilYa: Double($0)) }
        let (g, _) = try gestion(service: FauxServiceFeed(publications: toutes))
        await g.bloquer("p-bloque")
        await g.actualiser()
        #expect(g.etat(.clubs).publications.isEmpty)
        #expect(!g.etat(.clubs).encore)
    }

    @Test func leLikeEstUnParPersonneEtLeCompteVientDeLaRequete() async throws {
        let service = FauxServiceFeed(publications: jeu())
        let (g, _) = try gestion(service: service)
        await g.actualiser()
        let p = try #require(g.etat(.clubs).publications.first)
        await g.basculerLike(p)
        await g.actualiser()
        let apres = try #require(g.etat(.clubs).publications.first)
        #expect(apres.nbLikes == 1)
        #expect(apres.aime)
        await g.basculerLike(apres)
        await g.actualiser()
        #expect(g.etat(.clubs).publications.first?.nbLikes == 0)
    }

    // MARK: Signalement honnête

    @Test func signalerEcritLaTraceMasqueEtNeDitSignaleQuApresLEcriture() async throws {
        let service = FauxServiceFeed(publications: jeu())
        let (g, cache) = try gestion(service: service)
        await g.actualiser()
        let p = try #require(g.etat(.amis).publications.first)
        let issue = await g.signaler(p, motif: .spam)
        guard case .enregistre(let courriel) = issue else {
            Issue.record("attendu : enregistré")
            return
        }
        #expect(courriel?.absoluteString.contains("fishme.app@gmail.com") == true)
        #expect(courriel?.absoluteString.contains(p.id) == true)
        // Le texte signalé est joint (décision de Titouan), encodé dans l'URL.
        #expect(courriel?.absoluteString.contains("Texte%20signal") == true)
        #expect(g.message == .signale)
        #expect(g.etat(.amis).publications.isEmpty)
        #expect(await cache.masquees().contains(p.id))
        #expect(await service.signalements.count == 1)
        #expect(await cache.fileDeReprise().isEmpty)
        // Une nouvelle lecture ne la remet pas.
        await g.actualiser()
        #expect(!g.etat(.clubs).publications.map(\.id).contains(p.id))
    }

    @Test func sansMailLeCourrielNEstPasPropose() async throws {
        let (g, _) = try gestion(service: FauxServiceFeed(publications: jeu()), mail: false)
        await g.actualiser()
        let p = try #require(g.etat(.amis).publications.first)
        let issue = await g.signaler(p, motif: .spam)
        #expect(issue == .enregistre(courriel: nil))
    }

    @Test func sansEnregistrementPasDeSignaleEtLeSignalementAttendEnFile() async throws {
        let service = FauxServiceFeed(publications: jeu())
        let (g, cache) = try gestion(service: service)
        await g.actualiser()
        await service.regler(signalementEchoue: true)
        let p = try #require(g.etat(.amis).publications.first)
        let issue = await g.signaler(p, motif: .harcelement)
        guard case .pasEnregistre = issue else {
            Issue.record("attendu : pas enregistré")
            return
        }
        #expect(g.message == .signalementEnAttente)
        #expect(await service.signalements.isEmpty)
        #expect(await cache.fileDeReprise().count == 1)
        // Au chargement suivant, le réseau est revenu : la file est rejouée, puis vidée.
        await service.regler(signalementEchoue: false)
        await g.actualiser()
        #expect(await service.signalements.count == 1)
        #expect(await cache.fileDeReprise().isEmpty)
    }

    @Test func horsLigneLaFileResteEtNeSeVidePas() async throws {
        let service = FauxServiceFeed(publications: jeu())
        let (g, cache) = try gestion(service: service)
        await g.actualiser()
        await service.regler(horsLigne: true)
        let p = try #require(g.etat(.amis).publications.first)
        _ = await g.signaler(p, motif: .spam)
        await g.actualiser()
        #expect(await cache.fileDeReprise().count == 1)
        #expect(g.message == .horsLigne)
    }

    @Test func signalerUnCommentaireJointSonTexte() async throws {
        let service = FauxServiceFeed(publications: jeu())
        let (g, _) = try gestion(service: service)
        await g.actualiser()
        let c = CommentaireFeed(id: "c1", publication: "a1", auteurNom: "p-lui", texte: "message gênant", creeLe: Date())
        let issue = await g.signaler(c, motif: .autre)
        #expect(issue.courriel?.absoluteString.contains("message%20g") == true)
        #expect(await service.signalements.first?.extrait == "message gênant")
    }

    // MARK: Blocage

    @Test func bloquerUnAuteurEnleveToutDeLui() async throws {
        let service = FauxServiceFeed(publications: jeu())
        let (g, cache) = try gestion(service: service)
        await g.actualiser()
        await g.bloquer("p-gros-brochet")
        for section in SectionFeed.allCases {
            #expect(!g.etat(section).publications.contains { $0.auteurNom == "p-gros-brochet" })
        }
        #expect(await cache.bloques().contains("p-gros-brochet"))
        #expect(await service.blocages == ["p-gros-brochet"])
        await g.actualiser()
        #expect(!g.etat(.amis).publications.contains { $0.auteurNom == "p-gros-brochet" })
    }

    @Test func leBlocageEcritEnBasePriveeEstReluAuDemarrage() async throws {
        // Réinstallation : cache vide, mais la base privée se souvient.
        let service = FauxServiceFeed(publications: jeu(), blocages: ["p-gros-brochet"])
        let (g, cache) = try gestion(service: service)
        await g.ouvrir()
        #expect(g.bloques.contains("p-gros-brochet"))
        #expect(await cache.bloques().contains("p-gros-brochet"))
        #expect(!g.etat(.amis).publications.contains { $0.auteurNom == "p-gros-brochet" })
    }

    @Test func unBlocageSeulLocalRemonteEnBasePrivee() async throws {
        let service = FauxServiceFeed(publications: jeu())
        let (g, cache) = try gestion(service: service)
        await cache.bloquer("p-hors-ligne")
        await g.ouvrir()
        #expect(await service.blocages.contains("p-hors-ligne"))
    }

    // MARK: Hors ligne, profil, effacement

    @Test func horsLigneLeDernierFilResteLisible() async throws {
        let service = FauxServiceFeed(publications: jeu())
        let (g, cache) = try gestion(service: service)
        await g.actualiser()
        #expect(!(await cache.lire(section: .clubs)).isEmpty)

        // Nouvelle session, mode avion.
        await service.regler(horsLigne: true)
        let g2 = GestionFeed(service: service, cache: cache, source: SourceContexteFausse())
        await g2.ouvrir()
        #expect(g2.etat(.clubs).publications.map(\.id) == ["a1"])
        #expect(g2.message == .horsLigne)
    }

    @Test func sansProfilQuinzeAnsLeFilEstEnLectureSeule() async throws {
        let (g, _) = try gestion(service: FauxServiceFeed(publications: jeu()), source: SourceContexteFausse(quinzeAns: false))
        await g.actualiser()
        #expect(!g.peutPublier)
        #expect(!g.etat(.region).publications.isEmpty)
        let p = try #require(g.etat(.clubs).publications.first)
        await g.basculerLike(p)
        #expect(g.message == .profilRequis)
        #expect(g.etat(.clubs).publications.first?.nbLikes == 0)
    }

    @Test func publierRefuseSansProfilQuinzeAnsMemeSiLEcranLaisserait() async throws {
        let (g, _) = try gestion(service: FauxServiceFeed(publications: jeu()), source: SourceContexteFausse(quinzeAns: false))
        await g.actualiser()
        let f = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        try Data([1]).write(to: f)
        let brouillon = BrouillonPublication(auteurNom: "p-moi", genre: .photo, fichierMedia: f, vignette: f, dureeS: 0, legende: "Salut",
                                             lieu: LieuChoisi(mode: .aucun, lieuTexte: "", departement: ""), carte: nil, club: "")
        await #expect(throws: ErreurFeed.refuse) { try await g.publier(brouillon) }
    }

    @Test func supprimerMonProfilEffaceMesContenus() async throws {
        let mes = DemoFeed.publication("m1", auteur: "p-moi", club: "club-1")
        let service = FauxServiceFeed(publications: jeu() + [mes])
        let (g, cache) = try gestion(service: service)
        await g.actualiser()
        try await g.effacerContenu(deProfil: "p-moi")
        #expect(await service.contenusEffaces == ["p-moi"])
        #expect(await service.publications.contains { $0.auteurNom == "p-moi" } == false)
        #expect((await cache.lire(section: .clubs)).isEmpty)
    }

    @Test func lEffaceurUtiliseLIdentifiantRecuEtLeveUneErreurSiRienNeSAppliquePas() async throws {
        let service = FauxServiceFeed(publications: jeu())
        let (g, _) = try gestion(service: service)
        try await EffaceurFeed(gestion: g).effacerContenu(deProfil: "p-autre")
        #expect(await service.contenusEffaces == ["p-autre"])

        let (sansProfil, _) = try gestion(service: FauxServiceFeed(), source: SourceContexteFausse(nom: nil))
        await #expect(throws: ErreurFeed.introuvable) { try await sansProfil.effacerContenu(deProfil: "") }

        // Réseau coupé : l'erreur remonte, le profil sera gardé par L21.
        await service.regler(horsLigne: true)
        await #expect(throws: ErreurFeed.reseau) { try await g.effacerContenu(deProfil: "p-autre") }
    }

    @Test func laLegendeAvecUnMotInterditEstRefuseALaSaisie() {
        let m = ModelePublication(auteurNom: "p-moi", contexteLieu: ContexteLieu(eauNom: "La Marne", planDEau: false, departement: "94"),
                                  clubs: [])
        m.legende = "quel connard"
        #expect(m.refus == .motInterdit)
        #expect(m.brouillon() == nil)
        m.legende = "belle prise"
        #expect(m.refus == nil)
    }

    @Test func parDefautLeLieuEstLeDepartementSeul() {
        let m = ModelePublication(auteurNom: "p-moi", contexteLieu: ContexteLieu(eauNom: "La Marne", planDEau: false, departement: "94"),
                                  clubs: [])
        #expect(m.mode == .departement)
        #expect(m.options.contains(.coursEau))
    }

    // MARK: Mode démo (fil d'exemple)

    @Test func sansCompteICloudLeFilMontreDesExemplesEnLectureSeule() async throws {
        let service = FauxServiceFeed(publications: jeu(), compte: false)
        let (g, cache) = try gestion(service: service, avecExemple: true)
        await g.actualiser()
        #expect(g.exemples)
        #expect(g.message == .modeExemple)
        for section in SectionFeed.allCases {
            let pubs = g.etat(section).publications
            #expect(!pubs.isEmpty)
            #expect(pubs.allSatisfy(\.exemple))
        }
        #expect(!g.peutPublier)
        // Lecture seule : un like n'écrit rien.
        let p = try #require(g.etat(.region).publications.first)
        await g.basculerLike(p)
        #expect(g.message == .modeExemple)
        #expect(await service.likesEcrits.isEmpty)
        // Signaler masque ici, n'écrit ni signalement ni cache.
        let issue = await g.signaler(p, motif: .spam)
        #expect(issue == .exemple)
        #expect(await service.signalements.isEmpty)
        #expect(await cache.masquees().isEmpty)
        #expect(!g.etat(.region).publications.contains { $0.id == p.id })
    }

    @Test func leModeDemoDeLAppMontreLesExemplesMemeAvecUnCompte() async throws {
        let (g, cache) = try gestion(service: FauxServiceFeed(publications: jeu()), source: SourceContexteFausse(demo: true), avecExemple: true)
        await g.actualiser()
        #expect(g.exemples)
        #expect(g.etat(.clubs).publications.allSatisfy(\.exemple))
        // Aucun exemple n'est gardé en cache.
        #expect((await cache.lire(section: .clubs)).isEmpty)
    }

    @Test func avecUnCompteEtSansModeDemoLeVraiFilReprendLaPlace() async throws {
        let service = FauxServiceFeed(publications: jeu(), compte: false)
        let (g, _) = try gestion(service: service, avecExemple: true)
        await g.actualiser()
        #expect(g.exemples)
        await service.regler(compte: true)
        await g.actualiser()
        #expect(!g.exemples)
        #expect(g.etat(.clubs).publications.map(\.id) == ["a1"])
        #expect(!g.etat(.clubs).publications.contains(where: \.exemple))
    }

    @Test func sansCompteNiExempleLeBandeauDitConnecteToiAICloud() async throws {
        let (g, _) = try gestion(service: FauxServiceFeed(publications: jeu(), compte: false))
        await g.actualiser()
        #expect(g.message == .iCloudIndisponible)
        #expect(!g.exemples)
    }

    @Test func leServiceDExempleNEcritRien() async throws {
        let s = ServiceFeedExemple()
        await #expect(throws: ErreurFeed.lectureSeule) { try await s.aimer(publication: "x", par: "p-moi") }
        await #expect(throws: ErreurFeed.lectureSeule) {
            try await s.signaler(SignalementFeed(cible: "x", typeCible: .publication, motif: .spam, signalePar: "p-moi", auteurCible: "p-y"))
        }
        let page = try await s.page(DemandeSection(section: .region, valeurs: ["exemple"]))
        #expect(page.publications.allSatisfy(\.exemple))
        #expect(page.publications.allSatisfy { !$0.legende.isEmpty && FiltreTexte.verifier($0.legende) == nil })
    }
}
