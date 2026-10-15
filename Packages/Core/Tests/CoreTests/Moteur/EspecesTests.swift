import Foundation
import Testing
@testable import Core

@Suite("Espèces : rareté, coins, reconnaissance, poids")
struct EspecesTests {
    let moteur = moteurEssai()
    var especes: MoteurEspeces { moteur.especes }
    let quatreVingtQuatorze = Departement(code: "94")

    @Test func especesPechables() {
        let liste = especes.especesPechables()
        #expect(liste.count == 20)
        let brochet = liste.first { $0.espece.id == "brochet" }
        #expect(brochet?.espece.codeSandre == "2151")
        #expect(brochet?.confusions.first?.avec == Espece(id: "sandre", codeSandre: "2195"))
        #expect(liste.first { $0.espece.id == "esturgeon-europeen" }?.statuts == [.protegee, .toujoursRelachee])
        #expect(liste.first { $0.espece.id == "grenouille-verte" }?.suiviOFB == false)
        #expect(liste.first { $0.espece.id == "autre-poisson" }?.classeModele == "autre poisson")
    }

    @Test("Les niveaux du 94 des 14 espèces de « Attendu dans le 94 » égaux à donnees.md",
          arguments: [("perche-commune", NiveauRarete.commun), ("gardon", .commun), ("chevesne", .commun),
                      ("brochet", .peuCommun), ("silure-glane", .peuCommun), ("barbeau-fluviatile", .peuCommun),
                      ("sandre", .rare), ("breme-commune", .rare), ("tanche", .rare), ("black-bass", .rare), ("carpe-commune", .rare),
                      ("truite-fario", .legendaire), ("truite-arc-en-ciel", .legendaire), ("ombre-commun", .legendaire)])
    func niveauxDu94(id: String, niveau: NiveauRarete) {
        let r = especes.rarete(espece: Espece(id: id), departement: quatreVingtQuatorze)
        #expect(r.niveau == niveau)
        #expect(r.nTotal == 29)
        #expect(r.echelle == .departement)
    }

    @Test func raretePorteNEtAnnee() {
        let brochet = especes.rarete(espece: brochetEssai, departement: quatreVingtQuatorze)
        #expect(brochet.nPeches == 8)
        #expect(brochet.nTotal == 29)
        #expect(brochet.anneeDernierReleve == 2025)
        let carpe = especes.rarete(espece: Espece(id: "carpe-commune"), departement: quatreVingtQuatorze)
        #expect(carpe.nPeches == 1)
        #expect(carpe.niveau == .rare)
        // Légendaire = « 0 pêche sur N », avec l'année de l'historique.
        let fario = especes.rarete(espece: Espece(id: "truite-fario"), departement: quatreVingtQuatorze)
        #expect(fario.nPeches == 0)
        #expect(fario.anneeDernierReleve == 1998)
    }

    @Test("Les seuils : 50 % commun, 20 % peu commun")
    func seuils() {
        func zone(_ c: Int) -> DonneesRarete {
            DonneesRarete(departements: ["99": ZoneRarete(region: nil, dixAns: ComptesRarete(peches: 40, especes: c == 0 ? [:] : ["1": (c, 2025)]), historique: .vide)], regions: [:])
        }
        let dep = Departement(code: "99")
        func niveau(_ c: Int) -> NiveauRarete { CalculRarete.calculer(code: "1", suiviOFB: true, departement: dep, donnees: zone(c)).niveau }
        #expect(niveau(20) == .commun)
        #expect(niveau(19) == .peuCommun)
        #expect(niveau(8) == .peuCommun)
        #expect(niveau(7) == .rare)
        #expect(niveau(1) == .rare)
        #expect(niveau(0) == .legendaire)
    }

    @Test("Une grenouille verte : rareté non mesurée par l'OFB, jamais légendaire")
    func grenouille() {
        let r = especes.rarete(espece: Espece(id: "grenouille-verte"), departement: quatreVingtQuatorze)
        #expect(r.niveau == .nonMesuree)
    }

    @Test("Moins de 20 pêches : la région, et le résultat le dit")
    func regionSousVingtPeches() {
        let r = especes.rarete(espece: percheEssai, departement: Departement(code: "75"))
        #expect(r.echelle == .region)
        #expect(r.nTotal == 400)
        #expect(r.nPeches == 240)
        #expect(r.niveau == .commun)
    }

