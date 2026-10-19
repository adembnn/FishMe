import Core
import Foundation

// Choix par défaut de N5 (docs/fiches/N5.md, « Décisions pour Adem »), à confirmer par Adem :
// 2 gratuit ; 3 « Jusqu'au … » / « Expire dans N jours » / « Expirée le … » ; 4 on stocke le fichier, le millésime,
// l'association (facultative) et la date, jamais un nom ni un numéro ; 5 fichiers dans Application Support,
// protection `.complete`, sauvegarde iCloud de l'iPhone, aucune copie CloudKit ; 6 numéros 112, 18, 15 puis 17, 114 ;
// 8 « Événements » ouvre le site de la fédération.

nonisolated enum ErreurDepotCarte: Error, Equatable {
    case fichierTropLourd
    case nomDeFichierDangereux
    case illisible
}

/// Où vit la carte : une seule fiche à la fois en v1, sur l'iPhone, jamais envoyée ailleurs.
nonisolated protocol DepotCartePeche: Sendable {
    /// La fiche enregistrée, ou `nil` s'il n'y en a pas. Lève `.illisible` si le fichier de fiche est abîmé.
    func lire() throws -> FicheCartePeche?
    /// Le contenu du fichier importé (image ou PDF).
    func lireDonnees(de fiche: FicheCartePeche) throws -> Data
    /// Enregistre la fiche ; `donnees` est le fichier importé (`nil` : on ne change que la fiche).
    func enregistrer(_ fiche: FicheCartePeche, donnees: Data?) throws
    /// Efface la fiche et le fichier. Le dossier est vide ou absent ensuite.
    func supprimer() throws
}

/// Dépôt dans `Application Support/CartePeche/` : `fiche.json` et le fichier importé, protection `.complete`.
/// Le dossier reste dans la sauvegarde iCloud de l'iPhone (privée à l'utilisateur) : aucune copie CloudKit.
/// Pas de `UserDefaults` pour la fiche, pas de réseau.
nonisolated struct DepotCarteFichiers: DepotCartePeche {
    static let nomFiche = "fiche.json"

    let dossier: URL

    init(dossier: URL) {
        self.dossier = dossier
    }

    /// Le dépôt réel de l'app.
    static func reel() -> DepotCarteFichiers {
        let base = URL.applicationSupportDirectory
        return DepotCarteFichiers(dossier: base.appending(path: "CartePeche", directoryHint: .isDirectory))
    }

    private var urlFiche: URL { dossier.appending(path: Self.nomFiche, directoryHint: .notDirectory) }

    func lire() throws -> FicheCartePeche? {
        guard FileManager.default.fileExists(atPath: urlFiche.path) else { return nil }
        guard let donnees = try? Data(contentsOf: urlFiche),
              let fiche = try? JSONDecoder().decode(FicheCartePeche.self, from: donnees),
              fiche.fichier.nomEstSur else { throw ErreurDepotCarte.illisible }
        return fiche
    }

    func lireDonnees(de fiche: FicheCartePeche) throws -> Data {
        guard fiche.fichier.nomEstSur else { throw ErreurDepotCarte.nomDeFichierDangereux }
        return try Data(contentsOf: dossier.appending(path: fiche.fichier.nom, directoryHint: .notDirectory))
    }

    func enregistrer(_ fiche: FicheCartePeche, donnees: Data?) throws {
        guard fiche.fichier.nomEstSur else { throw ErreurDepotCarte.nomDeFichierDangereux }
        if let donnees, donnees.count > FichierCarte.tailleMaxOctets { throw ErreurDepotCarte.fichierTropLourd }

        let gestionnaire = FileManager.default
        try gestionnaire.createDirectory(at: dossier, withIntermediateDirectories: true,
                                         attributes: [.protectionKey: FileProtectionType.complete])
        let ancienne = try? lire()

        if let donnees {
            try donnees.write(to: dossier.appending(path: fiche.fichier.nom, directoryHint: .notDirectory),
                              options: [.atomic, .completeFileProtection])
        }
        let encodeur = JSONEncoder()
        encodeur.outputFormatting = [.sortedKeys]
        try encodeur.encode(fiche).write(to: urlFiche, options: [.atomic, .completeFileProtection])

        // Un fichier remplacé ne reste pas sur l'iPhone.
        if let ancienne, ancienne.fichier.nom != fiche.fichier.nom, ancienne.fichier.nomEstSur {
            try? gestionnaire.removeItem(at: dossier.appending(path: ancienne.fichier.nom, directoryHint: .notDirectory))
        }
    }

    func supprimer() throws {
        if FileManager.default.fileExists(atPath: dossier.path) {
            try FileManager.default.removeItem(at: dossier)
        }
    }

    /// L'attribut de protection lu sur un fichier du dépôt (pour le test d'app). ⚠ à vérifier : le simulateur peut ne pas le rendre.
    func protection(de fichier: FichierCarte) -> FileProtectionType? {
        let chemin = dossier.appending(path: fichier.nom, directoryHint: .notDirectory).path
        return try? FileManager.default.attributesOfItem(atPath: chemin)[.protectionKey] as? FileProtectionType
    }
}
