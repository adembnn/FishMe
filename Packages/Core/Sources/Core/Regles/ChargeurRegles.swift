import Foundation

/// D'où viennent les fichiers de règles : le paquet (embarqué), un dossier téléchargé par L11, ou la mémoire (tests).
public protocol SourceFichiersRegles: Sendable {
    /// Contenu brut de `regles/<nom>.json` (`nom` : `index`, `national` ou un code de département).
    func contenu(nom: String) -> Data?
    /// Les codes de département dont le fichier est présent (ni `index` ni `national`).
    func codesDepartements() -> [String]
}

/// Un dossier du disque (le dossier embarqué `Resources/regles/`, ou la copie téléchargée par L11).
public struct SourceDossier: SourceFichiersRegles {
    public let dossier: URL?

    public init(dossier: URL?) { self.dossier = dossier }

    public func contenu(nom: String) -> Data? {
        guard let dossier else { return nil }
        return try? Data(contentsOf: dossier.appendingPathComponent("\(nom).json"))
    }

    public func codesDepartements() -> [String] {
        guard let dossier, let noms = try? FileManager.default.contentsOfDirectory(atPath: dossier.path) else { return [] }
        return noms.filter { $0.hasSuffix(".json") }
            .map { String($0.dropLast(5)) }
            .filter { $0 != "index" && $0 != "national" }
            .sorted()
    }
}

/// Des fichiers tenus en mémoire (jeux d'essai des tests).
public struct SourceMemoire: SourceFichiersRegles {
    public let fichiers: [String: Data]

    public init(fichiers: [String: Data]) { self.fichiers = fichiers }

    public init(textes: [String: String]) {
        self.fichiers = textes.mapValues { Data($0.utf8) }
    }

    public func contenu(nom: String) -> Data? { fichiers[nom] }

    public func codesDepartements() -> [String] {
        fichiers.keys.filter { $0 != "index" && $0 != "national" }.sorted()
    }
}

/// Lit les fichiers de règles à la demande : `index.json`, puis `national.json` et le ou les départements du lieu seulement.
/// Plusieurs sources : la copie valide la plus récente (champ `version`) gagne ; à égalité, la première source de la liste.
public final class ChargeurRegles: @unchecked Sendable {
    private let sources: [any SourceFichiersRegles]
    private let verrou = NSLock()
    private var cache: [String: FichierRegles?] = [:]

    /// `sources` : mettre d'abord la copie téléchargée (L11), puis la copie embarquée.
    public init(sources: [any SourceFichiersRegles]) {
        self.sources = sources
    }

    /// Les règles embarquées dans le paquet.
    public static func embarque(telechargees: URL? = nil) -> ChargeurRegles {
        var s: [any SourceFichiersRegles] = []
        if let telechargees { s.append(SourceDossier(dossier: telechargees)) }
        s.append(SourceDossier(dossier: Ressources.dossierRegles))
        return ChargeurRegles(sources: s)
    }

    func fichier(_ nom: String) -> FichierRegles? {
        verrou.lock()
        if let dejaLu = cache[nom] { verrou.unlock(); return dejaLu }
        verrou.unlock()
        var meilleur: FichierRegles?
        for source in sources {
            guard let donnees = source.contenu(nom: nom),
                  let f = try? JSONDecoder().decode(FichierRegles.self, from: donnees) else { continue }
            if let m = meilleur, m.version >= f.version { continue }
            meilleur = f
        }
        verrou.lock()
        cache[nom] = .some(meilleur)
        verrou.unlock()
        return meilleur
    }

    func index() -> IndexRegles? {
        for source in sources {
            if let d = source.contenu(nom: "index"), let i = IndexRegles.decoder(d) { return i }
        }
        return nil
    }

    /// Codes présents dans l'une des sources, triés.
    func codesPresents() -> [String] {
        Set(sources.flatMap { $0.codesDepartements() }).sorted()
    }

    /// Charge les fichiers d'un lieu hors du fil principal, pour que `controle` ne lise plus le disque ensuite.
    public func precharger(departements codes: [String]) async {
        await Task.detached(priority: .userInitiated) { [self] in
            _ = fichier("national")
            for code in codes { _ = fichier(code) }
        }.value
    }
}
