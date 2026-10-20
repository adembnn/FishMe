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

    @Test func especesAjouteesRangeesDansLaBonneFamille() {
        for id in ["brochet-aquitain", "black-bass-petite-bouche", "crapet-de-roche", "barbue-de-riviere"] {
            #expect(PriseFamille.de(id) == .carnassiers, "\(id)")
        }
        for id in ["sterlet", "bar", "raye-hybride"] { #expect(PriseFamille.de(id) == .migrateurs, "\(id)") }
        for id in ["gobie-a-taches-noires", "gobie-de-kessler", "epinochette"] { #expect(PriseFamille.de(id) == .petitsDeFond, "\(id)") }
        #expect(PriseFamille.de("poisson-rouge") == .carpes)
        #expect(PriseFamille.de("hybrides") == .cyprinides)
    }

    @Test func tuileDeGroupeSansNomBrut() {
        let chat = entree("poisson-chat", nom: "Poisson-chat (Ameiurus melas ; Ameiurus nebulosus [?])")
        #expect(PriseLogique.nomDeGroupe(classe: "poisson_chat", membres: [chat]) == "Poisson-chat ou barbue")
        #expect(PriseLogique.nomDeGroupe(classe: "inconnue", membres: [chat]) == "Poisson-chat")
        #expect(PriseLogique.nomDeGroupe(classe: "hotu_toxostome", membres: []) == "Hotu ou toxostome")
        #expect(PriseLogique.nomCourt("Anguille européenne, stade jaune") == "Anguille européenne")
        #expect(PriseLogique.nomCourt("Carassin argenté / poisson rouge") == "Carassin argenté")
        for nom in PriseLogique.nomsDeGroupe.values { #expect(!nom.contains("(") && !nom.contains("[")) }
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

    /// Textes lus par Vision sur de vraies photos de prises (16 oct. 2026, `reports/reconnaissance/toise.md`).
    private func l(_ s: String, _ x: Double, _ y: Double, _ w: Double, _ h: Double) -> TexteLu {
        TexteLu(texte: s, rect: CGRect(x: x, y: y, width: w, height: h))
    }

    @Test func vraiePhotoGraduationEnUnSeulTexte() throws {
        // Photo 3 : mètre pliant, Vision rend « 10 11 12 … 33 » d'un bloc, avec des chiffres collés (« 19200 »).
        let textes = [
            l("}»4N 5¿6 ₫D]", 68, 286, 78, 10),
            l("10 11 12 13 14 15 16 17 18 19200 21 22 23024 25 26 27 28 29 3 0 31 32 33", 201.88, 283.69, 478.23, 19.06),
        ]
        let c = try #require(ToiseCalibrage.lire(textes, taille: CGSize(width: 700, height: 394)))
        #expect(c.axe == .horizontal)
        #expect(abs(c.cm(en: 680) - 33) < 1.5)
    }

    @Test func vraiePhotoTapisImprime() throws {
        // Photo 1 : tapis de mesure, « 10. 20. 30. 40. 50. » d'un bloc, plus la marque du tapis.
        let textes = [
            l("10. 20. 30. 40. 50.", 159.9, 136.91, 501.4, 76.25),
            l("a #mcjorfish", 95.09, 466.16, 59.68, 18.48),
            l("www.major-fish.de | @ tmajorfish", 237.05, 442.42, 153.7, 29.43),
            l("www.major-fish.de | @ #majortish", 469.17, 425.38, 143.6, 24.9),
        ]
        let c = try #require(ToiseCalibrage.lire(textes, taille: CGSize(width: 700, height: 525)))
        #expect(abs(c.cm(en: 159.9 + 501.4 * 17 / 19) - 50) < 1.5)
    }

    @Test func vraiePhotoRubanAvecBruit() throws {
        // Photo 8 : ruban jaune, Vision mêle chiffres et bruit (« 405@8--7==8 »).
        let textes = [
            l("3 405@8--7==8 @9 =10 115_12-13-14 15 18 17 18 19", 105.68, 300.2, 372.57, 27.45),
            l("22 23 24", 516, 302, 62, 12),
            l("25", 586, 302, 12, 10),
        ]
        let c = try #require(ToiseCalibrage.lire(textes, taille: CGSize(width: 600, height: 450)))
        #expect(abs(c.cm(en: 592) - 25) < 1.5)
    }

    @Test func vraiePhotoJournalNeDonnePasDeFausseToise() {
        // Photo 7 : seuls « 10 » et « 20 » du mètre sont lus, au milieu d'un journal (prix, tailles d'écran).
        let journal = [
            l("LCD-TV", -1.04, 330.61, 99.18, 103.79),
            l("107 cm/42\"", 28.84, 321.88, 77.76, 84.98),
            l("• LG", 334, 400, 22, 48),
            l("Litet Siced", 354, 384, 10, 38),
            l("2 LV 375 S", 362, 402, 12, 46),
            l("10", 202, 266, 16, 12),
            l("20", 382, 264, 18, 16),
            l("Alle Preise Abholpreise. Keine &", 426.97, 283.69, 18.51, 164.6),
            l("ehmej", 426, 238, 16, 30),
            l("RAUSVERI", 464.09, 211.93, 65.85, 238.25),
            l("WIR SO:", 522.45, 251.1, 72.42, 200.48),
            l("I Fina", 32.87, -1.6, 19.92, 32.57),
            l("24 klei", 62, 0, 12, 32),
            l("ab 10 €", 76, 0, 12, 32),
            l("vom 6.", 90, 0, 10, 32),
            l("integr. HD-", 168, 0, 10, 50),
            l("digitaler Hl", 189.53, -0.38, 14.37, 52.83),
            l("für Antenn", 202, 0, 10, 50),
            l("USB-Anschi", 226, 0, 10, 52),
            l("D9", 298, 0, 98, 126),
            l("Barpreis oder 24 x 24,95 l", 407.07, -0.26, 17.46, 134.52),
            l("JF:", 462, 88, 48, 62),
            l("Y PLAT", 501.74, -5.87, 68.84, 133.89),
        ]
        #expect(ToiseCalibrage.lire(journal, taille: CGSize(width: 600, height: 450)) == nil)
        let carton = [
            l("o doberg Zi", 81.63, 224.28, 56.58, 13.02),
            l("Angel", 308, 90, 40, 12),
            l("Masters", 296.95, 101.09, 60.15, 21.05),
            l("2012", 310, 118, 34, 14),
        ]
        #expect(ToiseCalibrage.lire(carton, taille: CGSize(width: 448, height: 336)) == nil)
    }
}

@MainActor
struct PriseModeleTests {
    private func modele() -> PriseModele {
        let contexte = PriseContexte(coordonnee: Coordonnee(latitude: 48.8, longitude: 2.4),
                                     lieu: Lieu(departement: Departement(code: "94")), lieuFlou: "La Marne · 94",
                                     date: Date(timeIntervalSince1970: 1_792_065_600), prisesDuJour: [])
        let m = PriseModele(services: .faux, contexte: contexte, terminer: { _ in })
        // Mémoire de taille isolée : une taille confirmée par un autre test ne doit pas déplacer le départ du curseur.
        m.memoire = MemoireTaille(defauts: UserDefaults(suiteName: "prise-logique-\(UUID().uuidString)")!)
        return m
    }

    @Test func avantConfirmationAucunControleNiPoids() {
        let m = modele()
        #expect(m.controle == nil)
        #expect(m.poids == nil)
    }

    /// Adem, 16 oct. : l'espèce confirmée mène tout droit à la carte, sans sosies ni taille ; sans taille, ni poids ni longueur.
    @Test func apresConfirmationOnVaToutDroitALaCarte() throws {
        let m = modele()
        let brochet = try #require(m.catalogue.first { $0.espece.id == "brochet" })
        m.choisir(brochet)
        #expect(m.etape == .resultat)
        #expect(m.controle != nil)
        #expect(m.poids == nil)
        #expect(!m.tailleConnue)
    }

    @Test func leCurseurDemarreAuMilieuEtDoitBouger() throws {
        let m = modele()
        let brochet = try #require(m.catalogue.first { $0.espece.id == "brochet" })
        m.choisir(brochet)
        #expect(m.longueurCm == PriseLogique.tailleDeDepart)
        #expect(PriseLogique.plageTaille.contains(m.longueurCm) && m.longueurCm != 40)
        #expect(!m.curseurBouge)
        m.deplacerCurseur(55)
        #expect(m.curseurBouge)
    }

    @Test func retourRevientALEtapeDAvant() throws {
        let m = modele()
        let brochet = try #require(m.catalogue.first { $0.espece.id == "brochet" })
        m.ouvrirLaGrille()
        m.choisir(brochet)
        #expect(m.etape == .resultat)
        m.retour()
        #expect(m.etape == .grille(classe: nil))
        m.retour()
        #expect(m.etape == .photo)
        m.retour()
        #expect(m.etape == .photo)
    }

    @Test func lAnguilleDemandeSonStade() throws {
        let m = modele()
        let anguille = try #require(m.catalogue.first { PriseLogique.estAnguille($0.espece) })
        m.choisir(anguille)
        #expect(m.etape == .stade)
    }

    /// Adem, 16 oct. : plus d'étape intermédiaire, un toucher sur l'espèce confirme et ouvre la carte de la prise
    /// (`PriseModele.confirmer`). L'ancien test attendait l'écran des sosies avant la confirmation.
    @Test func unSosieCoûteuxConfirmeDirectementLEspece() throws {
        let m = modele()
        let signal = try #require(m.catalogue.first { $0.espece.id == "ecrevisse-signal" })
        #expect(PriseLogique.demandeSosies(signal))
        m.choisir(signal)
        #expect(m.etape == .resultat)
        #expect(m.especeConfirmee == signal)
    }
}
