import Foundation

/// Qui a écrit le prix : l'agence elle-même, un éditeur de livrets (eRegulations…), ou un tiers (revendeur, blog) à traiter avec `[?]`.
public enum QualiteSourceUS: String, Sendable, Hashable, Codable, CaseIterable {
    case officiel
    case editeur
    case tiers
}

/// Comment l'écran doit parler d'un prix. Règle produit : un prix non vérifié n'est jamais présenté comme officiel.
public enum PresentationPrixUS: Sendable, Equatable {
    /// Source officielle ET État relu par un humain : le prix peut être dit tel quel, avec sa source et sa date.
    case officielVerifie
    /// Tout le reste : « environ », avec l'invitation à vérifier sur le site de l'agence.
    case indicatifAVerifier(qualite: QualiteSourceUS)
}

/// Un prix de permis (annuel, adulte, eau douce, en dollars US) avec sa source. Jamais corrigé ici : tel que lu.
public struct PrixPermisUS: Sendable, Equatable {
    public let montant: Decimal
    public let annee: Int
    public let source: URL?
    public let qualite: QualiteSourceUS
    public let note: String?
}

/// Un État au niveau 1 de la couverture : repères sourcés, jamais un verdict.
public struct EtatNiveau1US: Sendable, Equatable {
    public let code: CodeEtat
    public let nom: String
    public let agence: String
    /// Liens https seulement : un lien en http n'est jamais exposé (l'écran n'ouvre que du https).
    public let urlAgence: URL?
    public let urlReglesEauDouce: URL?
    public let urlPermis: URL?
    public let prixResident: PrixPermisUS?
    public let prixNonResident: PrixPermisUS?
    /// Niveau de couverture visé pour cet État (1, 2 ou 3), pas atteint.
    public let niveauVise: CouvertureUS
    /// Vrai seulement si un humain a relu l'État. Faux : aucun prix de cet État n'est présenté comme officiel.
    public let verifie: Bool
    public let dateLecture: JourCivil

    /// `true` si un prix est lu (donc un permis annuel existe), `nil` s'il n'y a aucun prix : « non lu », jamais « pas de permis ».
    public var permisRequis: Bool? { (prixResident != nil || prixNonResident != nil) ? true : nil }

    /// Le lien à montrer pour acheter ou lire le permis : page des permis, sinon page de l'agence.
    public var lienOfficiel: URL? { urlPermis ?? urlAgence }

    public func presentation(de prix: PrixPermisUS) -> PresentationPrixUS {
        (verifie && prix.qualite == .officiel) ? .officielVerifie : .indicatifAVerifier(qualite: prix.qualite)
    }

    /// Phrase de l'écran pour un prix. `officielVerifie` : « 25 $ (source officielle, lu le 2026-11-07) » ;
    /// sinon : « environ 17 $ (tarif 2026, source tierce [?]), vérifie sur le site de l'agence ».
    public func texte(de prix: PrixPermisUS) -> String {
        let somme = Self.montantTexte(prix.montant)
        switch presentation(de: prix) {
        case .officielVerifie:
            return "\(somme) $ (source officielle, lu le \(dateLecture.iso))"
        case .indicatifAVerifier(let q):
            let origine: String
            switch q {
            case .officiel: origine = "page de l'agence, État non relu"
            case .editeur: origine = "source d'un éditeur"
            case .tiers: origine = "source tierce [?]"
            }
            return "environ \(somme) $ (tarif \(prix.annee), \(origine)), vérifie sur le site de l'agence"
        }
    }

    static func montantTexte(_ m: Decimal) -> String {
        var v = m
        var arrondi = Decimal()
        NSDecimalRound(&arrondi, &v, 2, .plain)
        let s = "\(arrondi)"
        return s.replacingOccurrences(of: ".", with: ",")
    }
}

/// Erreurs du chargement de `etats.json`.
public enum ErreurNiveau1US: Error, Equatable, Sendable, CustomStringConvertible {
    case fichierAbsent
    case jsonIllisible(String)
    case champManquant(etat: String, champ: String)
    case valeurInvalide(etat: String, champ: String, detail: String)
    case etatEnDouble(String)
    case sommeDeControleDifferente

    public var description: String {
        switch self {
        case .fichierAbsent: "etats.json absent"
        case .jsonIllisible(let d): "etats.json illisible (\(d))"
        case .champManquant(let e, let c): "etats.json, \(e) : « \(c) » manquant"
        case .valeurInvalide(let e, let c, let d): "etats.json, \(e) : « \(c) » invalide (\(d))"
        case .etatEnDouble(let e): "etats.json : \(e) en double"
        case .sommeDeControleDifferente: "etats.json : somme de contrôle différente de celle de l'index"
        }
    }
}

/// Le niveau 1 : une fiche par État (permis, prix, liens), chargée depuis `regles-us/etats.json` (copie telle quelle du fichier du lot us-etats).
public struct Niveau1US: Sendable, Equatable {
    public let dateLecture: JourCivil
    public let avertissement: String?
    public let etats: [EtatNiveau1US]
    /// Marque `etat-de-la-donnee` portée par l'index (ex. « 3 États vérifiés sur 51 ; prix non vérifiés ailleurs »), si l'index existe.
    public let etatDeLaDonnee: String?

    public subscript(code: CodeEtat) -> EtatNiveau1US? { etats.first { $0.code == code } }

