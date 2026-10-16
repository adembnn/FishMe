import Core
import SwiftUI

/// E1 / P01 (direction C) : la seule question du premier lancement. Icône et nom FishMe, « Tu pêches depuis… »,
/// trois pastilles rondes avec pictogramme (celle qui est touchée se remplit en marine), « Continuer », « Passer ».
struct QuestionNiveauView: View {
    let choisir: (NiveauPecheur) -> Void
    let passer: () -> Void

    @State private var selection: NiveauPecheur? = NiveauPecheur.parDefaut

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Maquette : icône de 168 pt (coins 38) avec son ombre, « FishMe » dessous, puis la question vers 56 % de la hauteur.
                // À brancher : la vraie icône de l'app (aucun asset image n'existe, seulement AppIcon.appiconset), le symbole reste.
                VStack(spacing: Espace.l) {
                    Image(systemName: "fish.fill")
                        .font(Police.taille(84, .heavy))
                        .foregroundStyle(Palette.surMarine)
                        .frame(width: 168, height: 168)
                        .background(Palette.nuit, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
                        .shadow(color: Palette.nuit.opacity(0.55), radius: 18, y: 14)
                        .accessibilityHidden(true)
                    Text("FishMe")
                        .font(Police.grandTitre)
                        .foregroundStyle(Palette.encre)
                }
                .padding(.top, Espace.xxl * 2)
                // Hauteur du bloc icône : 64 + 168 + 16 + environ 41.
                Spacer().frame(height: max(Espace.xl, geo.size.height * 0.56 - 290))
                Text("Tu pêches depuis…")
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                HStack(alignment: .top, spacing: Espace.s) {
                    ForEach([NiveauPecheur.debutant, .occasionnel, .confirme], id: \.self) { niveau in
                        pastille(niveau)
                    }
                }
                .padding(.top, Espace.xl)
                Spacer(minLength: Espace.l)
                // Pas de « Passer » dans la maquette : la feuille ne se ferme que par « Continuer » (niveau par défaut pré-choisi).
                Button("Continuer") {
                    if let selection { choisir(selection) }
                }
                .buttonStyle(.principal)
                .padding(.bottom, Espace.s)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.l)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Palette.surface.ignoresSafeArea())
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
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .top)
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
            .fullScreenCover(isPresented: $ouverte, onDismiss: { questionVue = true }) {
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
                .interactiveDismissDisabled()
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
