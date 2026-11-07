import Foundation
import Testing
@testable import Core

@Suite("Région US : codes d'État et hiérarchie des juridictions")
struct HierarchieUSTests {
    @Test("Les 50 États et DC : 51 codes USPS distincts")
    func codesEtats() {
        #expect(CodeEtat.tous.count == 51)
        #expect(Set(CodeEtat.tous.map(\.rawValue)).count == 51)
        #expect(CodeEtat.tous.contains(usEtat("DC")))
        #expect(CodeEtat.tous.allSatisfy { $0.rawValue.count == 2 })
    }

    @Test("Un code inconnu est refusé, la casse est normalisée")
    func codeInconnu() {
        #expect(CodeEtat(rawValue: "ZZ") == nil)
        #expect(CodeEtat(rawValue: "PR") == nil)
        #expect(CodeEtat(rawValue: "") == nil)
        #expect(CodeEtat(rawValue: "wi")?.rawValue == "WI")
    }

    @Test("Codable : un code d'État invalide ne se décode pas")
    func codableEtat() throws {
        let data = try JSONEncoder().encode([usEtat("MN")])
        #expect(String(decoding: data, as: UTF8.self) == "[\"MN\"]")
        #expect(try JSONDecoder().decode([CodeEtat].self, from: data) == [usEtat("MN")])
        #expect(throws: DecodingError.self) { try JSONDecoder().decode([CodeEtat].self, from: Data("[\"XX\"]".utf8)) }
    }

    @Test("Identifiants stables : US-<USPS> pour un État, refus du vide et des espaces")
    func identifiants() {
        #expect(IdJuridiction.etat(usEtat("WI")).rawValue == "US-WI")
        #expect(IdJuridiction(rawValue: "") == nil)
        #expect(IdJuridiction(rawValue: "US-WI lac") == nil)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode([IdJuridiction].self, from: Data("[\"a b\"]".utf8)) }
    }

    @Test("Les niveaux sont ordonnés du plus large au plus précis")
    func niveaux() {
        #expect(NiveauJuridiction.etat < .zone && NiveauJuridiction.zone < .planDeau && NiveauJuridiction.planDeau < .troncon)
        #expect(NiveauJuridiction.allCases.count == 4)
    }

    @Test("Un État ne peut avoir ni parent ni un identifiant autre que US-<code>")
    func etatCoherent() {
        #expect(Juridiction(id: usWI, niveau: .etat, nom: "WI", etat: usEtat("WI"), parent: usMI) == nil)
        #expect(Juridiction(id: usId("WI"), niveau: .etat, nom: "WI", etat: usEtat("WI")) == nil)
        #expect(Juridiction(id: usId("US-MI"), niveau: .etat, nom: "WI", etat: usEtat("WI")) == nil)
        #expect(Juridiction.etat(usEtat("WI"), nom: "Wisconsin") != nil)
    }

    @Test("Un niveau sous l'État exige un parent différent de lui-même et un nom")
    func sousEtatCoherent() {
        #expect(Juridiction(id: usLacX, niveau: .planDeau, nom: "Lac X", etat: usEtat("WI")) == nil)
        #expect(Juridiction(id: usLacX, niveau: .planDeau, nom: "Lac X", etat: usEtat("WI"), parent: usLacX) == nil)
        #expect(Juridiction(id: usLacX, niveau: .planDeau, nom: "  ", etat: usEtat("WI"), parent: usWI) == nil)
    }

    @Test("HUC8 : huit chiffres ou rien")
    func huc8() {
        func j(_ h: String?) -> Juridiction? { Juridiction(id: usLacX, niveau: .planDeau, nom: "X", etat: usEtat("WI"), parent: usWI, huc8: h) }
        #expect(j("07070001")?.huc8 == "07070001")
        #expect(j(nil)?.huc8 == nil)
        #expect(j("0707000") == nil)
        #expect(j("070700012") == nil)
        #expect(j("0707000A") == nil)
        #expect(j("０７０７０００１") == nil)
    }

