import Core
import Foundation
import Observation

nonisolated enum ErreurAjoutRepere: Error, Equatable {
    case invalide(ErreurRepere)
    /// 3 repères gratuits atteints : le paywall s'ouvre, la saisie reste à l'écran.
    case paywall
    case plafond
    case lectureSeule
    case disque
}

/// La liste des repères, pour les écrans. Lit et écrit `DepotReperes` ; ne parle jamais au réseau.
@MainActor @Observable
final class ModeleReperes {
    static let partage = ModeleReperes()

    /// Repères actifs, sans les pierres tombales, du plus récent au plus ancien.
    private(set) var reperes: [Repere] = []
    /// Le fichier vient d'une version plus récente de l'app : lecture seule, rien n'est écrit.
    private(set) var lectureSeule = false
    private(set) var charge = false
    /// Vrai si le fichier illisible a été mis de côté (une copie est gardée).
    private(set) var fichierIllisible = false

    @ObservationIgnored let depot: DepotReperes
    @ObservationIgnored private let horloge: () -> Date

    init(depot: DepotReperes = DepotReperes(), horloge: @escaping () -> Date = { Date() }) {
        self.depot = depot
        self.horloge = horloge
    }

    var actifs: Int { reperes.count }

    func decision(abonne: Bool) -> DecisionAjoutRepere {
        ReglesReperes.peutAjouter(actifs: actifs, abonne: abonne)
    }

    func repere(id: UUID) -> Repere? { reperes.first { $0.id == id } }

    // MARK: Lecture

    func charger() async {
        do {
            appliquer(try await depot.lire())
            lectureSeule = false
            fichierIllisible = false
        } catch ErreurDepotReperes.versionFuture {
            lectureSeule = true
            reperes = []
        } catch {
            // Fichier illisible : il sera mis de côté à la première écriture (`DepotReperes.mettreAJour`).
            fichierIllisible = true
            reperes = []
        }
        charge = true
    }

    func chargerSiBesoin() async {
        if !charge { await charger() }
    }

    private func appliquer(_ tous: [Repere]) {
        reperes = tous.filter { !$0.estSupprime }.sorted { $0.cree > $1.cree }
    }

    // MARK: Ajout

    /// Crée un repère. `photos` : données brutes choisies par le pêcheur ; elles sont réduites et nettoyées ici.
    @discardableResult
    func ajouter(nom: String, note: String, icone: IconeRepere, position: Coordonnee, photos: [Data] = [],
                 abonne: Bool) async throws -> Repere {
        guard !lectureSeule else { throw ErreurAjoutRepere.lectureSeule }
        let saisie: SaisieRepere
        do { saisie = try Repere.valide(nom: nom, note: note) } catch let e as ErreurRepere { throw ErreurAjoutRepere.invalide(e) }
        switch decision(abonne: abonne) {
        case .oui: break
        case .paywall: throw ErreurAjoutRepere.paywall
        case .plafond: throw ErreurAjoutRepere.plafond
        }
        var noms: [String] = []
        for donnees in photos.prefix(LimitesReperes.photosMax) {
            guard let propre = PhotoRepere.preparer(donnees), let nomPhoto = try? await depot.ecrirePhoto(propre) else { continue }
            noms.append(nomPhoto)
        }
        let maintenant = Repere.instant(horloge())
        let nouveau = Repere(nom: saisie.nom, icone: icone, note: saisie.note, position: position, photos: noms,
                             cree: maintenant, modifie: maintenant)
        do {
            appliquer(try await depot.mettreAJour { $0 + [nouveau] })
        } catch {
            await depot.supprimerPhotos(noms)
            if case ErreurDepotReperes.versionFuture = error { lectureSeule = true; throw ErreurAjoutRepere.lectureSeule }
            throw ErreurAjoutRepere.disque
        }
        return nouveau
    }

    // MARK: Modification

