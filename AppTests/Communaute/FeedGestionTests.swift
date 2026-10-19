import Core
import Foundation
import Testing
@testable import BuildChallenge

// Tests du lot L23 (gestion du fil). Écrits sans compilateur : non exécutés à ce jour.

@MainActor
struct FeedGestionTests {
    private func gestion(service: FauxServiceFeed, source: SourceContexteFausse = SourceContexteFausse()) throws -> (GestionFeed, CacheFeed) {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = CacheFeed(conteneur: try CacheFeed.creerConteneur(enMemoire: true), dossierImages: dossier)
        return (GestionFeed(service: service, cache: cache, source: source), cache)
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

    @Test func signalerMasqueTout_de_suiteEtEcritLeSignalement() async throws {
        let service = FauxServiceFeed(publications: jeu())
        let (g, cache) = try gestion(service: service)
        await g.actualiser()
        let p = try #require(g.etat(.amis).publications.first)
        let url = await g.signaler(p, motif: .spam)
        #expect(url?.absoluteString.contains("fishme.app@gmail.com") == true)
        #expect(url?.absoluteString.contains(p.id) == true)
        #expect(g.etat(.amis).publications.isEmpty)
        #expect(await cache.masquees().contains(p.id))
        #expect(await service.signalements.count == 1)
        // Une nouvelle lecture ne la remet pas.
        await g.actualiser()
        #expect(!g.etat(.clubs).publications.map(\.id).contains(p.id))
    }

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

    @Test func supprimerMonProfilEffaceMesContenus() async throws {
        let mes = DemoFeed.publication("m1", auteur: "p-moi", club: "club-1")
        let service = FauxServiceFeed(publications: jeu() + [mes])
        let (g, cache) = try gestion(service: service)
        await g.actualiser()
        try await g.effacerMesContenus()
        #expect(await service.contenusEffaces == ["p-moi"])
        #expect(await service.publications.contains { $0.auteurNom == "p-moi" } == false)
        #expect((await cache.lire(section: .clubs)).isEmpty)
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
}
