import SwiftUI

/// Le haut de la page Amis : mon profil (ou « Créer mon profil »), la recherche par surnom, et le profil ouvert par un lien `fishme://ami/<id>`.
struct SectionProfilAmis: View {
    let gestion: GestionAmis
    let profil: GestionProfil

    @State private var recherche: RechercheProfils
    @State private var ouvert: ProfilModele?
    @State private var reglages = false
    @State private var creation = false
    /// Le lien reçu n'a pas pu s'ouvrir (réseau) : il reste en attente, la personne peut réessayer.
    @State private var noteLien: String?
    @State private var lienEnEchec = false
    private let relais = RelaisLienAmi.partage

    init(gestion: GestionAmis, profil: GestionProfil) {
        self.gestion = gestion
        self.profil = profil
        _recherche = State(initialValue: RechercheProfils(service: profil.service, profil: profil))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.l) {
            monProfil
            if let noteLien { noteDuLien(noteLien) }
            RechercheAmisView(recherche: recherche) { ouvert = $0 }
        }
        .task { await profil.charger() }
        .task(id: gestion.amis.map(\.id)) { await gestion.chargerAvatars(avec: profil.service) }
        .task(id: relais.enAttente) { await ouvrirLeLien() }
        .sheet(item: $ouvert) { autre in
            ProfilAutreView(profil: autre, gestion: profil, invitation: invitation,
                            urlSignalement: { Signalement.url(contact: gestion.configuration.contact, profilID: autre.id, motif: $0) },
                            apresBlocage: { bloque in await gestion.bloquerProfil(id: bloque.id) })
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
        } else if profil.aUnProfil {
            // Hors ligne ou lecture en échec : l'iPhone se souvient d'un profil. « Mon profil » reste là, avec la suppression.
            Button { reglages = true } label: {
                HStack(spacing: Espace.m) {
                    AvatarSurnom(surnom: profil.surnomMemorise ?? "?", image: nil)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profil.surnomMemorise ?? "Mon profil").font(Police.corps).foregroundStyle(Palette.encre).lineLimit(2)
                        Text("Mon profil · pas relu pour l'instant").font(Police.detail).foregroundStyle(Palette.encreDouce)
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
        } else {
            VStack(spacing: Espace.s) {
                Button { creation = true } label: {
                    Label("Créer mon profil", systemImage: "person.crop.circle.badge.plus")
                        .font(Police.corps)
                        .frame(maxWidth: .infinity, minHeight: Gabarit.bouton)
                }
                .buttonStyle(.secondaire)
                .accessibilityIdentifier("profil.creer")
                // Après une réinstallation, le profil existe encore en ligne : on le relit au lieu de redire « surnom pris ».
                Button("Retrouver mon profil") { Task { await profil.retrouver() } }
                    .font(Police.detail)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .disabled(profil.enCours)
                    .accessibilityIdentifier("profil.retrouver")
                if profil.message == .profilIntrouvable || profil.message == .horsLigne || profil.message == .iCloudIndisponible {
                    Text(profil.message?.texte ?? "").font(Police.detail).foregroundStyle(Palette.alerte)
                }
            }
        }
    }

    private func noteDuLien(_ texte: String) -> some View {
        HStack(spacing: Espace.m) {
            Text(texte).font(Police.detail).foregroundStyle(Palette.encre)
            Spacer(minLength: Espace.s)
            if lienEnEchec {
                Button("Réessayer") { Task { await ouvrirLeLien() } }
                    .font(Police.detail)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
        }
        .padding(Espace.m)
        .tuileFishMe()
    }

    /// Le même partage que le gros bouton « Inviter un ami » : l'invitation existante de L8.
    private var invitation: InvitationPescedex? {
        guard gestion.compte == .disponible else { return nil }
        let gestion = self.gestion
        return InvitationPescedex(conteneur: gestion.configuration.conteneur) { try await gestion.preparerLePartage() }
    }

    /// Ouvre le profil du lien `fishme://ami/<id>`. Un lien vers MON profil ouvre mes réglages (jamais inviter, signaler, bloquer sur moi).
    /// Une erreur réseau garde le lien en attente (« Réessayer ») : il n'est soldé que quand il a été traité ou qu'il ne mène à rien.
    private func ouvrirLeLien() async {
        guard let id = relais.enAttente else { return }
        noteLien = nil
        lienEnEchec = false
        if id == profil.monID {
            relais.solder()
            reglages = true
            return
        }
        if profil.estCache(id) {
            relais.solder()
            noteLien = "Ce profil est masqué chez toi."
            return
        }
        do {
            if let trouve = try await profil.service.profil(id: id) {
                relais.solder()
                ouvert = trouve
            } else {
                relais.solder()
                noteLien = "Ce profil n'existe plus."
            }
        } catch {
            lienEnEchec = true
            noteLien = "Le lien n'a pas pu s'ouvrir. Vérifie ton réseau."
        }
    }
}
