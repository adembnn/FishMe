import Core
import Foundation
import Testing
@testable import BuildChallenge

@MainActor
struct TextesDebutantTests {
    @Test func releveAccordeLePluriel() {
        #expect(texteReleve(nPeches: 1, annee: 2024) == "1 pêche, dernier relevé 2024")
        #expect(texteReleve(nPeches: 7, annee: 2024) == "7 pêches, dernier relevé 2024")
        #expect(texteReleve(nPeches: 3, annee: nil) == "3 pêches")
    }

    @Test func sigleOFBEstExplique() {
        #expect(TexteOFB.explication.contains("Office français de la biodiversité"))
        #expect(TexteOFB.nomComplet.contains("(OFB)"))
    }

    @Test func categorieInconnueADesMots() {
        #expect(TexteCategorie.libelle(.inconnue) == "catégorie inconnue")
        #expect(TexteCategorie.libelle(.premiere) == "1re catégorie")
        #expect(TexteCategorie.aide.contains("truites"))
        #expect(TexteCategorie.aide.contains("carnassiers"))
    }

    @Test func pescedexSansCarteEstVide() {
        #expect(PescedexVide.estVide([]))
        #expect(PescedexVide.texte == "Ta première prise ouvrira ton Pescedex")
    }

    @Test func niveauParDefautEstDebutant() {
        #expect(NiveauPecheur.parDefaut == .debutant)
    }
}
