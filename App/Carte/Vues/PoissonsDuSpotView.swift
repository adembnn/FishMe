import SwiftUI
import Core

/// Tous les poissons du spot (Adem, 16 oct. : « je peux cliquer sur aucun des poissons, ni sur + 14 »).
/// S'ouvre d'un toucher sur un poisson ou sur « + N » de la feuille « Ton spot » : une grille d'images avec la marque de rareté ;
/// le poisson touché s'affiche en haut avec ses relevés OFB (N pêches et année), son ouverture du jour et le premier conseil (L13).
struct PoissonsDuSpotView: View {
    @Environment(\.locale) private var locale
    let lieu: String
    let lignes: [LigneEspece]
    let pechable: (Espece) -> EspecePechable?
    let emplacementConseil: (Espece) -> AnyView
    @State var touchee: Espece?

    private let colonnes = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Poissons du spot")
                            .font(Police.taille(22, .heavy))
                            .foregroundStyle(Palette.encre)
                            .accessibilityAddTraits(.isHeader)
                        Text(lieu)
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                            .lineLimit(1)
                    }
                    Spacer(minLength: Espace.s)
                    BoutonRond(role: .fermer)
                }
                if let touchee, let ligne = lignes.first(where: { $0.espece == touchee }) {
                    detail(ligne)
                }
                LazyVGrid(columns: colonnes, spacing: 12) {
                    ForEach(lignes) { ligne in tuile(ligne) }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Palette.surface.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func detail(_ ligne: LigneEspece) -> some View {
        let fiche = pechable(ligne.espece)
        return VStack(alignment: .leading, spacing: 10) {
            RangeeEspece(nom: fiche?.nom ?? ligne.espece.id, image: fiche?.image, nPeches: ligne.nPeches,
                         annee: ligne.annee, rarete: ligne.rarete, ouverture: ligne.ouverture,
                         selectionnee: true, releve: ligne.releve)
            if let mini = ligne.tailleMiniCm {
                Label("Taille minimale : \(mini) cm", systemImage: "ruler")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                    .padding(.horizontal, 8)
            }
            emplacementConseil(ligne.espece)
        }
        .transition(.opacity)
    }

    private func tuile(_ ligne: LigneEspece) -> some View {
        let fiche = pechable(ligne.espece)
        let niveau: NiveauRarete = ligne.rarete?.niveau ?? .nonMesuree
        let choisie = touchee == ligne.espece
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { touchee = choisie ? nil : ligne.espece }
        } label: {
            VStack(spacing: 6) {
                ImageEspeceCarte(nom: fiche?.image)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(height: 64)
                    .background(choisie ? Palette.marineDoux : Palette.tuile,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topTrailing) {
                        if niveau != .nonMesuree {
                            Image(systemName: niveau.symboleSF)
                                .font(Police.taille(11, .heavy))
                                .foregroundStyle(CouleursCarte.rarete(niveau))
                                .padding(6)
                        }
                    }
                Text(fiche?.nom ?? ligne.espece.id)
                    .font(Police.taille(12, .bold))
                    .foregroundStyle(Palette.encre)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fiche?.nom ?? ligne.espece.id)
        .accessibilityValue(niveau == .nonMesuree ? "" : niveau.libelle(locale: locale))
    }
}
