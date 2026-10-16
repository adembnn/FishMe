import Foundation

/// Une valeur JSON quelconque (la clé `valeur` d'une règle change de forme selon son type).
enum JSONValeur: Decodable, Sendable, Equatable {
    case nombre(Double)
    case texte(String)
    case booleen(Bool)
    case liste([JSONValeur])
    case objet([String: JSONValeur])
    case nul

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .nul; return }
        if let b = try? c.decode(Bool.self) { self = .booleen(b); return }
        if let d = try? c.decode(Double.self) { self = .nombre(d); return }
        if let s = try? c.decode(String.self) { self = .texte(s); return }
        if let l = try? c.decode([JSONValeur].self) { self = .liste(l); return }
        if let o = try? c.decode([String: JSONValeur].self) { self = .objet(o); return }
        self = .nul
    }

    var nombre: Double? {
        switch self {
        case .nombre(let d): return d
        case .texte(let s): return Double(s)
        default: return nil
        }
    }

    var texte: String? {
        switch self {
        case .texte(let s): return s
        case .nombre(let d): return d == d.rounded() ? String(Int(d)) : String(d)
        default: return nil
        }
    }

    var nombres: [Double] {
        if case .liste(let l) = self { return l.compactMap(\.nombre) }
        return []
    }
}

struct PorteeDonnee: Decodable, Sendable {
    var niveau: String?
    var code: String?
    var eau: String?
    var lieu: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Cle.self)
        niveau = try? c.decodeIfPresent(String.self, forKey: .niveau)
        code = try? c.decodeIfPresent(String.self, forKey: .code)
        eau = try? c.decodeIfPresent(String.self, forKey: .eau)
        // `lieu` est un texte, ou (forme de consigne v2) un objet : seul le texte sert à l'affichage.
        lieu = try? c.decodeIfPresent(String.self, forKey: .lieu)
    }

    enum Cle: String, CodingKey { case niveau, code, eau, lieu }
}

struct TexteDonnee: Decodable, Sendable {
    var id: String
    var titre: String?
    var url: String?
    var luLe: String?

    enum Cle: String, CodingKey { case id, titre, url, luLe = "lu_le" }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Cle.self)
        id = try c.decode(String.self, forKey: .id)
        titre = try? c.decodeIfPresent(String.self, forKey: .titre)
        url = try? c.decodeIfPresent(String.self, forKey: .url)
        luLe = try? c.decodeIfPresent(String.self, forKey: .luLe)
    }
}

/// Ancienne forme d'une source (squelette de D1 et brouillon du 15 oct.) : `source` en ligne dans la règle.
struct SourceEnLigne: Decodable, Sendable {
    var texte: String?
    var url: String?
    var luLe: String?

    enum Cle: String, CodingKey { case texte, url, luLe = "lu_le" }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Cle.self)
        texte = try? c.decodeIfPresent(String.self, forKey: .texte)
        url = try? c.decodeIfPresent(String.self, forKey: .url)
        luLe = try? c.decodeIfPresent(String.self, forKey: .luLe)
    }
}

struct EauDonnee: Decodable, Sendable {
    var cle: String
    var nom: String?
    var code: String?

    enum Cle: String, CodingKey { case cle, nom, code }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Cle.self)
        cle = try c.decode(String.self, forKey: .cle)
        nom = try? c.decodeIfPresent(String.self, forKey: .nom)
        code = try? c.decodeIfPresent(String.self, forKey: .code)
    }
}

struct RegleDonnee: Decodable, Sendable {
    var id: String
    var type: String
    var especes: [String]
    /// « 1 », « 2 » ou « toutes ».
    var categorie: String
    var portee: PorteeDonnee?
    var du: String?
    var au: String?
    var valeur: [String: JSONValeur]
    var phrase: String
    var textes: [String]
    var source: SourceEnLigne?
    var citation: String?
    /// Citation propre à chaque texte (id du texte → passage), quand plusieurs sources se contredisent.
    var citations: [String: String]?
    var statut: String?
    var expireLe: String?
    var remplace: String?

    enum Cle: String, CodingKey {
        case id, type, especes, categorie, portee, du, au, valeur, phrase, textes, source, citation, citations, statut
        case expireLe = "expire_le", remplace
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Cle.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(String.self, forKey: .type)
        var especesLues = ((try? c.decodeIfPresent([JSONValeur].self, forKey: .especes)) ?? []).compactMap(\.texte)
        categorie = (try? c.decodeIfPresent(JSONValeur.self, forKey: .categorie))?.texte ?? "toutes"
        portee = try? c.decodeIfPresent(PorteeDonnee.self, forKey: .portee)
        du = try? c.decodeIfPresent(String.self, forKey: .du)
        au = try? c.decodeIfPresent(String.self, forKey: .au)
        valeur = (try? c.decodeIfPresent([String: JSONValeur].self, forKey: .valeur)) ?? [:]
        phrase = PhrasesNeutres.neutre((try? c.decodeIfPresent(String.self, forKey: .phrase)) ?? "")
        textes = (try? c.decodeIfPresent([String].self, forKey: .textes)) ?? []
        source = try? c.decodeIfPresent(SourceEnLigne.self, forKey: .source)
        citation = try? c.decodeIfPresent(String.self, forKey: .citation)
        citations = try? c.decodeIfPresent([String: String].self, forKey: .citations)
        statut = try? c.decodeIfPresent(String.self, forKey: .statut)
        expireLe = try? c.decodeIfPresent(String.self, forKey: .expireLe)
        remplace = try? c.decodeIfPresent(String.self, forKey: .remplace)
        // Forme réelle de D1 : une règle d'interdiction ou d'introduction qui vise des espèces sans code Sandre (écrevisses, migrateurs,
        // anguille argentée, perche soleil...) a `especes: []` et nomme ses espèces dans `valeur.texte`. Sans cette lecture, elle
        // s'appliquerait à toutes les espèces (un brochet serait « relâche-la » à cause de l'interdiction des écrevisses).
        if especesLues.isEmpty, type == "interdit" || type == "remise_eau" {
            especesLues = RegleDonnee.nomsVises(texte: valeur["texte"]?.texte ?? "", id: id).map { "nom:" + RegleDonnee.cleNom($0) }
        }
        especes = especesLues
    }

