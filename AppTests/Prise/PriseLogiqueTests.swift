import CoreGraphics
import Foundation
import Testing
import Core
@testable import BuildChallenge

@MainActor
struct PriseLogiqueTests {
    private func entree(_ id: String, nom: String, confusions: [Confusion] = []) -> EspecePechable {
        EspecePechable(espece: Espece(id: id), nom: nom, nomLatin: nom, image: id, confusions: confusions)
    }

    @Test func sosiesDejaTranchesDansUnGroupeDuModele() {
        var aquitain = entree("brochet-aquitain", nom: "Brochet aquitain"); aquitain.classeModele = "brochet"
        var brochet = entree("brochet", nom: "Brochet", confusions: [Confusion(avec: aquitain.espece, critere: "c", source: "s")])
        brochet.classeModele = "brochet"
        let cat = [brochet, aquitain]
        #expect(PriseLogique.sosiesDejaTranches(brochet, classe: "brochet", catalogue: cat))
        #expect(!PriseLogique.sosiesDejaTranches(brochet, classe: nil, catalogue: cat))
        #expect(!PriseLogique.sosiesDejaTranches(brochet, classe: "autre", catalogue: cat))
    }

    @Test func grilleGroupeParFamilleEtMetLesEspecesDuCoinEnPremier() {
        let catalogue = [entree("sandre", nom: "Sandre"), entree("brochet", nom: "Brochet"), entree("truite-fario", nom: "Truite fario")]
        let proches = [EspeceProche(espece: Espece(id: "sandre"), nPeches: 3, annee: 2024, ouverture: .ouverte)]
        let groupes = PriseLogique.groupes(catalogue: catalogue, proches: proches)
        #expect(groupes.map { $0.famille } == [.salmonides, .carnassiers])
        #expect(groupes[1].especes.map { $0.espece.id } == ["sandre", "brochet"])
        #expect(groupes[1].duCoin == ["sandre"])
    }

    @Test func classeQuiRegroupeFiltreLaGrille() {
        var a = entree("lamproie-marine", nom: "Lamproie marine"); a.classeModele = "lamproie"
        let b = entree("brochet", nom: "Brochet")
        let groupes = PriseLogique.groupes(catalogue: [a, b], proches: [], filtreClasse: "lamproie")
        #expect(groupes.flatMap { $0.especes }.map { $0.espece.id } == ["lamproie-marine"])
    }

    @Test func sosiesLusDansLesDonnees() {
        let fario = entree("truite-fario", nom: "Truite fario")
        let arc = entree("truite-arc-en-ciel", nom: "Truite arc-en-ciel",
                         confusions: [Confusion(avec: fario.espece, critere: "critere", source: "source")])
        let s = PriseLogique.sosies(de: arc, catalogue: [fario, arc])
        #expect(s.count == 1)
        #expect(s[0].entree.espece.id == "truite-fario")
        #expect(s[0].confusion.source == "source")
        #expect(PriseLogique.demandeSosies(arc))
        #expect(!PriseLogique.demandeSosies(fario))
    }

    @Test func anguilleDemandeToujoursSonStade() {
        #expect(PriseLogique.estAnguille(Espece(id: "anguille-jaune")))
        #expect(PriseLogique.stade(de: Espece(id: "anguille-argentee")) == .argentee)
        #expect(PriseLogique.stade(de: Espece(id: "civelle")) == .civelle)
        #expect(PriseLogique.stade(de: Espece(id: "brochet")) == nil)
    }

    @Test func consigneAvantConfirmationEstRelacheLa() {
        #expect(PriseLogique.consigneAvantConfirmation == "Relâche-la")
    }

    @Test func tropPresDeLaMailleVientDesLignesDeCore() {
        let ligne = LigneControle(type: .taille, etat: .aVerifierSurPlace, raison: .tropPresDeLaMaille, phrase: "p")
        #expect(PriseLogique.tropPresDeLaMaille(ResultatControle(lignes: [ligne], consigne: .mesureLaSurUneToise)))
        #expect(!PriseLogique.tropPresDeLaMaille(ResultatControle(lignes: [], consigne: .relacheLa)))
    }

