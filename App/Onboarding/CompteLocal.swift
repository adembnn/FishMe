import Foundation
import Security

/// Le compte FishMe d'avant iCloud : un surnom de pêcheur et, si le pêcheur le veut, un e-mail. Tout reste sur l'iPhone
/// (surnom dans les réglages, e-mail dans le trousseau, ce iPhone seulement). Rien n'est envoyé sans consentement explicite.
nonisolated enum CompteLocal {
    static let cleSurnom = "profil.surnomLocal"
    static let cleConsentement = "compte.emailConsenti"
    static let cleOnboardingFait = "onboarding.compteFait"

    static func surnom(_ defauts: UserDefaults = .standard) -> String? {
        defauts.string(forKey: cleSurnom).flatMap { $0.isEmpty ? nil : $0 }
    }

    static func emailConsenti(_ defauts: UserDefaults = .standard) -> Bool { defauts.bool(forKey: cleConsentement) }
}

/// Validation locale d'une adresse e-mail : une seule arobase, un nom, un domaine avec un point, ni espace ni retour.
nonisolated enum AdresseEmail {
    static func estValide(_ brut: String) -> Bool {
        let texte = brut.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texte.isEmpty, texte.count <= 254, !texte.contains(where: { $0.isWhitespace || $0.isNewline }) else { return false }
        let morceaux = texte.split(separator: "@", omittingEmptySubsequences: false)
        guard morceaux.count == 2, !morceaux[0].isEmpty, morceaux[0].count <= 64 else { return false }
        let domaine = morceaux[1]
        guard domaine.contains("."), !domaine.hasPrefix("."), !domaine.hasSuffix("."), !domaine.contains("..") else { return false }
        return true
    }

    static func nettoyer(_ brut: String) -> String { brut.trimmingCharacters(in: .whitespacesAndNewlines) }
}

/// Où l'e-mail du pêcheur est gardé sur l'iPhone.
nonisolated protocol StockageEmail: Sendable {
    func lire() -> String?
    func ecrire(_ email: String)
    func effacer()
}

/// Le trousseau : ce iPhone seulement, jamais synchronisé avec iCloud.
nonisolated struct StockageEmailTrousseau: StockageEmail {
    var service = "fishme.compte"
    var compte = "email"

    private var requete: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: compte]
    }

    func lire() -> String? {
        var q = requete
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var resultat: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &resultat) == errSecSuccess, let donnees = resultat as? Data else { return nil }
        return String(data: donnees, encoding: .utf8)
    }

    func ecrire(_ email: String) {
        effacer()
        var q = requete
        q[kSecValueData as String] = Data(email.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        q[kSecAttrSynchronizable as String] = false
        SecItemAdd(q as CFDictionary, nil)
    }

    func effacer() { SecItemDelete(requete as CFDictionary) }
}

/// Pour les tests : en mémoire.
nonisolated final class StockageEmailMemoire: StockageEmail, @unchecked Sendable {
    private let verrou = NSLock()
    private var valeur: String?
    init(_ valeur: String? = nil) { self.valeur = valeur }
    func lire() -> String? { verrou.lock(); defer { verrou.unlock() }; return valeur }
    func ecrire(_ email: String) { verrou.lock(); valeur = email; verrou.unlock() }
    func effacer() { verrou.lock(); valeur = nil; verrou.unlock() }
}
