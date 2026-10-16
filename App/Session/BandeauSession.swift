import SwiftUI
import Core

/// « Commencer une session » : A le place sur la carte et appelle `moteur.commencer(...)` dans l'action.
struct BoutonCommencerSession: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Commencer une session", systemImage: "figure.fishing")
        }
        .buttonStyle(.principal)
    }
}

/// Le bandeau de la session en cours. `ligneConditions` est l'emplacement de L12 (vide par défaut) : elle disparaît
/// aux tailles de texte d'accessibilité et ne passe jamais devant le chrono, la fin légale ni « Ajouter une prise ».
struct BandeauSession<LigneConditions: View>: View {
    let moteur: SuiviSession
    let ajouterPrise: () -> Void
    let ligneConditions: LigneConditions
    @Environment(\.dynamicTypeSize) private var tailleTexte
    @State private var explicationFin = false

    init(moteur: SuiviSession, ajouterPrise: @escaping () -> Void,
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
        // P14 C « Sujet » : le chrono en grand, la fin légale dessous, puis les prises et un seul bouton principal.
        VStack(spacing: Espace.m) {
            Text(Self.formater(moteur.duree(a: maintenant)))
                .font(Police.taille(64, .heavy).monospacedDigit())
                .foregroundStyle(Palette.encre)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            if let legale = session.finLegale {
                Button { explicationFin.toggle() } label: {
                    VStack(spacing: Espace.xs) {
                        Text("Fin légale \(Self.heure(legale))")
                            .font(Police.sousTitre.monospacedDigit())
                            .foregroundStyle(Palette.encreDouce)
                        if legale > maintenant {
                            Text("encore \(Self.reste(legale.timeIntervalSince(maintenant)))")
                                .font(Police.legende)
                                .foregroundStyle(Palette.encreDouce)
                        }
                    }
                    .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Touche pour lire d'où vient cette heure")
            }
            if explicationFin, let legale = session.finLegale {
                Text(Self.explication(legale))
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            Text(moteur.nombrePrises == 0 ? "0 prise" : "\(moteur.nombrePrises) prise\(moteur.nombrePrises > 1 ? "s" : "")")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
            ForEach(session.messages, id: \.self) { AvisSession(texte: $0) }
            if moteur.quotaAtteint {
                AvisSession(texte: "Quota du jour atteint")
            }
            if !tailleTexte.isAccessibilitySize {
                ligneConditions
            }
            Button(action: ajouterPrise) {
                Label("Ajouter une prise", systemImage: "camera.fill")
            }
            .buttonStyle(.principal)
            Button("Terminer la session", role: .cancel) { moteur.terminer() }
                .font(Police.corps)
                .foregroundStyle(Palette.marine)
                .frame(minHeight: Gabarit.zoneTactile)
        }
        .padding(Espace.l)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .accessibilityElement(children: .contain)
        .onChange(of: maintenant) { _, _ in moteur.verifierFin() }
    }

    static func formater(_ secondes: TimeInterval) -> String {
        let total = Int(secondes)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    /// « 1 h 12 » ou « 12 min » (arrondi à la minute inférieure, au moins 1 min).
    static func reste(_ secondes: TimeInterval) -> String {
        let minutes = max(1, Int(secondes) / 60)
        let h = minutes / 60, m = minutes % 60
        return h > 0 ? "\(h) h \(String(format: "%02d", m))" : "\(m) min"
    }

    /// Le coucher se déduit de la fin légale (coucher + 30 min − 1 min de marge, constantes de `MoteurSoleil`).
    static func explication(_ finLegale: Date) -> String {
        let decalage = (MoteurSoleil.prolongationLegaleMin - MoteurSoleil.margeDeSecuriteMin) * 60
        let coucher = finLegale.addingTimeInterval(-decalage)
        return "Coucher du soleil \(heure(coucher)) + 30 min (article R436-13 du Code de l'environnement)"
    }

    static func heure(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }
}

extension BandeauSession where LigneConditions == EmptyView {
    init(moteur: SuiviSession, ajouterPrise: @escaping () -> Void) {
        self.init(moteur: moteur, ajouterPrise: ajouterPrise) { EmptyView() }
    }
}

struct AvisSession: View {
    let texte: String

    var body: some View {
        Text(texte)
            .font(Police.detail)
            .foregroundStyle(Palette.alerte)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

/// Pas de coordonnée connue : la session demande de toucher son point sur la carte (un point, jamais un département).
struct DemandePointSession: View {
    var body: some View {
        AvisSession(texte: "Touche ton point sur la carte pour commencer")
    }
}
