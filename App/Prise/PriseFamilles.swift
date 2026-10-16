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
        if id.hasPrefix("grenouille") { return .grenouilles }
        if id.hasPrefix("truite") || id.hasPrefix("saumon") || id.hasPrefix("omble") || ["cristivomer", "ombre-commun", "huchon", "coregones"].contains(id) { return .salmonides }
        if id.hasPrefix("carpe") || id.hasPrefix("carassin") || id == "poisson-rouge" { return .carpes }
        if id.hasPrefix("brochet") || id.hasPrefix("black-bass") || ["sandre", "perche-commune", "gremille", "perche-soleil", "crapet-de-roche", "silure-glane", "lotte", "poisson-chat", "barbue-de-riviere"].contains(id) { return .carnassiers }
        if id.hasPrefix("anguille") || id == "civelle" || id.hasPrefix("lamproie") || id.hasPrefix("esturgeon") || id.contains("alose") || ["sterlet", "flet", "mulet", "bar", "raye-hybride", "apron-du-rhone"].contains(id) { return .migrateurs }
        if id.hasPrefix("loche") || id.hasPrefix("gobie") || id.hasPrefix("epinoche") || ["chabot", "vairon", "gambusie", "goujon", "goujon-de-l-amour", "spirlin", "pseudorasbora"].contains(id) { return .petitsDeFond }
        return .cyprinides
    }
}
