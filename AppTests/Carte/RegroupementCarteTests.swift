import Foundation
import Testing
import Core
@testable import BuildChallenge

/// L17 : 60 éléments au plus à l'écran, grappes numérotées, trois niveaux de zoom, halo pour une station `recalee == false`.
/// Écrit sans compiler (PC Windows) : à lancer sous Xcode.
struct RegroupementCarteTests {

    /// Un semis régulier de stations sur la France métropolitaine.
    private func semis(_ n: Int, recalee: (Int) -> Bool = { _ in true }) -> [PointCarte] {
        (0..<n).map { i in
            let lat = 42.5 + Double(i % 70) * 0.1
            let lon = -4.5 + Double(i / 70 % 90) * 0.1
            return PointCarte(id: "p\(i)", coordonnee: Coordonnee(latitude: lat, longitude: lon), recalee: recalee(i))
        }
    }

    private func region(span: Double) -> ZoneCarte {
        ZoneCarte(centre: Coordonnee(latitude: 46.2, longitude: 1.5), spanLatitude: span, spanLongitude: span * 1.2)
    }

    // MARK: 60 éléments au plus, à chaque niveau

    @Test func aucunNiveauNeDepasseSoixanteElements() {
        let tous = semis(6000)
        for span in [11.0, 6.5, 3.7, 1.5, 1.2, 0.4, 0.14] {
            let elements = Regroupeur.elements(points: tous, region: region(span: span))
            #expect(elements.count <= Regroupeur.maximum, "étendue \(span) : \(elements.count) éléments")
        }
    }

    @Test func laGrilleNeDepasseJamaisLeBudget() {
        for maximum in 1...100 {
            for niveau in [NiveauZoomCarte.large, .moyen, .proche] {
                let (lignes, colonnes) = Regroupeur.grille(maximum: maximum, niveau: niveau)
                #expect(lignes >= 1 && colonnes >= 1)
                #expect(lignes * colonnes <= maximum, "budget \(maximum) niveau \(niveau) : \(lignes)x\(colonnes)")
            }
        }
    }

    @Test func lesStationsEtLEauTiennentEnsembleDansSoixante() {
        #expect(Regroupeur.maximumStationsAvecEau + Regroupeur.maximumEau == Regroupeur.maximum)
        #expect(Regroupeur.maximumStations(pour: .france) == 60)
        #expect(Regroupeur.maximumStations(pour: region(span: 0.4)) == 40)
    }

    // MARK: Trois niveaux de zoom

    @Test func lesTroisNiveauxSuiventLesEtenduesDeLaCarte() {
        #expect(NiveauZoomCarte.pour(spanLatitude: 11) == .large)
        #expect(NiveauZoomCarte.pour(spanLatitude: 3.7) == .moyen)
        #expect(NiveauZoomCarte.pour(spanLatitude: 1.2) == .proche)
        #expect(NiveauZoomCarte.pour(spanLatitude: Self.etendueOuverture) == .proche)
        #expect(NiveauZoomCarte.large < .moyen && NiveauZoomCarte.moyen < .proche)
    }

    private static let etendueOuverture = ModeleCarte.etendueOuverture

    @Test func deuxTouchersSurUneGrappeAmenentDeLaFranceAuNiveauProche() {
        let centre = Coordonnee(latitude: 46.2, longitude: 1.5)
        var vue = ZoneCarte.france
        #expect(NiveauZoomCarte.pour(spanLatitude: vue.spanLatitude) == .large)
        vue = Regroupeur.zoom(sur: centre, depuis: vue)
        #expect(NiveauZoomCarte.pour(spanLatitude: vue.spanLatitude) == .moyen)
        vue = Regroupeur.zoom(sur: centre, depuis: vue)
        #expect(NiveauZoomCarte.pour(spanLatitude: vue.spanLatitude) == .proche)
    }

    @Test func plusOnZoomePlusLaGrilleEstFine() {
        let g = [NiveauZoomCarte.large, .moyen, .proche].map { Regroupeur.grille(maximum: 60, niveau: $0) }
        let cases = g.map { $0.lignes * $0.colonnes }
        #expect(cases[0] < cases[1] && cases[1] < cases[2])
    }

    @Test func moinsDeSoixantePointsVisiblesSontDesEpinglesAChaqueNiveau() {
        let peu = semis(40)
        for span in [11.0, 3.7, 0.4] {
            let elements = Regroupeur.elements(points: peu, region: region(span: span).agrandie(pour: peu))
            let epingles = elements.filter { if case .point = $0 { return true } else { return false } }
            #expect(epingles.count == elements.count)
        }
    }

    // MARK: Grappes numérotées

    @Test func laSommeDesGrappesEtDesEpinglesEstLeNombreDeStationsVisibles() {
        let tous = semis(3000)
        let vue = ZoneCarte.france
        let elements = Regroupeur.elements(points: tous, region: vue)
        let total = elements.reduce(0) { somme, e in
            switch e {
            case .point: return somme + 1
            case .groupe(_, _, let n): return somme + n
            }
        }
        #expect(total == tous.filter { vue.contient($0.coordonnee) }.count)
        #expect(elements.contains { if case .groupe = $0 { return true } else { return false } })
    }

