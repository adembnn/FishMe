import SwiftUI

// Cible APP seulement (comme PontAquariumWidget.swift). Dès le 1er poisson du Pescedex, une seule fois, l'app
// demande « Mettre ton aquarium sur l'écran d'accueil ? » ; sur « Oui », elle montre les 3 gestes (Adem, 16 oct.).
// iOS n'a aucune API qui pose un widget à la place de l'utilisateur : on ne peut que lui montrer comment.
// Branché dans RootView (A) : `.astuceAjouterWidget(prises: <nombre de poissons du Pescedex>)` sur la vue racine.

extension View {
    /// Pose la question la première fois que `prises` passe à 1 ou plus, puis plus jamais.
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

/// D'abord la question, puis, sur « Oui », trois gestes avec des icônes et peu de mots.
struct FeuilleAstuceWidget: View {
    var fermer: () -> Void
    @State private var etapesVisibles = false
    private let marine = Color(red: 0x0D / 255, green: 0x4A / 255, blue: 0x85 / 255)

    private let etapes: [(icone: String, texte: String)] = [
        ("hand.tap.fill", "Appuie longuement sur ton écran d'accueil"),
        ("plus.circle.fill", "Touche « Modifier », puis « Ajouter un widget »"),
        ("fish.fill", "Cherche FishMe et choisis « Mon aquarium »"),
    ]

    var body: some View {
        Group {
            if etapesVisibles { listeEtapes } else { question }
        }
        .padding(24)
        .animation(.snappy, value: etapesVisibles)
    }

    private var question: some View {
        VStack(spacing: 20) {
            Image(systemName: "fish.fill")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(marine)
            Text("Mettre ton aquarium sur l'écran d'accueil ?")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
            Text("Tes poissons y nagent.")
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
            VStack(spacing: 10) {
                Button { etapesVisibles = true } label: {
                    Text("Oui").font(.system(.body, design: .rounded, weight: .bold)).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(marine)
                Button(action: fermer) {
                    Text("Plus tard").font(.system(.body, design: .rounded, weight: .bold)).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(marine)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var listeEtapes: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(etapes.enumerated()), id: \.offset) { _, etape in
                HStack(spacing: 14) {
                    Image(systemName: etape.icone)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(marine)
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
            .tint(marine)
        }
    }
}

#Preview {
    FeuilleAstuceWidget {}
}
