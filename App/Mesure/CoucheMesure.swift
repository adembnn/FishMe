import Foundation
import Core
import StoreKit

/// Pourquoi le paywall s'est ouvert. Un choix parmi quelques valeurs, rien d'autre ne part avec `paywall_viewed`.
nonisolated enum DeclencheurPaywall: Sendable, Equatable, Hashable {
    case finPremiereSession
    case autreSpot
    case fonction(FonctionPro)
    /// Le widget aquarium (L15) : « Passer Pro » touché sur l'écran d'accueil.
    case widget
    /// Le 4e repère privé (N6) : les 3 repères gratuits sont posés.
    case reperes
    /// Un décor d'aquarium réservé à Pro (N1).
    case decors

    /// La valeur envoyée : un mot fixe, jamais de texte libre.
    var valeurMesure: String {
        switch self {
        case .finPremiereSession: return "fin_premiere_session"
        case .autreSpot: return "autre_spot"
        case .fonction(let fonction): return "fonction_\(fonction.rawValue)"
        case .widget: return "widget"
        case .reperes: return "reperes"
        case .decors: return "decors"
        }
    }
}

/// Ce que le paywall sait demander à la mesure (un faux suffit dans les tests de vue).
nonisolated protocol MesurePaywall: Sendable {
    func paywallMontre(declencheur: DeclencheurPaywall)
    /// Passe l'achat au SDK (`recordPurchase`), après l'accord seulement.
    func enregistrerAchat(_ resultat: Product.PurchaseResult) async
}

/// L'unique couche d'appel de la mesure : remplit le contrat `Mesure` de Core.
/// Règles : rien n'est configuré ni envoyé avant l'accord ; `configurer` part une seule fois ; refus ou retrait = plus rien ne part.
/// Seulement des compteurs, des durées arrondies et des choix : aucun événement ne porte de photo, d'espèce, de taille, de position ni de texte libre.
nonisolated final class CoucheMesure: Mesure, MesurePaywall, @unchecked Sendable {
    private let passerelle: PasserelleSDK
    private let coffre: CoffreConsentement
    private let verrou = NSLock()
    private var configure = false
    private var consentement: Consentement

    init(passerelle: PasserelleSDK, coffre: CoffreConsentement) {
        self.passerelle = passerelle
        self.coffre = coffre
        self.consentement = coffre.lire()
    }

    var etatConsentement: Consentement { verrou.withLock { consentement } }
    /// Vrai seulement si l'accord est donné et le SDK configuré.
    var actif: Bool { verrou.withLock { consentement == .accepte && configure } }

    // MARK: Consentement

    /// Au lancement : si l'accord a déjà été donné, on configure ; sinon on ne touche à rien.
    @MainActor func demarrerSiAccorde() {
        if etatConsentement == .accepte { configurerUneFois() }
    }

    @MainActor func accorder() {
        coffre.ecrire(.accepte)
        verrou.withLock { consentement = .accepte }
        configurerUneFois()
    }

    /// Refus : rien n'est initialisé.
    func refuser() { poser(.refuse) }

    /// Retrait de l'accord (Mon club, « Mesure d'usage ») : la couche cesse d'envoyer ; aux lancements suivants `configure` n'est plus appelé.
    func retirer() { poser(.refuse) }

    private func poser(_ valeur: Consentement) {
        coffre.ecrire(valeur)
        verrou.withLock { consentement = valeur }
    }

    @MainActor private func configurerUneFois() {
        let doitConfigurer = verrou.withLock { () -> Bool in
            if configure { return false }
            configure = true
            return true
        }
        if doitConfigurer { passerelle.configurer() }
    }

    // MARK: Événements

    func envoyer(_ evenement: EvenementMesure) {
        guard actif else { return }
        passerelle.evenement(type: Self.nom(evenement), proprietes: [:])
    }

    func paywallMontre(declencheur: DeclencheurPaywall) {
        guard actif else { return }
        passerelle.evenement(type: Self.nom(.paywallMontre), proprietes: ["declencheur": declencheur.valeurMesure])
    }

    static func nom(_ evenement: EvenementMesure) -> String {
        switch evenement {
        case .carteListe: return "map_ready"
        case .priseCommencee: return "capture_started"
        case .carteCreee: return "card_created"
        case .sessionCommencee: return "session_started"
        case .sessionFinie: return "session_ended"
        case .paywallMontre: return "paywall_viewed"
        }
    }

    // MARK: Achats (après l'accord seulement)

    func enregistrerAchat(_ resultat: Product.PurchaseResult) async {
        guard actif else { return }
        await passerelle.enregistrerAchat(resultat)
    }

    func enregistrerTransactions(_ transactions: [VerificationResult<Transaction>]) async {
        guard actif else { return }
        await passerelle.enregistrerTransactions(transactions)
    }
}
