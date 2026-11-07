import Foundation

/// Erreurs explicites du chargement des fichiers `regles-us/` : chacune dit quel fichier, quelle règle et quel champ posent problème.
/// Un fichier refusé n'apporte aucune règle (jamais de règle à moitié lue).
public enum ErreurReglesUS: Error, Equatable, Sendable, CustomStringConvertible {
    case fichierAbsent(String)
    case jsonIllisible(fichier: String, detail: String)
    case formatNonSupporte(fichier: String, trouve: Int?)
    /// Un fichier `"fixture": true` n'entre jamais dans l'app : seuls les tests peuvent le charger.
    case fichierFixtureHorsTests(fichier: String)
    case etatInattendu(fichier: String, attendu: String, trouve: String?)
    case champManquant(fichier: String, contexte: String, champ: String)
    case valeurInvalide(fichier: String, contexte: String, champ: String, detail: String)
    case sourceNonHttps(fichier: String, contexte: String, url: String)
    case citationTropLongue(fichier: String, contexte: String, longueur: Int)
    case statutManquant(fichier: String, contexte: String)
    case regleSansContenu(fichier: String, regle: String)
    case identifiantEnDouble(fichier: String, id: String)
    case porteeInconnue(fichier: String, contexte: String, portee: String)
    case arbreInvalide(fichier: String, detail: String)
    case sommeDeControleDifferente(fichier: String)

    public var description: String {
        switch self {
        case .fichierAbsent(let f): "Fichier absent : \(f)"
        case .jsonIllisible(let f, let d): "\(f) : JSON illisible (\(d))"
        case .formatNonSupporte(let f, let t): "\(f) : version de format non gérée (\(t.map(String.init) ?? "absente"))"
        case .fichierFixtureHorsTests(let f): "\(f) : fichier FIXTURE refusé hors des tests"
        case .etatInattendu(let f, let a, let t): "\(f) : État attendu \(a), trouvé \(t ?? "aucun")"
        case .champManquant(let f, let c, let ch): "\(f) : \(c) sans « \(ch) »"
        case .valeurInvalide(let f, let c, let ch, let d): "\(f) : \(c), « \(ch) » invalide (\(d))"
        case .sourceNonHttps(let f, let c, let u): "\(f) : \(c), source non https (\(u))"
        case .citationTropLongue(let f, let c, let n): "\(f) : \(c), citation de \(n) caractères (200 au plus)"
        case .statutManquant(let f, let c): "\(f) : \(c) sans statut de relecture"
        case .regleSansContenu(let f, let r): "\(f) : règle \(r) sans aucune contrainte"
        case .identifiantEnDouble(let f, let i): "\(f) : identifiant en double (\(i))"
        case .porteeInconnue(let f, let c, let p): "\(f) : \(c), portée « \(p) » absente des juridictions du fichier"
        case .arbreInvalide(let f, let d): "\(f) : hiérarchie des juridictions incohérente (\(d))"
        case .sommeDeControleDifferente(let f): "\(f) : somme de contrôle différente de celle de l'index"
        }
    }
}

/// Ce que contient un fichier `regles-us/<USPS>.json` une fois validé.
public struct EtatReglesUS: Sendable, Equatable {
    public let code: CodeEtat
    public let version: String
    public let genereLe: JourCivil
    /// Niveau annoncé par le fichier (2 ou 3).
    public let couverture: CouvertureUS
    public let juridictions: [Juridiction]
    public let exigences: [ExigenceUS]
    public let regles: [RegleUS]
}

/// Ce que contient `regles-us/index.json`.
public struct IndexReglesUS: Sendable, Equatable {
    public struct Entree: Sendable, Equatable {
        public let couverture: CouvertureUS
        public let nombreRegles: Int?
        public let sha256: String?
        public let expireMin: JourCivil?
    }
    public struct EntreeNiveau1: Sendable, Equatable {
        public let fichier: String
        /// Marque `etat-de-la-donnee` de la copie embarquée (ex. « non vérifié sauf NY, TX, VA »).
        public let etatDeLaDonnee: String
        public let date: JourCivil
        public let sha256: String?
    }
    public let format: Int
    public let version: String
    public let date: JourCivil
    public let etats: [CodeEtat: Entree]
    public let niveau1: EntreeNiveau1?
}

