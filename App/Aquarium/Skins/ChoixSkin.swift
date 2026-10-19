import Core
import SwiftUI

/// Le choix du pêcheur, gardé dans les réglages de l'iPhone (`@AppStorage("aquarium.skin")`, la valeur est un
/// `IdentifiantSkin` écrit en chaîne). Pas de réseau, pas de compte. Au rendu, la valeur est corrigée par `appliquable`.
enum ChoixSkin {
    static let cle = "aquarium.skin"
    /// Le dernier décor gagné appliqué : c'est vers lui qu'on revient si le Pro prend fin.
    static let cleDernierGagne = "aquarium.skin.dernierGagne"
    static let valeurParDefaut = IdentifiantSkin.parDefaut.valeur

    /// Une chaîne vide ou inconnue donne le décor de départ.
    static func identifiant(brut: String) -> IdentifiantSkin {
        brut.isEmpty ? .parDefaut : IdentifiantSkin(brut)
    }

    /// Un `Binding<IdentifiantSkin>` posé sur un `@AppStorage` de chaîne :
    /// `ChoixSkin.binding($skinBrut)` avec `@AppStorage(ChoixSkin.cle) private var skinBrut = ChoixSkin.valeurParDefaut`.
    static func binding(_ brut: Binding<String>) -> Binding<IdentifiantSkin> {
        Binding(get: { identifiant(brut: brut.wrappedValue) },
                set: { brut.wrappedValue = $0.valeur })
    }

    /// L'identifiant à dessiner (aquarium) et à publier (widget) : le choix enregistré, corrigé par la règle.
    static func affiche(brut: String, contexte: ContexteSkin, defaults: UserDefaults = .standard) -> IdentifiantSkin {
        let memoire = defaults.string(forKey: cleDernierGagne).flatMap { $0.isEmpty ? nil : IdentifiantSkin($0) }
        return appliquable(identifiant(brut: brut), choisiActuel: memoire, dans: contexte)
    }
}

/// « Appliquer » : la seule façon de changer le choix. Partagée par la galerie et l'aperçu.
enum ApplicationSkin {
    /// - Disponible : écrit le choix, retient le décor gagné, appelle `auChangement` une fois.
    /// - Aperçu seulement (Pro requis) : appelle `demanderPro`, le choix ne change pas.
    /// - Autre (hors saison, à gagner) : rien.
    /// Rend vrai si le choix a changé.
    @discardableResult
    static func appliquer(_ skin: Skin, contexte: ContexteSkin, choisi: Binding<IdentifiantSkin>,
                          demanderPro: () -> Void, auChangement: (IdentifiantSkin) -> Void,
                          defaults: UserDefaults = .standard) -> Bool {
        switch statut(skin, dans: contexte) {
        case .disponible:
            choisi.wrappedValue = skin.id
            if case .gagne = skin.origine { defaults.set(skin.id.valeur, forKey: ChoixSkin.cleDernierGagne) }
            auChangement(skin.id)
            return true
        case .apercuSeulement:
            demanderPro()
            return false
        case .horsSaison, .aGagner:
            return false
        }
    }
}
