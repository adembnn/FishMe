// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
import SwiftUI

/// Écran provisoire commun aux dossiers `Features/*` tant que leur vraie vue n'existe pas.
/// Chaque dossier a sa propre vue placeholder qui s'appuie dessus ; à remplacer lot par lot.
struct PlaceholderScreen: View {
    let title: String
    let symbol: String
    var detail: String = "Écran à venir."

    private var theme: Theme { Theme.current }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            ContentUnavailableView {
                Label(title, systemImage: symbol)
                    .fontDesign(theme.fontDesign)
            } description: {
                Text(detail)
            }
            .foregroundStyle(theme.textPrimary)
        }
    }
}

#Preview {
    PlaceholderScreen(title: "Exemple", symbol: "fish")
}
