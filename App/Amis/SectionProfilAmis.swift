import SwiftUI

/// Le haut de la page Amis : mon profil (ou « Créer mon profil »), la recherche par surnom, et le profil ouvert par un lien `fishme://ami/<id>`.
struct SectionProfilAmis: View {
    let gestion: GestionAmis
    let profil: GestionProfil

    @State private var recherche: RechercheProfils
    @State private var ouvert: ProfilModele?
    @State private var reglages = false
    @State private var creation = false
    private let relais = RelaisLienAmi.partage

    init(gestion: GestionAmis, profil: GestionProfil) {
        self.gestion = gestion
        self.profil = profil
        _recherche = State(initialValue: RechercheProfils(service: profil.service, profil: profil))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.l) {
            monProfil
            RechercheAmisView(recherche: recherche) { ouvert = $0 }
        }
        .task { await profil.charger() }
        .task(id: gestion.amis.map(\.id)) { await gestion.chargerAvatars(avec: profil.service) }
        .task(id: relais.enAttente) { await ouvrirLeLien() }
        .sheet(item: $ouvert) { autre in
            ProfilAutreView(profil: autre, gestion: profil, invitation: invitation,
                            urlSignalement: { Signalement.url(contact: gestion.configuration.contact, profilID: autre.id, motif: $0) }) { bloque in
                await gestion.bloquerProfil(id: bloque.id)
            }
        }
        .sheet(isPresented: $reglages) { ReglagesProfilView(gestion: profil) }
        .sheet(isPresented: $creation) { FinisTonProfilView(gestion: profil) }
    }

    @ViewBuilder private var monProfil: some View {
        if let moi = profil.profil {
            Button { reglages = true } label: {
                HStack(spacing: Espace.m) {
                    AvatarSurnom(surnom: moi.surnom, image: moi.avatar)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(moi.surnom).font(Police.corps).foregroundStyle(Palette.encre).lineLimit(2)
                        Text("Mon profil").font(Police.detail).foregroundStyle(Palette.encreDouce)
                    }
                    Spacer(minLength: Espace.s)
                    Image(systemName: "chevron.right").foregroundStyle(Palette.encreDouce)
                }
                .frame(minHeight: 60)
                .padding(.horizontal, Espace.l)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .tuileFishMe()
            .accessibilityIdentifier("profil.moi")
        } else if !profil.aUnProfil {
            Button { creation = true } label: {
                Label("Créer mon profil", systemImage: "person.crop.circle.badge.plus")
                    .font(Police.corps)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.bouton)
            }
            .buttonStyle(.secondaire)
            .accessibilityIdentifier("profil.creer")
        }
    }

    /// Le même partage que le gros bouton « Inviter un ami » : l'invitation existante de L8.
    private var invitation: InvitationPescedex? {
        guard gestion.compte == .disponible else { return nil }
        let gestion = self.gestion
        return InvitationPescedex(conteneur: gestion.configuration.conteneur) { try await gestion.preparerLePartage() }
    }

    private func ouvrirLeLien() async {
        guard let id = relais.enAttente else { return }
        defer { relais.solder() }
        guard !profil.estCache(id), let trouve = try? await profil.service.profil(id: id) else { return }
        ouvert = trouve
    }
}
