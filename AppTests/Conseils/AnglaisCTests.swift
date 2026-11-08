import Core
import Foundation
import Testing
@testable import BuildChallenge

/// Lot US13c : la table AnglaisC (Conseils, Communauté « bientôt », Repères). Chaque texte a une clé et une valeur anglaise,
/// aucun mot de permission, la France ne change pas.
struct AnglaisCTests {
    private let en = Locale(identifier: "en_US")
    private let fr = Locale(identifier: "fr_FR")

    private var racine: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    private func table() throws -> [String: String] {
        let data = try Data(contentsOf: racine.appendingPathComponent("App/Conseils/AnglaisC.xcstrings"))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let chaines = try #require(json["strings"] as? [String: [String: Any]])
        var out: [String: String] = [:]
        for (cle, entree) in chaines {
            let locs = entree["localizations"] as? [String: Any]
            let anglais = locs?["en"] as? [String: Any]
            let unite = anglais?["stringUnit"] as? [String: Any]
            out[cle] = unite?["value"] as? String ?? ""
        }
        return out
    }

    @Test func chaqueCleADeLAnglaisNonVide() throws {
        let t = try table()
        #expect(t.count > 100)
        for (cle, valeur) in t { #expect(!valeur.trimmingCharacters(in: .whitespaces).isEmpty, "valeur vide : \(cle)") }
    }

    @Test func aucunMotInterdit() throws {
        let mots = ["autoris", "allowed", "legal", "permitted", "tu peux la garder", "you can keep"]
        for (_, valeur) in try table() {
            for mot in mots { #expect(!valeur.lowercased().contains(mot), "mot interdit « \(mot) » : \(valeur)") }
        }
    }

    @Test func lAnglaisSortDeLaTableEtLeFrancaisResteTelQuel() throws {
        for (cle, valeur) in try table() {
            #expect(AnglaisC.texte(cle, en) == valeur, "clé sans anglais dans le paquet : \(cle)")
            #expect(AnglaisC.texte(cle, fr) == cle)
        }
    }

    @Test func lesTrousDuFrancaisEtDeLAnglaisSontLesMemes() throws {
        for (cle, valeur) in try table() {
            #expect(cle.components(separatedBy: "%").count == valeur.components(separatedBy: "%").count, "trous différents : \(cle)")
        }
    }

    @Test func aucuneCleNeCollisionneParLaCasse() throws {
        var vus: [String: String] = [:]
        for cle in try table().keys {
            let lettres = String(cle.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).filter { $0.isLetter || $0.isNumber })
            #expect(!lettres.isEmpty, "clé sans lettre : \(cle)")
            if let autre = vus[lettres] { Issue.record("clés au même symbole : « \(cle) » et « \(autre) »") }
            vus[lettres] = cle
        }
    }

    @Test func chaqueTexteAfficheDuDossierAUneCle() throws {
        let t = try table()
        let fichiers = [("App/Conseils", nil as String?), ("App/Communaute", "CommunauteBientotView.swift")]
        var vus = 0
        for (dossier, seul) in fichiers {
            let url = racine.appendingPathComponent(dossier)
            for nom in try FileManager.default.contentsOfDirectory(atPath: url.path) where nom.hasSuffix(".swift") && (seul == nil || nom == seul) {
                let source = try String(contentsOf: url.appendingPathComponent(nom), encoding: .utf8)
                let re = try NSRegularExpression(pattern: #"Text\(c: "((?:[^"\\]|\\.)*)""#)
                for m in re.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
                    guard let r = Range(m.range(at: 1), in: source) else { continue }
                    let cle = String(source[r]).replacingOccurrences(of: "\\'", with: "'").replacingOccurrences(of: "\\\"", with: "\"")
                    vus += 1
                    #expect(t[cle] != nil, "texte sans clé dans \(nom) : \(cle)")
                }
            }
        }
        #expect(vus > 20)
    }

    @Test func lesTextesDesReperesOntUneCleAnglaise() throws {
        let t = try table()
        let cles = [
            TextesReperes.titreListe, TextesReperes.ajouterIci, TextesReperes.etatVide, TextesReperes.nouveauTitre, TextesReperes.supprimerExplication,
            TextesReperes.yAller, TextesReperes.reglesIci, TextesReperes.noterPassage, TextesReperes.dernierPassage, TextesReperes.jamaisNote,
            TextesReperes.prive, TextesReperes.paywallTitre, TextesReperes.paywallTexte, TextesReperes.plafondTexte, TextesReperes.horsDeFrance,
            TextesReperes.limitePhotos, TextesReperes.aucuneReserve, TextesReperes.enregistrementImpossible, TextesReperes.sourcesTitre,
        ]
        for cle in cles { #expect((t[cle] ?? "").isEmpty == false, "pas d'anglais : \(cle)") }
    }

    @Test func lesFonctionsDesReperesParlentAnglais() {
        #expect(TextesReperes.libelle(.parking, locale: en) == "Parking")
        #expect(TextesReperes.libelle(.danger, locale: en) == "Hazard")
        #expect(TextesReperes.libelleVocal(.amorcage, locale: en) == "bait spot")
        #expect(TextesReperes.compteur(actifs: 2, locale: en) == "2 of \(LimitesReperes.gratuits)")
        #expect(TextesReperes.confirmerTiers("Sam", locale: en).contains("Sam"))
        #expect(TextesReperes.reservesNonPlacees(3, locale: en).contains("3"))
        #expect(TextesReperes.reservesNonPlacees(1, locale: en) != TextesReperes.reservesNonPlacees(1, locale: fr))
        #expect(TextesReperes.message(.nomVide, locale: en) != TextesReperes.message(.nomVide, locale: fr))
    }

    @Test func enFranceRienNeChange() {
        #expect(TextesReperes.libelle(.amorcage, locale: fr) == "Amorçage")
        #expect(TextesReperes.libelleVocal(.poste, locale: fr) == "poste de pêche")
        #expect(TextesReperes.compteur(actifs: 2, locale: fr) == "2 sur \(LimitesReperes.gratuits)")
        #expect(TextesReperes.confirmerTiers("Sam", locale: fr) == "Sam saura où se trouve ce repère. Continuer ?")
        #expect(TextesReperes.reserveSurEau("La Marne", locale: fr) == "Une réserve est signalée sur La Marne dans les textes lus.")
        #expect(TextesReperes.message(.nomVide, locale: fr) == "Donne un nom au repère.")
    }

    @Test func leTexteBientotEstTraduit() throws {
        let t = try table()
        for cle in ["Communauté", "Bientôt", "Les autres pêcheurs sont encore en route. Le fil, les messages et les clubs viendront plus tard."] {
            #expect((t[cle] ?? "").isEmpty == false)
            #expect(AnglaisC.texte(cle, en) != cle)
            #expect(AnglaisC.texte(cle, fr) == cle)
        }
    }
}
