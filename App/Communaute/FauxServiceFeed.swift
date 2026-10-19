#if DEBUG
import Core
import Foundation

/// Faux service du fil pour les tests et les aperçus : tout en mémoire, un interrupteur « hors ligne », aucun appel à iCloud.
actor FauxServiceFeed: ServiceFeed {
    private(set) var publications: [PublicationFeed]
    private(set) var commentairesEcrits: [CommentaireFeed] = []
    private(set) var likesEcrits: [String: Set<String>] = [:]
    private(set) var signalements: [SignalementFeed] = []
    private(set) var blocages: [String] = []
    private(set) var contenusEffaces: [String] = []
    private(set) var appelsPage = 0
    private var horsLigne: Bool
    private var compte: Bool

    init(publications: [PublicationFeed] = [], commentaires: [CommentaireFeed] = [], horsLigne: Bool = false, compte: Bool = true) {
        self.publications = publications
        self.commentairesEcrits = commentaires
        self.horsLigne = horsLigne
        self.compte = compte
    }

    func regler(horsLigne: Bool) { self.horsLigne = horsLigne }

    private func verifier() throws {
        if horsLigne { throw ErreurFeed.reseau }
    }

    func compteDisponible() async -> Bool { compte }

    func publier(_ b: BrouillonPublication) async throws -> PublicationFeed {
        try verifier()
        let p = PublicationFeed(id: b.id, auteurNom: b.auteurNom, genre: b.genre, dureeS: b.dureeS, legende: b.legende,
                                lieuMode: b.lieu.mode, lieuTexte: b.lieu.lieuTexte, departement: b.lieu.departement,
                                espece: b.carte?.espece, rarete: b.carte?.rarete, tailleCm: b.carte?.tailleCm, club: b.club,
                                creeLe: Date(), vignette: b.vignette)
        publications.insert(p, at: 0)
        return p
    }

    func page(_ d: DemandeSection) async throws -> PageFeed {
        try verifier()
        appelsPage += 1
        let champ: (PublicationFeed) -> String = { p in
            switch d.section {
            case .clubs: p.club
            case .amis: p.auteurNom
            case .region: p.departement
            }
        }
        let tries = publications
            .filter { pub in
                let valeur = champ(pub)
                let avantLimite = d.avant.map { limite in pub.creeLe < limite } ?? true
                return !valeur.isEmpty && d.valeurs.contains(valeur) && avantLimite
            }
            .sorted { $0.creeLe > $1.creeLe }
        let page = Array(tries.prefix(d.limite))
        return PageFeed(publications: page, encore: page.count >= d.limite && tries.count > d.limite)
    }

    func likes(de ids: [String]) async throws -> [String: [String]] {
        try verifier()
        return ids.reduce(into: [:]) { sortie, id in
            if let auteurs = likesEcrits[id], !auteurs.isEmpty { sortie[id] = Array(auteurs) }
        }
    }

    func aimer(publication: String, par auteur: String) async throws {
        try verifier()
        likesEcrits[publication, default: []].insert(auteur)
    }

    func nePlusAimer(publication: String, par auteur: String) async throws {
        try verifier()
        likesEcrits[publication]?.remove(auteur)
    }

    func commentaires(de publication: String, apres: Date?, limite: Int) async throws -> [CommentaireFeed] {
        try verifier()
        let tous = commentairesEcrits.filter { c in
            c.publication == publication && (apres.map { a in c.creeLe > a } ?? true)
        }
        return Array(tous.sorted { $0.creeLe < $1.creeLe }.prefix(limite))
    }

    func commenter(_ commentaire: CommentaireFeed) async throws {
        try verifier()
        commentairesEcrits.append(commentaire)
    }

    func signaler(_ signalement: SignalementFeed) async throws {
        try verifier()
        signalements.append(signalement)
    }

    func supprimerPublication(_ id: String) async throws {
        try verifier()
        publications.removeAll { $0.id == id }
    }

    func supprimerCommentaire(_ id: String) async throws {
        try verifier()
        commentairesEcrits.removeAll { $0.id == id }
    }

    func supprimerContenus(de auteur: String) async throws {
        try verifier()
        contenusEffaces.append(auteur)
        publications.removeAll { $0.auteurNom == auteur }
        commentairesEcrits.removeAll { $0.auteurNom == auteur }
        for cle in likesEcrits.keys { likesEcrits[cle]?.remove(auteur) }
    }

    func media(de publication: String) async throws -> URL {
        try verifier()
        throw ErreurFeed.introuvable
    }

    func bloquer(_ auteur: String) async throws {
        try verifier()
        blocages.append(auteur)
    }
}

/// Une source de contexte fixe, pour les tests et les aperçus.
nonisolated struct SourceContexteFausse: SourceContexte {
    var nom: String? = "p-moi"
    var amis: [String] = ["p-gros-brochet"]
    var clubs: [ClubResume] = [ClubResume(id: "club-1", nom: "Les Bords de Marne")]
    var departements: [String] = ["94"]
    var lieu = ContexteLieu(eauNom: "La Marne", planDEau: false, departement: "94")

    func monNom() async -> String? { nom }
    func nomsDesAmis() async -> [String] { amis }
    func mesClubs() async -> [ClubResume] { clubs }
    func departementsDeMaRegion() async -> [String] { departements }
    func lieuCourant() async -> ContexteLieu { lieu }
}

/// Des publications factices pour les aperçus (aucune image : la vignette est vide).
nonisolated enum DemoFeed {
    static let maintenant = Date(timeIntervalSince1970: 1_792_400_000)

    static func publication(_ id: String, auteur: String = "p-gros-brochet", mode: ModeLieu = .coursEau, club: String = "club-1",
                            ilYa minutes: Double = 5) -> PublicationFeed {
        PublicationFeed(id: id, auteurNom: auteur, genre: id.hasSuffix("v") ? .video : .photo, dureeS: id.hasSuffix("v") ? 12 : 0,
                        legende: "Un beau brochet ce matin.", lieuMode: mode,
                        lieuTexte: mode == .coursEau ? "La Marne · 94" : "", departement: mode == .aucun ? "" : "94",
                        espece: "brochet", rarete: .rare, tailleCm: 62, club: club,
                        creeLe: maintenant.addingTimeInterval(-minutes * 60), vignette: nil)
    }

    static let publications: [PublicationFeed] = [
        publication("a1v", ilYa: 5), publication("a2", mode: .departement, club: "", ilYa: 40),
        publication("a3", auteur: "p-inconnu", mode: .aucun, club: "", ilYa: 90),
    ]
}
#endif
