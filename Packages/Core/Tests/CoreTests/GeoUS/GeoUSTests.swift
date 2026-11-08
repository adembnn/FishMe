import Foundation
import Testing
@testable import Core

/// Données géographiques US embarquées (lot US11) : chargement, bornes, lieux connus, tri par distance, aucun champ vide.
@Suite struct GeoUSTests {
    static let motsInterdits = ["autoris", "allowed", "legal", "libre", "tu peux la garder", "you can keep it"]

    // MARK: Chargement

    @Test func etatsDisponiblesContientWisconsinEtMinnesota() {
        let etats = GeoUS.etatsDisponibles
        #expect(etats.contains("WI"))
        #expect(etats.contains("MN"))
        #expect(etats == etats.sorted())
        #expect(Set(etats).count == etats.count)
    }

    @Test func chaqueEtatADesPointsEtDesPlansEau() {
        for etat in GeoUS.etatsDisponibles {
            // US15 : 51 juridictions, certaines partielles (voir reports/us/couverture.md) : au moins une couche non vide
            let n = GeoUS.points(etat: etat).count + GeoUS.plansEau(etat: etat).count + GeoUS.lignesEau(etat: etat).count
            #expect(n > 0, "aucune donnée pour \(etat)")
        }
    }

    @Test func minusculesAcceptees() {
        #expect(GeoUS.points(etat: "wi") == GeoUS.points(etat: "WI"))
    }

    @Test func etatInconnuDonneDesListesVides() {
        #expect(GeoUS.points(etat: "ZZ").isEmpty)
        #expect(GeoUS.plansEau(etat: "ZZ").isEmpty)
        #expect(GeoUS.avis(etat: "ZZ").isEmpty)
        #expect(GeoUS.lignesEau(etat: "ZZ").isEmpty)
        #expect(GeoUS.points(etat: "").isEmpty)
        #expect(GeoUS.points(etat: "../x").isEmpty)
    }

    // MARK: Aucun champ vide, bornes

    @Test func pointsSansChampVide() {
        for etat in GeoUS.etatsDisponibles {
            var ids = Set<String>()
            for p in GeoUS.points(etat: etat) {
                #expect(!p.id.isEmpty && !p.nom.isEmpty && !p.source.isEmpty, "\(p.id)")
                #expect(p.etat == etat)
                #expect(ids.insert(p.id).inserted, "id en double : \(p.id)")
                #expect(Self.dateValide(p.date), "date \(p.date)")
                #expect(p.source.hasPrefix("accès public listé par") || p.source.hasPrefix("point cartographié par OpenStreetMap"), "\(p.source)")
                #expect(p.latitude.isFinite && p.longitude.isFinite)
            }
        }
    }

    @Test func pointsDansLaBoiteDeLEtat() throws {
        for etat in GeoUS.etatsDisponibles {
            guard let zone = DonneesGeoUS.embarque.zones.first(where: { $0.etat == etat }) else { continue }  // contour absent : État partiel
            for p in GeoUS.points(etat: etat) {
                #expect(p.latitude >= zone.minLat - 0.5 && p.latitude <= zone.maxLat + 0.5, "\(p.id) latitude \(p.latitude)")
                #expect(p.longitude >= zone.minLon - 0.5 && p.longitude <= zone.maxLon + 0.5, "\(p.id) longitude \(p.longitude)")
            }
        }
    }

    @Test func typesDePointsConnus() {
        for etat in ["WI", "MN"] {
            let types = Set(GeoUS.points(etat: etat).map(\.type))
            #expect(types.contains(.rampe), "rampes \(etat)")
            #expect(types.contains(.accesPublic), "accès à pied \(etat)")
        }
        #expect(GeoUS.points(etat: "WI").contains { $0.type == .quai })
    }

    @Test func plansEauSansChampVideEtRayonPositif() {
        for etat in GeoUS.etatsDisponibles {
            var ids = Set<String>()
            for p in GeoUS.plansEau(etat: etat) {
                #expect(!p.id.isEmpty && !p.nom.isEmpty && !p.source.isEmpty, "\(p.id)")
                #expect(p.etat == etat)
                #expect(p.rayonMetres > 0 && p.rayonMetres < 200_000, "\(p.nom) rayon \(p.rayonMetres)")
                #expect(Self.dateValide(p.date))
                #expect(ids.insert(p.id).inserted, "id en double : \(p.id)")
                #expect(p.lienAgence == nil || p.lienAgence?.hasPrefix("https://") == true)
            }
        }
    }

