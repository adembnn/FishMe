import Foundation
import Testing
@testable import Core

@Suite("Noms d'espèces dans les deux langues")
struct NomsEspecesTests {
    @Test("Chaque espèce du catalogue français a un nom anglais, différent d'un nom vide")
    func catalogueComplet() throws {
        let data = try #require(Ressources.donnees("especes"))
        let liste = EspecePechable.decoder(data)
        #expect(liste.count >= 99)
        for e in liste {
            let en = NomsEspeces.nom(id: e.espece.id, langue: .en, defaut: "")
            #expect(!en.isEmpty, "pas de nom anglais pour \(e.espece.id)")
        }
    }

    @Test("Noms d'usage connus")
    func nomsConnus() {
        #expect(NomsEspeces.nom(id: "brochet", langue: .en, defaut: "") == "Northern pike")
        #expect(NomsEspeces.nom(id: "sandre", langue: .en, defaut: "") == "Zander")
        #expect(NomsEspeces.nom(id: "perche-commune", langue: .en, defaut: "") == "European perch")
        #expect(NomsEspeces.nom(id: "walleye", langue: .fr, defaut: "") == "Doré jaune")
        #expect(NomsEspeces.nom(id: "muskellunge", langue: .fr, defaut: "") == "Maskinongé")
        #expect(NomsEspeces.nom(id: "inconnu", langue: .fr, defaut: "Reste") == "Reste")
    }
}
