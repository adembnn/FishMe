import Foundation
import Testing
@testable import Core

// ⚠ à vérifier : tests écrits sans compilateur Swift, non exécutés.
@Suite("Records et compteurs (N4)")
struct RecordsTests {
    static let brochet = Espece(id: "brochet", codeSandre: "2151")
    static let sandre = Espece(id: "sandre", codeSandre: "2195")
    static let perche = Espece(id: "perche-commune", codeSandre: "2193")
    static let carpe = Espece(id: "carpe-commune", codeSandre: "2032")
    static let aucunSeuil: (Espece) -> Double? = { _ in nil }

    static func prise(_ e: Espece = brochet, _ cm: Double? = nil, jour: Int = 1, mois: Int = 9, origine: OrigineCarte = .priseReelle,
                      exemple: Bool = false, mesure: MethodeMesure? = .saisie, lieu: String? = "la Marne") -> Prise {
        Prise(espece: e, origine: origine, longueurCm: cm, mesure: mesure, date: utc(2026, mois, jour), lieuFlou: lieu, exemple: exemple)
    }

    static func sortie(fin: Bool = true, _ prises: [Prise] = []) -> Sortie {
        Sortie(debut: utc(2026, 9, 1, 8), fin: fin ? utc(2026, 9, 1, 11) : nil, prises: prises)
    }

    // MARK: Records

    @Test("1. aucune prise : tout est à zéro")
    func aucunePrise() {
        let b = MoteurRecords.bilan(prises: [], sorties: [], seuilTropheeCm: Self.aucunSeuil)
        #expect(b.records.isEmpty)
        #expect(b.especesSansTaille.isEmpty)
        #expect(b.compteurs == CompteursPersonnels(sorties: 0, especesTrouvees: 0, bredouilles: 0))
    }

    @Test("2. une seule prise : un souvenir, première taille")
    func uneSeulePrise() {
        let p = Self.prise(Self.brochet, 62.0)
        let b = MoteurRecords.bilan(prises: [p], sorties: [], seuilTropheeCm: Self.aucunSeuil)
        #expect(b.records.count == 1)
        #expect(b.records.first?.nombreDePrises == 1)
        #expect(b.records.first?.priseID == p.id)
        #expect(MoteurRecords.evenement(pour: p, parmi: []) == .premiereTaille)
    }

    @Test("3. la seconde est plus grande : nouveau souvenir")
    func secondePlusGrande() {
        let a = Self.prise(Self.brochet, 60.0, jour: 1)
        let b = Self.prise(Self.brochet, 72.5, jour: 5)
        #expect(MoteurRecords.evenement(pour: b, parmi: [a]) == .nouveauSouvenir(ancienCm: 60.0, nouveauCm: 72.5))
        let bilan = MoteurRecords.bilan(prises: [a, b], sorties: [], seuilTropheeCm: Self.aucunSeuil)
        #expect(bilan.records.first?.longueurCm == 72.5)
        #expect(bilan.records.first?.priseID == b.id)
        #expect(bilan.records.first?.nombreDePrises == 2)
    }

    @Test("4. tailles égales : la plus ancienne garde le souvenir, aucun événement")
    func taillesEgales() {
        let a = Self.prise(Self.brochet, 72.0, jour: 1, mois: 9)
        let b = Self.prise(Self.brochet, 72.0, jour: 5, mois: 10)
        for ordre in [[a, b], [b, a]] {
            let bilan = MoteurRecords.bilan(prises: ordre, sorties: [], seuilTropheeCm: Self.aucunSeuil)
            #expect(bilan.records.first?.priseID == a.id)
        }
        #expect(MoteurRecords.evenement(pour: b, parmi: [a]) == .aucun)
    }

    @Test("5. égalité au millimètre")
    func egaliteAuMillimetre() {
        let base = Self.prise(Self.brochet, 72.0, jour: 1)
        #expect(MoteurRecords.evenement(pour: Self.prise(Self.brochet, 72.04, jour: 2), parmi: [base]) == .aucun)
        #expect(MoteurRecords.evenement(pour: Self.prise(Self.brochet, 72.1, jour: 2), parmi: [base]) == .nouveauSouvenir(ancienCm: 72.0, nouveauCm: 72.1))
    }

    @Test("6. taille inconnue : pas de record, espèce sous « sans taille » seulement si aucune autre prise mesurée")
    func tailleInconnue() {
        let sans = Self.prise(Self.brochet, nil, jour: 2)
        let b1 = MoteurRecords.bilan(prises: [sans], sorties: [], seuilTropheeCm: Self.aucunSeuil)
        #expect(b1.records.isEmpty)
        #expect(b1.especesSansTaille == [Self.brochet])
        #expect(b1.compteurs.especesTrouvees == 1)
        let mesuree = Self.prise(Self.brochet, 55.0, jour: 1)
        let b2 = MoteurRecords.bilan(prises: [sans, mesuree], sorties: [], seuilTropheeCm: Self.aucunSeuil)
        #expect(b2.records.count == 1)
        #expect(b2.especesSansTaille.isEmpty)
        #expect(b2.records.first?.nombreDePrises == 2)
        #expect(MoteurRecords.evenement(pour: sans, parmi: [mesuree]) == .aucun)
    }

