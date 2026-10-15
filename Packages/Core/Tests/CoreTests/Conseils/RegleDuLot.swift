import Foundation
@testable import Core

/// Ce que les tests savent des règles nationales et des statuts, en attendant `regles/national.json` et `especes.json` (D1).
/// Copié de `docs/regles/especes-national.json` (15 oct. 2026) ; à remplacer par la lecture des vrais fichiers quand D1 sera fusionné.
enum RegleDuLot {
    static let protegees: Set<String> = ["esturgeon-europeen", "apron-du-rhone", "anguille-argentee", "civelle"]
    static let envahissantes: Set<String> = [
        "perche-soleil", "poisson-chat", "ecrevisse-americaine", "ecrevisse-de-louisiane", "ecrevisse-signal",
        "ecrevisse-virile", "ecrevisse-marbree", "ecrevisse-a-taches-rouges", "grenouille-taureau",
    ]

    static func statuts(_ espece: String) -> Set<StatutEspece> {
        if protegees.contains(espece) { return [.protegee] }
        if envahissantes.contains(espece) { return [.envahissante] }
        return []
    }

    /// Lecture prudente : un mois est « fermé » dès qu'un seul de ses jours l'est.
    /// 1re catégorie : du 2e samedi de mars au 3e dimanche de septembre (brochet : dernier samedi d'avril ; ombre : 3e samedi de mai).
    /// 2e catégorie : ouvert toute l'année, sauf le brochet (fermé du dernier dimanche de janvier au dernier samedi d'avril),
    /// l'ombre (ouvert du 3e samedi de mai au 31 décembre) et la truite fario (comme la 1re catégorie).
    static func moisFermes(espece: String, categorie: Categorie) -> Set<Int> {
        let premiere: Set<Int> = [1, 2, 3, 9, 10, 11, 12]
        switch (espece, categorie) {
        case ("brochet", .premiere): return [1, 2, 3, 4, 9, 10, 11, 12]
        case ("brochet", .deuxieme): return [1, 2, 3, 4]
        case ("ombre-commun", .premiere): return [1, 2, 3, 4, 5, 9, 10, 11, 12]
        case ("ombre-commun", .deuxieme): return [1, 2, 3, 4, 5]
        case ("truite-fario", _): return premiere
        case (_, .premiere): return premiere
        default: return []
        }
    }

    /// Pendant la fermeture du brochet en 2e catégorie, le vif, le poisson mort ou artificiel et les leurres sont interdits
    /// (arrêtés 75 et 94 ; la FNPF le présente comme national, non lu dans le Code [?]) : mois 1 à 4, lecture prudente.
    static let modesFermesAvecLeBrochet: Set<ModeConseil> = [.vif, .poissonMort, .leurre]
    static let moisFermetureBrochet: Set<Int> = [1, 2, 3, 4]

    /// Erreurs d'un conseil contre ces règles ; vide pour une espèce protégée (« relâche-la » vaut toute l'année).
    static func erreurs(_ c: ConseilFiche) -> [String] {
        guard !protegees.contains(c.espece) else { return [] }
        var e: [String] = []
        let cats: [Categorie] = switch c.categorie {
        case .premiere: [.premiere]
        case .deuxieme: [.deuxieme]
        case .toutes: [.premiere, .deuxieme]
        }
        for cat in cats {
            let touches = Set(c.mois).intersection(moisFermes(espece: c.espece, categorie: cat))
            if !touches.isEmpty { e.append("mois \(touches.sorted()) dans une fermeture nationale (catégorie \(cat))") }
        }
        if c.categorie != .premiere, !Set(c.modes).isDisjoint(with: modesFermesAvecLeBrochet),
           !Set(c.mois).isDisjoint(with: moisFermetureBrochet) {
            e.append("mode interdit pendant la fermeture du brochet (mois 1 à 4)")
        }
        return e
    }
}
