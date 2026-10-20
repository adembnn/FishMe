import Foundation

/// Où la liste est gardée. L'app donne l'implémentation ; les tests en donnent une en mémoire.
public protocol StockageEnvies: Sendable {
    func lire() -> ListeEnvies
    func ecrire(_ liste: ListeEnvies)
}

/// Un fichier JSON sur l'iPhone (dans `Application Support`, l'URL vient de l'app). Écriture atomique.
/// Fichier absent, vide ou illisible : liste vide, jamais de plantage. Aucune coordonnée n'y figure.
public struct StockageEnviesFichier: StockageEnvies {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func lire() -> ListeEnvies {
        guard let data = try? Data(contentsOf: url), !data.isEmpty else { return ListeEnvies() }
        let decodeur = JSONDecoder()
        decodeur.dateDecodingStrategy = .iso8601
        return (try? decodeur.decode(ListeEnvies.self, from: data)) ?? ListeEnvies()
    }

    public func ecrire(_ liste: ListeEnvies) {
        let encodeur = JSONEncoder()
        encodeur.dateEncodingStrategy = .iso8601
        encodeur.outputFormatting = [.sortedKeys]
        guard let data = try? encodeur.encode(liste) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
