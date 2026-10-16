import SwiftUI
import UIKit

/// Mon compte : l'état d'iCloud, la sauvegarde des cartes et des sorties, la restauration de FishMe Pro.
/// Pas de mot de passe : le compte, c'est l'identifiant Apple. A le branche dans `RootView.swift` :
/// `CompteView(modele: CompteModele(service:restaurerAchats:surRapatriement:), abonne:)`.
@MainActor
@Observable
final class CompteModele {
    private(set) var etat: EtatICloud = .inconnu
    private(set) var bilan: BilanSauvegarde?
    private(set) var enCours = false
    private(set) var message: String?

    private let service: any ServiceSauvegarde
    private let restaurerAchats: @MainActor () async -> Bool
    private let surRapatriement: @MainActor () async -> Void

    init(
        service: any ServiceSauvegarde,
        restaurerAchats: @escaping @MainActor () async -> Bool,
        surRapatriement: @escaping @MainActor () async -> Void = {}
    ) {
        self.service = service
        self.restaurerAchats = restaurerAchats
        self.surRapatriement = surRapatriement
    }

    /// Lit l'état du compte iCloud et, s'il est disponible, sauvegarde tout de suite.
    func rafraichir() async {
        guard !enCours else { return }
        etat = await service.etatCompte()
        // Après « Effacer », on ne renvoie rien tout seul : seul « Sauvegarder maintenant » relance la sauvegarde.
        if etat == .disponible, !UserDefaults.standard.bool(forKey: SauvegardeICloud.cleCoupee) { await sauvegarder() }
    }

    func sauvegarder() async {
        guard !enCours else { return }
        enCours = true
        defer { enCours = false }
        message = nil
        do {
            let resultat = try await service.synchroniser()
            bilan = resultat
            if resultat.aRelire { await surRapatriement() }
        } catch {
            message = "La sauvegarde n'a pas pu se faire. Réessaie avec du réseau."
        }
    }

    func restaurer() async {
        guard !enCours else { return }
        enCours = true
        defer { enCours = false }
        message = nil
        let revenu = await restaurerAchats()
        message = revenu
            ? "FishMe Pro est revenu."
            : "Aucun achat à restaurer sur cet identifiant Apple."
    }

    func effacer() async {
        guard !enCours else { return }
        enCours = true
        defer { enCours = false }
        message = nil
        do {
            try await service.effacer()
            bilan = nil
            message = "Tes données iCloud sont supprimées : sauvegarde et cartes partagées avec tes amis. Tes cartes restent sur cet iPhone."
        } catch {
            message = "La suppression n'a pas pu se faire. Réessaie avec du réseau."
        }
    }
}

struct CompteView: View {
    @Bindable var modele: CompteModele
    let abonne: Bool

