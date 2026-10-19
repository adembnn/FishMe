import Foundation
import Observation

/// Où la migration note ce qu'elle a fait. UN DRAPEAU PAR CLUB (`clubs.migre.<uuid>`), plus un drapeau global `clubs.migres` quand tout est réglé :
/// la fiche L22 n'en prévoit qu'un global, mais s'il échoue au 3e club il rejouerait les trois (R2, `migration-clubs.md`).
nonisolated protocol DrapeauxMigration: Sendable {
    func etat(de club: UUID) -> EtatMigrationClub?
    func fixer(_ etat: EtatMigrationClub, pour club: UUID)
    /// Vrai quand chaque club local est réglé (en ligne ou gardé sur l'iPhone).
    var termine: Bool { get nonmutating set }
}

nonisolated enum EtatMigrationClub: String, Sendable, Equatable {
    /// Le club est en ligne, ses cartes sont repartagées.
    case fait
    /// Le pêcheur a choisi « Garder sur cet iPhone », ou le nom a été refusé : le club reste local, il n'est jamais écrit en ligne.
    case gardeLocal
}

nonisolated struct DrapeauxMigrationLocaux: DrapeauxMigration {
    static let cleGlobale = "clubs.migres"
    var prefixe: String = "clubs.migre."
    var cleGlobale: String = Self.cleGlobale

    func etat(de club: UUID) -> EtatMigrationClub? {
        UserDefaults.standard.string(forKey: prefixe + club.uuidString).flatMap(EtatMigrationClub.init(rawValue:))
    }

    func fixer(_ etat: EtatMigrationClub, pour club: UUID) {
        UserDefaults.standard.set(etat.rawValue, forKey: prefixe + club.uuidString)
    }

    var termine: Bool {
        get { UserDefaults.standard.bool(forKey: cleGlobale) }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: cleGlobale) }
    }
}

/// La migration des clubs locaux (`MesClubs`, `PartagesClub`) vers CloudKit. Une seule fois PAR CLUB.
/// Consentement (R2, `migration-clubs.md`, écart avec la fiche) : un club local était privé, en ligne il devient lisible par son lien.
/// La migration n'est donc jamais silencieuse : `enAttente` alimente une feuille « Mettre en ligne / Garder sur cet iPhone » par club.
/// La copie locale (`club.mesClubs`) est GARDÉE (retour en arrière) ; la page n'affiche pas deux fois le même club (même UUID).
@MainActor
@Observable
final class MigrationClubs {
    enum Issue: Equatable {
        case fait
        case gardeLocal
        /// Les cartes de la collection ne sont pas encore prêtes (RootView les rend en fond) : on réessaie plus tard, rien n'est noté.
        case cartesPasPretes
        case echec(ErreurClub)
    }

    private(set) var enCours = false
    private(set) var dernieresIssues: [UUID: Issue] = [:]

    private let service: any ServiceClubs
    private let memoire: any MemoireProfil
    private let drapeaux: any DrapeauxMigration
    private let filtre: any FiltreMots
    private let lireClubsLocaux: () -> [ClubLocal]
    private let lirePartages: () -> [String: Set<String>]
    private let lirePhoto: (ClubLocal) -> Data?
    private let maintenant: @Sendable () -> Date

    init(service: any ServiceClubs, memoire: any MemoireProfil = MemoireProfilLocale(),
         drapeaux: any DrapeauxMigration = DrapeauxMigrationLocaux(), filtre: any FiltreMots = FiltreCore(),
         clubsLocaux: @escaping () -> [ClubLocal] = { MesClubs().clubs },
         partages: @escaping () -> [String: Set<String>] = { PartagesClub.lire() },
         photo: @escaping (ClubLocal) -> Data? = MigrationClubs.photoLocale,
         maintenant: @escaping @Sendable () -> Date = { Date() }) {
        self.service = service
        self.memoire = memoire
        self.drapeaux = drapeaux
        self.filtre = filtre
        self.lireClubsLocaux = clubsLocaux
        self.lirePartages = partages
        self.lirePhoto = photo
        self.maintenant = maintenant
    }

