import AVKit
import SwiftUI
import UIKit

/// Plein écran : la photo en grand, ou la vidéo de 15 s. Le fichier complet se télécharge à l'ouverture.
struct LecteurMediaVue: View {
    let publication: PublicationFeed
    let service: any ServiceFeed
    @State private var fichier: URL?
    @State private var echec = false
    @State private var lecteur: AVPlayer?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            contenu
            BoutonRond(role: .fermer)
                .padding(Espace.bord)
        }
        .task { await charger() }
        .onDisappear { lecteur?.pause() }
    }

    @ViewBuilder
    private var contenu: some View {
        if let lecteur {
            VideoPlayer(player: lecteur).ignoresSafeArea()
        } else if let fichier, publication.genre == .photo, let image = UIImage(contentsOfFile: fichier.path) {
            Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if echec {
            Text("Impossible de charger hors ligne.")
                .font(Police.corps)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(Espace.xl)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ProgressView().tint(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func charger() async {
        do {
            let url = try await service.media(de: publication.id)
            fichier = url
            if publication.genre == .video {
                let joueur = AVPlayer(url: url)
                lecteur = joueur
                joueur.play()
            }
        } catch {
            echec = true
        }
    }
}
