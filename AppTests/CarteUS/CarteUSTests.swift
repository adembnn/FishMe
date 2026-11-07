import Foundation
import Testing
import Core
@testable import BuildChallenge

/// US10 : la carte des États-Unis. Bascule de région, filtrage par distance, regroupement sous le plafond, fiche sans mot interdit,
/// message honnête quand un État n'a pas de données. Sources de données : des fixtures, jamais de faux contenu dans l'app.
@MainActor
struct CarteUSTests {

    // MARK: Fixtures

    nonisolated struct SourceFixe: SourceCarteUS {
        var points: [PointAccesCarteUS] = []
        var plans: [PlanEauCarteUS] = []
        var avisListe: [AvisSanteCarteUS] = []
        var etats: [String] = ["MN", "WI"]

        var etatsDisponibles: [String] { etats }
        func points(etat: String) -> [PointAccesCarteUS] { points.filter { p in p.etat == etat } }
        func plansEau(etat: String) -> [PlanEauCarteUS] { plans.filter { p in p.etat == etat } }
        func avis(etat: String) -> [AvisSanteCarteUS] { avisListe }
        func etat(pour latitude: Double, longitude: Double) -> String? {
            if latitude >= 43.5, latitude <= 49.4, longitude >= -97.2, longitude <= -89.6 { return "MN" }
            if latitude >= 42.5, latitude <= 47.1, longitude >= -92.9, longitude <= -86.8 { return "WI" }
            return nil
        }
    }

    let agences = AgencesFixesCarteUS(tous: [
        InfoAgenceUS(code: "MN", nomEtat: "Minnesota", agence: "Minnesota DNR", url: URL(string: "https://www.dnr.state.mn.us/")),
        InfoAgenceUS(code: "TX", nomEtat: "Texas", agence: "Texas Parks and Wildlife", url: URL(string: "https://tpwd.texas.gov/")),
        InfoAgenceUS(code: "WI", nomEtat: "Wisconsin", agence: "Wisconsin DNR", url: URL(string: "https://dnr.wisconsin.gov/")),
    ])

    let minneapolis = Coordonnee(latitude: 44.98, longitude: -93.27)

    func point(_ id: String, _ lat: Double, _ lon: Double, etat: String = "MN", source: String = "MN DNR, accès publics à l'eau") -> PointAccesCarteUS {
        PointAccesCarteUS(id: id, nom: "Rampe " + id, etat: etat, latitude: lat, longitude: lon, type: .rampe, source: source, date: "2026-11-07")
    }

    func plan(_ id: String, _ lat: Double, _ lon: Double, lien: String? = "https://www.dnr.state.mn.us/lakefind/") -> PlanEauCarteUS {
        PlanEauCarteUS(id: id, nom: "Lac " + id, etat: "MN", latitude: lat, longitude: lon, rayonMetres: 800,
                       source: "MN DNR, LakeFinder", date: "2026-11-07", lienAgence: lien)
    }

    func zone(_ c: Coordonnee, span: Double) -> ZoneCarte {
        ZoneCarte(centre: c, spanLatitude: span, spanLongitude: span)
    }

    func reglages() -> UserDefaults {
        UserDefaults(suiteName: "carteus-" + UUID().uuidString)!
    }

    let mots = ["autoris", "allowed", "legal", "légal", "tu peux la garder", "you can keep", "libre"]

    func motInterdit(dans texte: String) -> String? {
        mots.first { m in texte.localizedCaseInsensitiveContains(m) }
    }

    // MARK: Bascule de région

    @Test func sansRegionOuEnFranceLaCarteResteCelleDeLaFrance() {
        #expect(ModeCarte.pour(nil) == .france)
        #expect(ModeCarte.pour(.france) == .france)
        let region = RegionCourante(reglages: reglages())
        #expect(ModeCarte.pour(region.region) == .france)
    }

