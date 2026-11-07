import Foundation
import Testing
@testable import Core

// Lot D7 : regles de niveau 2 (par espece, au niveau de l'Etat) de TX, FL, NC, NY et MI, issues de la double lecture
// (dossier outils/us/regles/donnees, un sous-dossier par Etat). Les fichiers lus ici sont ceux que l'app embarque.

private let etatsD7 = ["TX", "FL", "NC", "NY"]
/// Regles confirmees par les deux lectures et chargees ; le reste reste a verifier dans consensus.json avec les deux lectures.
private let reglesAttendues = ["TX": 22, "FL": 6, "NC": 15, "NY": 33]

private func fichierBrut(_ code: String) throws -> [String: Any] {
    let dossier = try #require(ChargementReglesUS.dossierEmbarque)
    let donnees = try Data(contentsOf: dossier.appendingPathComponent(code + ".json"))
    return try #require(try JSONSerialization.jsonObject(with: donnees) as? [String: Any])
}

private func texteBrut(_ code: String) throws -> String {
    let dossier = try #require(ChargementReglesUS.dossierEmbarque)
    return try String(contentsOf: dossier.appendingPathComponent(code + ".json"), encoding: .utf8)
}

@Suite("Regles US niveau 2 : TX, FL, NC, NY, MI (double lecture)")
struct ReglesNiveau2Tests {
    private func contenu() -> ContenuReglesUS { ChargementReglesUS.embarque().tout() }

    @Test("Les cinq Etats se chargent sans erreur ; le compte de l'index est celui du fichier et le nombre de regles est celui attendu")
    func chargementEtComptes() throws {
        let c = contenu()
        #expect(c.erreurs.isEmpty)
        let index = try ChargementReglesUS.embarque().index()
        for code in etatsD7 {
            let etat = try #require(c.etats.first(where: { e in e.code.rawValue == code }), "etat non charge")
            #expect(etat.regles.count == reglesAttendues[code], "nombre de regles inattendu")
            #expect(index.etats[etat.code]?.nombreRegles == etat.regles.count)
            #expect(etat.couverture == .niveau2)
        }
    }

    @Test("Aucune regle sans source, sans date de lecture, sans lien https ni sans citation ; toutes confirmees par deux lectures")
    func toutesSourcees() {
        let c = contenu()
        for etat in c.etats where etatsD7.contains(etat.code.rawValue) {
            for r in etat.regles {
                #expect(r.source.url.scheme == "https", Comment(rawValue: r.id))
                #expect(r.source.url.host?.isEmpty == false, Comment(rawValue: r.id))
                #expect(r.source.dateLecture.annee >= 2026, Comment(rawValue: r.id))
                #expect((r.source.citation ?? "").count >= 3, Comment(rawValue: r.id))
                #expect((r.source.citation ?? "").count <= ChargementReglesUS.citationMax, Comment(rawValue: r.id))
                #expect(r.statut == .doubleLectureConfirmee, Comment(rawValue: r.id))
            }
        }
    }

    @Test("Chaque fichier garde le lien de l'agence (https) ; chaque regle porte source.url, source.date et source.citation dans le JSON brut")
    func jsonBrut() throws {
        for code in etatsD7 {
            let f = try fichierBrut(code)
            let lien = try #require(f["lien_agence"] as? String, "sans lien_agence")
            #expect(lien.hasPrefix("https://"))
            let regles = try #require(f["regles"] as? [[String: Any]])
            for r in regles {
                let s = try #require(r["source"] as? [String: Any], "regle sans source")
                #expect((s["url"] as? String)?.hasPrefix("https://") == true)
                #expect((s["date"] as? String)?.count == 10)
                #expect(((s["citation"] as? String) ?? "").isEmpty == false)
            }
        }
    }

    @Test("Caroline du Nord : toutes les regles viennent d'eRegulations (editeur tiers) et le disent dans source.tiers ; aucune source tierce ailleurs")
    func sourcesTierces() throws {
        for code in etatsD7 {
            let regles = try #require(try fichierBrut(code)["regles"] as? [[String: Any]])
            for r in regles {
                let s = try #require(r["source"] as? [String: Any])
                let tiers = s["tiers"] as? Bool ?? false
                if code == "NC" {
                    #expect(tiers, "NC : une regle d'eRegulations sans marque tiers")
                    #expect((s["url"] as? String)?.contains("eregulations.com") == true)
                    #expect((s["edition"] as? String)?.contains("tierce") == true)
                } else {
                    #expect(!tiers, "source marquee tierce hors NC")
                }
            }
        }
    }

    @Test("Aucun mot interdit (autorise, allowed, legal, tu peux la garder...) dans les fichiers, citations comprises")
    func aucunMotInterdit() throws {
        for code in etatsD7 {
            let bas = try texteBrut(code).lowercased()
            for mot in usMotsInterdits { #expect(!bas.contains(mot), Comment(rawValue: code + ".json contient " + mot)) }
        }
    }

    @Test("Texas : black-bass a 12 pouces (minimum 14) -> interdit ; 14 pile -> a verifier ; New York : bass hors saison -> interdit")
    func verdictsTexasEtNewYork() throws {
        let m = try contenu().moteur()
        let jour = usJour(2026, 11, 20)
        let sous = m.evaluer(QuestionUS(espece: "largemouth-bass", juridiction: usId("US-TX"), jour: jour, taille: .pouces(12)))
        #expect(sous.verdict == .interdit)
        #expect(sous.sources.allSatisfy({ s in s.url.host == "tpwd.texas.gov" }))
        let pile = m.evaluer(QuestionUS(espece: "largemouth-bass", juridiction: usId("US-TX"), jour: jour, taille: .pouces(14)))
        #expect(pile.verdict == .aVerifier)
        let janvier = m.evaluer(QuestionUS(espece: "largemouth-bass", juridiction: usId("US-NY"), jour: usJour(2027, 1, 15), taille: .pouces(15)))
        #expect(janvier.verdict == .interdit)
        #expect(janvier.sources.allSatisfy({ s in s.url.host == "dec.ny.gov" }))
    }

    @Test("Espece sans regle confirmee (crappie en Caroline du Nord) -> donnee absente ; Michigan, sans regle confirmee, ne dit jamais interdit")
    func absenceEtMichigan() throws {
        let m = try contenu().moteur()
        let jour = usJour(2026, 11, 20)
        let nc = m.evaluer(QuestionUS(espece: "black-crappie", juridiction: usId("US-NC"), jour: jour, taille: .pouces(5)))
        #expect(nc.verdict == .donneeAbsente)
        let mi = m.evaluer(QuestionUS(espece: "walleye", juridiction: usId("US-MI"), jour: jour, taille: .pouces(5)))
        #expect(mi.verdict != .interdit)
    }

    @Test("Pas de confusion d'espece (bull trout, sockeye) ni d'engin date charge sans ses dates")
    func pasDeConfusionDEspece() throws {
        let c = contenu()
        let nc = try #require(c.etats.first(where: { e in e.code.rawValue == "NC" }))
        #expect(!nc.regles.contains(where: { r in r.espece == "bull-trout" }))
        let ny = try #require(c.etats.first(where: { e in e.code.rawValue == "NY" }))
        #expect(!ny.regles.contains(where: { r in r.espece == "sockeye-salmon" }))
        // Les leurres artificiels de New York valent du 1er dec. au 14 juin seulement : non charges sans leurs dates.
        #expect(!ny.regles.contains(where: { r in !r.engins.isEmpty }))
    }
}
