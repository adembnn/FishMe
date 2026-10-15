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
    @Environment(\.dismiss) private var dismiss

    private let colonnes = [GridItem(.adaptive(minimum: 96), spacing: 12, alignment: .top)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if filtreActuel != nil {
                        Button("Retirer le filtre") { choisir(nil) }
                            .font(PolicesCarte.corps())
                            .buttonStyle(.bordered)
                            .tint(CouleursCarte.accent)
                    }
                    if !proches.isEmpty {
                        section("Relevées près d'ici", especes: proches)
                    }
                    section(proches.isEmpty ? "Toutes les espèces" : "Les autres espèces", especes: autres)
                    if proches.isEmpty && autres.isEmpty {
                        Text("Aucune espèce ne porte ce nom.")
                            .font(PolicesCarte.corps())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Choisir un autre spot")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $recherche, prompt: "Chercher une espèce")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

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

    private func section(_ titre: String, especes: [EspecePechable]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titre)
                .font(PolicesCarte.legende())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            LazyVGrid(columns: colonnes, spacing: 14) {
                ForEach(especes, id: \.espece.id) { e in
                    Button { choisir(e) } label: {
                        VStack(spacing: 6) {
                            ImageEspece(nom: e.image)
                                .frame(height: 44)
                            Text(e.nom)
                                .font(PolicesCarte.legende())
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(filtreActuel?.espece == e.espece ? CouleursCarte.accent.opacity(0.15) : Color.primary.opacity(0.05),
                                    in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(e.nom)
                }
            }
        }
    }
}
