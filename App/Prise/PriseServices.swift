import Core
import Foundation

/// Les contrats de Core dont l'écran a besoin. A les passe à la création de l'écran (aucun import d'un autre dossier de l'app).
struct PriseServices {
    var especes: any ServiceEspeces
    var regles: any ServiceRegles
    var identification: any IdentifieEspece

    #if DEBUG
    /// Les faux de C0, pour le simulateur et les tests. Le vrai `Core` (L1) les remplace sans toucher l'écran.
    static let faux = PriseServices(especes: EspecesFaux(), regles: ReglesFaux(), identification: IdentifieEspeceFaux())
    #endif
}

/// Où et quand : donné par la session (L5) via A.
nonisolated struct PriseContexte: Sendable {
    var coordonnee: Coordonnee
    var lieu: Lieu
    var lieuFlou: String?
    var date: Date
    /// Les prises de la sortie du jour (pour le quota).
    var prisesDuJour: [Prise]
}

/// Ce que l'écran rend quand le pêcheur termine : la prise (sans chemin de photo) et la photo entière, que L4 range.
nonisolated struct PriseConfirmee: Sendable {
    var prise: Prise
    var photo: Data
}

/// Reconnaissance de la version soumise tant que R1 n'a pas remis de modèle examiné : aucun score, la grille s'ouvre.
nonisolated struct IdentificationAbsente: IdentifieEspece {
    func identifier(photo: Data) async -> ResultatIdentification { .grille(raison: .aucunModele) }
}
