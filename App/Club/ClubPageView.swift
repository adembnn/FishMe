import Core
import SwiftUI

/// Page « Club » de l'onglet Communauté. On crée un club parce qu'on en a envie (nom, poisson ou photo), puis on y partage ses cartes.
/// De haut en bas : « Créer mon club » et « Rejoindre un nouveau club », puis le club choisi (en-tête, membres,
/// « Partager une carte au club »), les cartes du club et le record.
/// Rien n'est envoyé sur un serveur dans cette version : les cartes que je partage restent sur cet iPhone,
/// et les cartes des autres membres viendront du partage CloudKit (lot Amis).
/// Aucun réglage ici : ils restent derrière la roue crantée.
struct ClubPageView: View {
  /// Mes cartes du Pescedex, déjà rendues : ce sont elles que je peux partager au club.
  let cartes: [CarteAPartager]
  /// Les poissons proposés comme image d'un club (RootView les fabrique depuis le catalogue de Core).
  var poissons: [PoissonClub] = []
  /// À brancher : membres, cartes des membres, record et invitations viennent du partage CloudKit (lot Amis).
  var membres: [MembreClub] = []
  var dernieresCartes: [CarteRecenteClub] = []
  var record: RecordClub?
  var invites: [InviteClub] = []
  var invitation: InvitationPescedex?

  @AppStorage("demo.communaute") private var demo = false
  @State private var clubs = MesClubs()
  @State private var clubChoisi: UUID?
  @State private var creationOuverte = false
  @State private var rechercheOuverte = false
  @State private var partageOuvert = false
  /// Identifiants de mes cartes partagées, par club (gardés sur l'iPhone).
  @State private var partages: [String: Set<String>] = PartagesClub.lire()

  private let colonnes = [GridItem(.flexible(), spacing: Espace.m), GridItem(.flexible(), spacing: Espace.m)]

  init(
    cartes: [CarteAPartager], poissons: [PoissonClub] = [], membres: [MembreClub] = [],
    dernieresCartes: [CarteRecenteClub] = [], record: RecordClub? = nil,
    invites: [InviteClub] = [], invitation: InvitationPescedex? = nil
  ) {
    self.cartes = cartes
    self.poissons = poissons
    self.membres = membres
    self.dernieresCartes = dernieresCartes
    self.record = record
    self.invites = invites
    self.invitation = invitation
  }

  /// Les 2 clubs de la démo (le premier est déjà choisi), puis mes vrais clubs. Les clubs de la démo ne sont jamais écrits dans `MesClubs`.
  private var tousLesClubs: [ClubLocal] {
    demo ? DemoClub.clubs + clubs.clubs : clubs.clubs
  }

  private var club: ClubLocal? {
    tousLesClubs.first { $0.id == clubChoisi } ?? tousLesClubs.first
  }

  private var enDemo: Bool { demo && DemoClub.estDemo(club) }
  private var membresAffiches: [MembreClub] {
    if enDemo, let club { return DemoClub.membres(pour: club) }
    return membres
  }
  private var cartesDesMembres: [CarteRecenteClub] {
    if enDemo, let club { return DemoClub.dernieresCartes(pour: club) }
    return dernieresCartes
  }
  private var recordAffiche: RecordClub? {
    if enDemo, let club { return DemoClub.record(pour: club) }
    return record
  }
  private var mesPartagees: Set<String> {
    guard let club else { return [] }
    return partages[club.id.uuidString] ?? []
  }
  private var mesCartesPartagees: [CarteAPartager] {
    cartes.filter { mesPartagees.contains($0.id) }
  }
  private var nombreDeMembres: Int { membresAffiches.count + 1 }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text("Club")
            .font(Police.grandTitre)
            .foregroundStyle(Palette.encre)
            .padding(.horizontal, Espace.l)
            .accessibilityAddTraits(.isHeader)

          boutonsClub.padding(.top, Espace.m)

