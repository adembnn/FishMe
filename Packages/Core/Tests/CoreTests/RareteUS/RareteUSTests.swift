import Foundation
import Testing
@testable import Core

@Suite("Rareté américaine (US-rarete)")
struct RareteUSTests {
    static let riviere = StrateUS(milieu: "cours_d_eau", engin: "electrofishing")
    static let fixes = ParametresRareteUS(seuils: .fixes(peuCommun: 0.2, commun: 0.5))

    /// `n` événements d'un HUC8 ; l'espèce `e` est vue dans les `k` premiers.
    static func evenements(_ huc8: String, etat: String = "WI", n: Int, especes: [String: Int], annee: Int = 2020,
                           milieu: MilieuUS = .coursDeau, engin: String = "electrofishing", source: String = "TEST") -> [EvenementEchantillonnageUS] {
        (0..<n).map { i in
            EvenementEchantillonnageUS(id: "\(etat)-\(huc8)-\(milieu.rawValue)-\(engin)-\(i)", huc8: huc8, etat: etat, milieu: milieu, engin: engin,
                                       especes: Set(especes.filter { i < $0.value }.keys), annee: annee - (i % 3), source: source)
        }
    }

    // MARK: Fréquence et classes

    @Test("1. une espèce partout est commune, avec comptes, dernière année et source")
    func partout() {
        let m = MoteurRareteUS(evenements: Self.evenements("07070001", n: 30, especes: ["bluegill": 30, "brochet": 3]), parametres: Self.fixes)
        let r = m.evaluer(espece: "bluegill", huc8: "07070001", strate: Self.riviere)
        #expect(r.classe == .commun)
        #expect(r.frequence == 1.0)
        #expect(r.nEspece == 30 && r.nTotal == 30)
        #expect(r.derniereAnnee == 2020)
        #expect(r.sources == ["TEST"])
        #expect(r.echelle == .huc8 && r.codeEchelle == "07070001")
    }

    @Test("2. une espèce rare (2 pêches sur 40) est rare")
    func rare() {
        let m = MoteurRareteUS(evenements: Self.evenements("07070001", n: 40, especes: ["esturgeon": 2, "bluegill": 40]), parametres: Self.fixes)
        let r = m.evaluer(espece: "esturgeon", huc8: "07070001", strate: Self.riviere)
        #expect(r.classe == .rare)
        #expect(r.nEspece == 2 && r.nTotal == 40)
        #expect(r.frequence == 0.05)
    }

    @Test("3. les seuils fixes séparent peu commun et commun")
    func seuilsFixes() {
        let m = MoteurRareteUS(evenements: Self.evenements("07070001", n: 20, especes: ["a": 10, "b": 9, "c": 4, "d": 3]), parametres: Self.fixes)
        func c(_ e: String) -> ClasseRareteUS { m.evaluer(espece: e, huc8: "07070001", strate: Self.riviere).classe }
        #expect(c("a") == .commun)
        #expect(c("b") == .peuCommun)
        #expect(c("c") == .peuCommun)
        #expect(c("d") == .rare)
    }

    @Test("4. les seuils par quantiles suivent la distribution des cellules fiables")
    func quantiles() {
        // 12 espèces à 5 %, 10 %, ..., 60 % de 20 événements : 1 à 12 événements.
        var esp: [String: Int] = [:]
        for k in 1...12 { esp["e\(k)"] = k }
        let m = MoteurRareteUS(evenements: Self.evenements("07070001", n: 20, especes: esp))
        let s = m.seuils(strate: Self.riviere)
        #expect(s != nil)
        #expect(abs((s?.peuCommun ?? 0) - 0.2333333333) < 1e-9)
        #expect(abs((s?.commun ?? 0) - 0.4166666667) < 1e-9)
        func c(_ e: String) -> ClasseRareteUS { m.evaluer(espece: e, huc8: "07070001", strate: Self.riviere).classe }
        #expect(c("e1") == .rare)
        #expect(c("e4") == .rare)
        #expect(c("e5") == .peuCommun)
        #expect(c("e8") == .peuCommun)
        #expect(c("e9") == .commun)
        #expect(c("e12") == .commun)
    }

