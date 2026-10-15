import Foundation

/// Le message du bouton « signaler une erreur de règle » (L9) : ce que L11 fixe pour qu'il retombe dans la même alerte
/// que la veille. Trois champs, sans position du pêcheur : l'identifiant de la règle, le département et la version
/// du fichier qui servait. Où le message arrive dépend du contact de Mon club (choix d'Adem).
public struct SignalementRegle: Sendable, Equatable {
    public var regleId: String
    public var departement: String
    public var versionFichier: String

    public init(regleId: String, departement: String, versionFichier: String) {
        self.regleId = regleId
        self.departement = departement
        self.versionFichier = versionFichier
    }

    /// « Erreur de règle signalée · regle=94-bro-ouv-2026 · departement=94 · fichier=2026-10-15.1 ».
    public var texte: String {
        "Erreur de règle signalée · regle=\(regleId) · departement=\(departement) · fichier=\(versionFichier)"
    }

    /// Relit un texte produit par `texte`, ou `nil`.
    public init?(texte: String) {
        var champs: [String: String] = [:]
        for morceau in texte.components(separatedBy: " · ") {
            let paire = morceau.split(separator: "=", maxSplits: 1)
            if paire.count == 2 { champs[String(paire[0])] = String(paire[1]) }
        }
        guard let regle = champs["regle"], let departement = champs["departement"], let fichier = champs["fichier"],
              !regle.isEmpty, !departement.isEmpty, !fichier.isEmpty else { return nil }
        self.init(regleId: regle, departement: departement, versionFichier: fichier)
    }
}

extension CatalogueRegles {
    /// Le signalement d'une règle du fichier qui sert, avec la version de ce fichier. `nil` si le fichier ou la règle manque.
    public func signalement(regleId: String, departement: Departement) -> SignalementRegle? {
        guard let fichier = meilleure(departement.code)?.fichier, fichier.regles.contains(where: { $0.id == regleId })
        else { return nil }
        return SignalementRegle(regleId: regleId, departement: departement.code, versionFichier: fichier.version.texte)
    }
}
