import Foundation
import Observation

/// Le cerveau du profil : créer (surnom vérifié avant et après l'écriture), retrouver, changer l'avatar, signaler, bloquer, supprimer.
/// Tout CloudKit passe par `ServiceProfil`. Juste un pseudonyme (décision 3) : aucun nom ni prénom n'est collecté.
@MainActor
@Observable
final class GestionProfil {
    enum Message: Equatable {
        case surnomRefuse(Surnom.Refus)
        case surnomPris
        /// Sans la déclaration « J'ai 15 ans ou plus », aucun profil public.
        case ageRequis
        /// Sans la case « J'accepte les conditions », aucun profil public (décision du 19 oct.).
        case conditionsRequises
        case profilIntrouvable
        case horsLigne
        case iCloudIndisponible
        case imageRefusee
        case suppressionIncomplete
        case echec

        var texte: String {
            switch self {
            case .surnomRefuse(let refus): Surnom.phrase(pour: refus)
            case .surnomPris: "Ce surnom est déjà pris. Choisis-en un autre."
            case .ageRequis: "Le profil public est réservé aux 15 ans et plus."
            case .conditionsRequises: "Accepte les conditions pour créer ton profil."
            case .profilIntrouvable: "Aucun profil à toi n'a été trouvé avec ce compte iCloud."
            case .horsLigne: "Pas de réseau. Réessaie plus tard."
            case .iCloudIndisponible: "Connecte-toi à iCloud pour créer ton profil."
            case .imageRefusee: "Cette image ne marche pas. Essaie-en une autre."
            case .suppressionIncomplete: "Tout n'a pas pu être effacé. Ton profil est gardé : réessaie."
            case .echec: "Ça n'a pas marché. Réessaie."
            }
        }
    }

    private(set) var profil: ProfilModele?
    private(set) var message: Message?
    private(set) var enCours = false

    let service: any ServiceProfil
    private let memoire: any MemoireProfil
    private let blocages: ListeBlocages
    private let filtre: any FiltreMots
    /// Fournis en plus par le registre (L23, L24) : A les compose à l'ouverture de l'app.
    private let effaceursFixes: [any EffaceurContenu]
    /// Le registre lu à la suppression : celui de l'app, ou un registre vide dans les tests (l'app hôte y a branché les vrais effaceurs).
    private let registre: RegistreEffaceurs
    /// Appelé après une création, une reprise ou une suppression : le titre du `CKShare` d'amis suit le surnom (rien dans les tests).
    private let apresChangementDeSurnom: @Sendable () async -> Void

    init(service: any ServiceProfil, memoire: any MemoireProfil = MemoireProfilLocale(),
         blocages: ListeBlocages = .partage, filtre: any FiltreMots = FiltreCore(), effaceurs: [any EffaceurContenu] = [],
         registre: RegistreEffaceurs = .partage,
         apresChangementDeSurnom: @escaping @Sendable () async -> Void = {}) {
        self.service = service
        self.memoire = memoire
        self.blocages = blocages
        self.filtre = filtre
        self.effaceursFixes = effaceurs
        self.registre = registre
        self.apresChangementDeSurnom = apresChangementDeSurnom
    }

    /// Le profil partagé par toute l'app (le vrai CloudKit). Créé à la première demande seulement.
    static let partage = GestionProfil(service: ServiceProfilCloudKit(conteneur: ConfigurationAmis.conteneurParDefaut),
                                       apresChangementDeSurnom: { await TitrePartage.synchroniser() })

    // MARK: État

    /// Vrai dès que l'iPhone se souvient d'un profil, même hors ligne : « Finis ton profil » ne revient alors jamais.
    var aUnProfil: Bool { profil != nil || memoire.idProfil() != nil }

    var monID: String? { profil?.id ?? memoire.idProfil() }

    /// Le surnom gardé sur l'iPhone : de quoi nommer « Mon profil » quand le réseau manque et que `profil` est vide.
    var surnomMemorise: String? { profil?.surnom ?? memoire.surnom() }

