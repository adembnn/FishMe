import Foundation

/// Une ligne de `liens-federations.json`, avec ses champs de relevé (`verifie`, `date_releve`, `note`)
/// que `LiensFederation` ne porte pas.
public struct LienDepartement: Sendable, Equatable {
    public var code: String
    public var nom: String
    public var liens: LiensFederation
    public var verifie: Bool
    public var releveLe: JourCivil?
    public var note: String?

    public init(code: String, nom: String, liens: LiensFederation, verifie: Bool = false,
                releveLe: JourCivil? = nil, note: String? = nil) {
        self.code = code
        self.nom = nom
        self.liens = liens
        self.verifie = verifie
        self.releveLe = releveLe
        self.note = note
    }
}

/// Lecture de `liens-federations.json` avec ses vrais champs : `federation_url`, `carte_peche_url`,
/// `verifie`, `date_releve`, `note`. Lecture propre à N5 : `MoteurCore.lireLiens` ne la remplace pas.
public enum RepertoireFederations {
    /// Un objet `{ "departements": [ { "code": "01", … } ] }` ; les lignes sans code sont ignorées.
    public static func lire(_ donnees: Data) -> [String: LienDepartement] {
        guard let json = try? JSONSerialization.jsonObject(with: donnees) as? [String: Any],
              let liste = json["departements"] as? [[String: Any]] else { return [:] }
        var sortie: [String: LienDepartement] = [:]
        for ligne in liste {
            guard let code = ligne["code"] as? String, !code.isEmpty else { continue }
            let note = (ligne["note"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            sortie[code] = LienDepartement(
                code: code,
                nom: (ligne["nom"] as? String) ?? "",
                liens: LiensFederation(siteFederation: (ligne["federation_url"] as? String).flatMap(nonVide),
                                       pageCarteDePeche: (ligne["carte_peche_url"] as? String).flatMap(nonVide)),
                verifie: (ligne["verifie"] as? Bool) ?? false,
                releveLe: (ligne["date_releve"] as? String).flatMap { JourCivil(iso: $0) },
                note: note)
        }
        return sortie
    }

    /// Le fichier embarqué dans le paquet (vide si le fichier manque).
    public static func embarque() -> [String: LienDepartement] {
        Ressources.donnees("liens-federations").map(lire) ?? [:]
    }

    private static func nonVide(_ texte: String) -> String? {
        texte.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : texte
    }
}

/// Ce que montre l'écran « Ma fédération » : les liens du département du spot, tels que le fichier les donne.
public struct MaFederation: Sendable, Equatable {
    /// Les départements qui partagent la fédération interdépartementale de Paris.
    public static let codesInterdepartementaux: Set<String> = ["75", "92", "93", "94"]
    public static let libelleInterdepartemental = "Fédération de Paris, Hauts-de-Seine, Seine-Saint-Denis et Val-de-Marne"

    /// Repli quand le département n'a aucun lien (identique à `LiensOfficiels.federationNationale` de l'app).
    public static let siteNational: URL = URL(string: "https://www.federationpeche.fr")!
    /// Repli de la page nationale « Toutes nos cartes de pêche ».
    public static let cartesNationalesRepli: URL = URL(string: "https://www.cartedepeche.fr")!

    public let code: String
    public let nomDepartement: String
    public let site: URL?
    public let cartesNationales: URL?
    /// Défaut : le site de la fédération (le fichier ne porte aucun lien d'événements par département).
    public let evenements: URL?
    public let interdepartementale: Bool
    public let notes: [String]
    /// Vrai quand le lien a été vérifié à la date `releveLe`.
    public let verifie: Bool
    public let releveLe: JourCivil?
    /// Vrai si le site affiché est le repli national, faute de lien pour ce département.
    public let siteDeRepli: Bool

    /// - Parameters:
    ///   - liens: les liens du département (`LiensFederation`).
    ///   - code: le code du département (« 94 »).
    ///   - nom: le nom du département, donné par l'appelant ; peut être vide s'il manque.
    ///   - notes: les notes du fichier à montrer à l'écran (ex. 2B).
    public init(liens: LiensFederation, code: String, nom: String, notes: [String] = [],
                verifie: Bool = false, releveLe: JourCivil? = nil) {
        self.code = code
        self.nomDepartement = nom
        let lienSite = liens.siteFederation.flatMap { URL(string: $0) }
        let siteChoisi = lienSite ?? Self.siteNational
        self.site = siteChoisi
        self.siteDeRepli = lienSite == nil
        self.cartesNationales = liens.pageCarteDePeche.flatMap { URL(string: $0) } ?? Self.cartesNationalesRepli
        self.evenements = siteChoisi
        self.interdepartementale = Self.codesInterdepartementaux.contains(code)
        self.notes = notes
        self.verifie = verifie
        self.releveLe = releveLe
    }

    /// Depuis une ligne du fichier ; `nom` prend le nom du fichier s'il est vide.
    public init(ligne: LienDepartement, nom: String? = nil) {
        let nomChoisi = (nom?.isEmpty == false ? nom : nil) ?? ligne.nom
        self.init(liens: ligne.liens, code: ligne.code, nom: nomChoisi,
                  notes: ligne.note.map { [$0] } ?? [], verifie: ligne.verifie, releveLe: ligne.releveLe)
    }

    /// Le département depuis le fichier embarqué ; sans ligne pour ce code, les liens de repli.
    public static func embarquee(code: String, nom: String? = nil) -> MaFederation {
        embarquee(code: code, nom: nom, repertoire: RepertoireFederations.embarque())
    }

    public static func embarquee(code: String, nom: String? = nil, repertoire: [String: LienDepartement]) -> MaFederation {
        if let ligne = repertoire[code] { return MaFederation(ligne: ligne, nom: nom) }
        return MaFederation(liens: LiensFederation(), code: code, nom: nom ?? "")
    }

    /// « Fédération de Paris, Hauts-de-Seine, Seine-Saint-Denis et Val-de-Marne » pour 75/92/93/94,
    /// sinon « Fédération de <nom> » ; `nil` sans nom de département.
    public var libelleFederation: String? {
        if interdepartementale { return Self.libelleInterdepartemental }
        let nom = nomDepartement.trimmingCharacters(in: .whitespacesAndNewlines)
        return nom.isEmpty ? nil : "Fédération de \(nom)"
    }
}
