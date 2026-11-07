import Foundation
import Testing
@testable import Core

/// Le dossier `regles-us/` est bien copié dans le paquet (`.copy("Resources/regles-us")` dans Package.swift).
@Suite struct EmbarqueUSTests {
    @Test func dossierEmbarquePresent() throws {
        let dossier = try #require(ChargementReglesUS.dossierEmbarque)
        #expect(FileManager.default.fileExists(atPath: dossier.appendingPathComponent("index.json").path))
        #expect(FileManager.default.fileExists(atPath: dossier.appendingPathComponent("etats.json").path))
    }

    @Test func indexEmbarqueLisible() throws {
        let index = try ChargementReglesUS.embarque().index()
        #expect(index.niveau1 != nil)
    }

    @Test func niveau1EmbarqueLisible() throws {
        let n1 = try Niveau1US.embarque()
        #expect(!n1.etats.isEmpty)
    }
}
