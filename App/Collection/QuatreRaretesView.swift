import SwiftUI
import UIKit

/// Les quatre paliers de rareté en quatre cartes miniatures, chacune avec un poisson de profil (P24 A).
/// Depuis L18 il ne s'affiche plus sous une carte ouverte ni dans la révélation : il explique les paliers dans la fiche d'une espèce
/// (`FicheEspeceView`). La carte du palier de l'espèce est entourée de marine. Les poissons sont des exemples d'image, sans chiffre.
struct QuatreRaretesView: View {
    /// Palier de la carte ouverte, entouré.
    let actuel: StyleRarete
    @Environment(\.locale) private var locale
    private var t: AnglaisD { AnglaisD(locale) }

    private static let exemples: [(style: StyleRarete, nom: String, image: String)] = [
        (.commun, "Gardon", "gardon"),
        (.peuCommun, "Brochet", "brochet"),
        (.rare, "Sandre", "sandre"),
        (.legendaire, "Truite fario", "truite-fario")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(t("Les paliers de rareté"))
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .top, spacing: 0) {
                ForEach(Self.exemples, id: \.nom) { exemple in
                    MiniatureRarete(style: exemple.style, nom: exemple.nom, image: exemple.image, entouree: exemple.style == actuel)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 14)
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, Espace.l)
        .padding(.bottom, Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// Une carte de 72 pt de large : la fenêtre du palier, le poisson, et la plaque avec le nom et la marque de palier.
private struct MiniatureRarete: View {
    let style: StyleRarete
    let nom: String
    let image: String
    let entouree: Bool
    @Environment(\.locale) private var locale
    private var t: AnglaisD { AnglaisD(locale) }

    private let largeur: CGFloat = 72

    var body: some View {
        CarteCadre(style: style, declaree: false) {
            VStack(spacing: 0) {
                fenetre
                plaque
            }
        }
        .frame(width: largeur)
        .padding(3)
        .overlay {
            if entouree {
                RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(Palette.marine, lineWidth: 2.5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(nom), \(style.mot(t))")
    }

    private var fenetre: some View {
        ZStack {
            LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
            Image(image)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 4)
                .shadow(color: Color.black.opacity(0.35), radius: 1, x: -1, y: 2)
                .rotationEffect(.degrees(-12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var plaque: some View {
        HStack(spacing: 2) {
            Text(nom)
                .font(Police.taille(8, .heavy))
                .foregroundStyle(Color(carte: 0x0F1A1C))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            MarqueRarete(style: style, taille: 9)
        }
        .padding(.horizontal, 5)
        .frame(height: 22)
        .frame(maxWidth: .infinity)
        .background(style.plaque)
    }
}
