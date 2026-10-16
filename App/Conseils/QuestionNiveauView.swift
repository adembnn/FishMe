import Core
import SwiftUI

/// E1 / P01 (direction C) : la seule question du premier lancement. Icône et nom FishMe, « Tu pêches depuis… »,
/// trois pastilles rondes avec pictogramme (celle qui est touchée se remplit en marine), « Continuer », « Passer ».
struct QuestionNiveauView: View {
    let choisir: (NiveauPecheur) -> Void
    let passer: () -> Void

    @State private var selection: NiveauPecheur? = NiveauPecheur.parDefaut

    var body: some View {
        VStack(spacing: Espace.l) {
            Spacer(minLength: 0)
            VStack(spacing: Espace.m) {
                Image(systemName: "fish.fill")
                    .font(Police.taille(44, .heavy))
                    .foregroundStyle(Palette.surMarine)
                    .frame(width: 84, height: 84)
                    .background(Palette.nuit, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
                    .accessibilityHidden(true)
                Text("FishMe")
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
            }
            Spacer(minLength: 0)
            Text("Tu pêches depuis…")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
            HStack(alignment: .top, spacing: Espace.m) {
                ForEach([NiveauPecheur.debutant, .occasionnel, .confirme], id: \.self) { niveau in
                    pastille(niveau)
                }
            }
            Spacer(minLength: 0)
            Button("Continuer") {
                if let selection { choisir(selection) }
            }
            .buttonStyle(.principal)
            .disabled(selection == nil)
            .opacity(selection == nil ? 0.45 : 1)
            Button("Passer", action: passer)
                .font(Police.corps)
                .foregroundStyle(Palette.marine)
                .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.vertical, Espace.l)
        .background(Palette.fond)
        .accessibilityIdentifier("question-niveau")
    }

    private func phrase(_ niveau: NiveauPecheur) -> String {
        switch niveau {
        case .debutant: "Je débute"
        case .occasionnel: "Quelques sorties"
        case .confirme: "Depuis longtemps"
        }
    }

    private func pastille(_ niveau: NiveauPecheur) -> some View {
        let choisie = selection == niveau
        return Button { selection = niveau } label: {
            VStack(spacing: Espace.s) {
                Image(systemName: niveau.pictogramme)
                    .font(Police.taille(30, .bold))
                    .foregroundStyle(choisie ? Palette.surMarine : Palette.marine)
                    .frame(width: 76, height: 76)
                    .background(choisie ? Palette.marine : Palette.marineDoux, in: Circle())
                Text(phrase(niveau))
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(phrase(niveau))
        .accessibilityAddTraits(choisie ? .isSelected : [])
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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
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
