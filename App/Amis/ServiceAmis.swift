import CloudKit
import Foundation

/// Réglages donnés par A dans RootView.swift. Le contact est celui publié dans Mon club : il n'est jamais inventé ici.
nonisolated struct ConfigurationAmis: Sendable {
    /// Adresse e-mail publiée (règle 1.2 d'Apple) : les signalements y partent.
    var contact: String
    static let conteneurParDefaut = "iCloud.ai.mwm.build.challenge.team.01"
    var conteneur: String = Self.conteneurParDefaut
}

/// Un partage CloudKit prêt à être envoyé. `CKShare` n'est pas `Sendable` : il ne traverse qu'ici, une seule fois.
nonisolated struct PartagePret: @unchecked Sendable {
    let share: CKShare
}

/// Une invitation reçue par lien. Le `CKShare.Metadata` est gardé tel quel pour `CKContainer.accept`.
nonisolated struct InvitationRecue: @unchecked Sendable {
    var nomAmi: String
    var metadata: CKShare.Metadata?
}

/// Tout ce que l'app demande à CloudKit, derrière un protocole : le vrai service (`ServiceAmisCloudKit`) et le faux des tests.
nonisolated protocol ServiceAmis: Sendable {
    func etatCompte() async -> EtatCompte
    /// Écrit ces cartes dans la zone partagée de la personne. Lève `.reseau` hors ligne : l'appelant garde l'envoi à rejouer.
    func publier(_ cartes: [CartePartagee]) async throws
    /// Crée la zone et son partage (lien réservé aux personnes invitées, lecture seule) ou rend celui qui existe.
    func partagePret() async throws -> PartagePret
    /// Les personnes que j'ai invitées (participants de mon partage).
    func amisInvites() async throws -> [Ami]
    /// Les collections de ceux qui m'ont invité.
    func collectionsRecues() async throws -> [CollectionAmi]
    /// Retire un participant de mon partage : il ne voit plus mes cartes.
    func retirerInvite(_ ami: Ami) async throws
    /// Quitte le partage d'un ami : je ne vois plus ses cartes.
    func quitterPartage(de ami: Ami) async throws
    /// Supprime la zone : toutes mes cartes partagées disparaissent chez les amis, le partage s'arrête.
    func supprimerMesCartes() async throws
    /// Accepte le lien reçu. Rend l'ami qui m'a invité.
    func accepter(_ invitation: InvitationRecue) async throws -> Ami
}