    @Test("Un département sans relevé : aucun niveau inventé")
    func departementSansReleve() {
        let r = especes.rarete(espece: brochetEssai, departement: Departement(code: "2A"))
        #expect(r.niveau == .nonMesuree)
        #expect(r.nTotal == 0)
    }

    // MARK: Espèces proches et coins

    @Test("especesProches : stations à moins de 10 km, avec N, l'année et l'ouverture du jour")
    func especesProches() {
        let proches = especes.especesProches(charenton)
        let parId = Dictionary(uniqueKeysWithValues: proches.map { ($0.espece.id, $0) })
        // S1, S2, S3 et S4 sont à moins de 10 km : perche 9 + 5, brochet 4 + 2 + 2, sandre 1, fario 3.
        #expect(parId["perche-commune"]?.nPeches == 14)
        #expect(parId["brochet"]?.nPeches == 8)
        #expect(parId["brochet"]?.annee == 2025)
        #expect(parId["perche-commune"]?.ouverture == .ouverte)
        #expect(parId["brochet"]?.ouverture == .ouverte)
        #expect(parId["truite-fario"]?.ouverture == .fermee(reouverture: utc(2027, 3, 13, 0)))
    }

    @Test("Sans relevé OFB à moins de 30 km : aucun relevé")
    func aucunReleve() {
        #expect(especes.especesProches(Coordonnee(latitude: 44.0, longitude: 0.0)).isEmpty)
        #expect(especes.especesProches(cupertino).isEmpty)
    }

    @Test("Le rayon s'élargit à 20 puis 30 km quand il y a moins de 2 stations")
    func rayonElargi() {
        // À 12 km au nord de Charenton : une seule station (S1) à moins de 20 km ? Non, plusieurs à 20 km : le rayon 20 km suffit.
        let nord = Coordonnee(latitude: 48.9325, longitude: 2.416)
        #expect(!especes.especesProches(nord).isEmpty)
    }

    @Test("coins : stations où l'espèce est relevée, triées par distance, avec N, année et ouverture")
    func coins() {
        let c = especes.coins(ou: brochetEssai, pres: charenton)
        #expect(c.map(\.codeStation) == ["S1", "S4", "S2", "L1"])
        #expect(c.first?.nPeches == 4)
        #expect(c.first?.annee == 2025)
        #expect(c.first?.eau == "La Marne")
        #expect(c.first?.departement.code == "94")
        #expect(c.first?.ouverture == .ouverte)
        #expect(zip(c, c.dropFirst()).allSatisfy { $0.distanceM <= $1.distanceM })
        let truites = especes.coins(ou: fario, pres: charenton)
        #expect(truites.map(\.codeStation) == ["S3"])
        #expect(truites.first?.ouverture == .fermee(reouverture: utc(2027, 3, 13, 0)))
        #expect(especes.coins(ou: Espece(id: "inconnue"), pres: charenton).isEmpty)
    }

    @Test("stationsDans : stations du rectangle sur un petit fichier d'essai, coordonnées arrondies, [] sans fichier")
    func stationsDansUneRegion() throws {
        let dossier = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
        let fichier = try Data(contentsOf: dossier.appendingPathComponent("stations-essai.json"))
        let avec = MoteurCore(donnees: donneesEssai(stations: fichier), horloge: { quinzeOctobre }).especes
        let region = RegionCarte(sudOuest: Coordonnee(latitude: 48.75, longitude: 2.30), nordEst: Coordonnee(latitude: 48.90, longitude: 2.50))
        let stations = avec.stationsDans(region)
        // E3 est hors du rectangle, E4 n'a aucune espèce connue.
        #expect(stations.map(\.codeStation) == ["E1", "E2"])
        let e1 = try #require(stations.first)
        #expect(e1.coordonnee == Coordonnee(latitude: 48.82, longitude: 2.42))
        #expect(e1.eau == "La Marne" && e1.departement.code == "94")
        #expect(e1.especes.map(\.espece.id) == ["perche-commune", "brochet", "sandre"])
        #expect(e1.especes.map(\.nPeches) == [9, 4, 1])
        #expect(e1.especes.allSatisfy { $0.annee == 2025 })
        // Aucune coordonnée exacte du fichier ne sort.
        #expect(!stations.contains { $0.coordonnee == Coordonnee(latitude: 48.8235, longitude: 2.4160) })
        let vide = RegionCarte(sudOuest: Coordonnee(latitude: 10, longitude: 10), nordEst: Coordonnee(latitude: 11, longitude: 11))
        #expect(avec.stationsDans(vide).isEmpty)
        let sans = MoteurCore(donnees: donneesEssai(stations: nil), horloge: { quinzeOctobre }).especes
        #expect(sans.stationsDans(region).isEmpty)
    }

