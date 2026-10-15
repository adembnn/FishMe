import Foundation

/// Ce qui s'est passé à une mise à jour. Pour les journaux et les tests : le pêcheur ne voit jamais d'erreur.
public struct RapportMiseAJour: Sendable, Equatable {
    /// Les fichiers pris (« 94 », « national »).
    public var adoptes: [String] = []
    /// Les fichiers dont la copie a déjà l'empreinte de l'index.
    public var inchanges: [String] = []
    /// Les fichiers refusés, avec la raison ; leur copie est restée en place.
    public var refuses: [String: RaisonRefus] = [:]
    /// `false` si `index.json` n'a pas pu être pris (réseau coupé, pas d'adresse, index illisible) : rien n'a changé.
    public var indexLu = false

    public init() {}
}

/// La mise à jour des règles (L11), au lancement de l'app.
///
/// 1. Demande `index.json` (quelques Ko). 2. Compare l'empreinte sha256 de chaque fichier à celle de sa copie.
/// 3. Télécharge tous les fichiers changés ou nouveaux, pas seulement celui du département du pêcheur : le serveur
///    n'apprend rien de l'endroit où il pêche. 4. Ne garde un fichier que s'il est valide (JSON lisible, empreinte égale à
///    celle de l'index, version plus récente que la copie, forme de `donnees.md`). Chaque fichier est écrit en entier puis
///    substitué à sa copie, un par un ; un fichier refusé ne bloque pas les autres. Sans réseau, la copie embarquée ou
///    la dernière copie valide sert, sans message d'erreur.
public actor MiseAJourRegles {
    /// Au-delà, un fichier est refusé sans être lu (un département fait quelques centaines de Ko).
    public static let tailleMaxFichier = 10 * 1024 * 1024

    private let telechargeur: any TelechargeFichier
    private let depot: DepotRegles
    private let embarque: URL?

    public init(telechargeur: any TelechargeFichier, embarque: URL?, copies: URL) {
        self.telechargeur = telechargeur
        self.embarque = embarque
        self.depot = DepotRegles(dossier: copies)
    }

    /// La vue sur les fichiers présents (embarqués et téléchargés), pour `departementsCouverts()` et le moteur de règles.
    public nonisolated var catalogue: CatalogueRegles { CatalogueRegles(embarque: embarque, depot: depot) }

    /// Une mise à jour. Ne lève jamais d'erreur : tout échec laisse les copies en place.
    @discardableResult
    public func mettreAJour() async -> RapportMiseAJour {
        var rapport = RapportMiseAJour()
        guard let empreintes = await lireIndex() else { return rapport }
        rapport.indexLu = true

        let catalogue = self.catalogue
        for (code, attendu) in empreintes.sorted(by: { $0.key < $1.key }) {
            let copie = catalogue.meilleure(code)
            if let copie, Sha256.hex(copie.data) == attendu {
                rapport.inchanges.append(code)
                continue
            }
            do {
                let data = try await telechargeur.telecharger(chemin: "\(code).json")
                try accepter(data, code: code, attendu: attendu, copieActuelle: copie)
                rapport.adoptes.append(code)
            } catch let raison as RaisonRefus {
                rapport.refuses[code] = raison
            } catch {
                rapport.refuses[code] = .telechargement
            }
        }
        return rapport
    }

    /// Les fichiers de l'index : code (ou « national ») vers empreinte. `nil` si l'index manque ou est illisible.
    private func lireIndex() async -> [String: String]? {
        guard let data = try? await telechargeur.telecharger(chemin: "index.json"),
              data.count <= Self.tailleMaxFichier,
              let objet = try? JSONSerialization.jsonObject(with: data), let index = objet as? [String: Any],
              let departements = index["departements"] as? [String: Any] else { return nil }
        var empreintes: [String: String] = [:]
        for (code, entree) in departements {
            guard CatalogueRegles.codeValide(code), let sha = (entree as? [String: Any])?["sha256"] as? String,
                  Self.estUneEmpreinte(sha) else { continue }
            empreintes[code] = sha
        }
        if let national = index["national"] as? [String: Any], let sha = national["sha256"] as? String,
           Self.estUneEmpreinte(sha) {
            empreintes[CatalogueRegles.codeNational] = sha
        }
        return empreintes
    }

    private static func estUneEmpreinte(_ texte: String) -> Bool {
        texte.count == 64 && texte.allSatisfy { $0.isASCII && ($0.isNumber || ("a"..."f").contains($0)) }
    }

    /// Contrôle puis substitue. Lève `RaisonRefus` si le fichier n'est pas pris.
    private func accepter(_ data: Data, code: String, attendu: String, copieActuelle: CopieRegles?) throws {
        guard data.count <= Self.tailleMaxFichier else { throw RaisonRefus.illisible }
        guard Sha256.hex(data) == attendu else { throw RaisonRefus.sha256Different }
        let fichier = try FichierReglesLu.lire(data)
        guard fichier.departement == code else { throw RaisonRefus.autreDepartement }
        if let actuelle = copieActuelle, fichier.version <= actuelle.fichier.version { throw RaisonRefus.pasPlusRecent }
        do {
            try depot.ecrire(data, code: code)
        } catch {
            throw RaisonRefus.telechargement
        }
    }
}
