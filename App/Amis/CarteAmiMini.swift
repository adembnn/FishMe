import Core
import SwiftUI
import UIKit

/// Une carte d'ami au même dessin que les cartes d'Adem : le cadre `CarteCadre` (filets de rareté, ombre, même rapport),
/// la fenêtre du poisson sur son fond de rareté, le nom et le badge `BadgeRarete`. Version courte pour une grille de deux colonnes :
/// la taille et la source OFB ne tiennent pas, elles restent dans la carte ouverte.
struct CarteAmiMini: View {
    let style: StyleRarete
    let nomEspece: String
    /// Nom de l'image d'espèce dans les ressources de l'app.
    let imageEspece: String?
    /// PNG de la carte envoyé par l'ami (sans GPS). S'il existe, il est montré tel quel, comme la vraie carte.
    var imageCarte: Data? = nil
    var tailleCm: Double? = nil
    var exemple = false

    var body: some View {
        Group {
            if let donnees = imageCarte, let image = UIImage(data: donnees) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Rayon.l + 2, style: .continuous))
                    .shadow(color: Palette.encre.opacity(0.22), radius: 8, y: 5)
            } else {
                CarteCadre(style: style, declaree: false) {
                    ZStack {
                        VStack(spacing: 0) {
                            fenetre
                            bas
                        }
                        if style.aUnReflet {
                            RefletHolographique(inclinaison: .zero, fixe: true)
                                .clipShape(RoundedRectangle(cornerRadius: Rayon.l + 2, style: .continuous))
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(texteVoixOff)
    }

    private var texteVoixOff: String {
        var morceaux = [nomEspece, style.mot]
        if let t = tailleCm { morceaux.append("\(Formats.nombre(t, decimales: 0)) cm") }
        if exemple { morceaux.append("exemple") }
        return morceaux.joined(separator: ", ")
    }

    private var fenetre: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
            if let imageEspece {
                Image(imageEspece)
                    .resizable()
                    .scaledToFit()
                    .padding(Espace.s)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if exemple {
                Text("Exemple")
                    .font(Police.taille(11, .heavy))
                    .foregroundStyle(Palette.encre)
                    .padding(.horizontal, Espace.s)
                    .padding(.vertical, 3)
                    .background(Palette.surface, in: Capsule())
                    .padding(Espace.s)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bas: some View {
        HStack(spacing: Espace.xs) {
            VStack(alignment: .leading, spacing: 0) {
                Text(nomEspece)
                    .font(Police.taille(14, .heavy))
                    .foregroundStyle(Palette.encre)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let t = tailleCm {
                    Text("\(Formats.nombre(t, decimales: 0)) cm")
                        .font(Police.taille(11, .bold))
                        .foregroundStyle(Palette.encreDouce)
                }
            }
            Spacer(minLength: 0)
            BadgeRarete(style: style, taille: 22)
        }
        .padding(.horizontal, Espace.m)
        .frame(height: 46)
        .background(Palette.surface)
    }
}

/// Ce que la grille montre pour une carte : la carte, puis dessous le prénom de l'ami et le mois.
struct CarteAmiGrille: Identifiable {
    let id: String
    let prenom: String
    let mois: String
    let style: StyleRarete
    let nomEspece: String
    let imageEspece: String?
    var imageCarte: Data? = nil
    var tailleCm: Double? = nil
    var exemple = false
}

/// Grille de deux colonnes de cartes d'amis, chacune toucable.
struct GrilleCartesAmis: View {
    let cartes: [CarteAmiGrille]
    let ouvrir: (CarteAmiGrille) -> Void

    private let colonnes = [GridItem(.flexible(), spacing: Espace.l), GridItem(.flexible(), spacing: Espace.l)]

    var body: some View {
        LazyVGrid(columns: colonnes, spacing: Espace.l) {
            ForEach(cartes) { carte in
                Button { ouvrir(carte) } label: {
                    VStack(alignment: .leading, spacing: Espace.s) {
                        CarteAmiMini(style: carte.style, nomEspece: carte.nomEspece, imageEspece: carte.imageEspece,
                                     imageCarte: carte.imageCarte, tailleCm: carte.tailleCm, exemple: carte.exemple)
                        Text(carte.prenom)
                            .font(Police.detail)
                            .foregroundStyle(Palette.encre)
                            .lineLimit(1)
                        Text(carte.exemple ? "\(carte.mois) · Exemple" : carte.mois)
                            .font(Police.legende)
                            .foregroundStyle(Palette.encreDouce)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Ouvre la carte")
            }
        }
    }
}
