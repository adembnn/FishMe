import PhotosUI
import SwiftUI
import UIKit

/// Une vidéo choisie dans la photothèque, copiée dans un fichier temporaire.
nonisolated struct FichierVideo: Transferable, Sendable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { recu in
            let copie = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: recu.file, to: copie)
            return FichierVideo(url: copie)
        }
    }
}

/// « Publier » : une photo ou une vidéo de 15 s, une légende courte, le lieu au choix, un club.
/// Depuis une carte du Pescedex : A passe `carte` et `imagePNG`. Depuis le « + » du fil : le pêcheur choisit un média.
struct PublierVue: View {
    @State private var modele: ModelePublication
    @State private var choix: PhotosPickerItem?
    @State private var apercu: UIImage?
    private let gestion: GestionFeed
    private let imagePNG: Data?
    @Environment(\.dismiss) private var fermer
    @Environment(\.dynamicTypeSize) private var taille

    init(gestion: GestionFeed, contexteLieu: ContexteLieu, carte: CarteLiee? = nil, imagePNG: Data? = nil) {
        self.gestion = gestion
        self.imagePNG = imagePNG
        _modele = State(initialValue: ModelePublication(auteurNom: gestion.peutPublier ? gestion.contexte.monNom : nil, contexteLieu: contexteLieu,
                                                        clubs: gestion.contexte.clubs, carte: carte))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                HStack(alignment: .top) {
                    Text("Publier").font(Police.titre).foregroundStyle(Palette.encre).accessibilityAddTraits(.isHeader)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    BoutonRond(role: .fermer)
                }
                mediaBloc
                legendeBloc
                lieuBloc
                if !modele.clubs.isEmpty { clubBloc }
                if let erreur = modele.erreur { Text(erreur).font(Police.detail).foregroundStyle(Palette.alerte) }
                if !gestion.peutPublier {
                    Text("Finis ton profil (15 ans ou plus) pour publier.").font(Police.detail).foregroundStyle(Palette.encreDouce)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button(modele.enCours ? "Envoi…" : "Publier") {
                    Task { if await modele.publier(avec: gestion) { fermer() } }
                }
                .buttonStyle(.principal)
                .disabled(!modele.peutPublier)
                .opacity(modele.peutPublier ? 1 : 0.5)
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .task { if let imagePNG { modele.choisirPhoto(imagePNG); majApercu() } }
        .onChange(of: choix) { _, nouveau in
            guard let nouveau else { return }
            Task { await charger(nouveau) }
        }
    }

    private var mediaBloc: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            if let apercu {
                Image(uiImage: apercu).resizable().scaledToFill()
                    .frame(maxWidth: .infinity).aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            }
            if imagePNG == nil {
                PhotosPicker(selection: $choix, matching: .any(of: [.images, .videos])) {
                    Label(apercu == nil ? "Choisir une photo ou une vidéo" : "Changer", systemImage: "photo.on.rectangle")
                        .font(Police.corps)
                        .frame(maxWidth: .infinity, minHeight: Gabarit.bouton)
                        .tuileFishMe()
                }
                Text("Vidéo : 15 secondes au plus. Aucune position n'est envoyée.")
                    .font(Police.legende).foregroundStyle(Palette.encreDouce)
            }
        }
    }

    private var legendeBloc: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            TextField("Légende (facultatif)", text: $modele.legende, axis: .vertical)
                .font(Police.corps)
                .lineLimit(1...5)
                .padding(Espace.m)
                .frame(minHeight: Gabarit.zoneTactile)
                .tuileFishMe()
            // Le refus et le compteur côte à côte, ou l'un sous l'autre en très grand texte.
            ViewThatFits(in: .horizontal) {
                HStack {
                    if let refus = modele.refus { Text(refus.message).foregroundStyle(Palette.alerte) }
                    Spacer()
                    compteur
                }
                VStack(alignment: .leading, spacing: Espace.xs) {
                    if let refus = modele.refus { Text(refus.message).foregroundStyle(Palette.alerte) }
                    compteur
                }
            }
            .font(Police.legende)
        }
    }

    private var compteur: some View {
        Text("\(modele.legende.count)/\(FiltreTexte.longueurMax)").foregroundStyle(Palette.encreDouce)
    }

    /// Trois choix : « La Marne · 94 », « 94 », « Aucun lieu ». En très grand texte, des lignes plutôt que des segments.
    private var lieuBloc: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text("Lieu montré").font(Police.sousTitre).foregroundStyle(Palette.encre)
            if taille.isAccessibilitySize {
                ForEach(modele.options, id: \.self) { mode in
                    Button {
                        modele.mode = mode
                    } label: {
                        Label(LieuPublication.etiquette(mode, modele.contexteLieu),
                              systemImage: modele.mode == mode ? "checkmark.circle.fill" : "circle")
                            .font(Police.corps)
                            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Picker("Lieu montré", selection: $modele.mode) {
                    ForEach(modele.options, id: \.self) { Text(LieuPublication.etiquette($0, modele.contexteLieu)).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Text("Les autres verront : \(modele.apercuLieu)")
                .font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
    }

    private var clubBloc: some View {
        Picker("Pour le club", selection: $modele.club) {
            Text("Aucun club").tag(String?.none)
            ForEach(modele.clubs) { Text($0.nom).tag(Optional($0.id)) }
        }
        .font(Police.corps)
        .frame(minHeight: Gabarit.zoneTactile)
    }

    private func charger(_ element: PhotosPickerItem) async {
        if element.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
            if let video = try? await element.loadTransferable(type: FichierVideo.self) {
                await modele.choisirVideo(video.url)
            }
        } else if let donnees = try? await element.loadTransferable(type: Data.self) {
            modele.choisirPhoto(donnees)
        }
        majApercu()
    }

    private func majApercu() {
        guard let vignette = modele.media?.vignette else { apercu = nil; return }
        apercu = UIImage(contentsOfFile: vignette.path)
    }
}

#if DEBUG
#Preview {
    PublierVue(gestion: GestionFeed.pourApercu(), contexteLieu: ContexteLieu(eauNom: "La Marne", planDEau: false, departement: "94"))
}
#endif