    func modifier(id: UUID, nom: String, note: String, icone: IconeRepere) async throws {
        guard !lectureSeule else { throw ErreurAjoutRepere.lectureSeule }
        let saisie: SaisieRepere
        do { saisie = try Repere.valide(nom: nom, note: note) } catch let e as ErreurRepere { throw ErreurAjoutRepere.invalide(e) }
        let maintenant = Repere.instant(horloge())
        try await changer(id) { r in
            r.nom = saisie.nom
            r.note = saisie.note
            r.icone = icone
            r.modifie = maintenant
        }
    }

    /// Ajoute une photo (6 au plus). Rend `false` si la limite est atteinte ou si la photo n'a pas pu être préparée.
    @discardableResult
    func ajouterPhoto(a id: UUID, donnees: Data) async throws -> Bool {
        guard !lectureSeule else { throw ErreurAjoutRepere.lectureSeule }
        guard let existant = repere(id: id), existant.photos.count < LimitesReperes.photosMax,
              let propre = PhotoRepere.preparer(donnees), let nomPhoto = try? await depot.ecrirePhoto(propre) else { return false }
        let maintenant = Repere.instant(horloge())
        try await changer(id) { r in
            r.photos.append(nomPhoto)
            r.modifie = maintenant
        }
        return true
    }

    func retirerPhoto(_ nomPhoto: String, de id: UUID) async throws {
        guard !lectureSeule else { throw ErreurAjoutRepere.lectureSeule }
        let maintenant = Repere.instant(horloge())
        try await changer(id) { r in
            r.photos.removeAll { $0 == nomPhoto }
            r.modifie = maintenant
        }
        await depot.supprimerPhotos([nomPhoto])
    }

    func rattacher(prise: UUID, a id: UUID) async throws {
        let maintenant = Repere.instant(horloge())
        try await changer(id) { r in
            guard !r.idsPrises.contains(prise) else { return }
            r.idsPrises.append(prise)
            r.modifie = maintenant
        }
    }

    func detacher(prise: UUID, de id: UUID) async throws {
        let maintenant = Repere.instant(horloge())
        try await changer(id) { r in
            r.idsPrises.removeAll { $0 == prise }
            r.modifie = maintenant
        }
    }

    func noterPassage(id: UUID, date: Date? = nil) async throws {
        let maintenant = Repere.instant(horloge())
        let jour = Repere.instant(date ?? maintenant)
        try await changer(id) { r in
            r.passageManuel = jour
            r.modifie = maintenant
        }
    }

    /// Suppression : le repère devient une pierre tombale (pour que la suppression gagne sur l'autre iPhone). Sa note, ses
    /// rattachements et ses photos sont vidés tout de suite ; les fichiers de photos sont effacés.
    func supprimer(id: UUID) async throws {
        guard !lectureSeule else { throw ErreurAjoutRepere.lectureSeule }
        let photos = repere(id: id)?.photos ?? []
        let maintenant = Repere.instant(horloge())
        try await changer(id) { r in
            r.supprime = maintenant
            r.modifie = maintenant
            r.note = ""
            r.photos = []
            r.idsPrises = []
            r.passageManuel = nil
        }
        await depot.supprimerPhotos(photos)
    }

    private func changer(_ id: UUID, _ modification: @escaping @Sendable (inout Repere) -> Void) async throws {
        guard !lectureSeule else { throw ErreurAjoutRepere.lectureSeule }
        do {
            appliquer(try await depot.mettreAJour { tous in
                tous.map { r in
                    guard r.id == id else { return r }
                    var copie = r
                    modification(&copie)
                    return copie
                }
            })
        } catch ErreurDepotReperes.versionFuture {
            lectureSeule = true
            throw ErreurAjoutRepere.lectureSeule
        } catch {
            throw ErreurAjoutRepere.disque
        }
    }

    // MARK: Photos

    func photo(_ nom: String) async -> Data? { await depot.photo(nom) }

    // MARK: Après une synchro iCloud ou la suppression du compte

    func recharger() async { await charger() }

    /// Suppression du compte : le fichier et les photos locales disparaissent, la liste se vide.
    func effacerTout() async throws {
        try await depot.effacerTout()
        reperes = []
        lectureSeule = false
        fichierIllisible = false
    }
}