/// Résultat d'un chargement complet : ce qui a passé la validation, et, par État, pourquoi le reste a été refusé.
public struct ContenuReglesUS: Sendable, Equatable {
    public let etats: [EtatReglesUS]
    public let erreurs: [CodeEtat: ErreurReglesUS]

    public var regles: [RegleUS] { etats.flatMap(\.regles) }
    public var juridictions: [Juridiction] { etats.flatMap(\.juridictions) }
    public var exigences: [ExigenceUS] { etats.flatMap(\.exigences) }

    public func arbre(avec supplementaires: [Juridiction] = []) throws -> ArbreJuridictions {
        try ArbreJuridictions(juridictions + supplementaires)
    }

    /// Le moteur du verdict, alimenté par les règles chargées.
    public func moteur(parametres: ParametresMoteurUS = ParametresMoteurUS()) throws -> MoteurUS {
        MoteurUS(arbre: try arbre(), regles: regles, exigences: exigences, parametres: parametres)
    }
}

/// Lit `regles-us/index.json` et `regles-us/<USPS>.json` et les valide. Même esprit que `ChargeurRegles` (France) : une source de
/// fichiers (paquet, dossier, mémoire), et des fichiers lus à la demande. Format documenté dans outils/us/format/LISEZMOI.md.
public struct ChargementReglesUS: Sendable {
    public static let versionFormat = 1
    public static let citationMax = 200

    private let source: any SourceFichiersRegles
    private let autoriseFixture: Bool

    /// Production : un fichier FIXTURE est toujours refusé.
    public init(source: any SourceFichiersRegles) {
        self.source = source
        self.autoriseFixture = false
    }

    /// Réservé aux tests (`@testable`).
    init(source: any SourceFichiersRegles, autoriseFixture: Bool) {
        self.source = source
        self.autoriseFixture = autoriseFixture
    }

    /// Le dossier `regles-us/` embarqué dans le paquet (nécessite `.copy("Resources/regles-us")` dans Package.swift).
    public static func embarque() -> ChargementReglesUS {
        ChargementReglesUS(source: SourceDossier(dossier: dossierEmbarque))
    }

    public static var dossierEmbarque: URL? { Bundle.module.url(forResource: "regles-us", withExtension: nil) }

    // MARK: Index

    public func index() throws -> IndexReglesUS {
        guard let donnees = source.contenu(nom: "index") else { throw ErreurReglesUS.fichierAbsent("index.json") }
        return try Self.lireIndex(donnees)
    }

    // MARK: États

    /// Les États à charger : ceux de l'index s'il existe, sinon les fichiers dont le nom est un code USPS.
    public func codesPresents() -> [CodeEtat] {
        if let idx = try? index() { return idx.etats.keys.sorted() }
        return source.codesDepartements().compactMap { n in CodeEtat(rawValue: n).flatMap { $0.rawValue == n ? $0 : nil } }.sorted()
    }

    public func etat(_ code: CodeEtat) throws -> EtatReglesUS {
        let nom = "\(code.rawValue).json"
        guard let donnees = source.contenu(nom: code.rawValue) else { throw ErreurReglesUS.fichierAbsent(nom) }
        let attendu = (try? index())?.etats[code]?.sha256
        return try Self.lire(donnees, fichier: nom, attendu: code, autoriseFixture: autoriseFixture, sha256Attendu: attendu)
    }

    /// Charge tous les États présents. Un fichier refusé n'empêche pas les autres : son erreur est rendue dans `erreurs`.
    public func tout() -> ContenuReglesUS {
        var etats: [EtatReglesUS] = []
        var erreurs: [CodeEtat: ErreurReglesUS] = [:]
        for code in codesPresents() {
            do { etats.append(try etat(code)) }
            catch let e as ErreurReglesUS { erreurs[code] = e }
            catch { erreurs[code] = .jsonIllisible(fichier: "\(code.rawValue).json", detail: "\(error)") }
        }
        return ContenuReglesUS(etats: etats, erreurs: erreurs)
    }

