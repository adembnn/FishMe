import Foundation
import Testing
import simd
@testable import BuildChallenge

struct MesureARTests {
    @Test func margeAvecLidarEstLaPlusGrandeDe2cmEt4Pourcent() {
        #expect(MesureARCalcul.margeCm(longueurCm: 30, lidar: true) == 2)
        #expect(abs(MesureARCalcul.margeCm(longueurCm: 100, lidar: true) - 4) < 1e-9)
    }

    @Test func margeSansLidarEstLaPlusGrandeDe4cmEt8Pourcent() {
        #expect(MesureARCalcul.margeCm(longueurCm: 30, lidar: false) == 4)
        #expect(abs(MesureARCalcul.margeCm(longueurCm: 100, lidar: false) - 8) < 1e-9)
    }

    @Test func plageAfficheUneFourchette() {
        let p = MesureARCalcul.plage(longueurCm: 54, lidar: true)
        #expect(p.basCm == 52 && p.centreCm == 54 && p.hautCm == 56)
        #expect(p.texte == "52 à 56 cm")
        let s = MesureARCalcul.plage(longueurCm: 54, lidar: false)
        #expect(s.texte == "50 à 58 cm")
    }

    @Test func plageNeDescendJamaisSousZero() {
        #expect(MesureARCalcul.plage(longueurCm: 3, lidar: false).basCm == 0)
    }

    @Test func distanceEn3DEnCentimetres() {
        let d = MesureARCalcul.distanceCm(SIMD3<Float>(0, 0, 0), SIMD3<Float>(0.3, 0.4, 0))
        #expect(abs(d - 50) < 1e-4)
    }

    @Test func plausibilite() {
        #expect(MesureARCalcul.plausible(54))
        #expect(!MesureARCalcul.plausible(2))
        #expect(!MesureARCalcul.plausible(250))
        #expect(!MesureARCalcul.plausible(.nan))
        #expect(MesureARCalcul.plausible(80, plage: 10...100))
        #expect(!MesureARCalcul.plausible(120, plage: 10...100))
    }

    @Test func plageEspeceDepuisLeP95() {
        #expect(MesureARCalcul.plageEspece(p95Cm: nil) == MesureARCalcul.plageParDefaut)
        #expect(MesureARCalcul.plageEspece(p95Cm: .nan) == MesureARCalcul.plageParDefaut)
        let gremille = MesureARCalcul.plageEspece(p95Cm: 15) // plafond 18 cm
        #expect(MesureARCalcul.plausible(17, plage: gremille))
        #expect(!MesureARCalcul.plausible(40, plage: gremille))
        #expect(!MesureARCalcul.plausible(2, plage: gremille))
        let silure = MesureARCalcul.plageEspece(p95Cm: 166.3) // plafond 199,56 cm
        #expect(MesureARCalcul.plausible(190, plage: silure))
        #expect(!MesureARCalcul.plausible(210, plage: silure))
    }

    @Test func textePoidsAuxDeuxBornes() {
        #expect(MesureARCalcul.textePoids(minKilos: 1.6, maxKilos: 2.04) == "≈ 1,6 à 2,0 kg, estimé")
    }
}
