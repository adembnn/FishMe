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
    @State private var achatEnCours = false
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
                    .frame(maxHeight: max(geo.size.height - 60, 0))
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

    /// La feuille prend la hauteur de son contenu (pas d'espace vide sous le texte). Si le contenu ne tient pas
    /// (petit iPhone, texte agrandi), la partie haute défile et le bouton et les liens restent fixés en bas (P50 B).
    private var feuille: some View {
        Group {
            switch modele.etat {
            case .chargement:
                VStack(spacing: 0) {
                    ChargementBouchon().frame(maxWidth: .infinity).frame(height: 300)
                    pied
                }
            case .indisponible:
                VStack(spacing: 0) {
                    indisponible
                    pied
                }
            case .pret:
                ViewThatFits(in: .vertical) {
                    VStack(spacing: 0) {
                        contenuHaut
                        boutonContinuer
                        pied
                    }
                    VStack(spacing: 0) {
                        ScrollView { contenuHaut }
                            .scrollIndicators(.hidden)
                            .scrollBounceBehavior(.basedOnSize)
                        boutonContinuer
                        pied
                    }
                }
            }
        }
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
        .shadow(color: Palette.encre.opacity(0.16), radius: 30, y: -2)
    }

    // MARK: Boutique (P34 A)

    /// Nos propres lignes d'offre et notre bouton « Continuer », en français et aux mesures de la maquette.
    /// (La boutique toute faite d'Apple écrasait l'offre sous son bouton et parlait anglais.)
    private var contenuHaut: some View {
        VStack(alignment: .leading, spacing: 0) {
            argumentaire
            VStack(spacing: 8) {
                ligneOffre(id: modele.produits.annuel, titre: "Annuel", detail: modele.phraseLancement, prix: modele.prixAnnuel)
                if let mensuel = modele.produits.mensuel, let prix = modele.prixMensuel {
                    ligneOffre(id: mensuel, titre: "Mensuel", detail: modele.phraseEssai, prix: prix)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var boutonContinuer: some View {
        Button {
            Task { await acheter() }
        } label: {
            Group {
                if achatEnCours { ProgressView().tint(Palette.surMarine) } else { Text("Continuer") }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.principal)
        .disabled(achatEnCours)
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    /// Une offre : rond de sélection, nom et phrase, prix à droite. Bord marine quand elle est cochée.
    private func ligneOffre(id: String, titre: String, detail: String?, prix: String?) -> some View {
        let coche = modele.choix == id
        return Button {
            modele.choix = id
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().strokeBorder(coche ? Palette.marine : Palette.filet, lineWidth: 2)
                    if coche { Circle().fill(Palette.marine).frame(width: 12, height: 12) }
                }
                .frame(width: 24, height: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(titre)
                        .font(Police.taille(17, .heavy))
                        .foregroundStyle(Palette.encre)
                    if let detail {
                        Text(detail)
                            .font(Police.taille(13, .bold))
                            .foregroundStyle(Palette.encreDouce)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                if let prix {
                    Text(prix)
                        .font(Police.taille(17, .heavy))
                        .foregroundStyle(Palette.encre)
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(coche ? Palette.marine : Palette.filet, lineWidth: coche ? 2 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(coche ? .isSelected : [])
    }

    private func acheter() async {
        achatEnCours = true
        defer { achatEnCours = false }
        message = nil
        // La mesure de l'achat passe par `AchatsStoreKit` (rappel `surAchat` branché par A).
        let etat = await achats.acheter(produit: modele.choix)
        surEtat(etat)
        if etat.donneAcces {
            surAchatTermine(declencheur)
            fermer()
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

    /// La ligne sous le bouton : renouvellement automatique et résiliation (le tarif fondateur est sur la ligne Annuel).
    private var mentions: String {
        TextesPaywall.renouvellementCourt
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
                .fixedSize(horizontal: false, vertical: true)
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
        .frame(height: 260)
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
