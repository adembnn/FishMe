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
                Button(role: .destructive, action: onSupprimer) { Label { Text(c: "Supprimer") } icon: { Image(systemName: "trash") } }
            } else {
                Button { motifs = true } label: { Label { Text(c: "Signaler") } icon: { Image(systemName: "flag") } }
                Button(role: .destructive) { confirmerBlocage = true } label: { Label { Text(c: "Bloquer l'auteur") } icon: { Image(systemName: "nosign") } }
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encreDouce)
                .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text(c: "Plus d'options"))
        .sheet(isPresented: $motifs) {
            FeuilleMotifs { motif in
                motifs = false
                onSignaler(motif)
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(Text(c: "Bloquer cet auteur ?"), isPresented: $confirmerBlocage, titleVisibility: .visible) {
            Button(role: .destructive, action: onBloquer) { Text(c: "Bloquer") }
            Button(role: .cancel) {} label: { Text(c: "Annuler") }
        } message: {
            Text(c: "Tu ne verras plus rien de lui.")
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
                    Label { Text(c: motif.titre) } icon: { Image(systemName: motif.symbole) }
                        .font(Police.corps)
                        .foregroundStyle(Palette.encre)
                        .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                }
                .listRowBackground(Palette.surface)
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(Palette.fond)
            .navigationTitle(Text(c: "Signaler"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Motifs") {
    FeuilleMotifs { _ in }
}