    @Test("5. quantile de type 7 sur une liste triée")
    func quantileType7() {
        #expect(MoteurRareteUS.quantile([1, 2, 3, 4], 0.5) == 2.5)
        #expect(MoteurRareteUS.quantile([1, 2, 3, 4], 0) == 1)
        #expect(MoteurRareteUS.quantile([1, 2, 3, 4], 1) == 4)
        #expect(MoteurRareteUS.quantile([7], 0.9) == 7)
    }

    @Test("6. trop peu de cellules : quantiles non calibrés, donnée insuffisante, jamais un niveau inventé")
    func seuilsNonCalibres() {
        let m = MoteurRareteUS(evenements: Self.evenements("07070001", n: 30, especes: ["a": 30, "b": 5]))
        let r = m.evaluer(espece: "a", huc8: "07070001", strate: Self.riviere)
        #expect(r.classe == .donneeInsuffisante)
        #expect(r.motif == .seuilsNonCalibres)
        #expect(r.nEspece == 30 && r.frequence == 1.0)
    }

    // MARK: Absence de donnée

    @Test("7. espèce jamais vue dans un HUC8 fourni : non observée, jamais légendaire ni rare")
    func nonObservee() {
        let m = MoteurRareteUS(evenements: Self.evenements("07070001", n: 30, especes: ["bluegill": 30]), parametres: Self.fixes)
        let r = m.evaluer(espece: "esturgeon", huc8: "07070001", strate: Self.riviere)
        #expect(r.classe == .donneeInsuffisante)
        #expect(r.motif == .nonObservee)
        #expect(r.nEspece == 0 && r.nTotal == 30)
        #expect(r.derniereAnnee == nil)
        #expect(r.libellePresence.contains("Non vue dans 30 événements"))
        #expect(r.libellePresence.contains("TEST"))
    }

    @Test("8. un HUC8 sans aucune donnée : donnée insuffisante, zéro événement")
    func huc8SansDonnees() {
        let m = MoteurRareteUS(evenements: Self.evenements("07070001", n: 30, especes: ["bluegill": 30]), parametres: Self.fixes)
        let r = m.evaluer(espece: "bluegill", huc8: "12345678", strate: Self.riviere)
        #expect(r.classe == .donneeInsuffisante)
        #expect(r.motif == .pasAssezEvenements)
        #expect(r.nTotal == 0 && r.nEspece == 0 && r.frequence == nil)
        #expect(r.echelle == .aucune)
        #expect(r.sources.isEmpty)
        #expect(r.affichageRarete == false)
    }

    @Test("9. sous le minimum partout : donnée insuffisante, comptes du plus fin échelon")
    func sousLeMinimum() {
        let m = MoteurRareteUS(evenements: Self.evenements("07070001", n: 5, especes: ["bluegill": 5]), parametres: Self.fixes)
        let r = m.evaluer(espece: "bluegill", huc8: "07070001", strate: Self.riviere)
        #expect(r.classe == .donneeInsuffisante)
        #expect(r.motif == .pasAssezEvenements)
        #expect(r.echelle == .aucune)
        #expect(r.nEspece == 5 && r.nTotal == 5)
    }

    // MARK: Repli

    @Test("10. repli HUC8 vers HUC6 : le HUC8 est trop petit, les HUC8 voisins complètent")
    func repliHUC6() {
        let evts = Self.evenements("07070001", n: 18, especes: ["bluegill": 18, "brochet": 9])
            + Self.evenements("07070002", n: 5, especes: ["bluegill": 5])
        let m = MoteurRareteUS(evenements: evts, parametres: Self.fixes)
        let r = m.evaluer(espece: "brochet", huc8: "07070002", strate: Self.riviere)
        #expect(r.echelle == .huc6)
        #expect(r.codeEchelle == "070700")
        #expect(r.nEspece == 9 && r.nTotal == 23)
        #expect(r.classe == .peuCommun)
    }

