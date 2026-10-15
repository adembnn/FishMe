import Core
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// « Choisir un autre spot » : l'espèce en images, puis les coins publics où l'OFB l'a relevée.
/// A branche cette vue à côté du filtre de la carte ; elle ne demande pas la position elle-même.
struct OuChercherVue: View {
    @State private var modele: OuChercherModele

    init(especes: ServiceEspeces, position: Coordonnee) {
        _modele = State(initialValue: OuChercherModele(especes: especes, position: position))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch modele.etat {
                case .choixEspece:
                    GrilleEspeces(especes: modele.grille, choisir: modele.choisir)
                case .resultats(let espece, let coins):
                    ListeCoins(espece: espece, coins: coins, changer: modele.changerEspece)
                case .aucunReleve(let espece):
                    ListeCoins(espece: espece, coins: [], changer: modele.changerEspece)
                }
            }
            .navigationTitle(OuChercherTextes.titreEcran)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .fontDesign(.rounded)
    }
}

// MARK: - Choix de l'espèce

private struct GrilleEspeces: View {
    let especes: [EspeceChoix]
    let choisir: (EspeceChoix) -> Void
    @ScaledMetric(relativeTo: .body) private var largeurMin: CGFloat = 130

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(OuChercherTextes.invite)
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: largeurMin), spacing: 12)], spacing: 12) {
                    ForEach(especes) { e in
                        Button { choisir(e) } label: { CarteEspece(espece: e) }
                            .buttonStyle(.plain)
                            .accessibilityLabel(e.nom)
                            .accessibilityHint(e.pres ? "Relevée près d'ici" : "")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }
}

private struct CarteEspece: View {
    let espece: EspeceChoix

    var body: some View {
        VStack(spacing: 8) {
            ImageEspeceOuChercher(nom: espece.image)
                .frame(height: 64)
            Text(espece.nom)
                .font(.subheadline.weight(.bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(10)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// L'image de l'espèce (livrée par D1 dans les assets, posée par A) ; une icône neutre tant qu'elle manque.
private struct ImageEspeceOuChercher: View {
    let nom: String

    var body: some View {
        if existe(nom) {
            Image(nom).resizable().scaledToFit()
        } else {
            Image(systemName: "fish").resizable().scaledToFit().padding(8).foregroundStyle(.secondary)
        }
    }

    private func existe(_ nom: String) -> Bool {
        #if canImport(UIKit)
        UIImage(named: nom) != nil
        #else
        false
        #endif
    }
}

// MARK: - Résultats

private struct ListeCoins: View {
    let espece: EspeceChoix
    let coins: [CoinAffiche]
    let changer: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ImageEspeceOuChercher(nom: espece.image).frame(width: 56, height: 56)
                    Text(espece.nom).font(.title2.weight(.bold)).accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                }
                Button(action: changer) {
                    Label("Changer d'espèce", systemImage: "arrow.left")
                        .font(.body.weight(.bold))
                        .frame(minHeight: 44)
                }
                .buttonStyle(.bordered)

                if coins.isEmpty {
                    Text(OuChercherTextes.sansRelevePres)
                        .font(.headline.weight(.bold))
                        .padding(.vertical, 8)
                } else {
                    Text(OuChercherTextes.explicationOrdre)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ForEach(coins) { LigneCoin(coin: $0) }
                    Text(OuChercherTextes.creditOSM)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }
}

private struct LigneCoin: View {
    let coin: CoinAffiche

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(coin.titre).font(.headline.weight(.bold))
                Spacer(minLength: 8)
                Text(coin.distance).font(.subheadline.weight(.bold)).foregroundStyle(.secondary)
            }
            Text(coin.releve).font(.subheadline)
            Label(coin.ouverture, systemImage: coin.estOuvert ? "checkmark.circle" : "clock")
                .font(.subheadline.weight(.bold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(coin.phraseVoixOff)
    }
}

#if DEBUG
#Preview("Choix de l'espèce") {
    OuChercherVue(especes: EspecesFaux(), position: Coordonnee(latitude: 48.82, longitude: 2.41))
}
#endif
