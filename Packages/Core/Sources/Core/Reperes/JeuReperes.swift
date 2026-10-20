import Foundation

/// Fusion de deux jeux de repères (iPhone et iCloud, ou deux iPhones). Contrairement à `FusionSauvegarde`, une suppression
/// voulue se propage, sinon un repère effacé reviendrait de l'iCloud.
public enum JeuReperes {
    private static func cleDeDepartage(_ r: Repere) -> String {
        let photos: String = r.photos.joined(separator: ",")
        let prises: String = r.idsPrises.map(\.uuidString).joined(separator: ",")
        let passage: Double = r.passageManuel?.timeIntervalSince1970 ?? 0
        let supprime: Double = r.supprime?.timeIntervalSince1970 ?? 0
        var morceaux: [String] = [r.nom, r.note, r.icone.rawValue, String(r.position.latitude), String(r.position.longitude)]
        morceaux += [photos, prises, String(r.cree.timeIntervalSince1970), String(r.modifie.timeIntervalSince1970)]
        morceaux += [String(passage), String(supprime)]
        return morceaux.joined(separator: "|")
    }

    /// Lequel des deux gagne : le dernier changement (modification ou suppression) le plus récent ; à égalité la suppression ;
    /// puis un ordre fixe sur le contenu, pour que l'ordre des arguments ne change jamais le résultat.
    static func gagnant(_ a: Repere, _ b: Repere) -> Repere {
        if a.dernierChangement != b.dernierChangement { return a.dernierChangement > b.dernierChangement ? a : b }
        if a.estSupprime != b.estSupprime { return a.estSupprime ? a : b }
        return cleDeDepartage(a) >= cleDeDepartage(b) ? a : b
    }

    /// Union par `id` ; le changement le plus récent gagne ; une pierre tombale plus récente que la dernière modification supprime ;
    /// les pierres tombales de plus de 30 jours disparaissent. Résultat trié par `id` : idempotent et commutatif.
    public static func fusionner(local: [Repere], distant: [Repere], maintenant: Date = Date()) -> [Repere] {
        var parId: [UUID: Repere] = [:]
        for r in local + distant {
            if let existant = parId[r.id] { parId[r.id] = gagnant(existant, r) } else { parId[r.id] = r }
        }
        let limite = TimeInterval(LimitesReperes.joursPierreTombale) * 86_400
        return parId.values
            .filter { r in
                guard let supprime = r.supprime else { return true }
                return maintenant.timeIntervalSince(supprime) <= limite
            }
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }

    /// Les identifiants à retirer de l'iCloud après une fusion : présents côté iCloud, absents du résultat (pierres tombales purgées).
    public static func aRetirer(distant: [Repere], resultat: [Repere]) -> [UUID] {
        let gardes = Set(resultat.map(\.id))
        return distant.map(\.id).filter { !gardes.contains($0) }
    }
}
