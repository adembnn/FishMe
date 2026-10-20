import Foundation
import Testing
@testable import Core

@Suite("Sauvegarde iCloud : fusion entre deux iPhones")
struct FusionSauvegardeTests {
    private let a = UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!
    private let b = UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!
    private let c = UUID(uuidString: "00000000-0000-0000-0000-00000000000C")!

    private func sortie(_ id: UUID, jour: Double) -> Sortie {
        Sortie(id: id, debut: Date(timeIntervalSince1970: jour * 86_400))
    }

    @Test("Nouvel iPhone : tout ce qui est dans iCloud revient, rien n'est envoyé")
    func nouvelIPhone() {
        let plan = FusionSauvegarde.plan(locaux: [], distants: [a, b])
        #expect(plan.aEnvoyer.isEmpty)
        #expect(plan.aRapatrier == [a, b])
    }

    @Test("Deux iPhones : chacun reçoit ce qui lui manque, rien ne s'efface")
    func deuxIPhones() {
        let plan = FusionSauvegarde.plan(locaux: [a, b], distants: [b, c])
        #expect(plan.aEnvoyer == [a])
        #expect(plan.aRapatrier == [c])
    }

    @Test("Profil vide d'un iPhone neuf : le profil iCloud gagne en entier")
    func profilNeuf() {
        let distant = ProfilSauvegarde(niveau: "confirme", questionVue: true, tunnelVu: true,
                                       sorties: [sortie(a, jour: 1)], sessionsTerminees: 3, modifie: Date(timeIntervalSince1970: 10))
        #expect(FusionSauvegarde.fusionner(local: ProfilSauvegarde(), distant: distant) == distant)
    }

    @Test("Sorties réunies sans doublon, compteur de sessions qui ne recule jamais")
    func sortiesEtCompteur() {
        let local = ProfilSauvegarde(niveau: "debutant", questionVue: true, sorties: [sortie(a, jour: 2), sortie(b, jour: 3)],
                                     sessionsTerminees: 2, modifie: Date(timeIntervalSince1970: 50))
        let distant = ProfilSauvegarde(niveau: "confirme", tunnelVu: true, sorties: [sortie(b, jour: 3), sortie(c, jour: 1)],
                                       sessionsTerminees: 5, modifie: Date(timeIntervalSince1970: 20))
        let f = FusionSauvegarde.fusionner(local: local, distant: distant)
        #expect(f.sorties.map(\.id) == [c, a, b])
        #expect(f.sessionsTerminees == 5)
        #expect(f.questionVue && f.tunnelVu)
        #expect(f.niveau == "debutant")
        #expect(f.modifie == Date(timeIntervalSince1970: 50))
    }

    @Test("Le compteur vaut au moins le nombre de sorties connues")
    func compteurAuMoinsLesSorties() {
        let local = ProfilSauvegarde(sorties: [sortie(a, jour: 1)], sessionsTerminees: 1)
        let distant = ProfilSauvegarde(sorties: [sortie(b, jour: 2)], sessionsTerminees: 1)
        #expect(FusionSauvegarde.fusionner(local: local, distant: distant).sessionsTerminees == 2)
    }

    @Test("Le profil s'encode et se relit à l'identique")
    func allerRetour() throws {
        let p = ProfilSauvegarde(niveau: "occasionnel", clubs: Data("[]".utf8), sorties: [sortie(a, jour: 4)],
                                 sessionsTerminees: 1, modifie: Date(timeIntervalSince1970: 99))
        let relu = try JSONDecoder().decode(ProfilSauvegarde.self, from: JSONEncoder().encode(p))
        #expect(relu == p)
    }

    // MARK: envies

    private func envie(_ id: String, jour: Double, retiree: Double? = nil) -> Envie {
        Envie(espece: id, ajoutee: Date(timeIntervalSince1970: jour * 86_400),
              retiree: retiree.map { Date(timeIntervalSince1970: $0 * 86_400) },
              motif: retiree == nil ? nil : .retireeParLePecheur)
    }

    @Test("Un profil qui n'a que des envies n'est pas vide")
    func profilAvecEnviesNEstPasVide() {
        #expect(ProfilSauvegarde().estVide)
        #expect(!ProfilSauvegarde(envies: [envie("brochet", jour: 1)]).estVide)
    }

    @Test("Une sauvegarde sans champ envies se lit comme une liste vide")
    func decodeurTolerant() throws {
        let json = """
        {"questionVue":true,"tunnelVu":false,"sorties":[],"sessionsTerminees":4,"modifie":0}
        """
        let p = try JSONDecoder().decode(ProfilSauvegarde.self, from: Data(json.utf8))
        #expect(p.envies.isEmpty)
        #expect(p.sessionsTerminees == 4)
        #expect(p.questionVue)
    }

    @Test("Aller-retour JSON avec des envies")
    func allerRetourEnvies() throws {
        let p = ProfilSauvegarde(questionVue: true, envies: [envie("brochet", jour: 1), envie("sandre", jour: 2, retiree: 3)],
                                 modifie: Date(timeIntervalSince1970: 99))
        let relu = try JSONDecoder().decode(ProfilSauvegarde.self, from: JSONEncoder().encode(p))
        #expect(relu == p)
    }

    @Test("Fusion : les envies des deux iPhones sont réunies, la modification la plus récente gagne")
    func fusionDesEnvies() {
        let local = ProfilSauvegarde(questionVue: true, envies: [envie("brochet", jour: 1), envie("perche", jour: 2)],
                                     modifie: Date(timeIntervalSince1970: 50))
        let distant = ProfilSauvegarde(tunnelVu: true, envies: [envie("brochet", jour: 1, retiree: 5), envie("sandre", jour: 3)],
                                       modifie: Date(timeIntervalSince1970: 40))
        let fusion = FusionSauvegarde.fusionner(local: local, distant: distant)
        let attendu = ListeEnvies.fusionner(local.envies, distant.envies).envies
        #expect(fusion.envies == attendu)
        #expect(Set(fusion.envies.map(\.espece)) == ["brochet", "perche", "sandre"])
        #expect(fusion.envies.first { $0.espece == "brochet" }?.retiree != nil)
        let inverse = FusionSauvegarde.fusionner(local: distant, distant: local)
        #expect(inverse.envies == fusion.envies)
    }

    @Test("Profil local sans rien d'autre que des envies : il ne perd pas face à iCloud")
    func localAvecEnviesSeules() {
        let local = ProfilSauvegarde(envies: [envie("brochet", jour: 1)])
        let distant = ProfilSauvegarde(niveau: "confirme", questionVue: true, modifie: Date(timeIntervalSince1970: 10))
        let fusion = FusionSauvegarde.fusionner(local: local, distant: distant)
        #expect(fusion.envies.map(\.espece) == ["brochet"])
        #expect(fusion.niveau == "confirme")
    }
}
