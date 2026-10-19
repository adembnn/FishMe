import SwiftUI
import Core

/// La feuille « Règles du spot » : les règles du lieu du cercle, groupées (garder ou relâcher · horaires · matériel et pratique),
/// chaque ligne ouvre sa source. Le groupement est celui de `BlocReglesView` (L19, `App/Style/BlocRegles/`) : il n'est pas redessiné ici.
/// ⚠ `BlocReglesView` vient de la branche L19 : cette feuille ne compile qu'après la fusion de L19.
/// Les lignes viennent de `reglesDuJour` de `Core` ; rien n'est filtré ni ajouté, jamais de phrase d'autorisation.
struct ReglesDuSpotView: View {
    let services: ServicesCarte
    let spot: Spot
    let lieu: String
    let fermer: () -> Void
    @State private var fiche: FicheCalculee?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                HStack(alignment: .center, spacing: Espace.m) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Règles du spot")
                            .font(Police.titre)
                            .foregroundStyle(Palette.encre)
                            .accessibilityAddTraits(.isHeader)
                        Text(lieu)
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                            .lineLimit(2)
                    }
                    Spacer(minLength: Espace.s)
                    BoutonRond(role: .fermer, action: fermer)
                }
                if let fiche {
                    BlocReglesView(lignes: ReglesDuSpot.lignesDuLieu(fiche.lignes), consigne: ReglesDuSpot.consigne)
                    couverture(fiche.couverture)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .accessibilityLabel("Lecture des règles")
                }
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task(id: spot) {
            fiche = await calculerFiche(services: services, coordonnee: spot.centre, choix: nil, espece: nil, date: Date())
        }
    }

    /// « règles locales en partie » ou « non saisies », avec le lien de la fédération : la couverture se dit, rien n'est inventé.
    @ViewBuilder
    private func couverture(_ couverture: CouvertureLocale) -> some View {
        switch couverture {
        case .complete:
            EmptyView()
        case .partielle(let lien):
            infoCouverture("règles locales en partie", lien: lien)
        case .nonSaisie(let lien):
            infoCouverture("règles locales non saisies", lien: lien)
        }
    }

    private func infoCouverture(_ texte: String, lien: String?) -> some View {
        HStack(spacing: Espace.s) {
            Image(systemName: "info.circle")
                .accessibilityHidden(true)
            Text(texte)
                .fixedSize(horizontal: false, vertical: true)
            if let lien, let url = URL(string: lien) {
                Link("lien de la fédération", destination: url)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
        }
        .font(Police.legende)
        .foregroundStyle(CouleursCarte.attention)
    }
}
