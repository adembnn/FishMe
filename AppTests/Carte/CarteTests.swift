import Foundation
import Testing
import Core
@testable import BuildChallenge

@MainActor
struct CarteTests {

    private func points(_ n: Int) -> [PointCarte] {
        (0..<n).map { i in
            let lat = 42.5 + Double(i % 70) * 0.1
            let lon = -4.5 + Double(i / 70 % 90) * 0.1
            return PointCarte(id: "p\(i)", coordonnee: Coordonnee(latitude: lat, longitude: lon))
        }
    }

    @Test func moinsDeCentCinquantePointsSontTousAffiches() {
        let region = RegionCarte(centre: Coordonnee(latitude: 46, longitude: 2), spanLatitude: 20, spanLongitude: 20)
        let elements = Regroupeur.elements(points: points(100), region: region)
        #expect(elements.count == 100)
    }

    @Test func franceEntiereNeDepasseJamaisCentCinquanteElements() {
        let tous = points(5000)
        let elements = Regroupeur.elements(points: tous, region: .france)
        #expect(elements.count <= Regroupeur.maximum)
        #expect(!elements.isEmpty)
    }

    @Test func lesRegroupementsGardentLeNombreDeStations() {
        let tous = points(3000)
        let elements = Regroupeur.elements(points: tous, region: .france)
        let total = elements.reduce(0) { somme, e in
            switch e {
            case .point: return somme + 1
            case .groupe(_, _, let n): return somme + n
            }
        }
        let visibles = tous.filter { RegionCarte.france.contient($0.coordonnee) }.count
        #expect(total == visibles)
    }

    @Test func leReleveAffichePecheEtAnnee() {
        #expect(texteReleve(nPeches: 9, annee: 2024) == "9 pêches, dernier relevé 2024")
        #expect(texteReleve(nPeches: 1, annee: 2011) == "1 pêche, dernier relevé 2011")
    }

    @Test func ouvertureAvecEtSansDate() {
        #expect(OuvertureDuJour.ouverte.texte == "ouverte aujourd'hui")
        #expect(OuvertureDuJour.fermee(reouverture: nil).texte == "fermée")
        let date = Date(timeIntervalSince1970: 1_776_000_000)
        #expect(OuvertureDuJour.fermee(reouverture: date).texte.hasPrefix("fermée jusqu'au "))
    }

    @Test func leChoixDuPecheurEstGardeSurLIphone() {
        let reglages = UserDefaults(suiteName: "carte-tests-\(UUID().uuidString)")!
        let choix = ChoixLieu(eau: Eau(nom: "un plan d'eau", cle: "plan-d-eau", type: .lac), categorie: .premiere,
                              tronconsConfirmes: ["du pont au barrage"])
        StockageChoixLieu.ecrire(choix, id: "essai", reglages: reglages)
        #expect(StockageChoixLieu.lire("essai", reglages: reglages) == choix)
        #expect(StockageChoixLieu.lire("autre", reglages: reglages) == nil)
    }

#if DEBUG
    @Test func laFicheMarcheAvecLesFauxDeCore() async {
        let services = ServicesCarte.faux()
        let fiche = await calculerFiche(services: services, coordonnee: Coordonnee(latitude: 48.8, longitude: 2.4),
                                        choix: nil, espece: nil, date: dateDeTest)
        #expect(fiche.lieuFlou == "La Marne · 94")
        #expect(fiche.especes.count == 2)
        #expect(fiche.especes.allSatisfy { $0.annee == 2024 && $0.nPeches > 0 })
        #expect(fiche.lignes.count == 1)
        #expect(fiche.couverture == .complete)
    }

    @Test func horsDesDepartementsCouvertsLeBandeauDitReglesNonSaisies() async {
        var services = ServicesCarte.faux()
        services.geo = GeoHorsCouverture()
        let fiche = await calculerFiche(services: services, coordonnee: Coordonnee(latitude: 45, longitude: 5),
                                        choix: nil, espece: nil, date: dateDeTest)
        guard case .nonSaisie = fiche.couverture else {
            Issue.record("attendu : règles locales non saisies")
            return
        }
    }

    @Test func leModeleChargeLesFauxSansPlanter() async {
        let modele = ModeleCarte(services: .faux())
        await modele.demarrer()
        #expect(modele.pechables.count == 6)
        #expect(modele.peutChangerDeSpot)
    }

    private var dateDeTest: Date { Date(timeIntervalSince1970: 1_792_065_600) }
#endif
}

#if DEBUG
/// Un département absent de `departementsCouverts()` du faux de `Core` (qui ne couvre que le 94).
nonisolated struct GeoHorsCouverture: ServiceGeo {
    func departement(de coordonnee: Coordonnee) -> Departement { Departement(code: "38") }
    func lieu(de coordonnee: Coordonnee, choix: ChoixLieu?) -> Lieu { Lieu(departement: Departement(code: "38")) }
    func eauxProches(_ coordonnee: Coordonnee) -> [Eau] { [] }
    func lieuFlou(_ coordonnee: Coordonnee) -> String { "38" }
}
#endif
