import Core
import Foundation
import SwiftData

/// Une carte d'ami gardée sur l'iPhone pour la lire hors ligne. Les images vivent sur disque, pas dans la base.
@Model
nonisolated final class AmiCarte {
    /// `amiId/carteId` : une carte n'existe qu'une fois par ami.
    @Attribute(.unique) var cle: String
    var amiId: String
    var amiNom: String
    var carteId: UUID
    var espece: String
    var rarete: String
    var date: Date
    var tailleCm: Double?
    var bredouille: Bool
    var departement: String?
    var nomImage: String?

    init(amiId: String, amiNom: String, carte: CartePartagee, nomImage: String?) {
        self.cle = "\(amiId)/\(carte.id.uuidString)"
        self.amiId = amiId
        self.amiNom = amiNom
        self.carteId = carte.id
        self.espece = carte.espece
        self.rarete = carte.rarete.rawValue
        self.date = carte.date
        self.tailleCm = carte.tailleCm
        self.bredouille = carte.bredouille
        self.departement = carte.departement
        self.nomImage = nomImage
    }
}

/// Un ami bloqué : ses cartes ne s'affichent plus, même s'il invite de nouveau.
@Model
nonisolated final class AmiBloque {
    @Attribute(.unique) var amiId: String

    init(amiId: String) {
        self.amiId = amiId
    }
}

/// Le cache des collections d'amis (base locale à part, `cloudKitDatabase: .none`) : lecture hors ligne.
actor CacheAmis {
    private let conteneur: ModelContainer
    private let dossierImages: URL

    init(conteneur: ModelContainer, dossierImages: URL) {
        self.conteneur = conteneur
        self.dossierImages = dossierImages
        try? FileManager.default.createDirectory(at: dossierImages, withIntermediateDirectories: true)
    }

    static func creerConteneur(enMemoire: Bool = false) throws -> ModelContainer {
        let schema = Schema([AmiCarte.self, AmiBloque.self])
        // Hors App Group (comme DepotCartes) : sinon SwiftData vise le conteneur partagé du widget.
        let configuration = ModelConfiguration("Amis", schema: schema, isStoredInMemoryOnly: enMemoire, groupContainer: .none, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func dossierParDefaut() -> URL {
        FileEnvoi.dossierParDefaut().appendingPathComponent("Images", isDirectory: true)
    }

    /// Remplace tout le cache par la dernière lecture : un ami qui a quitté le partage disparaît, ses images aussi.
    func remplacer(par collections: [CollectionAmi]) {
        let contexte = ModelContext(conteneur)
        let bloques = Set(((try? contexte.fetch(FetchDescriptor<AmiBloque>())) ?? []).map(\.amiId))
        for ancienne in (try? contexte.fetch(FetchDescriptor<AmiCarte>())) ?? [] {
            contexte.delete(ancienne)
        }
        try? FileManager.default.removeItem(at: dossierImages)
        try? FileManager.default.createDirectory(at: dossierImages, withIntermediateDirectories: true)
        for collection in collections where !bloques.contains(collection.ami.id) {
            for carte in collection.cartes {
                var nom: String?
                if let image = carte.image {
                    let n = "\(UUID().uuidString).png"
                    if (try? image.write(to: dossierImages.appendingPathComponent(n), options: [.atomic, .completeFileProtection])) != nil {
                        nom = n
                    }
                }
                contexte.insert(AmiCarte(amiId: collection.ami.id, amiNom: collection.ami.nom, carte: carte, nomImage: nom))
            }
        }
        try? contexte.save()
    }

    /// Les collections gardées, sans les amis bloqués.
    func collections() -> [CollectionAmi] {
        let contexte = ModelContext(conteneur)
        let bloques = Set(((try? contexte.fetch(FetchDescriptor<AmiBloque>())) ?? []).map(\.amiId))
        let lignes = (try? contexte.fetch(FetchDescriptor<AmiCarte>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        var parAmi: [String: CollectionAmi] = [:]
        var ordre: [String] = []
        for ligne in lignes where !bloques.contains(ligne.amiId) {
            let carte = CartePartagee(id: ligne.carteId, espece: ligne.espece,
                                      rarete: NiveauRarete(rawValue: ligne.rarete) ?? .nonMesuree, date: ligne.date,
                                      tailleCm: ligne.tailleCm, bredouille: ligne.bredouille, departement: ligne.departement,
                                      image: ligne.nomImage.flatMap { try? Data(contentsOf: dossierImages.appendingPathComponent($0)) })
            if parAmi[ligne.amiId] == nil {
                parAmi[ligne.amiId] = CollectionAmi(ami: Ami(id: ligne.amiId, nom: ligne.amiNom, sens: .recu), cartes: [])
                ordre.append(ligne.amiId)
            }
            parAmi[ligne.amiId]?.cartes.append(carte)
        }
        return ordre.compactMap { parAmi[$0] }
    }

    func bloquer(_ amiId: String) {
        let contexte = ModelContext(conteneur)
        let deja = ((try? contexte.fetch(FetchDescriptor<AmiBloque>())) ?? []).contains { $0.amiId == amiId }
        if !deja { contexte.insert(AmiBloque(amiId: amiId)) }
        for ligne in (try? contexte.fetch(FetchDescriptor<AmiCarte>())) ?? [] where ligne.amiId == amiId {
            if let nom = ligne.nomImage { try? FileManager.default.removeItem(at: dossierImages.appendingPathComponent(nom)) }
            contexte.delete(ligne)
        }
        try? contexte.save()
    }

    func bloques() -> Set<String> {
        let contexte = ModelContext(conteneur)
        return Set(((try? contexte.fetch(FetchDescriptor<AmiBloque>())) ?? []).map(\.amiId))
    }
}
