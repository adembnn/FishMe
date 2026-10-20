import Foundation

// L22 -> L24 : la table de correspondance écrite dans `App/Club/ClubPourChat.swift`, en code (testable sans l'app entière).
// Le dossier Chat connaît le type de L22 `ClubPourChat` (même module) ; L22 ne connaît rien de L24.

extension InterlocuteurChat {
    /// Un membre de club. Compte inconnu : identifiant vide, « en attente de son profil » (`enAttenteDeProfil`), pas admis.
    /// Membre de la démo : `estExemple`, jamais admis.
    init(_ membre: MembrePourChat) {
        self.init(id: membre.profil, surnom: membre.surnom, idCloudKit: membre.idCloudKit ?? "", a15Ans: true,
                  estExemple: membre.estExemple)
    }
}

extension ClubChat {
    init(_ club: ClubPourChat) {
        self.init(id: club.id, nom: club.nom, jeSuisFondateur: club.jeSuisFondateur, membres: club.membres.map(InterlocuteurChat.init))
    }
}
