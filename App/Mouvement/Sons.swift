import AVFoundation
import CoreHaptics
import Foundation

// Sons et vibrations de FishMe.
// Tous les sons sont synthétisés par nous (aucun audio tiers), fichiers `<nom>.caf`.

/// Les instants où l'app fait un son (et/ou une vibration).
/// La valeur texte est le nom du fichier, sans `.caf`.
enum MomentSonore: String, CaseIterable, Sendable {
    case lancement
    case toucher
    case retournement
    case montee
    case carteCommun = "carte-commun"
    case cartePeuCommun = "carte-peu-commun"
    case carteRare = "carte-rare"
    case carteLegendaire = "carte-legendaire"
    case plouf
    case bulles
    case moulinet
    case succes
    case alerte
}

// MARK: - Sons

@MainActor
enum Sons {
    private static let cleReglage = "reglages.sons"
    private static let joueursParSon = 2

    /// Les sons sont-ils activés ? (Réglages > Sons, oui par défaut)
    static var actifs: Bool {
        get { UserDefaults.standard.object(forKey: cleReglage) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: cleReglage) }
    }

    private static var sessionFaite = false
    private static var joueurs: [MomentSonore: [AVAudioPlayer]] = [:]
    /// Moments dont le fichier est absent : on ne le cherche pas deux fois.
    private static var absents: Set<MomentSonore> = []

    /// Joue un son. Ne fait rien si les sons sont coupés ou si le fichier manque.
    static func jouer(_ moment: MomentSonore) {
        guard actifs else { return }
        configurerSession()
        guard let joueur = joueurLibre(pour: moment) else { return }
        // Petite variation à chaque lecture pour que ça sonne naturel.
        joueur.rate = Float.random(in: 0.97...1.03)
        let decibels = Float.random(in: -1...1)
        joueur.volume = min(1, 0.9 * powf(10, decibels / 20))
        joueur.currentTime = 0
        joueur.play()
    }

    /// Charge tous les sons d'avance (à appeler au lancement).
    static func prechauffer() {
        guard actifs else { return }
        configurerSession()
        for moment in MomentSonore.allCases {
            _ = preparer(moment)
        }
    }

    // MARK: Détails

    /// Mode « ambiant » : respecte le bouton silence et ne coupe jamais la musique.
    private static func configurerSession() {
        guard !sessionFaite else { return }
        sessionFaite = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private static func trouverFichier(_ moment: MomentSonore) -> URL? {
        let nom = moment.rawValue
        return Bundle.main.url(forResource: nom, withExtension: "caf")
            ?? Bundle.main.url(forResource: nom, withExtension: "caf", subdirectory: "Sons")
    }

    /// Crée les deux lecteurs d'un son, la première fois seulement.
    private static func preparer(_ moment: MomentSonore) -> [AVAudioPlayer] {
        if let existants = joueurs[moment] { return existants }
        guard !absents.contains(moment), let url = trouverFichier(moment) else {
            absents.insert(moment)
            return []
        }
        var liste: [AVAudioPlayer] = []
        for _ in 0..<joueursParSon {
            guard let joueur = try? AVAudioPlayer(contentsOf: url) else { continue }
            joueur.enableRate = true
            joueur.prepareToPlay()
            liste.append(joueur)
        }
        if liste.isEmpty {
            absents.insert(moment)
            return []
        }
        joueurs[moment] = liste
        return liste
    }

    /// Un lecteur qui ne joue pas déjà, sinon le premier (il repart du début).
    private static func joueurLibre(pour moment: MomentSonore) -> AVAudioPlayer? {
        let liste = preparer(moment)
        return liste.first(where: { !$0.isPlaying }) ?? liste.first
    }
}

// MARK: - Vibrations

@MainActor
enum Vibrations {
    private static let cleReglage = "reglages.vibrations"

