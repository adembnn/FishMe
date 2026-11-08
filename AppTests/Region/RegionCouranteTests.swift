import Core
import Foundation
import Testing
@testable import BuildChallenge

@MainActor
struct RegionCouranteTests {
    /// Un `UserDefaults` neuf par test : aucune fuite entre tests ni vers les vrais réglages.
    private func reglagesNeufs() -> UserDefaults {
        let nom = "test.region.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: nom)!
        d.removePersistentDomain(forName: nom)
        return d
    }

    private let paris = Coordonnee(latitude: 48.8566, longitude: 2.3522)
    private let denver = Coordonnee(latitude: 39.7392, longitude: -104.9903)
    private let anchorage = Coordonnee(latitude: 61.2181, longitude: -149.9003)
    private let honolulu = Coordonnee(latitude: 21.3069, longitude: -157.8583)
    private let miami = Coordonnee(latitude: 25.7617, longitude: -80.1918)
    private let seattle = Coordonnee(latitude: 47.6062, longitude: -122.3321)
    private let bordeaux = Coordonnee(latitude: 44.8378, longitude: -0.5792)

    @Test func sansPositionNiReglageOnEstEnFrance() {
        let r = RegionCourante(reglages: reglagesNeufs())
        #expect(r.choix == .automatique)
        #expect(r.region == .france)
        #expect(r.region.locale.identifier == "fr_FR")
        #expect(r.systemeUnites == .metrique)
    }

    @Test func laPositionAuxEtatsUnisDonneLaRegionUS() {
        let r = RegionCourante(reglages: reglagesNeufs())
        r.positionConnue(denver)
        #expect(r.region == .etatsUnis)
        #expect(r.region.locale.identifier == "en_US")
        #expect(r.systemeUnites == .imperial)
    }

    @Test func laDeductionCouvreLesEtatsUnisEtLaFrance() {
        for p in [denver, anchorage, honolulu, miami, seattle] { #expect(RegionCourante.region(pour: p) == .etatsUnis) }
        for p in [paris, bordeaux] { #expect(RegionCourante.region(pour: p) == .france) }
        // Hors des deux régions (Londres, Tijuana) : repli France, le pêcheur règle à la main.
        #expect(RegionCourante.region(pour: Coordonnee(latitude: 51.5, longitude: -0.12)) == .france)
        #expect(RegionCourante.region(pour: Coordonnee(latitude: 32.5, longitude: -117.03)) == .france)
        #expect(RegionCourante.region(pour: Coordonnee(latitude: 32.75, longitude: -117.16)) == .etatsUnis) // San Diego
    }

    @Test func pasDePositionNeChangeRienEtLaDerniereRegionResteConnue() {
        let r = RegionCourante(reglages: reglagesNeufs())
        r.positionConnue(denver)
        r.positionConnue(nil)
        #expect(r.region == .etatsUnis)
    }

    @Test func leReglageExplicitPasseAvantLaPosition() {
        let r = RegionCourante(reglages: reglagesNeufs())
        r.positionConnue(denver)
        r.choix = .france
        #expect(r.region == .france)
        r.positionConnue(paris)
        r.choix = .etatsUnis
        #expect(r.region == .etatsUnis)
        r.choix = .automatique
        #expect(r.region == .france)   // déduite de Paris
    }

    @Test func leChoixEtLaRegionDeduiteSontMemorises() {
        let d = reglagesNeufs()
        let a = RegionCourante(reglages: d)
        a.choix = .etatsUnis
        a.choix = .automatique
        a.positionConnue(denver)
        let b = RegionCourante(reglages: d)
        #expect(b.choix == .automatique)
        #expect(b.region == .etatsUnis)
        a.choix = .france
        #expect(RegionCourante(reglages: d).choix == .france)
    }

    @Test func seuleLaRegionEstGardeeJamaisLesCoordonnees() {
        let d = reglagesNeufs()
        RegionCourante(reglages: d).positionConnue(denver)
        let valeurs = d.dictionaryRepresentation().filter { $0.key.hasPrefix("region.") }
        #expect(valeurs.count == 1)
        #expect(valeurs[RegionCourante.cleDeduite] as? String == "etatsUnis")
    }

    @Test func uneValeurMemoriseeInconnueRetombeSurLesDefauts() {
        let d = reglagesNeufs()
        d.set("mars", forKey: RegionCourante.cleChoix)
        d.set("mars", forKey: RegionCourante.cleDeduite)
        let r = RegionCourante(reglages: d)
        #expect(r.choix == .automatique)
        #expect(r.region == .france)
    }
}
