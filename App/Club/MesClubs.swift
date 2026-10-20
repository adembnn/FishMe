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
    /// L22 : l'image d'un club EN LIGNE (JPEG de CloudKit), pour que l'écran dessine un club en ligne comme un club local.
    /// Jamais écrite dans les réglages (absente de `CodingKeys`) ; les clubs locaux d'avant la mise à jour se relisent tels quels.
    var imageEnLigne: Data? = nil

    enum CodingKeys: String, CodingKey { case id, nom, poissonId, fichierPhoto, amisInvitesSeulement }
}

extension ClubLocal {
    /// Un club en ligne présenté comme un `ClubLocal` pour les écrans existants. `nil` si son identifiant n'est pas un UUID.
    init?(enLigne club: Club) {
        guard let uuid = UUID(uuidString: club.id) else { return nil }
        self.init(id: uuid, nom: club.nom, poissonId: club.poissonId, fichierPhoto: nil)
        imageEnLigne = club.image
    }
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
            if let donnees = club.imageEnLigne, let image = ImagesClubEnCache.image(donnees) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let fichier = club.fichierPhoto, let url = MesClubs.url(de: fichier),
               let image = ImagesClubEnCache.image(fichier: url) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let poisson = poissons.first(where: { $0.id == club.poissonId }) {
                // Maquette : poisson de 30 x 18 dans une pastille de 36.
                Image(poisson.image).resizable().scaledToFit().frame(width: taille * 30 / 36, height: taille * 18 / 36)
            } else {
                Image(systemName: "person.3.fill").foregroundStyle(Palette.marine)
            }
        }
        .frame(width: taille, height: taille)
        .background(Palette.tuile)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

// MARK: - Briques communes des écrans Club

/// Le titre d'un groupe : petites capitales discrètes au-dessus de la carte blanche (« MES CLUBS »).
struct EnteteGroupeClub: View {
    let titre: String
    /// Espace au-dessus du titre : 22 pt dans la maquette ; 4 sous le grand titre, 12 sur un écran de formulaire.
    var haut: CGFloat = 22

    var body: some View {
        Text(titre.uppercased())
            .font(Police.legende)
            .foregroundStyle(Palette.encreDouce)
            .tracking(0.5)
            .padding(.horizontal, Espace.l)
            .padding(.top, haut)
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
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }
}

/// Le filet entre deux lignes, aligné sur le texte.
struct FiletClub: View {
    var retrait: CGFloat = Espace.l

