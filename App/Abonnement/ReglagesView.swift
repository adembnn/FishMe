import SwiftUI
import StoreKit
import Core

/// P35 (direction B, « Réglages ») : retour, grand titre, niveau du pêcheur, alertes, mesure d'audience, sources,
/// puis sécurité, FishMe Pro, restauration et « À propos » (conditions, confidentialité, version).
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
    /// Ouvre « Mon compte » (sauvegarde iCloud, App/Compte). `nil` : la ligne est cachée.
    var ouvrirCompte: (() -> Void)? = nil
    /// Vrai quand l'abonné a l'annuel du tarif fondateur (34,99). `nil` : l'info manque, la ligne dit « Actif ».
    var tarifFondateur: Bool? = nil

    @Environment(\.locale) private var locale
    @State private var gestionOuverte = false
    @State private var message: String?
    @State private var aProposOuvert = false
    /// Mode démo (Adem, « Démo cachée ») : éteint par défaut ; remplit Pescedex, amis et club d'exemples marqués « Démo ».
    @AppStorage("demo.communaute") private var modeDemo = false

    /// Aux États-Unis, les sources françaises (OFB, Hub'Eau, Météo-France, arrêtés) ne sont pas montrées : seule Apple Weather reste.
    private var sourcesAffichees: [(nom: String, role: String)] {
        RegionPersistee.lire() == .etatsUnis ? Self.sources.filter { $0.nom == "Apple Weather" } : Self.sources
    }

    private static let sources: [(nom: String, role: String)] = [
        ("OFB", "Poissons par station"),
        ("Hub'Eau", "Niveau des rivières"),
        ("Météo-France", "Vigilance"),
        ("Arrêtés", "Règles et citations"),
        ("Apple Weather", "Météo"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EnteteEcranReglages(titre: "Réglages")
                bloc {
                    ligneNiveau
                    separateur
                    SelecteurRegion()
                    separateur
                    ligneInterrupteur("Alertes orage et crue", $alertes)
                    separateur
                    ligneInterrupteur("Mesure d'audience", $mesureAudience)
                    #if DEBUG
                    separateur
                    ligneInterrupteur("Mode démo", $modeDemo)
                    #endif
                }
                .padding(.top, 14)
                Text("Sources", tableName: AnglaisE.table)
                    .font(Police.taille(13, .heavy))
                    .textCase(.uppercase)
                    .tracking(0.52)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 6)
                    .accessibilityAddTraits(.isHeader)
                bloc {
                    ForEach(Array(sourcesAffichees.enumerated()), id: \.offset) { position, source in
                        ligne(source.nom, valeur: source.role) { ouvrirSource(source.nom) }
                        if position < sourcesAffichees.count - 1 { separateur }
                    }
                }
                bloc {
                    ligne("Sécurité au bord de l'eau", valeur: nil, action: ouvrirSecurite)
                    separateur
                    // Abonné : la ligne ouvre la gestion de l'abonnement d'Apple ; sinon le paywall.
                    ligne("FishMe Pro", valeur: abonne ? (tarifFondateur == true ? "Fondateur" : "Actif") : "Découvrir") {
                        if abonne { gestionOuverte = true } else { ouvrirPaywall() }
                    }
                    separateur
                    Button { Task { await restaurer() } } label: { Text("Restaurer les achats", tableName: AnglaisE.table) }
                        .font(Police.corps)
                        .foregroundStyle(Palette.marine)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, minHeight: Self.hauteurLigne, alignment: .leading)
                    if let ouvrirCompte {
                        separateur
                        ligne("Mon compte", valeur: "iCloud", action: ouvrirCompte)
                    }
                    separateur
                    ligne("À propos", valeur: Self.version) { aProposOuvert = true }
                }
                .padding(.top, 16)
                if let message {
                    Text(AnglaisE.t(message, locale))
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                        .padding(.horizontal, 16)
                        .padding(.top, Espace.m)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond)
        .manageSubscriptionsSheet(isPresented: $gestionOuverte)
        .navigationDestination(isPresented: $aProposOuvert) { AProposVue(liens: liens) }
    }

    // MARK: Pièces

    /// La hauteur d'une ligne de la maquette : 46 pt.
    fileprivate static let hauteurLigne: CGFloat = 46

    fileprivate static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var separateur: some View { SeparateurReglages() }

    private func bloc<Contenu: View>(@ViewBuilder _ contenu: () -> Contenu) -> some View {
        BlocReglages(contenu: contenu)
    }

    private var ligneNiveau: some View {
        Menu {
            Picker(selection: $niveau) {
                ForEach([NiveauPecheur.debutant, .occasionnel, .confirme], id: \.self) { n in
                    Text(AnglaisE.t(Self.nom(n), locale)).tag(n)
                }
            } label: {
                Text("Niveau de pêcheur", tableName: AnglaisE.table)
            }
        } label: {
            ContenuLigneReglages(titre: "Niveau de pêcheur", valeur: Self.nom(niveau), chevron: true)
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
        Toggle(isOn: valeur) { Text(AnglaisE.t(titre, locale)) }
            .font(Police.corps)
            .foregroundStyle(Palette.encre)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .frame(minHeight: Self.hauteurLigne)
    }

    private func ligne(_ titre: String, valeur: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ContenuLigneReglages(titre: titre, valeur: valeur, chevron: true)
        }
        .buttonStyle(.plain)
    }

    private func restaurer() async {
        let etat = await achats.restaurer()
        surEtat(etat)
        message = etat.donneAcces ? TextesPaywall.restaure : TextesPaywall.rienARestaurer
    }
}