    @Test("7. longueur invalide : traitée comme inconnue, sans plantage",
          arguments: [0.0, -3.0, Double.nan, Double.infinity, -Double.infinity])
    func longueurInvalide(valeur: Double) {
        let p = Self.prise(Self.brochet, valeur)
        let b = MoteurRecords.bilan(prises: [p], sorties: [], seuilTropheeCm: Self.aucunSeuil)
        #expect(b.records.isEmpty)
        #expect(b.especesSansTaille == [Self.brochet])
        #expect(MoteurRecords.evenement(pour: p, parmi: []) == .aucun)
        let bonne = Self.prise(Self.brochet, 40.0)
        #expect(MoteurRecords.evenement(pour: bonne, parmi: [p]) == .premiereTaille)
    }

    @Test("8. prise plus petite : aucun événement, bilan inchangé")
    func plusPetite() {
        let grande = Self.prise(Self.brochet, 80.0, jour: 1)
        let petite = Self.prise(Self.brochet, 50.0, jour: 2)
        #expect(MoteurRecords.evenement(pour: petite, parmi: [grande]) == .aucun)
        let seule = MoteurRecords.bilan(prises: [grande], sorties: [], seuilTropheeCm: Self.aucunSeuil)
        let deux = MoteurRecords.bilan(prises: [grande, petite], sorties: [], seuilTropheeCm: Self.aucunSeuil)
        #expect(deux.records.first?.priseID == seule.records.first?.priseID)
        #expect(deux.records.first?.longueurCm == 80.0)
    }

