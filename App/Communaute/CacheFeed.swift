import Core
import Foundation
import SwiftData

/// Une publication gardée sur l'iPhone pour lire le fil hors ligne. La vignette vit sur disque, pas dans la base.
@Model
nonisolated final class PublicationEnCache {
    /// `section/id` : une publication peut figurer dans deux sections.
    @Attribute(.unique) var cle: String
    var section: String
    var id: String
    var auteurNom: String
    var genre: String
    var dureeS: Int
    var legende: String
    var lieuMode: String
    var lieuTexte: String
    var departement: String
    var espece: String?
    var rarete: String?
    var tailleCm: Double?
    var club: String
    var creeLe: Date
    var nomVignette: String?
    var nbLikes: Int
    var aime: Bool

    init(section: String, publication p: PublicationFeed, nomVignette: String?) {
        self.cle = "\(section)/\(p.id)"
        self.section = section
        self.id = p.id
        self.auteurNom = p.auteurNom
        self.genre = p.genre.rawValue
        self.dureeS = p.dureeS
        self.legende = p.legende
        self.lieuMode = p.lieuMode.rawValue
        self.lieuTexte = p.lieuTexte
        self.departement = p.departement
        self.espece = p.espece
        self.rarete = p.rarete?.rawValue
        self.tailleCm = p.tailleCm
        self.club = p.club
        self.creeLe = p.creeLe
        self.nomVignette = nomVignette
        self.nbLikes = p.nbLikes
        self.aime = p.aime
    }
}

/// Un auteur bloqué sur cet iPhone : plus rien de lui, même après un nouveau téléchargement.
@Model
nonisolated final class AuteurBloqueFeed {
    @Attribute(.unique) var nom: String
    init(nom: String) { self.nom = nom }
}

/// Une publication ou un commentaire signalé sur cet iPhone : masqué tout de suite et pour toujours ici.
@Model
nonisolated final class ContenuMasqueFeed {
    @Attribute(.unique) var id: String
    init(id: String) { self.id = id }
}

