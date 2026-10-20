import Foundation

/// Pourquoi une envie n'est plus active.
public enum MotifRetrait: String, Sendable, Equatable, Hashable, Codable {
    /// Une carte de l'espèce est entrée au Pescedex.
    case pecheeLaCarteEstAuPescedex
    case retireeParLePecheur
}

/// Une espèce que le pêcheur veut pêcher. Une envie retirée reste en mémoire (pierre tombale) pour que la fusion
/// entre deux iPhones sache qu'elle a été retirée plutôt que jamais ajoutée.
public struct Envie: Sendable, Equatable, Hashable, Codable {
    /// `Espece.id`.
    public var espece: String
    public var ajoutee: Date
    /// `nil` : active ; sinon la date de sortie.
    public var retiree: Date?
    public var motif: MotifRetrait?

    public init(espece: String, ajoutee: Date, retiree: Date? = nil, motif: MotifRetrait? = nil) {
        self.espece = espece
        self.ajoutee = ajoutee
        self.retiree = retiree
        self.motif = motif
    }

    /// Dernière modification : c'est elle qui départage deux iPhones.
    public var modifie: Date { retiree ?? ajoutee }

    public var estActive: Bool { retiree == nil }

    enum CodingKeys: String, CodingKey { case espece, ajoutee, retiree, motif }

    /// Décodeur écrit à la main : un motif inconnu (écrit par une version plus récente) ne casse pas la lecture de la liste.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        espece = try c.decode(String.self, forKey: .espece)
        ajoutee = try c.decode(Date.self, forKey: .ajoutee)
        retiree = try c.decodeIfPresent(Date.self, forKey: .retiree)
        motif = (try? c.decodeIfPresent(MotifRetrait.self, forKey: .motif)) ?? nil
    }
}

/// Dans quel ordre montrer « Mes envies ». Jamais d'ordre par probabilité ni par rareté.
public enum OrdreEnvies: String, CaseIterable, Sendable {
    case ouvertesDAbord
    case recentes
    case alphabetique
}

/// Les envies du pêcheur : une entrée par espèce, active ou retirée.
public struct ListeEnvies: Sendable, Equatable, Codable {
    /// Actives et pierres tombales, une par espèce.
    public private(set) var envies: [Envie]

    /// Deux entrées de la même espèce se réduisent à la plus récente.
    public init(envies: [Envie] = []) {
        var gardees: [String: Envie] = [:]
        var ordre: [String] = []
        for e in envies {
            if let deja = gardees[e.espece] {
                gardees[e.espece] = ListeEnvies.plusRecente(deja, e)
            } else {
                gardees[e.espece] = e
                ordre.append(e.espece)
            }
        }
        self.envies = ordre.compactMap { gardees[$0] }
    }

    enum CodingKeys: String, CodingKey { case envies }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(envies: try c.decodeIfPresent([Envie].self, forKey: .envies) ?? [])
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(envies, forKey: .envies)
    }

    public var actives: [Envie] { envies.filter(\.estActive) }

    public var estVide: Bool { envies.isEmpty }

    /// Active seulement.
    public func contient(_ espece: Espece) -> Bool {
        envies.contains { $0.espece == espece.id && $0.estActive }
    }

    /// Idempotent ; réactive une pierre tombale.
    public mutating func ajouter(_ espece: Espece, le date: Date) {
        if let i = envies.firstIndex(where: { $0.espece == espece.id }) {
            guard !envies[i].estActive else { return }
            envies[i] = Envie(espece: espece.id, ajoutee: date)
        } else {
            envies.append(Envie(espece: espece.id, ajoutee: date))
        }
    }

    /// Motif `.retireeParLePecheur`. Sans effet si l'espèce n'est pas active.
    public mutating func retirer(_ espece: Espece, le date: Date) {
        sortir(Set([espece.id]), le: date, motif: .retireeParLePecheur)
    }

    /// Les espèces dont une carte est au Pescedex sortent (vraie prise ou carte déclarée). Ignore les cartes d'exemple.
    /// Rend vrai si la liste a changé.
    @discardableResult
    public mutating func retirerLesExaucees(cartes: [Prise], le date: Date) -> Bool {
        let trouvees = Set(cartes.filter { !$0.exemple }.map(\.espece.id))
        return sortir(trouvees, le: date, motif: .pecheeLaCarteEstAuPescedex)
    }

    @discardableResult
    private mutating func sortir(_ ids: Set<String>, le date: Date, motif: MotifRetrait) -> Bool {
        var change = false
        for i in envies.indices where envies[i].estActive && ids.contains(envies[i].espece) {
            envies[i].retiree = date
            envies[i].motif = motif
            change = true
        }
        return change
    }

    /// Peut-on proposer « Je veux la pêcher » ? Faux pour une espèce protégée, toujours relâchée ou dont le stade se demande,
    /// et pour une espèce qui a déjà une carte (hors carte d'exemple).
    public static func peutEtreMarquee(_ e: EspecePechable, cartes: [Prise]) -> Bool {
        let exclus: Set<StatutEspece> = [.protegee, .toujoursRelachee, .stadeADemander]
        if !e.statuts.isDisjoint(with: exclus) { return false }
        return !cartes.contains { !$0.exemple && $0.espece.id == e.espece.id }
    }

    /// Espèce par espèce, la modification la plus récente gagne. À égalité, la sortie l'emporte.
    /// Le résultat ne dépend pas de l'ordre des deux listes.
    public static func fusionner(_ a: ListeEnvies, _ b: ListeEnvies) -> ListeEnvies {
        fusionner(a.envies, b.envies)
    }

    /// Même règle sur des envies brutes (champ `envies` du profil de sauvegarde).
    public static func fusionner(_ a: [Envie], _ b: [Envie]) -> ListeEnvies {
        var parEspece: [String: Envie] = [:]
        for e in a + b {
            if let deja = parEspece[e.espece] {
                parEspece[e.espece] = plusRecente(deja, e)
            } else {
                parEspece[e.espece] = e
            }
        }
        var liste = ListeEnvies()
        liste.envies = parEspece.values.sorted {
            $0.ajoutee != $1.ajoutee ? $0.ajoutee < $1.ajoutee : $0.espece < $1.espece
        }
        return liste
    }

    private static func plusRecente(_ x: Envie, _ y: Envie) -> Envie {
        if x.modifie != y.modifie { return x.modifie > y.modifie ? x : y }
        if x.estActive != y.estActive { return x.estActive ? y : x }
        if x.ajoutee != y.ajoutee { return x.ajoutee > y.ajoutee ? x : y }
        return (x.motif?.rawValue ?? "") >= (y.motif?.rawValue ?? "") ? x : y
    }
}
