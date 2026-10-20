import Foundation
import Observation

/// Le cerveau des clubs en ligne : charger (avec le dernier état lu si le réseau manque), créer, rejoindre, quitter,
/// partager une carte, signaler, bloquer, écarter. Tout CloudKit passe par `ServiceClubs`, tout profil par `ServiceProfil` (L21).
@MainActor
@Observable
final class GestionClubs {
    enum Message: Equatable {
        case profilRequis
        case iCloudIndisponible
        case horsLigne
        case clubFerme
        case sansFondateur
        case ecarte
        case introuvable
        case nomRefuse
        case imageRefusee
        case refuse
        case echec

        var texte: String {
            switch self {
            case .profilRequis: "Finis ton profil pour rejoindre ou créer un club."
            case .iCloudIndisponible: "Connecte-toi à iCloud pour utiliser les clubs en ligne."
            case .horsLigne: "Pas de réseau. Tu vois le dernier état lu."
            case .clubFerme: "Ce club est fermé."
            case .sansFondateur: "Ce club n'a plus de fondateur : on ne peut plus y entrer."
            case .ecarte: "Le fondateur de ce club t'a retiré."
            case .introuvable: "Ce club n'existe pas (ou plus)."
            case .nomRefuse: "Ce nom n'est pas accepté."
            case .imageRefusee: "Cette image ne marche pas. Essaie-en une autre."
            case .refuse: "Seul le fondateur peut faire ça."
            case .echec: "Ça n'a pas marché. Réessaie."
            }
        }
    }

    private(set) var clubs: [Club] = []
    private(set) var membres: [String: [Membre]] = [:]
    private(set) var cartes: [String: [CartePartageeClub]] = [:]
    private(set) var profils: [String: EtatCacheClubs.ProfilCache] = [:]
    private(set) var message: Message?
    private(set) var enCours = false
    /// Vrai quand la dernière lecture a échoué faute de réseau : la page affiche le dernier état lu.
    private(set) var horsLigne = false
    /// Vrai si le compte iCloud était utilisable à la dernière vérification. Faux : les clubs restent locaux et la page le dit.
    private(set) var icloud = true
    private(set) var dernierChargement: Date?
    /// Cartes que j'ai signalées et auteurs que j'ai bloqués ou masqués : mis à jour tout de suite, ils retirent le contenu de l'écran.
    private(set) var cartesMasquees: Set<String>
    private(set) var auteursCaches: Set<String>
    /// Profil -> compte iCloud, vérifié par le créateur de son `ProfilPublic` (jamais par un champ reçu). Pour les membres dont
    /// l'adhésion ne porte pas d'`idCloudKit` : voir `resoudreIdentites`.
    private(set) var identites: [String: String] = [:]

    let service: any ServiceClubs
    private let profilsService: any ServiceProfil
    private let memoire: any MemoireProfil
    private let cache: any CacheClubs
    private let blocages: BlocagesProfils
    private let masquees: CartesMasquees
    private let filtre: any FiltreMots
    private let maintenant: @Sendable () -> Date
    /// `nil` : aucune résolution (aperçus, tests qui n'en ont pas besoin).
    private let resolveur: (any ResolveurIdentite)?

    /// Un profil que le résolveur dit introuvable n'est pas redemandé avant ce délai (sauf à l'ouverture de la page) ;
    /// une panne réseau, elle, ne compte pas : on réessaie au chargement suivant.
    static let delaiNouvelEssaiIdentite: TimeInterval = 60
    private var identitesEssayees: [String: Date] = [:]

    /// Les requêtes de la base publique sont cohérentes « à terme » : juste après une écriture, la lecture peut ne pas encore la montrer.
    /// Pendant ce délai on garde ce qu'on vient d'écrire (club créé ou rejoint, carte partagée) et on ignore ce qu'on vient de quitter ou retirer,
    /// sinon la page clignoterait au rafraîchissement suivant.
    static let delaiCoherence: TimeInterval = 90
    private var clubsRecents: [String: Date] = [:]
    private var clubsQuittes: [String: Date] = [:]
    private var cartesRecentes: [String: Date] = [:]
    private var cartesRetirees: [String: Date] = [:]