/// Le cache du fil (base locale à part, `cloudKitDatabase: .none`) : le dernier fil reste lisible en mode avion.
actor CacheFeed {
    private let conteneur: ModelContainer
    private let dossierImages: URL

    init(conteneur: ModelContainer, dossierImages: URL) {
        self.conteneur = conteneur
        self.dossierImages = dossierImages
        try? FileManager.default.createDirectory(at: dossierImages, withIntermediateDirectories: true)
    }

    static func creerConteneur(enMemoire: Bool = false) throws -> ModelContainer {
        let schema = Schema([PublicationEnCache.self, AuteurBloqueFeed.self, ContenuMasqueFeed.self])
        // Hors App Group (comme le cache d'Amis) : sinon SwiftData vise le conteneur partagé du widget.
        let configuration = ModelConfiguration("Feed", schema: schema, isStoredInMemoryOnly: enMemoire, groupContainer: .none, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func dossierParDefaut() -> URL {
        let base = (try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Feed", isDirectory: true)
    }

    // MARK: Lecture et écriture du fil

    /// Garde ces publications pour la section. `remplacer` : première page, l'ancien contenu de la section disparaît.
    func enregistrer(_ publications: [PublicationFeed], section: SectionFeed, remplacer: Bool) {
        let contexte = ModelContext(conteneur)
        if remplacer {
            for ancienne in lignes(contexte, section: section) { contexte.delete(ancienne) }
        }
        for p in publications {
            let cle = "\(section.rawValue)/\(p.id)"
            if let existante = (try? contexte.fetch(FetchDescriptor<PublicationEnCache>(predicate: #Predicate { $0.cle == cle })))?.first {
                contexte.delete(existante)
            }
            contexte.insert(PublicationEnCache(section: section.rawValue, publication: p, nomVignette: copierVignette(p)))
        }
        try? contexte.save()
    }

    /// Les publications gardées de la section, les plus récentes d'abord, sans auteur bloqué ni contenu signalé.
    func lire(section: SectionFeed) -> [PublicationFeed] {
        let contexte = ModelContext(conteneur)
        let bloques = Set(((try? contexte.fetch(FetchDescriptor<AuteurBloqueFeed>())) ?? []).map(\.nom))
        let masquees = Set(((try? contexte.fetch(FetchDescriptor<ContenuMasqueFeed>())) ?? []).map(\.id))
        return lignes(contexte, section: section)
            .filter { !bloques.contains($0.auteurNom) && !masquees.contains($0.id) }
            .sorted { $0.creeLe > $1.creeLe }
            .compactMap(publication(depuis:))
    }

    // MARK: Modération locale

    func bloquer(_ nom: String) {
        let contexte = ModelContext(conteneur)
        if !bloquesDans(contexte).contains(nom) { contexte.insert(AuteurBloqueFeed(nom: nom)) }
        for ligne in (try? contexte.fetch(FetchDescriptor<PublicationEnCache>())) ?? [] where ligne.auteurNom == nom {
            retirerVignette(ligne)
            contexte.delete(ligne)
        }
        try? contexte.save()
    }

    func bloques() -> Set<String> {
        bloquesDans(ModelContext(conteneur))
    }

    func masquer(_ id: String) {
        let contexte = ModelContext(conteneur)
        if !masqueesDans(contexte).contains(id) { contexte.insert(ContenuMasqueFeed(id: id)) }
        for ligne in (try? contexte.fetch(FetchDescriptor<PublicationEnCache>())) ?? [] where ligne.id == id {
            retirerVignette(ligne)
            contexte.delete(ligne)
        }
        try? contexte.save()
    }

    func masquees() -> Set<String> {
        masqueesDans(ModelContext(conteneur))
    }

    /// Une publication supprimée par son auteur : elle quitte le cache.
    func retirer(_ id: String) {
        let contexte = ModelContext(conteneur)
        for ligne in (try? contexte.fetch(FetchDescriptor<PublicationEnCache>())) ?? [] where ligne.id == id {
            retirerVignette(ligne)
            contexte.delete(ligne)
        }
        try? contexte.save()
    }

    /// Suppression du profil : tout le fil gardé disparaît (blocages et masquages restent, ils protègent la personne).
    func effacerLeFil() {
        let contexte = ModelContext(conteneur)
        for ligne in (try? contexte.fetch(FetchDescriptor<PublicationEnCache>())) ?? [] { contexte.delete(ligne) }
        try? contexte.save()
        try? FileManager.default.removeItem(at: dossierImages)
        try? FileManager.default.createDirectory(at: dossierImages, withIntermediateDirectories: true)
    }

    // MARK: Aides

    private func lignes(_ contexte: ModelContext, section: SectionFeed) -> [PublicationEnCache] {
        let brute = section.rawValue
        return (try? contexte.fetch(FetchDescriptor<PublicationEnCache>(predicate: #Predicate { $0.section == brute }))) ?? []
    }

    private func bloquesDans(_ contexte: ModelContext) -> Set<String> {
        Set(((try? contexte.fetch(FetchDescriptor<AuteurBloqueFeed>())) ?? []).map(\.nom))
    }

    private func masqueesDans(_ contexte: ModelContext) -> Set<String> {
        Set(((try? contexte.fetch(FetchDescriptor<ContenuMasqueFeed>())) ?? []).map(\.id))
    }

    private func copierVignette(_ p: PublicationFeed) -> String? {
        guard let source = p.vignette else { return nil }
        let nom = "\(p.id).jpg"
        let cible = dossierImages.appendingPathComponent(nom)
        if source.standardizedFileURL == cible.standardizedFileURL { return nom }
        try? FileManager.default.removeItem(at: cible)
        guard (try? FileManager.default.copyItem(at: source, to: cible)) != nil else { return nil }
        return nom
    }

    private func retirerVignette(_ ligne: PublicationEnCache) {
        // Le fichier est partagé par les sections ; bloquer, masquer et retirer visent toutes les lignes de la publication.
        guard let nom = ligne.nomVignette else { return }
        try? FileManager.default.removeItem(at: dossierImages.appendingPathComponent(nom))
    }

    private func publication(depuis l: PublicationEnCache) -> PublicationFeed? {
        guard let genre = GenreMedia(rawValue: l.genre), let mode = ModeLieu(rawValue: l.lieuMode) else { return nil }
        let vignette = l.nomVignette.map { dossierImages.appendingPathComponent($0) }
            .flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
        return PublicationFeed(id: l.id, auteurNom: l.auteurNom, genre: genre, dureeS: l.dureeS, legende: l.legende, lieuMode: mode,
                               lieuTexte: l.lieuTexte, departement: l.departement, espece: l.espece,
                               rarete: l.rarete.flatMap(NiveauRarete.init(rawValue:)), tailleCm: l.tailleCm, club: l.club,
                               creeLe: l.creeLe, vignette: vignette, nbLikes: l.nbLikes, aime: l.aime)
    }
}
