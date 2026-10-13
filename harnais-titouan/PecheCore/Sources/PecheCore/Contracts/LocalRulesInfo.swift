// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md.
import Foundation

/// Information « règles locales » : un lien vers la fédération + un texte d'avertissement FIXE.
/// RÈGLE ABSOLUE : ce type ne porte AUCUN verdict (pas de « légal », « autorisé », taille minimale,
/// période d'ouverture, quota, réserve). Ne jamais ajouter de champ de ce genre.
public struct LocalRulesInfo: Codable, Hashable, Sendable {
    /// Texte d'avertissement imposé, identique partout.
    public static let avertissement =
        "Cette application ne connaît pas les règles de pêche locales et ne dit jamais si une prise est légale. Consulte la fédération de pêche de ton département."

    /// Site national de repli quand la fédération du département est inconnue.
    /// ⚠ URL non vérifiée : à confirmer (site de la FNPF) avant livraison.
    public static let fallbackURL =URL(string: "https://www.federationpeche.fr")!

    public let departmentCode: String?
    public let federationNom: String?
    /// URL réellement connue de la fédération, ou nil si inconnue.
    public let federationURL: URL?

    public init(departmentCode: String? = nil, federationNom: String? = nil, federationURL: URL? = nil) {
        self.departmentCode = departmentCode
        self.federationNom = federationNom
        self.federationURL = federationURL
    }

    /// Construit l'info depuis un profil de département.
    public init(profile: DepartmentProfile) {
        self.init(departmentCode: profile.code, federationNom: profile.federationNom, federationURL: profile.federationURL)
    }

    /// Lien à ouvrir : la fédération du département, sinon l'URL nationale.
    public var linkURL: URL { federationURL ?? LocalRulesInfo.fallbackURL }

    public var avertissement: String { LocalRulesInfo.avertissement }

    /// true si on retombe sur l'URL nationale générique.
    public var usesFallbackLink: Bool { federationURL == nil }
}
