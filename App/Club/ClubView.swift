import StoreKit
import SwiftUI

/// Volet droit : Club (P29). Mes clubs, les membres du club choisi, ses dernières cartes, son record.
/// Tout y est gratuit ; rien n'y vient d'un autre utilisateur sans invitation. Les réglages d'avant
/// (fédération, sécurité, sources, confidentialité, abonnement) restent à un toucher, tout en bas.
struct ClubView<MarqueMeteo: View>: View {
    let liens: LiensClub
    let sources: [SourceClub]
    let cartes: [CarteAPartager]
    @Binding var mesureUsage: Bool
    let marqueMeteo: MarqueMeteo

    @State private var clubs = MesClubs()
    @State private var creationOuverte = false
    @State private var rejoindreOuvert = false
    @State private var clubChoisi: UUID?
    @State private var inviterOuvert = false
    /// Les poissons proposés comme image d'un club. À brancher : RootView les passe avec `.poissonsDuClub(_:)`.
    var poissons: [PoissonClub] = []
    /// À brancher : membres, dernières cartes, record et invitations viennent du partage CloudKit (lot Amis).
    var membres: [MembreClub] = []
    var dernieresCartes: [CarteRecenteClub] = []
    var record: RecordClub?
    var invites: [InviteClub] = []
    var invitation: InvitationPescedex?
    /// À brancher : l'envoi d'une carte au club choisi (partage CloudKit, lot Amis). Sans lui, « Partager au club » n'apparaît pas.
    var partagerAuClub: ((CarteAPartager) -> Void)?

    func partageAuClub(_ envoi: @escaping (CarteAPartager) -> Void) -> Self {
        var copie = self
        copie.partagerAuClub = envoi
        return copie
    }

    func poissonsDuClub(_ poissons: [PoissonClub]) -> Self {
        var copie = self
        copie.poissons = poissons
        return copie
    }

    /// Branche ce que le partage CloudKit sait du club choisi.
    func contenuDuClub(membres: [MembreClub], dernieresCartes: [CarteRecenteClub], record: RecordClub?,
                       invites: [InviteClub], invitation: InvitationPescedex?) -> Self {
        var copie = self
        copie.membres = membres
        copie.dernieresCartes = dernieresCartes
        copie.record = record
        copie.invites = invites
        copie.invitation = invitation
        return copie
    }

    init(liens: LiensClub, sources: [SourceClub], cartes: [CarteAPartager], mesureUsage: Binding<Bool>,
         @ViewBuilder marqueMeteo: () -> MarqueMeteo) {
        self.liens = liens
        self.sources = sources
        self.cartes = cartes
        _mesureUsage = mesureUsage
        self.marqueMeteo = marqueMeteo()
    }

    private var club: ClubLocal? {
        clubs.clubs.first { $0.id == clubChoisi } ?? clubs.clubs.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Club")
                        .font(Police.grandTitre)
                        .foregroundStyle(Palette.encre)
                        .accessibilityAddTraits(.isHeader)
                    if clubs.clubs.isEmpty {
                        etatSansClub
                    } else {
                        EnteteGroupeClub(titre: "Mes clubs", haut: 4)
                        mesClubs
                    }
                    if let club {
                        EnteteGroupeClub(titre: club.nom)
                        groupeMembres(club)
                        if membres.isEmpty && dernieresCartes.isEmpty && record == nil {
                            etatSansMembres
                        }
                    }
                    if club != nil, !(membres.isEmpty && dernieresCartes.isEmpty && record == nil) {
                        EnteteGroupeClub(titre: "Dernières cartes")
                        if dernieresCartes.isEmpty {
                            tuileVide
                        } else {
                            GroupeClub {
                                ForEach(Array(dernieresCartes.enumerated()), id: \.element.id) { rang, carte in
                                    if rang > 0 { FiletClub(retrait: 84) }
                                    ligneCarte(image: carte.image, titre: carte.membre,
                                               detail: "\(carte.espece), \(carte.jour)", taille: carte.tailleCm)
                                }
                            }
                        }
                        EnteteGroupeClub(titre: "Record du club")
                        if let record {
                            GroupeClub {
                                ligneCarte(image: record.image, titre: record.titre, detail: record.membre,
                                           taille: record.tailleCm)
                            }
                        } else {
                            tuileVide
                        }
                    }
                    NavigationLink {
                        ReglagesClubView(liens: liens, sources: sources, cartes: cartes,
                                         mesureUsage: $mesureUsage, marqueMeteo: marqueMeteo,
                                         partagerAuClub: partagerAuClub)
                    } label: {
                        HStack(spacing: Espace.s) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Ma pêche, sécurité et sources")
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
                    .padding(.top, Espace.l)
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
            .navigationDestination(isPresented: $inviterOuvert) {
                if let club { InviterClubView(club: club, invites: invites, invitation: invitation) }
            }
            .fullScreenCover(isPresented: $creationOuverte) {
                CreerClubView(poissons: poissons) { nom, poisson, photo in
                    clubs.creer(nom: nom, poissonId: poisson, photo: photo)
                    clubChoisi = clubs.clubs.last?.id
                }
            }
            .alert("Rejoindre avec un lien", isPresented: $rejoindreOuvert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Touche le lien d'invitation que tu as reçu : FishMe s'ouvre sur le club.")
            }
        }
    }

