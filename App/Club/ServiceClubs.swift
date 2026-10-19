import Foundation

/// Tout ce que l'app demande à CloudKit au sujet des clubs, derrière un protocole : le vrai (`ServiceClubsCloudKit`) et le faux des tests.
/// Les règles (club fermé, membre écarté, fondateur parti) sont dans `RegleAdhesion`, pas ici : le service écrit, il ne décide pas.
nonisolated protocol ServiceClubs: Sendable {
    /// Vrai si le compte iCloud est utilisable.
    func iCloudDisponible() async -> Bool
    /// Écrit `Club` puis le `Membre` fondateur. `id` est choisi par l'appelant : le même UUID rejoue la même écriture sans doublon
    /// (migration). Si le club existe déjà avec cet `id`, rend l'existant.
    func creer(id: String, nom: String, poissonId: String?, image: Data?, fondateur: String, le date: Date) async throws -> Club
    func club(id: String) async throws -> Club?
    func membres(deClub id: String) async throws -> [Membre]
    /// Les clubs où ce profil a une adhésion.
    func clubs(deProfil profil: String) async throws -> [Club]
    /// Écrit mon adhésion (rôle membre). Déjà membre : rend l'adhésion existante.
    func rejoindre(club id: String, profil: String, le date: Date) async throws -> Membre
    /// Supprime mon adhésion ET mes cartes partagées à ce club (`pc-<club>-*`). Les cartes des autres ne bougent pas.
    func quitter(club id: String, profil: String) async throws
    /// Fondateur seul dans son club : `ferme` = vrai, ses cartes et son adhésion sont supprimées.
    func fermer(club id: String, fondateur: String) async throws
    /// Fondateur : ajoute le profil à `Club.retires`. R2 : on ne peut pas supprimer le `Membre` d'un autre ; ses cartes restent en base
    /// mais ne sont plus affichées, et son iPhone les efface lui-même au prochain chargement (`GestionClubs.rafraichir`).
    /// ⚠ Cela ne retire PAS l'accès à la zone partagée du chat de club (L24) : seul le fondateur peut retirer le participant du `CKShare`.
    func ecarter(profil: String, deClub id: String) async throws
    func partager(_ carte: CartePartageeClub) async throws
    func retirerCarte(id: String) async throws
    func cartes(deClub id: String) async throws -> [CartePartageeClub]
    /// Trace d'un signalement (`Signalement`, base publique). L'e-mail prérempli reste le circuit principal (`moderation.md`).
    func signaler(cible: String, typeCible: String, motif: MotifSignalement, par monID: String?) async throws
}

#if DEBUG
/// Faux service en mémoire pour les tests et les aperçus. Aucun appel à iCloud.
actor FauxServiceClubs: ServiceClubs {
    private(set) var clubsParID: [String: Club] = [:]
    private(set) var adhesions: [String: Membre] = [:]
    private(set) var cartesParID: [String: CartePartageeClub] = [:]
    private(set) var signalements: [(cible: String, typeCible: String, motif: MotifSignalement)] = []
    private(set) var ecritures = 0
    private var horsLigne: Bool
    private var icloud: Bool

    init(horsLigne: Bool = false, icloud: Bool = true) {
        self.horsLigne = horsLigne
        self.icloud = icloud
    }

    func regler(horsLigne: Bool) { self.horsLigne = horsLigne }
    func regler(icloud: Bool) { self.icloud = icloud }

    private func verifier() throws {
        if !icloud { throw ErreurClub.iCloudIndisponible }
        if horsLigne { throw ErreurClub.reseau }
    }

    func iCloudDisponible() async -> Bool { icloud }

    func creer(id: String, nom: String, poissonId: String?, image: Data?, fondateur: String, le date: Date) async throws -> Club {
        try verifier()
        if let existant = clubsParID[id] { return existant }
        let club = Club(id: id, nom: nom, poissonId: poissonId, image: image, fondateur: fondateur, creeLe: date)
        clubsParID[id] = club
        let adhesion = Membre(id: Membre.identifiant(club: id, profil: fondateur), club: id, profil: fondateur, role: .fondateur, depuis: date)
        adhesions[adhesion.id] = adhesion
        ecritures += 2
        return club
    }

    func club(id: String) async throws -> Club? {
        try verifier()
        return clubsParID[id]
    }

    func membres(deClub id: String) async throws -> [Membre] {
        try verifier()
        return adhesions.values.filter { $0.club == id }.sorted { ($0.depuis, $0.id) < ($1.depuis, $1.id) }
    }

    func clubs(deProfil profil: String) async throws -> [Club] {
        try verifier()
        let ids = adhesions.values.filter { $0.profil == profil }.map(\.club)
        return ids.compactMap { clubsParID[$0] }.sorted { $0.creeLe < $1.creeLe }
    }

    func rejoindre(club id: String, profil: String, le date: Date) async throws -> Membre {
        try verifier()
        guard clubsParID[id] != nil else { throw ErreurClub.introuvable }
        let cle = Membre.identifiant(club: id, profil: profil)
        if let existant = adhesions[cle] { return existant }
        let adhesion = Membre(id: cle, club: id, profil: profil, role: .membre, depuis: date)
        adhesions[cle] = adhesion
        ecritures += 1
        return adhesion
    }

    func quitter(club id: String, profil: String) async throws {
        try verifier()
        adhesions[Membre.identifiant(club: id, profil: profil)] = nil
        for (cle, carte) in cartesParID where carte.club == id && carte.auteur == profil && cle.hasPrefix("pc-\(id)-") {
            cartesParID[cle] = nil
        }
        ecritures += 1
    }

    func fermer(club id: String, fondateur: String) async throws {
        try verifier()
        guard var club = clubsParID[id] else { throw ErreurClub.introuvable }
        guard club.fondateur == fondateur else { throw ErreurClub.refuse }
        club.ferme = true
        clubsParID[id] = club
        try await quitter(club: id, profil: fondateur)
    }

    func ecarter(profil: String, deClub id: String) async throws {
        try verifier()
        guard var club = clubsParID[id] else { throw ErreurClub.introuvable }
        if !club.retires.contains(profil) { club.retires.append(profil) }
        clubsParID[id] = club
        ecritures += 1
    }

    func partager(_ carte: CartePartageeClub) async throws {
        try verifier()
        cartesParID[carte.id] = carte
        ecritures += 1
    }

    func retirerCarte(id: String) async throws {
        try verifier()
        cartesParID[id] = nil
    }

    func cartes(deClub id: String) async throws -> [CartePartageeClub] {
        try verifier()
        return cartesParID.values.filter { $0.club == id }.sorted { ($0.creeLe, $0.id) > ($1.creeLe, $1.id) }
    }

    func signaler(cible: String, typeCible: String, motif: MotifSignalement, par monID: String?) async throws {
        try verifier()
        signalements.append((cible, typeCible, motif))
    }

    /// Pour les tests : pose un club déjà là, sans passer par `creer`.
    func poser(club: Club, membres: [Membre] = []) {
        clubsParID[club.id] = club
        for m in membres { adhesions[m.id] = m }
    }
}
#endif
