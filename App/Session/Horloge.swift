import Foundation

/// L'heure vient toujours de là, jamais de `Date()` directement : un faux (sous `#if DEBUG`)
/// permet de jouer « 18 h 30 un jour d'octobre à Paris » sans changer l'iPhone.
protocol Horloge: Sendable {
    func maintenant() -> Date
}

struct HorlogeSysteme: Horloge {
    func maintenant() -> Date { Date() }
}

#if DEBUG
/// Horloge réglable à la main, pour les tests et les démonstrations.
final class HorlogeFausse: Horloge, @unchecked Sendable {
    private let verrou = NSLock()
    private var heure: Date

    init(_ heure: Date) { self.heure = heure }

    func maintenant() -> Date {
        verrou.lock(); defer { verrou.unlock() }
        return heure
    }

    func avancer(de secondes: TimeInterval) {
        verrou.lock(); defer { verrou.unlock() }
        heure = heure.addingTimeInterval(secondes)
    }

    func regler(_ nouvelle: Date) {
        verrou.lock(); defer { verrou.unlock() }
        heure = nouvelle
    }
}
#endif
