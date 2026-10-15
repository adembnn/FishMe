import Foundation

/// Réponse du pêcheur à la demi-feuille de mesure d'usage.
nonisolated enum Consentement: String, Sendable, Equatable {
    /// Pas encore posé la question : rien n'est initialisé.
    case inconnu
    case accepte
    /// Refus ou accord retiré dans Mon club : SDK éteint, rien n'est envoyé.
    case refuse
}

/// Où l'on garde la réponse. Un protocole pour que les tests n'écrivent pas dans les réglages de l'iPhone.
nonisolated protocol CoffreConsentement: Sendable {
    func lire() -> Consentement
    func ecrire(_ valeur: Consentement)
}

nonisolated final class CoffreConsentementMemoire: CoffreConsentement, @unchecked Sendable {
    private let verrou = NSLock()
    private var valeur: Consentement

    init(_ valeur: Consentement = .inconnu) { self.valeur = valeur }

    func lire() -> Consentement { verrou.withLock { valeur } }
    func ecrire(_ nouvelle: Consentement) { verrou.withLock { valeur = nouvelle } }
}

nonisolated struct CoffreConsentementReglages: CoffreConsentement, @unchecked Sendable {
    private let reglages: UserDefaults
    private let cle = "mesure.consentement"

    init(reglages: UserDefaults = .standard) { self.reglages = reglages }

    func lire() -> Consentement { reglages.string(forKey: cle).flatMap(Consentement.init(rawValue:)) ?? .inconnu }
    func ecrire(_ valeur: Consentement) { reglages.set(valeur.rawValue, forKey: cle) }
}
