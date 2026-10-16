import Foundation
import Testing
import Core
@testable import BuildChallenge

@MainActor
struct CarteRapideTests {

    private func station(_ code: String, _ lat: Double, _ lon: Double) -> StationCarte {
        StationCarte(code: code, eau: "La Marne", departement: Departement(code: "94"),
                     coordonnee: Coordonnee(latitude: lat, longitude: lon),
                     releves: [ReleveEspece(espece: Espece(id: "brochet", codeSandre: "BRO"), nPeches: 7, annee: 2024)])
    }

    private func dossierTemporaire() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("cache-carte-\(UUID().uuidString)")
    }

    private let zone = ZoneCarte(centre: Coordonnee(latitude: 48.8, longitude: 2.4), spanLatitude: 0.2, spanLongitude: 0.2)

    @Test func leCacheSeRelitIdentique() {
        let dossier = dossierTemporaire()
        let cache = CacheCarte.pour(region: zone, stations: [station("A", 48.81, 2.41), station("B", 48.79, 2.39)])
        StockageCacheCarte.ecrire(cache, dans: dossier)
        #expect(StockageCacheCarte.lire(dans: dossier, maintenant: cache.ecritLe) == cache)
    }

    @Test func sansFichierOuAvecFichierAbimeLeCacheEstVide() throws {
        let dossier = dossierTemporaire()
        #expect(StockageCacheCarte.lire(dans: dossier, maintenant: Date()) == nil)
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        try Data("pas du json".utf8).write(to: dossier.appendingPathComponent(StockageCacheCarte.nomFichier))
        #expect(StockageCacheCarte.lire(dans: dossier, maintenant: Date()) == nil)
    }

    @Test func unCacheTropVieuxOuDUneAutreVersionEstIgnore() {
        let dossier = dossierTemporaire()
        let cache = CacheCarte.pour(region: zone, stations: [station("A", 48.81, 2.41)])
        StockageCacheCarte.ecrire(cache, dans: dossier)
        let plusTard = cache.ecritLe.addingTimeInterval(StockageCacheCarte.ageMaximum + 60)
        #expect(StockageCacheCarte.lire(dans: dossier, maintenant: plusTard) == nil)

        var autre = cache
        autre.version = 99
        StockageCacheCarte.ecrire(autre, dans: dossier)
        #expect(StockageCacheCarte.lire(dans: dossier, maintenant: cache.ecritLe) == nil)
    }

    @Test func leCentreDeLaVueEstArrondiAuCentieme() {
        let precise = ZoneCarte(centre: Coordonnee(latitude: 48.81234, longitude: 2.40789), spanLatitude: 0.2, spanLongitude: 0.2)
        let cache = CacheCarte.pour(region: precise, stations: [station("A", 48.81, 2.41)])
        #expect(cache.region.centre == Coordonnee(latitude: 48.81, longitude: 2.41))
    }

    @Test func laSelectionGardeLesPlusProchesDuCentreEtSeulementLesVisibles() {
        let stations = [station("C", 48.85, 2.45), station("A", 48.80, 2.40), station("B", 48.81, 2.41), station("Loin", 45.0, 5.0)]
        let gardees = SelectionVisible.stations(stations, dans: zone, maximum: 2)
        #expect(gardees.map(\.code) == ["A", "B"])
        #expect(SelectionVisible.stations(stations, dans: zone, maximum: 10).map(\.code) == ["A", "B", "C"])
        #expect(SelectionVisible.stations(stations, dans: zone, maximum: 0).isEmpty)
    }

    @Test func uneZoneDansLaMargeDuChargementEstCouverte() {
        let petite = ZoneCarte(centre: Coordonnee(latitude: 48.81, longitude: 2.41), spanLatitude: 0.1, spanLongitude: 0.1)
        #expect(petite.estCouverte(parChargee: zone))
        #expect(zone.estCouverte(parChargee: zone))
        let decalee = ZoneCarte(centre: Coordonnee(latitude: 48.8, longitude: 2.8), spanLatitude: 0.2, spanLongitude: 0.2)
        #expect(!decalee.estCouverte(parChargee: zone))
        #expect(!ZoneCarte.france.estCouverte(parChargee: zone))
    }

#if DEBUG
    @Test func affichageInitialNeChargeJamaisLaFrance() {
        let modele = ModeleCarte(services: .faux(), dossierCache: nil)
        modele.chargerApresMouvement(.france)
        #expect(modele.regionChargee == nil)
    }

    @Test func apresLaPositionUnPetitMouvementNeRelitPasLesStations() {
        let modele = ModeleCarte(services: .faux(), dossierCache: nil)
        modele.appliquer(position: Coordonnee(latitude: 48.8, longitude: 2.4), refusee: false)
        let chargee = modele.regionChargee
        #expect(chargee != nil)
        modele.chargerApresMouvement(ZoneCarte(centre: Coordonnee(latitude: 48.81, longitude: 2.41), spanLatitude: 0.1, spanLongitude: 0.1))
        #expect(modele.regionChargee == chargee)
        modele.chargerApresMouvement(ZoneCarte(centre: Coordonnee(latitude: 47.0, longitude: 3.0), spanLatitude: 0.1, spanLongitude: 0.1))
        #expect(modele.regionChargee != chargee)
    }
#endif
}