    @Test("11. repli HUC6 vers État, annoncé dans l'échelle et le code")
    func repliEtat() {
        let evts = Self.evenements("07070001", n: 15, especes: ["bluegill": 15, "brochet": 3])
            + Self.evenements("07090001", n: 8, especes: ["bluegill": 8])
        let m = MoteurRareteUS(evenements: evts, parametres: Self.fixes)
        let r = m.evaluer(espece: "bluegill", huc8: "07090001", strate: Self.riviere)
        #expect(r.echelle == .etat)
        #expect(r.codeEchelle == "WI")
        #expect(r.nTotal == 23 && r.nEspece == 23)
        // Un HUC8 sans événement avec l'État donné se replie aussi sur l'État.
        let s = m.evaluer(espece: "brochet", huc8: "09999999", etat: "WI", strate: Self.riviere)
        #expect(s.echelle == .etat && s.nEspece == 3 && s.nTotal == 23)
    }

    @Test("12. un HUC8 fourni garde son propre échelon, sans repli")
    func pasDeRepliInutile() {
        let evts = Self.evenements("07070001", n: 25, especes: ["bluegill": 25]) + Self.evenements("07070002", n: 25, especes: ["brochet": 25])
        let m = MoteurRareteUS(evenements: evts, parametres: Self.fixes)
        let r = m.evaluer(espece: "brochet", huc8: "07070001", strate: Self.riviere)
        #expect(r.echelle == .huc8 && r.nEspece == 0)
        #expect(r.motif == .nonObservee)
    }

    // MARK: Strates, fenêtre, hygiène des données

    @Test("13. milieux et engins ne se mélangent pas ; les confondre est un réglage")
    func strates() {
        let evts = Self.evenements("07070001", n: 25, especes: ["bluegill": 25])
            + Self.evenements("07070001", n: 25, especes: ["bluegill": 4], milieu: .lac, engin: "gill net")
        let m = MoteurRareteUS(evenements: evts, parametres: Self.fixes)
        #expect(m.strates.count == 2)
        let lac = StrateUS(milieu: "lac", engin: "gill net")
        #expect(m.evaluer(espece: "bluegill", huc8: "07070001", strate: lac).classe == .rare)
        var p = Self.fixes
        p.separerParMilieu = false
        p.separerParEngin = false
        let tous = MoteurRareteUS(evenements: evts, parametres: p)
        #expect(tous.strates == [StrateUS(milieu: "tous", engin: "tous")])
        let r = tous.evaluer(espece: "bluegill", huc8: "07070001", strate: tous.strates[0])
        #expect(r.nEspece == 29 && r.nTotal == 50)
    }

    @Test("14. la fenêtre d'années écarte les vieux événements")
    func fenetre() {
        let evts = Self.evenements("07070001", n: 25, especes: ["bluegill": 25], annee: 2005)
            + Self.evenements("07070001", n: 25, especes: ["bluegill": 25], annee: 2022, engin: "electrofishing").map { e -> EvenementEchantillonnageUS in
                var e = e; e.id += "-b"; return e }
        var p = Self.fixes
        p.anneeMinimum = 2018
        let m = MoteurRareteUS(evenements: evts, parametres: p)
        #expect(m.nEvenements == 25)
        #expect(m.evaluer(espece: "bluegill", huc8: "07070001", strate: Self.riviere).derniereAnnee == 2022)
    }

    @Test("15. identifiants répétés réunis, entrées invalides rejetées, événement vide au dénominateur")
    func hygiene() {
        var evts = Self.evenements("07070001", n: 20, especes: [:])
        evts[0].especes = ["a"]
        evts.append(EvenementEchantillonnageUS(id: evts[0].id, huc8: "07070001", etat: "WI", milieu: .coursDeau, engin: "electrofishing",
                                               especes: ["b"], annee: 2020, source: "TEST"))
        evts.append(EvenementEchantillonnageUS(id: "x", huc8: "0707", etat: "WI", milieu: .coursDeau, engin: "e", especes: ["a"], annee: 2020, source: "TEST"))
        evts.append(EvenementEchantillonnageUS(id: "", huc8: "07070001", etat: "WI", milieu: .coursDeau, engin: "electrofishing", especes: [], annee: 2020, source: "TEST"))
        let m = MoteurRareteUS(evenements: evts, parametres: Self.fixes)
        #expect(m.nEvenements == 20)
        #expect(m.nRejetes == 2)
        let r = m.evaluer(espece: "b", huc8: "07070001", strate: Self.riviere)
        #expect(r.nEspece == 1 && r.nTotal == 20)
    }