    public var verifies: [EtatNiveau1US] { etats.filter(\.verifie) }

    // MARK: Chargement

    public static func embarque() throws -> Niveau1US {
        try charger(source: SourceDossier(dossier: ChargementReglesUS.dossierEmbarque))
    }

    /// Lit `etats.json` (et l'index pour la marque `etat-de-la-donnee` et la somme de contrôle, s'il existe).
    public static func charger(source: any SourceFichiersRegles) throws -> Niveau1US {
        let index = source.contenu(nom: "index").flatMap { try? ChargementReglesUS.lireIndex($0) }
        let nom = index?.niveau1?.fichier.replacingOccurrences(of: ".json", with: "") ?? "etats"
        guard let donnees = source.contenu(nom: nom) else { throw ErreurNiveau1US.fichierAbsent }
        if let attendu = index?.niveau1?.sha256, attendu.lowercased() != SommeDeControle.sha256(donnees) {
            throw ErreurNiveau1US.sommeDeControleDifferente
        }
        return try decoder(donnees, marque: index?.niveau1?.etatDeLaDonnee)
    }

    public static func decoder(_ donnees: Data, marque: String? = nil) throws -> Niveau1US {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        let dto: FichierN1
        do { dto = try d.decode(FichierN1.self, from: donnees) }
        catch { throw ErreurNiveau1US.jsonIllisible("\(error)") }
        guard let jour = JourCivil(iso: dto.dateLecture ?? "") else {
            throw ErreurNiveau1US.valeurInvalide(etat: "fichier", champ: "date_lecture", detail: dto.dateLecture ?? "absente")
        }
        var vus = Set<CodeEtat>()
        var etats: [EtatNiveau1US] = []
        for e in dto.etats ?? [] {
            guard let usps = e.usps, let code = CodeEtat(rawValue: usps), code.rawValue == usps else {
                throw ErreurNiveau1US.valeurInvalide(etat: e.usps ?? "?", champ: "usps", detail: "code USPS inconnu")
            }
            guard vus.insert(code).inserted else { throw ErreurNiveau1US.etatEnDouble(usps) }
            guard let nom = e.nom, !nom.isEmpty else { throw ErreurNiveau1US.champManquant(etat: usps, champ: "nom") }
            guard let niv = e.niveauVise.flatMap(CouvertureUS.init(rawValue:)) else {
                throw ErreurNiveau1US.valeurInvalide(etat: usps, champ: "niveau_vise", detail: "1, 2 ou 3 attendu")
            }
            guard let verifie = e.verifie else { throw ErreurNiveau1US.champManquant(etat: usps, champ: "verifie") }
            let dj = e.dateLecture.map { JourCivil(iso: $0) } ?? jour
            guard let dateEtat = dj else { throw ErreurNiveau1US.valeurInvalide(etat: usps, champ: "date_lecture", detail: e.dateLecture ?? "") }
            etats.append(EtatNiveau1US(
                code: code, nom: nom, agence: e.agence ?? "[?]",
                urlAgence: lienHttps(e.urlAgence), urlReglesEauDouce: lienHttps(e.urlReglesEauDouce), urlPermis: lienHttps(e.urlPermis),
                prixResident: try prix(e.prixResident, etat: usps, champ: "prix_resident"),
                prixNonResident: try prix(e.prixNonResident, etat: usps, champ: "prix_non_resident"),
                niveauVise: niv, verifie: verifie, dateLecture: dateEtat))
        }
        return Niveau1US(dateLecture: jour, avertissement: dto.avertissement, etats: etats, etatDeLaDonnee: marque)
    }

    private static func lienHttps(_ s: String?) -> URL? {
        guard let s, let u = URL(string: s), u.scheme?.lowercased() == "https", u.host?.isEmpty == false else { return nil }
        return u
    }

    private static func prix(_ p: PrixDTO?, etat: String, champ: String) throws -> PrixPermisUS? {
        guard let p, let montant = p.montant else { return nil }
        guard montant >= 0 else { throw ErreurNiveau1US.valeurInvalide(etat: etat, champ: champ, detail: "montant négatif") }
        if let m = p.monnaie, m != "USD" { throw ErreurNiveau1US.valeurInvalide(etat: etat, champ: champ, detail: "monnaie \(m)") }
        guard let annee = p.annee else { throw ErreurNiveau1US.champManquant(etat: etat, champ: champ + ".annee") }
        // Une qualité absente ou inconnue est traitée comme la moins sûre : jamais promue en « officiel ».
        let q = p.qualite.flatMap(QualiteSourceUS.init(rawValue:)) ?? .tiers
        return PrixPermisUS(montant: montant, annee: annee, source: p.source.flatMap(lienHttps), qualite: q, note: p.note)
    }
}

private struct PrixDTO: Decodable { let montant: Decimal?; let monnaie: String?; let annee: Int?; let source: String?; let qualite: String?; let note: String? }
private struct EtatN1DTO: Decodable {
    let usps: String?
    let nom: String?
    let agence: String?
    let urlAgence: String?
    let urlReglesEauDouce: String?
    let urlPermis: String?
    let prixResident: PrixDTO?
    let prixNonResident: PrixDTO?
    let niveauVise: Int?
    let verifie: Bool?
    let dateLecture: String?
}
private struct FichierN1: Decodable { let dateLecture: String?; let avertissement: String?; let etats: [EtatN1DTO]? }