    init(service: any ServiceClubs, profils: any ServiceProfil, memoire: any MemoireProfil = MemoireProfilLocale(),
         cache: any CacheClubs = CacheClubsFichier(), blocages: BlocagesProfils = BlocagesProfils(),
         masquees: CartesMasquees = CartesMasquees(), filtre: any FiltreMots = FiltreCore(),
         resolveur: (any ResolveurIdentite)? = nil, maintenant: @escaping @Sendable () -> Date = { Date() }) {
        self.resolveur = resolveur
        self.service = service
        self.profilsService = profils
        self.memoire = memoire
        self.cache = cache
        self.blocages = blocages
        self.masquees = masquees
        self.filtre = filtre
        self.maintenant = maintenant
        self.cartesMasquees = masquees.ids()
        self.auteursCaches = blocages.bloques().union(blocages.masques())
        restaurerCache()
    }

    /// Le service partagé par toute l'app (le vrai CloudKit). Créé à la première demande seulement.
    static let partage = GestionClubs(service: ServiceClubsCloudKit(), profils: GestionProfil.partage.service,
                                         resolveur: ResolveurIdentiteCloudKit())

    // MARK: État

    /// Mon identifiant public (`p-<surnom>`, L21), ou `nil` tant que je n'ai pas fini mon profil.
    /// Avoir un profil vaut « 15 ans ou plus » : L21 ne le crée pas sans cette déclaration (décision de Titouan, 15 ans minimum).
    var monID: String? { memoire.idProfil() }
    var aUnProfil: Bool { monID != nil }

    func club(id: String) -> Club? { clubs.first { $0.id == id } }

    func etat(de club: Club) -> EtatClub { club.etat(membres: membres[club.id] ?? []) }

    func jeSuisFondateur(de club: Club) -> Bool { monID == club.fondateur && etat(de: club) == .actif }

    func surnom(de profil: String) -> String {
        profils[profil]?.surnom ?? Self.surnomTronque(profil)
    }

    func avatar(de profil: String) -> Data? { profils[profil]?.avatar }

    /// L21 en retard ou profil introuvable : « p-gros-brochet » s'affiche « gros-brochet ». Jamais un identifiant technique.
    nonisolated static func surnomTronque(_ id: String) -> String { id.hasPrefix("p-") ? String(id.dropFirst(2)) : id }

    /// Les membres à montrer : ni les écartés, ni les bloqués ou masqués.
    func membresVisibles(de club: Club) -> [Membre] {
        RegleAdhesion.visibles(membres[club.id] ?? [], club: club).filter { !auteursCaches.contains($0.profil) }
    }

    /// Les cartes à montrer : celles des membres écartés, bloqués ou masqués disparaissent, comme les cartes signalées.
    func cartesVisibles(de club: Club) -> [CartePartageeClub] {
        (cartes[club.id] ?? []).filter {
            !club.estEcarte($0.auteur) && !auteursCaches.contains($0.auteur) && !cartesMasquees.contains($0.id)
        }
    }

    /// Les identifiants (dans ma collection) de mes cartes déjà partagées à ce club.
    func mesCartesPartagees(dans club: Club) -> Set<String> {
        guard let moi = monID else { return [] }
        return Set((cartes[club.id] ?? []).filter { $0.auteur == moi }.map(\.carteID))
    }

    func record(de club: Club) -> CartePartageeClub? { RecordDuClub.meilleure(cartesVisibles(de: club)) }

    func effacerMessage() { message = nil }

    /// Le compte iCloud de ce membre pour l'admettre dans la zone du chat : celui de son adhésion, sinon celui vérifié via son profil.
    /// `nil` : on ne le connaît pas (encore).
    func idCloudKit(de membre: Membre) -> String? { IdentiteMembre.idCloudKit(de: membre, verifies: identites) }

    /// Vrai si ce membre est une vraie personne dont le compte est inconnu : l'écran dit « en attente de son profil ».
    func estEnAttenteDeProfil(_ membre: Membre) -> Bool {
        !IdentiteMembre.estExemple(membre.profil) && membre.profil != monID && idCloudKit(de: membre) == nil
    }