    // MARK: Décodage

    private static func decodeur() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }

    private static func decoder<T: Decodable>(_ type: T.Type, _ donnees: Data, fichier: String) throws -> T {
        do { return try decodeur().decode(type, from: donnees) }
        catch let e as DecodingError {
            let chemin: [CodingKey]
            let raison: String
            switch e {
            case .typeMismatch(_, let c): chemin = c.codingPath; raison = "type inattendu"
            case .valueNotFound(_, let c): chemin = c.codingPath; raison = "valeur nulle"
            case .keyNotFound(let k, let c): chemin = c.codingPath + [k]; raison = "clé absente"
            case .dataCorrupted(let c): chemin = c.codingPath; raison = c.debugDescription
            @unknown default: chemin = []; raison = "illisible"
            }
            let ou = chemin.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }.joined()
            throw ErreurReglesUS.jsonIllisible(fichier: fichier, detail: "\(raison) en \(ou.isEmpty ? "racine" : ou)")
        }
    }

    static func sha256Hex(_ donnees: Data) -> String { SommeDeControle.sha256(donnees) }

    static func lireIndex(_ donnees: Data) throws -> IndexReglesUS {
        let f = "index.json"
        let dto = try decoder(IndexDTO.self, donnees, fichier: f)
        guard dto.format == versionFormat else { throw ErreurReglesUS.formatNonSupporte(fichier: f, trouve: dto.format) }
        guard let version = dto.version, !version.isEmpty else { throw ErreurReglesUS.champManquant(fichier: f, contexte: "index", champ: "version") }
        let date = try jour(dto.date, fichier: f, contexte: "index", champ: "date")
        var etats: [CodeEtat: IndexReglesUS.Entree] = [:]
        for (cle, e) in dto.etats ?? [:] {
            guard let code = CodeEtat(rawValue: cle), code.rawValue == cle else {
                throw ErreurReglesUS.valeurInvalide(fichier: f, contexte: "etats", champ: cle, detail: "code USPS inconnu")
            }
            guard let niv = e.niveau.flatMap(CouvertureUS.init(rawValue:)), niv >= .niveau2 else {
                throw ErreurReglesUS.valeurInvalide(fichier: f, contexte: "etats.\(cle)", champ: "niveau", detail: "2 ou 3 attendu")
            }
            let expire = try e.expireMin.map { try jour($0, fichier: f, contexte: "etats.\(cle)", champ: "expire_min") }
            etats[code] = .init(couverture: niv, nombreRegles: e.regles, sha256: e.sha256, expireMin: expire)
        }
        var n1: IndexReglesUS.EntreeNiveau1?
        if let n = dto.niveau1 {
            guard let fichier = n.fichier, !fichier.isEmpty else { throw ErreurReglesUS.champManquant(fichier: f, contexte: "niveau1", champ: "fichier") }
            guard let marque = n.etatDeLaDonnee, !marque.isEmpty else { throw ErreurReglesUS.champManquant(fichier: f, contexte: "niveau1", champ: "etat_de_la_donnee") }
            n1 = .init(fichier: fichier, etatDeLaDonnee: marque, date: try jour(n.date, fichier: f, contexte: "niveau1", champ: "date"), sha256: n.sha256)
        }
        return IndexReglesUS(format: dto.format ?? versionFormat, version: version, date: date, etats: etats, niveau1: n1)
    }

    static func jour(_ s: String?, fichier: String, contexte: String, champ: String) throws -> JourCivil {
        guard let s else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: contexte, champ: champ) }
        guard let j = JourCivil(iso: s) else { throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: contexte, champ: champ, detail: "AAAA-MM-JJ attendu : \(s)") }
        return j
    }

    private static func moisJour(_ s: String, fichier: String, contexte: String, champ: String) throws -> MoisJour {
        let p = s.split(separator: "-", omittingEmptySubsequences: false)
        guard p.count == 2, p[0].count == 2, p[1].count == 2, let m = Int(p[0]), let j = Int(p[1]), let mj = MoisJour(mois: m, jour: j) else {
            throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: contexte, champ: champ, detail: "MM-JJ attendu : \(s)")
        }
        return mj
    }

    private static func periode(du: String?, au: String?, fichier: String, contexte: String) throws -> PeriodeAnnuelle? {
        switch (du, au) {
        case (nil, nil): return nil
        case (let d?, let a?):
            return PeriodeAnnuelle(debut: try moisJour(d, fichier: fichier, contexte: contexte, champ: "du"),
                                   fin: try moisJour(a, fichier: fichier, contexte: contexte, champ: "au"))
        default:
            throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: contexte, champ: "du/au", detail: "les deux bornes ou aucune")
        }
    }

    private static func longueur(_ l: LongueurDTO?, fichier: String, contexte: String, champ: String) throws -> Longueur? {
        guard let l else { return nil }
        let donnees = [l.pouces.map { ("pouces", $0) }, l.cm.map { ("cm", $0) }, l.mm.map { ("mm", $0) }].compactMap { $0 }
        guard donnees.count == 1, let (unite, v) = donnees.first, v.isFinite, v > 0 else {
            throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: contexte, champ: champ, detail: "une seule unité (pouces, cm ou mm), valeur positive")
        }
        switch unite {
        case "pouces": return .pouces(v)
        case "cm": return .centimetres(v)
        default: return Longueur(millimetres: v)
        }
    }

    /// Source d'une règle ou d'une exigence : https, date, citation (obligatoire pour une règle, 3 à 200 caractères).
    private static func source(_ s: SourceDTO?, fichier: String, contexte: String, citationObligatoire: Bool) throws -> SourceUS {
        guard let s else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: contexte, champ: "source") }
        guard let url = s.url, !url.isEmpty else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: contexte, champ: "source.url") }
        guard let u = URL(string: url), u.scheme?.lowercased() == "https", let h = u.host, !h.isEmpty else {
            throw ErreurReglesUS.sourceNonHttps(fichier: fichier, contexte: contexte, url: url)
        }
        let date = try jour(s.date, fichier: fichier, contexte: contexte, champ: "source.date")
        let citation = s.citation?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let c = citation, c.count > citationMax { throw ErreurReglesUS.citationTropLongue(fichier: fichier, contexte: contexte, longueur: c.count) }
        if citationObligatoire, (citation?.count ?? 0) < 3 { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: contexte, champ: "source.citation") }
        guard let src = SourceUS(url: url, dateLecture: date, edition: s.edition, citation: citation?.isEmpty == true ? nil : citation) else {
            throw ErreurReglesUS.sourceNonHttps(fichier: fichier, contexte: contexte, url: url)
        }
        return src
    }

    private static func statut(_ s: String?, fichier: String, contexte: String) throws -> StatutRelecture {
        guard let s, !s.isEmpty else { throw ErreurReglesUS.statutManquant(fichier: fichier, contexte: contexte) }
        switch s {
        case "non_relue": return .nonRelue
        case "double_lecture_confirmee": return .doubleLectureConfirmee
        case "lectures_divergentes": return .lecturesDivergentes
        case "relue_par_personne": return .relueParPersonne
        default: throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: contexte, champ: "statut", detail: "valeur inconnue : \(s)")
        }
    }

    static func lire(_ donnees: Data, fichier: String, attendu: CodeEtat?, autoriseFixture: Bool, sha256Attendu: String? = nil) throws -> EtatReglesUS {
        if let attendu256 = sha256Attendu, attendu256.lowercased() != sha256Hex(donnees) {
            throw ErreurReglesUS.sommeDeControleDifferente(fichier: fichier)
        }
        let dto = try decoder(FichierDTO.self, donnees, fichier: fichier)
        guard dto.format == versionFormat else { throw ErreurReglesUS.formatNonSupporte(fichier: fichier, trouve: dto.format) }
        if dto.fixture == true, !autoriseFixture { throw ErreurReglesUS.fichierFixtureHorsTests(fichier: fichier) }
        guard let brut = dto.etat, let code = CodeEtat(rawValue: brut), code.rawValue == brut else {
            throw ErreurReglesUS.etatInattendu(fichier: fichier, attendu: attendu?.rawValue ?? "un code USPS", trouve: dto.etat)
        }
        if let attendu, attendu != code { throw ErreurReglesUS.etatInattendu(fichier: fichier, attendu: attendu.rawValue, trouve: brut) }
        guard let version = dto.version, !version.isEmpty else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: "fichier", champ: "version") }
        let genere = try jour(dto.genereLe, fichier: fichier, contexte: "fichier", champ: "genere_le")
        guard let niv = dto.couverture.flatMap(CouvertureUS.init(rawValue:)), niv >= .niveau2 else {
            throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: "fichier", champ: "couverture", detail: "2 ou 3 attendu")
        }
        guard let nomEtat = dto.nomEtat, !nomEtat.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ErreurReglesUS.champManquant(fichier: fichier, contexte: "fichier", champ: "nom_etat")
        }

        // Juridictions : l'État d'abord, puis les niveaux plus fins.
        let racine = IdJuridiction.etat(code)
        var juridictions: [Juridiction] = []
        guard let etatJ = Juridiction.etat(code, nom: nomEtat, lienAgence: try lien(dto.lienAgence, fichier: fichier, contexte: "fichier")) else {
            throw ErreurReglesUS.arbreInvalide(fichier: fichier, detail: "État \(code.rawValue)")
        }
        juridictions.append(etatJ)
        for (i, j) in (dto.juridictions ?? []).enumerated() {
            let ctx = "juridiction[\(i)]"
            guard let idBrut = j.id, let id = IdJuridiction(rawValue: idBrut) else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: ctx, champ: "id") }
            guard let nom = j.nom else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: ctx, champ: "nom") }
            let niveau: NiveauJuridiction
            switch j.niveau {
            case "zone": niveau = .zone
            case "plan_eau": niveau = .planDeau
            case "troncon": niveau = .troncon
            default: throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "niveau", detail: "zone, plan_eau ou troncon attendu")
            }
            var parent = racine
            if let p = j.parent {
                guard let pid = IdJuridiction(rawValue: p) else { throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "parent", detail: p) }
                parent = pid
            }
            var alertes: Set<AlerteTerrain> = []
            for a in j.alertes ?? [] {
                guard let al = alerte(a) else { throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "alertes", detail: "inconnue : \(a)") }
                alertes.insert(al)
            }
            guard let jur = Juridiction(id: id, niveau: niveau, nom: nom, etat: code, parent: parent, huc8: j.huc8, alertes: alertes,
                                        lienAgence: try lien(j.lienAgence, fichier: fichier, contexte: ctx)) else {
                throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "id/huc8/nom", detail: "juridiction incohérente")
            }
            juridictions.append(jur)
        }
        do { _ = try ArbreJuridictions(juridictions) }
        catch { throw ErreurReglesUS.arbreInvalide(fichier: fichier, detail: "\(error)") }
        let connues = Set(juridictions.map(\.id))

        // Règles.
        var ids = Set<String>()
        var regles: [RegleUS] = []
        for (i, r) in (dto.regles ?? []).enumerated() {
            guard let id = r.id, !id.isEmpty else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: "regle[\(i)]", champ: "id") }
            let ctx = "règle \(id)"
            guard ids.insert("r:" + id).inserted else { throw ErreurReglesUS.identifiantEnDouble(fichier: fichier, id: id) }
            guard let pb = r.portee, let portee = IdJuridiction(rawValue: pb) else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: ctx, champ: "portee") }
            guard connues.contains(portee) else { throw ErreurReglesUS.porteeInconnue(fichier: fichier, contexte: ctx, portee: pb) }
            if let e = r.espece, e.trimmingCharacters(in: .whitespaces).isEmpty {
                throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "espece", detail: "vide (omettre le champ pour « toutes espèces »)")
            }
            let src = try source(r.source, fichier: fichier, contexte: ctx, citationObligatoire: true)
            let st = try statut(r.statut, fichier: fichier, contexte: ctx)
            let cov: CouvertureUS
            if let c = r.couverture {
                guard let v = CouvertureUS(rawValue: c), v >= .niveau2 else {
                    throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "couverture", detail: "2 ou 3 attendu")
                }
                cov = v
            } else { cov = niv }
            let saison = try periode(du: r.saison?.du, au: r.saison?.au, fichier: fichier, contexte: ctx + " saison")
            var tailles = TaillesUS()
            if let t = r.tailles {
                tailles.minimale = try longueur(t.minimale, fichier: fichier, contexte: ctx, champ: "tailles.minimale")
                tailles.maximale = try longueur(t.maximale, fichier: fichier, contexte: ctx, champ: "tailles.maximale")
                if let w = t.fenetre {
                    guard let b = try longueur(w.basse, fichier: fichier, contexte: ctx, champ: "tailles.fenetre.basse"),
                          let h = try longueur(w.haute, fichier: fichier, contexte: ctx, champ: "tailles.fenetre.haute"),
                          let fen = FenetreProtegee(basse: b, haute: h) else {
                        throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "tailles.fenetre", detail: "basse < haute attendu")
                    }
                    tailles.fenetre = fen
                }
            }
            var limites = LimitesUS()
            for (champ, v) in [("prise", r.limites?.prise), ("possession", r.limites?.possession)] {
                if let v, v < 0 { throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "limites.\(champ)", detail: "négatif") }
            }
            limites.prise = r.limites?.prise
            limites.possession = r.limites?.possession
            var fermetures: [FermetureUS] = []
            for (k, f) in (r.fermetures ?? []).enumerated() {
                let fctx = "\(ctx) fermeture[\(k)]"
                let type: TypeFermeture
                switch f.type {
                case "peche_interdite": type = .pecheInterdite
                case "remise_a_eau_seulement": type = .remiseAEauSeulement
                case "espece_protegee": type = .especeProtegee
                default: throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: fctx, champ: "type", detail: "valeur inconnue : \(f.type ?? "absente")")
                }
                guard let motif = f.motif, !motif.isEmpty else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: fctx, champ: "motif") }
                fermetures.append(FermetureUS(type: type, periode: try periode(du: f.du, au: f.au, fichier: fichier, contexte: fctx), motif: motif))
            }
            var age: ConditionAge?
            if let a = r.age {
                if let lo = a.min, let hi = a.max, lo > hi { throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "age", detail: "min > max") }
                if (a.min ?? 0) < 0 { throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "age", detail: "négatif") }
                age = ConditionAge(ageMin: a.min, ageMax: a.max)
            }
            let jusqua = try r.valideJusqua.map { try jour($0, fichier: fichier, contexte: ctx, champ: "valide_jusqua") }
            let regle = RegleUS(id: id, portee: portee, espece: r.espece, saison: saison, tailles: tailles, limites: limites,
                                engins: r.engins ?? [], appats: r.appats ?? [], fermetures: fermetures, age: age, source: src,
                                couverture: cov, statut: st, valideJusqua: jusqua)
            guard !regle.familles.isEmpty else { throw ErreurReglesUS.regleSansContenu(fichier: fichier, regle: id) }
            regles.append(regle)
        }

        // Exigences (permis, timbres).
        var exigences: [ExigenceUS] = []
        for (i, e) in (dto.exigences ?? []).enumerated() {
            guard let id = e.id, !id.isEmpty else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: "exigence[\(i)]", champ: "id") }
            let ctx = "exigence \(id)"
            guard ids.insert("e:" + id).inserted else { throw ErreurReglesUS.identifiantEnDouble(fichier: fichier, id: id) }
            guard let pb = e.portee, let portee = IdJuridiction(rawValue: pb) else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: ctx, champ: "portee") }
            guard connues.contains(portee) else { throw ErreurReglesUS.porteeInconnue(fichier: fichier, contexte: ctx, portee: pb) }
            let type: TypeExigence
            switch e.type {
            case "permis": type = .permis
            case "timbre": type = .timbre
            case "permis_tribal": type = .permisTribal
            default: throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "type", detail: "valeur inconnue : \(e.type ?? "absente")")
            }
            guard let nom = e.nom, !nom.isEmpty else { throw ErreurReglesUS.champManquant(fichier: fichier, contexte: ctx, champ: "nom") }
            if let p = e.prixDollars, p < 0 { throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "prix_dollars", detail: "négatif") }
            if let m = e.exempteMoinsDe, m < 0 { throw ErreurReglesUS.valeurInvalide(fichier: fichier, contexte: ctx, champ: "exempte_moins_de", detail: "négatif") }
            exigences.append(ExigenceUS(id: id, portee: portee, type: type, nom: nom, prixDollars: e.prixDollars, exempteMoinsDe: e.exempteMoinsDe,
                                        source: try source(e.source, fichier: fichier, contexte: ctx, citationObligatoire: false),
                                        statut: try statut(e.statut, fichier: fichier, contexte: ctx)))
        }
        return EtatReglesUS(code: code, version: version, genereLe: genere, couverture: niv, juridictions: juridictions, exigences: exigences, regles: regles)
    }

    private static func lien(_ s: String?, fichier: String, contexte: String) throws -> URL? {
        guard let s else { return nil }
        guard let u = URL(string: s), u.scheme?.lowercased() == "https", u.host?.isEmpty == false else {
            throw ErreurReglesUS.sourceNonHttps(fichier: fichier, contexte: contexte + " lien_agence", url: s)
        }
        return u
    }

    private static func alerte(_ s: String) -> AlerteTerrain? {
        switch s {
        case "reserve_tribale": .reserveTribale
        case "refuge_federal": .refugeFederal
        case "parc_national": .parcNational
        case "eau_frontaliere": .eauFrontaliere
        case "espece_listee_esa": .especeListeeESA
        default: nil
        }
    }
}

