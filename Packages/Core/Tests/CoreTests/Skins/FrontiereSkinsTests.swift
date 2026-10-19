import Foundation
import Testing
@testable import Core

@Suite("Skins : frontières")
struct FrontiereSkinsTests {
    /// Les sources de `Sources/Core/Skins/`, lues depuis le dossier du dépôt (⚠ à vérifier : chemin de #filePath).
    static func sources() throws -> [(nom: String, texte: String)] {
        let paquet = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Skins
            .deletingLastPathComponent() // CoreTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // Core (le paquet)
        let dossier = paquet.appendingPathComponent("Sources/Core/Skins")
        let fichiers = try FileManager.default.contentsOfDirectory(at: dossier, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        return try fichiers.map { (nom: $0.lastPathComponent, texte: try String(contentsOf: $0, encoding: .utf8)) }
    }

    @Test("Le dossier des skins contient bien des sources")
    func sourcesTrouvees() throws {
        #expect(try Self.sources().count >= 8)
    }

    @Test("Aucun mot de rareté, de collection, de lieu ou de hasard dans les sources")
    func motsAbsents() throws {
        let interdits = ["rarete", "prise", "pescedex", "carteresultat", "lieu", "spot", "latitude", "longitude",
                         "random", "shuffle", "arc4random", "coffre", "loot", "mystère", "gacha", "tirage"]
        for source in try Self.sources() {
            let bas = source.texte.lowercased()
            for mot in interdits {
                #expect(!bas.contains(mot), "« \(mot) » trouvé dans \(source.nom)")
            }
        }
    }

    @Test("Core n'importe que Foundation")
    func importsSeulementFoundation() throws {
        for source in try Self.sources() {
            let imports = source.texte.split(whereSeparator: \.isNewline).filter { $0.hasPrefix("import ") }
            #expect(imports.allSatisfy { $0 == "import Foundation" }, "import inattendu dans \(source.nom)")
        }
    }

    @Test("Le contexte et la progression n'ont pas de champ de lieu ni de rareté")
    func champsDuContexte() {
        let contexte = OutilsSkins.contexte(OutilsSkins.date(2026, 10, 20))
        #expect(Mirror(reflecting: contexte).children.compactMap(\.label).sorted()
                == ["abonne", "calendrier", "date", "defisTermines", "progression"])
        #expect(Mirror(reflecting: ProgressionPecheur()).children.compactMap(\.label).sorted()
                == ["especesDifferentes", "legendairesPris", "sessions"])
    }

    @Test("Aucun texte de pression dans les libellés")
    func libellesSansPression() {
        let paris = OutilsSkins.calendrier()
        let contexte = OutilsSkins.contexte(OutilsSkins.date(2026, 11, 5))
        let textes = CatalogueSkins.tous.flatMap { skin -> [String] in
            let s = statut(skin, dans: contexte)
            return [LibellesSkins.ligneStatut(s, calendrier: paris),
                    LibellesSkins.accessibilite(skin, statut: s, calendrier: paris),
                    LibellesSkins.boutonAppliquer(s) ?? ""]
        }
        let interdits = ["dernière chance", "dernier jour", "plus que", "vite", "offre limitée", "expire dans",
                         "compte à rebours", "mystère", "coffre", "loot", "pokémon", "pokédex"]
        for texte in textes {
            for mot in interdits { #expect(!texte.lowercased().contains(mot), "« \(mot) » dans « \(texte) »") }
        }
    }
}
