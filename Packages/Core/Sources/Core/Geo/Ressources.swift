import Foundation

/// Lecture des fichiers de `Resources/` embarqués (Bundle.module). Fichier absent ou illisible : `nil`, jamais de plantage.
enum Ressources {
    static func donnees(_ nom: String, extension ext: String = "json") -> Data? {
        guard let url = Bundle.module.url(forResource: nom, withExtension: ext) else { return nil }
        return try? Data(contentsOf: url)
    }

    /// Le dossier `regles/` embarqué (copié tel quel par Package.swift).
    static var dossierRegles: URL? { Bundle.module.url(forResource: "regles", withExtension: nil) }
}