    // MARK: États vides (jamais un écran blanc)

    /// Trois poissons de profil, tête à droite, sur des pastilles : l'illustration des deux états vides.
    private var illustrationClub: some View {
        HStack(spacing: -10) {
            ForEach(Array(poissons.prefix(3))) { poisson in
                Image(poisson.image).resizable().scaledToFit()
                    .padding(.horizontal, 12)
                    .frame(width: 84, height: 84)
                    .background(Palette.tuile, in: Circle())
                    .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 3))
                    .accessibilityHidden(true)
            }
            if poissons.isEmpty {
                Image(systemName: "person.3.fill")
                    .font(Police.taille(34))
                    .foregroundStyle(Palette.marine)
                    .frame(width: 84, height: 84)
                    .background(Palette.tuile, in: Circle())
                    .accessibilityHidden(true)
            }
        }
    }

    /// Aucun club : le poisson, une phrase, « Créer un club » (le seul bouton principal) et « Rejoindre avec un lien ».
    private var etatSansClub: some View {
        VStack(alignment: .leading, spacing: 0) {
            EnteteGroupeClub(titre: "Mes clubs", haut: 4)
            GroupeClub {
                VStack(spacing: Espace.m) {
                    illustrationClub.padding(.top, Espace.l)
                    Text("Pêche à plusieurs")
                        .font(Police.titre).foregroundStyle(Palette.encre)
                    Text(CloudKitPermis.actif ? "Crée un club, invite tes amis et regardez vos cartes ensemble." : "Crée ton club. L'invitation d'amis arrive bientôt.")
                        .font(Police.detail).foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Espace.l)
                    Button("Créer un club") { creationOuverte = true }
                        .buttonStyle(.principal)
                        .padding(.horizontal, Espace.l)
                    Button { rejoindreOuvert = true } label: {
                        Label("Rejoindre avec un lien", systemImage: "link")
                            .font(Police.taille(15)).foregroundStyle(Palette.marine)
                            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    }
                    .padding(.bottom, Espace.s)
                }
            }
            EnteteGroupeClub(titre: "Ce que tu verras")
            GroupeClub {
                avantage("person.2.fill", "Les membres et leurs cartes")
                FiletClub(retrait: 56)
                avantage("rectangle.stack.fill", "Les dernières cartes du club")
                FiletClub(retrait: 56)
                avantage("trophy.fill", "Le record du club")
            }
        }
    }

    private func avantage(_ icone: String, _ texte: String) -> some View {
        HStack(spacing: Espace.m) {
            Image(systemName: icone).font(Police.taille(17)).foregroundStyle(Palette.marine)
                .frame(width: 28)
            Text(texte).font(Police.corps).foregroundStyle(Palette.encre)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 52)
        .padding(.horizontal, Espace.l)
        .accessibilityElement(children: .combine)
    }

    /// Un club sans autre membre : une carte pleine avec « Inviter » à la place des deux tuiles vides.
    private var etatSansMembres: some View {
        GroupeClub {
            VStack(spacing: Espace.m) {
                illustrationClub.padding(.top, Espace.l)
                Text("Ton club attend ses premiers membres")
                    .font(Police.sousTitre).foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Espace.l)
                Text("Les cartes partagées et le record du club apparaîtront ici.")
                    .font(Police.legende).foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Espace.l)
                Button("Inviter") { inviterOuvert = true }
                    .buttonStyle(.principal)
                    .padding(.horizontal, Espace.l)
                    .padding(.bottom, Espace.l)
            }
        }
        .padding(.top, Espace.m)
    }

    // MARK: Mes clubs

    private var mesClubs: some View {
        GroupeClub {
            ForEach(clubs.clubs) { c in
                let choisi = c.id == club?.id
                Button { clubChoisi = c.id } label: {
                    HStack(spacing: Espace.m) {
                        VignetteClub(club: c, poissons: poissons, taille: 36)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(c.nom).font(Police.corps).foregroundStyle(Palette.encre)
                            // À brancher : le nombre de membres de chaque club vient du partage CloudKit ; connu seulement pour le club choisi.
                            if choisi, !membres.isEmpty {
                                Text(membres.count == 1 ? "1 membre" : "\(membres.count) membres")
                                    .font(Police.legende).foregroundStyle(Palette.encreDouce)
                            }
                        }
                        Spacer(minLength: Espace.s)
                        if choisi {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.marine)
                        } else {
                            Image(systemName: "chevron.right").font(Police.legende).foregroundStyle(Palette.silhouette)
                        }
                    }
                    .frame(minHeight: 52)
                    .padding(.horizontal, Espace.l)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(c.nom)
                .accessibilityAddTraits(choisi ? AccessibilityTraits.isSelected : AccessibilityTraits())
                FiletClub()
            }
            // Deux boutons de 48 pt, texte de 14 pt, icône de 20 pt, largeurs 1,5 pour 1 (maquette P29).
            HStack(spacing: 0) {
                Button { rejoindreOuvert = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "link").font(Police.taille(17))
                        Text("Rejoindre avec un lien")
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                }
                .containerRelativeFrame(.horizontal) { largeur, _ in (largeur - 2 * Espace.bord - 20 - 1) * 0.6 }
                Rectangle().fill(Palette.filet).frame(width: 1, height: 24)
                Button { creationOuverte = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(Police.taille(17))
                        Text("Créer un club")
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                }
                .containerRelativeFrame(.horizontal) { largeur, _ in (largeur - 2 * Espace.bord - 20 - 1) * 0.4 }
            }
            .font(Police.taille(14))
            .foregroundStyle(Palette.marine)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 10)
        }
    }

    // MARK: Membres

    private func groupeMembres(_ club: ClubLocal) -> some View {
        GroupeClub {
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 2) {
                    PastilleMembre(nom: "Moi", rang: 0)
                    Text("Moi").font(Police.detail).foregroundStyle(Palette.encreDouce).lineLimit(1)
                    Text(cartes.count == 1 ? "1 carte" : "\(cartes.count) cartes")
                        .font(Police.legende).foregroundStyle(Palette.encreDouce).lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                ForEach(Array(membres.prefix(2).enumerated()), id: \.element.id) { rang, membre in
                    VStack(spacing: 2) {
                        PastilleMembre(nom: membre.nom, rang: rang + 1)
                        Text(membre.nom).font(Police.detail).foregroundStyle(Palette.encreDouce).lineLimit(1)
                        Text(membre.nombreDeCartes.map { $0 == 1 ? "1 carte" : "\($0) cartes" } ?? " ")
                            .font(Police.legende).foregroundStyle(Palette.encreDouce).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
                NavigationLink {
                    InviterClubView(club: club, invites: invites, invitation: invitation)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "plus")
                            .font(Police.taille(26))
                            .frame(width: 36, height: 36)
                        Text("Inviter").font(Police.detail).foregroundStyle(Palette.encreDouce)
                        Text(" ").font(Police.legende)
                    }
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Inviter un ami")
            }
            .padding(.vertical, 10)
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
                Text("\(taille) cm").font(Police.corps.monospacedDigit()).foregroundStyle(Palette.encreDouce)
            }
            Image(systemName: "chevron.right").font(Police.taille(13)).foregroundStyle(Palette.silhouette)
        }
        .padding(.horizontal, Espace.l)
        .padding(.vertical, Espace.s)
        .frame(minHeight: 48)
        .accessibilityElement(children: .combine)
    }
}

