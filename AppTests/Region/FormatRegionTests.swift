import Core
import Foundation
import Testing
@testable import BuildChallenge

struct FormatRegionTests {
    private let fr = FormatRegion(region: .france)
    private let us = FormatRegion(region: .etatsUnis)
    private let utc = TimeZone(identifier: "UTC")!
    /// 7 nov. 2026, 15:05 UTC.
    private let date = Date(timeIntervalSince1970: 1_794_063_900)

    /// Les espaces insécables des formats du système (U+00A0, U+202F) ne comptent pas dans les tests.
    private func net(_ s: String) -> String {
        s.replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{00A0}", with: " ")
    }

    @Test func tailles() {
        #expect(fr.taille(centimetres: 35) == "35 cm")
        #expect(us.taille(centimetres: 35) == "13.8 in")
        #expect(fr.taille(centimetres: 35.5) == "35,5 cm")
        #expect(us.taille(.pouces(14)) == "14 in")
    }

    @Test func arrondisSurs() {
        // 35 cm = 13,78 po : un minimum s'arrondit vers le haut, un maximum vers le bas.
        #expect(us.taille(centimetres: 35, role: .tailleMinimale) == "13.8 in")
        #expect(us.taille(centimetres: 35, role: .tailleMaximale) == "13.7 in")
        // 14 po = 35,56 cm.
        #expect(fr.taille(.pouces(14), role: .tailleMinimale) == "35,6 cm")
        #expect(fr.taille(.pouces(14), role: .tailleMaximale) == "35,5 cm")
        // Valeur exacte : pas de dérive (15 po = 38,1 cm).
        #expect(fr.taille(.pouces(15), role: .tailleMinimale) == "38,1 cm")
        #expect(fr.taille(.pouces(15), role: .tailleMaximale) == "38,1 cm")
        #expect(us.taille(.pouces(15), role: .tailleMinimale) == "15 in")
        // Jamais plus souple que la règle réelle.
        for cm in stride(from: 20.0, through: 90.0, by: 0.7) {
            let min = us.taille(centimetres: cm, role: .tailleMinimale)
            let max = us.taille(centimetres: cm, role: .tailleMaximale)
            let vMin = Double(min.replacingOccurrences(of: " in", with: ""))!
            let vMax = Double(max.replacingOccurrences(of: " in", with: ""))!
            #expect(vMin * 2.54 >= cm - 1e-6)
            #expect(vMax * 2.54 <= cm + 1e-6)
        }
    }

    @Test func poidsEtTemperatures() {
        #expect(fr.poids(kilogrammes: 2.5) == "2,5 kg")
        #expect(us.poids(kilogrammes: 2.5) == "5.5 lb")
        #expect(fr.temperature(celsius: 18.4) == "18,4 °C")
        #expect(us.temperature(celsius: 20) == "68 °F")
        #expect(us.temperature(celsius: 0) == "32 °F")
        #expect(us.temperature(celsius: -5) == "23 °F")
    }

    @Test func profondeurs() {
        #expect(fr.profondeur(.metres(2.5)) == "2,5 m")
        #expect(us.profondeur(.metres(2.5)) == "8.2 ft")
    }

    @Test func distances() {
        #expect(net(fr.distance(kilometres: 12.46)) == "12,5 km")
        #expect(net(us.distance(kilometres: 12.46)) == "7.7 mi")
        #expect(net(fr.distance(metres: 850)) == "850 m")
        #expect(net(us.distance(metres: 100)) == "328 ft")
        #expect(net(us.distance(metres: 1609.344)) == "1 mi")
    }

    @Test func datesEtHeures() {
        #expect(fr.date(date, fuseau: utc) == "07/11/2026")
        #expect(us.date(date, fuseau: utc) == "11/07/2026")
        #expect(fr.jourMois(date, fuseau: utc) == "07/11")
        #expect(us.jourMois(date, fuseau: utc) == "11/07")
        #expect(net(fr.heure(date, fuseau: utc)) == "15:05")
        #expect(net(us.heure(date, fuseau: utc)) == "3:05 PM")
        #expect(net(us.dateEtHeure(date, fuseau: utc)) == "11/07/2026 3:05 PM")
    }

    @Test func leFuseauChangeLHeureAffichee() {
        let newYork = TimeZone(identifier: "America/New_York")!
        #expect(net(us.heure(date, fuseau: newYork)) == "10:05 AM")
    }
}
