import Foundation
import Testing
@testable import Core

private func chargerFichier() throws -> FichierConseils {
    let url = try #require(Bundle.module.url(forResource: "conseils", withExtension: "json"), "conseils.json absent des ressources")
    return try FichierConseils.decoder(Data(contentsOf: url))
}

/// Les 23 espèces « courant » de `especes.json` : liste de D1 encore absente du dépôt (rapport d'Adem non poussé).
private let especesCourantes: [String] = []

@Suite("conseils.json")
struct ConseilsFichierTests {
    @Test func leFichierSeDecodeEtRespecteLesReglesDeForme() throws {
        let f = try chargerFichier()
        let erreurs = ValidationConseils.erreurs(f, exigerRelecture: true, statuts: statutsDuFichier(f))
        #expect(erreurs.isEmpty, "\(erreurs)")
    }

    @Test func chaqueEspeceEstDeLaListeNationale() throws {
        for c in try chargerFichier().conseils {
            #expect(RegleDuLot.idsConnus.contains(c.espece), "\(c.id)")
        }
    }

    @Test func aucunConseilNeContrediLesReglesNationales() throws {
        for c in try chargerFichier().conseils {
            let e = RegleDuLot.erreurs(c)
            #expect(e.isEmpty, "\(c.id) : \(e)")
        }
    }

    @Test(.disabled("liste des 23 espèces « courant » absente du dépôt, et conseils.json reste vide tant que S n'a pas relu"))
    func chaqueEspeceCourantesAAuMoinsUnConseil() throws {
        let f = try chargerFichier()
        for espece in especesCourantes { #expect(f.conseils.contains { $0.espece == espece }, "\(espece)") }
    }

    @Test func lesStatutsViennentDeEspecesJson() {
        // Avec les fichiers de D1 (especes.json et regles/national.json dans les ressources) ; sinon la copie à la main sert de repli.
        guard RegleDuLot.lesFichiersDeD1SontLa else { return }
        #expect(RegleDuLot.estProtegee("esturgeon-europeen"))
        #expect(RegleDuLot.estProtegee("apron-du-rhone"))
        #expect(RegleDuLot.statuts("perche-soleil") == [.envahissante])
        #expect(RegleDuLot.statuts("civelle") == [.stadeADemander])
        #expect(RegleDuLot.statuts("brochet").isEmpty)
        #expect(RegleDuLot.moisFermes(espece: "brochet", categorie: .deuxieme).isSuperset(of: [2, 3]))
        #expect(RegleDuLot.moisFermes(espece: "truite-fario", categorie: .deuxieme).contains(10))
        #expect(RegleDuLot.moisFermes(espece: "sandre", categorie: .premiere).contains(11))
        #expect(RegleDuLot.moisFermes(espece: "sandre", categorie: .deuxieme).isEmpty)
    }

    @Test func fonctionSurLeVraiFichier() throws {
        let s = try ConseilsParEspece.charger()
        let debutant = s.conseils(espece: brochet, niveau: .debutant, mois: 10)
        #expect(debutant.count <= 3)
        if let premier = debutant.first { #expect(premier.gratuit); #expect(debutant.dropFirst().allSatisfy { !$0.gratuit }) }
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10).count >= debutant.count)
        #expect(s.conseils(espece: Espece(id: "espece-sans-conseil"), niveau: .confirme, mois: 10).isEmpty)
    }

    private func statutsDuFichier(_ f: FichierConseils) -> [String: Set<StatutEspece>] {
        Dictionary(uniqueKeysWithValues: Set(f.conseils.map(\.espece)).map { ($0, RegleDuLot.statuts($0)) })
    }
}

