import Foundation
import Testing
@testable import Core

// Critère 2 de la fiche N6. Écrits sans compilateur : non exécutés.

@Suite("Repères : fusion entre l'iPhone et iCloud")
struct FusionReperesTests {
    private let maintenant = Date(timeIntervalSince1970: 10_000_000)

    private func jour(_ n: Double) -> Date { maintenant.addingTimeInterval(-n * 86_400) }

    private func repere(_ n: Int, nom: String, modifie: Date, supprime: Date? = nil) -> Repere {
        let id = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", n))!
        return Repere(id: id, nom: nom, position: Coordonnee(latitude: 48, longitude: 2), cree: jour(100),
                      modifie: modifie, supprime: supprime)
    }

    private func fusion(_ l: [Repere], _ d: [Repere]) -> [Repere] {
        JeuReperes.fusionner(local: l, distant: d, maintenant: maintenant)
    }

    @Test("Ajout des deux côtés : l'union")
    func ajouts() {
        let a = repere(1, nom: "A", modifie: jour(2))
        let b = repere(2, nom: "B", modifie: jour(2))
        let sortie = fusion([a], [b])
        #expect(sortie.map(\.nom).sorted() == ["A", "B"])
    }

    @Test("Même id : le local plus récent gagne")
    func localPlusRecent() {
        let sortie = fusion([repere(1, nom: "local", modifie: jour(1))], [repere(1, nom: "distant", modifie: jour(3))])
        #expect(sortie.count == 1)
        #expect(sortie[0].nom == "local")
    }

    @Test("Même id : le distant plus récent gagne")
    func distantPlusRecent() {
        let sortie = fusion([repere(1, nom: "local", modifie: jour(3))], [repere(1, nom: "distant", modifie: jour(1))])
        #expect(sortie[0].nom == "distant")
    }

    @Test("Suppression plus récente que la modification : le repère disparaît")
    func suppressionPlusRecente() {
        let supprime = repere(1, nom: "A", modifie: jour(5), supprime: jour(2))
        let modifie = repere(1, nom: "A bis", modifie: jour(4))
        let sortie = fusion([supprime], [modifie])
        #expect(sortie.count == 1)
        #expect(sortie[0].estSupprime)
    }

    @Test("Modification plus récente que la suppression : le repère revient")
    func modificationPlusRecente() {
        let supprime = repere(1, nom: "A", modifie: jour(5), supprime: jour(4))
        let modifie = repere(1, nom: "A bis", modifie: jour(1))
        let sortie = fusion([supprime], [modifie])
        #expect(sortie.count == 1)
        #expect(!sortie[0].estSupprime)
        #expect(sortie[0].nom == "A bis")
    }

    @Test("Pierre tombale de 31 jours purgée, celle de 29 jours gardée")
    func purge() {
        let vieille = repere(1, nom: "A", modifie: jour(40), supprime: jour(31))
        let recente = repere(2, nom: "B", modifie: jour(40), supprime: jour(29))
        let sortie = fusion([vieille, recente], [])
        #expect(sortie.map(\.nom) == ["B"])
        #expect(JeuReperes.aRetirer(distant: [vieille, recente], resultat: sortie) == [vieille.id])
    }

    @Test("Idempotente et commutative")
    func algebre() {
        let l = [repere(1, nom: "l1", modifie: jour(3)), repere(2, nom: "l2", modifie: jour(1), supprime: jour(1)),
                 repere(3, nom: "l3", modifie: jour(9))]
        let d = [repere(1, nom: "d1", modifie: jour(2)), repere(2, nom: "d2", modifie: jour(4)),
                 repere(4, nom: "d4", modifie: jour(9))]
        let ab = fusion(l, d)
        let ba = fusion(d, l)
        #expect(ab == ba)
        #expect(fusion(ab, d) == ab)
        #expect(fusion(ab, l) == ab)
        #expect(fusion(ab, ab) == ab)
    }

    @Test("Égalité parfaite de date : l'ordre des arguments ne change rien")
    func egalite() {
        let a = repere(1, nom: "A", modifie: jour(2))
        let b = repere(1, nom: "B", modifie: jour(2))
        #expect(fusion([a], [b]) == fusion([b], [a]))
        let supprimeALaMemeDate = repere(1, nom: "A", modifie: jour(5), supprime: jour(2))
        #expect(fusion([supprimeALaMemeDate], [a])[0].estSupprime)
        #expect(fusion([a], [supprimeALaMemeDate])[0].estSupprime)
    }
}
