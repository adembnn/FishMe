import Foundation

/// Le dossier des copies téléchargées : un fichier `<code>.json` par département, plus `national.json`.
/// Chaque fichier est écrit en entier puis substitué à l'ancien d'un coup (écriture atomique) : si l'app est
/// tuée en route, l'ancienne copie reste, jamais un fichier à moitié écrit.
public struct DepotRegles: Sendable {
    public let dossier: URL

    public init(dossier: URL) {
        self.dossier = dossier
    }

    func chemin(_ code: String) -> URL { dossier.appendingPathComponent("\(code).json") }

    func lire(_ code: String) -> Data? { try? Data(contentsOf: chemin(code)) }

    func ecrire(_ data: Data, code: String) throws {
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        try data.write(to: chemin(code), options: .atomic)
    }
}

/// Une copie lue et contrôlée, avec l'endroit d'où elle vient.
struct CopieRegles: Sendable {
    enum Origine: Sendable { case embarquee, telechargee }
    var data: Data
    var fichier: FichierRegles
    var origine: Origine
}

/// Vue sur les fichiers de règles présents : ceux embarqués dans l'app et ceux téléchargés par L11.
/// Pour chaque département, la copie valide la plus récente gagne ; une copie illisible est ignorée et la précédente sert.
/// `departementsCouverts()` lit ces fichiers : un département est couvert dès que son fichier existe.
public struct CatalogueRegles: Sendable {
    public static let codeNational = "national"

    private let embarque: URL?
    private let depot: DepotRegles

    /// - Parameters:
    ///   - embarque: le dossier `regles/` embarqué dans l'app (`nil` si aucun, par exemple en essai).
    ///   - copies: le dossier où L11 range les fichiers téléchargés.
    public init(embarque: URL?, copies: URL) {
        self.embarque = embarque
        self.depot = DepotRegles(dossier: copies)
    }

    init(embarque: URL?, depot: DepotRegles) {
        self.embarque = embarque
        self.depot = depot
    }

    /// Un code de département (« 94 », « 2A », « 971 ») : ce qui peut devenir un nom de fichier sans risque.
    static func codeValide(_ code: String) -> Bool {
        if code == "2A" || code == "2B" { return true }
        return (2...3).contains(code.count) && code.allSatisfy { $0.isASCII && $0.isNumber }
    }

    private func fichiersPresents(dans dossier: URL?) -> Set<String> {
        guard let dossier,
              let noms = try? FileManager.default.contentsOfDirectory(atPath: dossier.path) else { return [] }
        var codes = Set<String>()
        for nom in noms where nom.hasSuffix(".json") {
            let code = String(nom.dropLast(5))
            if Self.codeValide(code) || code == Self.codeNational { codes.insert(code) }
        }
        return codes
    }

    private func lireEmbarque(_ code: String) -> Data? {
        guard let embarque else { return nil }
        return try? Data(contentsOf: embarque.appendingPathComponent("\(code).json"))
    }

    /// La meilleure copie valide de ce fichier : la plus récente ; à version égale, l'embarquée.
    func meilleure(_ code: String) -> CopieRegles? {
        var candidates: [CopieRegles] = []
        if let data = lireEmbarque(code), let f = try? FichierRegles.lire(data), f.departement == code {
            candidates.append(CopieRegles(data: data, fichier: f, origine: .embarquee))
        }
        if let data = depot.lire(code), let f = try? FichierRegles.lire(data), f.departement == code {
            candidates.append(CopieRegles(data: data, fichier: f, origine: .telechargee))
        }
        return candidates.max { $0.fichier.version < $1.fichier.version }
    }

    /// Le fichier d'un département tel qu'il sert (octets du JSON), ou `nil` s'il n'a pas de fichier.
    /// C'est ce que lit le moteur de règles (L1) : la copie embarquée ou la dernière copie valide.
    public func contenu(departement code: String) -> Data? { meilleure(code)?.data }

    public func contenuNational() -> Data? { meilleure(Self.codeNational)?.data }

    /// La version du fichier qui sert (« 2026-10-15.1 »), pour le signalement d'une erreur et l'écran Sources.
    public func version(de code: String) -> String? { meilleure(code)?.fichier.version.texte }

    /// Les départements dont un fichier valide est présent, embarqué ou téléchargé, triés par code.
    public func departementsCouverts() -> [DepartementCouvert] {
        let codes = fichiersPresents(dans: embarque).union(fichiersPresents(dans: depot.dossier))
            .filter { $0 != Self.codeNational }
        return codes.sorted().compactMap { code in
            guard let copie = meilleure(code) else { return nil }
            let f = copie.fichier
            return DepartementCouvert(departement: Departement(code: code), niveau: f.niveau,
                                      reglesConfirmees: f.regles.count, lignesAVerifier: f.nombreAVerifier,
                                      dateLecture: f.dernierLu.flatMap(Jours.date(iso:)),
                                      expireMin: f.expireMin.flatMap(Jours.date(iso:)))
        }
    }

    /// La date des règles de chaque département (dernier `lu_le` de ses textes), pour l'écran Sources.
    public func datesDesRegles() -> [String: Date] {
        var dates: [String: Date] = [:]
        for couvert in departementsCouverts() {
            if let date = couvert.dateLecture { dates[couvert.departement.code] = date }
        }
        return dates
    }
}
