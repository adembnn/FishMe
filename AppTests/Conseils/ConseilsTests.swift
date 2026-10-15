import Core
import Foundation
import Testing
@testable import BuildChallenge

struct ConseilsTests {
    private func conseil(_ texte: String, gratuit: Bool, source: String = "Fédération (essai)") -> Conseil {
        Conseil(texte: texte, icone: "fish", source: SourceRegle(titre: source), gratuit: gratuit)
    }

    @Test func sansAbonnementSeulLePremierEstVisible() {
        let a = RegleConseils.affiches([conseil("a", gratuit: true), conseil("b", gratuit: false)], toutOuvert: false)
        #expect(a.visibles.count == 1)
        #expect(a.nbCaches == 1)
        #expect(a.toutLeKit)
    }

    @Test func abonneVoitTout() {
        let a = RegleConseils.affiches([conseil("a", gratuit: true), conseil("b", gratuit: false)], toutOuvert: true)
        #expect(a.visibles.count == 2)
        #expect(!a.toutLeKit)
    }

    @Test func unConseilSansSourceNeSAffichePas() {
        let a = RegleConseils.affiches([conseil("a", gratuit: true, source: "  ")], toutOuvert: true)
        #expect(a.visibles.isEmpty)
    }

    @Test func leContexteSuitPeutUtiliserDeCore() {
        let fermé = ContexteConseils(conseils: ConseilsFaux(), session: SessionFaux(toutOuvert: false), mois: 10, lieu: nil,
                                     abonne: false, surSonSpot: true, toutLeKit: { _ in })
        let ouvert = ContexteConseils(conseils: ConseilsFaux(), session: SessionFaux(toutOuvert: true), mois: 10, lieu: nil,
                                      abonne: true, surSonSpot: true, toutLeKit: { _ in })
        let espece = Espece(id: "brochet")
        #expect(fermé.affiches(espece: espece, niveau: .debutant).visibles.count == 1)
        #expect(ouvert.affiches(espece: espece, niveau: .confirme).visibles.count == 2)
    }

    @Test func niveauInconnuDonneOccasionnel() {
        #expect(NiveauPecheur.depuis("n'importe quoi") == .occasionnel)
        #expect(NiveauPecheur.depuis("confirme") == .confirme)
    }

    @Test func especesDuSpotOuvertesDAbordLaPlusReleveeEnTete() {
        let a = EspeceProche(espece: Espece(id: "a"), nPeches: 3, annee: 2024, ouverture: .ouverte)
        let b = EspeceProche(espece: Espece(id: "b"), nPeches: 20, annee: 2024, ouverture: .fermee(reouverture: nil))
        let c = EspeceProche(espece: Espece(id: "c"), nPeches: 9, annee: 2024, ouverture: .ouverte)
        #expect(EspecesDuSpot.ordonnees([a, b, c]).map(\.espece.id) == ["c", "a", "b"])
        #expect(EspecesDuSpot.texteFermeture(.ouverte) == nil)
        #expect(EspecesDuSpot.texteFermeture(b.ouverture) == "Fermée ce jour")
    }

    @Test func tunnelPrendLesEspecesDeLaZoneDAbordSansDoublon() {
        let tout = (1...20).map { EspecePechable(espece: Espece(id: "e\($0)"), nom: "E\($0)", nomLatin: "", image: "e\($0)") }
        let proches = [EspeceProche(espece: Espece(id: "e15"), nPeches: 9, annee: 2024, ouverture: .ouverte)]
        let choisies = EspecesDuTunnel.choisir(pechables: tout, proches: proches)
        #expect(choisies.count == 12)
        #expect(choisies.first?.espece.id == "e15")
        #expect(Set(choisies.map(\.espece.id)).count == 12)
    }

    @Test func carteDeclareeNEstPasUneVraiePrise() {
        let p = Prise.declaree(espece: Espece(id: "brochet"), date: Date())
        #expect(p.estDeclaree)
        #expect(p.cheminPhoto == nil)
    }
}
