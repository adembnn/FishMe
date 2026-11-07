import Foundation
import Testing
@testable import Core

@Suite("Région US : système d'unités, conversions et formatage")
struct UnitesUSTests {
    let cm = FormatteurUnites(systeme: .metrique)
    let po = FormatteurUnites(systeme: .imperial)

    @Test("Pouces et centimètres : 1 po = 2,54 cm exactement")
    func pouces() {
        #expect(abs(Longueur.pouces(1).centimetres - 2.54) < 1e-12)
        #expect(abs(Longueur.centimetres(2.54).pouces - 1) < 1e-12)
        #expect(abs(Longueur.pouces(14).centimetres - 35.56) < 1e-9)
        #expect(abs(Longueur.pouces(0).millimetres) == 0)
    }

    @Test("Pieds et mètres : 1 pi = 0,3048 m")
    func pieds() {
        #expect(abs(Longueur.pieds(1).metres - 0.3048) < 1e-12)
        #expect(abs(Longueur.metres(0.3048).pieds - 1) < 1e-12)
        #expect(abs(Longueur.pieds(10).metres - 3.048) < 1e-12)
    }

    @Test("Livres et kilogrammes : 1 lb = 0,45359237 kg")
    func livres() {
        #expect(abs(Masse.livres(1).kilogrammes - 0.45359237) < 1e-12)
        #expect(abs(Masse.kilogrammes(1).livres - 2.2046226218) < 1e-9)
        #expect(abs(Masse.livres(10).grammes - 4535.9237) < 1e-9)
    }

    @Test("Températures : points fixes de l'eau et point commun à -40")
    func temperatures() {
        #expect(abs(Temperature.fahrenheit(32).celsius) < 1e-12)
        #expect(abs(Temperature.fahrenheit(212).celsius - 100) < 1e-12)
        #expect(abs(Temperature.degresCelsius(0).fahrenheit - 32) < 1e-12)
        #expect(abs(Temperature.degresCelsius(37).fahrenheit - 98.6) < 1e-9)
        #expect(abs(Temperature.fahrenheit(-40).celsius + 40) < 1e-12)
    }

    @Test("Comparaisons entre unités mélangées")
    func comparaisons() {
        #expect(Longueur.pouces(14) < .centimetres(36))
        #expect(Longueur.centimetres(35) < .pouces(14))
        #expect(Masse.livres(1) < .kilogrammes(0.5))
        #expect(Temperature.fahrenheit(50) < .degresCelsius(11))
    }

    @Test("Taille minimale : 14 po s'affiche 35,6 cm (vers le haut), jamais 35,5")
    func minimaleVersLeHaut() {
        #expect(cm.texte(.pouces(14), role: .tailleMinimale) == "35.6 cm")
    }

    @Test("Taille maximale : 14 po s'affiche 35,5 cm (vers le bas)")
    func maximaleVersLeBas() {
        #expect(cm.texte(.pouces(14), role: .tailleMaximale) == "35.5 cm")
    }

    @Test("Mesure neutre : au plus proche")
    func mesureNeutre() {
        #expect(cm.texte(.pouces(14)) == "35.6 cm")
        #expect(cm.texte(.pouces(14.04)) == "35.7 cm")   // 35,6616 cm
        #expect(cm.texte(.pouces(13.9)) == "35.3 cm")    // 35,306 cm
    }

    @Test("Fenêtre protégée 14 à 18 po : le début baisse, la fin monte, la fenêtre affichée contient la vraie")
    func fenetre() {
        #expect(cm.texte(.pouces(14), role: .debutFenetreProtegee) == "35.5 cm")
        #expect(cm.texte(.pouces(18), role: .finFenetreProtegee) == "45.8 cm")
    }

    @Test("Une valeur exacte ne bouge pas : 15 po = 38,1 cm, jamais 38,2 à cause d'un reste binaire")
    func valeurExacte() {
        for role in RoleValeur.allCases {
            #expect(cm.texte(.pouces(15), role: role) == "38.1 cm")
        }
        #expect(cm.texte(.pouces(20), role: .tailleMinimale) == "50.8 cm")
        #expect(cm.texte(.pouces(10), role: .tailleMinimale) == "25.4 cm")
        #expect(po.texte(.centimetres(50), role: .tailleMinimale) == "19.7 in")     // 19,685 po : monte
        #expect(po.texte(.centimetres(50.8), role: .tailleMinimale) == "20 in")     // exact : ne monte pas
    }

    @Test("Du métrique vers l'impérial : 45 cm = 17,72 po, minimale 17,8, maximale 17,7")
    func metriqueVersImperial() {
        #expect(po.texte(.centimetres(45), role: .tailleMinimale) == "17.8 in")
        #expect(po.texte(.centimetres(45), role: .tailleMaximale) == "17.7 in")
        #expect(po.texte(.centimetres(45)) == "17.7 in")
    }