/// Tout ce que l'écran Club avait avant la maquette P29 : ma fédération, ma carte de pêche, partage d'une carte,
/// sécurité, sources, confidentialité, abonnement. Un seul toucher depuis le bas de l'écran Club.
struct ReglagesClubView<MarqueMeteo: View>: View {
    let liens: LiensClub
    let sources: [SourceClub]
    let cartes: [CarteAPartager]
    @Binding var mesureUsage: Bool
    let marqueMeteo: MarqueMeteo
    var partagerAuClub: ((CarteAPartager) -> Void)?

    @AppStorage("club.cartePeche2026") private var aSaCarte = false
    @State private var gestionAbonnement = false
    @State private var partageOuvert = false

    var body: some View {
        List {
            Section {
                Link(destination: liens.federation ?? LiensOfficiels.federationNationale) {
                    LigneSortie(titre: "Ma fédération", sousTitre: liens.libelleFederation, icone: "building.columns")
                }
                // Sans association connue, pas de ligne : elle ouvrirait la même page que « Cartes de pêche ».
                if let association = liens.association {
                    Link(destination: association) {
                        LigneSortie(titre: "Mon association", sousTitre: nil, icone: "person.3")
                    }
                }
                Toggle(isOn: $aSaCarte) {
                    Label("J'ai ma carte de pêche 2026", systemImage: "checkmark.seal")
                }
                Link(destination: liens.carteDePeche) {
                    LigneSortie(titre: "Cartes de pêche, site officiel", sousTitre: nil, icone: "safari")
                }
            } header: {
                Text("Ma pêche").font(Police.legende)
            }

            Section {
                Button { partageOuvert = true } label: {
                    Label("Partager une carte en image", systemImage: "square.and.arrow.up")
                }
            } header: {
                Text("Partager").font(Police.legende)
            }

            Section {
                NavigationLink {
                    SecuriteView()
                } label: {
                    Label("Sécurité au bord de l'eau", systemImage: "exclamationmark.triangle")
                }
                NavigationLink {
                    SourcesView(sources: sources, marqueMeteo: marqueMeteo)
                } label: {
                    Label("Sources des données", systemImage: "books.vertical")
                }
            }

            Section {
                if let page = liens.confidentialite {
                    Link(destination: page) {
                        LigneSortie(titre: "Politique de confidentialité", sousTitre: nil, icone: "hand.raised")
                    }
                }
                Toggle(isOn: $mesureUsage) {
                    Label("Mesure d'usage", systemImage: "chart.bar")
                }
            } header: {
                Text("Confidentialité").font(Police.legende)
            }

            Section {
                Button {
                    gestionAbonnement = true
                } label: {
                    Label("Mon abonnement", systemImage: "creditcard")
                }
                if let contact = ContactClub.contact {
                    Link(destination: contact) {
                        LigneSortie(titre: "Contact", sousTitre: nil, icone: "envelope")
                    }
                }
                if let erreur = ContactClub.erreurDeRegle {
                    Link(destination: erreur) {
                        LigneSortie(titre: "Signaler une erreur de règle", sousTitre: nil, icone: "flag")
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .font(Police.corps)
        .foregroundStyle(Palette.encre)
        .tint(Palette.marine)
        .scrollContentBackground(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .navigationTitle("Ma pêche")
        .navigationBarTitleDisplayMode(.inline)
        .manageSubscriptionsSheet(isPresented: $gestionAbonnement)
        // P33 est plein écran, avec son rond « Fermer » en haut à gauche.
        .fullScreenCover(isPresented: $partageOuvert) {
            PartageCarteView(cartes: cartes, partagerAuClub: partagerAuClub)
        }
    }
}

/// Une ligne qui ouvre Safari ou Mail : titre, sous-titre facultatif et petite flèche de sortie.
private struct LigneSortie: View {
    let titre: String
    let sousTitre: String?
    let icone: String

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titre)
                    if let sousTitre {
                        Text(sousTitre).font(Police.legende).foregroundStyle(Palette.encreDouce)
                    }
                }
            } icon: {
                Image(systemName: icone)
            }
            Spacer(minLength: 8)
            Image(systemName: "arrow.up.right")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .accessibilityHidden(true)
        }
    }
}

extension ClubView where MarqueMeteo == EmptyView {
    init(liens: LiensClub, sources: [SourceClub], cartes: [CarteAPartager], mesureUsage: Binding<Bool>) {
        self.init(liens: liens, sources: sources, cartes: cartes, mesureUsage: mesureUsage) { EmptyView() }
    }
}

#if DEBUG
#Preview {
    ClubView(
        liens: LiensClub(),
        sources: [SourceClub(nom: "OpenStreetMap", mention: "© contributeurs OpenStreetMap",
                             lien: URL(string: "https://www.openstreetmap.org/copyright"))],
        cartes: [],
        mesureUsage: .constant(true)
    )
}
#endif