    // MARK: Halo : station non recalée

    @Test func laStationNonRecaleeGardeSonDrapeauJusquAuPoint() {
        let a = PointCarte(id: "A", coordonnee: Coordonnee(latitude: 48.8, longitude: 2.4), recalee: false)
        let b = PointCarte(id: "B", coordonnee: Coordonnee(latitude: 48.9, longitude: 2.5))
        let elements = Regroupeur.elements(points: [a, b], region: region(span: 3))
        let halos = elements.compactMap { e -> PointCarte? in
            if case .point(let p) = e, !p.recalee { return p } else { return nil }
        }
        #expect(halos.map(\.id) == ["A"])
        #expect(b.recalee)
    }

    @Test func leHaloCompteDansLesSoixanteElements() {
        let tous = semis(4000) { $0 % 3 != 0 }
        let elements = Regroupeur.elements(points: tous, region: region(span: 0.9))
        #expect(elements.count <= Regroupeur.maximum)
    }

    @Test func lAncienFichierSansRecaleeEstLuAVrai() throws {
        let json = #"{"code":"A","departement":{"code":"94"},"coordonnee":{"latitude":48.8,"longitude":2.4},"releves":[]}"#
        let station = try JSONDecoder().decode(StationCarte.self, from: Data(json.utf8))
        #expect(station.recalee)
        #expect(station.point.recalee)
    }

    @Test func recaleeFauxSeRelitEtSeReecrit() throws {
        let json = #"{"code":"A","departement":{"code":"94"},"coordonnee":{"latitude":48.8,"longitude":2.4},"releves":[],"recalee":false}"#
        let station = try JSONDecoder().decode(StationCarte.self, from: Data(json.utf8))
        #expect(!station.recalee)
        #expect(!station.point.recalee)
        let relue = try JSONDecoder().decode(StationCarte.self, from: JSONEncoder().encode(station))
        #expect(relue == station)
    }

    @Test func lecturedeRecaleeSurUnTypeDeCore() {
        struct SansChamp { var codeStation = "A" }
        struct AvecChamp { var recalee = false }
        struct AvecOptionnel { var recalee: Bool? = nil }
        struct AvecVrai { var recalee: Bool? = true }
        #expect(LectureRecalage.valeur(de: SansChamp()))
        #expect(!LectureRecalage.valeur(de: AvecChamp()))
        #expect(LectureRecalage.valeur(de: AvecOptionnel()))
        #expect(LectureRecalage.valeur(de: AvecVrai()))
    }

    // MARK: L'eau ne mange pas le budget

    @Test func leauNEstDessineeQuAuNiveauProche() async {
        let eau = (0..<400).map { i in
            SpotEau(id: "e\(i)", nom: "Eau \(i)",
                    coordonnee: Coordonnee(latitude: 46 + Double(i % 20) * 0.01, longitude: 2 + Double(i / 20) * 0.01), origine: .coursDEau)
        }
        let loin = await calculerCoucheEau(spots: eau, region: ZoneCarte(centre: Coordonnee(latitude: 46.1, longitude: 2.1),
                                                                         spanLatitude: 6.5, spanLongitude: 7))
        #expect(loin.elements.isEmpty)
        let pres = await calculerCoucheEau(spots: eau, region: ZoneCarte(centre: Coordonnee(latitude: 46.1, longitude: 2.1),
                                                                         spanLatitude: 0.4, spanLongitude: 0.4))
        #expect(!pres.elements.isEmpty)
        #expect(pres.elements.count <= Regroupeur.maximumEau)
    }

    // MARK: Vue « proche » de celle du code

    @Test func uneVueDeLaMemeTailleEstProcheUneVueEloigneeNonPas() {
        let cible = ZoneCarte(centre: Coordonnee(latitude: 48.8, longitude: 2.4), spanLatitude: 0.14, spanLongitude: 0.14)
        let ajustee = ZoneCarte(centre: Coordonnee(latitude: 48.801, longitude: 2.402), spanLatitude: 0.16, spanLongitude: 0.1)
        #expect(ajustee.estProche(de: cible))
        let deplacee = ZoneCarte(centre: Coordonnee(latitude: 48.9, longitude: 2.4), spanLatitude: 0.14, spanLongitude: 0.14)
        #expect(!deplacee.estProche(de: cible))
        let zoomee = ZoneCarte(centre: cible.centre, spanLatitude: 0.5, spanLongitude: 0.5)
        #expect(!zoomee.estProche(de: cible))
    }
}

private extension ZoneCarte {
    /// Une vue assez grande pour contenir tous les points de `points` (pour les tests qui veulent « tout ce qui existe est visible »).
    func agrandie(pour points: [PointCarte]) -> ZoneCarte {
        self.contientTout(points) ? self : ZoneCarte(centre: Coordonnee(latitude: 46, longitude: 1), spanLatitude: 20, spanLongitude: 20)
    }

    func contientTout(_ points: [PointCarte]) -> Bool { points.allSatisfy { contient($0.coordonnee) } }
}
