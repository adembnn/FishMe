import SwiftUI
import UIKit

/// La feuille ouverte par un lien `fishme://club/<id>` : nom, image, nombre de membres, « Rejoindre ».
/// Une seule feuille, une seule action. Sans iCloud ou sans profil, elle le dit et ne fait rien d'autre.
struct RejoindreClubView: View {
    let clubID: String
    let gestion: GestionClubs
    var poissons: [PoissonClub] = []
    /// Appelé quand je suis membre (je viens de rejoindre, ou je l'étais déjà) : la page choisit ce club.
    var ouvert: (String) -> Void = { _ in }

    @Environment(\.dismiss) private var fermer
    @State private var etat: Etat = .chargement

    enum Etat {
        case chargement
        case pret(ApercuClub)
        case dejaMembre(ApercuClub)
        case refus(ErreurClub)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Espace.l) {
                switch etat {
                case .chargement:
                    ProgressView().padding(.top, Espace.xxl)
                    Text("Je cherche le club…").font(Police.corps).foregroundStyle(Palette.encreDouce)
                case .pret(let apercu):
                    entete(apercu)
                    Button {
                        Task { await rejoindre(apercu) }
                    } label: {
                        Text("Rejoindre")
                    }
                    .buttonStyle(.principal)
                    .disabled(gestion.enCours)
                    .accessibilityIdentifier("club.rejoindre")
                    if let texte = gestion.message?.texte {
                        Text(texte).font(Police.legende).foregroundStyle(Palette.alerte).multilineTextAlignment(.center)
                    }
                    Text("Les membres voient ton surnom et ton avatar, et les cartes que tu partages. Ton coin exact ne part jamais.")
                        .font(Police.legende).foregroundStyle(Palette.encreDouce).multilineTextAlignment(.center)
                case .dejaMembre(let apercu):
                    entete(apercu)
                    Text("Tu es déjà dans ce club.").font(Police.corps).foregroundStyle(Palette.encreDouce)
                    Button("Ouvrir le club") {
                        ouvert(apercu.club.id)
                        fermer()
                    }
                    .buttonStyle(.principal)
                case .refus(let erreur):
                    refus(erreur)
                }
                Button("Fermer") { fermer() }
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .task { await charger() }
    }

    private func entete(_ apercu: ApercuClub) -> some View {
        VStack(spacing: Espace.m) {
            if let local = ClubLocal(enLigne: apercu.club) {
                VignetteClub(club: local, poissons: poissons, taille: 96)
            }
            Text(apercu.club.nom).font(Police.titre).foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
            Text(apercu.nombreDeMembres == 1 ? "1 membre" : "\(apercu.nombreDeMembres) membres")
                .font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func refus(_ erreur: ErreurClub) -> some View {
        Image(systemName: erreur == .iCloudIndisponible ? "icloud.slash" : "person.crop.circle.badge.questionmark")
            .font(Police.taille(40)).foregroundStyle(Palette.marine).padding(.top, Espace.xl)
            .accessibilityHidden(true)
        Text(GestionClubs.messageDe(erreur).texte)
            .font(Police.corps).foregroundStyle(Palette.encre).multilineTextAlignment(.center)
        if erreur == .iCloudIndisponible {
            Button("Ouvrir les réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .buttonStyle(.secondaire)
        }
    }

    private func charger() async {
        switch await gestion.apercu(clubID: clubID) {
        case .success(let apercu): etat = apercu.dejaMembre ? .dejaMembre(apercu) : .pret(apercu)
        case .failure(let erreur): etat = .refus(erreur)
        }
    }

    private func rejoindre(_ apercu: ApercuClub) async {
        if await gestion.rejoindre(clubID: apercu.club.id) {
            ouvert(apercu.club.id)
            fermer()
        }
    }
}

/// « Rejoindre un nouveau club » : coller le lien reçu (un lien `fishme://` n'est pas toujours cliquable dans une messagerie).
struct CollerLienClubView: View {
    @Environment(\.dismiss) private var fermer
    @State private var texte = ""
    @State private var invalide = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.m) {
                    Text("Colle le lien du club que tu as reçu.")
                        .font(Police.corps).foregroundStyle(Palette.encre)
                    TextField("fishme://club/…", text: $texte)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .font(Police.corps)
                        .frame(minHeight: 56)
                        .padding(.horizontal, Espace.l)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                    Button {
                        if let coller = UIPasteboard.general.string { texte = coller }
                    } label: {
                        Label("Coller", systemImage: "doc.on.clipboard")
                    }
                    .buttonStyle(.secondaire)
                    if invalide {
                        Text("Ce lien n'est pas celui d'un club FishMe.")
                            .font(Police.legende).foregroundStyle(Palette.alerte)
                    }
                    Button("Continuer") {
                        if let id = LienClub.clubID(depuis: texte) {
                            RelaisLienClub.partage.recevoir(LienClub.url(clubID: id) ?? URL(fileURLWithPath: "/"))
                            fermer()
                        } else {
                            invalide = true
                        }
                    }
                    .buttonStyle(.principal)
                    .disabled(texte.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, Espace.bord)
                .padding(.vertical, Espace.l)
            }
            .scrollIndicators(.hidden)
            .background(Palette.fond.ignoresSafeArea())
            .navigationTitle("Rejoindre avec un lien")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fermer") { fermer() } }
            }
        }
        .tint(Palette.marine)
    }
}

#if DEBUG
#Preview("Rejoindre, chargement") {
    RejoindreClubView(clubID: UUID().uuidString,
                      gestion: GestionClubs(service: FauxServiceClubs(), profils: FauxServiceProfil(),
                                            cache: CacheClubsMemoire()))
}

#Preview("Coller un lien") {
    CollerLienClubView()
}
#endif
