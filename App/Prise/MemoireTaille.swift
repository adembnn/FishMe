import Core
import Foundation

/// La dernière taille confirmée pour chaque espèce, gardée sur l'iPhone (UserDefaults) :
/// la prochaine prise de la même espèce part de là, pas de 78 cm.
struct MemoireTaille {
    var defauts: UserDefaults = .standard

    static func cle(_ espece: Espece) -> String { "prise.derniereTailleCm.\(espece.id)" }

    /// La dernière taille confirmée, ramenée dans la plage du curseur ; `nil` si l'espèce n'a jamais été confirmée.
    func derniere(_ espece: Espece) -> Double? {
        guard let valeur = defauts.object(forKey: Self.cle(espece)) as? Double, valeur.isFinite else { return nil }
        return Self.borner(valeur)
    }

    func retenir(_ cm: Double, pour espece: Espece) {
        guard cm.isFinite else { return }
        defauts.set(Self.borner(cm.rounded()), forKey: Self.cle(espece))
    }

    static func borner(_ cm: Double) -> Double {
        min(max(cm, PriseLogique.plageTaille.lowerBound), PriseLogique.plageTaille.upperBound)
    }

    /// Un pas de − ou + (1 cm) sans sortir de la plage.
    static func apresPas(_ cm: Double, delta: Double) -> Double { borner(cm + delta) }
}