          if let club {
            if tousLesClubs.count > 1 { choixDuClub }
            entete(club)
            EnteteGroupeClub(titre: "Membres", haut: Espace.m)
            groupeMembres(club)
            Button {
              partageOuvert = true
            } label: {
              Label("Partager une carte au club", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.principal)
            .padding(.top, Espace.l)
            Text("Visible par les membres de ton club")
              .font(Police.legende).foregroundStyle(Palette.encreDouce)
              .frame(maxWidth: .infinity)
              .padding(.top, Espace.xs)

            EnteteGroupeClub(titre: "Cartes du club")
            cartesDuClub
            EnteteGroupeClub(titre: "Record du club")
            recordDuClub
          } else {
            GroupeClub {
              Text(
                "Crée ton club avec un nom et un poisson ou une photo, puis partage-y tes cartes. Tu peux aussi rejoindre celui d'un ami avec son lien."
              )
              .font(Police.legende).foregroundStyle(Palette.encreDouce)
              .padding(Espace.l)
              .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, Espace.m)
          }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, Espace.xl)
      }
      .scrollIndicators(.hidden)
      .font(Police.corps)
      .foregroundStyle(Palette.encre)
      .tint(Palette.marine)
      .background(Palette.fond.ignoresSafeArea())
      .toolbar(.hidden, for: .navigationBar)
      .sheet(isPresented: $creationOuverte) {
        CreerClubView(poissons: poissons) { nom, poisson, photo in
          clubs.creer(nom: nom, poissonId: poisson, photo: photo)
          clubChoisi = clubs.clubs.last?.id
        }
      }
      .sheet(isPresented: $partageOuvert) {
        if let club {
          PartagerCarteClubView(
            club: club, cartes: cartes, partagees: mesPartagees,
            basculer: { basculer($0, dans: club) })
        }
      }
      .sheet(isPresented: $rechercheOuverte) {
        RechercheClubView(clubs: tousLesClubs, poissons: poissons) { choisi in
          clubChoisi = choisi.id
        } creer: {
          // La feuille de recherche se ferme d'abord, puis celle de création s'ouvre.
          rechercheOuverte = false
          Task {
            try? await Task.sleep(for: .milliseconds(400))
            creationOuverte = true
          }
        }
      }
    }
  }

  private func basculer(_ id: String, dans club: ClubLocal) {
    var ensemble = partages[club.id.uuidString] ?? []
    if ensemble.contains(id) { ensemble.remove(id) } else { ensemble.insert(id) }
    partages[club.id.uuidString] = ensemble
    PartagesClub.ecrire(partages)
  }

  // MARK: En-tête

  private func entete(_ club: ClubLocal) -> some View {
    HStack(spacing: Espace.m) {
      VignetteClub(club: club, poissons: poissons, taille: 64)
      VStack(alignment: .leading, spacing: 2) {
        Text(club.nom).font(Police.titre).foregroundStyle(Palette.encre)
          .lineLimit(2).minimumScaleFactor(0.8)
        Text(nombreDeMembres == 1 ? "1 membre" : "\(nombreDeMembres) membres")
          .font(Police.legende).foregroundStyle(Palette.encreDouce)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, Espace.l)
    .padding(.top, Espace.m)
    .accessibilityElement(children: .combine)
  }

  /// Plusieurs clubs : une rangée de pastilles pour passer de l'un à l'autre.
  private var choixDuClub: some View {
    ScrollView(.horizontal) {
      HStack(spacing: Espace.m) {
        ForEach(tousLesClubs) { c in
          let choisi = c.id == club?.id
          Button {
            clubChoisi = c.id
          } label: {
            VignetteClub(club: c, poissons: poissons, taille: 44)
              .overlay(Circle().strokeBorder(choisi ? Palette.marine : .clear, lineWidth: 3).padding(-3))
          }
          .buttonStyle(.plain)
          .accessibilityLabel(c.nom)
          .accessibilityAddTraits(choisi ? .isSelected : [])
        }
      }
      .padding(.horizontal, Espace.l)
      .padding(.vertical, Espace.s)
    }
    .scrollIndicators(.hidden)
    .padding(.top, Espace.s)
  }

  // MARK: Cartes du club

  private var cartesDuClub: some View {
    Group {
      if mesCartesPartagees.isEmpty && cartesDesMembres.isEmpty {
        tuileVide
      } else {
        LazyVGrid(columns: colonnes, spacing: Espace.l) {
          ForEach(mesCartesPartagees) { carte in
            VStack(spacing: Espace.xs) {
              VignetteMaCarteClub(carte: carte)
              Text("Moi").font(Police.detail).foregroundStyle(Palette.encre)
            }
          }
          ForEach(cartesDesMembres) { carte in
            VStack(spacing: Espace.xs) {
              VignetteCarteClub(
                image: carte.image, nom: carte.espece, niveau: carte.niveau,
                tailleCm: carte.tailleCm, photo: carte.photo)
              Text(carte.membre).font(Police.detail).foregroundStyle(Palette.encre)
                .lineLimit(1).minimumScaleFactor(0.7)
            }
          }
        }
      }
    }
  }

  private var recordDuClub: some View {
    Group {
      if let record = recordAffiche {
        HStack(alignment: .center, spacing: Espace.l) {
          VignetteCarteClub(
            image: record.image, nom: record.titre, niveau: record.niveau,
            tailleCm: record.tailleCm, photo: record.photo
          )
          .frame(width: 130)
          VStack(alignment: .leading, spacing: 2) {
            Text(record.titre).font(Police.corps).foregroundStyle(Palette.encre)
              .lineLimit(3).minimumScaleFactor(0.8)
            Text("\(record.tailleCm) cm").font(Police.titre.monospacedDigit()).foregroundStyle(Palette.marine)
              .lineLimit(1).minimumScaleFactor(0.7)
            Text(record.membre).font(Police.legende).foregroundStyle(Palette.encreDouce)
              .lineLimit(1)
          }
          Spacer(minLength: 0)
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .accessibilityElement(children: .combine)
      } else {
        tuileVide
      }
    }
  }

  private var tuileVide: some View {
    GroupeClub {
      Text("Aucune carte partagée pour l'instant")
        .font(Police.legende).foregroundStyle(Palette.encreDouce)
        .frame(maxWidth: .infinity, minHeight: 52)
        .padding(.horizontal, Espace.l)
    }
  }

  // MARK: Rejoindre ou créer

  /// Tout en haut de la page, sous le titre : bien visibles, avant le club choisi.
  private var boutonsClub: some View {
    VStack(spacing: Espace.s) {
      Button {
        creationOuverte = true
      } label: {
        Label("Créer mon club", systemImage: "plus")
      }
      .buttonStyle(.principal)
      Button {
        rechercheOuverte = true
      } label: {
        Label("Rejoindre un nouveau club", systemImage: "magnifyingglass")
      }
      .buttonStyle(.secondaire)
    }
  }

  // MARK: Membres

  private func groupeMembres(_ club: ClubLocal) -> some View {
    // Au-delà de 2 membres (cas des clubs de la démo), la rangée défile pour garder des pastilles lisibles.
    let large = membresAffiches.count > 2
    return GroupeClub {
      ScrollView(.horizontal) {
        HStack(alignment: .top, spacing: 0) {
          VStack(spacing: 2) {
            PastilleMembre(nom: "Moi", rang: 0)
            Text("Moi").font(Police.detail).foregroundStyle(Palette.encre).lineLimit(1)
            Text(cartes.count == 1 ? "1 carte" : "\(cartes.count) cartes")
              .font(Police.legende).foregroundStyle(Palette.encreDouce).lineLimit(1)
          }
          .frame(minWidth: large ? 76 : 0, maxWidth: large ? 76 : .infinity)
          .accessibilityElement(children: .combine)
          ForEach(Array(membresAffiches.prefix(large ? 6 : 2).enumerated()), id: \.element.id) {
            rang, membre in
            VStack(spacing: 2) {
              PastilleMembre(nom: membre.nom, rang: rang + 1)
              Text(membre.nom).font(Police.detail).foregroundStyle(Palette.encre).lineLimit(1)
              Text(membre.nombreDeCartes.map { $0 == 1 ? "1 carte" : "\($0) cartes" } ?? " ")
                .font(Police.legende).foregroundStyle(Palette.encreDouce).lineLimit(1)
            }
            .frame(minWidth: large ? 76 : 0, maxWidth: large ? 76 : .infinity)
            .accessibilityElement(children: .combine)
          }
          NavigationLink {
            InviterClubView(club: club, invites: invites, invitation: invitation)
          } label: {
            VStack(spacing: 2) {
              Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .frame(width: 36, height: 36)
              Text("Inviter").font(Police.detail)
              Text(" ").font(Police.legende)
            }
            .foregroundStyle(Palette.marine)
            .frame(minWidth: large ? 76 : 0, maxWidth: large ? 76 : .infinity)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Inviter un ami")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
      }
      .scrollIndicators(.hidden)
      .scrollDisabled(!large)
    }
  }
}

/// Mes cartes partagées par club, gardées dans les réglages de l'iPhone (jamais envoyées).
enum PartagesClub {
  private static let cle = "club.cartesPartagees"

  static func lire() -> [String: Set<String>] {
    guard let donnees = UserDefaults.standard.data(forKey: cle),
      let lu = try? JSONDecoder().decode([String: Set<String>].self, from: donnees)
    else { return [:] }
    return lu
  }

  static func ecrire(_ valeur: [String: Set<String>]) {
    if let donnees = try? JSONEncoder().encode(valeur) { UserDefaults.standard.set(donnees, forKey: cle) }
  }
}

/// Feuille « Rejoindre un club » : recherche par nom parmi les clubs connus de cet iPhone.
/// Il n'y a pas d'annuaire en ligne : un club d'un autre pêcheur se rejoint par son lien d'invitation.
struct RechercheClubView: View {
  let clubs: [ClubLocal]
  let poissons: [PoissonClub]
  let choisir: (ClubLocal) -> Void
  let creer: () -> Void

  @Environment(\.dismiss) private var fermer
  @State private var recherche = ""
  @State private var lienOuvert = false

  private var resultats: [ClubLocal] {
    let terme = recherche.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !terme.isEmpty else { return clubs }
    return clubs.filter { $0.nom.localizedStandardContains(terme) }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Espace.m) {
          if resultats.isEmpty {
            VStack(alignment: .leading, spacing: Espace.m) {
              Text("Aucun club trouvé. Demande un lien d'invitation à un membre, ou crée ton club.")
                .font(Police.corps).foregroundStyle(Palette.encreDouce)
              Button {
                creer()
              } label: {
                Label("Créer mon club", systemImage: "plus")
              }
              .buttonStyle(.secondaire)
            }
            .padding(.horizontal, Espace.l)
            .padding(.top, Espace.m)
          } else {
            GroupeClub {
              ForEach(Array(resultats.enumerated()), id: \.element.id) { rang, c in
                if rang > 0 { FiletClub(retrait: Espace.l + 36 + Espace.m) }
                Button {
                  choisir(c)
                  fermer()
                } label: {
                  HStack(spacing: Espace.m) {
                    VignetteClub(club: c, poissons: poissons, taille: 36)
                    Text(c.nom).font(Police.corps).foregroundStyle(Palette.encre)
                    Spacer(minLength: Espace.s)
                    Image(systemName: "chevron.right")
                      .font(Police.legende).foregroundStyle(Palette.silhouette)
                  }
                  .frame(minHeight: 52)
                  .padding(.horizontal, Espace.l)
                  .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(c.nom)
              }
            }
          }
          Button {
            lienOuvert = true
          } label: {
            Label("Rejoindre avec un lien", systemImage: "link")
          }
          .buttonStyle(.secondaire)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, Espace.xl)
      }
      .scrollIndicators(.hidden)
      .font(Police.corps)
      .foregroundStyle(Palette.encre)
      .background(Palette.fond.ignoresSafeArea())
      .navigationTitle("Rejoindre un club")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(
        text: $recherche, placement: .navigationBarDrawer(displayMode: .always),
        prompt: "Nom du club"
      )
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Fermer") { fermer() }
        }
      }
      .alert("Rejoindre avec un lien", isPresented: $lienOuvert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("Touche le lien d'invitation que tu as reçu : FishMe s'ouvre sur le club.")
      }
    }
    .tint(Palette.marine)
    .presentationDetents([.large])
  }
}

#if DEBUG
  #Preview("Club, vide") {
    ClubPageView(cartes: [])
  }

  #Preview("Recherche, sans résultat") {
    RechercheClubView(clubs: [], poissons: [], choisir: { _ in }, creer: {})
  }

  #Preview("Recherche, un club connu") {
    RechercheClubView(
      clubs: [ClubLocal(id: UUID(), nom: "Les brochets du dimanche")],
      poissons: [], choisir: { _ in }, creer: {})
  }
#endif
