import SwiftUI

/// La feuille « Finis ton profil » : surnom, avatar, lien à partager. « Me le rappeler plus tard » ferme sans rien bloquer.
struct FinisTonProfilView: View {
    let gestion: GestionProfil
    @Environment(\.dismiss) private var fermer
    @State private var surnom = ""
    @State private var avatar: Data?
    @State private var aQuinzeAns = false
    @FocusState private var champActif: Bool

    private var refus: Surnom.Refus? { gestion.verifier(surnom: surnom) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                if gestion.profil == nil {
                    saisie
                } else {
                    termine
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .interactiveDismissDisabled(gestion.enCours)
    }

    // MARK: Les trois lignes

    private var saisie: some View {
        VStack(alignment: .leading, spacing: Espace.xl) {
            Text("Finis ton profil")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            VStack(alignment: .leading, spacing: Espace.s) {
                Label("Ton surnom", systemImage: "person.text.rectangle")
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.encre)
                TextField("gros-brochet", text: $surnom)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($champActif)
                    .font(Police.corps)
                    .padding(Espace.m)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                    .accessibilityIdentifier("profil.surnom")
                    .onChange(of: surnom) { _, _ in gestion.effacerMessage() }
                aide
            }
            VStack(alignment: .leading, spacing: Espace.s) {
                Label("Ton avatar", systemImage: "face.smiling")
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.encre)
                ChoixAvatar(surnom: surnom, donnees: $avatar)
                    .frame(maxWidth: .infinity)
            }
            VStack(alignment: .leading, spacing: Espace.s) {
                Label("Tes acolytes", systemImage: "link")
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.encre)
                Text("Le lien se partage dès que ton profil est créé.")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
            }
            Toggle("J'ai 15 ans ou plus", isOn: $aQuinzeAns)
                .font(Police.corps)
                .frame(minHeight: Gabarit.zoneTactile)
                .accessibilityIdentifier("profil.age15")
            Text("Sans cela, pas de profil public : ta collection, les règles et la carte restent là.")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
            VStack(spacing: Espace.m) {
                Button("C'est bon") { Task { await creer() } }
                    .buttonStyle(.principal)
                    .disabled(refus != nil || !aQuinzeAns || gestion.enCours)
                    .accessibilityIdentifier("profil.cestbon")
                Button("Me le rappeler plus tard") { fermer() }
                    .buttonStyle(.secondaire)
                    .accessibilityIdentifier("profil.plustard")
            }
        }
    }

    /// Sous le champ : le refus de la règle, ou le message de CloudKit (surnom pris...), ou la règle en une ligne.
    @ViewBuilder private var aide: some View {
        if let message = gestion.message {
            Text(message.texte)
                .font(Police.detail)
                .foregroundStyle(Palette.alerte)
        } else if !surnom.isEmpty, let refus {
            Text(Surnom.phrase(pour: refus))
                .font(Police.detail)
                .foregroundStyle(Palette.alerte)
        } else {
            Text("3 à 20 caractères : lettres, chiffres, tiret.")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
        }
    }

    private var termine: some View {
        VStack(spacing: Espace.l) {
            if let profil = gestion.profil {
                AvatarSurnom(surnom: profil.surnom, image: profil.avatar, taille: 88)
                Text("Bienvenue, \(profil.surnom)")
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                if let lien = LienAmi.url(profilID: profil.id) {
                    ShareLink(item: lien, message: Text("Retrouve-moi sur FishMe : \(profil.surnom)")) {
                        Label("Partager le lien à mes acolytes", systemImage: "square.and.arrow.up")
                            .font(Police.corps)
                            .frame(maxWidth: .infinity, minHeight: Gabarit.bouton)
                    }
                    .buttonStyle(.principal)
                    .accessibilityIdentifier("profil.partager")
                }
            }
            Button("Terminé") { fermer() }
                .buttonStyle(.secondaire)
        }
        .frame(maxWidth: .infinity)
    }

    private func creer() async {
        champActif = false
        await gestion.creer(surnom: surnom, avatar: avatar, aQuinzeAns: aQuinzeAns)
    }
}

/// À poser sur la page Communauté (A, dans `RootView.swift`) : la feuille s'ouvre au premier passage si le profil n'existe pas,
/// puis seulement 7 jours après « Me le rappeler plus tard ». L'onglet reste utilisable dans tous les cas.
struct PresenterFinisTonProfil: ViewModifier {
    let gestion: GestionProfil
    @State private var affichee = false
    @AppStorage(RappelProfil.cle) private var prochain: Double = 0

    func body(content: Content) -> some View {
        content
            .task {
                await gestion.charger()
                if RappelProfil.doitAfficher(prochain: prochain, profilExiste: gestion.aUnProfil, maintenant: Date()) {
                    RappelProfil.reporter()
                    affichee = true
                }
            }
            .sheet(isPresented: $affichee) {
                FinisTonProfilView(gestion: gestion)
            }
    }
}

extension View {
    /// `CommunauteView { ... }.finisTonProfil()`
    func finisTonProfil(gestion: GestionProfil = .partage) -> some View {
        modifier(PresenterFinisTonProfil(gestion: gestion))
    }
}

#if DEBUG
#Preview("Finis ton profil") {
    FinisTonProfilView(gestion: GestionProfil(service: FauxServiceProfil()))
}
#endif
