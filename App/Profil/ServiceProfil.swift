import Foundation

/// Tout ce que l'app demande à CloudKit au sujet des profils, derrière un protocole : le vrai (`ServiceProfilCloudKit`) et le faux des tests.
nonisolated protocol ServiceProfil: Sendable {
    /// Le profil de cet identifiant, ou `nil` s'il n'existe pas (ou plus).
    func profil(id: String) async throws -> ProfilModele?
    /// Vrai si personne n'a ce surnom (normalisé). Première des deux vérifications : avant l'écriture.
    func surnomEstLibre(_ surnom: String) async throws -> Bool
    /// Écrit le profil. Lève `.surnomPris` si quelqu'un a écrit le même surnom entre-temps : le second perd.
    func creer(surnom: String, avatar: Data?) async throws -> ProfilModele
    func changerAvatar(id: String, avatar: Data?) async throws -> ProfilModele
    /// Profils dont le surnom normalisé commence par ce texte (3 caractères au moins), 20 au plus.
    func chercher(prefixe: String) async throws -> [ProfilModele]
    /// Efface l'enregistrement `Profil` et son avatar. Ne touche pas aux publications (c'est `EffaceurContenu`).
    func supprimer(id: String) async throws
    /// Écrit la trace d'un signalement. L'e-mail prérempli reste le circuit principal (`moderation.md`).
    func signaler(profilID: String, motif: MotifSignalement, par monID: String?) async throws
}

#if DEBUG
/// Faux service en mémoire pour les tests et les aperçus. Aucun appel à iCloud.
actor FauxServiceProfil: ServiceProfil {
    private var profils: [String: ProfilModele]
    private var horsLigne: Bool
    /// Surnoms que `surnomEstLibre` croit libres mais qu'un autre iPhone vient d'écrire : la course de la fiche.
    private var pris: Set<String> = []
    private(set) var signalements: [(profilID: String, motif: MotifSignalement)] = []
    private(set) var ecritures = 0

    init(profils: [ProfilModele] = [], horsLigne: Bool = false) {
        self.profils = Dictionary(uniqueKeysWithValues: profils.map { ($0.id, $0) })
        self.horsLigne = horsLigne
    }

    func regler(horsLigne: Bool) { self.horsLigne = horsLigne }

    /// Simule un autre iPhone qui écrit ce surnom juste après la première vérification.
    func glisserConcurrent(surnom: String) { pris.insert(Surnom.identifiant(pour: surnom)) }

    func profil(id: String) async throws -> ProfilModele? {
        if horsLigne { throw ErreurProfil.reseau }
        return profils[id]
    }

    func surnomEstLibre(_ surnom: String) async throws -> Bool {
        if horsLigne { throw ErreurProfil.reseau }
        return profils[Surnom.identifiant(pour: surnom)] == nil
    }

    func creer(surnom: String, avatar: Data?) async throws -> ProfilModele {
        if horsLigne { throw ErreurProfil.reseau }
        let id = Surnom.identifiant(pour: surnom)
        if profils[id] != nil || pris.contains(id) { throw ErreurProfil.surnomPris }
        let profil = ProfilModele(id: id, surnom: surnom.trimmingCharacters(in: .whitespacesAndNewlines), avatar: avatar, creeLe: Date())
        profils[id] = profil
        ecritures += 1
        return profil
    }

    func changerAvatar(id: String, avatar: Data?) async throws -> ProfilModele {
        if horsLigne { throw ErreurProfil.reseau }
        guard var profil = profils[id] else { throw ErreurProfil.introuvable }
        profil.avatar = avatar
        profils[id] = profil
        return profil
    }

    func chercher(prefixe: String) async throws -> [ProfilModele] {
        if horsLigne { throw ErreurProfil.reseau }
        let cle = Surnom.normaliser(prefixe)
        guard cle.count >= 3 else { return [] }
        return profils.values.filter { Surnom.normaliser($0.surnom).hasPrefix(cle) }.sorted { $0.id < $1.id }
    }

    func supprimer(id: String) async throws {
        if horsLigne { throw ErreurProfil.reseau }
        profils[id] = nil
    }

    func signaler(profilID: String, motif: MotifSignalement, par monID: String?) async throws {
        if horsLigne { throw ErreurProfil.reseau }
        signalements.append((profilID, motif))
    }

    func contient(_ id: String) -> Bool { profils[id] != nil }
}

/// Un effaceur factice : compte ce qu'on lui demande, ou échoue.
actor EffaceurFaux: EffaceurContenu {
    private(set) var appels: [String] = []
    private let echoue: Bool

    init(echoue: Bool = false) { self.echoue = echoue }

    func effacerContenu(deProfil profilID: String) async throws {
        appels.append(profilID)
        if echoue { throw ErreurProfil.reseau }
    }
}
#endif
