import Foundation

// Le nom de l'image de fond du widget selon le décor (N1). Foundation seulement : compile aussi sous Linux (tests).
// Le widget ne peut pas importer App/ ni Core : la règle de nommage de `Skin.nomImageFond` est répétée ici
// (`fond-<skin>-<petit|moyen|grand>`, repli `fond-<format>`). Le test `FondWidgetTests` la garde alignée.
// Aucune date, aucun abonnement : l'app donne un identifiant déjà corrigé.
// Les décors sont aussi DESSINÉS en code (`DecorsDessines.swift`, partagé entre l'app et le widget). La règle de choix
// du fond est ici, sans SwiftUI, pour être testée sous Linux : illustration du décor si elle existe, sinon le dessin,
// sinon le fond d'origine (même ordre que `sourceFond` dans Core, que l'app utilise).

nonisolated public enum FondWidget {
    nonisolated public enum Format: String, Sendable, CaseIterable {
        case petit, moyen, grand
    }

    /// Décor de départ : son fond est le fond d'origine `fond-<format>`.
    public static let parDefaut = "riviere"

    /// Un identifiant absent, vide ou douteux (espaces, `/`, majuscules) donne le décor de départ :
    /// jamais un nom d'image construit à partir de n'importe quoi.
    public static func identifiantSain(_ brut: String?) -> String {
        guard let brut, !brut.isEmpty, brut.count <= 40,
              brut.allSatisfy({ $0.isASCII && ($0.isLowercase || $0.isNumber || $0 == "-") })
        else { return parDefaut }
        return brut
    }

    /// Le fond d'origine.
    public static func nomRepli(_ format: Format) -> String { "fond-\(format.rawValue)" }

    /// Le nom voulu pour ce décor (sans vérifier qu'il existe).
    public static func nomVoulu(skin: String?, format: Format) -> String {
        let id = identifiantSain(skin)
        return id == parDefaut ? nomRepli(format) : "fond-\(id)-\(format.rawValue)"
    }

    /// Le nom à dessiner : celui du décor s'il existe dans les ressources du widget (`existe`), sinon le fond d'origine.
    public static func nomImage(skin: String?, format: Format, existe: (String) -> Bool) -> String {
        let voulu = nomVoulu(skin: skin, format: format)
        return existe(voulu) ? voulu : nomRepli(format)
    }

    // MARK: Décors dessinés en code

    /// Les décors qui ont un dessin (`DecorsDessines*.swift`) : les sept décors du catalogue hors le décor de départ.
    /// Un décor ajouté ici doit aussi avoir sa charge dans `BudgetDecor.charge` (le test de budget le vérifie).
    public static let decorsDessines: Set<String> = ["sous-bois", "etang", "grotte", "halloween", "noel", "ouverture-truite", "ete"]

    /// Vrai si ce décor a un dessin. Le décor de départ n'en a pas : son fond est le fond d'origine.
    public static func aUnDessin(_ skin: String?) -> Bool {
        let id = identifiantSain(skin)
        return id != parDefaut && decorsDessines.contains(id)
    }

    /// D'où vient le fond : l'illustration du décor, son dessin posé sur le fond d'origine, ou le fond d'origine seul.
    public enum Source: Equatable, Sendable {
        case image(String)
        case dessin(String)
        case repli(String)
    }

    /// La règle du fond. `existe` dit si l'illustration `fond-<skin>-<format>` est dans les ressources.
    public static func source(skin: String?, format: Format, existe: (String) -> Bool) -> Source {
        let id = identifiantSain(skin)
        guard id != parDefaut else { return .repli(nomRepli(format)) }
        let voulu = nomVoulu(skin: id, format: format)
        if existe(voulu) { return .image(voulu) }
        if decorsDessines.contains(id) { return .dessin(id) }
        return .repli(nomRepli(format))
    }
}
