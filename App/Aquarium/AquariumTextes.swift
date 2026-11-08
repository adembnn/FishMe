import Core
import Foundation

/// Textes de l'aquarium et de la galerie de décors en français avec leur équivalent anglais (région US).
/// Table dédiée « AquariumTextes » (`AquariumTextes.xcstrings`), clé = texte français, langue prise dans le dossier `.lproj`
/// de la région. En français, le texte revient tel quel : le français ne change pas d'un caractère.
/// Les libellés de `LibellesSkins` (Core) et les noms de décors sont recomposés ici pour l'anglais, sans toucher à Core.
nonisolated enum AquariumTextes {
    static let table = "AquariumTextes"

    private final class Ancre {}

    private static let fr = Locale(identifier: "fr_FR")

    static func bundle(_ locale: Locale) -> Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    private static func estFrancais(_ locale: Locale) -> Bool {
        let code = locale.language.languageCode?.identifier
        return code == nil || code == "fr"
    }

    static func t(_ francais: String, _ locale: Locale = fr) -> String {
        guard !estFrancais(locale) else { return francais }
        return bundle(locale).localizedString(forKey: francais, value: francais, table: table)
    }

    static func f(_ francais: String, _ locale: Locale = fr, _ args: CVarArg...) -> String {
        String(format: t(francais, locale), arguments: args)
    }

    // MARK: Aquarium

    static func compteur(_ nombre: Int, locale: Locale = fr) -> String {
        if estFrancais(locale) {
            return nombre == 1 ? "1 poisson dans ton aquarium" : "\(nombre) poissons dans ton aquarium"
        }
        return nombre == 1 ? t("1 poisson dans ton aquarium", locale) : f("%lld poissons dans ton aquarium", locale, nombre)
    }

    /// « 42 cm » en français ; en anglais, des pouces (« 16.5 in »).
    static func longueur(cm: Double?, locale: Locale = fr) -> String {
        guard let cm else { return t("Taille non mesurée", locale) }
        if estFrancais(locale) { return "\(Int(cm.rounded())) cm" }
        let pouces = (cm / 2.54 * 10).rounded() / 10
        return String(format: "%.1f in", pouces)
    }

    static func nomParDefaut(_ locale: Locale = fr) -> String { t("Poisson", locale) }

    static func voirCarte(nom: String, locale: Locale = fr) -> String {
        estFrancais(locale) ? "\(nom), voir la carte" : f("%@, ouvrir la carte", locale, nom)
    }

    // MARK: Décors

    /// Le nom du décor : le français vient du catalogue de Core, l'anglais d'une table dédiée.
    static func nomSkin(_ skin: Skin, locale: Locale = fr) -> String { t(skin.nom, locale) }

    private static let moisAnglais = ["January", "February", "March", "April", "May", "June", "July", "August",
                                      "September", "October", "November", "December"]

    static func revient(le date: Date, calendrier: Calendar, locale: Locale = fr) -> String {
        guard !estFrancais(locale) else { return LibellesSkins.revient(le: date, calendrier: calendrier) }
        let numero = calendrier.component(.month, from: date)
        guard (1...12).contains(numero) else { return t("Revient chaque année", locale) }
        return "Returns in \(moisAnglais[numero - 1])"
    }

    static func aGagner(_ critere: CritereDecor, locale: Locale = fr) -> String {
        guard !estFrancais(locale) else { return LibellesSkins.aGagner(critere) }
        switch critere {
        case .especesDifferentes(let n): return "To earn: \(n) different species"
        case .sessions(let n): return "To earn: \(n) fishing \(n > 1 ? "sessions" : "session")"
        case .unLegendaire: return "To earn: one legendary fish"
        }
    }

    static func ligneStatut(_ statut: StatutSkin, calendrier: Calendar, locale: Locale = fr) -> String {
        guard !estFrancais(locale) else { return LibellesSkins.ligneStatut(statut, calendrier: calendrier) }
        switch statut {
        case .disponible: return t("Disponible", locale)
        case .apercuSeulement: return t("Inclus avec Pro", locale)
        case .horsSaison(let revientLe): return revient(le: revientLe, calendrier: calendrier, locale: locale)
        case .aGagner(let critere): return aGagner(critere, locale: locale)
        }
    }

    static func accessibilite(_ skin: Skin, statut: StatutSkin, calendrier: Calendar, locale: Locale = fr) -> String {
        guard !estFrancais(locale) else { return LibellesSkins.accessibilite(skin, statut: statut, calendrier: calendrier) }
        let origine: String
        switch skin.origine {
        case .gagne: origine = "decor earned by fishing"
        case .pro, .saison: origine = "included with Pro"
        case .offertParDefi: origine = "challenge reward"
        }
        let etat: String
        switch statut {
        case .disponible: etat = "available"
        case .apercuSeulement: etat = "preview only, Pro required to apply it"
        case .horsSaison, .aGagner: etat = ligneStatut(statut, calendrier: calendrier, locale: locale)
        }
        return "\(nomSkin(skin, locale: locale)), \(origine), \(etat)"
    }

    static func boutonAppliquer(_ statut: StatutSkin, locale: Locale = fr) -> String? {
        guard !estFrancais(locale) else { return LibellesSkins.boutonAppliquer(statut) }
        switch statut {
        case .disponible: return t("Appliquer", locale)
        case .apercuSeulement: return t("Appliquer avec Pro", locale)
        case .horsSaison, .aGagner: return nil
        }
    }
}
