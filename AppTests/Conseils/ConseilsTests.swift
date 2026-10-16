import Core
import Foundation
import Testing
@testable import BuildChallenge

@MainActor
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

    /// Core ne rend que les conseils du mois ; le vrai fichier couvre surtout avril à août.
    private struct ConseilsDeSaison: ServiceConseils {
        var moisCouverts: Set<Int>
        func conseils(espece: Espece, niveau: NiveauPecheur, mois: Int) -> [Conseil] {
            guard moisCouverts.contains(mois) else { return [] }
            return [Conseil(texte: "Ver sous une flotte", icone: "fish", source: SourceRegle(titre: "Page lue (essai)"), gratuit: true)]
        }
        func conseils(espece: Espece, niveau: NiveauPecheur, mois: Int, lieu: Lieu) -> [Conseil] {
            conseils(espece: espece, niveau: niveau, mois: mois)
        }
    }

    @Test func horsSaisonOnPrendLeMoisLePlusProcheAuLieuDeRienMontrer() {
        let contexte = ContexteConseils(conseils: ConseilsDeSaison(moisCouverts: Set(4...8)), session: SessionFaux(toutOuvert: true),
                                        mois: 10, lieu: nil, abonne: true, surSonSpot: true, toutLeKit: { _ in })
        #expect(!contexte.affiches(espece: Espece(id: "perche-commune"), niveau: .debutant).visibles.isEmpty)
        #expect(ContexteConseils.moisParProximite(10).prefix(4) == [10, 11, 9, 12])
        #expect(Set(ContexteConseils.moisParProximite(1)) == Set(1...12))
        #expect(ContexteConseils.moisParProximite(13) == [13])
    }

    @Test func percheCommuneADesConseilsPourUnDebutantEnOctobreSurLeVraiFichier() throws {
        let contexte = ContexteConseils(conseils: try ConseilsParEspece.charger(), session: SessionFaux(toutOuvert: true),
                                        mois: 10, lieu: nil, abonne: true, surSonSpot: true, toutLeKit: { _ in })
        for id in ["perche-commune", "chevesne", "ablette"] {
            #expect(!contexte.affiches(espece: Espece(id: id), niveau: .debutant).visibles.isEmpty, "\(id)")
        }
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

    @Test func tunnelDeuxiemeCategorieRelevesPuisCourantesSansTruites() {
        let ids = ["truite-fario", "ombre-commun", "chabot", "gardon", "brochet", "perche-commune", "sandre", "carpe-commune",
                   "black-bass", "tanche", "chevesne", "breme-commune", "rotengle", "silure-glane", "ablette"]
        let tout = ids.map { EspecePechable(espece: Espece(id: $0), nom: $0, nomLatin: "", image: $0) }
        let proches = [EspeceProche(espece: Espece(id: "chabot"), nPeches: 4, annee: 2024, ouverture: .ouverte),
                       EspeceProche(espece: Espece(id: "silure-glane"), nPeches: 30, annee: 2024, ouverture: .ouverte)]
        let ordre = EspecesDuTunnel.choisir(pechables: tout, proches: proches, categorie: .deuxieme).map(\.espece.id)
        #expect(Array(ordre.prefix(3)) == ["silure-glane", "chabot", "gardon"])
        #expect(!ordre.contains("truite-fario") && !ordre.contains("ombre-commun"))
        #expect(ordre.count == 12)
    }

    @Test func tunnelPremiereCategorieAccepteLesSalmonides() {
        let ids = ["gardon", "truite-fario", "brochet"]
        let tout = ids.map { EspecePechable(espece: Espece(id: $0), nom: $0, nomLatin: "", image: $0) }
        #expect(EspecesDuTunnel.choisir(pechables: tout, proches: [], categorie: .premiere).map(\.espece.id).contains("truite-fario"))
        #expect(!EspecesDuTunnel.choisir(pechables: tout, proches: [], categorie: .deuxieme).map(\.espece.id).contains("truite-fario"))
        let relevee = [EspeceProche(espece: Espece(id: "truite-fario"), nPeches: 5, annee: 2024, ouverture: .ouverte)]
        #expect(EspecesDuTunnel.choisir(pechables: tout, proches: relevee, categorie: .deuxieme).first?.espece.id == "truite-fario")
    }

    @Test func carteDeclareeNEstPasUneVraiePrise() {
        let p = Prise.declaree(espece: Espece(id: "brochet"), date: Date())
        #expect(p.estDeclaree)
        #expect(p.cheminPhoto == nil)
    }
}