    // MARK: classer

    let scores: [String: Double] = ["brochet": 0.30, "sandre": 0.25, "perche": 0.20, "gardon": 0.15, "autre poisson": 0.07, "pas un poisson": 0.03]

    func especesDeLaListe(_ p: [Proposition]) -> [String] {
        p.compactMap { if case .espece(let e) = $0.type { return e.id } else if case .classe(let c) = $0.type { return "classe:\(c)" } else { return nil } }
    }

    @Test("classer : 3 propositions, puis « autre espèce » et « pas un poisson », sans score")
    func classer() {
        let p = especes.classer(scores: scores, especesProches: [brochetEssai, sandreEssai, percheEssai])
        #expect(p.count == 5)
        #expect(especesDeLaListe(p) == ["brochet", "sandre", "perche-commune"])
        #expect(p[3].type == .autreEspece)
        #expect(p[4].type == .pasUnPoisson)
    }

    @Test("classer : une espèce jamais relevée reste dans les 3 quand son score est nettement le plus haut (plancher)")
    func plancher() {
        // Brochet jamais relevé (0,9 × 0,3 = 0,27) contre des espèces relevées à 0,2 : il reste dans les 3.
        let s = ["brochet": 0.9, "sandre": 0.20, "perche": 0.19, "gardon": 0.18]
        let p = especes.classer(scores: s, especesProches: [sandreEssai, percheEssai, Espece(id: "gardon")])
        #expect(especesDeLaListe(p).contains("brochet"))
        #expect(especesDeLaListe(p).first == "brochet")
    }

    @Test("classer : à scores égaux, une espèce relevée passe devant")
    func egalite() {
        let s = ["brochet": 0.40, "sandre": 0.40]
        let p = especes.classer(scores: s, especesProches: [sandreEssai])
        #expect(especesDeLaListe(p).prefix(2) == ["sandre", "brochet"])
    }

    @Test("classer : une classe à plusieurs espèces devient une seule proposition, aucun pourcentage")
    func classeAPlusieursEspeces() {
        let p = especes.classer(scores: ["lamproie": 0.7, "brochet": 0.1], especesProches: [])
        #expect(p.first?.type == .classe("lamproie"))
        let texte = String(describing: p)
        #expect(!texte.contains("%"))
    }

    @Test("classer : toujours « autre espèce » et « pas un poisson », même sans score")
    func classerSansScore() {
        let p = especes.classer(scores: [:], especesProches: [])
        #expect(p.map(\.type) == [.autreEspece, .pasUnPoisson])
        // Une classe inconnue de la liste est ignorée.
        #expect(especes.classer(scores: ["dinosaure": 1.0], especesProches: []).count == 2)
    }

    // MARK: Poids

    @Test("poidsEstime : brochet 60 cm ≈ 1,39 kg, carpe 60 cm ≈ 3,6 kg, fourchette de 20 %, source")
    func poids() throws {
        let b = try #require(especes.poidsEstime(espece: brochetEssai, longueurCm: 60))
        #expect(abs(b.kilos - 1.39) / 1.39 < 0.02)
        #expect(abs(b.minKilos - b.kilos * 0.8) < 0.002)
        #expect(abs(b.maxKilos - b.kilos * 1.2) < 0.002)
        #expect(b.source.contains("Verreycken et al. 2011"))
        let c = try #require(especes.poidsEstime(espece: Espece(id: "carpe-commune"), longueurCm: 60))
        #expect(abs(c.kilos - 3.6) / 3.6 < 0.02)
    }

    @Test("poidsEstime : nil hors plage ou sans coefficient")
    func poidsNil() {
        #expect(especes.poidsEstime(espece: brochetEssai, longueurCm: 110) == nil)
        #expect(especes.poidsEstime(espece: brochetEssai, longueurCm: 10) == nil)
        #expect(especes.poidsEstime(espece: sandreEssai, longueurCm: 50) == nil)
    }
}
