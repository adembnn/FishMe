import Core
import SwiftUI

/// Nom, icône et note : la partie commune de « Nouveau repère » et « Modifier le repère ».
struct ChampsRepere: View {
    @Binding var nom: String
    @Binding var icone: IconeRepere
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.l) {
            VStack(alignment: .leading, spacing: Espace.xs) {
                Text(TextesReperes.champNom).font(Police.legende).foregroundStyle(Palette.encreDouce)
                TextField(TextesReperes.champNom, text: $nom)
                    .font(Police.corps)
                    .submitLabel(.done)
                    .padding(.horizontal, Espace.m)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    .accessibilityLabel(TextesReperes.champNom)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Espace.s)], spacing: Espace.s) {
                ForEach(IconeRepere.allCases, id: \.self) { option in
                    Button { icone = option } label: {
                        HStack(spacing: Espace.s) {
                            Image(systemName: TextesReperes.symbole(option)).accessibilityHidden(true)
                            Text(TextesReperes.libelle(option)).fixedSize(horizontal: false, vertical: true)
                        }
                        .font(Police.detail)
                        .foregroundStyle(icone == option ? Palette.surMarine : Palette.encre)
                        .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                        .padding(.horizontal, Espace.s)
                        .background(icone == option ? Palette.marine : Palette.tuile,
                                    in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(TextesReperes.libelle(option))
                    .accessibilityAddTraits(icone == option ? [.isSelected] : [])
                }
            }

            VStack(alignment: .leading, spacing: Espace.xs) {
                Text(TextesReperes.champNote).font(Police.legende).foregroundStyle(Palette.encreDouce)
                TextField(TextesReperes.champNote, text: $note, axis: .vertical)
                    .font(Police.corps)
                    .lineLimit(3...8)
                    .padding(Espace.m)
                    .frame(minHeight: Gabarit.zoneTactile, alignment: .topLeading)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    .accessibilityLabel(TextesReperes.champNote)
                Text("\(note.count) / \(LimitesReperes.noteMax)")
                    .font(Police.legende)
                    .foregroundStyle(note.count > LimitesReperes.noteMax ? Palette.alerte : Palette.encreDouce)
            }
        }
    }
}
