import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

// Cible widget seulement. Les 4 présentations : écran verrouillé, Dynamic Island compacte, étendue, minimale.
// Peu de texte (règle de la démo) : une icône, un chiffre, une heure.
// `Widget/` n'importe pas `App/Style` : les deux couleurs de la palette « Marine » sont répétées ici (Adem, 15 oct. 18h30).
// Aucune coordonnée, aucun nom de coin : l'écran verrouillé est vu par d'autres.

private enum Teintes {
    static let marine = Color(red: 13 / 255, green: 74 / 255, blue: 133 / 255)   // #0D4A85
    static let alerte = Color(red: 232 / 255, green: 87 / 255, blue: 28 / 255)   // #E8571C, alertes seulement
}

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
                if long { Text("fin légale dans").font(.caption).opacity(0.75) }
                Text(timerInterval: etat.debut...fin, pauseTime: nil, countsDown: true, showsHours: true)
                    .monospacedDigit()
            }
        case .finLegale(let fin):
            VStack(alignment: .leading, spacing: 0) {
                Text("fin légale")
                    .font(long ? .caption : .caption2).opacity(0.75)
                heure(fin).monospacedDigit()
            }
        case .pecheFermee:
            Label("pêche fermée", systemImage: "nosign")
                .foregroundStyle(Teintes.alerte)
        case .finInconnue(let depuis):
            VStack(alignment: .leading, spacing: 0) {
                if long { Text("en session").font(.caption).opacity(0.75) }
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

private func rond(_ taille: CGFloat, _ poids: Font.Weight = .heavy) -> Font {
    .system(size: taille, weight: poids, design: .rounded)
}

/// Écran verrouillé : en-tête (app, prises), durée écoulée à gauche, fin légale à droite.
/// Le lieu de la maquette n'est pas là (pas de nom de coin sur l'écran verrouillé).
private struct EcranVerrouille: View {
    let etat: EtatSession
    let perime: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("FishMe", systemImage: "fish.fill")
                    .font(rond(15))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(etat.prises == 1 ? "1 prise" : "\(etat.prises) prises")
                    .font(rond(15))
                    .foregroundStyle(.white.opacity(0.85))
            }
            HStack(alignment: .bottom) {
                Text(etat.debut, style: .timer)
                    .font(rond(36))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                FinLegale(etat: etat, perime: perime)
            }
            BoutonsSession().padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

/// Boutons de la maquette P15 A : « Prise » (marine, appareil photo) et « Pause » (gris).
private struct BoutonsSession: View {
    var body: some View {
        HStack(spacing: 10) {
            Button(intent: PrendrePriseIntent()) {
                Label("Prise", systemImage: "camera.fill")
                    .font(rond(17))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(Capsule().fill(Teintes.marine))
            }
            // « Pause » (maquette) : caché tant que le moteur de session n'a pas de vraie pause,
            // pour ne jamais montrer un bouton qui ne fait rien. `PauseSessionIntent` est prêt.
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }
}

private struct FinLegale: View {
    let etat: EtatSession
    let perime: Bool

    var body: some View {
        Group {
            switch etat.affichage(maintenant: .now, perime: perime) {
            case .pecheFermee:
                Label("pêche fermée", systemImage: "nosign")
                    .font(rond(15))
                    .foregroundStyle(Teintes.alerte)
            case .compteARebours(let fin), .finLegale(let fin):
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Fin légale")
                        .font(rond(13, .bold))
                        .foregroundStyle(.white.opacity(0.7))
                    heure(fin)
                        .font(rond(22))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
            case .finInconnue:
                EmptyView()
            }
        }
    }
}

struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionActivityAttributes.self) { context in
            // Écran verrouillé (maquette P15 A)
            EcranVerrouille(etat: context.state, perime: context.isStale)
                .activityBackgroundTint(Color(white: 0.14, opacity: 0.78))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    NombrePrises(prises: context.state.prises).font(.title3)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Decompte(etat: context.state, perime: context.isStale, long: false)
                        .font(.title3)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if case .compteARebours(let fin) = context.state.affichage(maintenant: .now, perime: context.isStale) {
                        HStack(spacing: 4) { Text("fin légale"); heure(fin) }
                            .font(.caption).opacity(0.75)
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
                    Image(systemName: "nosign").foregroundStyle(Teintes.alerte)
                case .finInconnue(let depuis):
                    Text(depuis, style: .timer).monospacedDigit().frame(maxWidth: 56)
                }
            } minimal: {
                Image(systemName: "fish")
            }
        }
    }
}
