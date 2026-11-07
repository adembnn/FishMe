import Foundation

/// Ce que le pêcheur demande : une espèce, un lieu, un jour, et ce qu'il sait de sa prise. Aucune horloge ici : le jour est un paramètre.
public struct QuestionUS: Sendable, Equatable {
    public let espece: String
    public let juridiction: IdJuridiction
    public let jour: JourCivil
    public var taille: Longueur?
    /// Vrai si la taille vient d'une estimation (photo) et non d'une mesure : elle ne suffit jamais à dire « interdit ».
    public var tailleEstimee: Bool
    public var age: Int?
    /// Poissons de cette espèce déjà gardés aujourd'hui (déclaré par le pêcheur, non vérifié).
    public var prisesGardeesAujourdhui: Int?
    public var enPossession: Int?

    public init(espece: String, juridiction: IdJuridiction, jour: JourCivil, taille: Longueur? = nil, tailleEstimee: Bool = false,
                age: Int? = nil, prisesGardeesAujourdhui: Int? = nil, enPossession: Int? = nil) {
        self.espece = espece
        self.juridiction = juridiction
        self.jour = jour
        self.taille = taille
        self.tailleEstimee = tailleEstimee
        self.age = age
        self.prisesGardeesAujourdhui = prisesGardeesAujourdhui
        self.enPossession = enPossession
    }
}

public struct ResultatUS: Sendable, Equatable {
    public let verdict: VerdictUS
    public let motifs: [MotifUS]
    /// Identifiants des règles qui ont pesé dans le verdict (les plus spécifiques de chaque famille).
    public let regles: [String]
    /// Sources de ces règles, la plus récemment lue d'abord, sans doublon d'adresse.
    public let sources: [SourceUS]
    /// Permis, timbres et permis tribal exigés le long de la hiérarchie (toutes les exigences connues, sans verdict).
    public let exigences: [ExigenceUS]
    public let alertes: [AlerteTerrain]
    /// Lien de l'agence le plus proche dans la hiérarchie : à afficher toujours.
    public let lienAgence: URL?
    /// Niveau de couverture le plus fin parmi les règles utilisées ; `nil` sans règle.
    public let couverture: CouvertureUS?
    /// Lecture la plus ancienne parmi les règles utilisées : date à afficher avec le verdict.
    public let lectureLaPlusAncienne: JourCivil?
}

/// Réglages du moteur.
public struct ParametresMoteurUS: Sendable, Equatable {
    /// Au-delà, une règle lue ne fonde plus « interdit » (les livrets changent chaque année ; `reglementation-cadre.md` §4.2).
    /// 400 jours est un choix de départ à valider, pas une donnée sourcée [?].
    public var ageMaxLectureJours: Int

    public init(ageMaxLectureJours: Int = 400) { self.ageMaxLectureJours = ageMaxLectureJours }
}

/// Le moteur du verdict US. Règles de composition :
/// 1. La règle la plus spécifique l'emporte, famille par famille (ouverture, taille, limites, engins, appâts) : d'abord le niveau de
///    juridiction (tronçon > plan d'eau > zone > État), puis la règle propre à l'espèce avant la règle « toutes espèces ».
/// 2. Aucune combinaison ne produit une valeur permissive : le meilleur résultat possible est « à vérifier ».
/// 3. « Interdit » exige une règle confirmée, valide, récemment lue, sans incertitude de terrain ni conflit, et violée sans ambiguïté.
/// 4. Aucune règle lue pour cette espèce ici : « donnée absente ».
public struct MoteurUS: Sendable {
    public let arbre: ArbreJuridictions
    public let regles: [RegleUS]
    public let exigences: [ExigenceUS]
    public let parametres: ParametresMoteurUS

    public init(arbre: ArbreJuridictions, regles: [RegleUS], exigences: [ExigenceUS] = [], parametres: ParametresMoteurUS = ParametresMoteurUS()) {
        self.arbre = arbre
        self.regles = regles
        self.exigences = exigences
        self.parametres = parametres
    }

    // Issue d'une règle pour une famille.
    private enum Issue {
        case violation([MotifUS])
        case incertaine([MotifUS])
        case neutre

        var motifs: [MotifUS] {
            switch self {
            case .violation(let m), .incertaine(let m): m
            case .neutre: []
            }
        }
    }

