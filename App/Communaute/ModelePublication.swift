import Core
import Foundation
import Observation

/// La logique de l'écran « Publier » : média prêt, légende filtrée, lieu au choix, club facultatif.
@MainActor
@Observable
final class ModelePublication {
    let contexteLieu: ContexteLieu
    let clubs: [ClubResume]
    let carte: CarteLiee?
    var legende = ""
    var mode: ModeLieu
    /// `nil` : aucun club.
    var club: String?
    private(set) var media: MediaPret?
    /// Calculé : pas d'observateur `didSet` dans une classe `@Observable`. La troncature se fait dans le Binding de la vue.
    var refus: RefusTexte? { FiltreTexte.verifier(legende) }
    private(set) var enCours = false
    private(set) var erreur: String?
    private let auteurNom: String?

    init(auteurNom: String?, contexteLieu: ContexteLieu, clubs: [ClubResume], carte: CarteLiee? = nil) {
        self.auteurNom = auteurNom
        self.contexteLieu = contexteLieu
        self.clubs = clubs
        self.carte = carte
        // Décision de Titouan (19 oct.) : « département seul » par défaut, jamais le cours d'eau ; le premier club s'il y en a un.
        self.mode = LieuPublication.parDefaut(contexteLieu)
        self.club = clubs.first?.id
    }

    var options: [ModeLieu] { LieuPublication.options(contexteLieu) }
    var apercuLieu: String { LieuPublication.apercu(mode, contexteLieu) }
    var peutPublier: Bool { media != nil && refus == nil && auteurNom != nil && !enCours }

    func choisirPhoto(_ donnees: Data) {
        erreur = nil
        do {
            media = try PreparationMedia.preparerPhoto(donnees, dossier: Self.dossier)
        } catch {
            media = nil
            erreur = "Cette photo ne peut pas être publiée."
        }
    }

    func choisirVideo(_ source: URL) async {
        erreur = nil
        enCours = true
        defer { enCours = false }
        do {
            media = try await PreparationMedia.preparerVideo(depuis: source, dossier: Self.dossier)
        } catch {
            media = nil
            erreur = "Cette vidéo ne peut pas être publiée."
        }
    }

    /// `nil` tant que quelque chose manque ou que la légende est refusée.
    func brouillon() -> BrouillonPublication? {
        guard let media, let auteurNom, refus == nil, let lieu = LieuPublication.choisir(mode, contexteLieu) else { return nil }
        return BrouillonPublication(auteurNom: auteurNom, genre: media.genre, fichierMedia: media.fichier, vignette: media.vignette,
                                    dureeS: media.dureeS, legende: legende.trimmingCharacters(in: .whitespacesAndNewlines),
                                    lieu: lieu, carte: carte, club: club ?? "")
    }

    func publier(avec gestion: GestionFeed) async -> Bool {
        guard let brouillon = brouillon() else { return false }
        enCours = true
        defer { enCours = false }
        do {
            try await gestion.publier(brouillon)
            nettoyer()
            return true
        } catch {
            erreur = "La publication n'est pas partie. Réessaie."
            return false
        }
    }

    private func nettoyer() {
        try? FileManager.default.removeItem(at: Self.dossier)
    }

    private static var dossier: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("FeedPreparation", isDirectory: true)
    }
}

/// Les commentaires d'une publication : 20 chargés, « voir plus », 280 caractères, mots interdits.
@MainActor
@Observable
final class ModeleCommentaires {
    private(set) var commentaires: [CommentaireFeed] = []
    private(set) var encore = false
    private(set) var erreur: String?
    var texte = ""
    var refus: RefusTexte? { FiltreTexte.verifier(texte) }

    let publication: PublicationFeed
    private let gestion: GestionFeed

    init(publication: PublicationFeed, gestion: GestionFeed) {
        self.publication = publication
        self.gestion = gestion
    }

    var peutEnvoyer: Bool {
        refus == nil && !texte.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && gestion.peutPublier
    }

    func charger(plus: Bool = false) async {
        let apres = plus ? commentaires.last?.creeLe : nil
        do {
            let recus = try await gestion.service.commentaires(de: publication.id, apres: apres, limite: 20)
            let base = plus ? commentaires : []
            commentaires = base + recus.filter { gestion.estVisible($0) }
            encore = recus.count >= 20
            erreur = nil
        } catch is CancellationError {
            // La feuille s'est fermée : pas de message parasite.
        } catch {
            erreur = "Commentaires indisponibles hors ligne."
        }
    }

    func envoyer() async {
        guard peutEnvoyer, let moi = gestion.contexte.monNom else { return }
        let c = CommentaireFeed(id: UUID().uuidString, publication: publication.id, auteurNom: moi,
                                texte: texte.trimmingCharacters(in: .whitespacesAndNewlines), creeLe: Date())
        do {
            try await gestion.service.commenter(c)
            commentaires.append(c)
            texte = ""
        } catch {
            erreur = "Le commentaire n'est pas parti. Réessaie."
        }
    }

    func supprimer(_ c: CommentaireFeed) async {
        commentaires.removeAll { $0.id == c.id }
        try? await gestion.service.supprimerCommentaire(c.id)
    }

    /// Signalé : masqué ici tout de suite.
    func signaler(_ c: CommentaireFeed, motif: MotifSignalementPublication) async -> IssueSignalement {
        commentaires.removeAll { $0.id == c.id }
        return await gestion.signaler(c, motif: motif)
    }

    func bloquer(_ c: CommentaireFeed) async {
        commentaires.removeAll { $0.auteurNom == c.auteurNom }
        await gestion.bloquer(c.auteurNom)
    }
}