// MARK: - Pièces communes (Réglages et À propos)

/// Retour en marine, sans fond, puis le grand titre (P35 : haut de 103 pt, titre remonté de 6 pt).
private struct EnteteEcranReglages: View {
    let titre: String
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BoutonRond(role: .retour, rendu: .simple)
                .padding(.leading, -8)
                .padding(.top, Espace.s)
            Text(AnglaisE.t(titre, locale))
                .font(Police.grandTitre)
                .foregroundStyle(Palette.encre)
                .padding(.top, -6)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

private struct BlocReglages<Contenu: View>: View {
    private let contenu: Contenu

    init(@ViewBuilder contenu: () -> Contenu) { self.contenu = contenu() }

    var body: some View {
        VStack(spacing: 0) { contenu }
            .frame(maxWidth: .infinity)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Le filet de 0,5 pt entre deux lignes, qui part à 16 pt du bord.
private struct SeparateurReglages: View {
    var body: some View {
        Rectangle().fill(Palette.filet).frame(height: 0.5).padding(.leading, 16)
    }
}

/// Une ligne : texte, valeur à droite, chevron de 8 × 14 pt gris-bleu.
private struct ContenuLigneReglages: View {
    let titre: String
    var valeur: String? = nil
    var chevron = false
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: 12) {
            Text(AnglaisE.t(titre, locale))
                .foregroundStyle(Palette.encre)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let valeur {
                Text(AnglaisE.t(valeur, locale))
                    .foregroundStyle(Palette.encreDouce)
                    .monospacedDigit()
            }
            if chevron {
                ChevronReglages()
                    .stroke(Color(.sRGB, red: 180 / 255, green: 191 / 255, blue: 203 / 255),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 8, height: 14)
                    .accessibilityHidden(true)
            }
        }
        .font(Police.corps)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(minHeight: ReglagesView.hauteurLigne)
        .contentShape(Rectangle())
    }
}

/// Le chevron de la maquette : `m1.5 1.5 5 5.5-5 5.5` dans une boîte de 8 × 14.
private nonisolated struct ChevronReglages: Shape {
    func path(in rect: CGRect) -> Path {
        var chemin = Path()
        chemin.move(to: CGPoint(x: rect.minX + rect.width * 1.5 / 8, y: rect.minY + rect.height * 1.5 / 14))
        chemin.addLine(to: CGPoint(x: rect.minX + rect.width * 6.5 / 8, y: rect.minY + rect.height * 7 / 14))
        chemin.addLine(to: CGPoint(x: rect.minX + rect.width * 1.5 / 8, y: rect.minY + rect.height * 12.5 / 14))
        return chemin
    }
}

// MARK: - À propos : conditions, confidentialité, version

/// La page derrière « À propos » : les conditions s'ouvrent dans l'app, la confidentialité dans le navigateur.
private struct AProposVue: View {
    let liens: LiensLegaux
    @State private var conditionsOuvertes = false
    @State private var confidentialiteOuverte = false
    @State private var creditsOuverts = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EnteteEcranReglages(titre: "À propos")
                BlocReglages {
                    Button { conditionsOuvertes = true } label: {
                        ContenuLigneReglages(titre: "Conditions d'utilisation", chevron: true)
                    }
                    .buttonStyle(.plain)
                    SeparateurReglages()
                    Button { confidentialiteOuverte = true } label: {
                        ContenuLigneReglages(titre: "Confidentialité", chevron: true)
                    }
                    .buttonStyle(.plain)
                    SeparateurReglages()
                    Button { creditsOuverts = true } label: {
                        ContenuLigneReglages(titre: "Crédits photos", chevron: true)
                    }
                    .buttonStyle(.plain)
                    SeparateurReglages()
                    ContenuLigneReglages(titre: "Version", valeur: ReglagesView.version)
                        .accessibilityElement(children: .combine)
                }
                .padding(.top, 14)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $conditionsOuvertes) { ConditionsFeuille() }
        .sheet(isPresented: $confidentialiteOuverte) { ConfidentialiteFeuille() }
        .sheet(isPresented: $creditsOuverts) { CreditsPhotosFeuille() }
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
        .environment(RegionCourante())
}
#endif
