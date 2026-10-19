import Core
import Foundation
import Testing
@testable import BuildChallenge

// Tests écrits, non exécutés (pas de Mac pendant l'écriture) : S les lance sur le Mac.

struct MaFederationAppTests {
    @Test func leFichierEmbarquePorteLes96Departements() {
        #expect(RepertoireFederations.embarque().count == 96)
    }

    @Test func le94MontreLaFederationInterdepartementale() {
        let f = MaFederation.embarquee(code: "94", nom: "Val-de-Marne")
        #expect(f.interdepartementale)
        #expect(f.libelleFederation == "Fédération de Paris, Hauts-de-Seine, Seine-Saint-Denis et Val-de-Marne")
        #expect(f.site?.scheme == "http")
        #expect(f.evenements == f.site)
        #expect(f.cartesNationales != nil)
    }

    @Test func lesNumerosOntTroisPrincipauxEtDeuxAutres() {
        #expect(NumerosUtiles.principaux.map(\.numero) == ["112", "18", "15"])
        #expect(NumerosUtiles.autres.map(\.numero) == ["17", "114"])
    }
}
