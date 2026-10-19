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
    static func longueur(_ cm: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        let texte = f.string(from: NSNumber(value: cm)) ?? String(Int(cm.rounded()))
        return "\(texte) cm"
    }

    /// « ≈ 4,2 kg estimé ».
    static func poids(_ kilos: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return "≈ \(f.string(from: NSNumber(value: kilos)) ?? "") kg estimé"
    }

    /// « 12 sept. » ou « 12 septembre ».
    static func jour(_ date: Date, long: Bool = false) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.timeZone = TimeZone(identifier: "Europe/Paris")
        f.dateFormat = long ? "d MMMM" : "d MMM"
        return f.string(from: date)
    }

    /// « La Marne · 94 » devient « La Marne » : l'eau seulement, jamais un point.
    static func lieu(_ lieuFlou: String?) -> String? {
        guard let brut = lieuFlou?.trimmingCharacters(in: .whitespacesAndNewlines), !brut.isEmpty else { return nil }
        let eau = brut.components(separatedBy: " · ").first?.trimmingCharacters(in: .whitespaces) ?? brut
        return eau.isEmpty ? nil : eau
    }

    /// « 12 sept. · la Marne ».
    static func jourEtLieu(_ record: RecordEspece) -> String {
        [jour(record.date), lieu(record.lieuFlou)].compactMap { $0 }.joined(separator: " · ")
    }

    /// « Brochet, 78 centimètres, 12 septembre, la Marne, trophée ».
    static func phraseVoixOff(_ record: RecordEspece, nom: String, nouveau: Bool = false) -> String {
        let cm = record.longueurCm
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.maximumFractionDigits = 1
        let nombre = f.string(from: NSNumber(value: cm)) ?? String(Int(cm.rounded()))
        var morceaux = [nom, "\(nombre) centimètres"]
        if record.mesure == .estimee { morceaux.append("estimé") }
        morceaux.append(jour(record.date, long: true))
        if let l = lieu(record.lieuFlou) { morceaux.append(l) }
        if record.estTrophee { morceaux.append("trophée") }
        if nouveau { morceaux.append("nouveau") }
        return morceaux.joined(separator: ", ")
    }

    /// « Ton plus grand brochet jusqu'ici : 78 cm. Joli souvenir. » ; `nil` hors d'un nouveau souvenir.
    static func bandeau(_ evenement: EvenementRecord, nomEspece: String) -> String? {
        guard case let .nouveauSouvenir(_, nouveau) = evenement else { return nil }
        return "Ton plus grand \(nomEspece.lowercased()) jusqu'ici : \(longueur(nouveau)). Joli souvenir."
    }
}