    @Test func leReglageEtatsUnisBasculeLaCarte() {
        let region = RegionCourante(reglages: reglages())
        region.choix = .etatsUnis
        #expect(ModeCarte.pour(region.region) == .etatsUnis)
        region.choix = .france
        #expect(ModeCarte.pour(region.region) == .france)
    }

    @Test func enAutomatiqueLaPositionDecideEtLeReglageGagne() {
        let region = RegionCourante(reglages: reglages())
        region.positionConnue(minneapolis)
        #expect(ModeCarte.pour(region.region) == .etatsUnis)
        region.positionConnue(Coordonnee(latitude: 48.85, longitude: 2.35))
        #expect(ModeCarte.pour(region.region) == .france)
        region.positionConnue(minneapolis)
        region.choix = .france
        #expect(ModeCarte.pour(region.region) == .france)
    }

    // MARK: Filtrage par distance

    @Test func lesPointsProchesSontTriesParDistanceEtLimites() {
        let source = SourceFixe(points: [
            point("c", 45.20, -93.27), point("a", 44.99, -93.27), point("b", 45.05, -93.27), point("loin", 46.50, -94.00),
            point("wi", 44.98, -91.50, etat: "WI"),
        ])
        let proches = source.points(autour: 44.98, longitude: -93.27, rayonKm: 30, limite: 10)
        #expect(proches.map { p in p.id } == ["a", "b", "c"])
        #expect(source.points(autour: 44.98, longitude: -93.27, rayonKm: 30, limite: 2).map { p in p.id } == ["a", "b"])
        #expect(source.points(autour: 44.98, longitude: -93.27, rayonKm: 0.1, limite: 10).isEmpty)
        #expect(source.points(autour: 44.98, longitude: -93.27, rayonKm: 30, limite: 0).isEmpty)
        // Un point du Wisconsin à 140 km n'entre qu'avec un rayon assez large.
        #expect(source.points(autour: 44.98, longitude: -93.27, rayonKm: 200, limite: 10).map { p in p.id }.contains("wi"))
    }

    @Test func laDistanceEstEnKilometres() {
        let d = SelectionCarteUS.distanceKm(Coordonnee(latitude: 45, longitude: -93), Coordonnee(latitude: 46, longitude: -93))
        #expect(abs(d - 111.2) < 0.5)
    }

    // MARK: Performance : le plafond de 200

    @Test func moinsDeDeuxCentsLieuxSontDessinesUnAUn() {
        let points = (0..<50).map { i in point(String(i), 44.9 + Double(i) * 0.001, -93.3) }
        let elements = SelectionCarteUS.elements(points: points, plans: [plan("z", 44.95, -93.3)], dans: zone(minneapolis, span: 0.5))
        #expect(elements.count == 51)
    }

    @Test func plusDeDeuxCentsLieuxSontRegroupesSousLePlafond() {
        var points: [PointAccesCarteUS] = []
        for i in 0..<30 {
            for j in 0..<30 { points.append(point(String(i) + "-" + String(j), 44.7 + Double(i) * 0.01, -93.5 + Double(j) * 0.01)) }
        }
        let elements = SelectionCarteUS.elements(points: points, plans: [], dans: zone(minneapolis, span: 0.5))
        #expect(elements.count <= SelectionCarteUS.plafond)
        var total = 0
        for e in elements {
            if case .groupe(_, _, let n) = e { total += n } else { total += 1 }
        }
        #expect(total == 900)
    }

    @Test func laCarteDezoomeeNeListeRien() {
        let points = [point("a", 44.98, -93.27)]
        #expect(SelectionCarteUS.elements(points: points, plans: [], dans: zone(minneapolis, span: 20)).isEmpty)
        let r = CalculCarteUS.calculer(source: SourceFixe(points: points), zone: zone(minneapolis, span: 20), etatChoisi: nil)
        #expect(r.tropLoin)
        #expect(!r.sansDonnees)
    }

