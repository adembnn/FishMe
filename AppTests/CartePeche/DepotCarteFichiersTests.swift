import Core
import Foundation
import Testing
@testable import BuildChallenge

// Tests écrits, non exécutés (pas de Mac pendant l'écriture) : S les lance sur le Mac.
// Chaque test travaille dans un dossier temporaire à lui, jamais dans le vrai Application Support.

struct DepotCarteFichiersTests {
    private func dossierTemporaire() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "cartepeche-test-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    private func fiche(nom: String = "carte-1.jpg", genre: GenreFichierCarte = .image) throws -> FicheCartePeche {
        let jour = try #require(JourCivil(annee: 2026, mois: 12, jour: 31))
        return FicheCartePeche(millesime: 2026, association: "AAPPMA test", expireLe: jour,
                               fichier: FichierCarte(nom: nom, genre: genre), ajouteeLe: jour)
    }

    @Test func enregistrerPuisRelireDonneLaMemeFicheEtLesMemesOctets() throws {
        let dossier = dossierTemporaire()
        defer { try? FileManager.default.removeItem(at: dossier) }
        let depot = DepotCarteFichiers(dossier: dossier)
        let f = try fiche()
        let octets = Data((0..<256).map { UInt8($0) })
        try depot.enregistrer(f, donnees: octets)
        #expect(try depot.lire() == f)
        #expect(try depot.lireDonnees(de: f) == octets)
    }

    @Test func sansFicheLireRendNil() throws {
        let depot = DepotCarteFichiers(dossier: dossierTemporaire())
        #expect(try depot.lire() == nil)
    }

    @Test func supprimerLaisseLeDossierAbsent() throws {
        let dossier = dossierTemporaire()
        let depot = DepotCarteFichiers(dossier: dossier)
        try depot.enregistrer(try fiche(), donnees: Data([1, 2, 3]))
        #expect(FileManager.default.fileExists(atPath: dossier.path))
        try depot.supprimer()
        #expect(!FileManager.default.fileExists(atPath: dossier.path))
        #expect(try depot.lire() == nil)
        // Supprimer deux fois ne plante pas.
        try depot.supprimer()
    }

    @Test func remplacerLeFichierEffaceLAncien() throws {
        let dossier = dossierTemporaire()
        defer { try? FileManager.default.removeItem(at: dossier) }
        let depot = DepotCarteFichiers(dossier: dossier)
        var f = try fiche(nom: "carte-1.jpg")
        try depot.enregistrer(f, donnees: Data([1]))
        f.fichier = FichierCarte(nom: "carte-2.pdf", genre: .pdf)
        try depot.enregistrer(f, donnees: Data([2]))
        let noms = try FileManager.default.contentsOfDirectory(atPath: dossier.path).sorted()
        #expect(noms == ["carte-2.pdf", "fiche.json"])
    }

    @Test func unFichierTropLourdEstRefuse() throws {
        let dossier = dossierTemporaire()
        defer { try? FileManager.default.removeItem(at: dossier) }
        let depot = DepotCarteFichiers(dossier: dossier)
        #expect(throws: ErreurDepotCarte.fichierTropLourd) {
            try depot.enregistrer(try fiche(), donnees: Data(count: FichierCarte.tailleMaxOctets + 1))
        }
    }

    @Test func unNomQuiEstUnCheminEstRefuse() throws {
        let dossier = dossierTemporaire()
        defer { try? FileManager.default.removeItem(at: dossier) }
        let depot = DepotCarteFichiers(dossier: dossier)
        #expect(throws: ErreurDepotCarte.nomDeFichierDangereux) {
            try depot.enregistrer(try fiche(nom: "../evasion.jpg"), donnees: Data([1]))
        }
        #expect(throws: ErreurDepotCarte.nomDeFichierDangereux) {
            try depot.lireDonnees(de: try fiche(nom: "/etc/passwd"))
        }
    }

    @Test func uneFicheAbimeeLeveUneErreur() throws {
        let dossier = dossierTemporaire()
        defer { try? FileManager.default.removeItem(at: dossier) }
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        try Data("pas du json".utf8).write(to: dossier.appending(path: DepotCarteFichiers.nomFiche))
        #expect(throws: ErreurDepotCarte.illisible) { try DepotCarteFichiers(dossier: dossier).lire() }
    }

    @Test func leFichierImporteEstProtegeComplete() throws {
        let dossier = dossierTemporaire()
        defer { try? FileManager.default.removeItem(at: dossier) }
        let depot = DepotCarteFichiers(dossier: dossier)
        let f = try fiche()
        try depot.enregistrer(f, donnees: Data([1, 2, 3]))
        // ⚠ à vérifier sur iPhone : le simulateur peut ne pas rendre l'attribut ; sur appareil il doit valoir `.complete`.
        // Le simulateur ne rend pas toujours l'attribut (nil) : le test ne vaut alors que sur appareil, il se termine sans échec.
        guard let protection = depot.protection(de: f.fichier) else { return }
        #expect(protection == .complete)
    }
}