    var body: some View {
        Rectangle().fill(Palette.filet).frame(height: 0.5).padding(.leading, retrait)
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
            .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// P30 : créer un club. Nom, image (un poisson ou une photo de la galerie), collections pour les amis invités seulement.
/// Présenté plein écran (maquette B · Réglages) : « Annuler », titre au centre, bouton « Créer le club » en bas.
struct CreerClubView: View {
    let poissons: [PoissonClub]
    /// L22 : vrai quand le club sera créé EN LIGNE (profil fini et iCloud). Le texte dit alors qui voit le club, sans promettre « amis seulement ».
    var enLigne = false
    let valider: (_ nom: String, _ poissonId: String?, _ photo: Data?) -> Void

    @Environment(\.dismiss) private var fermer
    @State private var nom = ""
    @FocusState private var champNomActif: Bool
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
            VStack(spacing: 0) {
                barre
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        EnteteGroupeClub(titre: "Nom", haut: 12)
                        GroupeClub {
                            TextField("Nom du club", text: $nom)
                                .font(Police.corps)
                                .foregroundStyle(Palette.encre)
                                .focused($champNomActif)
                                .submitLabel(.done)
                                .frame(minHeight: 56)
                                .padding(.horizontal, Espace.l)
                                // Toute la rangée de 56 pt donne le focus : le champ seul ne mesure qu'une ligne de texte.
                                .contentShape(Rectangle())
                                .onTapGesture { champNomActif = true }
                        }
                        EnteteGroupeClub(titre: "Image")
                        GroupeClub { grille.padding(Espace.m) }
                        EnteteGroupeClub(titre: enLigne ? "Qui voit le club" : "Qui voit les collections")
                        GroupeClub {
                            HStack(spacing: Espace.m) {
                                Image(systemName: enLigne ? "link" : "lock.fill")
                                    .font(Police.taille(18)).foregroundStyle(Palette.marine)
                                Text(enLigne ? "Ceux qui ont le lien" : "Amis invités seulement")
                                    .font(Police.corps).foregroundStyle(Palette.encre)
                                Spacer(minLength: Espace.s)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(Police.taille(22)).foregroundStyle(Palette.marine)
                            }
                            .accessibilityElement(children: .combine)
                            .allowsHitTesting(false)
                            .frame(minHeight: 56)
                            .padding(.horizontal, Espace.l)
                        }
                        Text(enLigne
                             ? "Pas d'annuaire : seul le lien ouvre le club. Quiconque a le lien voit son nom, son image et les cartes partagées. Ton coin exact ne part jamais."
                             : "Jamais en public. Seuls les amis que tu invites voient tes cartes. Le club reste sur cet iPhone.")
                            .font(Police.legende).foregroundStyle(Palette.encreDouce)
                            .padding(.horizontal, Espace.l).padding(.top, Espace.s)
                    }
                    .padding(.horizontal, Espace.bord)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Palette.fond.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                Button("Créer le club") {
                    valider(nom, poissonChoisi, photo)
                    fermer()
                }
                .buttonStyle(.principal)
                .disabled(!peutCreer)
                .opacity(peutCreer ? 1 : 0.5)
                .padding(.horizontal, Espace.bord)
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

    /// « Annuler », « Nouveau club » au centre, rien à droite : 44 pt sous la barre d'état (maquette : 103 pt avec elle).
    private var barre: some View {
        HStack(spacing: 0) {
            Button("Annuler") { fermer() }
                .font(Police.corps)
                .foregroundStyle(Palette.marine)
                .frame(minWidth: 90, minHeight: Gabarit.zoneTactile, alignment: .leading)
            Spacer(minLength: 0)
            Text("Nouveau club").font(Police.sousTitre).foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Color.clear.frame(width: 90, height: 1)
        }
        .padding(.horizontal, Espace.bord)
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
                    Image(poisson.image).resizable().scaledToFit()
                        .frame(width: 96 * 0.82, height: 40)
                        .frame(width: 96, height: 96)
                        .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                        .overlay(selection(poissonChoisi == poisson.id && photo == nil, rayon: Rayon.s))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(poisson.nom)
            }
        }
    }

    private var tuileGalerie: some View {
        ZStack(alignment: .bottom) {
            if let photo, let image = ImagesClubEnCache.image(photo) {
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: 96, height: 96).clipped()
            } else {
                Palette.tuile
                Image(systemName: "photo.on.rectangle").font(Police.titre).foregroundStyle(Palette.marine)
                    .frame(maxHeight: .infinity)
            }
            HStack(spacing: 4) {
                Image(systemName: "photo").font(Police.taille(12))
                Text("Galerie")
            }
            .font(Police.legende).foregroundStyle(Palette.surMarine)
            .frame(maxWidth: .infinity, minHeight: 24, maxHeight: 24)
            .background(Palette.marine)
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .overlay(selection(photo != nil, rayon: Rayon.m))
    }

    /// Le contour marine (2,5 pt) et la coche blanche de 24 pt d'une tuile choisie.
    @ViewBuilder
    private func selection(_ actif: Bool, rayon: CGFloat) -> some View {
        if actif {
            ZStack {
                RoundedRectangle(cornerRadius: rayon, style: .continuous).strokeBorder(Palette.marine, lineWidth: 2.5)
                Image(systemName: "checkmark.circle.fill")
                    .font(Police.taille(24))
                    .foregroundStyle(Palette.marine, Palette.surMarine)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(4)
            }
        }
    }
}