    @Test("La chaîne va de l'État au tronçon")
    func chaine() {
        let arbre = usArbre()
        #expect(arbre.chaine(de: usTroncon)?.map(\.id) == [usWI, usNord, usLacX, usTroncon])
        #expect(arbre.chaine(de: usTroncon)?.map(\.niveau) == [.etat, .zone, .planDeau, .troncon])
        #expect(arbre.chaine(de: usLacY)?.map(\.id) == [usWI, usLacY])
        #expect(arbre.chaine(de: usWI)?.map(\.id) == [usWI])
        #expect(arbre.chaine(de: usId("US-WI/inconnu")) == nil)
    }

    @Test("Enfants et accès par identifiant")
    func enfants() {
        let arbre = usArbre()
        #expect(arbre.enfants(de: usWI).map(\.id) == [usLacY, usNord, usReserve])
        #expect(arbre.enfants(de: usTroncon).isEmpty)
        #expect(arbre[usLacX]?.huc8 == "07070001")
        #expect(arbre.toutes.count == 8)
    }

    @Test("Arbre invalide : doublon, parent inconnu, niveau incohérent, État différent du parent")
    func erreursArbre() throws {
        let wi = Juridiction.etat(usEtat("WI"), nom: "WI")!
        let mi = Juridiction.etat(usEtat("MI"), nom: "MI")!
        let zone = Juridiction(id: usNord, niveau: .zone, nom: "Nord", etat: usEtat("WI"), parent: usWI)!
        let lac = Juridiction(id: usLacX, niveau: .planDeau, nom: "X", etat: usEtat("WI"), parent: usNord)!
        #expect(throws: ErreurArbreJuridictions.identifiantEnDouble(usWI)) { try ArbreJuridictions([wi, wi]) }
        #expect(throws: ErreurArbreJuridictions.parentInconnu(usNord)) { try ArbreJuridictions([wi, zone.withParent(usId("US-WI/fantome"))]) }
        #expect(throws: ErreurArbreJuridictions.niveauIncoherent(usNord)) { try ArbreJuridictions([wi, lac, zone.withParent(usLacX)]) }
        let mauvaisEtat = Juridiction(id: usNord, niveau: .zone, nom: "Nord", etat: usEtat("MI"), parent: usWI)!
        #expect(throws: ErreurArbreJuridictions.etatDifferentDuParent(usNord)) { try ArbreJuridictions([wi, mi, mauvaisEtat]) }
        _ = try ArbreJuridictions([wi, zone, lac])
    }

    @Test("Un plan d'eau peut se rattacher directement à l'État (zone sautée)")
    func zoneSautee() throws {
        #expect(usArbre().chaine(de: usLacY)?.count == 2)
    }

    @Test("Codable d'une juridiction : aller-retour exact")
    func codableJuridiction() throws {
        let j = Juridiction(id: usLacX, niveau: .planDeau, nom: "Lac X", etat: usEtat("WI"), parent: usNord, huc8: "07070001",
                            alertes: [.eauFrontaliere], lienAgence: usLienWI)!
        let data = try JSONEncoder().encode(j)
        #expect(try JSONDecoder().decode(Juridiction.self, from: data) == j)
    }

    @Test("RegionApp : deux régions, unités par défaut")
    func regionApp() {
        #expect(RegionApp.allCases == [.france, .etatsUnis])
        #expect(RegionApp.france.unitesParDefaut == .metrique)
        #expect(RegionApp.etatsUnis.unitesParDefaut == .imperial)
        #expect(RegionApp.etatsUnis.rawValue == "etatsUnis")
    }
}

private extension Juridiction {
    func withParent(_ p: IdJuridiction) -> Juridiction {
        Juridiction(id: id, niveau: niveau, nom: nom, etat: etat, parent: p, huc8: huc8, alertes: alertes, lienAgence: lienAgence)!
    }
}
