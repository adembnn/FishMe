import SwiftUI
import Core

/// « Choisir un autre spot » (E3) : un filtre d'espèce sur la carte, pas un nouvel écran.
/// Toutes les espèces pêchables en images, celles relevées près d'ici d'abord, avec une recherche par nom.
struct FiltreEspeceView: View {
    let pechables: [EspecePechable]
    let procheDIci: [Espece]
    let filtreActuel: EspecePechable?
    let choisir: (EspecePechable?) -> Void

    @State private var recherche = ""
    @State private var toutVoir = false
    @Environment(\.dismiss) private var dismiss

    /// Nombre d'espèces montrées avant « Voir les N autres espèces ».
    private let apercu = 6

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.l) {
                    VStack(alignment: .leading, spacing: Espace.xs) {
                        Text("Quel poisson ?")
                            .font(Police.grandTitre)
                            .foregroundStyle(Palette.encre)
                            .accessibilityAddTraits(.isHeader)
                        Text("La carte garde les tronçons où il a été relevé.")
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                    }
                    if filtreActuel != nil {
                        Button("Retirer le filtre") { choisir(nil) }
                            .buttonStyle(.secondaire)
                    }
                    if correspondantes.isEmpty {
                        Text("Aucune espèce ne porte ce nom.")
                            .font(Police.corps)
                            .foregroundStyle(Palette.encreDouce)
                    } else {
                        carte(visibles)
                        if cachees > 0 {
                            Button { withAnimation(.snappy) { toutVoir = true } } label: {
                                HStack {
                                    Text("Voir les \(cachees) autres espèces")
                                        .font(Police.corps)
                                        .foregroundStyle(Palette.marine)
                                    Spacer(minLength: Espace.s)
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Palette.silhouette)
                                        .accessibilityHidden(true)
                                }
                                .padding(Espace.l)
                                .frame(minHeight: Gabarit.zoneTactile)
                                .tuileFishMe(rayon: Rayon.l)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(Espace.bord)
            }
            .scrollIndicators(.hidden)
            .background(Palette.fond)
            .navigationTitle("Quel poisson ?")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $recherche, prompt: "Chercher une espèce")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    /// Les espèces relevées près d'ici d'abord, puis les autres.
    private var ordonnees: [EspecePechable] { proches + autres }

    private var enRecherche: Bool { !recherche.trimmingCharacters(in: .whitespaces).isEmpty }

    private var visibles: [EspecePechable] {
        (toutVoir || enRecherche) ? ordonnees : Array(ordonnees.prefix(apercu))
    }

    private var cachees: Int { (toutVoir || enRecherche) ? 0 : max(0, ordonnees.count - apercu) }

    private var correspondantes: [EspecePechable] {
        let terme = recherche.trimmingCharacters(in: .whitespaces)
        guard !terme.isEmpty else { return pechables }
        return pechables.filter { $0.nom.localizedStandardContains(terme) || $0.nomLatin.localizedStandardContains(terme) }
    }

    private var proches: [EspecePechable] {
        let ids = Set(procheDIci.map(\.id))
        return correspondantes.filter { ids.contains($0.espece.id) }
    }

    private var autres: [EspecePechable] {
        let ids = Set(procheDIci.map(\.id))
        return correspondantes.filter { !ids.contains($0.espece.id) }
    }

    /// Une carte blanche : une ligne par espèce, l'image à gauche, le nom, une coche sur le filtre actuel.
    private func carte(_ especes: [EspecePechable]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(especes.enumerated()), id: \.element.espece.id) { index, e in
                Button { choisir(e) } label: {
                    HStack(spacing: Espace.m) {
                        ImageEspeceCarte(nom: e.image)
                            .frame(width: 56, height: 36)
                        Text(e.nom)
                            .font(Police.sousTitre)
                            .foregroundStyle(Palette.encre)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        // À brancher : la rareté de l'espèce sous le nom (le filtre ne reçoit pas encore de rareté).
                        Spacer(minLength: Espace.s)
                        if filtreActuel?.espece == e.espece {
                            Image(systemName: "checkmark.circle.fill")
                                .font(Police.titre)
                                .foregroundStyle(Palette.marine)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.vertical, Espace.s)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(e.nom)
                .accessibilityAddTraits(filtreActuel?.espece == e.espece ? .isSelected : [])
                if index < especes.count - 1 { Divider().overlay(Palette.filet) }
            }
        }
        .padding(.horizontal, Espace.l)
        .tuileFishMe(rayon: Rayon.l)
    }
}
