import Foundation
import Testing

/// Le catalogue `App/Region/Localizable.xcstrings` : français en base, anglais américain, aucun mot interdit côté anglais.
struct CatalogueTextesTests {
    private static let motsInterdits = [
        "legal", "illegal", "lawful", "allowed", "authorized", "authorised", "permitted", "permissible",
        "keeper", "approved", "compliant", "guaranteed", "you can keep", "you may keep", "safe to keep",
    ]

    private func chargerCatalogue() throws -> [String: Any] {
        // #filePath : AppTests/Region/CatalogueTextesTests.swift -> App/Region/Localizable.xcstrings
        let racine = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let url = racine.appendingPathComponent("App/Region/Localizable.xcstrings")
        let donnees = try Data(contentsOf: url)
        return try #require(JSONSerialization.jsonObject(with: donnees) as? [String: Any])
    }

    private func anglais(_ catalogue: [String: Any]) throws -> [String: String] {
        let textes = try #require(catalogue["strings"] as? [String: [String: Any]])
        var r: [String: String] = [:]
        for (cle, entree) in textes {
            let loc = entree["localizations"] as? [String: [String: Any]]
            let unite = loc?["en"]?["stringUnit"] as? [String: Any]
            r[cle] = unite?["value"] as? String
        }
        return r
    }

    @Test func lesTrentePremiersTextesSontTraduits() throws {
        let c = try chargerCatalogue()
        #expect(c["sourceLanguage"] as? String == "fr")
        let en = try anglais(c)
        #expect(en.count >= 30)
        #expect(en.values.allSatisfy { !$0.isEmpty })
    }

    @Test func lesTroisVerdictsAnglais() throws {
        let en = try anglais(try chargerCatalogue())
        #expect(en["Interdit"] == "Prohibited")
        #expect(en["À vérifier"] == "Check the regulations")
        #expect(en["Donnée absente"] == "No data")
    }

    @Test func aucunMotInterditCoteAnglais() throws {
        for (cle, texte) in try anglais(try chargerCatalogue()) {
            let bas = texte.lowercased()
            for mot in Self.motsInterdits {
                #expect(!bas.contains(mot), "« \(texte) » (clé « \(cle) ») contient « \(mot) »")
            }
        }
    }
}
