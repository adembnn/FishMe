import SwiftUI
import StoreKit
import Core

/// P35 (direction B, « Réglages ») : niveau du pêcheur, alertes, mesure d'audience, sources, sécurité,
/// abonnement, restauration, pages légales et version. Une liste de blocs arrondis, sans texte inutile.
/// A la branche dans `RootView.swift` :
/// A la branche dans `RootView.swift` : `ReglagesView(niveau:alertes:mesureAudience:abonne:achats:liens:surEtat:ouvrirSource:ouvrirSecurite:ouvrirPaywall:)`.
struct ReglagesView: View {
    @Binding var niveau: NiveauPecheur
    @Binding var alertes: Bool
    /// Vrai si le pêcheur a accepté la mesure d'audience. Le changer passe par `reglerMesure` (SDK allumé ou éteint).
    @Binding var mesureAudience: Bool
    let abonne: Bool
    let achats: Achats
    let liens: LiensLegaux
    /// Rappelé après une restauration, avec l'état lu : A le passe à `SuiviAbonnement.appliquer`.
    let surEtat: (EtatAchats) -> Void
    /// Ouvre la page d'une source (« OFB », « Hub'Eau », « Météo-France », « Arrêtés », « Apple Weather »).
    let ouvrirSource: (String) -> Void
    let ouvrirSecurite: () -> Void
    /// Ouvre le paywall quand le pêcheur n'est pas abonné.
    let ouvrirPaywall: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var gestionOuverte = false
    @State private var message: String?

    private static let sources: [(nom: String, role: String)] = [
        ("OFB", "Poissons par station"),
        ("Hub'Eau", "Niveau des rivières"),
        ("Météo-France", "Vigilance"),
        ("Arrêtés", "Règles et citations"),
        ("Apple Weather", "Météo"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                HStack {
                    Text("Réglages")
                        .font(Police.grandTitre)
                        .foregroundStyle(Palette.encre)
                    Spacer(minLength: Espace.s)
                    // Ferme la feuille (la barre de navigation est cachée par RootView).
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .foregroundStyle(Palette.encre)
                            .frame(width: 44, height: 44)
                            .background(Palette.surface, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Fermer")
                }
                .padding(.horizontal, Espace.xs)
                bloc {
                    ligneNiveau
                    separateur
                    ligneInterrupteur("Alertes orage et crue", $alertes)
                    separateur
                    ligneInterrupteur("Mesure d'audience", $mesureAudience)
                }
                Text("SOURCES")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.leading, Espace.l)
                    .padding(.bottom, -Espace.s)
                bloc {
                    ForEach(Array(Self.sources.enumerated()), id: \.offset) { position, source in
                        ligne(source.nom, valeur: source.role) { ouvrirSource(source.nom) }
                        if position < Self.sources.count - 1 { separateur }
                    }
                }
                bloc {
                    ligne("Sécurité au bord de l'eau", valeur: nil, action: ouvrirSecurite)
                    separateur
                    ligne("FishMe Pro", valeur: abonne ? "Actif" : "Découvrir") {
                        if abonne { gestionOuverte = true } else { ouvrirPaywall() }
                    }
                    if abonne {
                        separateur
                        ligne("Gérer l'abonnement", valeur: nil) { gestionOuverte = true }
                    }
                    separateur
                    Button("Restaurer les achats") { Task { await restaurer() } }
                        .font(Police.corps)
                        .foregroundStyle(Palette.marine)
                        .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
                        .padding(.horizontal, Espace.l)
                    separateur
                    lien("Conditions d'utilisation", liens.conditions)
                    separateur
                    lien("Confidentialité", liens.confidentialite)
                    separateur
                    HStack {
                        Text("À propos").foregroundStyle(Palette.encre)
                        Spacer(minLength: Espace.s)
                        Text(Self.version).foregroundStyle(Palette.encreDouce)
                    }
                    .font(Police.corps)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .padding(.horizontal, Espace.l)
                    .accessibilityElement(children: .combine)
                }
                if let message {
                    Text(message)
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                        .padding(.horizontal, Espace.l)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.l)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond)
        .manageSubscriptionsSheet(isPresented: $gestionOuverte)
    }

