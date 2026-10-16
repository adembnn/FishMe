import SwiftUI

// Cible APP seulement (comme PontAquariumWidget.swift). Après la 1re prise, une seule fois : comment mettre
// « Mon aquarium » sur l'écran d'accueil (Adem, 16 oct. : « comment l'utilisateur met le widget ? »).
// À brancher dans RootView (A) : `.astuceAjouterWidget(prises: <nombre de vraies prises>)` sur la vue racine.

extension View {
    /// Montre l'astuce la première fois que `prises` passe à 1 ou plus, puis plus jamais.
    func astuceAjouterWidget(prises: Int) -> some View {
        modifier(AstuceAjouterWidget(prises: prises))
    }
}

private struct AstuceAjouterWidget: ViewModifier {
    let prises: Int
    @AppStorage("FishMeAstuceWidgetVue") private var dejaVue = false
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .onChange(of: prises, initial: true) { _, n in
                if n > 0 && !dejaVue {
                    dejaVue = true
                    visible = true
                }
            }
            .sheet(isPresented: $visible) {
                FeuilleAstuceWidget { visible = false }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
    }
}

/// Trois gestes, des icônes, peu de mots.
struct FeuilleAstuceWidget: View {
    var fermer: () -> Void

    private let etapes: [(icone: String, texte: String)] = [
        ("hand.tap.fill", "Appuie longuement sur ton écran d'accueil"),
        ("plus.circle.fill", "Touche « Modifier », puis « Ajouter un widget »"),
        ("fish.fill", "Cherche FishMe et choisis « Mon aquarium »"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Ta prise nage sur ton écran d'accueil")
                .font(.system(.title3, design: .rounded, weight: .bold))
            ForEach(Array(etapes.enumerated()), id: \.offset) { _, etape in
                HStack(spacing: 14) {
                    Image(systemName: etape.icone)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Color(red: 0x0D / 255, green: 0x4A / 255, blue: 0x85 / 255))
                        .frame(width: 34)
                    Text(etape.texte)
                        .font(.system(.body, design: .rounded, weight: .bold))
                }
            }
            Button(action: fermer) {
                Text("Compris")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0x0D / 255, green: 0x4A / 255, blue: 0x85 / 255))
        }
        .padding(24)
    }
}

#Preview {
    FeuilleAstuceWidget {}
}
