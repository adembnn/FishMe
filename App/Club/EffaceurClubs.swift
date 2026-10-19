import Foundation

/// « Supprimer mon profil » (L21) efface aussi ce que le profil a mis dans les clubs : ses cartes partagées et ses adhésions.
/// Branché sur `RegistreEffaceurs` (voir `enregistrer`). Si une étape échoue, l'erreur remonte : L21 garde le profil et la personne réessaie.
///  - membre : adhésion et cartes supprimées, le club continue ;
///  - fondateur seul : le club (enregistrement `Club`) est supprimé avec ses cartes ;
///  - fondateur avec d'autres membres : il part comme un membre, le club reste SANS fondateur (R2 : pas de transfert possible).
///    Écart avec `migration-clubs.md` (« efface les clubs dont il est fondateur ») : effacer un club vivant détruirait celui des autres.
///    ⚠ Le surnom d'un profil supprimé peut être repris par quelqu'un d'autre (`p-<surnom>`) : cette personne se croirait fondateur
///    (`Club.fondateur`) sans pouvoir rien écrire sur le club (le créateur de l'enregistrement reste l'ancien compte iCloud).
nonisolated struct EffaceurClubs: EffaceurContenu {
    let service: any ServiceClubs

    func effacerContenu(deProfil profilID: String) async throws {
        let miens = try await service.clubs(deProfil: profilID)
        for club in miens {
            let liste = try await service.membres(deClub: club.id)
            switch RegleAdhesion.sortie(club: club, membres: liste, profil: profilID) {
            case .fermer: try await service.supprimer(club: club.id, fondateur: profilID)
            case .quitter: try await service.quitter(club: club.id, profil: profilID)
            }
        }
    }

    /// A l'appelle une fois, à la composition de l'app (`RootView.swift`), avec le même service que `GestionClubs.partage`.
    @MainActor
    static func enregistrer(service: any ServiceClubs, dans registre: RegistreEffaceurs = .partage) {
        registre.ajouter(EffaceurClubs(service: service))
    }
}
