import Core
import Foundation

nonisolated enum ErreurDepotReperes: Error, Equatable {
    /// Le fichier vient d'une version plus récente de l'app : on ne l'écrase pas.
    case versionFuture(Int)
    case ecriture
    case photoInvalide
}

/// Les repères sur l'iPhone : `reperes.json` et `photos/<UUID>.jpg` dans Application Support/Reperes.
/// Écriture atomique, protection `completeUntilFirstUserAuthentication` (lisible en arrière-plan après le premier déverrouillage).
/// Pas exclu des sauvegardes d'appareil : un iPhone restauré doit retrouver ses repères (à confirmer, risque 3 de la fiche).
/// Toute modification passe par `mettreAJour` : lecture, changement et écriture dans un seul appel de l'acteur, donc sans perte
/// quand la synchro iCloud et l'écran écrivent en même temps.
actor DepotReperes {
    nonisolated let dossier: URL

    init(dossier: URL = DepotReperes.dossierParDefaut()) {
        self.dossier = dossier
    }

    nonisolated static func dossierParDefaut() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Reperes", isDirectory: true)
    }

    private var fichier: URL { dossier.appendingPathComponent("reperes.json") }
    private var dossierPhotos: URL { dossier.appendingPathComponent("photos", isDirectory: true) }
    private static let ecriture: Data.WritingOptions = [.atomic, .completeFileProtectionUntilFirstUserAuthentication]

    // MARK: Repères

    /// Fichier absent : aucun repère. Fichier tronqué : erreur (jamais « aucun repère »). Version future : erreur.
    func lire() throws -> [Repere] {
        guard FileManager.default.fileExists(atPath: fichier.path) else { return [] }
        let donnees = try Data(contentsOf: fichier)
        do {
            return try CodecReperes.decoder(donnees)
        } catch ErreurCodecReperes.versionFuture(let v) {
            throw ErreurDepotReperes.versionFuture(v)
        }
    }

    /// Lit, applique `changement`, écrit, et rend le nouveau jeu. Un fichier d'une version future n'est jamais écrasé.
    /// Un fichier illisible est d'abord copié en `reperes.illisible.json`, puis on repart de la liste vide.
    @discardableResult
    func mettreAJour(_ changement: @Sendable ([Repere]) -> [Repere]) throws -> [Repere] {
        var actuels: [Repere]
        do {
            actuels = try lire()
        } catch ErreurDepotReperes.versionFuture(let v) {
            throw ErreurDepotReperes.versionFuture(v)
        } catch ErreurCodecReperes.illisible {
            let copie = dossier.appendingPathComponent("reperes.illisible.json")
            try? FileManager.default.removeItem(at: copie)
            try? FileManager.default.copyItem(at: fichier, to: copie)
            actuels = []
        }
        let nouveaux = changement(actuels)
        try preparerDossier()
        do {
            try CodecReperes.encoder(nouveaux).write(to: fichier, options: Self.ecriture)
        } catch {
            throw ErreurDepotReperes.ecriture
        }
        return nouveaux
    }

    private func preparerDossier() throws {
        do {
            try FileManager.default.createDirectory(at: dossierPhotos, withIntermediateDirectories: true)
        } catch {
            throw ErreurDepotReperes.ecriture
        }
    }

    // MARK: Photos

    /// Un nom de photo valide est un UUID suivi de « .jpg » : un nom venu d'iCloud ne peut jamais sortir du dossier.
    nonisolated static func nomPhotoValide(_ nom: String) -> Bool {
        guard nom.hasSuffix(".jpg") else { return false }
        return UUID(uuidString: String(nom.dropLast(4))) != nil
    }

    nonisolated static func nouveauNomPhoto() -> String { UUID().uuidString + ".jpg" }

    /// Écrit une photo déjà préparée (`PhotoRepere.preparer`) et rend son nom.
    func ecrirePhoto(_ donnees: Data, nom: String = DepotReperes.nouveauNomPhoto()) throws -> String {
        guard Self.nomPhotoValide(nom) else { throw ErreurDepotReperes.photoInvalide }
        try preparerDossier()
        do {
            try donnees.write(to: dossierPhotos.appendingPathComponent(nom), options: Self.ecriture)
        } catch {
            throw ErreurDepotReperes.ecriture
        }
        return nom
    }

    func photo(_ nom: String) -> Data? {
        guard Self.nomPhotoValide(nom) else { return nil }
        return try? Data(contentsOf: dossierPhotos.appendingPathComponent(nom))
    }

    func urlPhoto(_ nom: String) -> URL? {
        guard Self.nomPhotoValide(nom) else { return nil }
        let url = dossierPhotos.appendingPathComponent(nom)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func supprimerPhotos(_ noms: [String]) {
        for nom in noms where Self.nomPhotoValide(nom) {
            try? FileManager.default.removeItem(at: dossierPhotos.appendingPathComponent(nom))
        }
    }

    /// Les photos qui existent sur le disque (pour ranger celles qu'aucun repère ne cite plus).
    func nomsPhotosPresentes() -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: dossierPhotos.path)) ?? []).filter(Self.nomPhotoValide)
    }

    // MARK: Suppression du compte

    /// Efface le fichier, ses copies et toutes les photos locales (App Store 5.1.1(v)).
    func effacerTout() throws {
        guard FileManager.default.fileExists(atPath: dossier.path) else { return }
        do {
            try FileManager.default.removeItem(at: dossier)
        } catch {
            throw ErreurDepotReperes.ecriture
        }
    }
}
