import Core
import Foundation

/// Petits formats d'affichage, en français. Aucun calcul métier : rareté, lune et consigne viennent de Core.
enum Formats {
    static let locale = Locale(identifier: "fr_FR")

    static func date(_ d: Date) -> String {
        d.formatted(.dateTime.day().month(.abbreviated).year().locale(locale))
    }

    static func heure(_ d: Date) -> String {
        d.formatted(.dateTime.hour().minute().locale(locale))
    }

    static func duree(_ secondes: Double) -> String {
        let minutes = Int((secondes / 60).rounded())
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? "\(h) h \(String(format: "%02d", m))" : "\(m) min"
    }

    static func nombre(_ v: Double, decimales: Int = 1) -> String {
        v.formatted(.number.precision(.fractionLength(0...decimales)).locale(locale))
    }

    static func taille(_ prise: Prise) -> String? {
        guard let l = prise.longueurCm else { return nil }
        let base = "\(nombre(l, decimales: 0)) cm"
        return prise.mesure == .estimee ? base + " estimé" : base
    }

    static func poids(_ p: PoidsEstime?) -> String? {
        guard let p else { return nil }
        return "≈ \(nombre(p.kilos)) kg estimé"
    }

    static func lune(_ phase: PhaseLune) -> String {
        switch phase {
        case .nouvelle: return "nouvelle lune"
        case .premierCroissant: return "premier croissant"
        case .premierQuartier: return "premier quartier"
        case .gibbeuseCroissante: return "gibbeuse croissante"
        case .pleine: return "pleine lune"
        case .gibbeuseDecroissante: return "gibbeuse décroissante"
        case .dernierQuartier: return "dernier quartier"
        case .dernierCroissant: return "dernier croissant"
        }
    }

    /// « La Marne · 94 » : le département est ce qui suit le dernier point médian. Jamais un point exact.
    static func departement(depuisLieuFlou lieu: String?) -> Departement? {
        guard let lieu, lieu.contains("·"), let reste = lieu.split(separator: "·").last else { return nil }
        let code = reste.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty, code.count <= 3 else { return nil }
        return Departement(code: code)
    }
}
