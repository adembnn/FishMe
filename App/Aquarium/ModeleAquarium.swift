import CoreGraphics
import Foundation
import Observation

/// Un toucher sur la vitre : une onde qui s'étend et écarte les poissons proches. Position en fractions de la vitre.
nonisolated struct OndeVitre: Equatable {
    let centre: CGPoint
    let debut: Double
    static let duree = 1.8
}

/// Une ration qui tombe. Les deux poissons les plus proches à l'instant du lâcher viennent la chercher.
nonisolated struct RationTombee: Equatable, Identifiable {
    let id: UUID
    let x: Double
    let debut: Double
    let attires: [UUID]
}

nonisolated enum ResultatChoixDecor: Equatable {
    case choisi
    /// Décor Pro sans abonnement : A ouvre le paywall de L6.
    case paywall
    /// Décor à gagner : la phrase dit quoi faire.
    case verrouille(String)
}

/// L'état de l'aquarium. Le temps est celui de l'animation (secondes) : il s'arrête quand l'écran n'est plus vu,
/// pour que les poissons ne sautent pas à la reprise.
@MainActor
@Observable
final class ModeleAquarium {
    private(set) var entrees: [EntreeAquarium] = []
    private(set) var progression = Progression(especesDifferentes: 0, sessionsTerminees: 0, aUnLegendaire: false)
    private(set) var decor: Decor
    private(set) var proOuvert = false
    private(set) var ondes: [OndeVitre] = []
    private(set) var rations: [RationTombee] = []
    private(set) var rationsDonnees: Int
    /// Vrai pendant une seconde quand le pêcheur demande une ration alors qu'il n'en reste plus.
    private(set) var plusDeRation = false

    @ObservationIgnored private let stockage: any StockageAquarium
    @ObservationIgnored private var origine: Date
    @ObservationIgnored private var pauseTotale: TimeInterval = 0
    @ObservationIgnored private var debutPause: Date?

    init(stockage: (any StockageAquarium)? = nil, maintenant: Date = Date()) {
        let stockage = stockage ?? StockageUserDefaults()
        self.stockage = stockage
        self.decor = stockage.decorChoisi
        self.rationsDonnees = stockage.rationsDonnees
        self.origine = maintenant
    }

    // MARK: Données

    func mettreAJour(entrees: [EntreeAquarium], sessionsTerminees: Int, proOuvert: Bool) {
        self.entrees = entrees
        self.proOuvert = proOuvert
        progression = Progression.depuis(entrees: entrees, sessionsTerminees: sessionsTerminees)
        // Un décor gagné qui n'est plus ouvert (abonnement terminé) : retour au bassin.
        if Decors.etat(decor, progression: progression, proOuvert: proOuvert) != .ouvert {
            decor = .bassin
        }
    }

    /// Une ration par session terminée, même bredouille ; celles déjà données sont décomptées.
    var rationsRestantes: Int { max(progression.sessionsTerminees - rationsDonnees, 0) }

    func etat(de decor: Decor) -> EtatDecor {
        Decors.etat(decor, progression: progression, proOuvert: proOuvert)
    }

    // MARK: Temps

    func temps(a date: Date) -> Double {
        let fin = debutPause ?? date
        return max(fin.timeIntervalSince(origine) - pauseTotale, 0)
    }

    func mettreEnPause(a date: Date) {
        if debutPause == nil { debutPause = date }
    }

    func reprendre(a date: Date) {
        if let debutPause {
            pauseTotale += date.timeIntervalSince(debutPause)
            self.debutPause = nil
        }
    }

    // MARK: Gestes

    func choisir(_ decor: Decor) -> ResultatChoixDecor {
        switch etat(de: decor) {
        case .ouvert:
            self.decor = decor
            stockage.decorChoisi = decor
            return .choisi
        case .pro:
            return .paywall
        case .aGagner(_, _, let phrase):
            return .verrouille(phrase)
        }
    }

    /// Toucher la vitre : une onde et les poissons proches s'écartent.
    func toucherVitre(a point: CGPoint, temps: Double) {
        ondes.removeAll { temps - $0.debut > OndeVitre.duree }
        ondes.append(OndeVitre(centre: point, debut: temps))
    }

    /// Appui long : une ration tombe, s'il en reste. Rend faux (sans rien faire tomber) quand il n'y en a plus.
    @discardableResult
    func lancerRation(x: Double, temps: Double) -> Bool {
        rations.removeAll { temps - $0.debut > Nage.dureeRation() }
        guard rationsRestantes > 0 else { return false }
        rationsDonnees += 1
        stockage.rationsDonnees = rationsDonnees
        let tries = entrees.sorted {
            abs(positionDeBase($0, temps: temps).x - x) < abs(positionDeBase($1, temps: temps).x - x)
        }
        rations.append(RationTombee(id: UUID(), x: x, debut: temps, attires: tries.prefix(2).map(\.id)))
        return true
    }

    func signalerPlusDeRation() async {
        plusDeRation = true
        try? await Task.sleep(for: .seconds(1.4))
        plusDeRation = false
    }

    // MARK: Positions

    private func positionDeBase(_ entree: EntreeAquarium, temps: Double) -> PositionNage {
        Nage.position(id: entree.id, especeId: entree.especeId, t: temps)
    }

    /// Où dessiner un poisson : sa nage propre, écartée par les ondes, attirée par une ration.
    func position(de entree: EntreeAquarium, temps: Double) -> PositionNage {
        var p = positionDeBase(entree, temps: temps)
        var x = p.x
        var y = p.y
        for onde in ondes {
            let e = Nage.ecart(poisson: CGPoint(x: x, y: y), centre: onde.centre, dt: temps - onde.debut)
            x += e.dx
            y += e.dy
        }
        for ration in rations where ration.attires.contains(entree.id) {
            let dt = temps - ration.debut
            let duree = Nage.dureeRation()
            guard dt > 0, dt < duree + 1.5 else { continue }
            let montee = min(dt / 1.2, 1)
            let descente = dt > duree ? max(1 - (dt - duree) / 1.5, 0) : 1
            let poids = 0.8 * montee * descente
            let cibleY = Nage.hauteurRation(dt: dt)
            x += (ration.x - x) * poids
            y += (cibleY - y) * poids * 0.7
            if poids > 0.4 { p.versLaDroite = ration.x >= x }
        }
        p.x = min(max(x, 0.08), 0.92)
        p.y = min(max(y, 0.12), 0.86)
        return p
    }

    /// Les poissons sont immobiles avec « Réduire les animations » : une place fixe, stable, sans onde.
    func positionFixe(de entree: EntreeAquarium) -> PositionNage {
        positionDeBase(entree, temps: 0)
    }
}
