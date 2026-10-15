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
        .background(JetonsAbonnement.papier)
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
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("FishMe Pro")
                    .font(JetonsAbonnement.police(.largeTitle))
                    .foregroundStyle(JetonsAbonnement.marine)
                if case .fonction(let fonction) = declencheur {
                    Text(TextesPaywall.titre(fonction))
                        .font(JetonsAbonnement.police(.title3))
                        .foregroundStyle(JetonsAbonnement.vert)
                    Text("Cette fonction fait partie de Pro.")
                        .font(JetonsAbonnement.texte(.subheadline))
                }
            }
            colonnes
            if let phrase = modele.phraseLancement {
                Text(phrase).font(JetonsAbonnement.police(.subheadline)).foregroundStyle(JetonsAbonnement.marine)
            }
            if let essai = modele.phraseEssai {
                Text(essai).font(JetonsAbonnement.police(.subheadline)).foregroundStyle(JetonsAbonnement.vert)
            }
            Text(TextesPaywall.renouvellement)
                .font(JetonsAbonnement.texte(.footnote))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var colonnes: some View {
        Group {
            if tailleTexte.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) { colonneGratuit; colonnePro }
            } else {
                HStack(alignment: .top, spacing: 14) { colonneGratuit; colonnePro }
            }
        }
    }

    private var colonneGratuit: some View {
        colonne(titre: "Gratuit, pour toujours", lignes: TextesPaywall.gratuit, couleur: JetonsAbonnement.marine)
    }

    private var colonnePro: some View {
        colonne(titre: "Avec Pro", lignes: TextesPaywall.proEnTete(declencheur), couleur: JetonsAbonnement.vert)
    }

    private func colonne(titre: String, lignes: [TextesPaywall.Ligne], couleur: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titre).font(JetonsAbonnement.police(.headline)).foregroundStyle(couleur)
            ForEach(lignes, id: \.texte) { ligne in
                Label {
                    Text(ligne.texte).font(JetonsAbonnement.texte(.subheadline)).fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: ligne.icone).foregroundStyle(couleur).frame(width: 22)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Produit introuvable

    private var indisponible: some View {
        VStack(spacing: 16) {
            Text(TextesPaywall.produitIntrouvable)
                .font(JetonsAbonnement.police(.headline))
                .multilineTextAlignment(.center)
            Button("Réessayer") { Task { await modele.charger() } }
                .buttonStyle(.borderedProminent).tint(JetonsAbonnement.vert).controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Pied : restaurer, message, fermer

    private var pied: some View {
        VStack(spacing: 8) {
            if let message {
                Text(message).font(JetonsAbonnement.texte(.footnote)).multilineTextAlignment(.center)
            }
            Button("Restaurer les achats") { Task { await restaurer() } }
                .font(JetonsAbonnement.texte(.subheadline))
            Button(action: fermer) {
                Text(declencheur.texteFermeture)
                    .font(JetonsAbonnement.police(.headline))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered).tint(JetonsAbonnement.marine)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.bar)
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
