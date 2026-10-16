import Foundation
import PhotosUI
import SwiftUI
import UIKit

/// Un poisson proposé comme image d'un club : RootView le fabrique depuis le catalogue d'espèces de Core.
struct PoissonClub: Identifiable, Hashable {
    let id: String
    let nom: String
    /// Nom de l'image dans les ressources.
    let image: String
}

/// Un club dont on est membre. Il vit seulement sur l'iPhone ; jamais d'annuaire public.
struct ClubLocal: Codable, Identifiable, Hashable {
    var id: UUID
    var nom: String
    /// Image choisie parmi les poissons (identifiant d'espèce) ; `nil` si la photo vient de la galerie.
    var poissonId: String?
    /// Nom du fichier de la photo de galerie (sans GPS) dans Application Support.
    var fichierPhoto: String?
    /// Toujours vrai : les collections ne sont visibles que par les amis invités.
    var amisInvitesSeulement: Bool = true
}

/// Les clubs de l'utilisateur, gardés en JSON dans les réglages. Les photos de galerie sont réécrites sans métadonnées.
@MainActor
@Observable
final class MesClubs {
    private(set) var clubs: [ClubLocal] = []
    private let cle = "club.mesClubs"

    init() {
        if let donnees = UserDefaults.standard.data(forKey: cle),
           let lus = try? JSONDecoder().decode([ClubLocal].self, from: donnees) {
            clubs = lus
        }
    }

    func creer(nom: String, poissonId: String?, photo: Data?) {
        var fichier: String?
        if let photo, let propre = try? ImageSansGPS.nettoyer(photo) {
            let nomFichier = "club-\(UUID().uuidString).png"
            if let url = Self.url(de: nomFichier), (try? propre.write(to: url, options: .atomic)) != nil {
                fichier = nomFichier
            }
        }
        let nomPropre = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        clubs.append(ClubLocal(id: UUID(), nom: nomPropre, poissonId: fichier == nil ? poissonId : nil, fichierPhoto: fichier))
        if let donnees = try? JSONEncoder().encode(clubs) { UserDefaults.standard.set(donnees, forKey: cle) }
    }

    static func url(de fichier: String) -> URL? {
        guard let dossier = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                         appropriateFor: nil, create: true) else { return nil }
        return dossier.appendingPathComponent(fichier)
    }
}

/// La pastille ronde d'un club : sa photo, son poisson, ou une icône.
struct VignetteClub: View {
    let club: ClubLocal
    let poissons: [PoissonClub]
    var taille: CGFloat = 44

