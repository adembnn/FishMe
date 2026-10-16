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
                .foregroundStyle(Palette.encreDouce)
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
            .foregroundStyle(Palette.surMarine)
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
    /// Faux : espèce proposée sans relevé OFB ici ; aucun chiffre n'est montré.
    var releve = true

    var body: some View {
        HStack(spacing: 12) {
            ImageEspeceCarte(nom: image)
                .frame(width: 56, height: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(nom)
                    .font(PolicesCarte.corps())
                    .fixedSize(horizontal: false, vertical: true)
                Text(releve ? texteReleve(nPeches: nPeches, annee: annee) : "pas relevée ici")
                    .font(PolicesCarte.legende())
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
                if let rarete, rarete.echelle == .region {
                    Text("rareté sur la région (moins de 20 pêches ici)")
                        .font(PolicesCarte.legende())
                        .foregroundStyle(Palette.encreDouce)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let ouverture {
                    Text(ouverture.texte)
                        .font(PolicesCarte.legende())
                        .foregroundStyle(ouverture.estOuverte ? Palette.ouvert : Palette.alerte)
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
        .background(selectionnee ? Palette.marineDoux : Color.clear, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Ce que l'écran « Ton spot » montre : le lieu, l'espèce la plus rare relevée, trois autres et le reste.
/// Tout vient de `calculerFiche` (donc de `Core`) ; chaque chiffre garde son nombre de pêches et son année.
nonisolated struct ApercuSpot: Sendable, Equatable {
    var lieu: String
    var vedette: LigneEspece?
    var autres: [LigneEspece]
    var reste: Int
}

@concurrent nonisolated func calculerApercuSpot(services: ServicesCarte, spot: Spot, date: Date) async -> ApercuSpot {
    let fiche = await calculerFiche(services: services, coordonnee: spot.centre, choix: nil, espece: nil, date: date)
    let releves = fiche.especes.filter { $0.releve }
    // Le plus rare d'abord ; à rareté égale, celui qui a été le moins pêché.
    let parRarete = releves
        .filter { $0.rarete != nil && $0.rarete?.niveau != .nonMesuree }
        .sorted { a, b in
            let ra = a.rarete?.niveau.rang ?? 0, rb = b.rarete?.niveau.rang ?? 0
            return ra != rb ? ra > rb : a.nPeches < b.nPeches
        }
    let vedette = parRarete.first
    let autres = releves
        .filter { $0.espece != vedette?.espece }
        .sorted { $0.nPeches > $1.nPeches }
    let eau = fiche.eaux.first?.nom ?? fiche.lieu.eau?.nom
    let code = spot.departement.estInconnu ? nil : spot.departement.code
    let lieu: String
    switch (eau, code) {
    case let (eau?, code?): lieu = "\(eau) · \(code)"
    case let (eau?, nil): lieu = eau
    case let (nil, code?): lieu = "Ton spot · \(code)"
    case (nil, nil): lieu = "Ton spot"
    }
    return ApercuSpot(lieu: lieu, vedette: vedette, autres: Array(autres.prefix(3)), reste: max(0, autres.count - 3))
}

/// Bouton rond de 44 pt en verre (carte) : icône encre ou marine.
struct BoutonVerreCarte: View {
    let symbole: String
    let libelle: String
    var teinte: Color = Palette.encre
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbole)
                .font(Police.taille(18))
                .foregroundStyle(teinte)
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .background {
                    Circle()
                        .fill(.regularMaterial)
                        .overlay(Circle().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                        .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(libelle)
    }
}