    @Test("Les zéros inutiles sont retirés, jamais de fausse précision")
    func zeros() {
        #expect(po.texte(.pouces(14)) == "14 in")
        #expect(po.texte(.pouces(14.5)) == "14.5 in")
        #expect(cm.texte(.centimetres(40)) == "40 cm")
        #expect(cm.texte(.centimetres(40.04)) == "40 cm")
    }

    @Test("Séparateur décimal au choix")
    func separateur() {
        let f = FormatteurUnites(systeme: .metrique, separateurDecimal: ",")
        #expect(f.texte(.pouces(14), role: .tailleMinimale) == "35,6 cm")
        #expect(f.texte(.pouces(14), role: .tailleMinimale).contains(".") == false)
    }

    @Test("Profondeurs : pieds et mètres")
    func profondeurs() {
        #expect(po.texte(.metres(3), grandeur: .profondeur) == "9.8 ft")
        #expect(cm.texte(.pieds(10), grandeur: .profondeur) == "3.05 m")
        #expect(cm.texte(.pieds(10), role: .tailleMaximale, grandeur: .profondeur) == "3.04 m")
        #expect(cm.texte(.pieds(10), role: .tailleMinimale, grandeur: .profondeur) == "3.05 m")
    }

    @Test("Masses : livres et kilogrammes avec sens d'arrondi")
    func masses() {
        #expect(cm.texte(Masse.livres(5), role: .tailleMinimale) == "2.27 kg")   // 2,26796
        #expect(cm.texte(Masse.livres(5), role: .tailleMaximale) == "2.26 kg")
        #expect(po.texte(Masse.kilogrammes(1)) == "2.2 lb")
        #expect(po.texte(Masse.kilogrammes(1), role: .tailleMinimale) == "2.3 lb")
    }

    @Test("Températures : 68 °F = 20 °C, 0 °F ne s'écrit jamais -0")
    func temperaturesTexte() {
        #expect(cm.texte(Temperature.fahrenheit(68)) == "20 °C")
        #expect(po.texte(Temperature.degresCelsius(20)) == "68 °F")
        #expect(po.texte(Temperature.fahrenheit(0)) == "0 °F")
        #expect(cm.texte(Temperature.degresCelsius(-0.04)) == "0 °C")
        #expect(cm.texte(Temperature.fahrenheit(-40)) == "-40 °C")
    }

    @Test("Propriété : de 1 à 60 po par quarts de pouce, une minimale affichée en cm n'est jamais sous la vraie, une maximale jamais au-dessus")
    func proprieteSensPrudent() {
        var po = 1.0
        while po <= 60 {
            let vraie = Longueur.pouces(po).centimetres
            let min = Double(cm.texte(.pouces(po), role: .tailleMinimale).dropLast(3))!
            let max = Double(cm.texte(.pouces(po), role: .tailleMaximale).dropLast(3))!
            let debut = Double(cm.texte(.pouces(po), role: .debutFenetreProtegee).dropLast(3))!
            let fin = Double(cm.texte(.pouces(po), role: .finFenetreProtegee).dropLast(3))!
            #expect(min >= vraie - 1e-9, "minimale \(po) po")
            #expect(min - vraie < 0.1 + 1e-9, "minimale \(po) po : écart au plus 1 mm")
            #expect(max <= vraie + 1e-9, "maximale \(po) po")
            #expect(vraie - max < 0.1 + 1e-9, "maximale \(po) po : écart au plus 1 mm")
            #expect(debut <= vraie + 1e-9 && fin >= vraie - 1e-9, "fenêtre \(po) po")
            po += 0.25
        }
    }

    @Test("Propriété inverse : du métrique vers les pouces, même sens prudent de 10 à 150 cm")
    func proprieteInverse() {
        let po = FormatteurUnites(systeme: .imperial)
        var c = 10.0
        while c <= 150 {
            let vraie = Longueur.centimetres(c).pouces
            let min = Double(po.texte(.centimetres(c), role: .tailleMinimale).dropLast(3))!
            let max = Double(po.texte(.centimetres(c), role: .tailleMaximale).dropLast(3))!
            #expect(min >= vraie - 1e-9 && min - vraie < 0.1 + 1e-9, "minimale \(c) cm")
            #expect(max <= vraie + 1e-9 && vraie - max < 0.1 + 1e-9, "maximale \(c) cm")
            c += 0.5
        }
    }

    @Test("Chaque rôle a un sens d'arrondi fixé")
    func roles() {
        #expect(RoleValeur.tailleMinimale.sens == .versLeHaut)
        #expect(RoleValeur.finFenetreProtegee.sens == .versLeHaut)
        #expect(RoleValeur.tailleMaximale.sens == .versLeBas)
        #expect(RoleValeur.debutFenetreProtegee.sens == .versLeBas)
        #expect(RoleValeur.mesure.sens == .auPlusProche)
    }

    @Test("Les systèmes d'unités sont deux, Codable par nom")
    func systemes() throws {
        #expect(SystemeUnites.allCases == [.imperial, .metrique])
        #expect(try JSONDecoder().decode(SystemeUnites.self, from: Data("\"metrique\"".utf8)) == .metrique)
    }
}
