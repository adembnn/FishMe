import Foundation
import Observation

/// Le lien `fishme://club/<id>` : il ouvre la feuille « Rejoindre » d'un club. `<id>` est l'UUID du club.
/// Même forme que `LienAmi` (L21). Ce lien n'est pas un secret : quiconque le connaît lit le nom et l'image du club (R2, `schema.md`).
nonisolated enum LienClub {
    static let schema = "fishme"
    static let hote = "club"

    static func url(clubID: String) -> URL? {
        guard let uuid = UUID(uuidString: clubID) else { return nil }
        return URL(string: "\(schema)://\(hote)/\(uuid.uuidString)")
    }

    /// L'identifiant lu dans un lien, ou `nil` si ce n'est pas un lien de club valide (autre hôte, identifiant qui n'est pas un UUID).
    static func clubID(depuis url: URL) -> String? {
        guard url.scheme?.lowercased() == schema, url.host()?.lowercased() == hote,
              let dernier = url.pathComponents.last, dernier != "/",
              let uuid = UUID(uuidString: dernier) else { return nil }
        return uuid.uuidString
    }

    /// Pour « coller un lien » : le texte collé peut avoir des espaces ou un retour à la ligne autour.
    static func clubID(depuis texte: String) -> String? {
        let propre = texte.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: propre) else { return nil }
        return clubID(depuis: url)
    }
}

/// Garde le lien de club reçu, le temps que la page Club montre la feuille « Rejoindre » (comme `RelaisLienAmi`).
/// A l'appelle dans `ouvrir(url:)` de `RootView.swift` : `RelaisLienClub.partage.recevoir(url)` pour l'hôte `club`, puis ouvre
/// l'onglet Communauté, page Club.
@MainActor
@Observable
final class RelaisLienClub {
    static let partage = RelaisLienClub()

    private(set) var enAttente: String?

    /// Vrai si le lien était un lien de club valide (A peut alors ouvrir Communauté).
    @discardableResult
    func recevoir(_ url: URL) -> Bool {
        guard let id = LienClub.clubID(depuis: url) else { return false }
        enAttente = id
        return true
    }

    func solder() { enAttente = nil }
}
