import ActivityKit
import SwiftUI
import WidgetKit

// Cible widget seulement. Les 4 présentations : écran verrouillé, Dynamic Island compacte, étendue, minimale.
// Peu de texte (règle de la démo) : une icône, un chiffre, une heure.

private func heure(_ date: Date) -> Text {
    Text(date, format: .dateTime.hour().minute())
}

/// Le cœur : compte à rebours natif, ou texte fixe.
private struct Decompte: View {
    let etat: EtatSession
    let perime: Bool
    var long = true

    var body: some View {
        switch etat.affichage(maintenant: .now, perime: perime) {
        case .compteARebours(let fin):
            VStack(alignment: .leading, spacing: 0) {
                if long { Text("fin légale dans").font(.caption).foregroundStyle(.secondary) }
                Text(timerInterval: etat.debut...fin, pauseTime: nil, countsDown: true, showsHours: true)
                    .monospacedDigit()
            }
        case .finLegale(let fin):
            VStack(alignment: .leading, spacing: 0) {
                Text("fin légale")
                    .font(long ? .caption : .caption2).foregroundStyle(.secondary)
                heure(fin).monospacedDigit()
            }
        case .pecheFermee:
            Text("pêche fermée")
        case .finInconnue(let depuis):
            VStack(alignment: .leading, spacing: 0) {
                if long { Text("en session").font(.caption).foregroundStyle(.secondary) }
                Text(depuis, style: .timer).monospacedDigit()
            }
        }
    }
}

private struct NombrePrises: View {
    let prises: Int
    var body: some View {
        Label("\(prises)", systemImage: "fish")
            .accessibilityLabel("\(prises) prises")
    }
}

struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            // Écran verrouillé
            HStack {
                Decompte(etat: context.state, perime: context.isStale)
                    .font(.title2.weight(.semibold))
                Spacer()
                NombrePrises(prises: context.state.prises)
                    .font(.title2)
            }
            .padding()
            .activityBackgroundTint(nil)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    NombrePrises(prises: context.state.prises).font(.title3)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Decompte(etat: context.state, perime: context.isStale, long: false)
                        .font(.title3.weight(.semibold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if case .compteARebours(let fin) = context.state.affichage(maintenant: .now, perime: context.isStale) {
                        HStack(spacing: 4) { Text("fin légale"); heure(fin) }
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "fish")
            } compactTrailing: {
                switch context.state.affichage(maintenant: .now, perime: context.isStale) {
                case .compteARebours(let fin):
                    Text(timerInterval: context.state.debut...fin, pauseTime: nil, countsDown: true, showsHours: true)
                        .monospacedDigit().frame(maxWidth: 56)
                case .finLegale(let fin):
                    heure(fin).monospacedDigit()
                case .pecheFermee:
                    Image(systemName: "nosign")
                case .finInconnue(let depuis):
                    Text(depuis, style: .timer).monospacedDigit().frame(maxWidth: 56)
                }
            } minimal: {
                Image(systemName: "fish")
            }
        }
    }
}
