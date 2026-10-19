import Foundation

public enum ErreurCodecReperes: Error, Equatable, Sendable {
    /// Fichier tronqué ou qui n'est pas du JSON de repères : jamais traité comme « aucun repère ».
    case illisible
    /// Fichier écrit par une version plus récente de l'app : à ne pas écraser.
    case versionFuture(Int)
}

/// Le fichier `reperes.json` : JSON stable (clés triées, dates ISO 8601 à la seconde).
public enum CodecReperes {
    public static let versionCourante = 1

    private struct Entete: Decodable { var version: Int }

    private struct Fichier: Codable {
        var version: Int
        var reperes: [Repere]
    }

    public static func encoder(_ reperes: [Repere]) -> Data {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys, .prettyPrinted]
        e.dateEncodingStrategy = .iso8601
        // Encoder des types simples ne peut pas échouer ; un échec rendrait un fichier vide, que `decoder` refuse.
        return (try? e.encode(Fichier(version: versionCourante, reperes: reperes))) ?? Data()
    }

    public static func decoder(_ donnees: Data) throws -> [Repere] {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        guard let entete = try? d.decode(Entete.self, from: donnees) else { throw ErreurCodecReperes.illisible }
        if entete.version > versionCourante { throw ErreurCodecReperes.versionFuture(entete.version) }
        guard let fichier = try? d.decode(Fichier.self, from: donnees) else { throw ErreurCodecReperes.illisible }
        return fichier.reperes
    }
}
