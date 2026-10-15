import SwiftUI
import UIKit
import Core

/// L'illustration d'une espèce (posée dans `App/Assets.xcassets/` par A). Sans image : un poisson générique, jamais un blanc.
struct ImageEspeceCarte: View {
    let nom: String?

    var body: some View {
        if let nom, UIImage(named: nom) != nil {
            Image(nom)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            Image(systemName: "fish")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }
}

struct PastilleRarete: View {
    let niveau: NiveauRarete

    var body: some View {
        Text(niveau.libelle)
            .font(PolicesCarte.legende())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(.white)
            .background(CouleursCarte.rarete(niveau), in: Capsule())
    }
}

/// Une espèce relevée : image, nom, rareté, « N pêches, dernier relevé AAAA », ouverture du jour.
struct RangeeEspece: View {
    let nom: String
    let image: String?
    let nPeches: Int
    let annee: Int?
    var rarete: ResultatRarete?
    var ouverture: OuvertureDuJour?
    var selectionnee = false

    var body: some View {
        HStack(spacing: 12) {
            ImageEspeceCarte(nom: image)
                .frame(width: 56, height: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(nom)
                    .font(PolicesCarte.corps())
                    .fixedSize(horizontal: false, vertical: true)
                Text(texteReleve(nPeches: nPeches, annee: annee))
                    .font(PolicesCarte.legende())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let rarete, rarete.echelle == .region {
                    Text("rareté sur la région (moins de 20 pêches ici)")
                        .font(PolicesCarte.legende())
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let ouverture {
                    Text(ouverture.texte)
                        .font(PolicesCarte.legende())
                        .foregroundStyle(ouverture.estOuverte ? CouleursCarte.accent : CouleursCarte.attention)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 4)
            if let rarete, rarete.niveau != .nonMesuree {
                PastilleRarete(niveau: rarete.niveau)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(selectionnee ? CouleursCarte.accent.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
