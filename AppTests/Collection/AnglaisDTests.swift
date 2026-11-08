import Foundation
import Testing
@testable import BuildChallenge

/// Lot US13d : la table AnglaisD (Collection et Prise).
struct AnglaisDTests {
    private final class Ancre {}

    private func tableAnglaise() -> [String: String] {
        let base = Bundle(for: Ancre.self)
        for b in [base, Bundle.main, Bundle(for: AnglaisDBundleMarqueur.self)] {
            if let chemin = b.path(forResource: "AnglaisD", ofType: "strings", inDirectory: nil, forLocalization: "en"),
               let d = NSDictionary(contentsOfFile: chemin) as? [String: String] { return d }
        }
        return [:]
    }

    @Test func chaqueCleADesaValeurAnglaise() {
        let t = tableAnglaise()
        #expect(t.count > 200)
        for (cle, valeur) in t { #expect(!valeur.trimmingCharacters(in: .whitespaces).isEmpty, "\(cle)") }
    }

    @Test func aucunMotInterdit() {
        let interdit = try! Regex("legal|allowed|permitted|authori[sz]|you can keep|autoris|tu peux la garder").ignoresCase()
        for (cle, valeur) in tableAnglaise() { #expect(valeur.firstMatch(of: interdit) == nil, "\(cle)") }
    }

    @Test func laFranceNeChangePas() {
        let fr = AnglaisD(Locale(identifier: "fr_FR"))
        for (cle, _) in tableAnglaise() where !cle.contains("%") { #expect(fr(cle) == cle) }
    }

    @Test func lAnglaisTraduit() {
        let en = AnglaisD(Locale(identifier: "en_US"))
        let fr = AnglaisD(Locale(identifier: "fr_FR"))
        var traduites = 0
        for (cle, valeur) in tableAnglaise() where !cle.contains("%") { if en(cle) == valeur { traduites += 1 } }
        #expect(traduites > 150)
        #expect(en.estAnglais && !fr.estAnglais)
    }
}

final class AnglaisDBundleMarqueur {}
