import Foundation

/// `conseils(espece, niveau, mois)` : choisit, parmi les conseils relus de `conseils.json`, ceux à montrer.
/// Aucun appel réseau, aucune IA : un texte écrit, relu, sourcé.
public struct ConseilsParEspece: ServiceConseils {
    /// Combien de conseils par niveau (défaut, à confirmer par Adem). `nil` : tous.
    public static func nombreMax(pour niveau: NiveauPecheur) -> Int? {
        switch niveau {
        case .debutant: return 3
        case .occasionnel: return 5
        case .confirme: return nil
        }
    }

    private let fichier: FichierConseils
    private let regles: (any ServiceRegles)?
    private let horloge: @Sendable () -> Date

    /// - Parameters:
    ///   - regles: pour la variante avec lieu (`reglesDuJour`). Sans elle, la variante ne retire que par catégorie.
    ///   - horloge: la date qui sert à demander les règles du jour.
    public init(fichier: FichierConseils, regles: (any ServiceRegles)? = nil,
                horloge: @escaping @Sendable () -> Date = { Date() }) {
        // Un conseil sans relu_par n'est jamais montré, même s'il s'est glissé dans le fichier.
        self.fichier = FichierConseils(version: fichier.version, date: fichier.date, sources: fichier.sources,
                                       conseils: fichier.conseils.filter(\.estRelu))
        self.regles = regles
        self.horloge = horloge
    }