    /// Relit mon profil depuis CloudKit s'il existe. Hors ligne, l'identifiant gardé suffit à savoir qu'il existe.
    func charger() async {
        // Décision 3 : les anciens champs nom et prénom des versions de test ne sont plus relus ; on les efface.
        AnciensChampsIdentite.purger()
        guard let id = memoire.idProfil() else { return }
        do {
            if let relu = try await service.profil(id: id) {
                profil = relu
            } else {
                // Effacé ailleurs (tableau de bord) : l'app continue sans profil.
                profil = nil
                memoire.oublier()
                await apresChangementDeSurnom()
            }
        } catch {
            message = traduire(error)
        }
    }

    // MARK: Créer

    /// `nil` si le surnom est permis, sinon le refus à montrer sous le champ.
    func verifier(surnom: String) -> Surnom.Refus? {
        Surnom.verifier(surnom, filtre: filtre)
    }

    /// Crée le profil. Vrai si c'est fait. Un surnom pris est refusé AVANT l'écriture ; si deux iPhones écrivent en même temps,
    /// le second reçoit `.surnomPris` de l'écriture et choisit un autre surnom.
    /// Si le surnom « pris » est en fait le mien (réponse perdue, réinstallation : `creatorUserRecordID` égal à moi), je le reprends.
    @discardableResult
    func creer(surnom: String, avatar: Data?, aQuinzeAns: Bool, accepteLesConditions: Bool) async -> Bool {
        // R2: 15 ans minimum (décision de Titouan, à confirmer par le juridique ; Declared Age Range d'Apple ⚠ à étudier).
        // Simple déclaration : rien n'est stocké, ni date de naissance ni la case cochée. Sans elle, l'app reste utilisable.
        guard aQuinzeAns else {
            message = .ageRequis
            return false
        }
        // Décision du 19 oct. : la case « J'accepte les conditions » est obligatoire avant le profil public.
        guard accepteLesConditions else {
            message = .conditionsRequises
            return false
        }
        if let refus = verifier(surnom: surnom) {
            message = .surnomRefuse(refus)
            return false
        }
        enCours = true
        defer { enCours = false }
        let id = Surnom.identifiant(pour: surnom)
        do {
            guard try await service.surnomEstLibre(surnom) else {
                if let mien = try await service.profilDontJeSuisLAuteur(id: id) {
                    await adopter(mien)
                    return true
                }
                message = .surnomPris
                return false
            }
            let cree: ProfilModele
            do {
                cree = try await service.creer(surnom: surnom, avatar: avatar)
            } catch ErreurProfil.surnomPris {
                // Perdu la course ? Ou gagné, avec une relecture qui a mal tourné ? Le seul juge est l'auteur de l'enregistrement.
                guard let mien = try await service.profilDontJeSuisLAuteur(id: id) else { throw ErreurProfil.surnomPris }
                await adopter(mien)
                return true
            }
            await adopter(cree)
            return true
        } catch {
            message = traduire(error)
            return false
        }
    }

    /// « Retrouver mon profil » : relit le profil public dont je suis l'auteur, au lieu de dire « surnom pris ».
    /// Essaie d'abord le surnom tapé (s'il y en a un), puis la recherche par auteur (utile après une réinstallation, sans surnom).
    @discardableResult
    func retrouver(surnom: String? = nil) async -> Bool {
        enCours = true
        defer { enCours = false }
        do {
            var trouve: ProfilModele?
            if let surnom, verifier(surnom: surnom) == nil {
                trouve = try await service.profilDontJeSuisLAuteur(id: Surnom.identifiant(pour: surnom))
            }
            if trouve == nil { trouve = try await service.monProfilPublic() }
            guard let trouve else {
                message = .profilIntrouvable
                return false
            }
            await adopter(trouve)
            return true
        } catch {
            message = traduire(error)
            return false
        }
    }

    private func adopter(_ trouve: ProfilModele) async {
        profil = trouve
        memoire.retenir(id: trouve.id, surnom: trouve.surnom)
        message = nil
        await apresChangementDeSurnom()
    }

    func changerAvatar(_ donnees: Data?) async {
        guard let id = monID else { return }
        enCours = true
        defer { enCours = false }
        do {
            profil = try await service.changerAvatar(id: id, avatar: donnees)
            message = nil
        } catch {
            message = traduire(error)
        }
    }

