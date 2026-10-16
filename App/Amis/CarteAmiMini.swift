import Core
import SwiftUI
import UIKit

/// Images déjà décodées d'un PNG/JPEG reçu en `Data` : sans elle, chaque évaluation d'une vue refaisait le décodage complet.
/// Clé : taille et quelques octets du début et de la fin (assez pour distinguer deux cartes, sans relire toute l'image).
@MainActor
enum ImagesAmisEnCache {
    private static let memoire: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 60
        return c
    }()

    static func image(_ donnees: Data) -> UIImage? {
        let cle = "\(donnees.count)-\(donnees.prefix(48).hashValue)-\(donnees.suffix(48).hashValue)" as NSString
        if let connue = memoire.object(forKey: cle) { return connue }
        guard let image = UIImage(data: donnees) else { return nil }
        memoire.setObject(image, forKey: cle)
        return image
    }
}

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
    /// Vraie photo de la prise (démo). Si elle manque, la fenêtre montre l'image d'espèce.
    var photo: UIImage? = nil
    var tailleCm: Double? = nil

    /// Hauteur fixe de la zone de texte, sous l'image : le texte ne passe jamais sur le dessin.
    private static let hauteurTexte: CGFloat = 58

    var body: some View {
        Group {
            if let donnees = imageCarte, let image = ImagesAmisEnCache.image(donnees) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: Rayon.l + 2, style: .continuous))
                    .shadow(color: Palette.encre.opacity(0.22), radius: 8, y: 5)
            } else {
                CarteCadre(style: style, declaree: false) {
                    VStack(spacing: 0) {
                        fenetre
                        bas
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
        return morceaux.joined(separator: ", ")
    }

    /// Le fond de rareté et le poisson, coupés à la fenêtre ; le reflet reste dans la fenêtre, jamais sur le texte.
    private var fenetre: some View {
        ZStack {
            LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
            if let image = photo {
                Color.clear.overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
            } else if let imageEspece {
                Image(imageEspece)
                    .resizable()
                    .scaledToFit()
                    .padding(Espace.s)
            }
            if style.aUnReflet {
                RefletHolographique(inclinaison: .zero, fixe: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    /// Zone de texte distincte, sur la plaque opaque : nom sur deux lignes au plus, taille en dessous, badge à droite.
    private var bas: some View {
        HStack(spacing: Espace.xs) {
            VStack(alignment: .leading, spacing: 1) {
                Text(nomEspece)
                    .font(Police.taille(13, .heavy))
                    .foregroundStyle(Palette.encre)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let t = tailleCm {
                    Text("\(Formats.nombre(t, decimales: 0)) cm")
                        .font(Police.taille(11, .bold))
                        .foregroundStyle(Palette.encreDouce)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            BadgeRarete(style: style, taille: 22)
        }
        .padding(.horizontal, Espace.m)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .frame(height: Self.hauteurTexte)
        .background(Palette.surface)
        .clipped()
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
    var photo: UIImage? = nil
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
                                     imageCarte: carte.imageCarte, photo: carte.photo, tailleCm: carte.tailleCm)
                        Text(carte.prenom)
                            .font(Police.detail)
                            .foregroundStyle(Palette.encre)
                            .lineLimit(1)
                        Text(carte.mois)
                            .font(Police.legende)
                            .foregroundStyle(Palette.encreDouce)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Ouvre la carte")
            }
        }
    }
}
