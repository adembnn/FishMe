import SwiftUI

/// Les conditions d'utilisation de FishMe, lisibles hors ligne (texte embarqué dans `TexteConditions`).
/// La vue se pousse dans une `NavigationStack` ou s'ouvre en feuille via `ConditionsFeuille` : pas de bouton retour maison.
struct ConditionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                Text("Conditions d'utilisation", tableName: AnglaisE.table)
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("Version du \(TexteConditions.version)", tableName: AnglaisE.table)
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.bottom, Espace.s)
                ForEach(TexteConditions.articles) { article in
                    VStack(alignment: .leading, spacing: Espace.s) {
                        Text(article.titre)
                            .font(Police.sousTitre)
                            .foregroundStyle(Palette.encre)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(Array(article.paragraphes.enumerated()), id: \.offset) { _, paragraphe in
                            Text(Self.rendu(paragraphe))
                                .font(Police.detail)
                                .foregroundStyle(Palette.encre)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.l)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Markdown en ligne (gras, liens) ; si l'analyse échoue, le texte brut.
    static func rendu(_ texte: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        if let rendu = try? AttributedString(markdown: texte, options: options) { return rendu }
        return AttributedString(texte)
    }
}

/// Les conditions dans une feuille : bouton « OK » en barre, qui ferme.
struct ConditionsFeuille: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ConditionsView()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("OK") { dismiss() }
                    }
                }
        }
    }
}

#if DEBUG
#Preview {
    ConditionsFeuille()
}
#endif
