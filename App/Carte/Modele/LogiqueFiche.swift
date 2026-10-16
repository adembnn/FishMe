import Foundation
import Core

/// Ordre des règles du jour : le plus important d'abord. Logique pure, sans écran.
nonisolated enum OrdreRegles {
    /// Nombre de lignes montrées avant « Voir toutes les règles (N) ».
    static let apercu = 5

    /// 0 = le plus important. Nuit en cours, no-kill, consommation, fermetures, puis le reste par état.
    static func priorite(_ ligne: LigneControle) -> Int {
        if ligne.type == .nuit, ligne.etat == .nonRespectee || ligne.etat == .aVerifierSurPlace { return 0 }
        if estNoKill(ligne) { return 1 }
        if ligne.type == .consommation { return 2 }
        if ligne.type == .reserve || (ligne.type == .periode && ligne.etat == .nonRespectee) { return 3 }
        switch ligne.etat {
        case .nonRespectee: return 4
        case .aVerifierSurPlace: return 5
        case .information: return 6
        case .respectee: return 7
        }
    }

    static func estNoKill(_ ligne: LigneControle) -> Bool {
        let phrase = ligne.phrase.lowercased()
        return phrase.contains("no-kill") || phrase.contains("no kill")
    }

    /// Tri stable : à priorité égale, l'ordre de `Core` est gardé.
    static func trier(_ lignes: [LigneControle]) -> [LigneControle] {
        lignes.enumerated()
            .sorted { a, b in
                let pa = priorite(a.element), pb = priorite(b.element)
                return pa != pb ? pa < pb : a.offset < b.offset
            }
            .map(\.element)
    }

    /// Les lignes à montrer : tout si `toutVoir`, sinon les `apercu` premières.
    static func visibles(_ lignes: [LigneControle], toutVoir: Bool) -> [LigneControle] {
        toutVoir ? lignes : Array(lignes.prefix(apercu))
    }
}

/// La truite fario est toujours proposée en eau de 1re catégorie, relevée ou non.
nonisolated enum TruiteEnPremiere {
    static let identifiant = "truite-fario"

    /// Ajoute la truite fario (non relevée : ni nombre de pêches, ni année) si l'eau est de 1re catégorie et qu'elle manque.
    static func completer(_ especes: [LigneEspece], categorie: Categorie) -> [LigneEspece] {
        guard categorie == .premiere, !especes.contains(where: { $0.espece.id == identifiant }) else { return especes }
        let truite = LigneEspece(espece: Espece(id: identifiant), nPeches: 0, annee: 0, ouverture: nil, rarete: nil, releve: false)
        return especes + [truite]
    }
}