    /// Lit le `conseils.json` des ressources de `Core`.
    public static func charger(regles: (any ServiceRegles)? = nil) throws -> ConseilsParEspece {
        guard let url = Bundle.module.url(forResource: "conseils", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return ConseilsParEspece(fichier: try FichierConseils.decoder(Data(contentsOf: url)), regles: regles)
    }

    public func conseils(espece: Espece, niveau: NiveauPecheur, mois: Int) -> [Conseil] {
        choisir(espece: espece, niveau: niveau, mois: mois, exclure: { _ in false })
    }

    public func conseils(espece: Espece, niveau: NiveauPecheur, mois: Int, lieu: Lieu) -> [Conseil] {
        let modesInterdits = self.modesInterdits(lieu: lieu, mois: mois)
        let categorie = lieu.categorie.valeur
        return choisir(espece: espece, niveau: niveau, mois: mois) { c in
            if c.modes.contains(where: modesInterdits.contains) { return true }
            switch categorie {
            case .premiere: return c.categorie == .deuxieme
            case .deuxieme: return c.categorie == .premiere
            case .inconnue: return c.categorie != .toutes
            }
        }
    }

    // MARK: - Choix

    private func choisir(espece: Espece, niveau: NiveauPecheur, mois: Int,
                         exclure: (ConseilFiche) -> Bool) -> [Conseil] {
        guard (1...12).contains(mois) else { return [] }
        var retenus = fichier.conseils
            .filter { $0.espece == espece.id && $0.mois.contains(mois) && $0.niveaux.contains(niveau) && !exclure($0) }
            .sorted { ($0.rang, $0.id) < ($1.rang, $1.id) }
        if let max = Self.nombreMax(pour: niveau) { retenus = Array(retenus.prefix(max)) }
        return retenus.enumerated().compactMap { (i, c) in
            guard let source = source(de: c) else { return nil }
            return Conseil(texte: c.texte, icone: c.icone, source: source, gratuit: i == 0)
        }
    }

    private func source(de c: ConseilFiche) -> SourceRegle? {
        guard let id = c.sources.first, let s = fichier.sources.first(where: { $0.id == id }) else { return nil }
        return SourceRegle(titre: s.titre, url: s.url)
    }

    // MARK: - Règles du jour

    /// Motifs (expressions régulières, texte sans accent) qui nomment chaque mode dans une phrase de règle.
    private static let motifsParMode: [(ModeConseil, String)] = [
        (.vif, #"\b(vifs?|vivants?)\b"#),
        (.poissonMort, #"\bpoissons? morts?\b"#),
        (.leurre, #"\b(leurres?|artificiel\w*)\b"#),
        (.asticot, #"\basticot"#),
        (.mouche, #"\bmouche"#),
        (.amorce, #"\bamorc"#),
        (.bateau, #"\b(bateau|bateaux|embarcations?)\b"#),
    ]

    /// Les modes qu'une ligne du jour interdit sur ce lieu : un type de mode de pêche (ou nuit, transport vivant, autre)
    /// dont la phrase dit « interdit » et nomme le mode. Lecture prudente : une phrase qui nomme deux modes les retire tous deux.
    func modesInterdits(lieu: Lieu, mois: Int) -> Set<ModeConseil> {
        guard let regles else { return [] }
        let lignes = regles.reglesDuJour(lieu: lieu, date: dateDuMois(mois))
        var interdits = Set<ModeConseil>()
        for l in lignes where [.modeDePeche, .nuit, .transportVivant, .autre].contains(l.type) {
            let phrase = ValidationConseils.normaliser(l.phrase)
            guard phrase.contains("interdit") || phrase.contains("interdiction") else { continue }
            if l.type == .nuit { interdits.insert(.nuit) }
            for (mode, motif) in Self.motifsParMode where phrase.range(of: motif, options: .regularExpression) != nil {
                interdits.insert(mode)
            }
        }
        return interdits
    }

    private func dateDuMois(_ mois: Int) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        let maintenant = horloge()
        if cal.component(.month, from: maintenant) == mois { return maintenant }
        var c = DateComponents()
        c.year = cal.component(.year, from: maintenant)
        c.month = mois
        c.day = 15
        c.hour = 12
        return cal.date(from: c) ?? maintenant
    }
}

// MARK: - Un conseil par type (écran « À essayer »)

/// Le meilleur conseil de chaque type (appât, hameçon, technique, moment) pour une espèce.
/// Un type sans conseil dans le mois demandé prend celui du mois le plus proche ; un type absent du dictionnaire n'a aucun conseil relu.
public protocol ServiceConseilsParType: ServiceConseils {
    func conseilsParType(espece: Espece, niveau: NiveauPecheur, mois: Int, lieu: Lieu?) -> [TypeConseil: Conseil]
}

public extension ServiceConseilsParType {
    func conseilsParType(espece: Espece, niveau: NiveauPecheur, mois: Int) -> [TypeConseil: Conseil] {
        conseilsParType(espece: espece, niveau: niveau, mois: mois, lieu: nil)
    }
}

extension ConseilsParEspece: ServiceConseilsParType {
    public func conseilsParType(espece: Espece, niveau: NiveauPecheur, mois: Int, lieu: Lieu?) -> [TypeConseil: Conseil] {
        guard (1...12).contains(mois) else { return [:] }
        var resultat: [TypeConseil: Conseil] = [:]
        for type in TypeConseil.allCases {
            if let c = meilleur(type: type, espece: espece, niveau: niveau, mois: mois, lieu: lieu) {
                resultat[type] = c
            }
        }
        return resultat
    }

    /// Le mois demandé d'abord, puis +1, -1, +2, -2… (circulaire).
    static func moisParProximite(_ mois: Int) -> [Int] {
        var liste = [mois]
        for d in 1...6 {
            for m in [mois + d, mois - d] {
                let n = (m - 1 + 12) % 12 + 1
                if !liste.contains(n) { liste.append(n) }
            }
        }
        return liste
    }

    private func meilleur(type: TypeConseil, espece: Espece, niveau: NiveauPecheur, mois: Int, lieu: Lieu?) -> Conseil? {
        let categorie = lieu?.categorie.valeur
        // Premier passage : le niveau du pêcheur sur tous les mois ; second passage : n'importe quel niveau.
        for tousNiveaux in [false, true] {
            for m in Self.moisParProximite(mois) {
                let interdits: Set<ModeConseil> = lieu.map { modesInterdits(lieu: $0, mois: m) } ?? []
                let candidats = fichier.conseils
                    .filter { $0.espece == espece.id && $0.type == type && $0.mois.contains(m) }
                    .filter { tousNiveaux || $0.niveaux.contains(niveau) }
                    .filter { c in
                        if c.modes.contains(where: interdits.contains) { return false }
                        switch categorie {
                        case .premiere: return c.categorie != .deuxieme
                        case .deuxieme: return c.categorie != .premiere
                        case .inconnue: return c.categorie == .toutes
                        case nil: return true
                        }
                    }
                    .sorted { ($0.rang, $0.id) < ($1.rang, $1.id) }
                for c in candidats {
                    if let source = source(de: c) { return Conseil(texte: c.texte, icone: c.icone, source: source, gratuit: false) }
                }
            }
        }
        return nil
    }
}
