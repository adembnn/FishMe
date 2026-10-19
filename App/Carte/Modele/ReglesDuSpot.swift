import Foundation
import Core

/// Le bouton « Règles du spot » de « Mon spot » : les règles du lieu, groupées par le bloc de règles de L19 (`BlocReglesView`,
/// qui ne prend que des types de `Core`). Ici seulement la préparation des lignes, pure et testable.
nonisolated enum ReglesDuSpot {
    /// Une règle de lieu n'est pas un verdict sur une prise : sans poisson en main, rien n'est « non respecté ».
    /// Les lignes « non respectée » de `reglesDuJour` (une période fermée pour telle espèce, par exemple) passent en « information »,
    /// pour que le bloc n'ouvre pas sur « Il faut relâcher le poisson » à propos d'un lieu. Phrases, sources et types ne changent pas.
    static func lignesDuLieu(_ lignes: [LigneControle]) -> [LigneControle] {
        lignes.map { ligne in
            guard ligne.etat == .nonRespectee else { return ligne }
            var neutre = ligne
            neutre.etat = .information
            return neutre
        }
    }

    /// La consigne passée au bloc pour un lieu : jamais « relâche-la » ; « Vérifie l'arrêté » ne s'affiche que si une ligne est à vérifier.
    static let consigne: Consigne = .verifieLArrete
}
