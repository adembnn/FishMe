import Foundation
import Testing
@testable import Core

/// Coins publics OpenStreetMap (L7) : lecture tolérante, liaison à la station OFB, tri par distance. Jeux d'essai simplifiés.
let coinsOSMEssai: Data = {
    func p(_ id: String, _ type: String, _ lat: Double, _ lon: Double, dep: String, nom: String? = nil, acces: Any? = nil, payant: Bool? = nil,
           geometrie: String = "Point") -> [String: Any] {
        var props: [String: Any] = ["id": id, "type": type, "dep": dep]
        if let nom { props["nom"] = nom }
        if let acces { props["acces"] = acces }
        if let payant { props["payant"] = payant }
        return ["type": "Feature", "properties": props, "geometry": ["type": geometrie, "coordinates": [lon, lat]]]
    }
    return geoJSON([
        p("node/1", "peche", 48.825, 2.410, dep: "94", nom: "Quai de Charenton", acces: "libre"),
        p("node/2", "ponton", 48.801, 2.451, dep: "94", acces: "permis", payant: true),
        p("way/3", "peche", 46.001, 5.001, dep: "01", nom: "Étang de l'Ain"),
        p("node/4", "peche", 48.70, 2.60, dep: "94", nom: "Loin de tout relevé"),
        p("node/5", "peche", 48.8236, 2.4161, dep: "94", nom: "Coin privé", acces: "prive"),
        p("node/6", "decharge", 48.8236, 2.4161, dep: "94"),
        p("node/7", "acces", 48.762, 2.401, dep: "94", nom: "Accès du Morbras", acces: "libre"),
        p("node/8", "peche", 48.8236, 2.4161, dep: "94", geometrie: "LineString"),
        p("node/1", "peche", 48.9, 2.4, dep: "94", nom: "Doublon"),
        p("node/9", "peche", 95, 2.4, dep: "94", nom: "Latitude folle"),
    ])
}()

func moteurAvecCoins(_ coins: Data?, horloge: Date = quinzeOctobre) -> MoteurCoins {
    MoteurCore(donnees: donneesEssai(), horloge: { horloge }).coins(donneesOSM: coins)
}

@Suite("Coins publics OpenStreetMap")
struct CoinsTests {
    @Test("Décodage : les points publics valides seulement, sans privé, sans doublon")
    func decodage() {
        let c = CoinOSM.decoder(coinsOSMEssai)
        #expect(c.map(\.id) == ["node/1", "node/2", "way/3", "node/4", "node/7"])
        #expect(c[0].nom == "Quai de Charenton" && c[0].acces == .libre && c[0].type == .peche && !c[0].payant)
        #expect(c[1].type == .ponton && c[1].acces == .permis && c[1].payant && c[1].nom == nil)
        #expect(c[2].acces == nil)
    }

    @Test("Décodage tolérant : fichier vide, absent, illisible, sans features")
    func decodageTolerant() {
        #expect(CoinOSM.decoder(nil).isEmpty)
        #expect(CoinOSM.decoder(Data()).isEmpty)
        #expect(CoinOSM.decoder(Data("pas du json".utf8)).isEmpty)
        #expect(CoinOSM.decoder(Data(#"{"type":"FeatureCollection","features":[]}"#.utf8)).isEmpty)
        #expect(CoinOSM.decoder(Data(#"{"type":"FeatureCollection"}"#.utf8)).isEmpty)
    }

