import Core
import Foundation

/// Ce que « Mes envies » demande aux autres dossiers de l'app. Passé par A depuis `RootView.swift` (lot L25) :
/// ce dossier n'importe que `Core`. Vide par défaut : sans rien de branché, la liste montre « Choisis un spot... ».
struct EnviesExternes {
    /// Le contrôle de l'espèce au spot du pêcheur à la date donnée ; `nil` sans spot.
    /// A l'appelle avec `ServiceRegles.controle(espece:tailleCm: nil, mesure: nil, date:, lieu:, prisesDuJour: [])`.
    var controle: (Espece, Date) -> ResultatControle? = { _, _ in nil }
    /// La date de réouverture d'une espèce fermée, si les règles la donnent (`ResultatControle` ne la porte pas). `nil` : « Fermée ce jour ».
    var reouverture: (Espece, Date) -> Date? = { _, _ in nil }
    /// Un conseil du mois pour l'espèce, déjà filtré par l'abonnement (A passe par `ContexteConseils.parType`) ; `nil` : la ligne disparaît.
    var conseil: (Espece) -> Conseil? = { _ in nil }
    /// Ouvre le choix d'un spot. Tant que c'est `nil`, la ligne « Choisis un spot » n'est pas un bouton.
    var choisirSpot: (() -> Void)? = nil

    static let vides = EnviesExternes()
}
