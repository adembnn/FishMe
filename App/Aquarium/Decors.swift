import Core
import Foundation
import SwiftUI

/// Comment un décor se débloque.
nonisolated enum ConditionDecor: Equatable {
    /// Toujours là.
    case aucune
    /// Un nombre d'espèces différentes prises.
    case especes(Int)
    /// Un nombre de sessions terminées, même bredouilles.
    case sessions(Int)
    /// Une prise légendaire.
    case legendaire
    /// Réservé à Pro (lu avec `peutUtiliser` de Core par A) : un toucher sans abonnement ouvre le paywall.
    case pro
}

nonisolated enum Decor: String, CaseIterable, Identifiable, Sendable {
    case bassin, riviere, etang, grotte, torrent, nocturne

    var id: String { rawValue }

    var nom: String {
        switch self {
        case .bassin: return "Bassin"
        case .riviere: return "Rivière"
        case .etang: return "Étang"
        case .grotte: return "Grotte"
        case .torrent: return "Torrent"
        case .nocturne: return "Nuit"
        }
    }

    var icone: String {
        switch self {
        case .bassin: return "drop.fill"
        case .riviere: return "water.waves"
        case .etang: return "leaf.fill"
        case .grotte: return "mountain.2.fill"
        case .torrent: return "wind"
        case .nocturne: return "moon.stars.fill"
        }
    }

    var condition: ConditionDecor {
        switch self {
        case .bassin: return .aucune
        case .riviere: return .especes(5)
        case .etang: return .sessions(10)
        case .grotte: return .legendaire
        case .torrent, .nocturne: return .pro
        }
    }

    var estPro: Bool { condition == .pro }
}

/// Ce que le pêcheur a gagné en pêchant, compté sur ses cartes et ses sessions (jamais sur un lieu).
nonisolated struct Progression: Equatable {
    var especesDifferentes: Int
    var sessionsTerminees: Int
    var aUnLegendaire: Bool

    /// Les vraies prises seulement : ni carte d'exemple ni carte déclarée.
    static func depuis(prises: [Prise], sessionsTerminees: Int, rareteDe: (Prise) -> NiveauRarete) -> Progression {
        let reelles = prises.filter(SelectionAquarium.nage)
        return Progression(especesDifferentes: Set(reelles.map(\.espece.id)).count,
                           sessionsTerminees: max(sessionsTerminees, 0),
                           aUnLegendaire: reelles.contains { rareteDe($0) == .legendaire })
    }

    /// Même progression à partir des entrées de l'aquarium.
    static func depuis(entrees: [EntreeAquarium], sessionsTerminees: Int) -> Progression {
        Progression(especesDifferentes: Set(entrees.map(\.especeId)).count,
                    sessionsTerminees: max(sessionsTerminees, 0),
                    aUnLegendaire: entrees.contains(where: \.estLegendaire))
    }
}

nonisolated enum EtatDecor: Equatable {
    case ouvert
    /// Gagné en pêchant : pas encore, avec l'avancement « 3 sur 5 ».
    case aGagner(actuel: Int, but: Int, phrase: String)
    /// Réservé à Pro, pas d'abonnement.
    case pro
}

nonisolated enum Decors {
    static func etat(_ decor: Decor, progression: Progression, proOuvert: Bool) -> EtatDecor {
        switch decor.condition {
        case .aucune:
            return .ouvert
        case .especes(let n):
            return progression.especesDifferentes >= n
                ? .ouvert
                : .aGagner(actuel: progression.especesDifferentes, but: n, phrase: "Prends \(n) espèces différentes")
        case .sessions(let n):
            return progression.sessionsTerminees >= n
                ? .ouvert
                : .aGagner(actuel: progression.sessionsTerminees, but: n, phrase: "Termine \(n) sessions")
        case .legendaire:
            return progression.aUnLegendaire
                ? .ouvert
                : .aGagner(actuel: 0, but: 1, phrase: "Prends un poisson légendaire")
        case .pro:
            return proOuvert ? .ouvert : .pro
        }
    }
}

/// Ce que l'aquarium garde sur l'iPhone : le décor choisi et le nombre de rations déjà données. Rien d'autre, aucun lieu.
protocol StockageAquarium: AnyObject {
    var decorChoisi: Decor { get set }
    var rationsDonnees: Int { get set }
}

final class StockageUserDefaults: StockageAquarium {
    private let defauts: UserDefaults
    private let cleDecor = "aquarium.decor"
    private let cleRations = "aquarium.rationsDonnees"

    init(defauts: UserDefaults = .standard) {
        self.defauts = defauts
    }

    var decorChoisi: Decor {
        get { defauts.string(forKey: cleDecor).flatMap(Decor.init(rawValue:)) ?? .bassin }
        set { defauts.set(newValue.rawValue, forKey: cleDecor) }
    }

    var rationsDonnees: Int {
        get { max(defauts.integer(forKey: cleRations), 0) }
        set { defauts.set(max(newValue, 0), forKey: cleRations) }
    }
}

/// Stockage en mémoire pour les tests.
final class StockageMemoire: StockageAquarium {
    var decorChoisi: Decor = .bassin
    var rationsDonnees = 0
}
