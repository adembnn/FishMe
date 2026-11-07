import Core
import Foundation

/// Les mots de « Mes records », réunis pour être testés. Un record est un souvenir : le ton reste tendre, sans pression.
/// ⚠ à vérifier : écrit sans compilateur Swift.
enum TextesRecords {
    static let titre = "Mes records"
    static let phraseVide = "Tes souvenirs de pêche se rangeront ici."
    static let sansTaille = "Taille non notée"
    static let legendeBredouilles = "ça arrive"
    static let etiquetteTrophee = "Trophée"
    static let nouveau = "Nouveau"
    /// Durée d'affichage du bandeau.
    static let dureeBandeau: Duration = .seconds(4)

    /// « 78 cm », « 72,5 cm » : un chiffre après la virgule au plus, à la française.
    static func longueur(_ cm: Double, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        if !estFrancais(locale) { return "\(pouces(cm, locale: locale)) in" }
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        let texte = f.string(from: NSNumber(value: cm)) ?? String(Int(cm.rounded()))
        return "\(texte) cm"
    }

    /// « ≈ 4,2 kg estimé ».
    static func poids(_ kilos: Double, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        if !estFrancais(locale) {
            let g = NumberFormatter()
            g.locale = locale
            g.numberStyle = .decimal
            g.minimumFractionDigits = 0
            g.maximumFractionDigits = 1
            return AnglaisE.f("≈ %@ lb estimé", locale, g.string(from: NSNumber(value: kilos * 2.2046226)) ?? "")
        }
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return "≈ \(f.string(from: NSNumber(value: kilos)) ?? "") kg estimé"
    }

    /// « 12 sept. » ou « 12 septembre ».
    static func jour(_ date: Date, long: Bool = false, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        let f = DateFormatter()
        f.locale = estFrancais(locale) ? Locale(identifier: "fr_FR") : locale
        f.timeZone = TimeZone(identifier: "Europe/Paris")
        if estFrancais(locale) {
            f.dateFormat = long ? "d MMMM" : "d MMM"
        } else {
            f.setLocalizedDateFormatFromTemplate(long ? "MMMMd" : "MMMd")
        }
        return f.string(from: date)
    }

    /// « La Marne · 94 » devient « La Marne » : l'eau seulement, jamais un point.
    static func lieu(_ lieuFlou: String?) -> String? {
        guard let brut = lieuFlou?.trimmingCharacters(in: .whitespacesAndNewlines), !brut.isEmpty else { return nil }
        let eau = brut.components(separatedBy: " · ").first?.trimmingCharacters(in: .whitespaces) ?? brut
        return eau.isEmpty ? nil : eau
    }

    /// « 12 sept. · la Marne ».
    static func jourEtLieu(_ record: RecordEspece, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        [jour(record.date, locale: locale), lieu(record.lieuFlou)].compactMap { $0 }.joined(separator: " · ")
    }

    /// « Brochet, 78 centimètres, 12 septembre, la Marne, trophée ».
    static func phraseVoixOff(_ record: RecordEspece, nom: String, nouveau: Bool = false,
                           locale: Locale = Locale(identifier: "fr_FR")) -> String {
        let cm = record.longueurCm
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.numberStyle = .decimal
        f.maximumFractionDigits = 1
        let nombre = f.string(from: NSNumber(value: cm)) ?? String(Int(cm.rounded()))
        var morceaux = [nom, estFrancais(locale) ? "\(nombre) centimètres" : "\(pouces(cm, locale: locale)) inches"]
        if record.mesure == .estimee { morceaux.append(AnglaisE.t("estimé", locale)) }
        morceaux.append(jour(record.date, long: true, locale: locale))
        if let l = lieu(record.lieuFlou) { morceaux.append(l) }
        if record.estTrophee { morceaux.append(AnglaisE.t(etiquetteTrophee, locale).lowercased()) }
        if nouveau { morceaux.append(AnglaisE.t(TextesRecords.nouveau, locale).lowercased()) }
        return morceaux.joined(separator: ", ")
    }

    /// « Ton plus grand brochet jusqu'ici : 78 cm. Joli souvenir. » ; `nil` hors d'un nouveau souvenir.
    static func bandeau(_ evenement: EvenementRecord, nomEspece: String, locale: Locale = Locale(identifier: "fr_FR")) -> String? {
        guard case let .nouveauSouvenir(_, nouveau) = evenement else { return nil }
        return AnglaisE.f("Ton plus grand %@ jusqu'ici : %@. Joli souvenir.", locale, nomEspece.lowercased(), longueur(nouveau, locale: locale))
    }

    private static func estFrancais(_ locale: Locale) -> Bool {
        locale.language.languageCode?.identifier == "fr"
    }

    /// Centimètres en pouces, arrondis au quart de pouce : « 30.75 ».
    private static func pouces(_ cm: Double, locale: Locale) -> String {
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        let quarts = (cm / 2.54 * 4).rounded() / 4
        return f.string(from: NSNumber(value: quarts)) ?? String(Int(quarts.rounded()))
    }
}
