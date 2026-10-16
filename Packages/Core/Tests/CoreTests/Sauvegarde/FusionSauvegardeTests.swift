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
}