    public func evaluer(_ q: QuestionUS) -> ResultatUS {
        guard let chaine = arbre.chaine(de: q.juridiction) else {
            return ResultatUS(verdict: .donneeAbsente, motifs: [.juridictionInconnue(q.juridiction)], regles: [], sources: [], exigences: [],
                              alertes: [], lienAgence: nil, couverture: nil, lectureLaPlusAncienne: nil)
        }
        let profondeur = Dictionary(uniqueKeysWithValues: chaine.enumerated().map { ($0.element.id, $0.offset) })
        let indexTribal = chaine.firstIndex { $0.alertes.contains(.reserveTribale) }

        var alertes: [AlerteTerrain] = []
        var motifs: [MotifUS] = []
        for j in chaine {
            for a in AlerteTerrain.allCases where j.alertes.contains(a) {
                if !alertes.contains(a) { alertes.append(a) }
                motifs.append(.alerteTerrain(a, juridiction: j.id))
            }
        }
        let exigencesApplicables = exigences.filter { profondeur[$0.portee] != nil }
            .sorted { (profondeur[$0.portee] ?? 0, $0.id) < (profondeur[$1.portee] ?? 0, $1.id) }
        let lien = chaine.reversed().compactMap(\.lienAgence).first

        // Règles qui visent ce lieu et cette espèce (ou toutes), puis celles qui visent aussi ce pêcheur (un âge connu peut en exclure).
        let existantes = regles.filter { r in profondeur[r.portee] != nil && (r.espece == nil || r.espece == q.espece) }
        let applicables = existantes.filter { r in
            guard let cond = r.age, let age = q.age else { return true }
            return cond.contient(age)
        }
        guard !existantes.isEmpty else {
            return ResultatUS(verdict: .donneeAbsente, motifs: motifs + [.aucuneRegleLue], regles: [], sources: [], exigences: exigencesApplicables,
                              alertes: alertes, lienAgence: lien, couverture: nil, lectureLaPlusAncienne: nil)
        }
        guard !applicables.isEmpty else {
            // Des règles existent mais aucune ne vise ce pêcheur : on ne conclut rien, on renvoie à l'agence.
            let hors = existantes.map { MotifUS.regleHorsTrancheDAge(regle: $0.id) }
            return ResultatUS(verdict: .aVerifier, motifs: motifs + hors, regles: existantes.map(\.id), sources: existantes.map(\.source),
                              exigences: exigencesApplicables, alertes: alertes, lienAgence: lien,
                              couverture: existantes.map(\.couverture).max(), lectureLaPlusAncienne: existantes.map(\.source.dateLecture).min())
        }

        var utilisees: [RegleUS] = []
        var violation = false
        for famille in FamilleRegle.allCases {
            let candidates = applicables.filter { $0.familles.contains(famille) }
            guard !candidates.isEmpty else { continue }
            func cle(_ r: RegleUS) -> [Int] { [profondeur[r.portee] ?? 0, r.espece == nil ? 0 : 1] }
            let meilleure = candidates.map(cle).max { $0.lexicographicallyPrecedes($1) } ?? [0, 0]
            let sommet = candidates.filter { cle($0) == meilleure }.sorted { $0.id < $1.id }
            for r in sommet where !utilisees.contains(where: { $0.id == r.id }) { utilisees.append(r) }

            let issues = sommet.map { evaluer($0, famille: famille, q: q, indexTribal: indexTribal, profondeur: profondeur) }
            let toutesViolations = issues.allSatisfy { if case .violation = $0 { true } else { false } }
            if toutesViolations {
                violation = true
                motifs.append(contentsOf: issues.flatMap(\.motifs))
                continue
            }
            if Set(sommet.map { contenu($0, famille) }).count > 1 {
                motifs.append(.conflitEntreRegles(famille: famille, regles: sommet.map(\.id)))
                continue
            }
            motifs.append(contentsOf: issues.flatMap(\.motifs))
        }

        let verdict: VerdictUS = violation ? .interdit : .aVerifier
        var vus = Set<URL>()
        let sources = utilisees.map(\.source).sorted { $0.dateLecture > $1.dateLecture }.filter { vus.insert($0.url).inserted }
        return ResultatUS(verdict: verdict, motifs: motifs, regles: utilisees.map(\.id), sources: sources, exigences: exigencesApplicables,
                          alertes: alertes, lienAgence: lien, couverture: utilisees.map(\.couverture).max(),
                          lectureLaPlusAncienne: utilisees.map(\.source.dateLecture).min())
    }

    // Valeur comparée entre deux règles de même niveau : si elles diffèrent, c'est un conflit.
    private func contenu(_ r: RegleUS, _ f: FamilleRegle) -> [String] {
        switch f {
        case .ouverture: [String(describing: r.saison), String(describing: r.fermetures)]
        case .taille: [String(describing: r.tailles)]
        case .limites: [String(describing: r.limites)]
        case .engins: [r.engins.sorted().joined(separator: "|")]
        case .appats: [r.appats.sorted().joined(separator: "|")]
        }
    }