    // MARK: Lecture

    /// Relit mes clubs, leurs membres et leurs cartes. Échec réseau : on garde le dernier état lu (cache) et `horsLigne` passe à vrai.
    /// `ouverture` : la page vient de s'ouvrir, on retente tout de suite les membres dont le profil manquait.
    func charger(ouverture: Bool = false) async {
        guard let moi = monID else { return }
        icloud = await service.iCloudDisponible()
        guard icloud else {
            message = .iCloudIndisponible
            return
        }
        enCours = true
        defer { enCours = false }
        do {
            let maintenantDate = maintenant()
            var miens = try await service.clubs(deProfil: moi).filter { !recent(clubsQuittes[$0.id], le: maintenantDate) }
            for (id, _) in clubsRecents where recent(clubsRecents[id], le: maintenantDate) && !miens.contains(where: { $0.id == id }) {
                if let present = try await service.club(id: id) { miens.append(present) }
            }
            var clubsGardes: [Club] = []
            var membresLus: [String: [Membre]] = [:]
            var cartesLues: [String: [CartePartageeClub]] = [:]
            for club in miens {
                if club.ferme {
                    // Fermé par son fondateur : plus rien à montrer. Je ménage ma propre trace (adhésion et cartes), sans bruit.
                    try? await service.quitter(club: club.id, profil: moi)
                    continue
                }
                if club.estEcarte(moi) {
                    // Le fondateur m'a écarté : il ne peut pas effacer mon adhésion (R2), je l'efface moi-même ainsi que mes cartes.
                    try? await service.quitter(club: club.id, profil: moi)
                    continue
                }
                var liste = try await service.membres(deClub: club.id)
                // Mon adhésion toute neuve peut ne pas encore se lire : on garde celle qu'on connaît.
                if recent(clubsRecents[club.id], le: maintenantDate), !liste.contains(where: { $0.profil == moi }),
                   let mienne = membres[club.id]?.first(where: { $0.profil == moi }) {
                    liste.append(mienne)
                }
                membresLus[club.id] = liste
                cartesLues[club.id] = try await lireCartes(club.id)
                clubsGardes.append(club)
            }
            clubs = clubsGardes
            membres = membresLus
            cartes = cartesLues
            await completerProfils()
            await resoudreIdentites(forcer: ouverture)
            horsLigne = false
            dernierChargement = maintenant()
            message = nil
            enregistrerCache()
        } catch {
            horsLigne = true
            message = traduire(error)
            // Le fichier ne sert qu'à l'écran vide d'un lancement sans réseau : sinon l'état en mémoire, plus récent, reste.
            if clubs.isEmpty { restaurerCache() }
        }
    }

    /// Les surnoms et avatars de L21 pour tous les auteurs et membres que je n'ai pas encore.
    private func completerProfils() async {
        var ids = Set<String>()
        for liste in membres.values { for m in liste { ids.insert(m.profil) } }
        for liste in cartes.values { for c in liste { ids.insert(c.auteur) } }
        for id in ids where profils[id] == nil {
            if let profil = try? await profilsService.profil(id: id) {
                profils[id] = EtatCacheClubs.ProfilCache(id: id, surnom: profil.surnom, avatar: profil.avatar)
            }
        }
    }

    /// Cherche le compte iCloud des membres qui n'en ont pas : lit leur `ProfilPublic` (par l'identifiant de profil, donc par surnom)
    /// et retient le CRÉATEUR de cet enregistrement. Profil absent : le membre reste « en attente » (aucune erreur) et on ne le
    /// redemande pas avant `delaiNouvelEssaiIdentite`, sauf `forcer` (ouverture de la page, retour du réseau). Panne réseau : on
    /// s'arrête là sans rien conclure ni compter d'essai. Ne touche ni aux membres de la démo ni à moi.
    func resoudreIdentites(forcer: Bool = false) async {
        guard let resolveur, icloud else { return }
        let maintenantDate = maintenant()
        var vus = Set<String>()
        var trouve = false
        for liste in membres.values {
            for membre in liste where estEnAttenteDeProfil(membre) && vus.insert(membre.profil).inserted {
                if !forcer, recentIdentite(identitesEssayees[membre.profil], le: maintenantDate) { continue }
                do {
                    if let compte = try await resolveur.idCloudKit(deProfil: membre.profil), !compte.isEmpty {
                        identites[membre.profil] = compte
                        identitesEssayees[membre.profil] = nil
                        trouve = true
                    } else {
                        identitesEssayees[membre.profil] = maintenantDate
                    }
                } catch {
                    if trouve { enregistrerCache() }
                    return
                }
            }
        }
        if trouve { enregistrerCache() }
    }

