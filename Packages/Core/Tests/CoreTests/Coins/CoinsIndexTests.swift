import Foundation
import Testing
@testable import Core

/// L'index paresseux de `MoteurCoins` (grille de stations, lieu mis en cache, limite) rend exactement ce que rendait le balayage d'origine.
@Suite("Coins publics : index identique au balayage d'origine")
struct CoinsIndexTests {
    static let points = [charenton, Coordonnee(latitude: 46.0, longitude: 5.0), Coordonnee(latitude: 48.70, longitude: 2.60),
                         Coordonnee(latitude: 43.3, longitude: 5.4), Coordonnee(latitude: 0, longitude: 0)]

    @Test("coinsProches : index et balayage d'origine rendent la même liste, pour chaque espèce et chaque point")
    func memeListe() {
        let m = moteurAvecCoins(coinsOSMEssai)
        for espece in [brochetEssai, sandreEssai, blackBassEssai, Espece(id: "inconnue")] {
            for p in Self.points {
                #expect(m.coinsProches(ou: espece, pres: p) == m.coinsProchesNaif(ou: espece, pres: p))
            }
        }
    }

    @Test("Les vrais coins (coins-osm.geojson) sur les stations d'essai : même liste")
    func vraisCoins() {
        let osm = Ressources.donnees("coins-osm", extension: "geojson")
        let m = MoteurCore(donnees: donneesEssai(), horloge: { quinzeOctobre }).coins(donneesOSM: osm)
        for p in Self.points {
            #expect(m.coinsProches(ou: brochetEssai, pres: p) == m.coinsProchesNaif(ou: brochetEssai, pres: p))
        }
    }

    @Test("limite : le début exact de la liste complète")
    func limite() {
        let m = moteurAvecCoins(coinsOSMEssai)
        let tous = m.coinsProches(ou: brochetEssai, pres: charenton)
        for n in [0, 1, 2, 3, 50] { #expect(m.coinsProches(ou: brochetEssai, pres: charenton, limite: n) == Array(tous.prefix(n))) }
        #expect(m.coinsProches(ou: brochetEssai, pres: charenton, limite: -4).isEmpty)
        // La valeur par défaut du contrat (extension) rend aussi le début de la liste.
        let faux: any ServiceCoinsPublics = CoinsFaux()
        #expect(faux.coinsProches(ou: brochetEssai, pres: charenton, limite: 0).isEmpty)
        #expect(faux.coinsProches(ou: brochetEssai, pres: charenton, limite: 3).count == 1)
    }

    @Test("Le fichier n'est lu qu'au premier besoin, et la copie du moteur partage l'index")
    func paresseux() {
        let m = moteurAvecCoins(coinsOSMEssai)
        let copie = m
        #expect(m.aDesCoins && copie.coinsOSM.count == 5)
        #expect(copie.coinsProches(ou: brochetEssai, pres: charenton) == m.coinsProches(ou: brochetEssai, pres: charenton))
    }

    @Test("Grille : la station la plus proche est celle du balayage complet, ex aequo compris, aux latitudes hautes comme basses")
    func grille() {
        var graine: UInt64 = 42
        func alea() -> Double { graine = graine &* 6364136223846793005 &+ 1442695040888963407; return Double(graine >> 11) / Double(1 << 53) }
        for (lat0, lon0) in [(48.8, 2.4), (51.0, 2.5), (42.5, 9.2), (-33.0, 151.0), (60.0, 10.0)] {
            let stations = (0..<1500).map { i -> StationBrute in
                // Quelques doublons exacts de coordonnée pour forcer des égalités de distance.
                let (dlat, dlon) = i % 50 == 0 ? (0.01, 0.01) : ((alea() - 0.5) * 0.6, (alea() - 0.5) * 0.9)
                return StationBrute(id: "S\(i)", coordonnee: Coordonnee(latitude: lat0 + dlat, longitude: lon0 + dlon), dep: "00", eau: nil,
                                    codeEau: nil, peches: 1, derniere: 2024, vues: ["1": 1])
            }
            let g = GrilleStations(stations)
            for _ in 0..<300 {
                let c = Coordonnee(latitude: lat0 + (alea() - 0.5) * 0.6, longitude: lon0 + (alea() - 0.5) * 0.9)
                var attendu: (StationBrute, Double)?
                for s in stations {
                    let d = Geodesie.distanceM(c, s.coordonnee)
                    if d <= MoteurCoins.rayonStationM, d < (attendu?.1 ?? .infinity) { attendu = (s, d) }
                }
                let obtenu = g.laPlusProche(de: c)
                #expect(obtenu?.station.id == attendu?.0.id)
                #expect(obtenu?.distanceM == attendu?.1)
            }
        }
    }
}