    /// Noms d'espèces cités dans `valeur.texte` : listes `especes noms : [...]` et `introduction interdite : [...]`, et l'anguille argentée et la civelle.
    static func nomsVises(texte: String, id: String) -> [String] {
        var noms: [String] = []
        for marqueur in ["especes noms : [", "introduction interdite : ["] {
            guard let debut = texte.range(of: marqueur), let fin = texte[debut.upperBound...].firstIndex(of: "]") else { continue }
            let liste = texte[debut.upperBound..<fin]
            noms += liste.split(separator: ",").map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"")) }.filter { !$0.isEmpty }
        }
        if noms.isEmpty, texte.lowercased().contains("anguille argent") { noms = ["anguille argentée", "civelle"] }
        return noms
    }

    /// Clé de comparaison d'un nom d'espèce : sans accent ni article, séparée par des espaces (« Écrevisse à pattes blanches » comme `ecrevisse-pattes-blanches`).
    static func cleNom(_ s: String) -> String {
        let sansAccent = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR")).lowercased()
        let mots = sansAccent.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        return mots.filter { !["a", "de", "des", "du", "la", "le", "les", "l", "d"].contains($0) }.joined(separator: " ")
    }
}

struct AVerifierDonnee: Decodable, Sendable {
    var type: String
    var especes: [String]
    var categorie: String
    var eau: String?
    var textes: [String]

    enum Cle: String, CodingKey { case type, especes, categorie, eau, textes }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Cle.self)
        type = (try? c.decodeIfPresent(String.self, forKey: .type)) ?? "autre"
        especes = ((try? c.decodeIfPresent([JSONValeur].self, forKey: .especes)) ?? []).compactMap(\.texte)
        categorie = (try? c.decodeIfPresent(JSONValeur.self, forKey: .categorie))?.texte ?? "toutes"
        eau = try? c.decodeIfPresent(String.self, forKey: .eau)
        textes = (try? c.decodeIfPresent([String].self, forKey: .textes)) ?? []
    }
}

/// Un élément de liste que le décodeur peut sauter sans faire échouer le fichier (compté dans `illisibles`).
private struct Tolerant<T: Decodable>: Decodable {
    var valeur: T?
    init(from decoder: Decoder) throws { valeur = try? T(from: decoder) }
}

/// `regles/<code>.json` ou `regles/national.json`.
struct FichierRegles: Decodable, Sendable {
    var version: String
    var departement: String
    /// `complet` ou `partiel` ; absent : `partiel` (le plus prudent).
    var niveau: String
    var textes: [String: TexteDonnee]
    var eaux: [EauDonnee]
    var regles: [RegleDonnee]
    var aVerifier: [AVerifierDonnee]
    /// Règles que le décodeur n'a pas su lire : la ligne du département dit « vérifie l'arrêté ».
    var illisibles: Int

    enum Cle: String, CodingKey { case version, departement, niveau, textes, eaux, regles, aVerifier = "a_verifier" }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Cle.self)
        version = (try? c.decodeIfPresent(JSONValeur.self, forKey: .version))?.texte ?? ""
        departement = (try? c.decodeIfPresent(JSONValeur.self, forKey: .departement))?.texte ?? ""
        niveau = (try? c.decodeIfPresent(String.self, forKey: .niveau)) ?? "partiel"
        let liste = (try? c.decodeIfPresent([Tolerant<TexteDonnee>].self, forKey: .textes)) ?? []
        textes = Dictionary(liste.compactMap(\.valeur).map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        eaux = ((try? c.decodeIfPresent([Tolerant<EauDonnee>].self, forKey: .eaux)) ?? []).compactMap(\.valeur)
        let toutes = try c.decode([Tolerant<RegleDonnee>].self, forKey: .regles)
        regles = toutes.compactMap(\.valeur)
        let av = (try? c.decodeIfPresent([Tolerant<AVerifierDonnee>].self, forKey: .aVerifier)) ?? []
        aVerifier = av.compactMap(\.valeur)
        illisibles = (toutes.count - regles.count) + (av.count - aVerifier.count)
    }
}

/// `regles/index.json`.
struct IndexRegles: Sendable {
    struct Entree: Sendable {
        var niveau: String?
        var confirmees: Int?
        var aVerifier: Int?
        var expireMin: String?
    }

    var version: String
    var departements: [String: Entree]

    static func decoder(_ donnees: Data) -> IndexRegles? {
        guard let racine = (try? JSONSerialization.jsonObject(with: donnees)) as? [String: Any] else { return nil }
        var sortie: [String: Entree] = [:]
        if let deps = racine["departements"] as? [String: Any] {
            for (code, v) in deps {
                guard let e = v as? [String: Any] else { continue }
                sortie[code] = Entree(niveau: e["niveau"] as? String, confirmees: (e["confirmees"] as? NSNumber)?.intValue,
                                      aVerifier: (e["a_verifier"] as? NSNumber)?.intValue, expireMin: e["expire_min"] as? String)
            }
        }
        return IndexRegles(version: (racine["version"] as? String) ?? "", departements: sortie)
    }
}