    /// Lit les cartes du club sans retélécharger les images déjà là : une carte déjà lue garde son image.
    private func lireCartes(_ clubID: String) async throws -> [CartePartageeClub] {
        let avant = Dictionary((cartes[clubID] ?? []).compactMap { c in c.image.map { (c.id, $0) } }, uniquingKeysWith: { a, _ in a })
        let lues = try await service.cartes(deClub: clubID, sauf: Set(avant.keys))
        let maintenantDate = maintenant()
        var resultat: [CartePartageeClub] = lues.compactMap { carte in
            if recent(cartesRetirees[carte.id], le: maintenantDate) { return nil }
            var copie = carte
            if copie.image == nil { copie.image = avant[carte.id] }
            return copie
        }
        // Une carte que je viens de partager peut ne pas encore se lire : on la garde.
        for ancienne in cartes[clubID] ?? [] where recent(cartesRecentes[ancienne.id], le: maintenantDate)
            && !resultat.contains(where: { $0.id == ancienne.id }) {
            resultat.insert(ancienne, at: 0)
        }
        return resultat
    }

    private func recent(_ date: Date?, le maintenantDate: Date) -> Bool {
        guard let date else { return false }
        return maintenantDate.timeIntervalSince(date) < Self.delaiCoherence
    }

    private func recentIdentite(_ date: Date?, le maintenantDate: Date) -> Bool {
        guard let date else { return false }
        return maintenantDate.timeIntervalSince(date) < Self.delaiNouvelEssaiIdentite
    }

    // MARK: Cache (mode avion)

    private func enregistrerCache() {
        cache.ecrire(EtatCacheClubs(clubs: clubs, membres: membres, cartes: cartes, profils: profils,
                                  enregistreLe: maintenant(), identites: identites))
    }

    private func restaurerCache() {
        guard let etat = cache.lire() else { return }
        clubs = etat.clubs
        membres = etat.membres
        cartes = etat.cartes
        profils = etat.profils
        identites = etat.identites ?? [:]
    }

    // MARK: Créer, rejoindre

    /// Crée un club en ligne : le créateur est fondateur (`Membre` de rôle fondateur). `id` : fourni pour la migration, sinon neuf.
    @discardableResult
    func creer(nom: String, poissonId: String?, photo: Data?, id: String = UUID().uuidString) async -> Club? {
        guard let moi = monID else { message = .profilRequis; return nil }
        let propre = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !propre.isEmpty else { return nil }
        guard !filtre.refuse(propre) else { message = .nomRefuse; return nil }
        enCours = true
        defer { enCours = false }
        do {
            let image = try photo.map { try ImageClubJPEG.preparer($0) }
            let date = maintenant()
            let club = try await service.creer(id: id, nom: propre, poissonId: image == nil ? poissonId : nil, image: image,
                                               fondateur: moi, le: date)
            inserer(club)
            clubsRecents[club.id] = date
            membres[club.id] = [Membre(id: Membre.identifiant(club: club.id, profil: moi), club: club.id, profil: moi,
                                       role: .fondateur, depuis: date)]
            cartes[club.id] = cartes[club.id] ?? []
            await completerProfils()
            enregistrerCache()
            message = nil
            return club
        } catch {
            message = traduire(error)
            return nil
        }
    }

