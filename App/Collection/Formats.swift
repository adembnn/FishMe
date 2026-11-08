import Core
import Foundation

/// Les libellés de la carte, écrits en toutes lettres (L18). Les formes courtes ne servent que si la largeur manque
/// (`ViewThatFits`) : jamais un sigle de trois lettres.
enum LibellesCarte {
    static let frequence = "Fréquence"
    static let frequenceCourt = "Fréq."
    static let taille = "Taille"
    static let tailleEstimee = "Taille · estimée"
    static let tailleEstimeeCourt = "Taille est."
    static let poidsEstime = "Poids · estimé"
    static let rang = "Rang"

    /// « Taille » pour une mesure lue ou saisie, « Taille · estimée » pour une taille choisie au curseur.
    static func libelleTaille(estimee: Bool, _ t: AnglaisD = AnglaisD()) -> String { t(estimee ? tailleEstimee : taille) }
    /// La forme courte de `libelleTaille`.
    static func libelleTailleCourt(estimee: Bool, _ t: AnglaisD = AnglaisD()) -> String { t(estimee ? tailleEstimeeCourt : taille) }
}

/// Petits formats d'affichage, en français. Aucun calcul métier : rareté, lune et consigne viennent de Core.
enum Formats {
    static let locale = Locale(identifier: "fr_FR")

    static func date(_ d: Date, locale: Locale = Formats.locale) -> String {
        d.formatted(.dateTime.day().month(.abbreviated).year().locale(locale))
    }

    /// Le partage ne donne jamais le jour : « oct. 2026 ».
    static func moisAnnee(_ d: Date, locale: Locale = Formats.locale) -> String {
        d.formatted(.dateTime.month(.abbreviated).year().locale(locale))
    }

    static func heure(_ d: Date, locale: Locale = Formats.locale) -> String {
        d.formatted(.dateTime.hour().minute().locale(locale))
    }

    static func duree(_ secondes: Double, locale: Locale = Formats.locale) -> String {
        let t = AnglaisD(locale)
        let minutes = Int((secondes / 60).rounded())
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? t("%lld h %@", h, String(format: "%02d", m)) : t("%lld min", m)
    }

    static func nombre(_ v: Double, decimales: Int = 1, locale: Locale = Formats.locale) -> String {
        v.formatted(.number.precision(.fractionLength(0...decimales)).locale(locale))
    }

    static func taille(_ prise: Prise, locale: Locale = Formats.locale) -> String? {
        guard let l = prise.longueurCm else { return nil }
        let t = AnglaisD(locale)
        let base = t.estAnglais ? t.format.taille(centimetres: l) : "\(nombre(l, decimales: 0, locale: locale)) cm"
        return prise.mesure == .estimee ? t("%@ estimé", base) : base
    }

    static func poids(_ p: PoidsEstime?, locale: Locale = Formats.locale) -> String? {
        guard let p else { return nil }
        let t = AnglaisD(locale)
        let valeur = t.estAnglais ? t.format.poids(kilogrammes: p.kilos) : "\(nombre(p.kilos, locale: locale)) kg"
        return "≈ " + t("%@ estimé", valeur)
    }

    /// La valeur du poids seule (« ≈ 1,4 kg »), à mettre derrière le libellé « Poids · estimé ».
    static func poidsValeur(_ p: PoidsEstime?, locale: Locale = Formats.locale) -> String? {
        guard let p else { return nil }
        let t = AnglaisD(locale)
        return "≈ " + (t.estAnglais ? t.format.poids(kilogrammes: p.kilos) : "\(nombre(p.kilos, locale: locale)) kg")
    }

    /// La valeur de la taille seule (« 62 cm »), à mettre derrière le libellé « Taille » ou « Taille · estimée ».
    static func tailleValeur(_ prise: Prise, locale: Locale = Formats.locale) -> String? {
        guard let l = prise.longueurCm else { return nil }
        let t = AnglaisD(locale)
        return t.estAnglais ? t.format.taille(centimetres: l) : "\(nombre(l, decimales: 0, locale: locale)) cm"
    }

    static func lune(_ phase: PhaseLune, locale: Locale = Formats.locale) -> String {
        let t = AnglaisD(locale)
        switch phase {
        case .nouvelle: return t("nouvelle lune")
        case .premierCroissant: return t("premier croissant")
        case .premierQuartier: return t("premier quartier")
        case .gibbeuseCroissante: return t("gibbeuse croissante")
        case .pleine: return t("pleine lune")
        case .gibbeuseDecroissante: return t("gibbeuse décroissante")
        case .dernierQuartier: return t("dernier quartier")
        case .dernierCroissant: return t("dernier croissant")
        }
    }

    /// « La Marne · 94 » (eau connue) ou « Département 94 » (pas d'eau nommée) : le département est le dernier mot.
    /// « Hors de France » et les textes sans code n'en donnent aucun. Jamais un point exact.
    static func departement(depuisLieuFlou lieu: String?) -> Departement? {
        guard let lieu else { return nil }
        let reste: String
        if lieu.contains("·"), let fin = lieu.split(separator: "·").last {
            reste = String(fin)
        } else if lieu.hasPrefix("Département "), let fin = lieu.split(separator: " ").last {
            reste = String(fin)
        } else {
            return nil
        }
        let code = reste.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty, code.count <= 3 else { return nil }
        return Departement(code: code)
    }
}
