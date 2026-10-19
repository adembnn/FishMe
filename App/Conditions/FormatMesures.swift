import Foundation
import Core

/// Mise en forme des mesures de N3 : aucune valeur n'est calculée ici, tout vient de `ServiceMesures` (Core).
nonisolated enum FormatMesures {
    private static func fabriquer(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = format
        return f
    }
    nonisolated(unsafe) private static let fJour = fabriquer("d MMM")
    private static let verrou = NSLock()

    /// « 12 oct. »
    static func jour(_ date: Date) -> String {
        verrou.lock()
        defer { verrou.unlock() }
        return fJour.string(from: date)
    }

    static func nom(_ g: Grandeur) -> String {
        switch g {
        case .pression: return "Pression"
        case .temperatureEau: return "Eau"
        case .debit: return "Débit"
        }
    }

    static func icone(_ g: Grandeur) -> String {
        switch g {
        case .pression: return "gauge.medium"
        case .temperatureEau: return "thermometer.medium"  // ⚠ à vérifier sur Mac : nom du symbole SF
        case .debit: return "water.waves"  // ⚠ à vérifier sur Mac : nom du symbole SF
        }
    }

    static func identifiant(_ g: Grandeur) -> String {
        switch g {
        case .pression: return "mesure-pression"
        case .temperatureEau: return "mesure-eau"
        case .debit: return "mesure-debit"
        }
    }

    /// « 1010 hPa », « 14,2 °C », « 18 m³/s ».
    static func valeur(_ m: MesureSourcee) -> String {
        "\(FormatConditions.nombre(m.valeur, decimales: decimales(m.grandeur, m.valeur))) \(m.unite)"
    }

    private static func decimales(_ g: Grandeur, _ v: Double) -> Int {
        switch g {
        case .pression: return 0
        case .temperatureEau: return 1
        case .debit: return abs(v) < 10 ? 1 : 0
        }
    }

    /// « −3 hPa en 6 h », « +0,7 °C en 24 h » ; `nil` sans tendance.
    static func ecart(_ m: MesureSourcee) -> String? {
        guard let t = m.tendance else { return nil }
        let arrondi = (t.ecart * 10).rounded() / 10
        let d = arrondi == arrondi.rounded() ? 0 : 1
        let signe = arrondi < 0 ? "−" : (arrondi > 0 ? "+" : "")
        return "\(signe)\(FormatConditions.nombre(abs(arrondi), decimales: d)) \(m.unite) en \(t.surHeures) h"
    }

    /// Symbole de la flèche : jamais de couleur, une tendance n'est ni un bon ni un mauvais signe.
    static func fleche(_ s: SensTendance) -> String {
        switch s {
        case .hausse: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .baisse: return "arrow.down.right"
        }
    }

    static func sens(_ s: SensTendance) -> String {
        switch s {
        case .hausse: return "en hausse"
        case .stable: return "stable"
        case .baisse: return "en baisse"
        }
    }

    /// La ligne de légende : la source et l'heure. « Apple Weather · 14 h 05 », « … · prévu 16 h 05 »,
    /// « … · dernière mesure le 12 oct. » pour une mesure d'eau de plus de 48 h.
    static func sourceEtHeure(_ m: MesureSourcee) -> String {
        if m.fraicheur == .ancienne { return "\(m.source) · dernière mesure le \(jour(m.heure))" }
        if m.prevue { return "\(m.source) · prévu \(FormatConditions.heure(m.heure))" }
        return "\(m.source) · \(FormatConditions.heure(m.heure))"
    }

    /// Ce que VoiceOver lit pour une ligne.
    static func accessibilite(_ m: MesureSourcee) -> String {
        var s = "\(nom(m.grandeur)), \(valeur(m))"
        if let t = m.tendance, let e = ecart(m) { s += ", \(sens(t.sens)), \(e)" }
        return s + ", " + sourceEtHeure(m)
    }

    /// « lu à 14 h 05, sans réseau »
    static func luSansReseau(_ date: Date) -> String { "lu à \(FormatConditions.heure(date)), sans réseau" }
}