    @Test func lignesEauValides() {
        for etat in GeoUS.etatsDisponibles {
            for l in GeoUS.lignesEau(etat: etat).prefix(2000) {
                #expect(!l.id.isEmpty && !l.nom.isEmpty && !l.source.isEmpty)
                #expect(l.ordre >= 1)
                #expect(l.points.count >= 2)
                #expect(Self.dateValide(l.date))
                for c in l.points {
                    #expect(c.latitude > 17 && c.latitude < 72 && c.longitude < -64 && c.longitude > -180, "\(l.nom)")
                }
            }
        }
    }

    @Test func avisDatesEtLies() {
        for etat in GeoUS.etatsDisponibles {
            let avis = GeoUS.avis(etat: etat)
            for a in avis {
                #expect(!a.texte.isEmpty && !a.source.isEmpty)
                #expect(Self.dateValide(a.date))
                #expect(a.lien.hasPrefix("https://"))
            }
        }
    }

    @Test func jamaisDeMotPermissif() {
        for etat in GeoUS.etatsDisponibles {
            var textes = GeoUS.avis(etat: etat).flatMap { [$0.texte, $0.source] }
            textes += Set(GeoUS.points(etat: etat).map(\.source))
            textes += Set(GeoUS.plansEau(etat: etat).map(\.source))
            for t in textes {
                let bas = t.lowercased()
                for m in Self.motsInterdits {
                    #expect(!bas.contains(m), "mot interdit \(m) dans \(t)")
                }
            }
        }
    }

    // MARK: Quel État

    @Test func lieuxConnusTombentDansLeBonEtat() {
        #expect(GeoUS.etat(pour: 43.0731, longitude: -89.4012) == "WI")   // Madison
        #expect(GeoUS.etat(pour: 43.0389, longitude: -87.9065) == "WI")   // Milwaukee
        #expect(GeoUS.etat(pour: 44.9778, longitude: -93.2650) == "MN")   // Minneapolis
        #expect(GeoUS.etat(pour: 46.7867, longitude: -92.1005) == "MN")   // Duluth
        #expect(GeoUS.etat(pour: 46.5436, longitude: -87.3954) == "MI")   // Marquette
    }

    @Test func lieuxHorsDesEtatsCouvertsDonnentNil() {
        #expect(GeoUS.etat(pour: 48.8566, longitude: 2.3522) == nil)       // Paris
        #expect(GeoUS.etat(pour: 40.7128, longitude: -74.0060) == nil)     // New York
        #expect(GeoUS.etat(pour: 19.4326, longitude: -99.1332) == nil)     // Mexico
        #expect(GeoUS.etat(pour: 0, longitude: 0) == nil)
        #expect(GeoUS.etat(pour: .nan, longitude: -89) == nil)
    }

    @Test func unPointListeEstDansSonEtat() {
        for etat in GeoUS.etatsDisponibles {
            guard DonneesGeoUS.embarque.zones.contains(where: { $0.etat == etat }) else { continue }  // contour absent : État partiel
            let pts = GeoUS.points(etat: etat)
            guard pts.count >= 10 else { continue }  // échantillon trop petit (DC : 2 points)
            let echantillon = stride(from: 0, to: pts.count, by: max(1, pts.count / 200)).map { pts[$0] }
            let dedans = echantillon.filter { GeoUS.etat(pour: $0.latitude, longitude: $0.longitude) == etat }.count
            // le contour est très simplifié (0,01°) : des rampes de rive ou de côte peuvent tomber dehors, pas plus de 20 %
            #expect(Double(dedans) >= Double(echantillon.count) * 0.80, "\(etat) : \(dedans) sur \(echantillon.count)")
        }
    }

    // MARK: Autour d'une position

    @Test func pointsAutourTriesParDistance() {
        let lat = 45.9, lon = -89.7   // Vilas County, Wisconsin
        let pts = GeoUS.points(autour: lat, longitude: lon, rayonKm: 30, limite: 50)
        #expect(!pts.isEmpty)
        #expect(pts.count <= 50)
        let centre = Coordonnee(latitude: lat, longitude: lon)
        let distances = pts.map { Geodesie.distanceM(centre, Coordonnee(latitude: $0.latitude, longitude: $0.longitude)) }
        #expect(distances == distances.sorted())
        #expect(distances.allSatisfy { $0 <= 30_000 })
    }

