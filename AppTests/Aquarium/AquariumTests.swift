import Core
import CoreGraphics
import Foundation
import Testing
@testable import BuildChallenge

@MainActor
struct AquariumTests {
    private nonisolated static let dateEssai = Date(timeIntervalSince1970: 1_760_000_000)
    private var dateEssai: Date { Self.dateEssai }

    private nonisolated static func prise(_ id: String, longueur: Double? = 40, gardee: Bool = false, origine: OrigineCarte = .priseReelle,
                       exemple: Bool = false, lieu: String? = "La Marne · 94") -> Prise {
        Prise(espece: Espece(id: id), origine: origine, longueurCm: longueur, mesure: .saisie, date: Self.dateEssai, lieuFlou: lieu,
              cheminPhoto: origine == .declaree ? nil : "photo.jpg", gardee: gardee, exemple: exemple)
    }

    private func entrees(_ prises: [Prise], rarete: NiveauRarete = .commun) -> [EntreeAquarium] {
        SelectionAquarium.entrees(depuis: prises, especes: EspecesFaux().especesPechables()) { _ in rarete }
    }

    // MARK: Qui nage

    @Test func seulesLesVraiesPrisesNagent() {
        let cartes = [Self.prise("brochet"), Self.prise("sandre", exemple: true), Self.prise("perche", origine: .declaree)]
        let nageurs = entrees(cartes)
        #expect(nageurs.count == 1)
        #expect(nageurs.first?.especeId == "brochet")
    }

    @Test func unPoissonRelacheEstMarque() {
        let nageurs = entrees([Self.prise("brochet", gardee: false), Self.prise("sandre", gardee: true)])
        #expect(nageurs[0].relachee)
        #expect(!nageurs[1].relachee)
    }

    @Test func laRareteVientDeLaFonctionDeCore() {
        let cartes = [Self.prise("brochet"), Self.prise("sandre")]
        let nageurs = SelectionAquarium.entrees(depuis: cartes, especes: []) { $0.espece.id == "brochet" ? .rare : .legendaire }
        #expect(nageurs[0].rarete == .rare && nageurs[0].estRare && !nageurs[0].estLegendaire)
        #expect(nageurs[1].rarete == .legendaire && nageurs[1].estLegendaire)
    }

    @Test func laRareteSansDepartementEstNonMesuree() {
        let nageurs = SelectionAquarium.entrees(depuis: [Self.prise("brochet")], services: EspecesFaux()) { _ in nil }
        #expect(nageurs[0].rarete == .nonMesuree)
    }

    @Test func laRareteLitLeServiceDeCore() {
        let nageurs = SelectionAquarium.entrees(depuis: [Self.prise("brochet")], services: EspecesFaux()) { _ in Departement(code: "94") }
        #expect(nageurs[0].rarete == .commun)
        #expect(nageurs[0].nom == "Brochet")
    }

    // MARK: Aucun lieu

    @Test func leTypeDEntreeNePorteAucunLieu() {
        let entree = entrees([Self.prise("brochet")])[0]
        let champs = Mirror(reflecting: entree).children.compactMap(\.label)
        #expect(!champs.isEmpty)
        for champ in champs {
            let bas = champ.lowercased()
            for interdit in ["lieu", "coordonn", "latitude", "longitude", "gps", "departement", "eau", "spot", "station", "photo", "chemin"] {
                #expect(!bas.contains(interdit), "le champ « \(champ) » ressemble à un lieu ou à une photo")
            }
        }
    }

    @Test func leLieuDeLaPriseNeChangeRienALEntree() {
        let id = UUID()
        func une(_ lieu: String?) -> EntreeAquarium {
            let p = Prise(id: id, espece: Espece(id: "brochet"), longueurCm: 60, date: dateEssai, lieuFlou: lieu, cheminPhoto: "p.jpg")
            return entrees([p])[0]
        }
        #expect(une("La Marne · 94") == une("Le Rhône · 69"))
        #expect(une("La Marne · 94") == une(nil))
    }

    // MARK: Taille et nage

    @Test func unGrosPoissonEstPlusGrandQuUnPetit() {
        #expect(Nage.largeur(longueurCm: 80) > Nage.largeur(longueurCm: 15))
        #expect(Nage.largeur(longueurCm: 15) >= 48)
        #expect(Nage.largeur(longueurCm: 300) <= 176)
        #expect(Nage.largeur(longueurCm: 80, largeurVitre: 780) == 2 * Nage.largeur(longueurCm: 80, largeurVitre: 390))
    }

