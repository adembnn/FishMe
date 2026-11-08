import Foundation

/// La langue des noms d'espèces et des textes de l'app : choix du pêcheur, indépendant de la région (règles, unités).
public enum LangueNomsCode: String, Sendable, CaseIterable {
    case fr, en
}

/// La langue courante des noms d'espèces, posée par l'app (réglage mémorisé) et lue par `EspecePechable.nom`.
/// Français tant que l'app n'a rien posé (tests, Linux).
public enum LangueNoms {
    private static let verrou = NSLock()
    nonisolated(unsafe) private static var valeur: LangueNomsCode = .fr

    public static var courante: LangueNomsCode {
        get { verrou.lock(); defer { verrou.unlock() }; return valeur }
        set { verrou.lock(); valeur = newValue; verrou.unlock() }
    }
}

/// Les noms d'usage des espèces, dans les deux langues (`Resources/noms-especes.json`, relu à la main).
/// Clés : identifiants du catalogue français (« brochet ») et slugs américains (« walleye »).
/// En anglais, tous les noms sont anglais, y compris les espèces françaises ; en français, une espèce américaine a un nom
/// français d'usage quand il existe, sinon le nom anglais reste.
public enum NomsEspeces {
    private struct Tables: Sendable { let fr: [String: String]; let en: [String: String] }

    private static let tables: Tables = {
        guard let url = Bundle.module.url(forResource: "noms-especes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONDecoder().decode([String: [String: String]].self, from: data) else {
            return Tables(fr: [:], en: [:])
        }
        return Tables(fr: json["fr"] ?? [:], en: json["en"] ?? [:])
    }()

    /// Le nom de l'espèce `id` dans `langue` ; `defaut` si la table n'a pas d'entrée.
    public static func nom(id: String, langue: LangueNomsCode, defaut: String) -> String {
        switch langue {
        case .fr: tables.fr[id] ?? defaut
        case .en: tables.en[id] ?? defaut
        }
    }

    /// Nombre d'entrées par langue (tests).
    public static var comptes: (fr: Int, en: Int) { (tables.fr.count, tables.en.count) }
}
