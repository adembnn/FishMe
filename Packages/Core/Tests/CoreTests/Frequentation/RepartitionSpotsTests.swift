import Foundation
import Testing
@testable import Core

/// Stations de l'essai : 6 stations du 94 autour de Charenton, avec leurs eaux et espèces.
private func jeu(_ extra: [[String: Any]] = [], retirer: Set<String> = []) -> Data {
    func s(_ id: String, _ lat: Double, _ lon: Double, eau: String, code: String, vues: [String: Int], dep: String = "94") -> [String: Any] {
        ["id": id, "lat": lat, "lon": lon, "dep": dep, "peches": 10, "derniere": 2025, "vues": vues, "eau": eau, "code_eau": code]
    }
    let base: [[String: Any]] = [
        s("A1", 48.8235, 2.4160, eau: "La Marne", code: "F6--0020", vues: ["2193": 9, "2151": 2]),
        s("A2", 48.8100, 2.4300, eau: "La Marne", code: "F6--0020", vues: ["2193": 5]),
        s("A3", 48.8000, 2.4500, eau: "La Seine", code: "F3--0001", vues: ["2193": 5]),
        s("A4", 48.7900, 2.4000, eau: "Le Morbras", code: "F6--0030", vues: ["2193": 4]),
        s("A5", 48.7800, 2.3900, eau: "L'Yerres", code: "F4--0001", vues: ["2193": 4]),
        s("A6", 48.7700, 2.4400, eau: "Le Réveillon", code: "F4--0002", vues: ["2193": 4]),
    ]
    return try! JSONSerialization.data(withJSONObject: base.filter { !retirer.contains($0["id"] as! String) } + extra)
}

private func session(_ stations: Data, regles: ChargeurRegles = chargeurEssai()) -> MoteurSession {
    MoteurCore(donnees: donneesEssai(regles: regles, stations: stations), horloge: { quinzeOctobre }).session
}

@Suite("Répartition des spots")
struct RepartitionSpotsTests {
    @Test("Même graine, même spot")
    func memeGraine() throws {
        let m = session(jeu())
        let a = try #require(m.spotPropose(coordonnee: charenton, date: quinzeOctobre, niveau: .confirme, graine: 42))
        let b = try #require(m.spotPropose(coordonnee: charenton, date: quinzeOctobre, niveau: .confirme, graine: 42))
        #expect(a == b)
    }

    @Test("Des graines différentes donnent au moins deux spots différents")
    func graineDifferentes() {
        let m = session(jeu())
        let spots = Set((0..<5).compactMap { m.spotPropose(coordonnee: charenton, date: quinzeOctobre, niveau: .confirme, graine: UInt64($0))?.centre })
        #expect(spots.count >= 2)
        #expect(spots.count <= MoteurSession.stationsRepartition)
    }

    @Test("Le débutant écarte une station dont l'espèce dominante est rare")
    func debutantEcarteLeRare() {
        // Sandre (2195) dominant : rare dans le 94 ; la perche est commune.
        let rare: [String: Any] = ["id": "R1", "lat": 48.8225, "lon": 2.4150, "dep": "94", "peches": 10, "derniere": 2025,
                                   "vues": ["2195": 9], "eau": "La Seine", "code_eau": "F3--0001"]
        let m = session(jeu([rare]))
        for g in 0..<10 {
            #expect(m.spotPropose(coordonnee: charenton, date: quinzeOctobre, niveau: .debutant, graine: UInt64(g))?.centre
                    != Coordonnee(latitude: 48.8225, longitude: 2.4150))
        }
        let confirmes = Set((0..<10).compactMap { m.spotPropose(coordonnee: charenton, date: quinzeOctobre, niveau: .confirme, graine: UInt64($0))?.centre })
        #expect(confirmes.contains(Coordonnee(latitude: 48.8225, longitude: 2.4150)))
    }

    @Test("Une station sur un cours d'eau à réserve est écartée quand une autre existe")
    func reserveEcartee() {
        // Le 94 de l'essai déclare une réserve sur la Marne : seules les stations hors Marne restent.
        let m = session(jeu())
        let marne = [Coordonnee(latitude: 48.8235, longitude: 2.4160), Coordonnee(latitude: 48.8100, longitude: 2.4300)]
        for g in 0..<10 {
            let c = m.spotPropose(coordonnee: charenton, date: quinzeOctobre, niveau: .confirme, graine: UInt64(g))?.centre
            #expect(c != nil && !marne.contains(c!))
        }
        // Toutes sur la Marne : la liste d'avant est gardée.
        let seules = session(jeu(retirer: ["A3", "A4", "A5", "A6"]))
        #expect(seules.spotPropose(coordonnee: charenton, date: quinzeOctobre, niveau: .confirme, graine: 0) != nil)
    }

    @Test("Coin calme : saute le tronçon chargé et préfère le même cours d'eau")
    func coinCalme() throws {
        // Sans réserve : on retire les règles du 94.
        let sansReserve = chargeurEssai(extra: ["94": fichierRegles(departement: "94", regles: [])])
        let m = session(jeu(), regles: sansReserve)
        let depart = Spot(centre: Coordonnee(latitude: 48.8235, longitude: 2.4160), departement: Departement(code: "94"))
        #expect(m.troncon(de: depart) == "A1")
        let calme = try #require(m.coinCalme(depuis: depart, date: quinzeOctobre, niveau: .confirme, estCharge: { _ in false }))
        #expect(calme.centre == Coordonnee(latitude: 48.8100, longitude: 2.4300))
        // A2 chargé : la prochaine est une autre eau, la plus proche (A3).
        let suivant = try #require(m.coinCalme(depuis: depart, date: quinzeOctobre, niveau: .confirme, estCharge: { $0 == "A2" }))
        #expect(suivant.centre == Coordonnee(latitude: 48.8000, longitude: 2.4500))
        #expect(m.coinCalme(depuis: depart, date: quinzeOctobre, niveau: .confirme, estCharge: { _ in true }) == nil)
    }

    @Test("L'ancien spotPropose est inchangé")
    func ancienInchange() throws {
        let m = moteurEssai().session
        let spot = try #require(m.spotPropose(coordonnee: charenton, date: quinzeOctobre))
        #expect(spot.centre == Coordonnee(latitude: 48.8235, longitude: 2.4160))
        #expect(m.troncon(de: spot) == "S1")
    }
}
