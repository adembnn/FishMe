import Core

/// Les 8 familles de la grille « autre espèce » (fiche L3). `especes.json` n'a pas de champ famille :
/// le classement se fait ici sur l'identifiant. A demander à D1 : un champ `famille` dans `especes.json`, qui remplacerait ce fichier.
nonisolated enum PriseFamille: Int, CaseIterable, Sendable {
    case salmonides, carnassiers, carpes, cyprinides, petitsDeFond, migrateurs, ecrevisses, grenouilles

    var titre: String {
        switch self {
        case .salmonides: return "Salmonidés"
        case .carnassiers: return "Carnassiers"
        case .carpes: return "Carpes"
        case .cyprinides: return "Cyprinidés"
        case .petitsDeFond: return "Petits poissons de fond"
        case .migrateurs: return "Migrateurs et estuaire"
        case .ecrevisses: return "Écrevisses et crabe"
        case .grenouilles: return "Grenouilles"
        }
    }

    /// Symbole de la silhouette de repli quand une illustration manque.
    var symbole: String {
        switch self {
        case .ecrevisses: return "ant"
        case .grenouilles: return "hare"
        default: return "fish"
        }
    }

    static func de(_ id: String) -> PriseFamille {
        if id.hasPrefix("ecrevisse") || id == "crabe-chinois" { return .ecrevisses }
        if id.hasPrefix("grenouille") || id == "hybrides" { return .grenouilles }
        if id.hasPrefix("truite") || id.hasPrefix("saumon") || id.hasPrefix("omble") || ["cristivomer", "ombre-commun", "huchon", "coregones"].contains(id) { return .salmonides }
        if id.hasPrefix("carpe") || id.hasPrefix("carassin") { return .carpes }
        if ["brochet", "sandre", "perche-commune", "gremille", "black-bass", "perche-soleil", "silure-glane", "lotte", "poisson-chat"].contains(id) { return .carnassiers }
        if id.hasPrefix("anguille") || id == "civelle" || id.hasPrefix("lamproie") || id.hasPrefix("esturgeon") || id.hasSuffix("alose") || id.hasPrefix("alose") || ["flet", "mulet", "apron-du-rhone"].contains(id) || id.contains("alose") { return .migrateurs }
        if id.hasPrefix("loche") || ["chabot", "epinoche", "vairon", "gambusie", "goujon", "goujon-de-l-amour", "spirlin", "pseudorasbora"].contains(id) { return .petitsDeFond }
        return .cyprinides
    }
}
