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

    /// P34 A (et P50 B sur petit iPhone) : la carte de l'app reste visible derrière un voile, la croix en verre est en haut à gauche,
    /// la feuille blanche (rayon 38, 8 pt de marge) flotte en bas. Sur petit écran sa hauteur est plafonnée : le contenu défile
    /// et le bouton et les liens restent fixés en bas.
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Palette.fond.opacity(0.62).ignoresSafeArea()
                feuille
                    .frame(height: min(max(geo.size.height - 60, 0), 540))
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        // Croix toujours visible (règle Apple) : elle ferme la feuille sans rien débloquer, même quand le paywall bloque.
        .overlay(alignment: .topLeading) {
            BoutonRond(role: .fermer, action: fermer)
                .padding(.top, Espace.s)
                .padding(.leading, Espace.bord)
        }
        .presentationBackground(.clear)
        .presentationDragIndicator(.hidden)
        .task {
            if !dejaMontre {
                dejaMontre = true
                mesure.paywallMontre(declencheur: declencheur)
            }
            await modele.charger()
        }
    }

    private var feuille: some View {
        VStack(spacing: 0) {
            Group {
                switch modele.etat {
                case .chargement:
                    ChargementBouchon().frame(maxWidth: .infinity, maxHeight: .infinity)
                case .indisponible:
                    indisponible
                case .pret:
                    boutique
                }
            }
            pied
        }
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
        .shadow(color: Palette.encre.opacity(0.16), radius: 30, y: -2)
    }

    // MARK: Boutique native

    private var boutique: some View {
        SubscriptionStoreView(productIDs: modele.produits.identifiants) {
            argumentaire
        }
        .subscriptionStoreControlStyle(.prominentPicker)
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
        VStack(alignment: .leading, spacing: 0) {
            Text("FishMe Pro")
                .font(Police.taille(22, .heavy))
                .foregroundStyle(Palette.encre)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            pastilles
                .padding(.top, 18)
                .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 26)
    }

    /// La ligne sous le bouton : tarif fondateur, essai éventuel (lus dans StoreKit), puis renouvellement automatique et résiliation.
    private var mentions: String {
        let morceaux = [modele.phraseLancement, modele.phraseEssai].compactMap { $0 }
        return (morceaux + [TextesPaywall.renouvellementCourt]).joined(separator: " ")
    }

    /// P34 A : quatre pastilles rondes (spots, météo et rivière, alertes, conseils), une icône et un mot chacune.
    private var pastilles: some View {
        HStack(alignment: .top, spacing: 6) {
            pastille("map", "Tous les spots")
            pastille("cloud", "Météo et rivière")
            pastille("bolt.fill", "Alertes")
            pastille("doc.text", "Conseils")
        }
    }

    private func pastille(_ icone: String, _ texte: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icone)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.marine)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Palette.marineDoux))
                .accessibilityHidden(true)
            Text(texte)
                .font(Police.legende)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
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
        VStack(spacing: 0) {
            if let message {
                Text(message).font(Police.legende).foregroundStyle(Palette.encreDouce).multilineTextAlignment(.center)
                    .padding(.bottom, Espace.xs)
            }
            // P34 A : un seul bouton principal (celui de la boutique) ; la croix en haut ferme la feuille.
            if modele.etat == .pret {
                Text(mentions)
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
            // Liens légaux toujours visibles. Une seule ligne (ou deux si le texte est agrandi) : le pied reste bas sur petit iPhone.
            Group {
                if tailleTexte >= .accessibility1 {
                    Menu("Plus") { piedLiens }
                        .frame(minHeight: Gabarit.zoneTactile)
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 4) { piedLiens }
                        VStack(spacing: 0) { piedLiens }
                    }
                }
            }
            .font(Police.taille(13, .heavy))
            .foregroundStyle(Palette.marine)
        }
        .padding(.horizontal, 20)
        .padding(.top, Espace.xs)
        .padding(.bottom, 12)
    }

    @ViewBuilder private var piedLiens: some View {
        Button("Restaurer les achats") { Task { await restaurer() } }
            .frame(minHeight: Gabarit.zoneTactile).padding(.horizontal, 6)
        Link("Conditions", destination: liens.conditions)
            .frame(minHeight: Gabarit.zoneTactile).padding(.horizontal, 6)
        Link("Confidentialité", destination: liens.confidentialite)
            .frame(minHeight: Gabarit.zoneTactile).padding(.horizontal, 6)
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