    @Test func laNageEstStableEtResteDansLaVitre() {
        let id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        for espece in ["brochet", "perche-commune", "anguille-jaune", "gardon", "truite-fario"] {
            for t in stride(from: 0.0, to: 200.0, by: 0.7) {
                let p = Nage.position(id: id, especeId: espece, t: t)
                #expect((0.1...0.9).contains(p.x) && (0.14...0.84).contains(p.y))
                #expect(p == Nage.position(id: id, especeId: espece, t: t))
            }
        }
    }

    @Test func lePoissonSeRetourneEnNageantVersLaGauche() {
        let id = UUID()
        let sens = stride(from: 0.0, to: 120.0, by: 0.5).map { Nage.position(id: id, especeId: "brochet", t: $0).versLaDroite }
        #expect(sens.contains(true) && sens.contains(false))
    }

    @Test func chaqueEspeceNageADeuxFacons() {
        #expect(StyleNage.pour(especeId: "brochet") != StyleNage.pour(especeId: "perche-commune"))
        #expect(StyleNage.pour(especeId: "ablette") == StyleNage.pour(especeId: "ablette"))
        #expect(StyleNage.pour(especeId: "ablette") != StyleNage.pour(especeId: "goujon"))
    }

    @Test func uneOndeEcarteLesPoissonsProchesSeulement() {
        let centre = CGPoint(x: 0.5, y: 0.5)
        let proche = Nage.ecart(poisson: CGPoint(x: 0.6, y: 0.5), centre: centre, dt: 0.3)
        #expect(proche.dx > 0)
        let loin = Nage.ecart(poisson: CGPoint(x: 0.95, y: 0.5), centre: centre, dt: 0.3)
        #expect(loin == .zero)
        #expect(Nage.ecart(poisson: CGPoint(x: 0.6, y: 0.5), centre: centre, dt: -1) == .zero)
        #expect(abs(Nage.ecart(poisson: CGPoint(x: 0.6, y: 0.5), centre: centre, dt: 30).dx) < 0.001)
    }

    // MARK: Décors

    private func progression(especes: Int = 0, sessions: Int = 0, legendaire: Bool = false) -> Progression {
        Progression(especesDifferentes: especes, sessionsTerminees: sessions, aUnLegendaire: legendaire)
    }