    @Test func seulsLesLieuxDeLaZoneSontGardes() {
        let source = SourceFixe(points: [point("ici", 44.98, -93.27), point("la-bas", 46.9, -92.1)])
        let r = CalculCarteUS.calculer(source: source, zone: zone(minneapolis, span: 0.5), etatChoisi: nil)
        #expect(r.elements.count == 1)
        #expect(r.etat == "MN")
        #expect(r.donneesChargees)
    }

    @Test func leModeleCalculeHorsDuThreadPrincipalEtRend() async {
        let modele = ModeleCarteUS(source: SourceFixe(points: [point("ici", 44.98, -93.27)]), agences: agences)
        modele.zoneChangee(zone(minneapolis, span: 0.5))
        for _ in 0..<100 {
            if !modele.resultat.elements.isEmpty { break }
            try? await Task.sleep(for: .milliseconds(20))
        }
        #expect(modele.resultat.elements.count == 1)
        #expect(modele.message == nil)
    }

    // MARK: Zone sans données

    @Test func unEtatSansDonneesLeDitAvecLeLienDeLAgence() {
        let texas = Coordonnee(latitude: 30.27, longitude: -97.74)
        let r = CalculCarteUS.calculer(source: SourceFixe(), zone: zone(texas, span: 0.5), etatChoisi: "TX")
        #expect(r.sansDonnees)
        let m = MessageSansDonneesUS.pour(etat: r.etat, agences: agences)
        #expect(m.texte.hasPrefix("Pas encore de données pour cet État"))
        #expect(m.texte.contains("Texas"))
        #expect(m.lien == URL(string: "https://tpwd.texas.gov/"))
        #expect(m.libelleLien.contains("Texas Parks and Wildlife"))
        #expect(!m.proposerChoixEtat)
    }

    @Test func unEtatInconnuProposeDeChoisirSonEtat() {
        let r = CalculCarteUS.calculer(source: SourceCarteUSVide(), zone: zone(Coordonnee(latitude: 35, longitude: -100), span: 0.5), etatChoisi: nil)
        #expect(r.sansDonnees)
        let m = MessageSansDonneesUS.pour(etat: r.etat, agences: agences)
        #expect(m.texte.hasPrefix("Pas encore de données pour cet État"))
        #expect(m.lien == nil)
        #expect(m.proposerChoixEtat)
    }

    @Test func leModeleDitPasDeDonneesPuisLeChoixDeLEtatDonneLeLien() async {
        let modele = ModeleCarteUS(source: SourceCarteUSVide(), agences: agences)
        modele.zoneChangee(zone(Coordonnee(latitude: 30.27, longitude: -97.74), span: 0.5))
        for _ in 0..<100 {
            if modele.message != nil { break }
            try? await Task.sleep(for: .milliseconds(20))
        }
        #expect(modele.message?.proposerChoixEtat == true)
        modele.etatChoisi = "TX"
        for _ in 0..<100 {
            if modele.message?.lien != nil { break }
            try? await Task.sleep(for: .milliseconds(20))
        }
        #expect(modele.message?.lien == URL(string: "https://tpwd.texas.gov/"))
    }

    @Test func unEtatChargeSansLieuDansLaZoneNeDitPasPasDeDonnees() {
        let r = CalculCarteUS.calculer(source: SourceFixe(points: [point("a", 47, -94)]), zone: zone(minneapolis, span: 0.1), etatChoisi: nil)
        #expect(r.elements.isEmpty)
        #expect(r.donneesChargees)
        #expect(!r.sansDonnees)
    }

    // MARK: Fiche

    @Test func laFicheDUnAccesPorteNomEtatSourceDateEtLienDeLAgence() {
        let f = FicheUS.pour(point: point("Hastings", 44.74, -92.85), agences: agences)
        #expect(f.titre == "Rampe Hastings")
        #expect(f.sousTitre.contains("Minnesota"))
        #expect(f.sousTitre.contains("Rampe de mise à l'eau"))
        #expect(f.source == "MN DNR, accès publics à l'eau")
        #expect(f.date == "2026-11-07")
        #expect(f.lienAgence == URL(string: "https://www.dnr.state.mn.us/"))
        #expect(f.libelleLien.contains("Minnesota DNR"))
    }

