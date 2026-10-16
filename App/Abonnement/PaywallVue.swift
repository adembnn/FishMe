import SwiftUI
import StoreKit
import Core

/// Les adresses des deux pages légales. Elles viennent de la fiche App Store (S1) : A les passe.
struct LiensLegaux {
    var conditions: URL
    var confidentialite: URL

    /// Conditions d'utilisation standard d'Apple, tant que celles de FishMe ne sont pas publiées.
    static let conditionsApple = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}

/// Le paywall : un seul écran pour les trois déclencheurs (fin de 1re session, autre spot, fonction Pro touchée).
/// Il ne décide rien : `acces` et `peutUtiliser` de Core disent quand l'ouvrir. Il dit ce qui reste gratuit et ce que Pro ajoute.
@available(iOS 17.0, *)
struct PaywallVue: View {
    let declencheur: DeclencheurPaywall
    let achats: Achats
    let mesure: MesurePaywall
    let liens: LiensLegaux
    /// Rappelé après un achat ou une restauration, avec l'état lu : A le passe à `moteur.abonne`.
    let surEtat: (EtatAchats) -> Void
    /// Rappelé après un achat réussi, avant la fermeture : A rouvre la fonction touchée.
    let surAchatTermine: (DeclencheurPaywall) -> Void
    /// Ferme le paywall et rend l'écran d'où il vient ; la fonction touchée reste fermée.
    let fermer: () -> Void

    @State private var modele: ModeleOffres
    @State private var message: String?
    @State private var dejaMontre = false
    @Environment(\.dynamicTypeSize) private var tailleTexte

    init(declencheur: DeclencheurPaywall, produits: ProduitsMontres, achats: Achats, mesure: MesurePaywall, liens: LiensLegaux,
         surEtat: @escaping (EtatAchats) -> Void, surAchatTermine: @escaping (DeclencheurPaywall) -> Void = { _ in },
         fermer: @escaping () -> Void) {
        self.declencheur = declencheur
        self.achats = achats
        self.mesure = mesure
        self.liens = liens
        self.surEtat = surEtat
        self.surAchatTermine = surAchatTermine
        self.fermer = fermer
        _modele = State(initialValue: ModeleOffres(produits: produits))
    }

    var body: some View {
        Group {
            switch modele.etat {
            case .chargement:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .indisponible:
                indisponible
            case .pret:
                boutique
            }
        }
        .background(Palette.surface)
        .safeAreaInset(edge: .bottom) { pied }
        .task {
            if !dejaMontre {
                dejaMontre = true
                mesure.paywallMontre(declencheur: declencheur)
            }
            await modele.charger()
        }
    }

    // MARK: Boutique native

    private var boutique: some View {
        SubscriptionStoreView(productIDs: modele.produits.identifiants) {
            argumentaire
        }
        .subscriptionStoreControlStyle(.picker)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePolicyDestination(url: liens.conditions, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: liens.confidentialite, for: .privacyPolicy)
        .storeButton(.hidden, for: .restorePurchases)
        .scrollIndicators(.hidden)
        .onInAppPurchaseCompletion { _, resultat in
            guard case .success(let achat) = resultat else { return }
            await mesure.enregistrerAchat(achat)
            if case .success(.verified(let transaction)) = achat { await transaction.finish() }
            let etat = await achats.etat()
            surEtat(etat)
            if etat.donneAcces {
                surAchatTermine(declencheur)
                fermer()
            }
        }
    }

    // MARK: Contenu au-dessus des offres

    private var argumentaire: some View {
        VStack(alignment: .leading, spacing: Espace.l) {
            VStack(alignment: .leading, spacing: Espace.xs) {
                Text("FishMe Pro")
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                if case .fonction(let fonction) = declencheur {
                    Text(TextesPaywall.titre(fonction))
                        .font(Police.sousTitre)
                        .foregroundStyle(Palette.marine)
                }
            }
            avantages
            Text("Ton spot gratuit reste à toi, pour toujours.")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
            if let phrase = modele.phraseLancement {
                Text(phrase).font(Police.detail).foregroundStyle(Palette.encre)
            }
            if let essai = modele.phraseEssai {
                Text(essai).font(Police.detail).foregroundStyle(Palette.marine)
            }
            Text(TextesPaywall.renouvellement)
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Les quatre avantages de la maquette P34 A : une pastille ronde et un mot chacun.
    private static let avantagesPro: [(icone: String, titre: String)] = [
        ("map", "Tous les spots"),
        ("cloud", "Météo et rivière"),
        ("bolt", "Alertes"),
        ("doc.text", "Conseils"),
    ]

    private var avantages: some View {
        let disposition = tailleTexte.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Espace.m))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Espace.s))
        return disposition {
            ForEach(Self.avantagesPro, id: \.titre) { avantage in
                VStack(spacing: Espace.s) {
                    Image(systemName: avantage.icone)
                        .font(Police.sousTitre)
                        .foregroundStyle(Palette.marine)
                        .frame(width: 48, height: 48)
                        .background(Palette.marineDoux, in: Circle())
                    Text(avantage.titre)
                        .font(Police.legende)
                        .foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: Produit introuvable

    private var indisponible: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(TextesPaywall.produitIntrouvable)
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                Button("Réessayer") { Task { await modele.charger() } }
                    .buttonStyle(.principal)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Pied : restaurer, message, fermer, liens légaux

    private var pied: some View {
        VStack(spacing: 4) {
            if let message {
                Text(message).font(Police.legende).foregroundStyle(Palette.encreDouce).multilineTextAlignment(.center)
            }
            Button(action: fermer) {
                Text(declencheur.texteFermeture)
            }
            .buttonStyle(.secondaire)
            // Liens légaux toujours visibles, même si ce pied recouvre ceux de la boutique.
            // Une seule ligne (ou deux si le texte est agrandi) : le pied reste bas sur iPhone SE et 13 mini.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Espace.l) { piedLiens }
                VStack(spacing: 0) { piedLiens }
            }
            .font(Police.legende)
            .foregroundStyle(Palette.marine)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.vertical, Espace.s)
        .background(Palette.surface)
    }

    @ViewBuilder private var piedLiens: some View {
        Button("Restaurer") { Task { await restaurer() } }
            .frame(minHeight: Gabarit.zoneTactile)
        Link("Conditions", destination: liens.conditions)
            .frame(minHeight: Gabarit.zoneTactile)
        Link("Confidentialité", destination: liens.confidentialite)
            .frame(minHeight: Gabarit.zoneTactile)
    }

    private func restaurer() async {
        let etat = await achats.restaurer()
        surEtat(etat)
        if etat.donneAcces {
            message = TextesPaywall.restaure
            surAchatTermine(declencheur)
            fermer()
        } else {
            message = TextesPaywall.rienARestaurer
        }
    }
}
