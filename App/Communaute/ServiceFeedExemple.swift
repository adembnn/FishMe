#if DEBUG
import Core
import Foundation

/// Le fil du mode démo, en Release comme en Debug (décision de Titouan, 19 oct. ; règle 2.1 d'Apple : un relecteur seul, sans compte
/// iCloud ni deuxième iPhone, doit voir un fil rempli). Utilisé quand l'iPhone n'a pas de compte iCloud ou quand l'app est en « Mode démo ».
///
/// Lecture seule : rien n'est écrit, aucun appel à iCloud ni au réseau. Chaque publication porte `exemple = true` et l'écran la marque
/// « Exemple ». Les prénoms sont fictifs ; aucun lieu exact, aucune coordonnée, aucun média réel (l'image est celle de l'espèce).
nonisolated struct ServiceFeedExemple: ServiceFeed {
    func compteDisponible() async -> Bool { true }

    func page(_ demande: DemandeSection) async throws -> PageFeed {
        PageFeed(publications: DonneesExemple.publications(pour: demande.section), encore: false)
    }

    func likes(de publications: [String]) async throws -> [String: [String]] {
        publications.reduce(into: [:]) { sortie, id in
            let n = DonneesExemple.nombreDeLikes(id)
            if n > 0 { sortie[id] = Array(DonneesExemple.aimants.prefix(n)) }
        }
    }

    func commentaires(de publication: String, apres: Date?, limite: Int) async throws -> [CommentaireFeed] {
        guard apres == nil else { return [] }
        return DonneesExemple.commentaires(de: publication)
    }

    func media(de publication: String) async throws -> URL { throw ErreurFeed.introuvable }

    func blocagesPrives() async throws -> [String] { [] }

    // Tout ce qui écrit est refusé : le fil d'exemple se lit, il ne se publie pas.
    func publier(_ brouillon: BrouillonPublication) async throws -> PublicationFeed { throw ErreurFeed.lectureSeule }
    func aimer(publication: String, par auteur: String) async throws { throw ErreurFeed.lectureSeule }
    func nePlusAimer(publication: String, par auteur: String) async throws { throw ErreurFeed.lectureSeule }
    func commenter(_ commentaire: CommentaireFeed) async throws { throw ErreurFeed.lectureSeule }
    func signaler(_ signalement: SignalementFeed) async throws { throw ErreurFeed.lectureSeule }
    func supprimerPublication(_ id: String) async throws { throw ErreurFeed.lectureSeule }
    func supprimerCommentaire(_ id: String) async throws { throw ErreurFeed.lectureSeule }
    func supprimerContenus(de auteur: String) async throws {}
    func bloquer(_ auteur: String) async throws { throw ErreurFeed.lectureSeule }
}

nonisolated enum DonneesExemple {
    static let aimants = ["p-Léa", "p-Hugo", "p-Théo", "p-Camille", "p-Sam"]

    /// Stable d'un lancement à l'autre (`hashValue` ne l'est pas).
    static func nombreDeLikes(_ id: String) -> Int {
        id.utf8.reduce(0) { ($0 + Int($1)) % 1000 } % 6
    }

    static func commentaires(de publication: String, maintenant: Date = Date()) -> [CommentaireFeed] {
        [CommentaireFeed(id: "\(publication)-c1", publication: publication, auteurNom: "p-Léa", texte: "Belle prise, bravo !",
                         creeLe: maintenant.addingTimeInterval(-3_600)),
         CommentaireFeed(id: "\(publication)-c2", publication: publication, auteurNom: "p-Hugo", texte: "Elle a bien mordu ce matin ?",
                         creeLe: maintenant.addingTimeInterval(-1_800))]
    }

    private static func publication(_ section: SectionFeed, _ numero: Int, auteur: String, espece: String, rarete: NiveauRarete,
                                    taille: Double, legende: String, mode: ModeLieu, departement: String, club: String,
                                    ilYaMinutes: Double, maintenant: Date) -> PublicationFeed {
        PublicationFeed(id: "exemple-\(section.rawValue)-\(numero)", auteurNom: auteur, genre: .photo, dureeS: 0, legende: legende,
                        lieuMode: mode, lieuTexte: "", departement: mode == .aucun ? "" : departement, espece: espece, rarete: rarete,
                        tailleCm: taille, club: club, creeLe: maintenant.addingTimeInterval(-ilYaMinutes * 60),
                        vignette: nil, nbLikes: 0, aime: false, exemple: true)
    }

    static func publications(pour section: SectionFeed, maintenant: Date = Date()) -> [PublicationFeed] {
        switch section {
        case .clubs:
            [publication(section, 1, auteur: "p-Camille", espece: "brochet", rarete: .rare, taille: 78,
                         legende: "Sortie du club ce matin, brume et brochet.", mode: .departement, departement: "94",
                         club: "exemple-club", ilYaMinutes: 25, maintenant: maintenant),
             publication(section, 2, auteur: "p-Léa", espece: "perche-commune", rarete: .commun, taille: 27,
                         legende: "Les perchettes étaient là.", mode: .departement, departement: "94",
                         club: "exemple-club", ilYaMinutes: 300, maintenant: maintenant)]
        case .amis:
            [publication(section, 1, auteur: "p-Hugo", espece: "truite-fario", rarete: .peuCommun, taille: 31,
                         legende: "Première truite de la saison, relâchée.", mode: .departement, departement: "77",
                         club: "", ilYaMinutes: 70, maintenant: maintenant),
             publication(section, 2, auteur: "p-Théo", espece: "sandre", rarete: .peuCommun, taille: 61,
                         legende: "Au leurre souple, en fin de journée.", mode: .aucun, departement: "",
                         club: "", ilYaMinutes: 600, maintenant: maintenant),
             publication(section, 3, auteur: "p-Camille", espece: "ombre-commun", rarete: .legendaire, taille: 38,
                         legende: "Un ombre, enfin !", mode: .departement, departement: "94",
                         club: "", ilYaMinutes: 1_500, maintenant: maintenant)]
        case .region:
            [publication(section, 1, auteur: "p-Sam", espece: "carpe-commune", rarete: .commun, taille: 64,
                         legende: "Carpe au coup, bien lutté.", mode: .departement, departement: "94",
                         club: "", ilYaMinutes: 45, maintenant: maintenant),
             publication(section, 2, auteur: "p-Mila", espece: "tanche", rarete: .peuCommun, taille: 36,
                         legende: "Une tanche au lever du jour.", mode: .departement, departement: "94",
                         club: "", ilYaMinutes: 240, maintenant: maintenant),
             publication(section, 3, auteur: "p-Noa", espece: "black-bass", rarete: .rare, taille: 41,
                         legende: "Black-bass sur un poisson nageur.", mode: .departement, departement: "94",
                         club: "", ilYaMinutes: 900, maintenant: maintenant)]
        }
    }
}
#endif
