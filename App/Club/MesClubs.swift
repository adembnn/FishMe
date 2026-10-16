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

// MARK: - Briques communes des écrans Club

/// Le titre d'un groupe : petites capitales discrètes au-dessus de la carte blanche (« MES CLUBS »).
struct EnteteGroupeClub: View {
    let titre: String

    var body: some View {
        Text(titre.uppercased())
            .font(Police.legende)
            .foregroundStyle(Palette.encreDouce)
            .padding(.horizontal, Espace.l)
            .padding(.top, Espace.xl)
            .padding(.bottom, Espace.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// La carte blanche d'un groupe ; les lignes y sont séparées par un filet.
struct GroupeClub<Contenu: View>: View {
    @ViewBuilder let contenu: () -> Contenu

    var body: some View {
        VStack(spacing: 0, content: contenu)
            .frame(maxWidth: .infinity)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
    }
}

/// Le filet entre deux lignes, aligné sur le texte.
struct FiletClub: View {
    var retrait: CGFloat = Espace.l

    var body: some View {
        Rectangle().fill(Palette.filet).frame(height: 1).padding(.leading, retrait)
    }
}

/// La pastille ronde d'un membre : son initiale. En attente : fond blanc et contour.
struct PastilleMembre: View {
    let nom: String
    let rang: Int
    var enAttente = false
    var taille: CGFloat = 36

    private var fond: Color {
        [Palette.marine, Palette.ouvert, Palette.nuit][rang % 3]
    }

    var body: some View {
        Text(String(nom.prefix(1)).uppercased())
            .font(Police.taille(15, .heavy))
            .foregroundStyle(enAttente ? Palette.encreDouce : Palette.surMarine)
            .frame(width: taille, height: taille)
            .background {
                if enAttente {
                    Circle().fill(Palette.surface).overlay(Circle().strokeBorder(Palette.silhouette, lineWidth: 2))
                } else {
                    Circle().fill(fond)
                }
            }
            .accessibilityHidden(true)
    }
}

/// La vignette d'un poisson : 48 x 32, fond doux, coins de 8.
struct VignettePoissonClub: View {
    let image: String

    var body: some View {
        Image(image)
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 6)
            .frame(width: 48, height: 32)
            .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
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

    /// Les cinq poissons les plus pêchés d'abord (comme la maquette), puis les autres ; six tuiles en tout avec la galerie.
    private var proposes: [PoissonClub] {
        let preferes = ["perche-commune", "brochet", "sandre", "carpe-commune", "truite-fario"]
        let premiers = preferes.compactMap { id in poissons.first { $0.id == id } }
        let autres = poissons.filter { p in !preferes.contains(p.id) }
        return Array((premiers + autres).prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    EnteteGroupeClub(titre: "Nom").padding(.top, Espace.s)
                    GroupeClub {
                        TextField("Nom du club", text: $nom)
                            .font(Police.corps)
                            .foregroundStyle(Palette.encre)
                            .frame(minHeight: 56)
                            .padding(.horizontal, Espace.l)
                    }
                    EnteteGroupeClub(titre: "Image")
                    GroupeClub { grille.padding(Espace.m) }
                    EnteteGroupeClub(titre: "Qui voit les collections")
                    GroupeClub {
                        HStack(spacing: Espace.m) {
                            Image(systemName: "lock.fill").foregroundStyle(Palette.marine)
                            Text("Amis invités seulement").font(Police.corps).foregroundStyle(Palette.encre)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Palette.marine)
                        }
                        .frame(minHeight: 56)
                        .padding(.horizontal, Espace.l)
                    }
                    Text("Jamais en public. Seuls les amis que tu invites voient tes cartes.")
                        .font(Police.legende).foregroundStyle(Palette.encreDouce)
                        .padding(.horizontal, Espace.l).padding(.top, Espace.s)
                }
                .padding(.horizontal, Espace.bord)
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

    private var grille: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Espace.s), count: 3), spacing: Espace.s) {
            PhotosPicker(selection: $choixGalerie, matching: .images) {
                tuileGalerie
            }
            .accessibilityLabel("Galerie")
            ForEach(proposes) { poisson in
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
                .frame(maxWidth: .infinity, minHeight: 24)
                .background(Palette.marine)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .overlay(selection(photo != nil))
    }

    /// Le contour marine et la coche d'une tuile choisie.
    @ViewBuilder
    private func selection(_ actif: Bool) -> some View {
        if actif {
            ZStack {
                RoundedRectangle(cornerRadius: Rayon.m, style: .continuous).strokeBorder(Palette.marine, lineWidth: 2.5)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.surMarine, Palette.marine)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(4)
            }
        }
    }
}

/// P31 : inviter. Le lien, la liste des invités et l'envoi viennent du partage CloudKit du lot Amis ;
/// tant que RootView ne les passe pas, les blocs correspondants restent vides ou masqués.
struct InviterClubView: View {
    let club: ClubLocal
    /// À brancher : adresse courte du club (partage CloudKit). Sans elle, la ligne « Lien d'invitation » n'apparaît pas.
    var lienTexte: String? = nil
    /// À brancher : `Ami.enAttente` et `Ami.jeVoisSaCollection` du lot Amis.
    var invites: [InviteClub] = []
    /// À brancher : le partage CloudKit en lecture seule, réservé aux personnes invitées.
    var invitation: InvitationPescedex? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let lienTexte {
                    EnteteGroupeClub(titre: "Lien d'invitation").padding(.top, Espace.s)
                    GroupeClub {
                        HStack {
                            Text(lienTexte)
                                .font(.system(size: 15, weight: .regular, design: .monospaced))
                                .foregroundStyle(Palette.encre)
                                .lineLimit(1)
                            Spacer(minLength: Espace.s)
                            Button("Copier") { UIPasteboard.general.string = lienTexte }
                                .font(Police.corps)
                                .foregroundStyle(Palette.marine)
                        }
                        .frame(minHeight: 56)
                        .padding(.horizontal, Espace.l)
                    }
                }
                if !invites.isEmpty {
                    EnteteGroupeClub(titre: "Invitations").padding(.top, lienTexte == nil ? Espace.s : Espace.xl)
                    GroupeClub {
                        ForEach(Array(invites.enumerated()), id: \.element.id) { rang, invite in
                            if rang > 0 { FiletClub() }
                            HStack(spacing: Espace.m) {
                                PastilleMembre(nom: invite.nom, rang: rang, enAttente: !invite.acceptee)
                                Text(invite.nom).font(Police.corps).foregroundStyle(Palette.encre)
                                Spacer()
                                Text(invite.acceptee ? "Acceptée" : "En attente")
                                    .font(Police.corps)
                                    .foregroundStyle(invite.acceptee ? Palette.ouvert : Palette.encreDouce)
                            }
                            .frame(minHeight: 56)
                            .padding(.horizontal, Espace.l)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                Text("Ton coin exact ne quitte jamais ton iPhone. Les amis invités voient tes cartes, personne d'autre.")
                    .font(Police.legende).foregroundStyle(Palette.encreDouce)
                    .padding(.horizontal, Espace.l).padding(.top, Espace.m)
            }
            .padding(.horizontal, Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .navigationTitle("Inviter")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Group {
                if let invitation {
                    ShareLink(item: invitation, preview: SharePreview(club.nom)) {
                        Label("Envoyer l'invitation", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.principal)
                } else {
                    Button {} label: { Label("Envoyer l'invitation", systemImage: "square.and.arrow.up") }
                        .buttonStyle(.principal)
                        .disabled(true)
                        .opacity(0.5)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, Espace.s)
        }
    }
}
