import AVKit
import SwiftUI
import UIKit

/// Un `CKAsset` se télécharge dans un fichier à l'extension `.asset` : `AVPlayer` peut le refuser. On le copie sous un vrai nom `.mp4`.
/// ⚠ à vérifier sur le Mac : lecture réelle d'une vidéo reçue (non vérifiable ici).
nonisolated enum CopieMedia {
    static let dossier = FileManager.default.temporaryDirectory.appendingPathComponent("FeedLecture", isDirectory: true)

    static func copier(_ source: URL, extension ext: String) throws -> URL {
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        let cible = dossier.appendingPathComponent("\(UUID().uuidString).\(ext)")
        try FileManager.default.copyItem(at: source, to: cible)
        return cible
    }

    static func nettoyer() {
        try? FileManager.default.removeItem(at: dossier)
    }
}

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
        .onDisappear {
            lecteur?.pause()
            CopieMedia.nettoyer()
        }
    }

    @ViewBuilder
    private var contenu: some View {
        if let lecteur {
            VideoPlayer(player: lecteur).ignoresSafeArea()
        } else if let fichier, publication.genre == .photo, let image = UIImage(contentsOfFile: fichier.path) {
            Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if echec {
            Text(c: "Impossible de charger hors ligne.")
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
            let recu = try await service.media(de: publication.id)
            let genre = publication.genre
            let url = try await Task.detached { try CopieMedia.copier(recu, extension: genre == .video ? "mp4" : "jpg") }.value
            fichier = url
            if genre == .video {
                let joueur = AVPlayer(url: url)
                lecteur = joueur
                joueur.play()
            }
        } catch is CancellationError {
            // Fermé avant la fin du téléchargement : rien à afficher.
        } catch {
            echec = true
        }
    }
}
