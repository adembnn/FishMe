import Core
import Foundation
import Testing
@testable import BuildChallenge

@MainActor
struct OuChercherModeleTests {
    let position = Coordonnee(latitude: 48.82, longitude: 2.41)

    private func coin(_ code: String, d: Double, n: Int = 9, annee: Int = 2024, o: OuvertureDuJour = .ouverte) -> Coin {
        Coin(codeStation: code, eau: "La Marne", departement: Departement(code: "94"),
             coordonnee: position, distanceM: d, nPeches: n, annee: annee, ouverture: o)
    }

    @Test func phraseDeReleveAvecNEtAnnee() {
        let c = CompositeurCoins()
        #expect(c.releveTexte(n: 9, annee: 2024) == "9 pêches, dernier relevé 2024")
        #expect(c.releveTexte(n: 1, annee: 2011) == "1 pêche, dernier relevé 2011")
    }

    @Test func auPlusTroisCoinsSansRemplissage() {
        let c = CompositeurCoins()
        let quatre = (1...4).map { coin("S\($0)", d: Double($0) * 300) }
        #expect(c.afficher(quatre).map(\.id) == ["S1", "S2", "S3"])
        #expect(c.afficher([coin("S1", d: 100)]).count == 1)
        #expect(c.afficher([]).isEmpty)
    }

    @Test func ouverteAujourdhui() {
        let (texte, ouvert) = CompositeurCoins().ouvertureTexte(.ouverte)
        #expect(texte == "Ouverte aujourd'hui" && ouvert)
    }

    @Test func fermeeAvecDateDeReouverture() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Paris")!
        let date = cal.date(from: DateComponents(year: 2027, month: 3, day: 15, hour: 12))!
        let (texte, ouvert) = CompositeurCoins().ouvertureTexte(.fermee(reouverture: date))
        #expect(texte == "Fermée jusqu'au 15 mars" && !ouvert)
        #expect(CompositeurCoins().ouvertureTexte(.fermee(reouverture: nil)).0 == "Fermée")
    }

    @Test func distanceArrondie() {
        let c = CompositeurCoins()
        #expect(c.distanceTexte(metres: 1200) == "1,2 km")
        #expect(c.distanceTexte(metres: 430) == "450 m")
    }

    @Test func aucunMotInterdit() {
        let c = CompositeurCoins().coin(coin("S1", d: 500))
        let tout = [c.titre, c.distance, c.releve, c.ouverture, c.phraseVoixOff, OuChercherTextes.explicationOrdre,
                    OuChercherTextes.sansRelevePres, OuChercherTextes.invite].joined(separator: " ").lowercased()
        for mot in ["meilleur", "garanti", "chances", "poké"] { #expect(!tout.contains(mot)) }
    }

    @Test func grilleMetLesEspecesProchesEnPremier() {
        let m = OuChercherModele(especes: EspecesFaux(), position: position)
        // Le faux rend brochet et perche comme espèces proches.
        #expect(Set(m.grille.prefix(2).map(\.id)) == ["brochet", "perche-commune"])
        #expect(m.grille.count == 6)
    }

    @Test func choisirUneEspeceDonneLesCoinsOuAucunReleve() {
        let m = OuChercherModele(especes: EspecesFaux(), position: position)
        m.choisir(m.grille[0])
        if case .resultats(_, let coins) = m.etat { #expect(coins.count == 1) } else { Issue.record("résultats attendus") }
        m.changerEspece()
        #expect(m.etat == .choixEspece)

        let vide = OuChercherModele(especes: SansCoins(), position: position)
        vide.choisir(vide.grille[0])
        if case .aucunReleve = vide.etat {} else { Issue.record("« aucun relevé » attendu") }
    }
}

private struct SansCoins: ServiceEspeces {
    private let base = EspecesFaux()
    func rarete(espece: Espece, departement: Departement) -> ResultatRarete { base.rarete(espece: espece, departement: departement) }
    func especesProches(_ c: Coordonnee) -> [EspeceProche] { base.especesProches(c) }
    func coins(ou espece: Espece, pres coordonnee: Coordonnee) -> [Coin] { [] }
    func especesPechables() -> [EspecePechable] { base.especesPechables() }
    func classer(scores: [String: Double], especesProches: [Espece]) -> [Proposition] { base.classer(scores: scores, especesProches: especesProches) }
    func poidsEstime(espece: Espece, longueurCm: Double) -> PoidsEstime? { base.poidsEstime(espece: espece, longueurCm: longueurCm) }
}