    /// Ce que la feuille « Rejoindre » montre : nom, image, nombre de membres, et si je peux entrer.
    func apercu(clubID: String) async -> Result<ApercuClub, ErreurClub> {
        guard let moi = monID else { return .failure(.profilRequis) }
        do {
            guard let club = try await service.club(id: clubID) else { return .failure(.introuvable) }
            let liste = try await service.membres(deClub: clubID)
            let dejaMembre = liste.contains { $0.profil == moi }
            let visibles = RegleAdhesion.visibles(liste, club: club)
            let apercu = ApercuClub(club: club, nombreDeMembres: visibles.count, etat: club.etat(membres: liste), dejaMembre: dejaMembre)
            if let refus = RegleAdhesion.verifier(club: club, membres: liste, profil: moi) { return .failure(refus) }
            return .success(apercu)
        } catch {
            return .failure(Self.erreur(depuis: error))
        }
    }

    /// Rejoint le club (feuille « Rejoindre » confirmée). Les règles (fermé, écarté, sans fondateur) sont revérifiées au moment d'écrire.
    @discardableResult
    func rejoindre(clubID: String) async -> Bool {
        guard let moi = monID else { message = .profilRequis; return false }
        enCours = true
        defer { enCours = false }
        do {
            guard let club = try await service.club(id: clubID) else { message = .introuvable; return false }
            let liste = try await service.membres(deClub: clubID)
            if let refus = RegleAdhesion.verifier(club: club, membres: liste, profil: moi) {
                message = Self.messageDe(refus)
                return false
            }
            let adhesion = try await service.rejoindre(club: clubID, profil: moi, le: maintenant())
            inserer(club)
            clubsRecents[clubID] = maintenant()
            var apres = try await service.membres(deClub: clubID)
            if !apres.contains(where: { $0.profil == moi }) { apres.append(adhesion) }
            membres[clubID] = apres
            cartes[clubID] = try await lireCartes(clubID)
            await completerProfils()
            enregistrerCache()
            message = nil
            return true
        } catch {
            message = traduire(error)
            return false
        }
    }

    // MARK: Quitter, fermer

    /// « Quitter le club » : mon adhésion ET mes cartes partagées disparaissent chez les autres.
    /// Fondateur seul : le club est fermé. Fondateur avec d'autres membres : le club reste SANS fondateur (R2 : pas de transfert).
    /// ⚠ Quitter ne retire pas l'accès à la zone partagée du chat de club (L24) : seul le fondateur peut retirer un participant du `CKShare`.
    @discardableResult
    func quitter(_ club: Club) async -> Bool {
        guard let moi = monID else { message = .profilRequis; return false }
        enCours = true
        defer { enCours = false }
        do {
            // Les membres sont relus au moment de partir : l'état affiché peut dater de 8 s, et fermer un club où quelqu'un vient d'entrer serait une erreur.
            let presents = try await service.membres(deClub: club.id)
            switch RegleAdhesion.sortie(club: club, membres: presents, profil: moi) {
            case .fermer: try await service.fermer(club: club.id, fondateur: moi)
            case .quitter: try await service.quitter(club: club.id, profil: moi)
            }
            clubsQuittes[club.id] = maintenant()
            clubsRecents[club.id] = nil
            oublier(club.id)
            enregistrerCache()
            message = nil
            return true
        } catch {
            message = traduire(error)
            return false
        }
    }

    // MARK: Cartes

    /// Partage une de mes cartes au club : le PNG de la collection (sans GPS) et le département, rien d'autre.
    @discardableResult
    func partager(_ carte: CarteAPartager, dans club: Club) async -> Bool {
        guard let moi = monID else { message = .profilRequis; return false }
        let partagee = CartePartageeClub(
            id: CartePartageeClub.identifiant(club: club.id, carte: carte.id), club: club.id, carteID: carte.id, auteur: moi,
            espece: carte.espece ?? carte.titre, rarete: carte.rarete, tailleCm: carte.tailleCm,
            departement: LieuClub.departement(carte.departement), image: carte.png, creeLe: maintenant())
        do {
            try await service.partager(partagee)
            var liste = cartes[club.id] ?? []
            liste.removeAll { $0.id == partagee.id }
            liste.insert(partagee, at: 0)
            cartes[club.id] = liste
            cartesRecentes[partagee.id] = maintenant()
            cartesRetirees[partagee.id] = nil
            enregistrerCache()
            return true
        } catch {
            message = traduire(error)
            return false
        }
    }

