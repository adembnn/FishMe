import Foundation
import Testing
@testable import BuildChallenge

struct ReglagesCommunauteTests {
    private func defauts() -> UserDefaults {
        let nom = "test.communaute.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: nom)!
        d.removePersistentDomain(forName: nom)
        return d
    }

    @Test func leReseauEstEteintParDefaut() {
        #expect(ReglagesCommunaute.reseauParDefaut == false)
        #expect(ReglagesCommunaute.reseauActif(defaults: defauts(), debug: false) == false)
        #expect(ReglagesCommunaute.reseauActif(defaults: defauts(), debug: true) == false)
    }

    @Test func lOngletEstAfficheEnV1() {
        #expect(ReglagesCommunaute.afficherOnglet == true)
    }

    @Test func enReleaseLaCleDebugEstIgnoree() {
        let d = defauts()
        d.set(true, forKey: ReglagesCommunaute.cleDebug)
        #expect(ReglagesCommunaute.reseauActif(defaults: d, debug: false) == false)
    }

    @Test func enDebugLaCleRallumeLeReseau() {
        let d = defauts()
        d.set(true, forKey: ReglagesCommunaute.cleDebug)
        #expect(ReglagesCommunaute.reseauActif(defaults: d, debug: true) == ReglagesCommunaute.afficherOnglet)
        d.set(false, forKey: ReglagesCommunaute.cleDebug)
        #expect(ReglagesCommunaute.reseauActif(defaults: d, debug: true) == false)
    }
}
