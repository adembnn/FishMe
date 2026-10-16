import Core
import Foundation
import SwiftData

/// Enregistrement local des cartes (SwiftData, sans synchro iCloud) et des photos nettoyées (fichiers, sans GPS).
/// Remplit le contrat `CollectionCartes` de Core.
actor DepotCartes: CollectionCartes {
    private let conteneur: ModelContainer
    let dossierPhotos: URL
    private let services: ServicesCollection

    init(conteneur: ModelContainer, dossierPhotos: URL, services: ServicesCollection) {
        self.conteneur = conteneur
        self.dossierPhotos = dossierPhotos
        self.services = services
        try? FileManager.default.createDirectory(at: dossierPhotos, withIntermediateDirectories: true)
    }

    /// Base locale : `cloudKitDatabase: .none`, jamais de synchro iCloud.
    static func creerConteneur(enMemoire: Bool = false) throws -> ModelContainer {
        let schema = Schema([CarteEnregistree.self, BredouilleEnregistree.self])
        // Fichier nommé dans Application Support, hors App Group : avec l'App Group du widget (L15), SwiftData irait sinon
        // dans le conteneur partagé (absent sans provisionnement), et la base retombait en mémoire : les cartes se perdaient.
        let configuration = enMemoire
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, groupContainer: .none, cloudKitDatabase: .none)
            : ModelConfiguration(schema: schema, url: fichierBase(), cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func fichierBase() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("cartes.store")
    }

    static func dossierParDefaut() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Cartes", isDirectory: true)
    }

    // MARK: Écriture

    /// Enregistre une prise confirmée, gardée ou relâchée. La photo est ré-encodée sans GPS avant d'être écrite.
    /// Pas de photo, pas de carte d'une vraie prise : seule une carte déclarée ou d'exemple peut en être dépourvue.
    @discardableResult
    func enregistrer(prise: Prise, photo: Data?, conditions: Conditions? = nil, dureeSecondes: Double? = nil) throws -> Prise {
        var finale = prise
        if let photo, let propre = NettoyagePhoto.sansMetadonnees(photo) {
            let nom = "\(prise.id.uuidString).jpg"
            try propre.write(to: dossierPhotos.appendingPathComponent(nom), options: .completeFileProtection)
            finale.cheminPhoto = nom
        } else if !prise.estDeclaree && !prise.exemple {
            throw ErreurDepot.photoIllisible
        } else {
            finale.cheminPhoto = nil
        }
        let contexte = ModelContext(conteneur)
        let json = try conditions.map { try JSONEncoder().encode($0) }
        contexte.insert(CarteEnregistree(prise: finale, conditionsJSON: json, dureeSecondes: dureeSecondes))
        try contexte.save()
        return finale
    }

    /// Carte du swipe du premier lancement : sans photo, distincte d'une vraie prise.
    @discardableResult
    func enregistrerDeclaree(espece: Espece, date: Date = Date()) throws -> Prise {
        try enregistrer(prise: Prise.declaree(espece: espece, date: date), photo: nil)
    }

    /// Session finie sans prise : une carte bredouille avec son propre dos, rangée à part.
    func enregistrerBredouille(sortie: Sortie, lieuFlou: String?) throws {
        let json = try sortie.conditions.first.map { try JSONEncoder().encode($0) }
        let contexte = ModelContext(conteneur)
        contexte.insert(BredouilleEnregistree(id: sortie.id, debut: sortie.debut, fin: sortie.fin, lieuFlou: lieuFlou,
                                              conditionsJSON: json))
        try contexte.save()
    }

    // MARK: Lecture

    func cartes() async -> [Prise] {
        detaillees().map(\.prise)
    }

    func detaillees() -> [CarteDetaillee] {
        let contexte = ModelContext(conteneur)
        let descripteur = FetchDescriptor<CarteEnregistree>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let lignes = (try? contexte.fetch(descripteur)) ?? []
        return lignes.map { ligne in
            CarteDetaillee(prise: ligne.prise, conditions: Self.decoder(ligne.conditionsJSON), dureeSecondes: ligne.dureeSecondes)
        }
    }

    func bredouilles() -> [CarteBredouille] {
        let contexte = ModelContext(conteneur)
        let descripteur = FetchDescriptor<BredouilleEnregistree>(sortBy: [SortDescriptor(\.debut, order: .reverse)])
        let lignes = (try? contexte.fetch(descripteur)) ?? []
        return lignes.map {
            CarteBredouille(id: $0.id, debut: $0.debut, fin: $0.fin, lieuFlou: $0.lieuFlou, conditions: Self.decoder($0.conditionsJSON),
                            photoURL: urlPhotoSortie(id: $0.id))
        }
    }

    /// La photo nettoyée d'une carte, telle que le pêcheur l'a prise.
    func photo(de prise: Prise) -> Data? {
        guard let nom = prise.cheminPhoto else { return nil }
        return try? Data(contentsOf: dossierPhotos.appendingPathComponent(nom))
    }

    /// Image PNG de la recto, sans métadonnée ni bloc météo, prête à partager.
    func imagePNG(de carte: Prise) async -> Data? {
        let existe = detaillees().contains { $0.prise.id == carte.id }
        guard existe else { return nil }
        let services = self.services
        return await MainActor.run { ImagePartage.png(de: carte, services: services) }
    }

    // MARK: Sauvegarde iCloud (App/Compte)

    /// Identifiants de toutes les cartes et bredouilles, pour savoir ce qui manque d'un côté ou de l'autre.
    func identifiants() -> (cartes: [UUID], bredouilles: [UUID]) {
        (detaillees().map(\.prise.id), bredouilles().map(\.id))
    }

    /// Fichier de la photo nettoyée d'une carte, s'il existe : CloudKit l'envoie tel quel (déjà sans GPS).
    func urlPhoto(de prise: Prise) -> URL? {
        guard let nom = prise.cheminPhoto else { return nil }
        let url = dossierPhotos.appendingPathComponent(nom)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Remet une carte revenue d'iCloud (nouvel iPhone). Ne fait rien si elle est déjà là.
    /// La photo repasse par le nettoyage ; sans photo lisible, la carte revient quand même, plutôt que d'être perdue.
    func importer(_ carte: CarteDetaillee, photo: Data?) throws {
        let id = carte.prise.id
        let contexte = ModelContext(conteneur)
        let existe = (try? contexte.fetchCount(FetchDescriptor<CarteEnregistree>(predicate: #Predicate { $0.id == id }))) ?? 0
        guard existe == 0 else { return }
        var prise = carte.prise
        prise.cheminPhoto = nil
        if let photo, let propre = NettoyagePhoto.sansMetadonnees(photo) {
            let nom = "\(id.uuidString).jpg"
            try propre.write(to: dossierPhotos.appendingPathComponent(nom), options: .completeFileProtection)
            prise.cheminPhoto = nom
        }
        let json = try carte.conditions.map { try JSONEncoder().encode($0) }
        contexte.insert(CarteEnregistree(prise: prise, conditionsJSON: json, dureeSecondes: carte.dureeSecondes))
        try contexte.save()
    }

    /// Remet une carte bredouille revenue d'iCloud, si elle n'est pas déjà là.
    func importer(bredouille: CarteBredouille) throws {
        let id = bredouille.id
        let contexte = ModelContext(conteneur)
        let existe = (try? contexte.fetchCount(FetchDescriptor<BredouilleEnregistree>(predicate: #Predicate { $0.id == id }))) ?? 0
        guard existe == 0 else { return }
        let json = try bredouille.conditions.map { try JSONEncoder().encode($0) }
        contexte.insert(BredouilleEnregistree(id: id, debut: bredouille.debut, fin: bredouille.fin,
                                              lieuFlou: bredouille.lieuFlou, conditionsJSON: json))
        try contexte.save()
    }

    private static func decoder(_ donnees: Data?) -> Conditions? {
        guard let donnees else { return nil }
        return try? JSONDecoder().decode(Conditions.self, from: donnees)
    }
}

nonisolated enum ErreurDepot: Error {
    /// Une carte ne naît que d'une photo prise dans l'app.
    case photoIllisible
}
