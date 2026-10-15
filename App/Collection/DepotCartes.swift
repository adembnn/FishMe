import Core
import Foundation
import SwiftData

/// Enregistrement local des cartes (SwiftData, sans synchro iCloud) et des photos nettoyées (fichiers, sans GPS).
/// Remplit le contrat `CollectionCartes` de Core.
actor DepotCartes: CollectionCartes {
    private let conteneur: ModelContainer
    private let dossierPhotos: URL
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
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: enMemoire, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
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
            CarteBredouille(id: $0.id, debut: $0.debut, fin: $0.fin, lieuFlou: $0.lieuFlou, conditions: Self.decoder($0.conditionsJSON))
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

    private static func decoder(_ donnees: Data?) -> Conditions? {
        guard let donnees else { return nil }
        return try? JSONDecoder().decode(Conditions.self, from: donnees)
    }
}

enum ErreurDepot: Error {
    /// Une carte ne naît que d'une photo prise dans l'app.
    case photoIllisible
}