    // MARK: Pièces

    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var separateur: some View {
        Divider().padding(.leading, Espace.l)
    }

    private func bloc<Contenu: View>(@ViewBuilder _ contenu: () -> Contenu) -> some View {
        VStack(spacing: 0, content: contenu)
            .tuileFishMe(rayon: Rayon.l)
    }

    private var ligneNiveau: some View {
        Menu {
            Picker("Niveau de pêcheur", selection: $niveau) {
                ForEach([NiveauPecheur.debutant, .occasionnel, .confirme], id: \.self) { n in
                    Text(Self.nom(n)).tag(n)
                }
            }
        } label: {
            HStack {
                Text("Niveau de pêcheur").foregroundStyle(Palette.encre)
                Spacer(minLength: Espace.s)
                Text(Self.nom(niveau)).foregroundStyle(Palette.encreDouce)
                chevron
            }
            .font(Police.corps)
            .frame(minHeight: Gabarit.zoneTactile)
            .padding(.horizontal, Espace.l)
            .contentShape(Rectangle())
        }
    }

    private static func nom(_ niveau: NiveauPecheur) -> String {
        switch niveau {
        case .debutant: "Débutant"
        case .occasionnel: "Occasionnel"
        case .confirme: "Confirmé"
        }
    }

    private func ligneInterrupteur(_ titre: String, _ valeur: Binding<Bool>) -> some View {
        Toggle(titre, isOn: valeur)
            .font(Police.corps)
            .foregroundStyle(Palette.encre)
            .frame(minHeight: Gabarit.zoneTactile)
            .padding(.horizontal, Espace.l)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(Police.legende)
            .foregroundStyle(Palette.silhouette)
            .accessibilityHidden(true)
    }

    private func ligne(_ titre: String, valeur: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(titre).foregroundStyle(Palette.encre)
                Spacer(minLength: Espace.s)
                if let valeur { Text(valeur).foregroundStyle(Palette.encreDouce) }
                chevron
            }
            .font(Police.corps)
            .frame(minHeight: Gabarit.zoneTactile)
            .padding(.horizontal, Espace.l)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func lien(_ titre: String, _ adresse: URL) -> some View {
        Link(destination: adresse) {
            HStack {
                Text(titre).foregroundStyle(Palette.encre)
                Spacer(minLength: Espace.s)
                chevron
            }
            .font(Police.corps)
            .frame(minHeight: Gabarit.zoneTactile)
            .padding(.horizontal, Espace.l)
            .contentShape(Rectangle())
        }
    }

    private func restaurer() async {
        let etat = await achats.restaurer()
        surEtat(etat)
        message = etat.donneAcces ? TextesPaywall.restaure : TextesPaywall.rienARestaurer
    }
}

#if DEBUG
private struct AchatsApercu: Achats {
    func etat() async -> EtatAchats { .nonAbonne }
    func modifications() -> AsyncStream<EtatAchats> { AsyncStream { $0.finish() } }
    func acheter(produit: String) async -> EtatAchats { .nonAbonne }
    func restaurer() async -> EtatAchats { .nonAbonne }
}

#Preview {
    @Previewable @State var niveau = NiveauPecheur.confirme
    @Previewable @State var alertes = true
    @Previewable @State var mesure = true
    ReglagesView(
        niveau: $niveau, alertes: $alertes, mesureAudience: $mesure, abonne: false,
        achats: AchatsApercu(),
        liens: LiensLegaux(conditions: LiensLegaux.conditionsApple, confidentialite: LiensLegaux.conditionsApple),
        surEtat: { _ in }, ouvrirSource: { _ in }, ouvrirSecurite: {}, ouvrirPaywall: {})
}
#endif