    @Test func poidsAffichePourUnBrochet() {
        let p = PoidsEstime(kilos: 1.4, minKilos: 1.2, maxKilos: 1.6, source: "s")
        #expect(PriseLogique.texteDuPoids(p) == "≈ 1,4 kg estimé")
        #expect(PriseLogique.calculePasPese == "Calculé, pas pesé")
    }

    @Test func familleDesEspecesDeLaListeNationale() {
        for id in Espece.identifiantsNationaux {
            #expect(PriseFamille.allCases.contains(PriseFamille.de(id)))
        }
        #expect(PriseFamille.de("esturgeon-europeen") == .migrateurs)
        #expect(PriseFamille.de("ecrevisse-signal") == .ecrevisses)
    }
}

@MainActor
struct ToiseCalibrageTests {
    private func texte(_ valeur: Int, x: Double, y: Double = 100) -> TexteLu {
        TexteLu(texte: String(valeur), rect: CGRect(x: x - 10, y: y - 10, width: 20, height: 20))
    }

    @Test func litUneToiseHorizontale() throws {
        // 10 cm tous les 100 pixels, butée à x = 50.
        let textes = [texte(0, x: 50), texte(10, x: 150), texte(20, x: 250), texte(30, x: 350), texte(40, x: 450)]
        let c = try #require(ToiseCalibrage.lire(textes))
        #expect(c.axe == .horizontal)
        #expect(abs(c.longueurCm(boutDeLaQueue: CGPoint(x: 400, y: 120)) - 35) < 0.1)
    }

    @Test func litUneToiseVerticale() throws {
        let textes = [texte(0, x: 80, y: 700), texte(10, x: 80, y: 600), texte(20, x: 80, y: 500), texte(30, x: 80, y: 400)]
        let c = try #require(ToiseCalibrage.lire(textes))
        #expect(c.axe == .vertical)
        #expect(abs(c.longueurCm(boutDeLaQueue: CGPoint(x: 90, y: 450)) - 25) < 0.1)
    }

    @Test func rienDeCoherentDonnePasDeCalibrage() {
        #expect(ToiseCalibrage.lire([]) == nil)
        #expect(ToiseCalibrage.lire([texte(10, x: 100), texte(20, x: 200)]) == nil)
        // chiffres dans le désordre : écart trop grand
        let fouillis = [texte(0, x: 50), texte(40, x: 150), texte(10, x: 250), texte(30, x: 350)]
        #expect(ToiseCalibrage.lire(fouillis) == nil)
    }
}

@MainActor
struct PriseModeleTests {
    private func modele() -> PriseModele {
        let contexte = PriseContexte(coordonnee: Coordonnee(latitude: 48.8, longitude: 2.4),
                                     lieu: Lieu(departement: Departement(code: "94")), lieuFlou: "La Marne · 94",
                                     date: Date(timeIntervalSince1970: 1_792_065_600), prisesDuJour: [])
        return PriseModele(services: .faux, contexte: contexte, terminer: { _ in })
    }

    @Test func avantConfirmationAucunControleNiPoids() {
        let m = modele()
        #expect(m.controle == nil)
        #expect(m.poids == nil)
    }

    @Test func apresConfirmationEtTailleLeControleEtLePoidsArrivent() throws {
        let m = modele()
        let brochet = try #require(m.catalogue.first { $0.espece.id == "brochet" })
        m.choisir(brochet)
        #expect(m.etape == .taille)
        #expect(m.controle == nil)
        m.longueurCm = 60
        m.confirmerLaTaille()
        #expect(m.controle != nil)
        #expect(m.poids != nil)
        #expect(m.methode == .saisie)
    }

    @Test func lAnguilleDemandeSonStade() throws {
        let m = modele()
        let anguille = try #require(m.catalogue.first { PriseLogique.estAnguille($0.espece) })
        m.choisir(anguille)
        #expect(m.etape == .stade)
    }

    @Test func unSosieCoûteuxMontreLesSosiesAvantLaConfirmation() throws {
        let m = modele()
        let signal = try #require(m.catalogue.first { $0.espece.id == "ecrevisse-signal" })
        m.choisir(signal)
        #expect(m.etape == .sosies(signal))
        #expect(m.especeConfirmee == nil)
    }
}
