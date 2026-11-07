import Foundation
import Testing
@testable import BuildChallenge

/// Lot US13f : la table AnglaisF (Session, Conditions, Région). Chaque clé française a une valeur anglaise non vide,
/// aucun mot de permission, la France ne change pas.
struct AnglaisFTests {
    private let en = Locale(identifier: "en_US")
    private let fr = Locale(identifier: "fr_FR")

    private func table() throws -> [String: String] {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/Session/AnglaisF.xcstrings")
        let data = try Data(contentsOf: url)
        let racine = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let chaines = try #require(racine["strings"] as? [String: [String: Any]])
        var out: [String: String] = [:]
        for (cle, entree) in chaines {
            let locs = entree["localizations"] as? [String: Any]
            let anglais = locs?["en"] as? [String: Any]
            let unite = anglais?["stringUnit"] as? [String: Any]
            out[cle] = unite?["value"] as? String ?? ""
        }
        return out
    }

    @Test func chaqueCleADeLAnglaisNonVide() throws {
        let t = try table()
        #expect(t.count > 100)
        for (cle, valeur) in t {
            #expect(!valeur.trimmingCharacters(in: .whitespaces).isEmpty, "valeur vide : \(cle)")
        }
    }

    @Test func aucunMotInterdit() throws {
        let mots = ["autoris", "allowed", "legal", "tu peux la garder", "you can keep"]
        for (_, valeur) in try table() {
            for mot in mots {
                #expect(!valeur.lowercased().contains(mot), "mot interdit « \(mot) » : \(valeur)")
            }
        }
    }

    @Test func aucuneCleNeDiffereQuParLaCasse() throws {
        var vues: [String: String] = [:]
        for cle in try table().keys {
            let bas = cle.lowercased()
            #expect(vues[bas] == nil, "« \(cle) » et « \(vues[bas] ?? "") » ne diffèrent que par la casse")
            vues[bas] = cle
        }
    }

    @Test func lAnglaisSortDeLaTableEtLeFrancaisResteTelQuel() throws {
        for (cle, valeur) in try table() {
            #expect(AnglaisF.t(cle, en) == valeur, "clé sans anglais dans le paquet : \(cle)")
            #expect(AnglaisF.t(cle, fr) == cle)
        }
    }

    @Test func lesTrousDuFrancaisEtDeLAnglaisSontLesMemes() throws {
        func trous(_ s: String) -> Int {
            s.matches(of: /%(\d+\$)?(@|lld)/).count
        }
        for (cle, valeur) in try table() {
            #expect(trous(cle) == trous(valeur), "trous différents : \(cle)")
        }
    }

    @Test func lesTextesATrousSeRemplissentDansLesDeuxLangues() {
        #expect(AnglaisF.f("Fin légale %@", locale: fr, "20 h 42") == "Fin légale 20 h 42")
        #expect(AnglaisF.f("Fin légale %@", locale: en, "8:42 PM") == "Fishing ends 8:42 PM")
        #expect(AnglaisF.f("Max. %@  Min. %@", locale: en, "54°", "41°") == "High 54°  Low 41°")
        #expect(AnglaisF.f("Prévisions sur %lld jours", locale: en, 7) == "7-day forecast")
    }

    @Test func lePluriel() {
        #expect(AnglaisF.nombre(0, un: "1 prise", autres: "%lld prises", locale: fr) == "0 prises")
        #expect(AnglaisF.nombre(1, un: "1 prise", autres: "%lld prises", locale: fr) == "1 prise")
        #expect(AnglaisF.nombre(3, un: "1 prise", autres: "%lld prises", locale: en) == "3 catches")
        #expect(AnglaisF.nombre(1, un: "1 prise", autres: "%lld prises", locale: en) == "1 catch")
    }

    @Test func laQuestionGardeLEspaceFrancaise() {
        #expect(AnglaisF.question("Terminer la session", fr) == "Terminer la session ?")
        #expect(AnglaisF.question("Terminer la session", en) == "End session?")
    }

    @Test func lesMotsEnMinusculesSuiventLaLangue() {
        #expect(AnglaisF.bas("Crue", fr) == "crue")
        #expect(AnglaisF.bas("Crue", en) == "flood")
        #expect(AnglaisF.bas("Normal", en) == "normal")
    }

    @Test func lesAvisDeSessionSontTraduitsEtLeMessageFrancaisDisparaitAuxEtatsUnis() {
        let messages = ["Quota du jour atteint", "hors de France : aucune règle française", "pêche fermée à cette heure"]
        #expect(AvisSession.affiches(messages, locale: fr) == messages)
        let anglais = AvisSession.affiches(messages, locale: en)
        #expect(anglais == ["Daily bag limit reached", "Fishing is closed at this hour"])
    }

    @Test @MainActor func laQuestionDeRattachementPasseLaLocale() {
        let p = PropositionRepere(idPrise: UUID(), idRepere: UUID(), nomRepere: "Dock")
        #expect(RattachementRepere.question(p) == "Rattacher au repère Dock ?")
        #expect(RattachementRepere.question(p, locale: en) == "Attach to the marker Dock?")
        #expect(TextesReperes.t(TextesReperes.ajouterIci, en) == "Add a marker here")
    }

    @Test @MainActor func lesEtatsDeLaRiviereEtLesCiels() {
        // Région active : France dans les tests (aucun choix enregistré) ; seul l'état anglais passe par la locale explicite.
        #expect(StyleMeteo.libelle(codeTemps: 0) == AnglaisF.t("Dégagé", RegionPersistee.lire().locale))
        #expect(AnglaisF.t("Averses", en) == "Showers")
    }
}