    @Test func laRiviereSeDebloqueAvecCinqEspeces() {
        #expect(Decors.etat(.riviere, progression: progression(especes: 4), proOuvert: false)
                == .aGagner(actuel: 4, but: 5, phrase: "Prends 5 espèces différentes"))
        #expect(Decors.etat(.riviere, progression: progression(especes: 5), proOuvert: false) == .ouvert)
    }

    @Test func lEtangEtLaGrotte() {
        #expect(Decors.etat(.etang, progression: progression(sessions: 9), proOuvert: false) != .ouvert)
        #expect(Decors.etat(.etang, progression: progression(sessions: 10), proOuvert: false) == .ouvert)
        #expect(Decors.etat(.grotte, progression: progression(), proOuvert: true) != .ouvert)
        #expect(Decors.etat(.grotte, progression: progression(legendaire: true), proOuvert: false) == .ouvert)
        #expect(Decors.etat(.bassin, progression: progression(), proOuvert: false) == .ouvert)
    }

    @Test func lesDecorsProDependentDeLAbonnement() {
        for decor in Decor.allCases where decor.estPro {
            #expect(Decors.etat(decor, progression: progression(especes: 50, sessions: 50, legendaire: true), proOuvert: false) == .pro)
            #expect(Decors.etat(decor, progression: progression(), proOuvert: true) == .ouvert)
        }
        #expect(Decor.allCases.contains { $0.estPro })
    }

    @Test func laProgressionNeCompteQueLesVraiesPrises() {
        let cartes = [Self.prise("brochet"), Self.prise("brochet"), Self.prise("sandre", exemple: true), Self.prise("perche", origine: .declaree), Self.prise("gardon")]
        let p = Progression.depuis(prises: cartes, sessionsTerminees: -3) { $0.espece.id == "gardon" ? .legendaire : .commun }
        #expect(p.especesDifferentes == 2)
        #expect(p.sessionsTerminees == 0)
        #expect(p.aUnLegendaire)
        let sansLegende = Progression.depuis(prises: [Self.prise("sandre", exemple: true)], sessionsTerminees: 0) { _ in .legendaire }
        #expect(!sansLegende.aUnLegendaire)
    }

    // MARK: Modèle

    private func modele(sessions: Int, pro: Bool = false, stockage: StockageMemoire? = nil,
                        cartes: [Prise] = [Self.prise("brochet"), Self.prise("sandre"), Self.prise("perche")]) -> ModeleAquarium {
        let m = ModeleAquarium(stockage: stockage ?? StockageMemoire(), maintenant: dateEssai)
        m.mettreAJour(entrees: entrees(cartes), sessionsTerminees: sessions, proOuvert: pro)
        return m
    }

    @Test func unDecorProSansAbonnementOuvreLePaywall() {
        let sans = modele(sessions: 0)
        #expect(sans.choisir(.torrent) == .paywall)
        #expect(sans.decor == .bassin)
        let avec = modele(sessions: 0, pro: true)
        #expect(avec.choisir(.torrent) == .choisi)
        #expect(avec.decor == .torrent)
    }

    @Test func unDecorAGagnerNeSeChoisitPas() {
        let m = modele(sessions: 0)
        if case .verrouille = m.choisir(.riviere) {} else { Issue.record("la rivière doit rester verrouillée") }
        #expect(m.decor == .bassin)
    }

    @Test func leDecorChoisiSeRetrouve() {
        let stock = StockageMemoire()
        let m = modele(sessions: 0, pro: true, stockage: stock)
        _ = m.choisir(.nocturne)
        #expect(stock.decorChoisi == .nocturne)
        #expect(modele(sessions: 0, pro: true, stockage: stock).decor == .nocturne)
        // L'abonnement a pris fin : retour au bassin, sans plantage.
        #expect(modele(sessions: 0, pro: false, stockage: stock).decor == .bassin)
    }

    @Test func uneRationTombeSeulementSIlEnReste() {
        let stock = StockageMemoire()
        let m = modele(sessions: 2, stockage: stock)
        #expect(m.rationsRestantes == 2)
        #expect(m.lancerRation(x: 0.5, temps: 1))
        #expect(m.lancerRation(x: 0.4, temps: 2))
        #expect(m.rationsRestantes == 0)
        #expect(!m.lancerRation(x: 0.5, temps: 3))
        #expect(m.rations.count == 2)
        #expect(stock.rationsDonnees == 2)
        // Une nouvelle session redonne une ration, même bredouille.
        m.mettreAJour(entrees: m.entrees, sessionsTerminees: 3, proOuvert: false)
        #expect(m.rationsRestantes == 1)
    }

    @Test func sansSessionAucuneRation() {
        let m = modele(sessions: 0)
        #expect(!m.lancerRation(x: 0.5, temps: 0))
        #expect(m.rations.isEmpty)
    }

    @Test func laRationAttireLesDeuxPoissonsLesPlusProches() {
        let m = modele(sessions: 1)
        #expect(m.lancerRation(x: 0.5, temps: 0))
        #expect(m.rations[0].attires.count == 2)
    }

    @Test func leTempsSArreteEnPause() {
        let m = ModeleAquarium(stockage: StockageMemoire(), maintenant: dateEssai)
        #expect(m.temps(a: dateEssai.addingTimeInterval(5)) == 5)
        m.mettreEnPause(a: dateEssai.addingTimeInterval(5))
        #expect(m.temps(a: dateEssai.addingTimeInterval(60)) == 5)
        m.reprendre(a: dateEssai.addingTimeInterval(65))
        #expect(m.temps(a: dateEssai.addingTimeInterval(66)) == 6)
    }

    @Test func lAquariumVideNePlantePas() {
        let m = modele(sessions: 0, cartes: [])
        #expect(m.entrees.isEmpty)
        m.toucherVitre(a: CGPoint(x: 0.5, y: 0.5), temps: 0)
        #expect(!m.lancerRation(x: 0.5, temps: 0))
    }

    @Test func immobilesAvecReduireLesAnimations() {
        let m = modele(sessions: 1)
        m.toucherVitre(a: CGPoint(x: 0.5, y: 0.5), temps: 0)
        for e in m.entrees {
            #expect(m.positionFixe(de: e) == m.positionFixe(de: e))
            #expect(m.positionFixe(de: e) == Nage.position(id: e.id, especeId: e.especeId, t: 0))
        }
    }

    @Test func lesPoissonsRestentDansLaVitreAvecOndesEtRations() {
        let m = modele(sessions: 5)
        m.toucherVitre(a: CGPoint(x: 0.5, y: 0.5), temps: 1)
        _ = m.lancerRation(x: 0.95, temps: 1)
        for t in stride(from: 0.0, to: 30.0, by: 0.25) {
            for e in m.entrees {
                let p = m.position(de: e, temps: t)
                #expect((0.08...0.92).contains(p.x) && (0.12...0.86).contains(p.y))
            }
        }
    }

    @Test func laVoixOffDitTout() {
        let e = entrees([Self.prise("brochet", longueur: 62.4)], rarete: .rare)[0]
        #expect(e.texteVoixOff == "Brochet, rare, 62 cm, relâché")
    }
}
