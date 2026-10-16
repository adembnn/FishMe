import Core
import SwiftUI
import UIKit

/// Cadre commun : recto et verso, comme toutes les cartes, ont exactement la même taille.
struct CarteCadre<Contenu: View>: View {
    let style: StyleRarete
    let declaree: Bool
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        let forme = RoundedRectangle(cornerRadius: 28, style: .continuous)
        contenu()
            .background(Jeton.papier, in: forme)
            .clipShape(forme)
            .overlay { filets(forme) }
            .shadow(color: Jeton.encre.opacity(0.25), radius: 14, y: 8)
            .aspectRatio(Jeton.rapportCarte, contentMode: .fit)
    }

    @ViewBuilder
    private func filets(_ forme: RoundedRectangle) -> some View {
        if declaree {
            // Carte déclarée : cadre en tirets, jamais plein.
            forme.strokeBorder(Jeton.ardoise, style: StrokeStyle(lineWidth: 3, dash: [9, 6]))
        } else {
            ZStack {
                ForEach(0..<style.filets, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 28 - CGFloat(i) * 4, style: .continuous)
                        .strokeBorder(i % 2 == 0 ? style.couleur : Color.white, lineWidth: 3)
                        .padding(CGFloat(i) * 4)
                }
            }
        }
    }
}

/// Le recto, 6 éléments et pas un de plus : le poisson, son nom, sa rareté, sa taille, son lieu flouté, sa date.
struct CarteRectoView: View {
    let infos: InfosCarte
    /// Vrai seulement sur la carte ouverte en plein écran : le poisson nage.
    var anime = false
    var inclinaison: CGSize = .zero
    var refletFixe = false
    /// Image déjà décodée (rendu du partage) : évite le fournisseur d'images asynchrone d'`ImageRenderer`, qui peut expirer.
    var imageDecodee: UIImage? = nil
    /// Image partagée : ni rivière, ni jour exact (le département et « mois année » suffisent).
    var pourPartage = false

    var body: some View {
        CarteCadre(style: infos.style, declaree: infos.prise.estDeclaree) {
            ZStack {
                VStack(alignment: .leading, spacing: 10) {
                    illustration
                    enTete
                    taillePoids
                    pied
                    Spacer(minLength: 0)
                }
                .padding(14)
                if infos.style.aUnReflet && !infos.prise.estDeclaree {
                    RefletHolographique(inclinaison: inclinaison, fixe: refletFixe)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(infos.texteVoixOff)
    }

    private var illustration: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(colors: infos.style.fond, startPoint: .top, endPoint: .bottom)
            if anime {
                NageView(nomImage: infos.espece.image)
            } else {
                (imageDecodee.map { Image(uiImage: $0) } ?? Image(infos.espece.image))
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .saturation(infos.prise.estDeclaree ? 0.35 : 1)
            }
            VStack(alignment: .trailing, spacing: 6) {
                BadgeRarete(style: infos.style)
                if infos.prise.estDeclaree { etiquette("Déclarée") }
                if infos.prise.exemple { etiquette("Exemple") }
            }
            .padding(10)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func etiquette(_ texte: String) -> some View {
        Text(texte.uppercased())
            .font(Jeton.police(11))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Jeton.papier, in: Capsule())
            .foregroundStyle(Jeton.encre)
    }

    private var enTete: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(infos.espece.nom)
                    .font(Jeton.police(26))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text(infos.espece.nomLatin)
                    .font(Jeton.police(13, .semibold))
                    .italic()
                    .foregroundStyle(Jeton.encreDouce)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(infos.style.mot.uppercased())
                .font(Jeton.police(11))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(infos.style.couleur, in: Capsule())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(Jeton.encre)
    }

    @ViewBuilder
    private var taillePoids: some View {
        if let t = Formats.taille(infos.prise) {
            HStack(spacing: 8) {
                Text(t).font(Jeton.police(17))
                if let p = Formats.poids(infos.poids) {
                    Text(p).font(Jeton.police(15, .semibold)).foregroundStyle(Jeton.encreDouce)
                }
            }
            .foregroundStyle(Jeton.encre)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
    }

    private var pied: some View {
        VStack(alignment: .leading, spacing: 2) {
            if pourPartage {
                if let d = infos.departement { Text("Département \(d.code)").font(Jeton.police(15)) }
            } else if let lieu = infos.prise.lieuFlou, !infos.prise.estDeclaree {
                Text(lieu).font(Jeton.police(15))
            }
            HStack(spacing: 6) {
                Text(pourPartage ? Formats.moisAnnee(infos.prise.date) : Formats.date(infos.prise.date))
                if let rang = infos.rangDansLaZone, let d = infos.departement {
                    Text("· espèce n°\(rang) du \(d.code)")
                }
            }
            .font(Jeton.police(14, .semibold))
            .foregroundStyle(Jeton.encreDouce)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .foregroundStyle(Jeton.encre)
    }
}