    func effacerMessage() { message = nil }

    // MARK: Règle 1.2 : signaler, bloquer

    func estCache(_ profilID: String) -> Bool { blocages.estCache(profilID) }

    /// Masque tout de suite chez moi (règle 1.2), puis écrit le signalement. Le résultat dit la vérité : `.enregistre` seulement si
    /// l'enregistrement `Signalement` est en base ; l'échec ne défait pas le masquage, mais l'écran ne dit alors PAS « signalé ».
    func signaler(_ autre: ProfilModele, motif: MotifSignalement) async -> ResultatSignalement {
        await signaler(cible: autre.id, type: .profil, motif: motif, masquer: true)
    }

    /// Le point d'entrée des autres lots (L23 : publication, commentaire ; L24 : message) : mêmes motifs, même honnêteté.
    /// `masquer` : cacher aussi `cible` chez moi tout de suite (vrai pour un profil, faux pour une carte ou un message).
    func signaler(cible: String, type: CibleSignalement, motif: MotifSignalement, masquer: Bool) async -> ResultatSignalement {
        if masquer { blocages.masquer(cible) }
        do {
            try await service.signaler(cible: cible, type: type, motif: motif, par: monID)
            return .enregistre
        } catch {
            return .nonEnregistre
        }
    }

    func bloquer(_ profilID: String) {
        blocages.bloquer(profilID)
    }

    func debloquer(_ profilID: String) {
        blocages.debloquer(profilID)
    }

    // MARK: Supprimer

    /// Vrai si au moins un effaceur (L23, L24) est branché. Sinon la suppression n'efface QUE le profil public.
    var effaceDuContenu: Bool { !(effaceursFixes.isEmpty && registre.effaceurs.isEmpty) }

    /// Ce que la première question promet : jamais plus que ce qui sera vraiment effacé.
    var phraseSuppression: String {
        effaceDuContenu
            ? "Ton surnom et ton avatar seront effacés du réseau, avec tes publications, tes commentaires et tes messages."
            : "Seuls ton surnom et ton avatar seront effacés du réseau."
    }

    /// « Supprimer mon profil » : efface publications, commentaires et messages (par les effaceurs), puis `ProfilPublic` et l'avatar.
    /// Si un effaceur échoue, rien du profil n'est supprimé : la personne réessaie (règle 5.1.1).
    /// Marche aussi sans identifiant gardé (réponse perdue, réinstallation) : le profil dont je suis l'auteur est alors retrouvé, puis effacé.
    /// Vrai si tout est effacé. L'app continue sans profil.
    @discardableResult
    func supprimer() async -> Bool {
        enCours = true
        defer { enCours = false }
        var cible = monID
        if cible == nil {
            do {
                cible = try await service.monProfilPublic()?.id
            } catch {
                message = traduire(error)
                return false
            }
        }
        guard let id = cible else { return true }
        do {
            for effaceur in effaceursFixes + registre.effaceurs {
                do {
                    try await effaceur.effacerContenu(deProfil: id)
                } catch {
                    message = .suppressionIncomplete
                    return false
                }
            }
            try await service.supprimer(id: id)
        } catch {
            message = traduire(error)
            return false
        }
        profil = nil
        memoire.oublier()
        AnciensChampsIdentite.purger()
        // Le titre du partage d'amis ne doit plus porter un surnom effacé.
        await apresChangementDeSurnom()
        // Pas de « Finis ton profil » juste après une suppression : le rappel repart pour 7 jours.
        RappelProfil.reporter()
        message = nil
        return true
    }

    // MARK: Aides

    private func traduire(_ erreur: Error) -> Message {
        switch (erreur as? ErreurProfil) ?? ServiceProfilCloudKit.traduire(erreur) {
        case .surnomPris: .surnomPris
        case .surnomInvalide(let refus): .surnomRefuse(refus)
        case .reseau: .horsLigne
        case .iCloudIndisponible: .iCloudIndisponible
        case .imageRefusee: .imageRefusee
        case .effacementIncomplet: .suppressionIncomplete
        case .profilIntrouvable: .profilIntrouvable
        default: .echec
        }
    }
}
