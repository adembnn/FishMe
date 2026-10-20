import Foundation

/// Où en est la pêche de l'espèce aujourd'hui, d'après les règles sourcées du spot. Une porte vers la source, pas un verdict.
public enum StatutOuverture: Sendable, Equatable {
    case ouverte(SourceRegle?)
    case fermee(reouverture: Date?, SourceRegle?)
    case aVerifier
    /// Aucun spot : rien à lire.
    case sansSpot
}

/// Ce que « Mes envies » montre d'une espèce : l'ouverture, la règle de taille, un conseil. Rien d'autre.
public struct ResumeEnvie: Sendable, Equatable {
    public var espece: EspecePechable
    public var ouverture: StatutOuverture
    /// `LigneControle.phrase` de la ligne `.taille`, telle quelle (jamais recomposée).
    public var taille: String?
    public var sourceTaille: SourceRegle?
    /// Toutes les sources de la ligne de taille (deux quand les textes se contredisent).
    public var sourcesTaille: [SourceRegle]
    /// Un conseil du mois, déjà filtré par l'abonnement.
    public var conseil: Conseil?

    public init(espece: EspecePechable, ouverture: StatutOuverture, taille: String? = nil, sourceTaille: SourceRegle? = nil,
                sourcesTaille: [SourceRegle] = [], conseil: Conseil? = nil) {
        self.espece = espece
        self.ouverture = ouverture
        self.taille = taille
        self.sourceTaille = sourceTaille
        self.sourcesTaille = sourcesTaille
        self.conseil = conseil
    }

    /// - `controle` : le contrôle de l'espèce au spot du pêcheur à la date du jour ; `nil` sans spot.
    /// - `reouverture` : la date de réouverture si elle est connue (`ResultatControle` ne la porte pas).
    /// Si plusieurs lignes `.periode` se contredisent, la plus prudente gagne : fermée, puis à vérifier, puis ouverte.
    public static func construire(espece: EspecePechable, controle: ResultatControle?, conseil: Conseil?,
                                  reouverture: Date? = nil) -> ResumeEnvie {
        guard let controle else {
            return ResumeEnvie(espece: espece, ouverture: .sansSpot, conseil: conseil)
        }
        let periodes = controle.lignes.filter { $0.type == .periode }
        let ouverture: StatutOuverture
        if let fermee = periodes.first(where: { $0.etat == .nonRespectee }) {
            ouverture = .fermee(reouverture: reouverture, fermee.sources.first)
        } else if periodes.contains(where: { $0.etat == .aVerifierSurPlace }) {
            ouverture = .aVerifier
        } else if let ouverte = periodes.first(where: { $0.etat == .respectee }) {
            ouverture = .ouverte(ouverte.sources.first)
        } else {
            ouverture = .aVerifier
        }
        let ligneTaille = controle.lignes.first { $0.type == .taille }
        return ResumeEnvie(espece: espece, ouverture: ouverture, taille: ligneTaille?.phrase,
                           sourceTaille: ligneTaille?.sources.first, sourcesTaille: ligneTaille?.sources ?? [], conseil: conseil)
    }

    private var rangOuverture: Int {
        switch ouverture {
        case .ouverte: 0
        case .aVerifier, .sansSpot: 1
        case .fermee: 2
        }
    }

    /// Tri stable. « Ouvertes d'abord » : ouvertes, puis à vérifier, puis fermées ; à égalité la plus récemment ajoutée,
    /// puis l'ordre alphabétique. Aucun ordre ne dépend de la rareté ni d'une probabilité de capture.
    public static func trier(_ resumes: [ResumeEnvie], ordre: OrdreEnvies, liste: ListeEnvies) -> [ResumeEnvie] {
        let ajoutees = Dictionary(liste.envies.map { ($0.espece, $0.ajoutee) }, uniquingKeysWith: { premier, _ in premier })
        func ajoutee(_ r: ResumeEnvie) -> Date { ajoutees[r.espece.espece.id] ?? .distantPast }
        func alpha(_ a: ResumeEnvie, _ b: ResumeEnvie) -> ComparisonResult {
            a.espece.nom.compare(b.espece.nom, options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "fr_FR"))
        }
        func parNom(_ a: ResumeEnvie, _ b: ResumeEnvie) -> Bool? {
            let c = alpha(a, b)
            return c == .orderedSame ? nil : c == .orderedAscending
        }
        func precede(_ a: ResumeEnvie, _ b: ResumeEnvie) -> Bool? {
            switch ordre {
            case .ouvertesDAbord:
                if a.rangOuverture != b.rangOuverture { return a.rangOuverture < b.rangOuverture }
                if ajoutee(a) != ajoutee(b) { return ajoutee(a) > ajoutee(b) }
                return parNom(a, b)
            case .recentes:
                if ajoutee(a) != ajoutee(b) { return ajoutee(a) > ajoutee(b) }
                return parNom(a, b)
            case .alphabetique:
                return parNom(a, b)
            }
        }
        return resumes.enumerated().sorted { x, y in
            precede(x.element, y.element) ?? (x.offset < y.offset)
        }.map(\.element)
    }
}
