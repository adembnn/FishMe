import Foundation

/// Ce que le chat de club (L24) demande à L22 : mes clubs, qui est fondateur, qui sont les autres membres.
/// L24 a posé son propre protocole `AnnuaireChat` / `ClubChat` (App/Chat, pas encore fusionné) : A écrit UN adaptateur qui
/// transforme ceci en `ClubChat` / `InterlocuteurChat`. Aucun import de L24 ici : les deux lots restent indépendants.
///   `ClubChat.id`               <- `ClubPourChat.id` (l'UUID du club)
///   `ClubChat.jeSuisFondateur`  <- `ClubPourChat.jeSuisFondateur` (faux dès que le fondateur est parti : R2, pas de transfert)
///   `InterlocuteurChat.id`      <- `MembrePourChat.profil` (`p-<surnom>`)
///   `InterlocuteurChat.surnom`  <- `MembrePourChat.surnom`
///   `InterlocuteurChat.idCloudKit` <- `MembrePourChat.idCloudKit` (vide : ce membre ne peut pas encore être admis dans la zone du chat)
nonisolated struct MembrePourChat: Sendable, Equatable, Hashable {
    var profil: String
    var surnom: String
    var idCloudKit: String?
}

nonisolated struct ClubPourChat: Sendable, Equatable, Hashable, Identifiable {
    var id: String
    var nom: String
    var jeSuisFondateur: Bool
    /// Les AUTRES membres, sans les écartés ni les bloqués.
    var membres: [MembrePourChat]
}

extension GestionClubs {
    /// Mes clubs en ligne pour le chat. Un club fermé ou sans fondateur est rendu quand même (lecture) avec `jeSuisFondateur` à faux.
    func clubsPourChat() -> [ClubPourChat] {
        clubs.map { club in
            ClubPourChat(
                id: club.id, nom: club.nom, jeSuisFondateur: jeSuisFondateur(de: club),
                membres: membresVisibles(de: club).filter { $0.profil != monID }.map {
                    MembrePourChat(profil: $0.profil, surnom: surnom(de: $0.profil), idCloudKit: $0.idCloudKit)
                })
        }
    }
}
