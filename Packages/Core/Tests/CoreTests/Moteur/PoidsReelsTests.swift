import Foundation
import Testing
@testable import Core

/// La table poids-longueur du 16 oct. (`Resources/longueur-poids.json`) lue dans le vrai moteur.
@Suite("Poids estimé : table réelle")
struct PoidsReelsTests {
    static let service: any ServiceEspeces = CasVerdictsReelsTests.moteur.especes
    static func e(_ id: String) -> Espece { Espece(id: id, codeSandre: nil) }

    @Test("source : gardon 20 cm = 0,00367 × 20^3,3972, fourchette de 20 %, source citée")
    func source() throws {
        let p = try #require(Self.service.poidsEstime(espece: Self.e("gardon"), longueurCm: 20))
        #expect(abs(p.kilos - 0.00366816 * pow(20, 3.3972) / 1000) < 0.001)
        #expect(abs(p.minKilos - p.kilos * 0.8) < 0.002)
        #expect(p.source.contains("Irz"))
        #expect(!p.source.contains("proxy"))
    }

    @Test("proxy : estimé, source visible et marquée proxy")
    func proxy() throws {
        let p = try #require(Self.service.poidsEstime(espece: Self.e("truite-arc-en-ciel"), longueurCm: 40))
        #expect(abs(p.kilos - 0.00429131 * pow(40, 3.2637) / 1000) < 0.002)
        #expect(p.source.contains("proxy"))
        #expect(p.source.contains("Irz"))
    }

    @Test("lacune : aucun poids, mais une longueur plausible quand elle est connue",
          arguments: ["gambusie", "poisson-chat", "lamproie-marine", "mulet", "gobie-a-taches-noires"])
    func lacune(id: String) {
        #expect(Self.service.poidsEstime(espece: Self.e(id), longueurCm: 10) == nil)
    }

    @Test("sans ligne du tout : nil")
    func sansLigne() {
        #expect(Self.service.poidsEstime(espece: Self.e("ecrevisse-signal"), longueurCm: 10) == nil)
        #expect(Self.service.longueurPlausibleMax(espece: Self.e("ecrevisse-signal")) == nil)
    }

    @Test("sans plage d'étude : refusé au-delà de 1,2 × p95 (gardon p95 = 38 cm)")
    func gardePlausibilite() {
        #expect(Self.service.poidsEstime(espece: Self.e("gardon"), longueurCm: 45) != nil)
        #expect(Self.service.poidsEstime(espece: Self.e("gardon"), longueurCm: 46) == nil)
        #expect(Self.service.poidsEstime(espece: Self.e("gardon"), longueurCm: 0) == nil)
        #expect(Self.service.poidsEstime(espece: Self.e("gardon"), longueurCm: .nan) == nil)
    }

    @Test("avec plage d'étude : elle prévaut (sandre 4,5 à 76,5 cm)")
    func plageEtude() {
        #expect(Self.service.poidsEstime(espece: Self.e("sandre"), longueurCm: 60) != nil)
        #expect(Self.service.poidsEstime(espece: Self.e("sandre"), longueurCm: 80) == nil)
        #expect(Self.service.poidsEstime(espece: Self.e("sandre"), longueurCm: 3) == nil)
    }

    @Test("brochet : a et b recalés sur les prises, source visible")
    func brochet() throws {
        let p = try #require(Self.service.poidsEstime(espece: Self.e("brochet"), longueurCm: 60))
        #expect(abs(p.kilos - 0.005041 * pow(60, 3.085) / 1000) < 0.01)
        #expect(p.source.contains("prises"))
    }

    @Test("esturgeon : statut prises, pas une lacune, plage des prises (65 à 229 cm)")
    func esturgeon() throws {
        let p = try #require(Self.service.poidsEstime(espece: Self.e("esturgeon-europeen"), longueurCm: 100))
        #expect(p.source.contains("prises"))
        #expect(Self.service.poidsEstime(espece: Self.e("esturgeon-europeen"), longueurCm: 30) == nil)
    }

    @Test("silure : la table remplace la ligne serbe de 10 poissons")
    func silure() throws {
        let p = try #require(Self.service.poidsEstime(espece: Self.e("silure-glane"), longueurCm: 140))
        #expect(abs(p.kilos - 0.00805412 * pow(140, 2.972) / 1000) < 0.05)
        #expect(Self.service.poidsEstime(espece: Self.e("silure-glane"), longueurCm: 150) == nil) // hors plage de l'étude (30,9 à 148,1 cm)
        #expect(p.source.contains("Alp"))
    }

    @Test("longueurPlausibleMax : p95 par espèce, partagé dans la classe")
    func p95() {
        #expect(Self.service.longueurPlausibleMax(espece: Self.e("silure-glane")) == 166.3)
        #expect(Self.service.longueurPlausibleMax(espece: Self.e("gremille")) == 15.0)
        #expect(Self.service.longueurPlausibleMax(espece: Self.e("gambusie")) == nil) // lacune sans p95
        #expect(Self.service.longueurPlausibleMax(espece: Self.e("esturgeon-europeen")) == 163.1) // lacune avec p95
    }

    @Test("un faux ServiceEspeces n'a pas à connaître longueurPlausibleMax")
    func fauxParDefaut() {
        let faux: any ServiceEspeces = EspecesFaux()
        #expect(faux.longueurPlausibleMax(espece: Self.e("gardon")) == nil)
    }

    @Test("décodage : lacune sans a ni b, plage facultative")
    func decodage() {
        let json = #"{"lignes":[{"espece_id":"x","statut":"lacune","nl_p95_cm":30},{"espece_id":"y","a":0.01,"b":3,"source":"s"}]}"#
        let c = CoefficientPoids.decoder(Data(json.utf8))
        #expect(c.count == 2)
        #expect(c[0].estLacune && c[0].p95Cm == 30)
        #expect(c[1].ltMinCm == nil && c[1].ltMaxCm == nil && c[1].p95Cm == nil)
    }
}
