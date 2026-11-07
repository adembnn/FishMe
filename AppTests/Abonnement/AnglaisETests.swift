import Foundation
import Testing
@testable import BuildChallenge

/// Lot US13e : la table AnglaisE. Chaque clé française a une valeur anglaise non vide, aucun mot de permission, la France ne change pas.
struct AnglaisETests {
    private let en = Locale(identifier: "en_US")
    private let fr = Locale(identifier: "fr_FR")

    private func table() throws -> [String: String] {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/Abonnement/AnglaisE.xcstrings")
        let data = try Data(contentsOf: url)
        let racine = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let chaines = try #require(racine["strings"] as? [String: [String: Any]])
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
        for (cle, valeur) in t {
            #expect(!valeur.trimmingCharacters(in: .whitespaces).isEmpty, "valeur vide : \(cle)")
        }
    }

    @Test func aucunMotInterdit() throws {
        let mots = ["autoris", "allowed", "legal", "permitted", "tu peux la garder", "you can keep"]
        for (_, valeur) in try table() {
            for mot in mots {
                #expect(!valeur.lowercased().contains(mot), "mot interdit « \(mot) » : \(valeur)")
            }
        }
    }

    @Test func lAnglaisSortDeLaTableEtLeFrancaisResteTelQuel() throws {
        for (cle, valeur) in try table() {
            #expect(AnglaisE.t(cle, en) == valeur, "clé sans anglais dans le paquet : \(cle)")
            #expect(AnglaisE.t(cle, fr) == cle)
        }
    }

    @Test func lesTrousDuFrancaisEtDeLAnglaisSontLesMemes() throws {
        for (cle, valeur) in try table() {
            let a = cle.components(separatedBy: "%").count
            let b = valeur.components(separatedBy: "%").count
            #expect(a == b, "trous différents : \(cle)")
        }
    }

    @Test func francePreserveLesConstantes() {
        #expect(TextesEnvies.titre == "Mes envies")
        #expect(TextesMaFederation.titre == "Ma fédération")
    }
}