    /// Incertitudes qui empêchent une règle de fonder « interdit » (elle reste lue et montrée).
    private func incertitudes(_ r: RegleUS, q: QuestionUS, indexTribal: Int?, profondeur: [IdJuridiction: Int]) -> [MotifUS] {
        var m: [MotifUS] = []
        if !r.statut.estConfirme { m.append(.regleNonConfirmee(regle: r.id, statut: r.statut)) }
        if let fin = r.valideJusqua, q.jour > fin { m.append(.regleExpiree(regle: r.id)) }
        let ecart = r.source.dateLecture.jours(jusqua: q.jour)
        if ecart < 0 { m.append(.lectureDansLeFutur(regle: r.id)) }
        else if ecart > parametres.ageMaxLectureJours { m.append(.lectureAncienne(regle: r.id, jours: ecart)) }
        if let t = indexTribal, (profondeur[r.portee] ?? 0) < t { m.append(.reglesDEtatSurTerrainTribal(regle: r.id)) }
        if r.age != nil, q.age == nil { m.append(.ageInconnu(regle: r.id)) }
        return m
    }

    private func evaluer(_ r: RegleUS, famille: FamilleRegle, q: QuestionUS, indexTribal: Int?, profondeur: [IdJuridiction: Int]) -> Issue {
        var violations: [MotifUS] = []
        var doutes: [MotifUS] = []
        switch famille {
        case .ouverture:
            if let s = r.saison {
                switch s.position(de: q.jour) {
                case .dehors: violations.append(.horsSaison(regle: r.id))
                case .surBorne: doutes.append(.jourSurUneBorne(regle: r.id))
                case .dedans: break
                }
            }
            for f in r.fermetures {
                guard let p = f.periode else { violations.append(.fermeture(regle: r.id, type: f.type, motif: f.motif)); continue }
                switch p.position(de: q.jour) {
                case .dedans: violations.append(.fermeture(regle: r.id, type: f.type, motif: f.motif))
                case .surBorne: doutes.append(.jourSurUneBorne(regle: r.id))
                case .dehors: break
                }
            }
        case .taille:
            guard let t = q.taille else { doutes.append(.tailleNonMesuree(regle: r.id)); break }
            if let min = r.tailles.minimale {
                if t.memeValeur(que: min) { doutes.append(.tailleALaLimite(regle: r.id)) }
                else if t < min { violations.append(.sousTailleMinimale(regle: r.id, taille: t, minimale: min)) }
            }
            if let w = r.tailles.fenetre {
                if t.memeValeur(que: w.basse) || t.memeValeur(que: w.haute) { doutes.append(.tailleALaLimite(regle: r.id)) }
                else if t > w.basse && t < w.haute { violations.append(.dansFenetreProtegee(regle: r.id, taille: t, fenetre: w)) }
            }
            if let max = r.tailles.maximale {
                if t.memeValeur(que: max) { doutes.append(.tailleALaLimite(regle: r.id)) }
                else if t > max { violations.append(.auDessusTailleMaximale(regle: r.id, taille: t, maximale: max)) }
            }
            if q.tailleEstimee { doutes.append(.tailleEstimee(regle: r.id)) }
        case .limites:
            if q.prisesGardeesAujourdhui == nil && q.enPossession == nil { doutes.append(.compteursInconnus(regle: r.id)) }
            if let l = r.limites.prise, let n = q.prisesGardeesAujourdhui, n >= l { violations.append(.limiteDePriseAtteinte(regle: r.id, limite: l)) }
            if let l = r.limites.possession, let n = q.enPossession, n >= l { violations.append(.limiteDePossessionAtteinte(regle: r.id, limite: l)) }
        case .engins, .appats:
            doutes.append(.enginsOuAppatsALire(regle: r.id))
        }

        let incertain = incertitudes(r, q: q, indexTribal: indexTribal, profondeur: profondeur)
        // Une taille estimée ne suffit pas à interdire.
        let estimee = famille == .taille && q.tailleEstimee
        if !violations.isEmpty && incertain.isEmpty && !estimee && doutes.allSatisfy({ if case .tailleEstimee = $0 { true } else { false } }) {
            return .violation(violations)
        }
        if violations.isEmpty && doutes.isEmpty && incertain.isEmpty { return .neutre }
        return .incertaine(violations + doutes + incertain)
    }
}