    var body: some View {
        Group {
            if let fichier = club.fichierPhoto, let url = MesClubs.url(de: fichier),
               let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let poisson = poissons.first(where: { $0.id == club.poissonId }) {
                Image(poisson.image).resizable().scaledToFit().padding(taille * 0.12)
            } else {
                Image(systemName: "person.3.fill").foregroundStyle(Palette.marine)
            }
        }
        .frame(width: taille, height: taille)
        .background(Palette.marineDoux)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

/// P29 : « Mes clubs », seulement ceux dont on est membre.
struct MesClubsSection: View {
    let clubs: [ClubLocal]
    let poissons: [PoissonClub]
    let creer: () -> Void

    var body: some View {
        Section {
            ForEach(clubs) { club in
                NavigationLink {
                    InviterClubView(club: club)
                } label: {
                    HStack(spacing: Espace.m) {
                        VignetteClub(club: club, poissons: poissons)
                        // À brancher : le nombre de membres vient du partage CloudKit (lot Amis).
                        Text(club.nom).font(Police.sousTitre).foregroundStyle(Palette.encre)
                    }
                    .frame(minHeight: Gabarit.zoneTactile)
                }
            }
            Button(action: creer) {
                Label("Créer un club", systemImage: "plus")
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
        } header: {
            Text("Mes clubs").font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
    }
}

/// P30 : créer un club. Nom, image (un poisson ou une photo de la galerie), collections pour les amis invités seulement.
struct CreerClubView: View {
    let poissons: [PoissonClub]
    let valider: (_ nom: String, _ poissonId: String?, _ photo: Data?) -> Void

    @Environment(\.dismiss) private var fermer
    @State private var nom = ""
    @State private var poissonChoisi: String?
    @State private var choixGalerie: PhotosPickerItem?
    @State private var photo: Data?

    private var peutCreer: Bool { !nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.xl) {
                    bloc("Nom") {
                        TextField("Nom du club", text: $nom)
                            .font(Police.sousTitre)
                            .frame(minHeight: Gabarit.zoneTactile)
                            .padding(.horizontal, Espace.l)
                            .tuileFishMe()
                    }
                    bloc("Image") { grille }
                    bloc("Qui voit les collections") {
                        HStack(spacing: Espace.m) {
                            Image(systemName: "lock.fill").foregroundStyle(Palette.marine)
                            Text("Amis invités seulement").font(Police.sousTitre).foregroundStyle(Palette.encre)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.marine)
                        }
                        .frame(minHeight: Gabarit.zoneTactile)
                        .padding(.horizontal, Espace.l)
                        .tuileFishMe()
                        Text("Jamais en public. Seuls les amis que tu invites voient tes cartes.")
                            .font(Police.legende).foregroundStyle(Palette.encreDouce)
                    }
                }
                .padding(Espace.bord)
            }
            .scrollIndicators(.hidden)
            .background(Palette.fond.ignoresSafeArea())
            .navigationTitle("Nouveau club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { fermer() } }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Créer le club") {
                    valider(nom, poissonChoisi, photo)
                    fermer()
                }
                .buttonStyle(.principal)
                .disabled(!peutCreer)
                .opacity(peutCreer ? 1 : 0.5)
                .padding(.horizontal, Espace.bord)
                .padding(.bottom, Espace.s)
            }
            .onChange(of: choixGalerie) { _, nouveau in
                guard let nouveau else { return }
                Task {
                    let donnees = try? await nouveau.loadTransferable(type: Data.self)
                    photo = donnees
                    if donnees != nil { poissonChoisi = nil }
                }
            }
        }
    }

    private func bloc<Contenu: View>(_ titre: String, @ViewBuilder _ contenu: () -> Contenu) -> some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(titre.uppercased()).font(Police.legende).foregroundStyle(Palette.encreDouce)
            contenu()
        }
    }

    private var grille: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Espace.m), count: 3), spacing: Espace.m) {
            PhotosPicker(selection: $choixGalerie, matching: .images) {
                tuileGalerie
            }
            .accessibilityLabel("Galerie")
            ForEach(poissons) { poisson in
                Button {
                    poissonChoisi = poisson.id
                    photo = nil
                    choixGalerie = nil
                } label: {
                    Image(poisson.image).resizable().scaledToFit().padding(Espace.s)
                        .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                        .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                        .overlay(selection(poissonChoisi == poisson.id && photo == nil))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(poisson.nom)
            }
        }
        .padding(Espace.m)
        .tuileFishMe(rayon: Rayon.l)
    }

    private var tuileGalerie: some View {
        ZStack(alignment: .bottom) {
            if let photo, let image = UIImage(data: photo) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Palette.marineDoux
                Image(systemName: "photo.on.rectangle").font(Police.titre).foregroundStyle(Palette.marine)
                    .frame(maxHeight: .infinity)
            }
            Label("Galerie", systemImage: "photo")
                .font(Police.legende).foregroundStyle(Palette.surMarine)
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(Palette.marine)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .overlay(selection(photo != nil))
    }

    @ViewBuilder
    private func selection(_ actif: Bool) -> some View {
        if actif {
            RoundedRectangle(cornerRadius: Rayon.m, style: .continuous).strokeBorder(Palette.marine, lineWidth: 3)
        }
    }
}

/// P31 : inviter. Le lien et la liste des invités viennent du partage CloudKit du lot Amis.
struct InviterClubView: View {
    let club: ClubLocal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                // À brancher : lien d'invitation (ShareLink d'AmisView) et état des invités (Ami.enAttente), pas de donnée ici.
                ContentUnavailableView("Aucune invitation", systemImage: "person.badge.plus",
                                       description: Text("Invite des amis depuis l'onglet Amis."))
                Text("Ton coin exact ne quitte jamais ton iPhone. Les amis invités voient tes cartes, personne d'autre.")
                    .font(Police.legende).foregroundStyle(Palette.encreDouce)
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .navigationTitle(club.nom)
        .navigationBarTitleDisplayMode(.inline)
    }
}
