import CloudKit
import Core
import SwiftUI

/// Ce que `ShareLink` envoie : un partage CloudKit préparé à la demande, réservé aux personnes invitées, en lecture seule.
/// `UICloudSharingController(preparationHandler:)` est déprécié : on passe par `CKShareTransferRepresentation`.
nonisolated struct InvitationPescedex: Transferable, Sendable {
    let conteneur: String
    let preparer: @Sendable () async throws -> PartagePret

    static var transferRepresentation: some TransferRepresentation {
        CKShareTransferRepresentation { invitation in
            let options = CKAllowedSharingOptions(allowedParticipantPermissionOptions: .readOnly,
                                                  allowedParticipantAccessOptions: .specifiedRecipientsOnly)
            return .prepareShare(container: CKContainer(identifier: invitation.conteneur), allowedSharingOptions: options) {
                try await invitation.preparer().share
            }
        }
    }
}

/// Le volet Amis (maquette F1) : inviter, accepter, voir qui voit quoi. A le place dans Mon club.
struct AmisView: View {
    @State var gestion: GestionAmis
    @State private var amiOuvert: Ami?
    @State private var confirmerSuppression = false

    var body: some View {
        Group {
            if let ami = amiOuvert {
                PescedexAmiView(gestion: gestion, ami: ami, fermer: { amiOuvert = nil })
            } else {
                liste
            }
        }
        .task { await gestion.actualiser() }
        .task { await gestion.surveillerLeReseau() }
        .task { prendreLInvitation() }
    }

