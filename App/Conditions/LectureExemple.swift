import Foundation
import Core

/// Une lecture d'exemple pour le mode démo (`demo.communaute`) : WeatherKit ne répond ni sans signature ni sans réseau.
/// Jamais utilisée hors du mode démo, et la feuille l'annonce (« Données d'exemple »).
enum LectureExemple {
    static func creer(maintenant: Date = Date()) -> LectureConditions {
        let cal = Calendar.current
        let debutHeure = cal.dateInterval(of: .hour, for: maintenant)?.start ?? maintenant
        // Un code de temps par jour (aujourd'hui, puis les six suivants).
        let codes = [2, 80, 3, 61, 1, 95, 0]
        let base: [Double] = [16, 14, 13, 12, 15, 19, 21]
        let heures: [PointMeteo] = (-6..<168).map { i in
            let date = debutHeure.addingTimeInterval(Double(i) * 3600)
            let jour = max(0, min(6, cal.dateComponents([.day], from: cal.startOfDay(for: maintenant), to: cal.startOfDay(for: date)).day ?? 0))
            let h = Double(cal.component(.hour, from: date))
            let cycle = -cos((h - 4) / 24 * 2 * .pi)
            let code = codes[jour]
            let pluvieux = [61, 80, 95].contains(code)
            return PointMeteo(
                heure: date,
                ventKmh: 11 + Double(jour * 2) + 4 * (cycle + 1),
                rafalesKmh: 24 + Double(jour * 3),
                directionDeg: 250 + Double(jour * 10),
                pluieMm: pluvieux && Int(h) % 3 == 0 ? 0.8 : 0,
                pressionHPa: 1014 - Double(i) / 14,
                temperatureC: base[jour] + 4.5 * cycle,
                codeTemps: code)
        }
        let aube = cal.date(bySettingHour: 7, minute: 52, second: 0, of: maintenant)
        let soir = cal.date(bySettingHour: 19, minute: 41, second: 0, of: maintenant)
        let station = StationHydro(code: "F7100000", nom: "La Marne à Gournay", eau: "La Marne",
                                   coordonnee: Coordonnee(latitude: 48.86, longitude: 2.58))
        // Une crue douce puis une décrue, un point tous les quarts d'heure sur 48 h, terminant sur la mesure courante.
        let serie: [MesureNiveau] = (0...192).map { i in
            let t = Double(i) / 192
            let date = maintenant.addingTimeInterval(-Double(192 - i) * 900)
            let onde: Double = sin(t * 2 * Double.pi) * (1 - t)
            return MesureNiveau(heure: date, hauteurM: 1.32 + 0.18 * onde, debitM3s: 41 + 6 * onde)
        }
        let eau = NiveauEau(station: station, hauteurM: 1.32, debitM3s: 41, serie48h: serie, normaleDebitM3s: 45,
                            vigilance: .vert, heureMesure: maintenant)
        let point = heures.min { abs($0.heure.timeIntervalSince(maintenant)) < abs($1.heure.timeIntervalSince(maintenant)) }
        let conditions = Conditions(heure: maintenant, ventKmh: point?.ventKmh, pluieMm: point?.pluieMm,
                                    pressionHPa: point?.pressionHPa, tendancePressionHPa6h: -2, aube: aube, crepuscule: soir,
                                    etatRiviere: .normal, sources: ["Exemple (mode démo)"])
        return LectureConditions(point: station.coordonnee, conditions: conditions, meteo: MeteoBrute(heures: heures),
                                 eau: eau, alerte: nil, lueLe: maintenant)
    }
}
