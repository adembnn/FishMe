#if DEBUG
import SwiftUI
import WidgetKit

// DEBUG seulement. Vérifier l'animation du widget aquarium SANS l'écran d'accueil : la même vue que le widget
// (VueAquariumWidget, ses 160 copies et ses masques chronos) affichée en plein écran dans l'app, où les chronos
// tournent comme dans l'hôte des widgets. Lancer l'app avec `-FishMeApercuWidget YES`, puis filmer :
//   xcrun simctl launch booted ai.mwm.build.challenge.team.01 -FishMeApercuWidget YES
//   xcrun simctl io booted recordVideo --codec=h264 reports/ecrans/L15/nage.mp4   (Ctrl-C après 12 s)
// ou deux captures à 0,5 s d'écart (`xcrun simctl io booted screenshot a.png`, puis b.png) : elles doivent différer.
// La ligne du bas donne la copie que le calcul attend à l'écran (HorlogeAnimation.imageVisible), pour comparer.

struct ApercuAnimationAquarium: View {
    /// Date de l'entrée, fixée à l'ouverture comme une entrée de timeline.
    @State private var entree = EntreeAquarium.exempleRendu(pro: true, date: .now)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VueAquariumWidget(entree: entree, famille: .systemSmall, fondVisible: true)
                    .frame(width: 170, height: 170)
                    .clipShape(.rect(cornerRadius: 22))
                VueAquariumWidget(entree: entree, famille: .systemMedium, fondVisible: true)
                    .frame(width: 364, height: 170)
                    .clipShape(.rect(cornerRadius: 22))
                VueAquariumWidget(entree: entree, famille: .systemLarge, fondVisible: true)
                    .frame(width: 364, height: 382)
                    .clipShape(.rect(cornerRadius: 22))
                TimelineView(.periodic(from: .now, by: 1.0 / Double(HorlogeAnimation.imagesParSeconde))) { contexte in
                    let reference = HorlogeAnimation.reference(pour: entree.date)
                    Text("copie attendue \(HorlogeAnimation.imageVisible(reference: reference, a: contexte.date)) · polices \(PolicesMasque.disponibles ? "ok" : "KO")")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
}

extension View {
    /// Avec `-FishMeApercuWidget YES` (DEBUG), affiche l'aperçu animé du widget aquarium par-dessus l'app.
    /// Une ligne dans RootView : `.apercuWidgetSiDemande()`.
    func apercuWidgetSiDemande() -> some View {
        overlay {
            if UserDefaults.standard.bool(forKey: "FishMeApercuWidget") {
                ApercuAnimationAquarium()
                    .background(Color(.systemBackground))
            }
        }
    }
}

#Preview("Aquarium animé (vue du widget)") {
    ApercuAnimationAquarium()
}
#endif
