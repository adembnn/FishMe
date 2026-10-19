import Foundation
import Observation

/// Le cerveau du profil : créer (surnom vérifié avant et après l'écriture), changer l'avatar, signaler, bloquer, supprimer.
/// Tout CloudKit passe par `ServiceProfil`.
@MainActor
@Observable
final class GestionProfil {
    enum Message: Equatable {
        case surnomRefuse(Surnom.Refus)
        case surnomPris
        /// Sans la déclaration « J'ai 15 ans ou plus », aucun profil public.
        case ageRequis
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

    private let service: any ServiceProfil
    private let memoire: any MemoireProfil
    private let identite: any StockageIdentitePrivee
    private let blocages: BlocagesProfils
    private let filtre: any FiltreMots
    /// Fournis en plus par le registre (L23, L24) : A les compose à l'ouverture de l'app.
    private let effaceursFixes: [any EffaceurContenu]

    init(service: any ServiceProfil, memoire: any MemoireProfil = MemoireProfilLocale(),
         identite: any StockageIdentitePrivee = IdentitePriveeLocale(), blocages: BlocagesProfils = BlocagesProfils(),
         filtre: any FiltreMots = AucunFiltre(), effaceurs: [any EffaceurContenu] = []) {
        self.service = service
        self.memoire = memoire
        self.identite = identite
        self.blocages = blocages
        self.filtre = filtre
        self.effaceursFixes = effaceurs
    }

    /// Le profil partagé par toute l'app (le vrai CloudKit). Créé à la première demande seulement.
    static let partage = GestionProfil(service: ServiceProfilCloudKit(conteneur: ConfigurationAmis.conteneurParDefaut))

    // MARK: État

    /// Vrai dès que l'iPhone se souvient d'un profil, même hors ligne : « Finis ton profil » ne revient alors jamais.
    var aUnProfil: Bool { profil != nil || memoire.idProfil() != nil }

    var monID: String? { profil?.id ?? memoire.idProfil() }

    /// Relit mon profil depuis CloudKit s'il existe. Hors ligne, l'identifiant gardé suffit à savoir qu'il existe.
    func charger() async {
        guard let id = memoire.idProfil() else { return }
        do {
            if let relu = try await service.profil(id: id) {
                profil = relu
            } else {
                // Effacé ailleurs (tableau de bord) : l'app continue sans profil.
                profil = nil
                memoire.oublier()
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
    @discardableResult
    func creer(surnom: String, avatar: Data?, aQuinzeAns: Bool) async -> Bool {
        // R2: 15 ans minimum (décision de Titouan, à confirmer par le juridique ; Declared Age Range d'Apple ⚠ à étudier).
        // Simple déclaration : rien n'est stocké, ni date de naissance ni la case cochée. Sans elle, l'app reste utilisable.
        guard aQuinzeAns else {
            message = .ageRequis
            return false
        }
        if let refus = verifier(surnom: surnom) {
            message = .surnomRefuse(refus)
            return false
        }
        enCours = true
        defer { enCours = false }
        do {
            guard try await service.surnomEstLibre(surnom) else {
                message = .surnomPris
                return false
            }
            let cree = try await service.creer(surnom: surnom, avatar: avatar)
            profil = cree
            memoire.retenir(id: cree.id, surnom: cree.surnom)
            message = nil
            return true
        } catch {
            message = traduire(error)
            return false
        }
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

    // MARK: Nom et prénom privés

    func identitePrivee() -> (nom: String, prenom: String) { identite.lire() }

    func enregistrerIdentitePrivee(nom: String, prenom: String) {
        identite.ecrire(nom: nom.trimmingCharacters(in: .whitespacesAndNewlines),
                        prenom: prenom.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: Règle 1.2 : signaler, bloquer

    func estCache(_ profilID: String) -> Bool { blocages.estCache(profilID) }

    /// Masque tout de suite chez moi, puis écrit la trace. L'échec de la trace ne défait pas le masquage.
    func signaler(_ autre: ProfilModele, motif: MotifSignalement) async {
        blocages.masquer(autre.id)
        try? await service.signaler(profilID: autre.id, motif: motif, par: monID)
    }

    func bloquer(_ profilID: String) {
        blocages.bloquer(profilID)
    }

    func debloquer(_ profilID: String) {
        blocages.debloquer(profilID)
    }

    // MARK: Supprimer

    /// « Supprimer mon profil » : efface publications, commentaires et messages (par les effaceurs), puis `Profil` et l'avatar,
    /// puis nom et prénom privés. Si un effaceur échoue, rien du profil n'est supprimé : la personne réessaie (règle 5.1.1).
    /// Vrai si tout est effacé. L'app continue sans profil.
    @discardableResult
    func supprimer() async -> Bool {
        guard let id = monID else { return true }
        enCours = true
        defer { enCours = false }
        do {
            for effaceur in effaceursFixes + RegistreEffaceurs.partage.effaceurs {
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
        identite.effacer()
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
        default: .echec
        }
    }
}
