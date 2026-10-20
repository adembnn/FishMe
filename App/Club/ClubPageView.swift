import Core
import SwiftUI
import UIKit

/// Page « Club » de l'onglet Communauté. On crée un club parce qu'on en a envie (nom, poisson ou photo), puis on y partage ses cartes.
/// De haut en bas : « Créer mon club » et « Rejoindre un nouveau club », puis le club choisi (en-tête, membres,
/// « Partager une carte au club »), les cartes du club et le record.
/// L22 : un club créé avec un profil fini et iCloud est EN LIGNE (CloudKit, base publique) : ses membres entrent par le lien
/// `fishme://club/<id>`, les cartes partagées sont lues chez tous les membres. Sans profil ou sans iCloud, le club reste sur cet iPhone
/// (la page le dit). Les clubs de la démo (`DemoClub`) ne sont jamais écrits en ligne.
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
  /// L24 : le chat. Absent : pas de bouton « Écrire ». Donné par RootView (`app.chat`).
  var chat: GestionChat?
  @State private var conversation: ConversationID?

  @AppStorage(DemoClub.cle) private var demo = false
  @State private var gestion: GestionClubs
  @State private var migration: MigrationClubs
  @State private var lienOuvert: LienAOuvrir?
  @State private var migrationOuverte = false
  @State private var quitterDemande = false
  @State private var carteASignaler: CartePartageeClub?
  @Environment(\.openURL) private var ouvrirURL
  private let relais = RelaisLienClub.partage
  @State private var clubs = MesClubs()
  @State private var clubChoisi: UUID?
  @State private var creationOuverte = false
  @State private var rechercheOuverte = false
  @State private var partageOuvert = false
  /// La carte ouverte en grand dans `VisionneuseCarte`.
  @State private var carteOuverte: CarteOuverteClub?
  /// Identifiants de mes cartes partagées, par club (gardés sur l'iPhone).
  @State private var partages: [String: Set<String>] = PartagesClub.lire()

  private let colonnes = [GridItem(.flexible(), spacing: Espace.m), GridItem(.flexible(), spacing: Espace.m)]

  init(
    cartes: [CarteAPartager], poissons: [PoissonClub] = [], membres: [MembreClub] = [],
    dernieresCartes: [CarteRecenteClub] = [], record: RecordClub? = nil,
    invites: [InviteClub] = [], invitation: InvitationPescedex? = nil,
    gestion: GestionClubs = .partage, chat: GestionChat? = nil
  ) {
    self.chat = chat
    _gestion = State(initialValue: gestion)
    _migration = State(initialValue: MigrationClubs(service: gestion.service))
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
    let enLigne = gestion.clubs.compactMap { ClubLocal(enLigne: $0) }
    let ids = Set(enLigne.map(\.id))
    // Un club local déjà migré (même UUID) n'apparaît qu'une fois : en ligne.
    let locaux = clubs.clubs.filter { !ids.contains($0.id) }
    return (demo ? DemoClub.clubs : []) + enLigne + locaux
  }

  /// Le club choisi tel qu'il est en ligne, ou `nil` (club local, club de démo).
  private var clubEnLigne: Club? {
    guard let club, !DemoClub.estDemo(club) else { return nil }
    return gestion.club(id: club.id.uuidString)
  }

  private var peutCreerEnLigne: Bool { gestion.aUnProfil && gestion.icloud && CloudKitPermis.actif }

  private var club: ClubLocal? {
    tousLesClubs.first { $0.id == clubChoisi } ?? tousLesClubs.first
  }

  private var enDemo: Bool { demo && DemoClub.estDemo(club) }
  private var membresAffiches: [MembreClub] {
    if enDemo, let club { return DemoClub.membres(pour: club) }
    if let enLigne = clubEnLigne {
      let visibles = gestion.cartesVisibles(de: enLigne)
      return gestion.membresVisibles(de: enLigne).filter { $0.profil != gestion.monID }.map { membre in
        MembreClub(
          id: membre.profil, nom: gestion.surnom(de: membre.profil),
          nombreDeCartes: visibles.filter { $0.auteur == membre.profil }.count,
          avatar: gestion.avatar(de: membre.profil))
      }
    }
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
  /// Nombre de mes cartes pour la pastille « Moi » : en ligne, celles du club ; sinon toute ma collection comme avant.
  private var nombreDeMesCartes: Int {
    if let enLigne = clubEnLigne { return gestion.mesCartesPartagees(dans: enLigne).count }
    return cartes.count
  }
  private var mesPartagees: Set<String> {
    guard let club else { return [] }
    if let enLigne = clubEnLigne { return gestion.mesCartesPartagees(dans: enLigne) }
    return partages[club.id.uuidString] ?? []
  }
  private var mesCartesPartagees: [CarteAPartager] {
    cartes.filter { mesPartagees.contains($0.id) }
  }
  /// Dans le club de démo de l'ESSEC, l'utilisateur est l'un des membres listés : on ne l'ajoute pas une seconde fois.
  private var moiDansLaListe: Bool { enDemo && DemoClub.utilisateurEstMembre(club) }
  private var nombreDeMembres: Int { membresAffiches.count + (moiDansLaListe ? 0 : 1) }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          boutonsClub.padding(.top, Espace.s)
          bandeau

          if let club {
            if tousLesClubs.count > 1 { choixDuClub }
            entete(club)
            EnteteGroupeClub(titre: "Membres", haut: Espace.m)
            groupeMembres(club)
            if let enLigne = clubEnLigne { lienMembres(enLigne) }
            if let enLigne = clubEnLigne, chat != nil {
              BoutonEcrire { conversation = .club(enLigne.id) }
                .accessibilityIdentifier("club.ecrire")
            }
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
            if let enLigne = clubEnLigne { boutonQuitter(enLigne) }
          } else {
            GroupeClub {
              Text(
                peutCreerEnLigne
                  ? "Crée ton club avec un nom et un poisson ou une photo, puis invite tes amis avec un lien. Ils verront les cartes que tu y mets."
                  : "Crée ton club avec un nom et un poisson ou une photo, puis choisis les cartes à y mettre. Ton club reste sur ton iPhone tant que ton profil n'est pas fini et qu'iCloud n'est pas là."
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
      .fullScreenCover(item: $carteOuverte) { ouverte in
        VisionneuseCarte(
          nomEspece: ouverte.nomEspece, imageEspece: ouverte.imageEspece,
          tailleCm: ouverte.tailleCm, niveau: ouverte.niveau, photo: ouverte.photo,
          detail: ouverte.detail
        ) { carteOuverte = nil }
      }
      .sheet(isPresented: $creationOuverte) {
        CreerClubView(poissons: poissons, enLigne: peutCreerEnLigne) { nom, poisson, photo in
          if peutCreerEnLigne {
            Task {
              if let cree = await gestion.creer(nom: nom, poissonId: poisson, photo: photo) {
                clubChoisi = UUID(uuidString: cree.id)
              }
            }
          } else {
            clubs.creer(nom: nom, poissonId: poisson, photo: photo)
            clubChoisi = clubs.clubs.last?.id
          }
        }
      }
      .sheet(isPresented: $partageOuvert) {
        if let club {
          PartagerCarteClubView(
            club: club, cartes: cartes, partagees: mesPartagees, enLigne: clubEnLigne != nil,
            basculer: { id in
              if let enLigne = clubEnLigne, let carte = cartes.first(where: { $0.id == id }) {
                Task { await gestion.basculer(carte, dans: enLigne) }
              } else {
                basculer(id, dans: club)
              }
            })
        }
      }
      .sheet(item: $conversation) { ouverte in
        if let chat { FeuilleConversationView(gestion: chat, conversation: ouverte) }
      }
      .sheet(item: $lienOuvert) { lien in
        RejoindreClubView(clubID: lien.id, gestion: gestion, poissons: poissons) { id in
          clubChoisi = UUID(uuidString: id)
        }
      }
      .sheet(isPresented: $migrationOuverte) {
        MigrationClubsView(migration: migration, cartes: cartes, poissons: poissons)
      }
      .sheet(item: $carteASignaler) { carte in
        SignalerCarteClubView(carte: carte) { motif in
          Task {
            if let url = await gestion.signaler(carte, motif: motif) { ouvrirURL(url) }
          }
        }
      }
      .task { await suivre() }
      .onChange(of: relais.enAttente) { _, _ in Task { await traiterLien() } }
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
          .lineLimit(2)
        Text(nombreDeMembres == 1 ? "1 membre" : "\(nombreDeMembres) membres")
          .font(Police.legende).foregroundStyle(Palette.encreDouce)
        if DemoClub.estDemo(club) { PastilleDemo() }
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
      if let enLigne = clubEnLigne {
        cartesEnLigne(enLigne)
      } else if mesCartesPartagees.isEmpty && cartesDesMembres.isEmpty {
        tuileVide
      } else {
        LazyVGrid(columns: colonnes, spacing: Espace.l) {
          ForEach(mesCartesPartagees) { carte in
            VStack(spacing: Espace.xs) {
              VignetteMaCarteClub(carte: carte)
              Text(moiDansLaListe ? "Titouan" : "Moi").font(Police.detail).foregroundStyle(Palette.encre)
            }
          }
          ForEach(cartesDesMembres) { carte in
            VStack(spacing: Espace.xs) {
              Button {
                carteOuverte = CarteOuverteClub(
                  id: carte.id, nomEspece: carte.espece, imageEspece: carte.image,
                  tailleCm: carte.tailleCm, niveau: carte.niveau,
                  photo: PhotoDemoClub.image(carte.photo), detail: "\(carte.membre) · \(carte.jour)")
              } label: {
                VignetteCarteClub(
                  image: carte.image, nom: carte.espece, niveau: carte.niveau,
                  tailleCm: carte.tailleCm, photo: carte.photo)
              }
              .buttonStyle(.plain)
              .accessibilityHint("Ouvre la carte en grand")
              Text(carte.membre).font(Police.detail).foregroundStyle(Palette.encre)
                .lineLimit(1)
            }
          }
        }
      }
    }
  }

  private var recordDuClub: some View {
    Group {
      if let enLigne = clubEnLigne {
        if let meilleure = gestion.record(de: enLigne) {
          RecordEnLigneClubView(carte: meilleure, auteur: gestion.surnom(de: meilleure.auteur))
        } else {
          tuileVide
        }
      } else if let record = recordAffiche {
        HStack(alignment: .center, spacing: Espace.l) {
          Button {
            carteOuverte = CarteOuverteClub(
              id: "record", nomEspece: record.titre, imageEspece: record.image,
              tailleCm: record.tailleCm, niveau: record.niveau,
              photo: PhotoDemoClub.image(record.photo), detail: "\(record.membre) · record du club")
          } label: {
            VignetteCarteClub(
              image: record.image, nom: record.titre, niveau: record.niveau,
              tailleCm: record.tailleCm, photo: record.photo
            )
          }
          .buttonStyle(.plain)
          .accessibilityHint("Ouvre la carte en grand")
          .frame(width: 130)
          VStack(alignment: .leading, spacing: 2) {
            Text(record.titre).font(Police.corps).foregroundStyle(Palette.encre)
              .lineLimit(3)
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

  /// Les cartes du club lues depuis CloudKit (les miennes et celles des autres), sans celles que j'ai signalées ou dont j'ai bloqué l'auteur.
  @ViewBuilder
  private func cartesEnLigne(_ enLigne: Club) -> some View {
    let visibles = gestion.cartesVisibles(de: enLigne)
    if visibles.isEmpty {
      tuileVide
    } else {
      LazyVGrid(columns: colonnes, spacing: Espace.l) {
        ForEach(visibles) { carte in
          CarteEnLigneClubView(
            carte: carte, auteur: gestion.surnom(de: carte.auteur), estMoi: carte.auteur == gestion.monID,
            signaler: { carteASignaler = carte },
            bloquer: { gestion.bloquer(carte.auteur) },
            retirer: { Task { await gestion.retirerCarte(carteID: carte.carteID, de: enLigne) } })
        }
      }
    }
  }

  // MARK: État du club en ligne

  /// Une ligne d'état sous les boutons : hors ligne (dernier état lu), message d'erreur, club local, club sans fondateur.
  @ViewBuilder
  private var bandeau: some View {
    if let texte = texteBandeau {
      Text(texte)
        .font(Police.legende).foregroundStyle(Palette.encreDouce)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Espace.l).padding(.top, Espace.s)
        .accessibilityIdentifier("club.bandeau")
    }
  }

  private var texteBandeau: String? {
    if gestion.horsLigne { return "Pas de réseau : tu vois le dernier état lu." }
    if let message = gestion.message, message != .horsLigne { return message.texte }
    if let enLigne = clubEnLigne, gestion.etat(de: enLigne) == .sansFondateur {
      return "Ce club n'a plus de fondateur : on ne peut plus y entrer ni retirer un membre."
    }
    if clubEnLigne == nil, let club, !DemoClub.estDemo(club) {
      if !CloudKitPermis.actif || !gestion.icloud { return "Ce club reste sur cet iPhone : iCloud n'est pas disponible." }
      if !gestion.aUnProfil { return "Ce club reste sur cet iPhone. Finis ton profil pour le mettre en ligne." }
      if !migration.enAttente.isEmpty { return "Ce club est encore sur cet iPhone. Il n'est pas encore en ligne." }
    }
    return nil
  }

  private func lienMembres(_ enLigne: Club) -> some View {
    NavigationLink {
      MembresClubView(club: enLigne, gestion: gestion)
    } label: {
      HStack(spacing: Espace.s) {
        Image(systemName: "person.2")
        Text(gestion.jeSuisFondateur(de: enLigne) ? "Gérer les membres" : "Voir les membres")
        Spacer()
        Image(systemName: "chevron.right")
      }
      .font(Police.legende)
      .foregroundStyle(Palette.encreDouce)
      .frame(minHeight: Gabarit.zoneTactile)
      .padding(.horizontal, Espace.l)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  /// « Quitter le club » : retire mon adhésion ET mes cartes. Fondateur seul : « Fermer le club ».
  private func boutonQuitter(_ enLigne: Club) -> some View {
    let ferme =
      gestion.monID.map {
        RegleAdhesion.sortie(club: enLigne, membres: gestion.membres[enLigne.id] ?? [], profil: $0) == .fermer
      } ?? false
    let fondateur = gestion.jeSuisFondateur(de: enLigne)
    return Button(role: .destructive) {
      quitterDemande = true
    } label: {
      Label(ferme ? "Fermer le club" : "Quitter le club", systemImage: "rectangle.portrait.and.arrow.right")
        .font(Police.corps)
        .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
    }
    .buttonStyle(.secondaire)
    .padding(.top, Espace.xl)
    .confirmationDialog(
      ferme ? "Fermer ce club ?" : "Quitter ce club ?", isPresented: $quitterDemande, titleVisibility: .visible
    ) {
      Button(ferme ? "Fermer le club" : "Quitter", role: .destructive) {
        Task {
          if await gestion.quitter(enLigne) { clubChoisi = nil }
        }
      }
      Button("Annuler", role: .cancel) {}
    } message: {
      Text(
        ferme
          ? "Le club sera fermé et tes cartes partagées disparaîtront."
          : fondateur
            ? "Tes cartes partagées seront retirées du club. Il n'aura plus de fondateur : on ne pourra plus y entrer."
            : "Tes cartes partagées seront retirées du club. Tu gardes, pour l'instant, l'accès à sa conversation.")
    }
  }

  // MARK: Suivi (rafraîchissement, lien reçu, migration)

  /// Tant que la page est à l'écran : relit les clubs toutes les 8 s (le membre qui arrive ou la carte partagée apparaissent en moins de 10 s).
  /// ⚠ Un abonnement CloudKit (`CKQuerySubscription`) ferait mieux avec les notifications de L25 ; ce rafraîchissement est le repli.
  private func suivre() async {
    await gestion.charger()
    await traiterLien()
    if !migration.termine, migration.peutMigrer, gestion.icloud, !migration.enAttente.isEmpty { migrationOuverte = true }
    while !Task.isCancelled {
      try? await Task.sleep(for: .seconds(8))
      if Task.isCancelled { break }
      await gestion.charger()
    }
  }

  /// Un lien `fishme://club/<id>` reçu (ou collé) ouvre la feuille « Rejoindre ».
  private func traiterLien() async {
    guard let id = relais.enAttente else { return }
    relais.solder()
    if rechercheOuverte {
      // La feuille de recherche se ferme d'abord, puis celle du club s'ouvre (comme pour la création).
      rechercheOuverte = false
      try? await Task.sleep(for: .milliseconds(450))
    }
    lienOuvert = LienAOuvrir(id: id)
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
          if !moiDansLaListe {
            VStack(spacing: 2) {
              PastilleMembre(nom: "Moi", rang: 0)
              Text("Moi").font(Police.detail).foregroundStyle(Palette.encre).lineLimit(1)
              Text(nombreDeMesCartes == 1 ? "1 carte" : "\(nombreDeMesCartes) cartes")
                .font(Police.legende).foregroundStyle(Palette.encreDouce).lineLimit(1)
            }
            .frame(minWidth: large ? 76 : 0, maxWidth: large ? 76 : .infinity)
            .accessibilityElement(children: .combine)
          }
          ForEach(Array(membresAffiches.prefix(large ? 6 : 2).enumerated()), id: \.element.id) {
            rang, membre in
            VStack(spacing: 2) {
              if let avatar = membre.avatar {
                AvatarSurnom(surnom: membre.nom, image: avatar, taille: 36)
              } else {
                PastilleMembre(nom: membre.nom, rang: moiDansLaListe ? rang : rang + 1)
              }
              Text(membre.nom).font(Police.detail).foregroundStyle(Palette.encre).lineLimit(1)
              Text(membre.nombreDeCartes.map { $0 == 1 ? "1 carte" : "\($0) cartes" } ?? " ")
                .font(Police.legende).foregroundStyle(Palette.encreDouce).lineLimit(1)
            }
            .frame(minWidth: large ? 76 : 0, maxWidth: large ? 76 : .infinity)
            .accessibilityElement(children: .combine)
          }
          NavigationLink {
            InviterClubView(
              club: club, invites: invites, invitation: invitation,
              lienClub: clubEnLigne.flatMap { LienClub.url(clubID: $0.id) })
          } label: {
            VStack(spacing: 2) {
              Image(systemName: "plus")
                .font(Police.taille(22))
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

/// Un lien de club à ouvrir dans la feuille « Rejoindre ».
struct LienAOuvrir: Identifiable {
  let id: String
}

/// Une carte du club ouverte en grand dans `VisionneuseCarte` (écrite par le lot Collection).
struct CarteOuverteClub: Identifiable {
  let id: String
  let nomEspece: String
  let imageEspece: String
  let tailleCm: Int?
  let niveau: NiveauRarete
  let photo: UIImage?
  let detail: String
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
      .sheet(isPresented: $lienOuvert) {
        CollerLienClubView()
      }
    }
    .tint(Palette.marine)
    .presentationDetents([.large])
  }
}

#if DEBUG
  /// Aperçus : un faux service en mémoire, jamais iCloud.
  @MainActor private func gestionFactice() -> GestionClubs {
    GestionClubs(
      service: FauxServiceClubs(), profils: FauxServiceProfil(), cache: CacheClubsMemoire(),
      blocages: BlocagesProfils(cleBloques: "apercu.bl", cleMasques: "apercu.ma"),
      masquees: CartesMasquees(cle: "apercu.cm"))
  }

  #Preview("Club, vide") {
    ClubPageView(cartes: [], gestion: gestionFactice())
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
