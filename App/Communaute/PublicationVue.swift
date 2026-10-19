import SwiftUI
import UIKit

/// Une publication dans le fil : auteur, lieu choisi, image, légende, carte liée, like, commentaires, menu.
struct PublicationVue: View {
    let publication: PublicationFeed
    let gestion: GestionFeed
    @Environment(\.openURL) private var ouvrirURL
    @State private var lecteur = false
    @State private var commentaires = false

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
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
                HStack(spacing: Espace.xs) {
                    if let lieu = publication.lieuAffiche {
                        Image(systemName: "mappin.and.ellipse").accessibilityHidden(true)
                        Text(lieu)
                        Text("·")
                    }
                    Text(publication.creeLe, style: .relative)
                }
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
            }
            Spacer(minLength: 0)
            MenuModeration(
                estMien: gestion.estMienne(publication.auteurNom),
                onSignaler: { motif in
                    Task {
                        if let url = await gestion.signaler(publication, motif: motif) { ouvrirURL(url) }
                    }
                },
                onBloquer: { Task { await gestion.bloquer(publication.auteurNom) } },
                onSupprimer: { Task { await gestion.supprimer(publication) } })
        }
    }

    private var media: some View {
        Button {
            lecteur = true
        } label: {
            ZStack {
                if let url = publication.vignette, let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Palette.tuile
                    Image(systemName: "fish").font(.largeTitle).foregroundStyle(Palette.silhouette)
                }
                if publication.genre == .video {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white)
                        .shadow(radius: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(publication.genre == .video ? "Lire la vidéo" : "Ouvrir la photo")
    }

    private func carteLiee(_ espece: String) -> some View {
        HStack(spacing: Espace.s) {
            if UIImage(named: espece) != nil {
                Image(espece).resizable().scaledToFit().frame(width: 44, height: 28).accessibilityHidden(true)
            }
            Text([espece.replacingOccurrences(of: "-", with: " ").capitalized,
                  publication.tailleCm.map { "\(Int($0)) cm" }].compactMap { $0 }.joined(separator: " · "))
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
        }
        .padding(.horizontal, Espace.m)
        .frame(minHeight: Gabarit.zoneTactile)
        .background(Palette.tuile, in: Capsule())
    }

    private var actions: some View {
        HStack(spacing: Espace.l) {
            Button {
                Task { await gestion.basculerLike(publication) }
            } label: {
                Label("\(publication.nbLikes)", systemImage: publication.aime ? "heart.fill" : "heart")
                    .font(Police.corps)
                    .foregroundStyle(publication.aime ? Palette.bouchon : Palette.encre)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
            .accessibilityLabel(publication.aime ? "Ne plus aimer, \(publication.nbLikes) j'aime" : "Aimer, \(publication.nbLikes) j'aime")
            Button {
                commentaires = true
            } label: {
                Label("Commenter", systemImage: "bubble.left")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
            Spacer(minLength: 0)
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

extension GestionFeed {
    /// Un fil factice, en mémoire, pour les aperçus et les tests.
    static func pourApercu(horsLigne: Bool = false) -> GestionFeed {
        let conteneur = try! CacheFeed.creerConteneur(enMemoire: true)
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent("FeedApercu-\(UUID().uuidString)")
        return GestionFeed(service: FauxServiceFeed(publications: DemoFeed.publications, horsLigne: horsLigne),
                           cache: CacheFeed(conteneur: conteneur, dossierImages: dossier), source: SourceContexteFausse())
    }
}
#endif
