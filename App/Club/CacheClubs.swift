import Foundation

/// Le dernier état lu des clubs, gardé sur l'iPhone : mode avion, la page montre ce qu'elle a lu la dernière fois (fiche L22, test 5).
/// Un simple fichier JSON dans Application Support (pas de SwiftData : le reste de l'app garde SwiftData pour ses données locales).
nonisolated struct EtatCacheClubs: Codable, Sendable, Equatable {
    /// Le surnom et l'avatar d'un membre, tels que L21 les donne.
    nonisolated struct ProfilCache: Codable, Sendable, Equatable {
        var id: String
        var surnom: String
        var avatar: Data?
    }

    var clubs: [Club] = []
    var membres: [String: [Membre]] = [:]
    var cartes: [String: [CartePartageeClub]] = [:]
    var profils: [String: ProfilCache] = [:]
    var enregistreLe: Date = Date(timeIntervalSince1970: 0)
    /// Profil -> compte iCloud vérifié (voir `GestionClubs.resoudreIdentites`). Optionnel : un fichier plus ancien se relit.
    var identites: [String: String]? = nil

    /// Au plus ce nombre de cartes par club dans le fichier : les images pèsent (PNG de carte).
    static let cartesParClub = 40

    func reduit() -> EtatCacheClubs {
        var copie = self
        for (club, liste) in cartes where liste.count > Self.cartesParClub {
            copie.cartes[club] = Array(liste.prefix(Self.cartesParClub))
        }
        return copie
    }
}

nonisolated protocol CacheClubs: Sendable {
    func lire() -> EtatCacheClubs?
    func ecrire(_ etat: EtatCacheClubs)
    func effacer()
}

/// Le vrai fichier : `clubs-en-ligne.json` dans Application Support.
nonisolated struct CacheClubsFichier: CacheClubs {
    var nomFichier: String = "clubs-en-ligne.json"

    private var url: URL? {
        guard let dossier = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                         appropriateFor: nil, create: true) else { return nil }
        return dossier.appendingPathComponent(nomFichier)
    }

    func lire() -> EtatCacheClubs? {
        guard let url, let donnees = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(EtatCacheClubs.self, from: donnees)
    }

    func ecrire(_ etat: EtatCacheClubs) {
        guard let url, let donnees = try? JSONEncoder().encode(etat.reduit()) else { return }
        try? donnees.write(to: url, options: .atomic)
    }

    func effacer() {
        if let url { try? FileManager.default.removeItem(at: url) }
    }
}

#if DEBUG
/// Cache en mémoire pour les tests.
nonisolated final class CacheClubsMemoire: CacheClubs, @unchecked Sendable {
    private let verrou = NSLock()
    private var etat: EtatCacheClubs?

    init(_ etat: EtatCacheClubs? = nil) { self.etat = etat }

    func lire() -> EtatCacheClubs? { verrou.lock(); defer { verrou.unlock() }; return etat }
    func ecrire(_ etat: EtatCacheClubs) { verrou.lock(); defer { verrou.unlock() }; self.etat = etat.reduit() }
    func effacer() { verrou.lock(); defer { verrou.unlock() }; etat = nil }
}
#endif
