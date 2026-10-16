import Foundation
import Testing
@testable import BuildChallenge

@MainActor
struct ConditionsUtilisationTests {
    private func defautsNeufs() -> UserDefaults {
        UserDefaults(suiteName: UUID().uuidString)!
    }

    @Test func neufOnDemande() {
        let suivi = SuiviConditions(defauts: defautsNeufs())
        #expect(suivi.doitDemander)
        #expect(suivi.versionAcceptee == nil)
    }

    @Test func apresAccepterOnNeDemandePlus() {
        let suivi = SuiviConditions(defauts: defautsNeufs())
        suivi.accepter()
        #expect(!suivi.doitDemander)
        #expect(suivi.versionAcceptee == TexteConditions.numeroVersion)
    }

    @Test func uneVersionPlusAncienneRedemande() {
        let defauts = defautsNeufs()
        defauts.set(TexteConditions.numeroVersion - 1, forKey: SuiviConditions.cle)
        #expect(SuiviConditions(defauts: defauts).doitDemander)
    }

    @Test func leTexteEstComplet() {
        let articles = TexteConditions.articles
        #expect(!articles.isEmpty)
        #expect(Set(articles.map(\.id)).count == articles.count)
        for article in articles {
            #expect(!article.titre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!article.paragraphes.isEmpty)
            for p in article.paragraphes {
                #expect(!p.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    @Test func aucunTermeInterdit() {
        let tout = TexteConditions.articles.flatMap { [$0.titre] + $0.paragraphes }.joined(separator: "\n").lowercased()
        for terme in ["pokémon", "pokédex", "pokemon", "pokedex", "tu peux la garder"] {
            #expect(!tout.contains(terme), "terme interdit : \(terme)")
        }
    }
}
