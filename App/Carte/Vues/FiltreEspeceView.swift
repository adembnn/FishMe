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
    /// `VueCarte` la calcule (`services.especes.rarete(espece:departement:)` pour chaque espèce).
    var raretes: [String: NiveauRarete] = [:]

    @State private var toutVoir = false
    @State private var choisie: EspecePechable?
    @State private var initialise = false
    @Environment(\.dismiss) private var dismiss

    /// Nombre d'espèces montrées avant « Voir les N autres espèces ».
    private let apercu = 6

    var body: some View {
        // Calculés une fois par affichage, pas à chaque ligne.
        let ordonnees = ordonneesCalculees()
        let visibles = toutVoir ? ordonnees : Array(ordonnees.prefix(apercu))
        let cachees = toutVoir ? 0 : max(0, ordonnees.count - apercu)
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    BoutonRond(role: .fermer, rendu: .simple) { dismiss() }
                        .offset(x: -Espace.s)
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quel poisson ?")
                        .font(Police.taille(34, .heavy))
                        .foregroundStyle(Palette.encre)
                        .accessibilityAddTraits(.isHeader)
                    Text("La carte garde les tronçons où il a été relevé.")
                        .font(Police.taille(15))
                        .foregroundStyle(Palette.encreDouce)
                }
                .padding(.top, 8)
                if procheDIci.isEmpty {
                    // État vide, hors maquette : rien n'est relevé près d'ici.
                    Label("Rien de relevé près d'ici", systemImage: "magnifyingglass")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                        .padding(.top, Espace.s)
                }
                carte(visibles, total: ordonnees.count)
                    .padding(.top, 20)
                if cachees > 0 {
                    Button { withAnimation(.snappy) { toutVoir = true } } label: {
                        HStack {
                            Text("Voir les \(cachees) autres espèces")
                                .font(Police.corps)
                                .foregroundStyle(Palette.marine)
                            Spacer(minLength: Espace.s)
                            Image(systemName: "chevron.right")
                                .font(Police.taille(13))
                                .foregroundStyle(Palette.silhouette)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, Espace.l)
                        .frame(minHeight: 56)
                        .tuileFishMe(rayon: Rayon.m)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.s)
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .presentationDragIndicator(.visible)
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

    /// Les espèces relevées près d'ici d'abord, puis les autres (un seul Set pour les deux).
    private func ordonneesCalculees() -> [EspecePechable] {
        let ids = Set(procheDIci.map(\.id))
        return pechables.filter { ids.contains($0.espece.id) } + pechables.filter { !ids.contains($0.espece.id) }
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
    /// Filets : inset de 16 sous la première ligne, de 84 (sous l'image) ensuite, comme la maquette.
    private func carte(_ especes: [EspecePechable], total: Int) -> some View {
        LazyVStack(spacing: 0) {
            ligneToutes(total: total)
            ForEach(especes, id: \.espece.id) { e in
                Divider().overlay(Palette.filet).padding(.leading, e.espece.id == especes.first?.espece.id ? 16 : 84)
                ligne(e)
            }
        }
        .tuileFishMe(rayon: Rayon.m)
    }

    private func ligneToutes(total: Int) -> some View {
        Button { choisie = nil } label: {
            HStack {
                Text("Toutes les espèces")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                Spacer(minLength: Espace.s)
                Text("\(total)")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encreDouce)
                if choisie == nil { coche }
            }
            .padding(.horizontal, Espace.l)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(choisie == nil ? .isSelected : [])
    }

    private var coche: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(Police.taille(24))
            .foregroundStyle(Palette.marine)
            .accessibilityHidden(true)
    }

    private func ligne(_ e: EspecePechable) -> some View {
        let estChoisie = choisie?.espece == e.espece
        let niveau = raretes[e.espece.id]
        return Button { choisie = estChoisie ? nil : e } label: {
            HStack(spacing: Espace.m) {
                ImageEspeceCarte(nom: e.image)
                    .frame(width: 56, height: 32)
                    .frame(width: 56, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.nom)
                        .font(Police.corps)
                        .foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let niveau, niveau != .nonMesuree {
                        HStack(spacing: 5) {
                            Image(systemName: symbole(niveau))
                                .font(Police.taille(13, .heavy))
                                .accessibilityHidden(true)
                            Text(niveau.libelle)
                                .font(Police.taille(13, .heavy))
                        }
                        .foregroundStyle(CouleursCarte.rarete(niveau))
                    }
                }
                Spacer(minLength: Espace.s)
                if estChoisie { coche }
            }
            .padding(.vertical, Espace.s)
            .padding(.horizontal, Espace.l)
            .frame(minHeight: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(e.nom + ((niveau.map { $0 == .nonMesuree ? "" : ", " + $0.libelle }) ?? ""))
        .accessibilityAddTraits(estChoisie ? .isSelected : [])
    }
}
