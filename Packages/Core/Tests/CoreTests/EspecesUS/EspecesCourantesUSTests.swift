import Foundation
import Testing
@testable import Core

@Suite struct EspecesCourantesUSTests {
    @Test func slugsUniquesEtNomsAnglais() {
        let l = EspecesCourantesUS.liste
        #expect(Set(l.map(\.slug)).count == l.count)
        #expect(l.allSatisfy { !$0.nomEn.isEmpty && !$0.latin.isEmpty })
        #expect(l.count >= 12)
    }

    @Test func aucuneImageFrancaiseSiEspeceDifferente() {
        // seules les espèces identiques (lien « = » de la table de correspondance) empruntent une image française
        let identiques: Set<String> = ["largemouth-bass", "channel-catfish", "northern-pike", "rainbow-trout", "smallmouth-bass", "brown-trout", "brook-trout", "common-carp"]
        for e in EspecesCourantesUS.liste {
            #expect((e.imageEspeceFrancaise != nil) == identiques.contains(e.slug), "\(e.slug)")
        }
    }

    @Test func aucunMotDePermission() {
        for e in EspecesCourantesUS.liste {
            let t = (e.nomEn + e.latin).lowercased()
            for m in ["autoris", "allowed", "legal", "rare"] { #expect(!t.contains(m)) }
        }
    }
}
