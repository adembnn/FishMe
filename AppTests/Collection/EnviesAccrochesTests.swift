import Core
import Foundation
import Testing
@testable import BuildChallenge

// Tests écrits, non exécutés : à lancer sur Mac. // ⚠ à vérifier

private final class StockageMemoireAccroches: StockageEnvies, @unchecked Sendable {
    private let verrou = NSLock()
    private var contenu: ListeEnvies
    init(_ contenu: ListeEnvies = ListeEnvies()) { self.contenu = contenu }
    func lire() -> ListeEnvies { verrou.lock(); defer { verrou.unlock() }; return contenu }
    func ecrire(_ liste: ListeEnvies) { verrou.lock(); defer { verrou.unlock() }; contenu = liste }
}

/// Les accroches de « Mes envies » dans le Pescedex (N2 posé après L18).
@MainActor
struct EnviesAccrochesTests {
    private func pechable(_ id: String, nom: String) -> EspecePechable {
        EspecePechable(espece: Espece(id: id), nom: nom, nomLatin: "Latinus", image: id, statuts: [])
    }

    private var especes: [EspecePechable] { [pechable("brochet", nom: "Brochet"), pechable("sandre", nom: "Sandre")] }

    private func source(_ chemin: String) throws -> String {
        let racine = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try String(contentsOf: racine.appendingPathComponent(chemin), encoding: .utf8)
    }

    @Test func laLigneDuPescedexSeLitAvecLeNombre() {
        #expect(TextesEnvies.ligneDuPescedex(nombre: 2) == "Mes envies · 2")
    }

    @Test func lePescedexSansModeleEnviesResteInchange() throws {
        let texte = try source("App/Collection/PescedexView.swift")
        #expect(texte.contains("var envies: EnviesModele? = nil"))
    }

    @Test func lesAccrochesSontPoseesDansLePescedex() throws {
        let texte = try source("App/Collection/PescedexView.swift")
        #expect(texte.contains("LigneMesEnviesView(nombre: envies.nombre)"))
        #expect(texte.contains("envies.nombre >= 1"))
        #expect(texte.contains("MesEnviesView(modele: envies"))
        #expect(texte.contains("BoutonEnvieView(espece: emplacement.espece, modele: envies)"))
        #expect(texte.contains(".menuEnvie(espece: e.espece, modele: envies)"))
    }

    @Test func chaqueChargementDuPescedexRechargeLesEnvies() throws {
        let texte = try source("App/Collection/PescedexView.swift")
        let lignes = texte.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
        let appels = lignes.enumerated().filter { $0.element.hasPrefix("await modele.charger()") || $0.element.hasPrefix("await modele.choisir(") }
        #expect(!appels.isEmpty)
        for (i, _) in appels {
            let suivante = i + 1 < lignes.count ? lignes[i + 1] : ""
            #expect(suivante == "rechargerEnvies()", "ligne \(i + 1) : pas de rechargerEnvies() derrière")
        }
    }

    @Test func uneCartePriseFaitSortirLEnvieAuChargement() {
        let modele = EnviesModele(stockage: StockageMemoireAccroches(), especes: especes)
        modele.basculer(especes[0])
        #expect(modele.nombre == 1)
        modele.charger(cartes: [Prise(espece: Espece(id: "brochet"), date: Date(timeIntervalSince1970: 1_000))])
        #expect(modele.nombre == 0)
    }

    @Test func lesEnviesPassentParLeProfilDeSauvegardeEtSeRelisent() {
        let stockage = StockageMemoireAccroches()
        let modele = EnviesModele(stockage: stockage, especes: especes)
        modele.basculer(especes[0])
        let profil = ProfilSauvegarde(envies: modele.liste.envies)
        #expect(!profil.estVide)
        // Restauration sur un iPhone neuf : le profil iCloud gagne, puis le modèle relit son stockage.
        let neuf = StockageMemoireAccroches()
        let modeleNeuf = EnviesModele(stockage: neuf, especes: especes)
        let fusion = FusionSauvegarde.fusionner(local: ProfilSauvegarde(), distant: profil)
        neuf.ecrire(ListeEnvies(envies: fusion.envies))
        modeleNeuf.relire()
        #expect(modeleNeuf.contient(especes[0]))
        #expect(modeleNeuf.nombre == 1)
    }
}