    @Environment(\.openURL) private var openURL
    @State private var confirmationOuverte = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                Text("Mon compte")
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .padding(.horizontal, Espace.xs)
                enTete
                if let bilan = modele.bilan {
                    chiffres(bilan)
                }
                if modele.etat == .disponible {
                    sauvegarderBouton
                }
                blocPro
                if let lien = Self.lienAppStore {
                    ShareLink(item: lien, preview: SharePreview("FishMe")) {
                        Label("Partager FishMe", systemImage: "square.and.arrow.up")
                            .font(Police.corps)
                            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    }
                    .buttonStyle(.secondaire)
                }
                if modele.etat == .disponible {
                    blocEffacer
                }
                if let message = modele.message {
                    Text(message)
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                        .padding(.horizontal, Espace.l)
                }
                Text("Pas de mot de passe : ton compte, c'est ton identifiant Apple. Rien n'est envoyé chez nous. Tes coins de pêche exacts restent sur cet iPhone.")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.horizontal, Espace.l)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.l)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond)
        .task { await modele.rafraichir() }
    }

    /// Lien App Store de FishMe, lu dans Info (`FishMeLienAppStore`) : absent tant que l'app n'a pas son numéro, et le bouton reste caché.
    static var lienAppStore: URL? {
        (Bundle.main.object(forInfoDictionaryKey: "FishMeLienAppStore") as? String).flatMap(URL.init(string:))
    }

    // MARK: Pièces

    private func bloc<Contenu: View>(@ViewBuilder _ contenu: () -> Contenu) -> some View {
        VStack(spacing: 0, content: contenu)
            .frame(maxWidth: .infinity)
            .tuileFishMe(rayon: Rayon.l)
    }

    private var enTete: some View {
        bloc {
            VStack(spacing: Espace.m) {
                switch modele.etat {
                case .inconnu:
                    ChargementBouchon(taille: 44)
                        .frame(minHeight: Gabarit.zoneTactile)
                case .disponible:
                    symbole("checkmark.icloud.fill", Palette.marine)
                    phrase("Tes cartes sont à l'abri dans ton iCloud")
                case .absent:
                    symbole("icloud.slash", Palette.encreDouce)
                    phrase("Connecte-toi à iCloud pour garder tes cartes si tu changes d'iPhone")
                    Button("Ouvrir les Réglages") {
                        if let adresse = URL(string: UIApplication.openSettingsURLString) {
                            openURL(adresse)
                        }
                    }
                    .buttonStyle(.secondaire)
                case .restreint:
                    symbole("icloud.slash", Palette.alerte)
                    phrase("iCloud est bloqué sur cet iPhone")
                }
            }
            .padding(Espace.l)
            .frame(maxWidth: .infinity)
        }
    }

    private func symbole(_ nom: String, _ couleur: Color) -> some View {
        Image(systemName: nom)
            .font(Police.taille(56))
            .foregroundStyle(couleur)
            .accessibilityHidden(true)
    }

    private func phrase(_ texte: String) -> some View {
        Text(texte)
            .font(Police.sousTitre)
            .foregroundStyle(Palette.encre)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func chiffres(_ bilan: BilanSauvegarde) -> some View {
        bloc {
            VStack(spacing: Espace.m) {
                HStack(alignment: .top, spacing: Espace.l) {
                    chiffre(bilan.cartes, "cartes", "square.stack.fill")
                    chiffre(bilan.sorties, "sorties", "figure.fishing")
                }
                HStack(spacing: Espace.xs) {
                    Text("Sauvegardé")
                    Text(bilan.date.formatted(.relative(presentation: .named)))
                }
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .accessibilityElement(children: .combine)
            }
            .padding(Espace.l)
            .frame(maxWidth: .infinity)
        }
    }

    private func chiffre(_ valeur: Int, _ nom: String, _ icone: String) -> some View {
        VStack(spacing: Espace.xs) {
            Image(systemName: icone)
                .font(Police.sousTitre)
                .foregroundStyle(Palette.marine)
                .accessibilityHidden(true)
            Text("\(valeur)")
                .font(Police.chiffre)
                .foregroundStyle(Palette.encre)
            Text(nom)
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var sauvegarderBouton: some View {
        Button {
            Task { await modele.sauvegarder() }
        } label: {
            if modele.enCours {
                ProgressView().tint(Palette.surMarine)
            } else {
                Label("Sauvegarder maintenant", systemImage: "icloud.and.arrow.up")
            }
        }
        .buttonStyle(.principal)
        .disabled(modele.enCours || modele.etat != .disponible)
    }

    private var blocPro: some View {
        bloc {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("FishMe Pro").foregroundStyle(Palette.encre)
                    Spacer(minLength: Espace.s)
                    Text(abonne ? "Actif" : "Non abonné").foregroundStyle(Palette.encreDouce)
                }
                .font(Police.corps)
                .frame(minHeight: Gabarit.zoneTactile)
                .padding(.horizontal, Espace.l)
                .accessibilityElement(children: .combine)
                Text("Ton abonnement revient avec ton identifiant Apple")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.horizontal, Espace.l)
                    .padding(.bottom, Espace.s)
                Divider().padding(.leading, Espace.l)
                Button("Restaurer les achats") { Task { await modele.restaurer() } }
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
                    .padding(.horizontal, Espace.l)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .disabled(modele.enCours)
            }
        }
    }

    private var blocEffacer: some View {
        bloc {
            Button(role: .destructive) {
                confirmationOuverte = true
            } label: {
                Text("Supprimer mon compte et mes données iCloud")
                    .font(Police.corps)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
                    .padding(.horizontal, Espace.l)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(modele.enCours)
        }
        .confirmationDialog(
            "Supprimer ton compte FishMe ?",
            isPresented: $confirmationOuverte,
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) { Task { await modele.effacer() } }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Ta sauvegarde iCloud et les cartes partagées avec tes amis sont effacées. Tes cartes restent sur cet iPhone, mais un nouvel iPhone ne les retrouvera plus. L'abonnement se résilie dans les réglages de l'App Store.")
        }
    }
}

#if DEBUG
nonisolated struct ServiceSauvegardeApercu: ServiceSauvegarde {
    func etatCompte() async -> EtatICloud { .disponible }
    func synchroniser() async throws -> BilanSauvegarde {
        BilanSauvegarde(cartes: 12, sorties: 4, rapatriees: 0, date: .now)
    }
    func effacer() async throws {}
}

#Preview {
    CompteView(
        modele: CompteModele(service: ServiceSauvegardeApercu(), restaurerAchats: { true }),
        abonne: false)
}
#endif
