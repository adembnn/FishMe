import Foundation
import Testing
@testable import BuildChallenge

/// Lot US13f : la table AnglaisFCarte. Chaque clé française a une valeur anglaise non vide, aucun mot de permission, la France ne change pas.
struct AnglaisFCarteTests {
    private let en = Locale(identifier: "en_US")
    private let fr = Locale(identifier: "fr_FR")

    private func table() throws -> [String: String] {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/Carte/AnglaisFCarte.xcstrings")
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
        #expect(t.count > 20)
        for (cle, valeur) in t {
            #expect(!valeur.trimmingCharacters(in: .whitespaces).isEmpty, "valeur vide : \(cle)")
        }
    }

    @Test func aucunMotInterdit() throws {
        let mots = ["autoris", "allowed", "legal", "tu peux la garder", "you can keep"]
        for (_, valeur) in try table() {
            for mot in mots {
                #expect(!valeur.lowercased().contains(mot), "mot interdit « \(mot) » : \(valeur)")
            }
        }
    }

    @Test func aucuneCleNeDiffereQueParLaCasse() throws {
        let cles = try table().keys.map { $0.lowercased() }
        #expect(Set(cles).count == cles.count)
    }

    @Test func lAnglaisSortDeLaTableEtLeFrancaisResteTelQuel() throws {
        for (cle, valeur) in try table() {
            #expect(AnglaisFCarte.t(cle, en) == valeur, "clé sans anglais dans le paquet : \(cle)")
            #expect(AnglaisFCarte.t(cle, fr) == cle)
        }
    }

    @Test func leTrouEstRempli() {
        #expect(AnglaisFCarte.f("Y aller avec %@", en, "Waze") == "Directions with Waze")
        #expect(AnglaisFCarte.f("Y aller avec %@", fr, "Waze") == "Y aller avec Waze")
    }
}
