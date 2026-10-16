import Testing
import Core
@testable import BuildChallenge

@MainActor
struct NomDeZoneTests {
    @Test func sansDepartementOuInconnuAucunNom() {
        #expect(NomDeZone.texte(departement: nil) == nil)
        #expect(NomDeZone.texte(departement: .inconnu) == nil)
    }

    @Test func unDepartementConnuDonneSonNom() {
        #expect(NomDeZone.texte(departement: Departement(code: "87")) == "Département 87")
    }
}
