import SwiftUI

/// Le menu « ... » d'une publication ou d'un commentaire : Signaler et Bloquer l'auteur, ou Supprimer si c'est le mien.
struct MenuModeration: View {
    let estMien: Bool
    let onSignaler: (MotifSignalementPublication) -> Void
    let onBloquer: () -> Void
    let onSupprimer: () -> Void

    @State private var motifs = false
    @State private var confirmerBlocage = false

    var body: some View {
        Menu {
            if estMien {
                Button("Supprimer", systemImage: "trash", role: .destructive, action: onSupprimer)
            } else {
                Button("Signaler", systemImage: "flag") { motifs = true }
                Button("Bloquer l'auteur", systemImage: "nosign", role: .destructive) { confirmerBlocage = true }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encreDouce)
                .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Plus d'options")
        .sheet(isPresented: $motifs) {
            FeuilleMotifs { motif in
                motifs = false
                onSignaler(motif)
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Bloquer cet auteur ?", isPresented: $confirmerBlocage, titleVisibility: .visible) {
            Button("Bloquer", role: .destructive, action: onBloquer)
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Tu ne verras plus rien de lui.")
        }
    }
}

/// La liste fermée des motifs : une icône, un mot, pas de texte libre.
struct FeuilleMotifs: View {
    let choisir: (MotifSignalementPublication) -> Void

    var body: some View {
        NavigationStack {
            List(MotifSignalementPublication.allCases) { motif in
                Button {
                    choisir(motif)
                } label: {
                    Label(motif.titre, systemImage: motif.symbole)
                        .font(Police.corps)
                        .foregroundStyle(Palette.encre)
                        .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                }
                .listRowBackground(Palette.surface)
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(Palette.fond)
            .navigationTitle("Signaler")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Motifs") {
    FeuilleMotifs { _ in }
}
