import SwiftUI
import Core

/// « Commencer une session » : A le place sur la carte et appelle `moteur.commencer(...)` dans l'action.
struct BoutonCommencerSession: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Commencer une session", systemImage: "figure.fishing")
                .font(JetonsSession.police(.headline))
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
        .tint(JetonsSession.vert)
        .controlSize(.large)
    }
}

/// Le bandeau de la session en cours. `ligneConditions` est l'emplacement de L12 (vide par défaut) : elle disparaît
/// aux tailles de texte d'accessibilité et ne passe jamais devant le chrono, la fin légale ni « Ajouter une prise ».
struct BandeauSession<LigneConditions: View>: View {
    let moteur: MoteurSession
    let ajouterPrise: () -> Void
    let ligneConditions: LigneConditions
    @Environment(\.dynamicTypeSize) private var tailleTexte

    init(moteur: MoteurSession, ajouterPrise: @escaping () -> Void,
         @ViewBuilder ligneConditions: () -> LigneConditions) {
        self.moteur = moteur
        self.ajouterPrise = ajouterPrise
        self.ligneConditions = ligneConditions()
    }

    var body: some View {
        if let session = moteur.enCours {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                contenu(session, maintenant: moteur.maintenant())
            }
        }
    }

    private func contenu(_ session: SessionEnCours, maintenant: Date) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(Self.formater(moteur.duree(a: maintenant)))
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy).monospacedDigit())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    if let legale = session.finLegale {
                        Text("Fin légale \(Self.heure(legale))")
                    }
                    Text(moteur.nombrePrises == 0 ? "0 prise" : "\(moteur.nombrePrises) prise\(moteur.nombrePrises > 1 ? "s" : "")")
                }
                .font(JetonsSession.police(.subheadline))
            }
            ForEach(session.messages, id: \.self) { AvisSession(texte: $0) }
            if moteur.quotaAtteint {
                AvisSession(texte: "Quota du jour atteint")
            }
            if !tailleTexte.isAccessibilitySize {
                ligneConditions
            }
            Button(action: ajouterPrise) {
                Label("Ajouter une prise", systemImage: "camera.fill")
                    .font(JetonsSession.police(.title3))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(JetonsSession.vert)
            Button("Terminer", role: .cancel) { moteur.terminer() }
                .font(JetonsSession.police(.subheadline))
                .frame(minHeight: 44)
        }
        .foregroundStyle(JetonsSession.marine)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .contain)
        .onChange(of: maintenant) { _, _ in moteur.verifierFin() }
    }

    static func formater(_ secondes: TimeInterval) -> String {
        let total = Int(secondes)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    static func heure(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }
}

extension BandeauSession where LigneConditions == EmptyView {
    init(moteur: MoteurSession, ajouterPrise: @escaping () -> Void) {
        self.init(moteur: moteur, ajouterPrise: ajouterPrise) { EmptyView() }
    }
}

struct AvisSession: View {
    let texte: String

    var body: some View {
        Text(texte)
            .font(JetonsSession.police(.subheadline))
            .foregroundStyle(JetonsSession.alerte)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Pas de coordonnée connue : la session demande de toucher son point sur la carte (un point, jamais un département).
struct DemandePointSession: View {
    var body: some View {
        AvisSession(texte: "Touche ton point sur la carte pour commencer")
    }
}