    @Test func limiteRespecteeEtPlusProchesGardes() {
        let lat = 45.9, lon = -89.7
        let tous = GeoUS.points(autour: lat, longitude: lon, rayonKm: 40, limite: 10_000)
        let trois = GeoUS.points(autour: lat, longitude: lon, rayonKm: 40, limite: 3)
        #expect(trois.count == 3)
        #expect(trois == Array(tous.prefix(3)))
    }

    @Test func rayonTropPetitOuEntreesInvalides() {
        #expect(GeoUS.points(autour: 0, longitude: 0, rayonKm: 50, limite: 10).isEmpty)
        #expect(GeoUS.points(autour: 45.9, longitude: -89.7, rayonKm: 50, limite: 0).isEmpty)
        #expect(GeoUS.points(autour: 45.9, longitude: -89.7, rayonKm: -1, limite: 10).isEmpty)
        #expect(GeoUS.points(autour: .nan, longitude: -89.7, rayonKm: 5, limite: 10).isEmpty)
        #expect(GeoUS.points(autour: 45.9, longitude: -89.7, rayonKm: .infinity, limite: 10).isEmpty)
    }

    @Test func pointsAutourTraverseLaFrontiereEntreEtats() {
        // Hudson (WI) et Stillwater (MN) sont séparées par la rivière St. Croix : les deux États répondent
        let pts = GeoUS.points(autour: 44.95, longitude: -92.76, rayonKm: 60, limite: 10_000)
        #expect(Set(pts.map(\.etat)).isSuperset(of: ["WI", "MN"]))
    }

    // MARK: Fichiers abîmés

    @Test func dossierAbsentOuAbimeDonneDesListesVides() throws {
        let vide = DonneesGeoUS(dossier: nil)
        #expect(vide.etats.isEmpty)
        #expect(vide.points(etat: "WI").isEmpty)
        #expect(vide.etat(latitude: 44, longitude: -90) == nil)

        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("geo-us-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        try Data("pas du json".utf8).write(to: tmp.appendingPathComponent("WI-points.json"))
        try Data(Self.jsonTordu.utf8).write(to: tmp.appendingPathComponent("MN-points.json"))
        let d = DonneesGeoUS(dossier: tmp)
        #expect(d.etats == ["MN", "WI"])
        #expect(d.points(etat: "WI").isEmpty)
        #expect(d.points(etat: "MN").isEmpty)
        #expect(d.avis(etat: "WI").isEmpty)
    }

    @Test func ligneMalFormeeIgnoreeLesBonnesGardees() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("geo-us-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        try Data(Self.jsonMelange.utf8).write(to: tmp.appendingPathComponent("TT-points.json"))
        let pts = DonneesGeoUS(dossier: tmp).points(etat: "TT")
        #expect(pts.map(\.id) == ["t:1", "t:4"])
        #expect(pts[1].type == .autre)
        #expect(pts[0].source == "accès public listé par Test DNR, essai")
        #expect(pts[0].date == "2026-11-07")
    }

    // MARK: Outils

    static let jsonTordu = #"{"points": [["a", "b"], 3, null]}"#

    static let jsonMelange = #"""
    {"date": "2026-11-07", "sources": [{"texte": "accès public listé par Test DNR, essai", "date": "2026-11-07"}],
     "points": [["t:1", "Rampe Un", 44.5, -89.5, "rampe", 0],
                ["t:2", "", 44.5, -89.5, "rampe", 0],
                ["t:3", "Sans source", 44.5, -89.5, "rampe", 7],
                ["t:4", "Type inconnu", 44.6, -89.6, "zzz", 0],
                ["t:5", "Trop court"]]}
    """#

    static func dateValide(_ s: String) -> Bool {
        let p = s.split(separator: "-")
        guard p.count == 3, p[0].count == 4, p[1].count == 2, p[2].count == 2,
              let a = Int(p[0]), let m = Int(p[1]), let j = Int(p[2]) else { return false }
        return a >= 2026 && (1...12).contains(m) && (1...31).contains(j)
    }
}
