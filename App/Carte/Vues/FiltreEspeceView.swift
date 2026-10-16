import SwiftUI
import Core

/// « Choisir un autre spot » (E3), page « Quel poisson ? » (P09 B) : un filtre d'espèce sur la carte, pas un nouvel écran.
/// Le total, 6 espèces en images avec leur rareté (celles relevées près d'ici d'abord), « Voir les N autres espèces »,
/// et un seul bouton principal « Afficher ». Un toucher choisit, « Afficher » applique le filtre sur la carte.
struct FiltreEspeceView: View {
    let pechables: [EspecePechable]
    let procheDIci: [Espece]
    let filtreActuel: EspecePechable?
    let choisir: (EspecePechable?) -> Void
    /// Rareté par identifiant d'espèce, dans le département du spot. Vide : la rareté n'est pas montrée.
    /// À brancher : `VueCarte` doit la passer (`services.especes.rarete(espece:departement:)` pour chaque espèce).
    var raretes: [String: NiveauRarete] = [:]

    @State private var toutVoir = false
    @State private var choisie: EspecePechable?
    @State private var initialise = false
    @Environment(\.dismiss) private var dismiss

    /// Nombre d'espèces montrées avant « Voir les N autres espèces ».
    private let apercu = 6

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                HStack {
                    BoutonRond(role: .fermer, rendu: .simple) { dismiss() }
                        .offset(x: -Espace.s)
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text("Quel poisson ?")
                        .font(Police.grandTitre)
                        .foregroundStyle(Palette.encre)
                        .accessibilityAddTraits(.isHeader)
                    Text("La carte garde les tronçons où il a été relevé.")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
                carte(visibles)
                if cachees > 0 {
                    Button { withAnimation(.snappy) { toutVoir = true } } label: {
                        HStack {
                            Text("Voir les \(cachees) autres espèces")
                                .font(Police.corps)
                                .foregroundStyle(Palette.marine)
                            Spacer(minLength: Espace.s)
                            Image(systemName: "chevron.right")
                                .font(Police.legende)
                                .foregroundStyle(Palette.silhouette)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, Espace.l)
                        .frame(minHeight: 56)
                        .tuileFishMe(rayon: Rayon.l)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.s)
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button {
                choisir(choisie)
                dismiss()
            } label: {
                Label("Afficher", systemImage: "map")
            }
            .buttonStyle(.principal)
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, Espace.s)
        }
        .onAppear {
            if !initialise {
                choisie = filtreActuel
                initialise = true
            }
        }
    }

    /// Les espèces relevées près d'ici d'abord, puis les autres.
    private var ordonnees: [EspecePechable] { proches + autres }

    private var visibles: [EspecePechable] {
        toutVoir ? ordonnees : Array(ordonnees.prefix(apercu))
    }

    private var cachees: Int { toutVoir ? 0 : max(0, ordonnees.count - apercu) }

    private var proches: [EspecePechable] {
        let ids = Set(procheDIci.map(\.id))
        return pechables.filter { ids.contains($0.espece.id) }
    }

    private var autres: [EspecePechable] {
        let ids = Set(procheDIci.map(\.id))
        return pechables.filter { !ids.contains($0.espece.id) }
    }

    /// Une forme par niveau, pour se lire sans la couleur.
    private func symbole(_ niveau: NiveauRarete) -> String {
        switch niveau {
        case .commun, .nonMesuree: return "circle.fill"
        case .peuCommun: return "hexagon.fill"
        case .rare: return "diamond.fill"
        case .legendaire: return "star.fill"
        }
    }

    /// Une carte blanche : « Toutes les espèces » et leur nombre, puis une ligne par espèce (image, nom, rareté, coche).
    private func carte(_ especes: [EspecePechable]) -> some View {
        VStack(spacing: 0) {
            Button { choisie = nil } label: {
                HStack {
                    Text("Toutes les espèces")
                        .font(Police.corps)
                        .foregroundStyle(Palette.encre)
                    Spacer(minLength: Espace.s)
                    if choisie == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .font(Police.titre)
                            .foregroundStyle(Palette.marine)
                            .accessibilityHidden(true)
                    } else {
                        Text("\(ordonnees.count)")
                            .font(Police.corps)
                            .foregroundStyle(Palette.encreDouce)
                    }
                }
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(choisie == nil ? .isSelected : [])
            ForEach(especes, id: \.espece.id) { e in
                Divider().overlay(Palette.filet)
                ligne(e)
            }
        }
        .padding(.horizontal, Espace.l)
        .tuileFishMe(rayon: Rayon.l)
    }

    private func ligne(_ e: EspecePechable) -> some View {
        let estChoisie = choisie?.espece == e.espece
        let niveau = raretes[e.espece.id]
        return Button { choisie = estChoisie ? nil : e } label: {
            HStack(spacing: Espace.m) {
                ImageEspeceCarte(nom: e.image)
                    .frame(width: 56, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.nom)
                        .font(Police.corps)
                        .foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let niveau, niveau != .nonMesuree {
                        Label(niveau.libelle, systemImage: symbole(niveau))
                            .font(Police.detail)
                            .foregroundStyle(CouleursCarte.rarete(niveau))
                    }
                }
                Spacer(minLength: Espace.s)
                if estChoisie {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Police.titre)
                        .foregroundStyle(Palette.marine)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, Espace.s)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(e.nom + ((niveau.map { $0 == .nonMesuree ? "" : ", " + $0.libelle }) ?? ""))
        .accessibilityAddTraits(estChoisie ? .isSelected : [])
    }
}
