import Foundation

/// Ce qui suit le pêcheur d'un iPhone à l'autre en plus de ses cartes : réglages du premier lancement, clubs et sorties.
/// Jamais de coordonnée exacte : les sorties n'en ont pas, le spot gratuit reste dans le trousseau de l'iPhone.
public struct ProfilSauvegarde: Sendable, Equatable, Codable {
    /// `NiveauPecheur.rawValue`, `nil` si la question n'a pas encore été posée.
    public var niveau: String?
    public var questionVue: Bool
    public var tunnelVu: Bool
    /// Les clubs, en JSON tels que l'app les range ; `nil` : aucun club.
    public var clubs: Data?
    public var sorties: [Sortie]
    public var sessionsTerminees: Int
    /// Dernière modification connue, pour savoir quel réglage gagne entre deux iPhones.
    public var modifie: Date

    public init(niveau: String? = nil, questionVue: Bool = false, tunnelVu: Bool = false, clubs: Data? = nil,
                sorties: [Sortie] = [], sessionsTerminees: Int = 0, modifie: Date = Date(timeIntervalSince1970: 0)) {
        self.niveau = niveau
        self.questionVue = questionVue
        self.tunnelVu = tunnelVu
        self.clubs = clubs
        self.sorties = sorties
        self.sessionsTerminees = sessionsTerminees
        self.modifie = modifie
    }

    /// Profil d'un iPhone neuf : rien à garder, tout ce qui vient d'iCloud gagne.
    public var estVide: Bool {
        niveau == nil && !questionVue && !tunnelVu && clubs == nil && sorties.isEmpty && sessionsTerminees == 0
    }
}

/// Ce qu'une synchro doit faire, calculé sur les seuls identifiants.
public struct PlanSynchro: Sendable, Equatable {
    /// Sur l'iPhone, pas encore dans iCloud.
    public var aEnvoyer: [UUID]
    /// Dans iCloud, absents de l'iPhone : un nouvel iPhone, ou une carte prise sur un autre.
    public var aRapatrier: [UUID]
}

/// Règles de fusion entre l'iPhone et iCloud. Rien ne s'efface jamais par une synchro : on ajoute ce qui manque des deux côtés.
public enum FusionSauvegarde {
    public static func plan(locaux: some Sequence<UUID>, distants: some Sequence<UUID>) -> PlanSynchro {
        let l = Set(locaux), d = Set(distants)
        return PlanSynchro(aEnvoyer: l.subtracting(d).sorted { $0.uuidString < $1.uuidString },
                           aRapatrier: d.subtracting(l).sorted { $0.uuidString < $1.uuidString })
    }

    /// Union des deux profils. Une case cochée sur un iPhone l'est partout ; le compteur de sessions ne recule jamais
    /// (la limite du gratuit en dépend) ; pour le niveau et les clubs, le profil modifié le plus tard gagne.
    public static func fusionner(local: ProfilSauvegarde, distant: ProfilSauvegarde) -> ProfilSauvegarde {
        if local.estVide { return distant }
        if distant.estVide { return local }
        let recent = local.modifie >= distant.modifie ? local : distant
        let ancien = local.modifie >= distant.modifie ? distant : local
        var sorties = local.sorties
        let connues = Set(sorties.map(\.id))
        sorties += distant.sorties.filter { !connues.contains($0.id) }
        sorties.sort { $0.debut < $1.debut }
        return ProfilSauvegarde(
            niveau: recent.niveau ?? ancien.niveau,
            questionVue: local.questionVue || distant.questionVue,
            tunnelVu: local.tunnelVu || distant.tunnelVu,
            clubs: recent.clubs ?? ancien.clubs,
            sorties: sorties,
            sessionsTerminees: max(local.sessionsTerminees, distant.sessionsTerminees, sorties.count),
            modifie: max(local.modifie, distant.modifie))
    }
}
