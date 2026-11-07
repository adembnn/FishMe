import Core
import Foundation

/// Une ligne de règle : un libellé et sa valeur, déjà écrite dans les unités de la région (pouces et livres aux États-Unis).
nonisolated struct LigneReglesUS: Equatable, Sendable, Hashable {
    let titre: String
    let valeur: String
}

/// Les lignes d'une règle lue, sous le nom de son lieu (l'État, une zone, un plan d'eau).
nonisolated struct GroupeReglesUS: Equatable, Sendable, Hashable {
    let id: String
    let portee: String
    let lignes: [LigneReglesUS]
}

/// Tout ce que le bloc affiche, calculé hors de la vue (donc testable) : le verdict du moteur, ses raisons, les lignes de règles, et
/// toujours le lien de l'agence, la source et sa date quand le lieu est connu.
/// Le verdict est calculé en unités du Système international par `Core` ; seules les valeurs affichées changent avec les unités.
struct PresentationReglesUS: Equatable, Sendable {
    /// Exactement trois valeurs possibles (`VerdictUS`) : « interdit », « à vérifier », « donnée absente ».
    let verdict: VerdictUS
    let etiquette: String
    let phrase: String
    /// Pour « interdit » seulement : pourquoi (une ligne par règle violée).
    let raisons: [String]
    let groupes: [GroupeReglesUS]
    let nomEtat: String?
    let lienAgence: URL?
    let sourceURL: URL?
    /// « Source : Guide to Wisconsin Hook and Line Fishing Regulations, lue le 11/07/2026 », ou nil si aucune source n'est connue.
    let texteSource: String?
    /// Vrai quand l'État du lieu est inconnu : le bloc propose alors de le choisir.
    let etatInconnu: Bool
    let mention: String

    /// La question posée au moteur : une espèce (identifiant de l'app), un lieu, un jour, une taille mesurée ou estimée.
    static func question(espece: String, etat: CodeEtat, juridiction: IdJuridiction? = nil, date: Date, tailleCm: Double?,
                         tailleEstimee: Bool, calendrier: Calendar = .current) -> QuestionUS {
        QuestionUS(espece: espece, juridiction: juridiction ?? .etat(etat), jour: JourCivil(date: date, calendrier: calendrier),
                   taille: tailleCm.map { Longueur.centimetres($0) }, tailleEstimee: tailleEstimee)
    }

    /// Le cas où l'État n'est pas connu : « donnée absente », sans lien (il apparaît dès que le pêcheur choisit l'État).
    static func sansEtat(format: FormatRegion) -> PresentationReglesUS {
        vide(format: format, etatInconnu: true)
    }

    private static func vide(format: FormatRegion, etatInconnu: Bool) -> PresentationReglesUS {
        let t = TextesReglesUS(locale: format.locale)
        return PresentationReglesUS(verdict: .donneeAbsente, etiquette: t.etiquette(.donneeAbsente), phrase: t.phrase(.donneeAbsente),
                                    raisons: [], groupes: [], nomEtat: nil, lienAgence: nil, sourceURL: nil, texteSource: nil,
                                    etatInconnu: etatInconnu, mention: t.mention)
    }

    static func construire(question: QuestionUS, etat: CodeEtat, evaluateur: EvaluateurUS?, format: FormatRegion) -> PresentationReglesUS {
        let t = TextesReglesUS(locale: format.locale)
        // Règles non chargées : « donnée absente », jamais un verdict inventé.
        guard let evaluateur else { return vide(format: format, etatInconnu: false) }
        let r = evaluateur.evaluer(question)
        let n1 = evaluateur.niveau1?[etat]
        let utilisees = r.regles.compactMap { id in evaluateur.moteur.regles.first { $0.id == id } }
        let f = FormatteurUnites(systeme: format.systeme, separateurDecimal: format.region == .france ? "," : ".")
        var groupes: [GroupeReglesUS] = []
        for regle in utilisees {
            let lignes = Self.lignes(de: regle, f: f, format: format, textes: t)
            if lignes.isEmpty { continue }
            let portee = evaluateur.moteur.arbre[regle.portee]?.nom ?? regle.portee.rawValue
            groupes.append(GroupeReglesUS(id: regle.id, portee: portee, lignes: lignes))
        }
        let raisons = r.verdict == .interdit ? r.motifs.compactMap { t.raison($0, unites: format.systeme) } : []

        // Source et date : la règle lue la plus récente, sinon la page de l'agence du niveau 1.
        var url: URL?
        var nom: String?
        var jour: JourCivil?
        if let s = r.sources.first {
            url = s.url
            nom = s.edition
            jour = s.dateLecture
        } else if let n1 {
            url = n1.urlReglesEauDouce ?? n1.urlAgence
            jour = n1.dateLecture
        }
        var texteSource: String?
        if let jour {
            let date = Self.texte(jour, format: format)
            if let nom = nom ?? url?.host { texteSource = t.source(nom: nom, date: date) } else { texteSource = t.sourceSansNom(date: date) }
        }
        return PresentationReglesUS(verdict: r.verdict, etiquette: t.etiquette(r.verdict), phrase: t.phrase(r.verdict), raisons: raisons,
                                    groupes: groupes, nomEtat: n1?.nom, lienAgence: r.lienAgence ?? n1?.lienOfficiel, sourceURL: url,
                                    texteSource: texteSource, etatInconnu: false, mention: t.mention)
    }

    // MARK: Lignes de règles

