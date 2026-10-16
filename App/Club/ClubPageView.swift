import SwiftUI

/// Page « Club » de l'onglet Communauté : mes clubs, le club choisi (membres, dernières cartes, record),
/// un gros bouton pour rejoindre un club et un bouton pour créer le sien.
/// Aucun réglage ici (fédération, carte de pêche, sécurité, sources, confidentialité, abonnement) :
/// ils restent derrière la roue crantée, hors de cette page.
/// Les clubs vivent sur l'iPhone et se partagent par invitation CloudKit : il n'existe pas d'annuaire en ligne.
struct ClubPageView: View {
  /// Les cartes du Pescedex de l'utilisateur (seul leur nombre sert ici, pour la pastille « Moi »).
  let cartes: [CarteAPartager]
  /// Les poissons proposés comme image d'un club (RootView les fabrique depuis le catalogue de Core).
  var poissons: [PoissonClub] = []
  /// À brancher : membres, dernières cartes, record et invitations viennent du partage CloudKit (lot Amis).
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

  /// Mes vrais clubs, plus les 2 clubs d'exemple en mode démo (jamais écrits dans `MesClubs`).
  private var tousLesClubs: [ClubLocal] {
    demo ? clubs.clubs + DemoClub.clubs : clubs.clubs
  }

  private var club: ClubLocal? {
    tousLesClubs.first { $0.id == clubChoisi } ?? tousLesClubs.first
  }

  private var enDemo: Bool { demo && DemoClub.estExemple(club) }
  private var membresAffiches: [MembreClub] {
    if enDemo, let club { return DemoClub.membres(pour: club) }
    return membres
  }
  private var cartesAffichees: [CarteRecenteClub] {
    if enDemo, let club { return DemoClub.dernieresCartes(pour: club) }
    return dernieresCartes
  }
  private var recordAffiche: RecordClub? {
    if enDemo, let club { return DemoClub.record(pour: club) }
    return record
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          Text("Club")
            .font(Police.grandTitre)
            .foregroundStyle(Palette.encre)
            .padding(.horizontal, Espace.l)
            .accessibilityAddTraits(.isHeader)

          if demo {
            BandeauDemoClub().padding(.top, Espace.s)
          }

          VStack(spacing: Espace.s) {
            Button {
              rechercheOuverte = true
            } label: {
              Label("Rejoindre un club", systemImage: "magnifyingglass")
            }
            .buttonStyle(.principal)
            Button {
              creationOuverte = true
            } label: {
              Label("Créer mon club", systemImage: "plus")
            }
            .buttonStyle(.secondaire)
          }
          .padding(.top, Espace.m)

          EnteteGroupeClub(titre: "Mes clubs").padding(.top, Espace.s)
          if tousLesClubs.isEmpty {
            GroupeClub {
              Text(
                "Tu n'as pas encore de club. Rejoins celui d'un ami avec son lien, ou crée le tien."
              )
              .font(Police.legende).foregroundStyle(Palette.encreDouce)
              .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
              .padding(.horizontal, Espace.l)
            }
          } else {
            mesClubs
          }

          if let club {
            EnteteGroupeClub(titre: club.nom)
            groupeMembres(club)
            EnteteGroupeClub(titre: "Dernières cartes")
            if cartesAffichees.isEmpty {
              tuileVide
            } else {
              GroupeClub {
                ForEach(Array(cartesAffichees.enumerated()), id: \.element.id) { rang, carte in
                  if rang > 0 { FiletClub(retrait: 80) }
                  ligneCarte(
                    image: carte.image, titre: carte.membre,
                    detail: "\(carte.espece), \(carte.jour)", taille: carte.tailleCm)
                }
              }
            }
            EnteteGroupeClub(titre: "Record du club")
            if let record = recordAffiche {
              GroupeClub {
                ligneCarte(
                  image: record.image, titre: record.titre, detail: record.membre,
                  taille: record.tailleCm)
              }
            } else {
              tuileVide
            }
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

  // MARK: Mes clubs

  private var mesClubs: some View {
    GroupeClub {
      ForEach(Array(tousLesClubs.enumerated()), id: \.element.id) { rang, c in
        let choisi = c.id == club?.id
        if rang > 0 { FiletClub(retrait: Espace.l + 36 + Espace.m) }
        Button {
          clubChoisi = c.id
        } label: {
          HStack(spacing: Espace.m) {
            VignetteClub(club: c, poissons: poissons, taille: 36)
            VStack(alignment: .leading, spacing: 0) {
              Text(c.nom).font(Police.corps).foregroundStyle(Palette.encre)
              // À brancher : le nombre de membres de chaque club vient du partage CloudKit ; connu seulement pour le club choisi.
              if choisi, !membresAffiches.isEmpty {
                Text(membresAffiches.count == 1 ? "1 membre" : "\(membresAffiches.count) membres")
                  .font(Police.legende).foregroundStyle(Palette.encreDouce)
              }
            }
            Spacer(minLength: Espace.s)
            if choisi {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.marine)
            } else {
              Image(systemName: "chevron.right").font(Police.legende).foregroundStyle(
                Palette.silhouette)
            }
          }
          .frame(minHeight: 52)
          .padding(.horizontal, Espace.l)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(c.nom)
        .accessibilityAddTraits(choisi ? AccessibilityTraits.isSelected : AccessibilityTraits())
      }
    }
  }

  // MARK: Membres

  private func groupeMembres(_ club: ClubLocal) -> some View {
    // Au-delà de 2 membres (cas des clubs d'exemple), la rangée défile pour garder des pastilles lisibles.
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
          ForEach(Array(membresAffiches.prefix(large ? 5 : 2).enumerated()), id: \.element.id) {
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

  // MARK: Cartes

  private var tuileVide: some View {
    GroupeClub {
      Text("Aucune carte partagée pour l'instant")
        .font(Police.legende).foregroundStyle(Palette.encreDouce)
        .frame(maxWidth: .infinity, minHeight: 52)
        .padding(.horizontal, Espace.l)
    }
  }

  private func ligneCarte(image: String, titre: String, detail: String, taille: Int?) -> some View {
    HStack(spacing: Espace.m) {
      VignettePoissonClub(image: image)
      VStack(alignment: .leading, spacing: 0) {
        Text(titre).font(Police.corps).foregroundStyle(Palette.encre)
        Text(detail).font(Police.legende).foregroundStyle(Palette.encreDouce)
      }
      Spacer(minLength: Espace.s)
      if let taille {
        Text("\(taille) cm").font(Police.corps.monospacedDigit()).foregroundStyle(
          Palette.encreDouce)
      }
    }
    .frame(minHeight: 48)
    .padding(.horizontal, Espace.l)
    .padding(.vertical, Espace.xs)
    .accessibilityElement(children: .combine)
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
