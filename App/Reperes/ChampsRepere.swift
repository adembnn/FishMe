import Core
import SwiftUI

/// Nom, icône et note : la partie commune de « Nouveau repère » et « Modifier le repère ».
struct ChampsRepere: View {
    @Environment(\.locale) private var locale
    @Binding var nom: String
    @Binding var icone: IconeRepere
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.l) {
            VStack(alignment: .leading, spacing: Espace.xs) {
                Text(TextesReperes.t(TextesReperes.champNom, locale)).font(Police.legende).foregroundStyle(Palette.encreDouce)
                TextField(TextesReperes.t(TextesReperes.champNom, locale), text: $nom)
                    .font(Police.corps)
                    .submitLabel(.done)
                    .padding(.horizontal, Espace.m)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    .accessibilityLabel(TextesReperes.t(TextesReperes.champNom, locale))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Espace.s)], spacing: Espace.s) {
                ForEach(IconeRepere.allCases, id: \.self) { option in
                    Button { icone = option } label: {
                        HStack(spacing: Espace.s) {
                            IconeRepereView(type: option, taille: 24, suitLeTexte: true, decoratif: true)
                            Text(TextesReperes.libelle(option, locale: locale)).fixedSize(horizontal: false, vertical: true)
                        }
                        .font(Police.detail)
                        .foregroundStyle(Palette.encre)
                        .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                        .padding(.horizontal, Espace.s)
                        // Choisi : fond marine doux et contour marine (la goutte marine du poste disparaîtrait sur un fond marine).
                        .background(icone == option ? Palette.marineDoux : Palette.tuile,
                                    in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                        .overlay {
                            if icone == option {
                                RoundedRectangle(cornerRadius: Rayon.s, style: .continuous).stroke(Palette.marine, lineWidth: 2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(TextesReperes.libelle(option, locale: locale))
                    .accessibilityAddTraits(icone == option ? [.isSelected] : [])
                }
            }

            VStack(alignment: .leading, spacing: Espace.xs) {
                Text(TextesReperes.t(TextesReperes.champNote, locale)).font(Police.legende).foregroundStyle(Palette.encreDouce)
                TextField(TextesReperes.t(TextesReperes.champNote, locale), text: $note, axis: .vertical)
                    .font(Police.corps)
                    .lineLimit(3...8)
                    .padding(Espace.m)
                    .frame(minHeight: Gabarit.zoneTactile, alignment: .topLeading)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    .accessibilityLabel(TextesReperes.t(TextesReperes.champNote, locale))
                Text("\(note.count) / \(LimitesReperes.noteMax)")
                    .font(Police.legende)
                    .foregroundStyle(note.count > LimitesReperes.noteMax ? Palette.alerte : Palette.encreDouce)
            }
        }
    }
}