    @Test("16. aucune classe n'est affichable avant la revue d'un biologiste")
    func revue() {
        let evts = Self.evenements("07070001", n: 30, especes: ["bluegill": 30])
        let avant = MoteurRareteUS(evenements: evts, parametres: Self.fixes).evaluer(espece: "bluegill", huc8: "07070001", strate: Self.riviere)
        #expect(avant.classe == .commun && avant.affichageRarete == false)
        var p = Self.fixes
        p.revueBiologisteValidee = true
        let apres = MoteurRareteUS(evenements: evts, parametres: p).evaluer(espece: "bluegill", huc8: "07070001", strate: Self.riviere)
        #expect(apres.affichageRarete == true)
        // Une donnée insuffisante ne devient jamais affichable, même après la revue.
        #expect(MoteurRareteUS(evenements: evts, parametres: p).evaluer(espece: "x", huc8: "07070001", strate: Self.riviere).affichageRarete == false)
    }

    @Test("17. aucune ligne produite n'est sans source ni nombre d'événements, aucune n'est légendaire")
    func toutesLesLignes() {
        let evts = Self.evenements("07070001", n: 30, especes: ["a": 30, "b": 10, "c": 2]) + Self.evenements("07090001", n: 3, especes: ["a": 3])
        let lignes = MoteurRareteUS(evenements: evts, parametres: Self.fixes).toutes()
        #expect(lignes.count == 6)
        for l in lignes {
            #expect(l.nTotal > 0)
            #expect(!l.sources.isEmpty)
            #expect(l.derniereAnnee != nil)
            #expect(["commun", "peu_commun", "rare", "donnee_insuffisante"].contains(l.classe.rawValue))
        }
    }

    // MARK: Comparaison avec Python

    static func racineDepot(_ fichier: String = #filePath) -> URL {
        var u = URL(fileURLWithPath: fichier)
        for _ in 0..<6 { u.deleteLastPathComponent() }
        return u
    }

    static func lireCSV(_ url: URL) throws -> [[String: String]] {
        let lignes = try String(contentsOf: url, encoding: .utf8).split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        let tete = lignes[0].split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        return lignes.dropFirst().map { l in
            let champs = l.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            return Dictionary(uniqueKeysWithValues: zip(tete, champs))
        }
    }

    @Test("18. même résultat que outils/us/rarete/rarete_us.py sur la fixture commune")
    func memeResultatQuePython() throws {
        let dossier = Self.racineDepot().appendingPathComponent("outils/us/rarete/exemples")
        let entree = try Self.lireCSV(dossier.appendingPathComponent("evenements-fixture.csv"))
        let attendu = try Self.lireCSV(dossier.appendingPathComponent("attendu-fixture.csv"))
        let evts = entree.map { l in
            EvenementEchantillonnageUS(id: l["evenement_id"]!, huc8: l["huc8"]!, etat: l["etat"]!, milieu: MilieuUS(rawValue: l["milieu"]!) ?? .autre,
                                       engin: l["engin"]!.lowercased(), especes: Set(l["especes"]!.split(separator: ";").map(String.init)),
                                       annee: Int(l["annee"]!) ?? 0, source: l["source"]!)
        }
        let lignes = MoteurRareteUS(evenements: evts).toutes()
        #expect(lignes.count == attendu.count)
        for (r, a) in zip(lignes, attendu) {
            #expect(r.strate.milieu == a["milieu"] && r.strate.engin == a["engin"] && r.huc8 == a["huc8"] && r.espece == a["espece"])
            #expect(r.classe.rawValue == a["classe"], "\(r.espece) \(r.huc8)")
            #expect((r.motif?.rawValue ?? "") == a["motif"])
            #expect((r.frequence.map { String(format: "%.6f", $0) } ?? "") == a["frequence"])
            #expect(String(r.nEspece) == a["n_evenements_espece"] && String(r.nTotal) == a["n_evenements_total"])
            #expect((r.derniereAnnee.map(String.init) ?? "") == a["derniere_annee"])
            #expect(r.echelle.rawValue == a["echelle"] && r.codeEchelle == a["code_echelle"])
            #expect(r.sources.joined(separator: ";") == a["sources"])
            #expect((r.affichageRarete ? "true" : "false") == a["affichage_rarete"])
        }
    }
}