    nonisolated static func photoLocale(_ club: ClubLocal) -> Data? {
        guard let fichier = club.fichierPhoto, let url = MesClubs.url(de: fichier) else { return nil }
        return try? Data(contentsOf: url)
    }

    /// Les clubs locaux pas encore réglés : ceux que la feuille de consentement propose. Vide = rien à faire.
    var enAttente: [ClubLocal] {
        lireClubsLocaux().filter { drapeaux.etat(de: $0.id) == nil }
    }

    var termine: Bool { drapeaux.termine }

    /// Il faut un profil (L21) : sans surnom, pas de `Membre`. L'écran dit « Finis ton profil », sans bloquer le reste de l'app.
    var peutMigrer: Bool { memoire.idProfil() != nil }

    /// « Garder sur cet iPhone » : le club reste local pour toujours, jamais écrit en ligne. Réversible seulement en effaçant le drapeau.
    func garderEnLocal(_ club: ClubLocal) {
        drapeaux.fixer(.gardeLocal, pour: club.id)
        solder()
    }

    /// « Mettre en ligne » pour ces clubs, un à la fois. `cartes` : les PNG de la collection (RootView).
    /// Un échec arrête la boucle : le club en cause n'est pas noté, il sera rejoué au prochain lancement (écriture idempotente).
    @discardableResult
    func migrer(_ clubs: [ClubLocal], cartes: [CarteAPartager]) async -> [UUID: Issue] {
        guard let moi = memoire.idProfil() else { return [:] }
        enCours = true
        defer { enCours = false }
        var issues: [UUID: Issue] = [:]
        for club in clubs {
            if let deja = drapeaux.etat(de: club.id) {
                issues[club.id] = deja == .fait ? .fait : .gardeLocal
                continue
            }
            let issue = await migrerUn(club, cartes: cartes, moi: moi)
            issues[club.id] = issue
            if case .echec = issue { break }
        }
        dernieresIssues = issues
        solder()
        return issues
    }

    private func migrerUn(_ club: ClubLocal, cartes: [CarteAPartager], moi: String) async -> Issue {
        // Un nom que le filtre refuse (R2) : le club reste local.
        if filtre.refuse(club.nom) {
            drapeaux.fixer(.gardeLocal, pour: club.id)
            return .gardeLocal
        }
        let partagees = lirePartages()[club.id.uuidString] ?? []
        // Cartes à repartager mais collection pas encore rendue : surtout ne pas noter « fait », les cartes seraient perdues.
        if !partagees.isEmpty && cartes.isEmpty { return .cartesPasPretes }
        do {
            let image = try lirePhoto(club).map { try ImageClubJPEG.preparer($0) }
            // Même UUID que le club local : rejouer l'écriture ne crée aucun doublon (`creer` rend l'existant).
            let cree = try await service.creer(id: club.id.uuidString, nom: club.nom, poissonId: image == nil ? club.poissonId : nil,
                                               image: image, fondateur: moi, le: maintenant())
            for carte in cartes where partagees.contains(carte.id) {
                let envoi = CartePartageeClub(
                    id: CartePartageeClub.identifiant(club: cree.id, carte: carte.id), club: cree.id, carteID: carte.id, auteur: moi,
                    espece: carte.espece ?? carte.titre, rarete: carte.rarete, tailleCm: carte.tailleCm,
                    departement: LieuClub.departement(carte.departement), image: carte.png, creeLe: maintenant())
                try await service.partager(envoi)
            }
            // Une carte partagée mais retrouvée nulle part (supprimée depuis) est simplement ignorée : jamais une erreur bloquante.
            drapeaux.fixer(.fait, pour: club.id)
            return .fait
        } catch {
            return .echec((error as? ErreurClub) ?? ServiceClubsCloudKit.traduire(error))
        }
    }

    /// Le drapeau global ne passe à vrai que lorsque plus aucun club local n'attend.
    private func solder() {
        if enAttente.isEmpty { drapeaux.termine = true }
    }
}
