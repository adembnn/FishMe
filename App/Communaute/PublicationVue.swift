import SwiftUI
import UIKit

/// Les vignettes décodées une seule fois : `body` se rejoue souvent, le décodage d'un fichier ne doit pas suivre.
/// ⚠ à vérifier sur le Mac : `UIImage` passé d'une tâche détachée à l'acteur principal (Sendable depuis iOS 17 ?).
nonisolated final class CacheImagesFeed: @unchecked Sendable {
    static let partage = CacheImagesFeed()
    private let cache = NSCache<NSString, UIImage>()

    private init() { cache.countLimit = 60 }

    func image(depuis url: URL) -> UIImage? {
        let cle = url.path as NSString
        if let connue = cache.object(forKey: cle) { return connue }
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: cle)
        return image
    }
}

/// Une publication dans le fil : auteur, lieu choisi, image, légende, carte liée, like, commentaires, menu.
struct PublicationVue: View {
    let publication: PublicationFeed
    let gestion: GestionFeed
    @Environment(\.openURL) private var ouvrirURL
    @State private var lecteur = false
    @State private var commentaires = false
    @State private var image: UIImage?
    /// Suit la taille du texte : l'icône « lecture » ne reste pas à 52 pt fixes en très grand texte.
    @ScaledMetric(relativeTo: .largeTitle) private var tailleLecture: CGFloat = 52

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            if publication.exemple { pastilleExemple }
            entete
            media
            if !publication.legende.isEmpty {
                Text(publication.legende)
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let espece = publication.espece { carteLiee(espece) }
            actions
        }
        .padding(Espace.l)
        .tuileFishMe(rayon: Rayon.l)
        .accessibilityElement(children: .contain)
        .fullScreenCover(isPresented: $lecteur) { LecteurMediaVue(publication: publication, service: gestion.service) }
        .sheet(isPresented: $commentaires) { CommentairesVue(publication: publication, gestion: gestion) }
        .task(id: publication.vignette) { await chargerImage() }
    }

    /// Décodée hors du fil principal, une fois (cache), pas à chaque `body`.
    private func chargerImage() async {
        guard let url = publication.vignette else { image = nil; return }
        image = await Task.detached { CacheImagesFeed.partage.image(depuis: url) }.value
    }

    private var pastilleExemple: some View {
        Text("Exemple")
            .font(Police.legende)
            .foregroundStyle(Palette.marineFonce)
            .padding(.horizontal, Espace.m)
            .frame(minHeight: 28)
            .background(Palette.marineDoux, in: Capsule())
            .accessibilityLabel("Publication d'exemple")
    }

    private var entete: some View {
        HStack(alignment: .top, spacing: Espace.m) {
            // À aligner L21 : l'avatar du profil remplace l'initiale.
            Text(String(publication.auteurAffiche.prefix(1)).uppercased())
                .font(Police.sousTitre)
                .foregroundStyle(Palette.marineFonce)
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .background(Palette.marineDoux, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Espace.xs) {
                Text(publication.auteurAffiche).font(Police.sousTitre).foregroundStyle(Palette.encre)
                    .fixedSize(horizontal: false, vertical: true)
                lieuEtDate
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
            }
            Spacer(minLength: 0)
            MenuModeration(
                estMien: gestion.estMienne(publication.auteurNom),
                onSignaler: { motif in
                    Task {
                        let issue = await gestion.signaler(publication, motif: motif)
                        if let url = issue.courriel { ouvrirURL(url) }
                    }
                },
                onBloquer: { Task { await gestion.bloquer(publication.auteurNom) } },
                onSupprimer: { Task { await gestion.supprimer(publication) } })
        }
    }

    /// Lieu et date sur une ligne ; en très grand texte, sur deux (`ViewThatFits`), jamais coupés.
    private var lieuEtDate: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Espace.xs) {
                if let lieu = publication.lieuAffiche {
                    Image(systemName: "mappin.and.ellipse").accessibilityHidden(true)
                    Text(lieu)
                    Text("·")
                }
                Text(publication.creeLe, style: .relative)
            }
            VStack(alignment: .leading, spacing: Espace.xs) {
                if let lieu = publication.lieuAffiche {
                    Label(lieu, systemImage: "mappin.and.ellipse")
                }
                Text(publication.creeLe, style: .relative)
            }
        }
    }

    private var media: some View {
        Button {
            lecteur = true
        } label: {
            ZStack {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else if publication.exemple, let espece = publication.espece, UIImage(named: espece) != nil {
                    // Publication d'exemple : pas de photo, l'image de l'espèce.
                    Palette.eauClaire
                    Image(espece).resizable().scaledToFit().padding(Espace.xl)
                } else {
                    Palette.tuile
                    Image(systemName: "fish").font(.largeTitle).foregroundStyle(Palette.silhouette)
                }
                if publication.genre == .video, !publication.exemple {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: tailleLecture))
                        .foregroundStyle(.white)
                        .shadow(radius: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(publication.exemple)
        .accessibilityLabel(publication.exemple ? "Image d'exemple" : (publication.genre == .video ? "Lire la vidéo" : "Ouvrir la photo"))
    }

    private func carteLiee(_ espece: String) -> some View {
        HStack(spacing: Espace.s) {
            if UIImage(named: espece) != nil {
                Image(espece).resizable().scaledToFit().frame(width: 44, height: 28).accessibilityHidden(true)
            }
            Text([espece.replacingOccurrences(of: "-", with: " ").capitalized,
                  FabriqueFeed.centimetres(publication.tailleCm).map { "\($0) cm" }].compactMap { $0 }.joined(separator: " · "))
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Espace.m)
        .padding(.vertical, Espace.xs)
        .frame(minHeight: Gabarit.zoneTactile)
        .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }

    /// J'aime et Commenter côte à côte, ou l'un sous l'autre quand la place manque (très grand texte).
    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Espace.l) {
                boutonLike
                boutonCommenter
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: Espace.xs) {
                boutonLike
                boutonCommenter
            }
        }
    }

    private var boutonLike: some View {
        Button {
            Task { await gestion.basculerLike(publication) }
        } label: {
            Label("\(publication.nbLikes)", systemImage: publication.aime ? "heart.fill" : "heart")
                .font(Police.corps)
                .foregroundStyle(publication.aime ? Palette.marine : Palette.encre)
                .frame(minHeight: Gabarit.zoneTactile)
        }
        .accessibilityLabel(publication.aime ? "Ne plus aimer, \(publication.nbLikes) j'aime" : "Aimer, \(publication.nbLikes) j'aime")
    }

    private var boutonCommenter: some View {
        Button {
            commentaires = true
        } label: {
            Label("Commenter", systemImage: "bubble.left")
                .font(Police.corps)
                .foregroundStyle(Palette.encre)
                .frame(minHeight: Gabarit.zoneTactile)
        }
    }
}

#if DEBUG
#Preview {
    ScrollView {
        PublicationVue(publication: DemoFeed.publications[0], gestion: GestionFeed.pourApercu())
            .padding(Espace.bord)
    }
    .background(Palette.fond)
}

#Preview("Très grand texte") {
    ScrollView {
        PublicationVue(publication: DemoFeed.publications[0], gestion: GestionFeed.pourApercu())
            .padding(Espace.bord)
    }
    .background(Palette.fond)
    .environment(\.dynamicTypeSize, .accessibility5)
}

extension GestionFeed {
    /// Un fil factice, en mémoire, pour les aperçus et les tests. `sansCompte` : pas d'iCloud, donc le fil d'exemple.
    static func pourApercu(horsLigne: Bool = false, sansCompte: Bool = false) -> GestionFeed {
        let conteneur = try! CacheFeed.creerConteneur(enMemoire: true)
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent("FeedApercu-\(UUID().uuidString)")
        return GestionFeed(service: FauxServiceFeed(publications: DemoFeed.publications, horsLigne: horsLigne, compte: !sansCompte),
                           cache: CacheFeed(conteneur: conteneur, dossierImages: dossier), source: SourceContexteFausse(),
                           exemple: ServiceFeedExemple())
    }
}
#endif
