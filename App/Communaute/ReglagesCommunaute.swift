import Foundation

/// Les deux interrupteurs de l'onglet Communauté (décision n° 6 du 7 nov. : le réseau n'est pas lancé en v1).
/// - `afficherOnglet` : une seule constante pour masquer l'onglet entier. Mettre `false` et il disparaît de la barre.
/// - `reseauParDefaut` : `false` en v1, l'onglet montre l'écran « bientôt ». Le code du réseau (fil, amis, clubs, chat)
///   reste intact : pour la v2, passer cette constante à `true`.
/// En DEBUG seulement, on peut rallumer le réseau sans recompiler : argument de lancement `-communaute.reseau YES`
/// (clé `communaute.reseau`). En Release, cette clé est ignorée : seule la constante compte.
nonisolated enum ReglagesCommunaute {
    /// Faux : l'onglet « Communauté » n'est pas dans la barre d'onglets.
    static let afficherOnglet = true
    /// Faux en v1 : le fil, les amis, les clubs et le chat restent éteints.
    static let reseauParDefaut = false
    /// Clé de l'interrupteur DEBUG.
    static let cleDebug = "communaute.reseau"

    /// Vrai si le réseau (fil, amis, clubs, chat) est actif. La clé `communaute.reseau` de `defaults` ne compte qu'en DEBUG.
    static func reseauActif(defaults: UserDefaults = .standard, debug: Bool = ReglagesCommunaute.estDebug) -> Bool {
        guard afficherOnglet else { return false }
        if debug, defaults.object(forKey: cleDebug) != nil { return defaults.bool(forKey: cleDebug) }
        return reseauParDefaut
    }

    #if DEBUG
    static let estDebug = true
    #else
    static let estDebug = false
    #endif
}