    @discardableResult
    func retirerCarte(carteID: String, de club: Club) async -> Bool {
        let id = CartePartageeClub.identifiant(club: club.id, carte: carteID)
        do {
            try await service.retirerCarte(id: id)
            cartes[club.id]?.removeAll { $0.id == id }
            cartesRetirees[id] = maintenant()
            cartesRecentes[id] = nil
            enregistrerCache()
            return true
        } catch {
            message = traduire(error)
            return false
        }
    }

    /// Toucher une carte dans « Partager une carte » : la partage ou la retire.
    func basculer(_ carte: CarteAPartager, dans club: Club) async {
        if mesCartesPartagees(dans: club).contains(carte.id) {
            await retirerCarte(carteID: carte.id, de: club)
        } else {
            await partager(carte, dans: club)
        }
    }

    // MARK: Modération (règle 1.2, décision 5)

    /// Signale une carte : masquée chez moi TOUT DE SUITE, trace en base publique, puis rend l'e-mail prérempli à envoyer.
    /// L'échec de la trace ne défait pas le masquage.
    func signaler(_ carte: CartePartageeClub, motif: MotifSignalementClub) async -> URL? {
        masquees.masquer(carte.id)
        cartesMasquees.insert(carte.id)
        try? await service.signaler(cible: carte.id, typeCible: "publication", motif: motif, par: monID)
        return SignalementClub.url(carte: carte, motif: motif)
    }

    /// Bloquer un membre : plus rien de lui chez moi (filtre local de L21, `BlocagesProfils`).
    func bloquer(_ profilID: String) {
        blocages.bloquer(profilID)
        auteursCaches.insert(profilID)
    }

    /// Le fondateur écarte un membre (R2 : par `Club.retires`, il ne peut pas supprimer son `Membre`).
    /// L'écarté disparaît des listes ; son iPhone efface lui-même son adhésion et ses cartes au prochain chargement.
    /// ⚠ L'écarté garde son accès à la zone partagée du chat tant que le fondateur ne l'en retire pas (L24).
    @discardableResult
    func ecarter(_ profilID: String, de club: Club) async -> Bool {
        guard let moi = monID, RegleAdhesion.peutEcarter(club: club, membres: membres[club.id] ?? [], moi: moi, cible: profilID) else {
            message = .refuse
            return false
        }
        do {
            try await service.ecarter(profil: profilID, deClub: club.id)
            if let rang = clubs.firstIndex(where: { $0.id == club.id }), !clubs[rang].retires.contains(profilID) {
                clubs[rang].retires.append(profilID)
            }
            enregistrerCache()
            return true
        } catch {
            message = traduire(error)
            return false
        }
    }

    // MARK: Aides

    private func inserer(_ club: Club) {
        if let rang = clubs.firstIndex(where: { $0.id == club.id }) {
            clubs[rang] = club
        } else {
            clubs.append(club)
        }
    }

    private func oublier(_ id: String) {
        clubs.removeAll { $0.id == id }
        membres[id] = nil
        cartes[id] = nil
    }

    static func erreur(depuis erreur: Error) -> ErreurClub {
        (erreur as? ErreurClub) ?? ServiceClubsCloudKit.traduire(erreur)
    }

    static func messageDe(_ erreur: ErreurClub) -> Message {
        switch erreur {
        case .reseau: .horsLigne
        case .iCloudIndisponible: .iCloudIndisponible
        case .introuvable: .introuvable
        case .clubFerme: .clubFerme
        case .sansFondateur: .sansFondateur
        case .ecarte: .ecarte
        case .profilRequis: .profilRequis
        case .nomRefuse: .nomRefuse
        case .imageRefusee: .imageRefusee
        case .refuse: .refuse
        case .autre: .echec
        }
    }

    private func traduire(_ erreur: Error) -> Message { Self.messageDe(Self.erreur(depuis: erreur)) }
}
