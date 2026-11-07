import Core
import Foundation

/// Tous les textes du bloc de règles américaines (lot US12), en français avec leur équivalent anglais.
/// La clé est le texte français (comme `App/Region/Localizable.xcstrings`) ; les traductions sont dans `ReglesUS.xcstrings`
/// (table « ReglesUS » : un second `Localizable.xcstrings` dans un autre dossier ferait entrer deux fichiers de même nom dans le paquet).
/// La langue suit la région de l'app (`Locale` de l'environnement), pas celle du téléphone : on cherche donc le dossier `.lproj` de la langue demandée.
/// Aucun texte ne dit qu'une prise est permise : trois verdicts seulement, « interdit », « à vérifier », « donnée absente ».
nonisolated struct TextesReglesUS: Sendable, Equatable {
    static let table = "ReglesUS"

    let locale: Locale

    init(locale: Locale = Locale(identifier: "en_US")) { self.locale = locale }

    private final class Ancre {}

    private var bundle: Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    // MARK: Les trois verdicts

    /// Le mot de la pastille de tête : exactement trois valeurs.
    func etiquette(_ verdict: VerdictUS) -> String {
        switch verdict {
        case .interdit: String(localized: "Interdit", table: Self.table, bundle: bundle)
        case .aVerifier: String(localized: "À vérifier", table: Self.table, bundle: bundle)
        case .donneeAbsente: String(localized: "Donnée absente", table: Self.table, bundle: bundle)
        }
    }

    /// La phrase de tête, sans promesse : « à vérifier » vaut aussi pour « aucune interdiction connue ».
    func phrase(_ verdict: VerdictUS) -> String {
        switch verdict {
        case .interdit: String(localized: "Il faut relâcher le poisson", table: Self.table, bundle: bundle)
        case .aVerifier:
            String(localized: "Aucune interdiction connue de nous, vérifie auprès de l'agence", table: Self.table, bundle: bundle)
        case .donneeAbsente:
            String(localized: "Nous n'avons lu aucune règle pour ce poisson ici, vérifie auprès de l'agence", table: Self.table, bundle: bundle)
        }
    }

    // MARK: Titres et liens

    var titreDepliant: String { String(localized: "Voir les règles lues pour ce poisson", table: Self.table, bundle: bundle) }
    var aucuneLigne: String { String(localized: "Aucune règle lue pour ce poisson ici.", table: Self.table, bundle: bundle) }
    var lienAgence: String { String(localized: "Site de l'agence de l'État", table: Self.table, bundle: bundle) }
    var lienSource: String { String(localized: "Ouvrir la source", table: Self.table, bundle: bundle) }

    // Titres, liens, mentions.
    var mention: String {
        String(localized: "Ce résumé ne remplace pas le texte de l'agence : vérifie auprès d'elle avant de pêcher.", table: Self.table, bundle: bundle)
    }
    var etatInconnu: String {
        String(localized: "Choisis l'État pour voir le lien de l'agence.", table: Self.table, bundle: bundle)
    }
    var choisirEtat: String { String(localized: "Choisir l'État", table: Self.table, bundle: bundle) }
    var titreBloc: String { String(localized: "Règles de pêche", table: Self.table, bundle: bundle) }
    var boutonRegles: String { String(localized: "Règles de pêche de l'État", table: Self.table, bundle: bundle) }

    func source(nom: String, date: String) -> String {
        String(localized: "Source : \(nom), lue le \(date)", table: Self.table, bundle: bundle)
    }

    func sourceSansNom(date: String) -> String {
        String(localized: "Source lue le \(date)", table: Self.table, bundle: bundle)
    }

    // MARK: Lignes de règles

    var tailleMinimale: String { String(localized: "Taille minimale", table: Self.table, bundle: bundle) }
    var tailleMaximale: String { String(localized: "Taille maximale", table: Self.table, bundle: bundle) }
    var fenetreProtegee: String { String(localized: "Fenêtre protégée", table: Self.table, bundle: bundle) }
    var limiteJour: String { String(localized: "Limite par jour", table: Self.table, bundle: bundle) }
    var limitePossession: String { String(localized: "Limite de possession", table: Self.table, bundle: bundle) }
    var saison: String { String(localized: "Saison", table: Self.table, bundle: bundle) }
    var fermeture: String { String(localized: "Fermeture", table: Self.table, bundle: bundle) }
    var materiel: String { String(localized: "Matériel", table: Self.table, bundle: bundle) }
    var appats: String { String(localized: "Appâts", table: Self.table, bundle: bundle) }
    var touteLAnnee: String { String(localized: "Toute l'année", table: Self.table, bundle: bundle) }

    func type(_ t: TypeFermeture) -> String {
        switch t {
        case .pecheInterdite: String(localized: "Pêche interdite", table: Self.table, bundle: bundle)
        case .remiseAEauSeulement: String(localized: "Prise et relâche seulement", table: Self.table, bundle: bundle)
        case .especeProtegee: String(localized: "Espèce protégée, à relâcher", table: Self.table, bundle: bundle)
        }
    }

    // MARK: Raisons d'un « interdit » (les motifs d'incertitude ne s'affichent pas : le verdict dit déjà « vérifie »)

    func raison(_ motif: MotifUS, unites: SystemeUnites) -> String? {
        let f = FormatteurUnites(systeme: unites)
        switch motif {
        case .horsSaison:
            return String(localized: "Hors de la période d'ouverture lue", table: Self.table, bundle: bundle)
        case .fermeture(_, let t, let motif):
            switch t {
            case .pecheInterdite: return String(localized: "Pêche interdite ici : \(motif)", table: Self.table, bundle: bundle)
            case .remiseAEauSeulement: return String(localized: "Prise et relâche seulement : \(motif)", table: Self.table, bundle: bundle)
            case .especeProtegee: return String(localized: "Espèce protégée, à relâcher : \(motif)", table: Self.table, bundle: bundle)
            }
        case .sousTailleMinimale(_, let t, let m):
            let mini = f.texte(m, role: .tailleMinimale), mesure = f.texte(t)
            return String(localized: "Sous la taille minimale (\(mini)) : poisson mesuré \(mesure)", table: Self.table, bundle: bundle)
        case .dansFenetreProtegee(_, let t, let w):
            let basse = f.texte(w.basse, role: .debutFenetreProtegee), haute = f.texte(w.haute, role: .finFenetreProtegee)
            let mesure = f.texte(t)
            return String(localized: "Dans la fenêtre protégée de \(basse) à \(haute) : poisson mesuré \(mesure)", table: Self.table, bundle: bundle)
        case .auDessusTailleMaximale(_, let t, let m):
            let maxi = f.texte(m, role: .tailleMaximale), mesure = f.texte(t)
            return String(localized: "Au-dessus de la taille maximale (\(maxi)) : poisson mesuré \(mesure)", table: Self.table, bundle: bundle)
        case .limiteDePriseAtteinte(_, let n):
            return String(localized: "Limite de prise du jour atteinte (\(n))", table: Self.table, bundle: bundle)
        case .limiteDePossessionAtteinte(_, let n):
            return String(localized: "Limite de possession atteinte (\(n))", table: Self.table, bundle: bundle)
        default:
            return nil
        }
    }
}
