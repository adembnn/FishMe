import Core
import SwiftUI

/// E1 : la seule question du premier lancement, en demi-écran par-dessus la carte. Trois images, « passer ».
struct QuestionNiveauView: View {
    let choisir: (NiveauPecheur) -> Void
    let passer: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Ton niveau ?")
                .font(JetonsConseils.police(.title2))
                .padding(.top, 24)
            HStack(spacing: 12) {
                ForEach([NiveauPecheur.debutant, .occasionnel, .confirme], id: \.self) { niveau in
                    Button { choisir(niveau) } label: {
                        VStack(spacing: 8) {
                            Image(systemName: niveau.pictogramme)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(JetonsConseils.accent)
                                .frame(maxWidth: .infinity, minHeight: 72)
                            Text(niveau.mot)
                                .font(JetonsConseils.police(.footnote))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, minHeight: JetonsConseils.tailleToucher)
                        .background(JetonsConseils.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(niveau.mot)
                }
            }
            Button("Passer", action: passer)
                .font(JetonsConseils.police(.body))
                .frame(minWidth: JetonsConseils.tailleToucher, minHeight: JetonsConseils.tailleToucher)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .accessibilityIdentifier("question-niveau")
    }
}

/// Le demi-écran : au premier lancement seulement, jamais bloquant (la carte reste utilisable derrière).
/// `declenchee` : A le passe à vrai quand la demande de position est passée (ordre fixé dans `RootView.swift`).
struct QuestionNiveauModifier: ViewModifier {
    let declenchee: Bool
    @AppStorage(ClesConseils.niveau) private var niveauBrut = NiveauPecheur.parDefaut.rawValue
    @AppStorage(ClesConseils.questionVue) private var questionVue = false
    @State private var ouverte = false

    func body(content: Content) -> some View {
        content
            .onAppear(perform: ouvrirSiBesoin)
            .onChange(of: declenchee) { ouvrirSiBesoin() }
            .sheet(isPresented: $ouverte, onDismiss: { questionVue = true }) {
                QuestionNiveauView(
                    choisir: { niveau in
                        niveauBrut = niveau.rawValue
                        ouverte = false
                    },
                    passer: {
                        niveauBrut = NiveauPecheur.parDefaut.rawValue
                        ouverte = false
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
    }

    private func ouvrirSiBesoin() {
        if declenchee && !questionVue { ouverte = true }
    }
}

extension View {
    /// `.questionNiveau(declenchee: positionDemandee)` sur la carte, dans `RootView.swift`.
    func questionNiveau(declenchee: Bool) -> some View {
        modifier(QuestionNiveauModifier(declenchee: declenchee))
    }
}