    @Test("9. carte déclarée et carte d'exemple : jamais de record ni d'événement")
    func declareeEtExemple() {
        let declaree = Self.prise(Self.brochet, 99.0, origine: .declaree)
        let exemple = Self.prise(Self.brochet, 99.0, exemple: true)
        let b = MoteurRecords.bilan(prises: [declaree, exemple], sorties: [], seuilTropheeCm: Self.aucunSeuil)
        #expect(b.records.isEmpty)
        #expect(b.especesSansTaille.isEmpty)
        #expect(MoteurRecords.evenement(pour: declaree, parmi: []) == .aucun)
        #expect(MoteurRecords.evenement(pour: exemple, parmi: []) == .aucun)
        let petite = Self.prise(Self.brochet, 20.0)
        #expect(MoteurRecords.evenement(pour: Self.prise(Self.brochet, 30.0), parmi: [petite, declaree, exemple])
                == .nouveauSouvenir(ancienCm: 20.0, nouveauCm: 30.0))
    }

    @Test("10. la prise elle-même dans autres est ignorée")
    func priseDansAutres() {
        let a = Self.prise(Self.brochet, 60.0, jour: 1)
        let b = Self.prise(Self.brochet, 72.5, jour: 5)
        #expect(MoteurRecords.evenement(pour: b, parmi: [a, b]) == MoteurRecords.evenement(pour: b, parmi: [a]))
        #expect(MoteurRecords.evenement(pour: a, parmi: [a]) == .premiereTaille)
    }

    @Test("11. plusieurs espèces : un record chacune, tri par date décroissante puis id, ordre stable")
    func plusieursEspeces() {
        let prises = [
            Self.prise(Self.brochet, 70, jour: 3), Self.prise(Self.sandre, 50, jour: 9), Self.prise(Self.perche, 25, jour: 3),
            Self.prise(Self.carpe, 80, jour: 1), Self.prise(Self.brochet, 40, jour: 7, mois: 8),
        ]
        let b = MoteurRecords.bilan(prises: prises, sorties: [], seuilTropheeCm: Self.aucunSeuil)
        #expect(b.records.map(\.espece.id) == ["sandre", "brochet", "perche-commune", "carpe-commune"])
        #expect(MoteurRecords.bilan(prises: prises.reversed(), sorties: [], seuilTropheeCm: Self.aucunSeuil) == b)
        #expect(MoteurRecords.bilan(prises: prises, sorties: [], seuilTropheeCm: Self.aucunSeuil) == b)
    }

    @Test("12. trophée : strictement au-dessus du seuil ; sans seuil, faux et le souvenir reste")
    func trophee() {
        let seuil: (Espece) -> Double? = { _ in 90.0 }
        func record(_ cm: Double, _ s: (Espece) -> Double?) -> RecordEspece? {
            MoteurRecords.bilan(prises: [Self.prise(Self.brochet, cm)], sorties: [], seuilTropheeCm: s).records.first
        }
        #expect(record(90.0, seuil)?.estTrophee == false)
        #expect(record(90.1, seuil)?.estTrophee == true)
        #expect(record(95.0, Self.aucunSeuil)?.estTrophee == false)
        #expect(record(95.0, Self.aucunSeuil)?.longueurCm == 95.0)
    }

    @Test("13. la taille ne change ni les compteurs ni les espèces trouvées")
    func tailleSansEffetSurLesCompteurs() {
        func jeu(_ a: Double?, _ b: Double?) -> BilanRecords {
            let p = [Self.prise(Self.brochet, a, jour: 1), Self.prise(Self.sandre, b, jour: 2)]
            return MoteurRecords.bilan(prises: p, sorties: [Self.sortie(p), Self.sortie()], seuilTropheeCm: { _ in 10 })
        }
        let petit = jeu(20, 15), grand = jeu(150, 200), sans = jeu(nil, nil)
        #expect(petit.compteurs == grand.compteurs)
        #expect(petit.compteurs == sans.compteurs)
        #expect(petit.compteurs.especesTrouvees == 2)
    }

    // MARK: Compteurs

    @Test("14. sorties : seules les sorties terminées comptent")
    func sorties() {
        let s = [Self.sortie(), Self.sortie(), Self.sortie(), Self.sortie(fin: false)]
        #expect(MoteurRecords.bilan(prises: [], sorties: s, seuilTropheeCm: Self.aucunSeuil).compteurs.sorties == 3)
    }

    @Test("15. bredouilles : sans prise, ou seulement un exemple ou une déclarée")
    func bredouilles() {
        let s = [
            Self.sortie(),
            Self.sortie([Self.prise(Self.carpe, exemple: true)]),
            Self.sortie([Self.prise(Self.brochet, 50)]),
            Self.sortie(fin: false),
        ]
        let c = MoteurRecords.bilan(prises: [], sorties: s, seuilTropheeCm: Self.aucunSeuil).compteurs
        #expect(c.bredouilles == 2)
        #expect(c.sorties == 3)
        #expect(c.bredouilles <= c.sorties)
        let declaree = MoteurRecords.bilan(prises: [], sorties: [Self.sortie([Self.prise(Self.perche, origine: .declaree)])],
                                           seuilTropheeCm: Self.aucunSeuil)
        #expect(declaree.compteurs.bredouilles == 1)
    }

    @Test("16. espèces trouvées : déclarées comprises, exemples exclus")
    func especesTrouvees() {
        let cartes = [
            Self.prise(Self.brochet, 60), Self.prise(Self.brochet, 70, jour: 2), Self.prise(Self.sandre, 50),
            Self.prise(Self.perche, origine: .declaree), Self.prise(Self.carpe, exemple: true),
        ]
        #expect(MoteurRecords.bilan(prises: cartes, sorties: [], seuilTropheeCm: Self.aucunSeuil).compteurs.especesTrouvees == 3)
    }

    @Test("17. aucune sortie, des cartes déclarées seulement")
    func declareesSeulement() {
        let cartes = [Self.brochet, Self.sandre, Self.perche].map { Prise.declaree(espece: $0, date: utc(2026, 10, 1)) }
        let b = MoteurRecords.bilan(prises: cartes, sorties: [], seuilTropheeCm: Self.aucunSeuil)
        #expect(b.compteurs == CompteursPersonnels(sorties: 0, especesTrouvees: 3, bredouilles: 0))
        #expect(b.records.isEmpty)
    }

    // MARK: Seuil et données

    @Test("18. seuil de Trophée : truite fario 50, 40 espèces sur le fichier réel")
    func seuilReel() throws {
        let service: any ServiceEspeces = CasVerdictsReelsTests.moteur.especes
        #expect(service.seuilTropheeCm(espece: Espece(id: "truite-fario")) == 50.0)
        let donnees = try #require(CasVerdictsReelsTests.lire("longueur-poids.json"))
        let racine = try #require(try JSONSerialization.jsonObject(with: donnees) as? [String: Any])
        let lignes = try #require(racine["lignes"] as? [[String: Any]])
        var avecSeuil = 0
        for ligne in lignes {
            guard let id = ligne["espece_id"] as? String else { continue }
            let attendu = (ligne["nl_p95_cm"] as? NSNumber)?.doubleValue
            if attendu != nil { avecSeuil += 1 }
            #expect(service.seuilTropheeCm(espece: Espece(id: id)) == attendu, "seuil de \(id)")
        }
        #expect(avecSeuil == 40)
        #expect(service.seuilTropheeCm(espece: Espece(id: "espece-inconnue")) == nil)
    }
}