    private var liste: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l + 2) {
                entete
                if let message = texteDuMessage { bandeau(message) }
                if let invitation = gestion.invitationRecue { demande(invitation) }
                if gestion.compte == .disponible { inviter }
                if gestion.proposerInvitationEnRetour { enRetour }
                rangees
                if gestion.partageActif { suppression }
                Text("Tu ne vois que les collections de tes amis. Le lieu d'une prise s'arrête au département.")
                    .font(JetonAmis.police(13, .bold))
                    .foregroundStyle(JetonAmis.ardoise)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.s)
        }
        .scrollIndicators(.hidden)
        .background(JetonAmis.fondPage.ignoresSafeArea())
    }

    // MARK: Pièces

    private var entete: some View {
        HStack {
            Text("Amis")
                .font(JetonAmis.police(30))
                .foregroundStyle(JetonAmis.encre)
            Spacer()
            Button {
                Task { await gestion.actualiser() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(JetonAmis.police(17))
                    .frame(width: JetonAmis.zoneTactile, height: JetonAmis.zoneTactile)
            }
            .accessibilityLabel("Actualiser")
        }
    }

    private var texteDuMessage: String? {
        if gestion.cartesEnAttente > 0 {
            return gestion.cartesEnAttente == 1 ? "1 carte part au retour du réseau." : "\(gestion.cartesEnAttente) cartes partent au retour du réseau."
        }
        switch gestion.message {
        case .iCloudIndisponible: return "Connecte-toi à iCloud pour voir tes amis. Ton Pescedex reste là."
        case .horsLigne: return "Pas de réseau : les dernières cartes de tes amis restent lisibles."
        case .iCloudPlein: return "Ton iCloud est plein."
        case .echec: return "Ça n'a pas marché. Réessaie avec Actualiser."
        case nil: return nil
        }
    }

    private func bandeau(_ texte: String) -> some View {
        HStack(spacing: 10) {
            Text(texte)
                .font(JetonAmis.police(15, .bold))
                .foregroundStyle(JetonAmis.encre)
            if gestion.compte == .indisponible, let reglages = URL(string: UIApplication.openSettingsURLString) {
                Link("Réglages", destination: reglages)
                    .font(JetonAmis.police(15))
                    .frame(minHeight: JetonAmis.zoneTactile)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JetonAmis.papier, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }

    private func demande(_ invitation: InvitationRecue) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Demande")
                .font(JetonAmis.police(13))
                .foregroundStyle(JetonAmis.ardoise)
            HStack(spacing: 12) {
                Avatar(nom: invitation.nomAmi)
                Text("\(invitation.nomAmi) veut partager sa collection avec toi")
                    .font(JetonAmis.police(16))
                    .foregroundStyle(JetonAmis.encre)
            }
            HStack(spacing: 12) {
                Button("Accepter") { Task { await gestion.accepterLInvitation() } }
                    .buttonStyle(.principal)
                Button("Refuser") { gestion.refuserLInvitation() }
                    .buttonStyle(.secondaire)
            }
        }
        .padding(Espace.l)
        .tuileFishMe()
    }

    private var inviter: some View {
        ShareLink(item: lienDInvitation, preview: SharePreview("Mon Pescedex")) {
            Label("Inviter un ami", systemImage: "person.badge.plus")
        }
        .buttonStyle(.principal)
    }

    private var enRetour: some View {
        HStack {
            ShareLink(item: lienDInvitation, preview: SharePreview("Mon Pescedex")) {
                Label("Inviter en retour", systemImage: "arrow.uturn.right")
                    .font(JetonAmis.police(16))
                    .frame(minHeight: JetonAmis.zoneTactile)
            }
            Spacer()
            Button {
                gestion.fermerLaProposition()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: JetonAmis.zoneTactile, height: JetonAmis.zoneTactile)
            }
            .accessibilityLabel("Fermer")
        }
    }

    private var lienDInvitation: InvitationPescedex {
        let gestion = self.gestion
        return InvitationPescedex(conteneur: gestion.configuration.conteneur) {
            try await gestion.preparerLePartage()
        }
    }

    @ViewBuilder
    private var rangees: some View {
        if !gestion.amis.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(gestion.amis) { ami in
                    if ami.enAttente && !ami.jeVoisSaCollection {
                        ligne(ami, detail: "invitation envoyée", ouvrable: false)
                    } else {
                        Button { amiOuvert = ami } label: { ligne(ami, detail: detail(de: ami), ouvrable: true) }
                            .buttonStyle(.plain)
                    }
                    Divider()
                }
            }
            .padding(.horizontal, Espace.l)
            .tuileFishMe()
        }
    }

    private func detail(de ami: Ami) -> String {
        let n = Set(gestion.collections.first { $0.id == ami.id }?.cartes.map(\.espece) ?? []).count
        guard ami.jeVoisSaCollection else { return "voit ta collection" }
        return n == 1 ? "1 espèce" : "\(n) espèces"
    }

    private func ligne(_ ami: Ami, detail: String, ouvrable: Bool) -> some View {
        HStack(spacing: 12) {
            Avatar(nom: ami.nom)
            VStack(alignment: .leading, spacing: 2) {
                Text(ami.nom).font(JetonAmis.police(17)).foregroundStyle(JetonAmis.encre)
                Text(detail).font(JetonAmis.police(14, .bold)).foregroundStyle(JetonAmis.ardoise)
            }
            Spacer()
            if ouvrable { Image(systemName: "chevron.right").foregroundStyle(JetonAmis.ardoise) }
        }
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }

    private var suppression: some View {
        Button("Supprimer mes cartes partagées", role: .destructive) { confirmerSuppression = true }
            .font(JetonAmis.police(15))
            .frame(minHeight: JetonAmis.zoneTactile)
            .confirmationDialog("Tes amis ne verront plus tes cartes. Ton Pescedex reste sur ton iPhone.",
                                isPresented: $confirmerSuppression, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) { Task { await gestion.supprimerMesCartesPartagees() } }
                Button("Garder", role: .cancel) {}
            }
    }

    private func prendreLInvitation() {
        if let invitation = RelaisInvitations.partage.enAttente { gestion.invitationRecue = invitation }
    }
}

struct Avatar: View {
    let nom: String

    var body: some View {
        Text(String(nom.prefix(1)).uppercased())
            .font(JetonAmis.police(18))
            .foregroundStyle(Palette.surMarine)
            .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
            .background(Palette.marine, in: Circle())
            .accessibilityHidden(true)
    }
}

struct BoutonPlein: ButtonStyle {
    let fond: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(JetonAmis.police(16))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: JetonAmis.zoneTactile)
            .background(fond.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
    }
}