// MARK: DTO (décodage tolérant : les clés inconnues sont ignorées, chaque champ requis est contrôlé ensuite avec une erreur nommée)

private struct IndexDTO: Decodable {
    struct Etat: Decodable { let niveau: Int?; let regles: Int?; let sha256: String?; let expireMin: String? }
    struct Niveau1: Decodable { let fichier: String?; let etatDeLaDonnee: String?; let date: String?; let sha256: String? }
    let format: Int?
    let version: String?
    let date: String?
    let etats: [String: Etat]?
    let niveau1: Niveau1?
}

private struct SourceDTO: Decodable { let url: String?; let date: String?; let edition: String?; let citation: String? }
private struct LongueurDTO: Decodable { let pouces: Double?; let cm: Double?; let mm: Double? }
private struct SaisonDTO: Decodable { let du: String?; let au: String? }
private struct FenetreDTO: Decodable { let basse: LongueurDTO?; let haute: LongueurDTO? }
private struct TaillesDTO: Decodable { let minimale: LongueurDTO?; let maximale: LongueurDTO?; let fenetre: FenetreDTO? }
private struct LimitesDTO: Decodable { let prise: Int?; let possession: Int? }
private struct FermetureDTO: Decodable { let type: String?; let du: String?; let au: String?; let motif: String? }
private struct AgeDTO: Decodable { let min: Int?; let max: Int? }

private struct RegleDTO: Decodable {
    let id: String?
    let portee: String?
    let espece: String?
    let saison: SaisonDTO?
    let tailles: TaillesDTO?
    let limites: LimitesDTO?
    let engins: [String]?
    let appats: [String]?
    let fermetures: [FermetureDTO]?
    let age: AgeDTO?
    let source: SourceDTO?
    let couverture: Int?
    let statut: String?
    let valideJusqua: String?
}

private struct ExigenceDTO: Decodable {
    let id: String?
    let portee: String?
    let type: String?
    let nom: String?
    let prixDollars: Decimal?
    let exempteMoinsDe: Int?
    let source: SourceDTO?
    let statut: String?
}

private struct JuridictionDTO: Decodable {
    let id: String?
    let niveau: String?
    let nom: String?
    let parent: String?
    let huc8: String?
    let alertes: [String]?
    let lienAgence: String?
}

private struct FichierDTO: Decodable {
    let format: Int?
    let fixture: Bool?
    let etat: String?
    let nomEtat: String?
    let lienAgence: String?
    let version: String?
    let genereLe: String?
    let couverture: Int?
    let juridictions: [JuridictionDTO]?
    let exigences: [ExigenceDTO]?
    let regles: [RegleDTO]?
}