@Suite("Tableau de relecture (reports/relecture/conseils.csv)")
struct TableauRelectureTests {
    /// Le tableau avant la relecture de S : mêmes règles de forme, `relu_par` pas encore exigé.
    @Test func chaqueLigneRespecteLesReglesDeLaFiche() throws {
        guard let lignes = try lireTableau() else { return }
        #expect(!lignes.isEmpty)
        var vus = Set<String>()
        var rangs: [String: [Int]] = [:]
        for l in lignes {
            #expect(vus.insert(l.conseil.id).inserted, "identifiant en double \(l.conseil.id)")
            rangs[l.conseil.espece, default: []].append(l.conseil.rang)
            #expect(RegleDuLot.idsConnus.contains(l.conseil.espece), "\(l.conseil.id) : espèce hors liste")
            var erreurs = ValidationConseils.erreurs(l.conseil, sources: l.sources, exigerRelecture: false,
                                                     statuts: RegleDuLot.statuts(l.conseil.espece))
            erreurs += RegleDuLot.erreurs(l.conseil)
            if RegleDuLot.statuts(l.conseil.espece).contains(.stadeADemander) { erreurs.append("stade à demander : statut non tranché, pas de conseil") }
            #expect(erreurs.isEmpty, "\(l.conseil.id) : \(erreurs)")
        }
        for (espece, r) in rangs {
            #expect(r.sorted() == Array(1...r.count), "\(espece) : rangs \(r)")
            if RegleDuLot.estProtegee(espece) { #expect(r.count == 1, "\(espece) : un seul conseil") }
        }
    }

    // MARK: - Lecture du CSV (RFC 4180)

    struct Ligne { var conseil: ConseilFiche; var sources: [SourceLue] }

    private func lireTableau() throws -> [Ligne]? {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { url.deleteLastPathComponent() }
        url.appendPathComponent("reports/relecture/conseils.csv")
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let lignes = Self.analyser(try String(contentsOf: url, encoding: .utf8))
        guard let entete = lignes.first else { return [] }
        return try lignes.dropFirst().filter { !$0.allSatisfy(\.isEmpty) }.map { champs in
            func col(_ nom: String) throws -> String {
                let i = try #require(entete.firstIndex(of: nom), "colonne \(nom) absente")
                return i < champs.count ? champs[i] : ""
            }
            let mots = { (s: String) in s.split(separator: " ").map(String.init) }
            let sources: [SourceLue] = try col("sources").components(separatedBy: " || ").enumerated().map { (i, s) in
                let p = s.components(separatedBy: " | ")
                return SourceLue(id: "s\(i)", titre: p.first ?? "", url: p.count > 1 ? p[1] : "", luLe: p.count > 2 ? p[2] : "")
            }
            let conseil = ConseilFiche(
                id: try col("id"), espece: try col("espece"),
                type: try #require(TypeConseil(rawValue: try col("type"))),
                texte: try col("texte"), icone: try col("icone"),
                mois: mots(try col("mois")).compactMap { Int($0) },
                categorie: try #require(CategorieConseil(rawValue: try col("categorie"))),
                niveaux: try mots(col("niveaux")).map { try #require(NiveauPecheur(rawValue: $0)) },
                modes: try mots(col("modes")).map { try #require(ModeConseil(rawValue: $0)) },
                rang: Int(try col("rang")) ?? 0, sources: sources.map(\.id), reluPar: try col("relu_par"))
            return Ligne(conseil: conseil, sources: sources)
        }
    }

    static func analyser(_ texte: String) -> [[String]] {
        var lignes: [[String]] = [], champs: [String] = [], champ = "", guillemets = false
        var it = texte.makeIterator()
        var suivant = it.next()
        while let c = suivant {
            suivant = it.next()
            if guillemets {
                if c == "\"" { if suivant == "\"" { champ.append("\""); suivant = it.next() } else { guillemets = false } }
                else { champ.append(c) }
            } else if c == "\"" { guillemets = true }
            else if c == "," { champs.append(champ); champ = "" }
            else if c == "\n" || c == "\r\n" { champs.append(champ); champ = ""; lignes.append(champs); champs = [] }
            else { champ.append(c) }
        }
        if !champ.isEmpty || !champs.isEmpty { champs.append(champ); lignes.append(champs) }
        return lignes
    }
}