    @Test("Fichier vide : coins(ou:pres:) reste sur les stations OFB, comme avant")
    func fichierVideRepliSurStations() {
        let vide = Data(#"{"type":"FeatureCollection","features":[]}"#.utf8)
        for source in [vide, nil] as [Data?] {
            let c = moteurAvecCoins(source).coins(ou: brochetEssai, pres: charenton)
            #expect(c.map(\.codeStation) == ["S1", "S4", "S2", "L1"])
            #expect(c.count == 4)
        }
    }

    @Test("Avec des coins : seulement des coins OSM, triés par distance, reliés à la station OFB la plus proche")
    func coinsReliesAuxStations() {
        let c = moteurAvecCoins(coinsOSMEssai).coinsProches(ou: brochetEssai, pres: charenton)
        // node/4 est à plus de 5 km de toute station : omis. Aucune station seule n'est rendue.
        #expect(c.map(\.id) == ["node/1", "node/2", "way/3"])
        #expect(zip(c, c.dropFirst()).allSatisfy { $0.distanceM <= $1.distanceM })
        let premier = c[0]
        #expect(premier.nom == "Quai de Charenton" && premier.type == .peche && premier.acces == .libre)
        #expect(premier.codeStation == "S1" && premier.eauStation == "La Marne" && premier.nPeches == 4 && premier.annee == 2025)
        #expect(premier.departement.code == "94" && premier.ouverture == .ouverte)
        #expect(premier.distanceStationM > 0 && premier.distanceStationM < MoteurCoins.rayonStationM)
        #expect(c[1].codeStation == "S2" && c[1].nPeches == 2 && c[1].annee == 2024 && c[1].payant && c[1].nom == nil)
        #expect(c[2].codeStation == "L1" && c[2].departement.code == "01")
    }

    @Test("ServiceEspeces : avec des coins, coins(ou:pres:) rend des coins OSM nommés ; sans, les stations")
    func contratEspeces() {
        let c = moteurAvecCoins(coinsOSMEssai).coins(ou: brochetEssai, pres: charenton)
        #expect(c.map(\.codeStation) == ["S1", "S2", "L1"])
        #expect(c.first?.eau == "Quai de Charenton" && c[1].eau == "La Marne")
        #expect(c.first?.nPeches == 4 && c.first?.annee == 2025)
        #expect(zip(c, c.dropFirst()).allSatisfy { $0.distanceM <= $1.distanceM })
        #expect(moteurAvecCoins(nil).especesPechables().count == 20)
    }

    @Test("Un coin est relié à une station où l'espèce a été vue, pas à la plus proche tout court")
    func stationDeLEspece() {
        // Le sandre n'est relevé qu'en S1 : node/2, collé à S2 (sans sandre), est relié à S1 à 3,6 km ; way/3 est trop loin de S1.
        let sandre = moteurAvecCoins(coinsOSMEssai).coinsProches(ou: sandreEssai, pres: charenton)
        #expect(sandre.map(\.id) == ["node/1", "node/2"])
        #expect(sandre.allSatisfy { $0.codeStation == "S1" && $0.nPeches == 1 })
    }

    @Test("Espèce fermée ce jour-là : « fermée » avec la date de réouverture de Core")
    func especeFermee() {
        let c = moteurAvecCoins(coinsOSMEssai).coinsProches(ou: fario, pres: charenton)
        #expect(c.map(\.id) == ["node/7"])
        #expect(c.first?.ouverture == .fermee(reouverture: utc(2027, 3, 13, 0)))
    }

    @Test("Espèce sans relevé à proximité d'un coin, ou inconnue : aucun coin inventé")
    func sansReleve() {
        let m = moteurAvecCoins(coinsOSMEssai)
        #expect(m.coinsProches(ou: blackBassEssai, pres: charenton).isEmpty)
        #expect(m.coinsProches(ou: Espece(id: "inconnue"), pres: charenton).isEmpty)
    }

    @Test("Jamais de coin privé, ni de mot de promesse dans les données rendues")
    func jamaisPrive() {
        let m = moteurAvecCoins(coinsOSMEssai)
        let tous = m.coinsPublicsDans(RegionCarte(sudOuest: Coordonnee(latitude: 40, longitude: 0), nordEst: Coordonnee(latitude: 50, longitude: 10)))
        #expect(!tous.contains { $0.id == "node/5" })
        #expect(tous.count == 5)
    }

    @Test("coinsPublicsDans : coins du rectangle avec les espèces de leur station, [] sans couche")
    func dansUneRegion() throws {
        let m = moteurAvecCoins(coinsOSMEssai)
        let region = RegionCarte(sudOuest: Coordonnee(latitude: 48.75, longitude: 2.30), nordEst: Coordonnee(latitude: 48.90, longitude: 2.50))
        let coins = m.coinsPublicsDans(region)
        #expect(coins.map(\.id) == ["node/1", "node/2", "node/7"])
        let quai = try #require(coins.first)
        #expect(quai.codeStation == "S1" && quai.eauStation == "La Marne")
        #expect(quai.especes.map(\.espece.id) == ["perche-commune", "brochet", "sandre"])
        #expect(quai.especes.map(\.nPeches) == [9, 4, 1])
        let loin = RegionCarte(sudOuest: Coordonnee(latitude: 48.69, longitude: 2.59), nordEst: Coordonnee(latitude: 48.71, longitude: 2.61))
        let sansStation = try #require(m.coinsPublicsDans(loin).first)
        #expect(sansStation.id == "node/4" && sansStation.codeStation == nil && sansStation.especes.isEmpty)
        #expect(moteurAvecCoins(nil).coinsPublicsDans(region).isEmpty)
    }

    @Test("coinsPublics(pres:rayonM:) : dans le rayon, du plus proche au plus loin")
    func presDUnPoint() {
        let m = moteurAvecCoins(coinsOSMEssai)
        let c = m.coinsPublics(pres: charenton, rayonM: 5_000)
        #expect(c.map(\.id) == ["node/1", "node/2"])
        #expect(m.coinsPublics(pres: Coordonnee(latitude: 44, longitude: 0), rayonM: 1_000).isEmpty)
    }
}
