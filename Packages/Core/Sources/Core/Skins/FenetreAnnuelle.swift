import Foundation

/// Les thèmes de saison. Un cas de plus (l'automne, plus tard) ne change aucun fichier déjà écrit.
public enum ThemeSaison: String, Codable, Sendable, CaseIterable {
    case halloween
    case noel
    case ouvertureTruite
    case ete
}

/// Une période qui revient chaque année aux mêmes dates, bornes incluses, comptée en jours entiers (jamais à l'heure).
/// Elle peut traverser le 31 décembre (Noël : du 1er décembre au 6 janvier).
/// Rien n'en est tiré qui ressemble à un compte à rebours : on sait si la saison est ouverte et quand elle revient.
public struct FenetreAnnuelle: Sendable, Equatable {
    public let moisDebut: Int
    public let jourDebut: Int
    public let moisFin: Int
    public let jourFin: Int

    public init(moisDebut: Int, jourDebut: Int, moisFin: Int, jourFin: Int) {
        self.moisDebut = moisDebut
        self.jourDebut = jourDebut
        self.moisFin = moisFin
        self.jourFin = jourFin
    }

    /// Le jour de l'année en un entier comparable (mois * 100 + jour) : le 29 février existe, aucune année n'est supposée.
    private func cle(mois: Int, jour: Int) -> Int { mois * 100 + jour }

    /// Vrai si le jour calendaire de `date` (dans le calendrier donné) est dans la fenêtre, bornes incluses.
    public func contient(_ date: Date, calendrier: Calendar) -> Bool {
        let mois = calendrier.component(.month, from: date)
        let jour = calendrier.component(.day, from: date)
        let x = cle(mois: mois, jour: jour)
        let debut = cle(mois: moisDebut, jour: jourDebut)
        let fin = cle(mois: moisFin, jour: jourFin)
        if debut <= fin { return x >= debut && x <= fin }
        // Traverse le 31 décembre.
        return x >= debut || x <= fin
    }

    /// Le début (minuit, calendrier donné) de la prochaine ouverture strictement après le jour de `date`.
    /// Dans la fenêtre comme hors fenêtre : c'est le prochain jour de début, cette année ou la suivante.
    public func prochaineOuverture(apres date: Date, calendrier: Calendar) -> Date {
        let jourCourant = calendrier.startOfDay(for: date)
        let annee = calendrier.component(.year, from: date)
        for decalage in 0...8 {
            var composants = DateComponents()
            composants.year = annee + decalage
            composants.month = moisDebut
            composants.day = jourDebut
            guard let brut = calendrier.date(from: composants) else { continue }
            // Un 29 février dans une année non bissextile bascule au 1er mars : on passe à l'année suivante.
            guard calendrier.component(.month, from: brut) == moisDebut,
                  calendrier.component(.day, from: brut) == jourDebut else { continue }
            let candidat = calendrier.startOfDay(for: brut)
            if candidat > jourCourant { return candidat }
        }
        return jourCourant
    }
}
