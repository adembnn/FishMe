import Testing
@testable import Core

@Suite("Régions de France")
struct RegionsFranceTests {
    @Test func treizeRegionsEtQuatreVingtSeizeDepartements() {
        #expect(RegionsFrance.toutes.count == 13)
        let tous = RegionsFrance.toutes.flatMap(\.departements)
        #expect(tous.count == 96, "96 départements métropolitains (la Corse compte 2A et 2B)")
        #expect(Set(tous).count == tous.count, "aucun département dans deux régions")
    }

    @Test func chaqueNumeroDeDepartementEstPresent() {
        var attendus = (1...95).filter { $0 != 20 }.map { String(format: "%02d", $0) }
        attendus += ["2A", "2B"]
        let presents = Set(RegionsFrance.toutes.flatMap(\.departements))
        #expect(presents == Set(attendus))
    }

    @Test(arguments: [("94", "idf"), ("75", "idf"), ("01", "ara"), ("1", "ara"), ("2a", "cor"), ("29", "bre"),
                      ("13", "pac"), ("31", "occ"), ("33", "naq"), ("57", "ges"), ("59", "hdf"), ("44", "pdl"),
                      ("14", "nor"), ("45", "cvl"), ("21", "bfc")])
    func laRegionDUnDepartement(_ code: String, _ attendue: String) {
        #expect(RegionsFrance.region(deDepartement: code)?.id == attendue)
    }

    @Test func unCodeInconnuNeDonneRien() {
        #expect(RegionsFrance.region(deDepartement: "99") == nil)
        #expect(RegionsFrance.region(deDepartement: "") == nil)
        #expect(RegionsFrance.departementsDeLaRegion(de: "99").isEmpty)
    }

    @Test func lesDepartementsDeLaRegionDuVal_DeMarne() {
        let idf = RegionsFrance.departementsDeLaRegion(de: "94")
        #expect(idf.contains("75") && idf.contains("95") && idf.count == 8)
    }

    @Test func laLocutionSeLitDansUneFrase() {
        #expect(RegionsFrance.region(deDepartement: "94")?.locution == "en Île-de-France")
        #expect(RegionsFrance.region(deDepartement: "59")?.locution == "dans les Hauts-de-France")
        #expect(RegionsFrance.region(deDepartement: "67")?.locution == "dans le Grand Est")
    }
}
