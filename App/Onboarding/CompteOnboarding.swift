import Foundation
import Observation

/// Le cerveau du compte créé pendant l'onboarding (et supprimé dans Réglages). Local d'abord : surnom dans `UserDefaults`,
/// e-mail dans le trousseau. L'e-mail n'est JAMAIS gardé ni envoyé sans la case de consentement (Apple 5.1.1) ; il est facultatif.
@MainActor
@Observable
final class CompteOnboarding {
    enum Echec: Equatable {
        case surnom(Surnom.Refus)
        case emailInvalide
        case ageRequis
    }

    private let defauts: UserDefaults
    private let stockage: any StockageEmail
    private let collecte: any ServiceCollecteEmail
    private let filtre: any FiltreMots

    /// Le surnom gardé, ou `nil`.
    private(set) var surnom: String?
    /// L'e-mail gardé (consenti), ou `nil`.
    private(set) var email: String?

    init(defauts: UserDefaults = .standard, stockage: any StockageEmail = StockageEmailTrousseau(),
         collecte: any ServiceCollecteEmail = CollecteEmailHTTP(), filtre: any FiltreMots = FiltreCore()) {
        self.defauts = defauts
        self.stockage = stockage
        self.collecte = collecte
        self.filtre = filtre
        self.surnom = CompteLocal.surnom(defauts)
        self.email = CompteLocal.emailConsenti(defauts) ? stockage.lire() : nil
    }

    static let partage = CompteOnboarding()

    var aUnCompte: Bool { surnom != nil || email != nil }

    /// Contrôle sans rien écrire : `nil` si tout est permis. `emailBrut` vide : pas d'e-mail, pas de contrôle.
    func controler(surnom brut: String, ageDeclare: Bool, email emailBrut: String, consentement: Bool) -> Echec? {
        if let refus = Surnom.verifier(brut, filtre: filtre) { return .surnom(refus) }
        if !ageDeclare { return .ageRequis }
        if consentement, !AdresseEmail.nettoyer(emailBrut).isEmpty, !AdresseEmail.estValide(emailBrut) { return .emailInvalide }
        return nil
    }

    /// Enregistre le surnom (toujours local) puis, SI le pêcheur a coché la case et que l'adresse est valide, l'e-mail (trousseau,
    /// puis envoi au point de terminaison s'il est configuré). Rend l'échec de validation, ou `nil`.
    @discardableResult
    func enregistrer(surnom brut: String, ageDeclare: Bool, email emailBrut: String, consentement: Bool,
                     langue: String) async -> Echec? {
        if let echec = controler(surnom: brut, ageDeclare: ageDeclare, email: emailBrut, consentement: consentement) { return echec }
        let propre = brut.trimmingCharacters(in: .whitespacesAndNewlines)
        defauts.set(propre, forKey: CompteLocal.cleSurnom)
        surnom = propre
        let adresse = AdresseEmail.nettoyer(emailBrut)
        if consentement, AdresseEmail.estValide(adresse) {
            stockage.ecrire(adresse)
            defauts.set(true, forKey: CompteLocal.cleConsentement)
            email = adresse
            _ = await collecte.envoyer(email: adresse, langue: langue)
        } else {
            // Pas de consentement : aucune trace d'e-mail.
            stockage.effacer()
            defauts.set(false, forKey: CompteLocal.cleConsentement)
            email = nil
        }
        defauts.set(true, forKey: CompteLocal.cleOnboardingFait)
        return nil
    }

    /// Réglages : retire l'e-mail du trousseau et demande son effacement au serveur (s'il y en a un).
    func supprimerEmail() async {
        let adresse = email ?? stockage.lire()
        stockage.effacer()
        defauts.set(false, forKey: CompteLocal.cleConsentement)
        email = nil
        if let adresse { _ = await collecte.supprimer(email: adresse) }
    }

    /// Réglages : supprime le compte local en entier (surnom et e-mail).
    func supprimerCompte() async {
        await supprimerEmail()
        defauts.removeObject(forKey: CompteLocal.cleSurnom)
        defauts.removeObject(forKey: CompteLocal.cleOnboardingFait)
        surnom = nil
    }
}
