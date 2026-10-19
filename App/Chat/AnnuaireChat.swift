import Foundation

// Protocole minimal posé par L24 parce que L21 (profil, amis) et L22 (clubs CloudKit) ne sont pas fusionnés.
// Quand ils le seront, A écrit UN adaptateur qui implémente `AnnuaireChat` avec `ProfilModele`, la liste d'amis et `ServiceClubs`.
// Rien d'autre ne change dans ce dossier.

/// Une personne avec qui on peut écrire.
nonisolated struct InterlocuteurChat: Hashable, Identifiable, Sendable {
    /// Identifiant public de l'auteur (À aligner L21 : le `recordName` du `Profil`, « p-surnom »).
    var id: String
    /// Surnom de pêcheur (À aligner L21 : `surnomAffiche`). Jamais un nom réel.
    var surnom: String
    /// Identifiant CloudKit du compte (À aligner L21 : `Ami.id` de `App/Amis/CartePartagee.swift`). Sert à nommer la zone partagée.
    var idCloudKit: String
    /// A déclaré avoir 15 ans ou plus (déclaration faite dans L21). Faux : conversation en lecture seule, « Finis ton profil ».
    /// À aligner L21 : le champ réel du profil. Sans effet sur les AUTRES (on ne lit ce champ que pour `moi`).
    var a15Ans: Bool = true
}

/// Un club dont je suis membre (À aligner L22 : `Club.id`, `Club.nom`, `Membre`).
nonisolated struct ClubChat: Hashable, Identifiable, Sendable {
    var id: String
    var nom: String
    /// Le fondateur possède la zone partagée du club et seul il y admet des membres. R2: `Club.fondateur` ne change jamais
    /// (schema.md) : un club dont le fondateur est parti ne peut plus admettre personne. À réaligner avec Adem.
    var jeSuisFondateur: Bool
    /// Les autres membres (À aligner L22 : `Membre` + profils L21), avec leur identifiant CloudKit pour les admettre.
    var membres: [InterlocuteurChat]
}

nonisolated protocol AnnuaireChat: Sendable {
    /// Moi, ou `nil` tant que je n'ai pas de profil (« Finis ton profil », L21) : le chat se lit, mais n'envoie pas.
    func moi() async -> InterlocuteurChat?
    /// Mes amis (À aligner L21). Un ami bloqué dans L21 n'y figure plus.
    func amis() async -> [InterlocuteurChat]
    /// Mes clubs (À aligner L22).
    func clubs() async -> [ClubChat]
    /// Identifiants d'auteurs bloqués côté profil (À aligner L21 : liste `Blocage`, base privée). Peut être vide.
    func bloques() async -> Set<String>
}

/// Ce que L21 appelle `EffaceurContenu` : « Supprimer mon profil » efface aussi mes messages.
/// À aligner L21 : le protocole réel est dans `App/Profil/` ; A compose `GestionChat.effacerMesMessages()` dedans.
nonisolated protocol EffaceurMessages: Sendable {
    func effacerMesMessages() async throws
}