    private static func lignes(de r: RegleUS, f: FormatteurUnites, format: FormatRegion, textes t: TextesReglesUS) -> [LigneReglesUS] {
        var l: [LigneReglesUS] = []
        func periode(_ p: PeriodeAnnuelle) -> String { "\(texte(p.debut, format: format)) – \(texte(p.fin, format: format))" }
        if let m = r.tailles.minimale { l.append(LigneReglesUS(titre: t.tailleMinimale, valeur: f.texte(m, role: .tailleMinimale))) }
        if let w = r.tailles.fenetre {
            let valeur = "\(f.texte(w.basse, role: .debutFenetreProtegee)) – \(f.texte(w.haute, role: .finFenetreProtegee))"
            l.append(LigneReglesUS(titre: t.fenetreProtegee, valeur: valeur))
        }
        if let m = r.tailles.maximale { l.append(LigneReglesUS(titre: t.tailleMaximale, valeur: f.texte(m, role: .tailleMaximale))) }
        if let n = r.limites.prise { l.append(LigneReglesUS(titre: t.limiteJour, valeur: "\(n)")) }
        if let n = r.limites.possession { l.append(LigneReglesUS(titre: t.limitePossession, valeur: "\(n)")) }
        if let s = r.saison { l.append(LigneReglesUS(titre: t.saison, valeur: periode(s))) }
        for fe in r.fermetures {
            var morceaux = [t.type(fe.type), fe.periode.map(periode) ?? t.touteLAnnee]
            if !fe.motif.isEmpty { morceaux.append(fe.motif) }
            l.append(LigneReglesUS(titre: t.fermeture, valeur: morceaux.joined(separator: " · ")))
        }
        if !r.engins.isEmpty { l.append(LigneReglesUS(titre: t.materiel, valeur: liste(r.engins))) }
        if !r.appats.isEmpty { l.append(LigneReglesUS(titre: t.appats, valeur: liste(r.appats))) }
        return l
    }

    /// Les engins et appâts viennent du fichier de règles sous forme d'étiquettes (« max_3_hamecons ») : on les rend lisibles, sans rien changer au sens.
    private static func liste(_ etiquettes: [String]) -> String {
        etiquettes.map { $0.replacingOccurrences(of: "_", with: " ") }.joined(separator: ", ")
    }

    // MARK: Dates

    /// « 11/07/2026 » aux États-Unis (jour lu à midi UTC : aucun décalage de fuseau possible).
    static func texte(_ jour: JourCivil, format: FormatRegion) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .gmt
        let d = cal.date(from: DateComponents(year: jour.annee, month: jour.mois, day: jour.jour, hour: 12)) ?? Date(timeIntervalSince1970: 0)
        return format.date(d, fuseau: .gmt)
    }

    /// « May 15 » ou « 15 mai » : un jour de l'année sans année (2024, bissextile, pour accepter le 29 février).
    static func texte(_ jour: MoisJour, format: FormatRegion) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .gmt
        let d = cal.date(from: DateComponents(year: 2024, month: jour.mois, day: jour.jour, hour: 12)) ?? Date(timeIntervalSince1970: 0)
        return d.formatted(Date.FormatStyle(locale: format.locale, timeZone: .gmt).month(.abbreviated).day())
    }
}

/// Les règles chargées une seule fois : `regles-us/` embarqué (WI, MN…) et le niveau 1 (50 États, lien de l'agence).
/// Un État du niveau 1 sans règle par espèce rend « donnée absente » avec le lien de son agence (décision du 7 nov.).
nonisolated enum ServiceReglesUS {
    /// `nil` si le paquet ne se charge pas : le bloc dit alors « donnée absente », jamais un verdict inventé.
    /// Premier appel : lecture des fichiers JSON ; à faire hors du fil principal (voir `BlocReglesUS`).
    static let evaluateur: EvaluateurUS? = {
        let contenu = ChargementReglesUS.embarque().tout()
        let niveau1 = try? Niveau1US.embarque()
        return try? EvaluateurUS(contenu: contenu, niveau1: niveau1)
    }()
}

/// Où est le pêcheur : l'État américain d'une position ou d'un lieu flou de carte.
nonisolated enum EtatUSDepuisLieu {
    private struct Cadre {
        let code: String
        let sud: Double, nord: Double, ouest: Double, est: Double
    }

    /// Cadres volontairement étroits, tout à fait à l'intérieur de l'État : près d'une frontière on ne devine rien, le pêcheur choisit l'État.
    /// Seuls les États dont les règles sont chargées (WI, MN) sont devinés ; les autres se choisissent à la main.
    private static let cadres: [Cadre] = [
        Cadre(code: "WI", sud: 43.3, nord: 45.6, ouest: -90.9, est: -88.5),
        Cadre(code: "MN", sud: 44.6, nord: 48.0, ouest: -95.5, est: -93.5),
    ]

    static func etat(pour p: Coordonnee) -> CodeEtat? {
        let trouves = cadres.filter { p.latitude >= $0.sud && p.latitude <= $0.nord && p.longitude >= $0.ouest && p.longitude <= $0.est }
        guard trouves.count == 1 else { return nil }
        return CodeEtat(rawValue: trouves[0].code)
    }

    /// Un lieu flou de carte (« Lake Mendota · WI », « Wisconsin ») : un code USPS écrit en majuscules, ou le nom complet d'un État du niveau 1.
    /// Deux États différents dans le même texte : on ne devine rien.
    static func etat(depuisLieuFlou texte: String?, noms: [(code: CodeEtat, nom: String)]) -> CodeEtat? {
        guard let texte, !texte.isEmpty else { return nil }
        var trouves = Set<CodeEtat>()
        let mots = texte.split { !$0.isLetter }.map(String.init)
        for mot in mots where mot.count == 2 && mot == mot.uppercased() {
            if let c = CodeEtat(rawValue: mot) { trouves.insert(c) }
        }
        let bas = texte.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        for n in noms where bas.contains(n.nom.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)) { trouves.insert(n.code) }
        return trouves.count == 1 ? trouves.first : nil
    }
}
