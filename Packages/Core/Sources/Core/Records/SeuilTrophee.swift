import Foundation

/// Seuil au-delà duquel une prise porte l'étiquette « Trophée » (D2 de la fiche N4 : le 95e centile des longueurs connues).
/// Protocole à part, sur le modèle de `ServiceLongueurPlausible`, pour ne casser aucun faux service.
public protocol ServiceSeuilTrophee: Sendable {
    /// En cm ; `nil` si l'espèce n'a pas de référence (elle garde son souvenir, sans étiquette).
    func seuilTropheeCm(espece: Espece) -> Double?
}

public extension ServiceEspeces {
    /// `nil` pour un service qui ne sait pas le donner (faux, enveloppes).
    func seuilTropheeCm(espece: Espece) -> Double? {
        (self as? ServiceSeuilTrophee)?.seuilTropheeCm(espece: espece)
    }
}
