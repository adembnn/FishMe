import Foundation
#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

// Fichier à ajouter aux DEUX cibles (app et widget) : c'est le type qui décrit l'activité (fiche L10, « Pièges »).
// Il n'importe pas `Core` : l'heure de fin légale arrive comme donnée (`finLegale` de `ServiceSoleil`),
// elle n'est jamais recalculée ici. Aucune coordonnée, aucun nom de coin : l'écran verrouillé est vu par d'autres.

/// Ce que montre l'activité. Rien d'autre que des heures et un nombre.
public struct EtatSession: Codable, Hashable, Sendable {
    public var debut: Date
    /// `nil` si `Core` n'a pas pu la calculer : on ne l'invente pas.
    public var finLegale: Date?
    /// Nombre de prises de la session (gardées ou relâchées). Ce n'est pas un verdict : l'activité ne dit jamais ce qu'on peut garder.
    public var prises: Int

    public init(debut: Date, finLegale: Date?, prises: Int) {
        self.debut = debut
        self.finLegale = finLegale
        self.prises = prises
    }

    /// Ce qui s'affiche à un instant donné.
    public enum Affichage: Equatable, Sendable {
        /// Le système fait tourner le compte à rebours sans réveiller l'app.
        case compteARebours(jusqua: Date)
        /// Texte fixe « fin légale 19:33 » (le jour d'octobre dure plus longtemps que les 8 h de l'activité).
        case finLegale(Date)
        /// Départ hors de la fenêtre légale (la fin légale est déjà passée au départ).
        case pecheFermee
        /// `Core` n'a pas rendu d'heure : durée écoulée seulement, sans fausse fin.
        case finInconnue(depuis: Date)
    }

    /// `perime` : le système a passé `staleDate` (`context.isStale`). `maintenant` sert au cas où le redessin tarde.
    public func affichage(maintenant: Date, perime: Bool) -> Affichage {
        guard let fin = finLegale else { return .finInconnue(depuis: debut) }
        if fin <= debut { return .pecheFermee }
        if perime || maintenant >= fin { return .finLegale(fin) }
        return .compteARebours(jusqua: fin)
    }

    /// Heure de péremption à passer à `ActivityContent(staleDate:)` : la fin légale, si elle est encore à venir.
    public func heurePerimee(maintenant: Date) -> Date? {
        guard let fin = finLegale, fin > debut, fin > maintenant else { return nil }
        return fin
    }
}

#if canImport(ActivityKit) && os(iOS)
public struct SessionActivityAttributes: ActivityAttributes {
    public typealias ContentState = EtatSession
    public init() {}
}
#endif
