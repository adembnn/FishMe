import Foundation
import Core
#if canImport(Security)
import Security
#endif

/// Une session commencée et pas finie. Aucune coordonnée exacte : la fin légale est calculée au départ et gardée.
struct SessionEnCours: Codable, Equatable {
    var sortie: Sortie
    var finLegale: Date?
    var departement: Departement
    /// « pêche fermée à cette heure », « hors de France : aucune règle française ».
    var messages: [String] = []
}

/// Tout ce que L5 garde dans son fichier (pas SwiftData : ses modèles sont à L4). Sorties terminées sans coordonnée exacte.
struct FichierSession: Codable, Equatable {
    var enCours: SessionEnCours?
    var terminees: [Sortie] = []
    var sessionsTerminees: Int = 0
    /// Prises gardées d'une session à l'autre ; le compte du jour filtre sur la date.
    var prisesGardees: [Prise] = []
}

protocol StockageSession: Sendable {
    func charger() -> FichierSession
    func ecrire(_ fichier: FichierSession)
}

/// Fichier JSON dans Application Support, protégé tant que l'iPhone n'a pas été déverrouillé une fois.
struct StockageFichier: StockageSession {
    let url: URL

    init(url: URL? = nil) {
        if let url {
            self.url = url
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.url = base.appendingPathComponent("Session", isDirectory: true).appendingPathComponent("session.json")
        }
    }

    func charger() -> FichierSession {
        guard let donnees = try? Data(contentsOf: url) else { return FichierSession() }
        let decodeur = JSONDecoder()
        decodeur.dateDecodingStrategy = .iso8601
        return (try? decodeur.decode(FichierSession.self, from: donnees)) ?? FichierSession()
    }

    func ecrire(_ fichier: FichierSession) {
        let encodeur = JSONEncoder()
        encodeur.dateEncodingStrategy = .iso8601
        guard let donnees = try? encodeur.encode(fichier) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? donnees.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}

/// Le spot gratuit survit à une réinstallation : il va dans le trousseau d'iOS.
protocol CoffreSpotGratuit: Sendable {
    func lire() -> Spot?
    func ecrire(_ spot: Spot)
}

#if canImport(Security)
struct TrousseauSpotGratuit: CoffreSpotGratuit {
    private let service = "fr.fishme.session"
    private let compte = "spot-gratuit"

    private var requete: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: compte]
    }

    func lire() -> Spot? {
        var q = requete
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var resultat: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &resultat) == errSecSuccess, let donnees = resultat as? Data else { return nil }
        return try? JSONDecoder().decode(Spot.self, from: donnees)
    }

    func ecrire(_ spot: Spot) {
        guard let donnees = try? JSONEncoder().encode(spot) else { return }
        SecItemDelete(requete as CFDictionary)
        var q = requete
        q[kSecValueData as String] = donnees
        // Ce iPhone seulement, jamais synchronisé avec iCloud : le coin ne quitte pas l'appareil.
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        q[kSecAttrSynchronizable as String] = false
        SecItemAdd(q as CFDictionary, nil)
    }
}
#endif

#if DEBUG
final class StockageMemoire: StockageSession, @unchecked Sendable {
    private let verrou = NSLock()
    private var fichier = FichierSession()
    func charger() -> FichierSession { verrou.lock(); defer { verrou.unlock() }; return fichier }
    func ecrire(_ f: FichierSession) { verrou.lock(); defer { verrou.unlock() }; fichier = f }
}

final class CoffreMemoire: CoffreSpotGratuit, @unchecked Sendable {
    private let verrou = NSLock()
    private var spot: Spot?
    init(_ spot: Spot? = nil) { self.spot = spot }
    func lire() -> Spot? { verrou.lock(); defer { verrou.unlock() }; return spot }
    func ecrire(_ s: Spot) { verrou.lock(); defer { verrou.unlock() }; spot = s }
}
#endif