/// P31 : inviter. Le lien, la liste des invités et l'envoi viennent du partage CloudKit du lot Amis ;
/// tant que RootView ne les passe pas, les blocs correspondants restent vides ou masqués.
/// Poussé dans la pile du Club : barre de 44 pt (retour marine, « Inviter » au centre), bouton en bas.
struct InviterClubView: View {
    let club: ClubLocal
    /// À brancher : adresse courte du club (partage CloudKit). Sans elle, la ligne « Lien d'invitation » montre l'attente.
    var lienTexte: String? = nil
    /// À brancher : `Ami.enAttente` et `Ami.jeVoisSaCollection` du lot Amis.
    var invites: [InviteClub] = []
    /// À brancher : le partage CloudKit en lecture seule, réservé aux personnes invitées.
    var invitation: InvitationPescedex? = nil
    /// L22 : le lien `fishme://club/<id>` d'un club EN LIGNE. S'il est là, il remplace l'invitation d'amis du lot Amis.
    var lienClub: URL? = nil

    @Environment(\.dismiss) private var fermer

    var body: some View {
        VStack(spacing: 0) {
            barre
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    EnteteGroupeClub(titre: "Lien d'invitation", haut: 12)
                    if let lienTexte = lienClub?.absoluteString ?? lienTexte {
                        GroupeClub {
                            HStack(spacing: Espace.m) {
                                Text(lienTexte)
                                    .font(Police.taille(15, .medium).monospaced())
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
                    } else {
                        GroupeClub {
                            HStack(spacing: Espace.m) {
                                ProgressView()
                                Text("Prépare ton invitation…").font(Police.corps).foregroundStyle(Palette.encreDouce)
                                Spacer()
                            }
                            .frame(minHeight: 56)
                            .padding(.horizontal, Espace.l)
                        }
                    }
                    if lienClub == nil { EnteteGroupeClub(titre: "Invitations") }
                    if lienClub != nil {
                        EmptyView()
                    } else if invites.isEmpty {
                        GroupeClub {
                            HStack(spacing: Espace.m) {
                                Image(systemName: "person.crop.circle.badge.questionmark").foregroundStyle(Palette.silhouette)
                                Text("Personne n'est invité").font(Police.corps).foregroundStyle(Palette.encreDouce)
                                Spacer()
                            }
                            .frame(minHeight: 56)
                            .padding(.horizontal, Espace.l)
                        }
                    } else {
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
                    Text(lienClub != nil
                         ? "Quiconque reçoit ce lien peut rejoindre le club et voir ses cartes. Ton coin exact ne quitte jamais ton iPhone."
                         : "Ton coin exact ne quitte jamais ton iPhone. Les amis invités voient tes cartes, personne d'autre.")
                        .font(Police.legende).foregroundStyle(Palette.encreDouce)
                        .padding(.horizontal, Espace.l).padding(.top, 10)
                }
                .padding(.horizontal, Espace.bord)
            }
            .scrollIndicators(.hidden)
        }
        .background(Palette.fond.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Group {
                if let lienClub {
                    ShareLink(item: lienClub, preview: SharePreview(club.nom)) {
                        Label("Envoyer le lien du club", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.principal)
                } else if let invitation {
                    ShareLink(item: invitation, preview: SharePreview(club.nom)) {
                        Label("Envoyer l'invitation", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.principal)
                } else {
                    VStack(spacing: Espace.s) {
                        Text(CloudKitPermis.actif ? "Connecte-toi à iCloud pour inviter tes amis" : "L'invitation d'amis arrive bientôt")
                            .font(Police.corps).foregroundStyle(Palette.encreDouce)
                            .multilineTextAlignment(.center)
                        if CloudKitPermis.actif {
                            Button("Ouvrir les réglages") {
                                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                            }
                            .buttonStyle(.secondaire)
                        }
                    }
                }
            }
            .padding(.horizontal, Espace.bord)
        }
    }

    /// Retour : le rond de verre du design système, « Inviter » au centre, 44 pt vides à droite.
    private var barre: some View {
        HStack(spacing: 0) {
            BoutonRond(role: .retour) { fermer() }
            Spacer(minLength: 0)
            Text("Inviter").font(Police.sousTitre).foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Color.clear.frame(width: Gabarit.zoneTactile, height: 1)
        }
        .padding(.horizontal, Espace.bord)
    }
}
