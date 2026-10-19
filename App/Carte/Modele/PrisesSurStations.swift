import Foundation
import Core

// Les vignettes de SES PROPRES prises sur ses stations (fiche d'un coin). Elles viennent de la collection de l'iPhone,
// restent sur l'iPhone et ne sont partagées nulle part : rien ici n'envoie, n'exporte ni ne publie une photo.
// Une prise n'a pas de coordonnée (aucun GPS, règle du produit) : le lien prise-station passe par le lieu flou
// (« La Marne · 94 ») que `Core` a donné à la prise quand elle a été faite.

/// Ce que A branche : la lecture des prises du pêcheur et de leurs photos (dossier de `App/Collection/`, que la carte n'importe pas).
/// Par défaut : aucune prise, aucune vignette.
nonisolated struct PrisesDuPecheurCarte: Sendable {
    /// Toutes les prises du pêcheur (par exemple `CollectionCartes.cartes()`).
    var lire: @Sendable () async -> [Prise]
    /// Les octets de la photo d'une prise, sans GPS (par exemple le fichier de `DepotCartes`), ou `nil`.
    var photo: @Sendable (Prise) -> Data?

    static let aucune = PrisesDuPecheurCarte(lire: { [] }, photo: { _ in nil })
}

nonisolated enum AppariementPrises {
    /// Au plus ce nombre de vignettes sur une fiche : la rangée reste lisible et légère.
    static let maximumVignettes = 6

    /// Minuscules, sans accents, espaces et points médians uniformisés : « La Marne · 94 » et « la marne  ·  94 » sont le même lieu.
    static func normaliser(_ texte: String) -> String {
        texte
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .split(whereSeparator: { $0 == " " })
            .joined(separator: " ")
    }

    /// Les prises du pêcheur faites sur cette station : de vraies prises avec une photo (ni carte déclarée, ni photo d'exemple),
    /// dont le lieu flou est celui de la station (`lieuxFlous` : celui que `Core` donne au coin, et « eau · département » de la station).
    /// Les plus récentes d'abord, `maximumVignettes` au plus.
    static func prises(_ toutes: [Prise], lieuxFlous: [String]) -> [Prise] {
        let cibles = Set(lieuxFlous.map(normaliser).filter { !$0.isEmpty })
        guard !cibles.isEmpty else { return [] }
        return toutes
            .filter { prise in
                guard !prise.estDeclaree, !prise.exemple, prise.cheminPhoto != nil, let lieu = prise.lieuFlou else { return false }
                return cibles.contains(normaliser(lieu))
            }
            .sorted { $0.date > $1.date }
            .prefix(maximumVignettes)
            .map { $0 }
    }

    /// « La Marne · 94 », sans le point exact ; `nil` sans nom d'eau.
    static func lieuFlou(eau: String?, departement: Departement?) -> String? {
        guard let eau, !eau.isEmpty else { return nil }
        guard let departement, !departement.estInconnu else { return eau }
        return "\(eau) · \(departement.code)"
    }
}
