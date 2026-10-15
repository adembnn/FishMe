import Core
import Foundation
import Testing
@testable import BuildChallenge

@MainActor
struct OuChercherModeleTests {
    let position = Coordonnee(latitude: 48.82, longitude: 2.41)

    private func coin(_ id: String, d: Double, n: Int = 9, annee: Int = 2024, o: OuvertureDuJour = .ouverte, nom: String? = "Quai de Charenton",
                      type: TypeCoinPublic = .peche, acces: AccesCoinPublic? = .libre, payant: Bool = false) -> CoinProche {
        CoinProche(id: id, nom: nom, type: type, acces: acces, payant: payant, departement: Departement(code: "94"), coordonnee: position,
                   distanceM: d, codeStation: "S1", eauStation: "La Marne", distanceStationM: 430, nPeches: n, annee: annee, ouverture: o)
    }

    @Test func coinPublicTitreAccesEtStation() {
        let c = CompositeurCoins()
        let quai = c.coin(coin("node/1", d: 640, n: 4, annee: 2025))
        #expect(quai.id == "node/1" && quai.titre == "Quai de Charenton" && quai.acces == "Accès libre")
        #expect(quai.station == "Station OFB à proximité : La Marne, à 450 m")
        #expect(quai.releve == "4 pêches, dernier relevé 2025")
        #expect(quai.phraseVoixOff.contains("Relevée à proximité"))
        #expect(c.coin(coin("a", d: 100, nom: nil, type: .ponton, acces: .permis)).titre == "Ponton")
        #expect(c.coin(coin("a", d: 100, nom: nil, type: .acces, acces: nil)).acces == nil)
        #expect(c.coin(coin("a", d: 100, nom: nil, type: .acces, acces: nil)).titre == "Accès à l'eau")
        #expect(c.coin(coin("a", d: 100, payant: true)).acces == "Accès payant")
    }

    @Test func phraseDeReleveAvecNEtAnnee() {
        let c = CompositeurCoins()
        #expect(c.releveTexte(n: 9, annee: 2024) == "9 pêches, dernier relevé 2024")
        #expect(c.releveTexte(n: 1, annee: 2011) == "1 pêche, dernier relevé 2011")
    }

    @Test func auPlusTroisCoinsSansRemplissage() {
        let c = CompositeurCoins()
        let quatre = (1...4).map { coin("node/\($0)", d: Double($0) * 300) }
        #expect(c.afficher(quatre).map(\.id) == ["node/1", "node/2", "node/3"])
        #expect(c.afficher([coin("node/1", d: 100)]).count == 1)
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
        let c = CompositeurCoins().coin(coin("node/1", d: 500))
        let tout = [c.titre, c.distance, c.releve, c.ouverture, c.station, c.acces ?? "", c.phraseVoixOff, OuChercherTextes.explicationOrdre,
                    OuChercherTextes.sansRelevePres, OuChercherTextes.invite].joined(separator: " ").lowercased()
        for mot in ["meilleur", "garanti", "chances", "poké"] { #expect(!tout.contains(mot)) }
    }

    @Test func grilleMetLesEspecesProchesEnPremier() {
        let m = OuChercherModele(especes: CoinsFaux(), position: position)
        // Le faux rend brochet et perche comme espèces proches.
        #expect(Set(m.grille.prefix(2).map(\.id)) == ["brochet", "perche-commune"])
        #expect(m.grille.count == 6)
    }

    @Test func choisirUneEspeceDonneLesCoinsOuAucunReleve() {
        let m = OuChercherModele(especes: CoinsFaux(), position: position)
        m.choisir(m.grille[0])
        if case .resultats(_, let coins) = m.etat { #expect(coins.count == 1) } else { Issue.record("résultats attendus") }
        m.changerEspece()
        #expect(m.etat == .choixEspece)

        let vide = OuChercherModele(especes: SansCoins(), position: position)
        vide.choisir(vide.grille[0])
        if case .aucunReleve = vide.etat {} else { Issue.record("« aucun relevé » attendu") }
    }
}

private struct SansCoins: ServiceEspeces, ServiceCoinsPublics {
    private let base = CoinsFaux()
    func rarete(espece: Espece, departement: Departement) -> ResultatRarete { base.rarete(espece: espece, departement: departement) }
    func especesProches(_ c: Coordonnee) -> [EspeceProche] { base.especesProches(c) }
    func coins(ou espece: Espece, pres coordonnee: Coordonnee) -> [Coin] { [] }
    func especesPechables() -> [EspecePechable] { base.especesPechables() }
    func classer(scores: [String: Double], especesProches: [Espece]) -> [Proposition] { base.classer(scores: scores, especesProches: especesProches) }
    func poidsEstime(espece: Espece, longueurCm: Double) -> PoidsEstime? { base.poidsEstime(espece: espece, longueurCm: longueurCm) }
    func coinsProches(ou espece: Espece, pres coordonnee: Coordonnee) -> [CoinProche] { [] }
    func coinsPublicsDans(_ region: RegionCarte) -> [CoinPublic] { [] }
    func coinsPublics(pres coordonnee: Coordonnee, rayonM: Double) -> [CoinPublic] { [] }
}
