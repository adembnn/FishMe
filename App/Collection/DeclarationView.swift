import AVFoundation
import Core
import SwiftUI

/// Quand « Prendre une photo » ouvre la caméra d'emblée (L18) : seulement si l'accès est déjà donné. Sinon le menu s'ouvre,
/// et la caméra demande sa permission à la prise.
enum AccesCamera {
    static func ouvreEnUnToucher(_ statut: AVAuthorizationStatus) -> Bool { statut == .authorized }
}

/// Le tri et la recherche de la grille « Déclarer un poisson déjà pêché », sans écran (testables).
enum FiltreDeclaration {
    /// Les espèces à montrer : celles qui correspondent à la recherche (nom ou nom latin, sans tenir compte des accents ni de la casse),
    /// celles dont le nom commence par la recherche d'abord, puis celles de la zone, puis l'ordre alphabétique.
    static func especes(_ toutes: [EspecePechable], recherche: String, deLaZone: Set<String>) -> [EspecePechable] {
        let q = recherche.trimmingCharacters(in: .whitespaces)
        let retenues = q.isEmpty
            ? toutes
            : toutes.filter { $0.nom.localizedStandardContains(q) || $0.nomLatin.localizedStandardContains(q) }
        func commence(_ e: EspecePechable) -> Bool {
            !q.isEmpty && e.nom.range(of: q, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) != nil
        }
        return retenues.sorted { a, b in
            if commence(a) != commence(b) { return commence(a) }
            let zoneA = deLaZone.contains(a.espece.id)
            let zoneB = deLaZone.contains(b.espece.id)
            if zoneA != zoneB { return zoneA }
            return a.nom.localizedCompare(b.nom) == .orderedAscending
        }
    }
}

/// « Déclarer un poisson déjà pêché » (L18) : une grille d'espèces en images, une recherche par nom, les espèces de la zone d'abord.
/// Toucher une espèce crée sa carte déclarée (sans photo, distincte d'une vraie prise) et ferme la grille ; le Pescedex ouvre alors
/// sa fiche. « La prendre en photo » mène à la prise. Le tunnel du premier lancement ne s'ouvre jamais d'ici.
struct DeclarationView: View {
    /// Les espèces pêchables, la liste fermée de l'app (la même que la grille de la prise).
    let especes: [EspecePechable]
    /// Les espèces qui ont déjà une carte (vraie ou déclarée) : montrées avec une coche, sans second toucher.
    let dejaDansLePescedex: Set<String>
    /// Les espèces relevées dans la zone du pêcheur : elles passent d'abord.
    let especesDeLaZone: Set<String>
    /// Crée la carte déclarée de l'espèce choisie.
    let choisir: (EspecePechable) async -> Void
    /// « La prendre en photo ». Tant que c'est `nil`, le bouton n'est pas affiché.
    var photographier: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var tailleTexte
    @State private var recherche = ""
    @State private var enCours = false

    private var visibles: [EspecePechable] {
        FiltreDeclaration.especes(especes, recherche: recherche, deLaZone: especesDeLaZone)
    }

    /// Une seule colonne aux plus grandes tailles de texte, sinon des tuiles d'au moins 150 pt.
    private var colonnes: [GridItem] {
        tailleTexte.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 150), spacing: Espace.m)]
    }

    var body: some View {
        VStack(spacing: Espace.s) {
            enTete
            champRecherche
            grille
            if let photographier {
                Button {
                    dismiss()
                    // La grille finit de se fermer avant que la prise ne s'ouvre (deux présentations ne se chevauchent pas).
                    Task {
                        try? await Task.sleep(for: .milliseconds(400))
                        photographier()
                    }
                } label: {
                    Label("La prendre en photo", systemImage: "camera")
                }
                .buttonStyle(.secondaire)
                .padding(.horizontal, Espace.bord)
                .padding(.bottom, Espace.l)
            }
        }
        .background(Palette.fond.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            BoutonRond(role: .fermer, rendu: .verre).padding(Espace.bord)
        }
        .interactiveDismissDisabled(enCours)
    }

    private var enTete: some View {
        Text("Déclarer un poisson déjà pêché")
            .font(Police.sousTitre)
            .foregroundStyle(Palette.encre)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile + Espace.bord * 2)
            .padding(.horizontal, Gabarit.zoneTactile + Espace.bord * 2)
            .accessibilityAddTraits(.isHeader)
    }

    private var champRecherche: some View {
        HStack(spacing: Espace.s) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.encreDouce)
                .accessibilityHidden(true)
            TextField("Chercher un poisson", text: $recherche)
                .font(Police.corps)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
        }
        .padding(.horizontal, Espace.m)
        .frame(minHeight: Gabarit.zoneTactile)
        .tuileFishMe()
        .padding(.horizontal, Espace.bord)
    }

    private var grille: some View {
        ScrollView {
            LazyVGrid(columns: colonnes, spacing: Espace.m) {
                ForEach(visibles, id: \.espece.id) { espece in
                    tuile(espece)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.s)
            if visibles.isEmpty {
                Text("Aucun poisson ne correspond.")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(Espace.xl)
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private func tuile(_ espece: EspecePechable) -> some View {
        let deja = dejaDansLePescedex.contains(espece.espece.id)
        return Button {
            toucher(espece)
        } label: {
            VStack(spacing: Espace.s) {
                Image(espece.image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .opacity(deja ? 0.45 : 1)
                    .accessibilityHidden(true)
                HStack(spacing: Espace.xs) {
                    Text(espece.nom)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encre)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    if deja {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Palette.marine)
                            .accessibilityHidden(true)
                    }
                }
            }
            .padding(Espace.m)
            .frame(maxWidth: .infinity, minHeight: 88)
            .tuileFishMe(rayon: Rayon.m)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(deja || enCours)
        .accessibilityLabel(deja ? "\(espece.nom), déjà dans ton Pescedex" : espece.nom)
    }

    private func toucher(_ espece: EspecePechable) {
        guard !enCours else { return }
        enCours = true
        Task {
            await choisir(espece)
            enCours = false
            dismiss()
        }
    }
}

#if DEBUG
#Preview("Déclarer un poisson") {
    DeclarationView(
        especes: [
            EspecePechable(espece: Espece(id: "sandre"), nom: "Sandre", nomLatin: "Sander lucioperca", image: "sandre"),
            EspecePechable(espece: Espece(id: "brochet"), nom: "Brochet", nomLatin: "Esox lucius", image: "brochet"),
            EspecePechable(espece: Espece(id: "gardon"), nom: "Gardon", nomLatin: "Rutilus rutilus", image: "gardon"),
        ],
        dejaDansLePescedex: ["gardon"],
        especesDeLaZone: ["brochet"],
        choisir: { _ in },
        photographier: {})
}
#endif
