import Core
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// « Choisir un autre spot » : l'espèce en images, puis les coins publics où l'OFB l'a relevée.
/// A branche cette vue à côté du filtre de la carte ; elle ne demande pas la position elle-même.
struct OuChercherVue: View {
    @State private var modele: OuChercherModele
    @Environment(\.dismiss) private var dismiss

    init(especes: any ServiceEspeces & ServiceCoinsPublics, position: Coordonnee) {
        _modele = State(initialValue: OuChercherModele(especes: especes, position: position))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch modele.etat {
                case .choixEspece:
                    GrilleEspeces(especes: modele.grille, choisir: modele.choisir)
                case .chargement(let espece):
                    ChargementCoins(espece: espece, changer: modele.changerEspece)
                case .resultats(let espece, let coins):
                    ListeCoins(espece: espece, coins: coins, changer: modele.changerEspece)
                case .aucunReleve(let espece):
                    ListeCoins(espece: espece, coins: [], changer: modele.changerEspece)
                }
            }
            .navigationTitle(OuChercherTextes.titreEcran)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BoutonRond(role: .fermer, rendu: .simple) { dismiss() }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .fontDesign(.rounded)
        .background(Palette.fond)
    }
}

// MARK: - Choix de l'espèce

private struct GrilleEspeces: View {
    let especes: [EspeceChoix]
    let choisir: (EspeceChoix) -> Void
    @ScaledMetric(relativeTo: .body) private var largeurMin: CGFloat = 130

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                Text(OuChercherTextes.invite)
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: largeurMin), spacing: Espace.m)], spacing: Espace.m) {
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
            ImageEspeceCoin(nom: espece.image)
                .frame(height: 64)
            Text(espece.nom)
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(10)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }
}

/// L'image de l'espèce (livrée par D1 dans les assets, posée par A) ; une icône neutre tant qu'elle manque.
private struct ImageEspeceCoin: View {
    let nom: String

    var body: some View {
        if existe(nom) {
            Image(nom).resizable().scaledToFit()
        } else {
            Image(systemName: "fish").resizable().scaledToFit().padding(8).foregroundStyle(Palette.silhouette)
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

// MARK: - Recherche en cours

private struct ChargementCoins: View {
    let espece: EspeceChoix
    let changer: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            ImageEspeceCoin(nom: espece.image).frame(width: 72, height: 72)
            ChargementBouchon()
            Text(OuChercherTextes.recherche(espece.nom))
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
            Button(action: changer) {
                Label("Changer d'espèce", systemImage: "arrow.left")
            }
            .buttonStyle(.secondaire)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(OuChercherTextes.recherche(espece.nom))
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
                    ImageEspeceCoin(nom: espece.image).frame(width: 56, height: 56)
                    Text(espece.nom).font(Police.titre).foregroundStyle(Palette.encre).accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                }
                Button(action: changer) {
                    Label("Changer d'espèce", systemImage: "arrow.left")
                }
                .buttonStyle(.secondaire)

                if coins.isEmpty {
                    Text(OuChercherTextes.sansRelevePres)
                        .font(Police.sousTitre)
                        .foregroundStyle(Palette.encre)
                        .padding(.vertical, Espace.s)
                } else {
                    Text(OuChercherTextes.explicationOrdre)
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                    ForEach(coins) { LigneCoin(coin: $0) }
                    Text(OuChercherTextes.creditOSM)
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
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
                Text(coin.titre).font(Police.sousTitre).foregroundStyle(Palette.encre)
                Spacer(minLength: 8)
                Text(coin.distance).font(Police.detail).foregroundStyle(Palette.encreDouce)
            }
            if let acces = coin.acces { Text(acces).font(Police.legende).foregroundStyle(Palette.encreDouce) }
            Text(coin.releve).font(Police.detail).foregroundStyle(Palette.encre)
            Text(coin.station).font(Police.legende).foregroundStyle(Palette.encreDouce)
            Label(coin.ouverture, systemImage: coin.estOuvert ? "checkmark.circle" : "clock")
                .font(Police.detail)
                .foregroundStyle(coin.estOuvert ? Palette.ouvert : Palette.alerte)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(coin.phraseVoixOff)
    }
}

#if DEBUG
#Preview("Choix de l'espèce") {
    OuChercherVue(especes: CoinsFaux(), position: Coordonnee(latitude: 48.82, longitude: 2.41))
}
#endif