    /// Les vibrations sont-elles activées ? (Réglages > Vibrations, oui par défaut)
    static var actives: Bool {
        get { UserDefaults.standard.object(forKey: cleReglage) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: cleReglage) }
    }

    private static var moteur: CHHapticEngine?

    /// Fait vibrer pour ce moment. Ne fait rien sans moteur haptique ni en cas d'erreur.
    static func jouer(_ moment: MomentSonore) {
        guard actives else { return }
        guard let evenements = motif(pour: moment) else { return }
        guard let moteur = moteurPret() else { return }
        do {
            try moteur.start()
            let schema = try CHHapticPattern(events: evenements.evenements,
                                            parameterCurves: evenements.courbes)
            let joueur = try moteur.makePlayer(with: schema)
            try joueur.start(atTime: CHHapticTimeImmediate)
        } catch {
            // On ignore : une vibration ratée ne doit jamais gêner.
        }
    }

    // MARK: Moteur

    private static func moteurPret() -> CHHapticEngine? {
        if let moteur { return moteur }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return nil }
        guard let nouveau = try? CHHapticEngine() else { return nil }
        nouveau.isAutoShutdownEnabled = true
        // Ces gestionnaires tournent hors du fil principal : `@Sendable` évite le contrôle d'acteur de Swift 6 (plantage),
        // et on revient sur le fil principal avant de toucher l'état.
        nouveau.stoppedHandler = { @Sendable _ in
            Task { @MainActor in Vibrations.redemarrer() }
        }
        nouveau.resetHandler = { @Sendable in
            Task { @MainActor in Vibrations.redemarrer() }
        }
        moteur = nouveau
        return nouveau
    }

    private static func redemarrer() {
        try? moteur?.start()
    }

    // MARK: Motifs

    private struct Motif {
        var evenements: [CHHapticEvent]
        var courbes: [CHHapticParameterCurve] = []
    }

    private static func parametres(_ intensite: Float, _ nettete: Float) -> [CHHapticEventParameter] {
        [CHHapticEventParameter(parameterID: .hapticIntensity, value: intensite),
         CHHapticEventParameter(parameterID: .hapticSharpness, value: nettete)]
    }

    private static func claque(_ intensite: Float, _ nettete: Float, a temps: TimeInterval = 0) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: parametres(intensite, nettete), relativeTime: temps)
    }

    /// Événement continu : l'intensité réelle vient de la courbe (l'événement est à 1).
    private static func continu(duree: TimeInterval, nettete: Float, a temps: TimeInterval = 0) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticContinuous, parameters: parametres(1, nettete),
                      relativeTime: temps, duration: duree)
    }

    private static func courbe(_ id: CHHapticDynamicParameter.ID,
                               de debut: Float, vers fin: Float,
                               duree: TimeInterval, a temps: TimeInterval = 0) -> CHHapticParameterCurve {
        CHHapticParameterCurve(
            parameterID: id,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: debut),
                CHHapticParameterCurve.ControlPoint(relativeTime: duree, value: fin)
            ],
            relativeTime: temps)
    }

    private static func motif(pour moment: MomentSonore) -> Motif? {
        switch moment {
        case .toucher:
            return Motif(evenements: [claque(0.35, 0.6)])
        case .retournement:
            return Motif(evenements: [claque(0.5, 0.4)])
        case .montee:
            return Motif(
                evenements: [continu(duree: 0.9, nettete: 0.3)],
                courbes: [courbe(.hapticIntensityControl, de: 0.15, vers: 0.8, duree: 0.9),
                          courbe(.hapticSharpnessControl, de: 0.3, vers: 0.6, duree: 0.9)])
        case .carteCommun:
            return Motif(evenements: [claque(0.5, 0.5)])
        case .cartePeuCommun:
            return Motif(evenements: [claque(0.55, 0.5), claque(0.7, 0.5, a: 0.09)])
        case .carteRare:
            return Motif(
                evenements: [continu(duree: 0.35, nettete: 0.5), claque(1.0, 0.8, a: 0.35)],
                courbes: [courbe(.hapticIntensityControl, de: 0.2, vers: 0.7, duree: 0.35)])
        case .carteLegendaire:
            return Motif(
                evenements: [continu(duree: 0.6, nettete: 0.5),
                             claque(1.0, 1.0, a: 0.6),
                             continu(duree: 0.6, nettete: 0.4, a: 0.6)],
                courbes: [courbe(.hapticIntensityControl, de: 0.2, vers: 1.0, duree: 0.6),
                          courbe(.hapticIntensityControl, de: 0.6, vers: 0, duree: 0.6, a: 0.6)])
        case .plouf:
            return Motif(evenements: [claque(0.7, 0.3)])
        case .succes:
            return Motif(evenements: [claque(0.5, 0.5), claque(0.8, 0.5, a: 0.12)])
        case .alerte:
            return Motif(evenements: [claque(0.6, 0.5), claque(0.6, 0.5, a: 0.14), claque(0.6, 0.5, a: 0.28)])
        case .moulinet:
            return Motif(evenements: (0..<6).map { claque(0.25, 0.5, a: Double($0) * 0.05) })
        case .lancement, .bulles:
            return nil
        }
    }
}