    @Test func laFicheDUnPlanDEauPrendSonLienPuisCeluiDeLEtatEtPorteSesAvis() {
        let avis = [AvisSanteCarteUS(planEauId: "A", texte: "Avis de proliférations d'algues", date: "2026-08-01", source: "MN DNR", lien: "https://www.dnr.state.mn.us/avis"),
                    AvisSanteCarteUS(planEauId: "B", texte: "Autre lac", date: "2026-08-02", source: "MN DNR", lien: nil)]
        let f = FicheUS.pour(plan: plan("A", 45, -93), avis: avis, agences: agences)
        #expect(f.lienAgence == URL(string: "https://www.dnr.state.mn.us/lakefind/"))
        #expect(f.avis.count == 1)
        #expect(f.avis.first?.lien == URL(string: "https://www.dnr.state.mn.us/avis"))
        // Lien propre en http : jamais gardé, on retombe sur la page de l'agence de l'État.
        let http = FicheUS.pour(plan: plan("A", 45, -93, lien: "http://exemple.org/lac"), avis: [], agences: agences)
        #expect(http.lienAgence == URL(string: "https://www.dnr.state.mn.us/"))
    }

    @Test func sansSourceLaFicheDitDonneeAbsenteJamaisUnAcces() {
        let f = FicheUS.pour(point: point("x", 45, -93, source: "  "), agences: agences)
        #expect(f.source == TextesCarteUS.donneeAbsente)
    }

    @Test func sansAgenceConnueIlNYAPasDeLienInvente() {
        let f = FicheUS.pour(point: point("x", 45, -93, etat: "ND"), agences: agences)
        #expect(f.lienAgence == nil)
        #expect(f.sousTitre.contains("ND"))
    }

    @Test func lAdresseDeLAgenceEstToujoursEnHttps() {
        #expect(lienHttpsCarteUS("http://exemple.org") == nil)
        #expect(lienHttpsCarteUS(nil) == nil)
        #expect(lienHttpsCarteUS("https://exemple.org/a") != nil)
    }

    // MARK: Aucun mot interdit

    @Test func aucunTexteAfficheNeContientDeMotInterdit() {
        let avisUn = [AvisSanteCarteUS(planEauId: "A", texte: "Avis", date: "2026-08-01", source: "MN DNR", lien: nil)]
        let fiches = [FicheUS.pour(point: point("a", 45, -93), agences: agences),
                      FicheUS.pour(plan: plan("A", 45, -93), avis: avisUn, agences: agences),
                      FicheUS.pour(point: point("x", 45, -93, source: ""), agences: agences)]
        var textes = TextesCarteUS.tous
        for f in fiches { textes += f.textes }
        for texte in textes {
            #expect(motInterdit(dans: texte) == nil, Comment(rawValue: "mot interdit dans : " + texte))
        }
        for m in [MessageSansDonneesUS.pour(etat: "TX", agences: agences), MessageSansDonneesUS.pour(etat: nil, agences: agences)] {
            #expect(motInterdit(dans: m.texte) == nil)
            #expect(motInterdit(dans: m.libelleLien) == nil)
        }
    }

    @Test func lesFichiersDuLotNeContiennentAucunMotInterdit() throws {
        let racine = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let dossier = racine.appendingPathComponent("App/CarteUS")
        let fichiers = try #require(FileManager.default.enumerator(at: dossier, includingPropertiesForKeys: nil))
        var lus = 0
        for cas in fichiers {
            guard let url = cas as? URL, url.pathExtension == "swift" else { continue }
            let texte = try String(contentsOf: url, encoding: .utf8)
            lus += 1
            #expect(motInterdit(dans: texte) == nil, Comment(rawValue: "mot interdit dans " + url.lastPathComponent))
        }
        #expect(lus >= 5)
    }
}
