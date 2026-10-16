import SwiftUI
import UIKit

// Jetons de style de FishMe (lot D0) : la piste « Natif », façon Plans d'Apple, en SF Pro Rounded gras.
// Palette « Marine » (planche Variations du 15 oct.) : bleu nuit de lac, encre, et l'orange du bouchon.
// Tout le style de l'app vient d'ici : pour retoucher une couleur (par exemple quand le logo arrive),
// on change une seule ligne de ce fichier, jamais les écrans.

// MARK: - Couleurs

/// Une couleur UIKit lue en hexadécimal (0xRRGGBB).
nonisolated private func uiCouleur(_ hex: UInt32) -> UIColor {
    UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

/// Une couleur pour le mode clair et une pour le mode sombre, en hexadécimal (0xRRGGBB).
nonisolated private func teinte(_ clair: UInt32, sombre: UInt32) -> Color {
    Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? uiCouleur(sombre) : uiCouleur(clair)
    })
}

/// La palette : trois couleurs de base (marine, encre, bouchon), les neutres qui les portent,
/// et les quatre couleurs de rareté.
enum Palette {
    // Les trois couleurs de base.
    /// Bleu marine : boutons, onglet choisi, liens, spot du pêcheur. La seule couleur « de marque ».
    static let marine = teinte(0x0D4A85, sombre: 0x7FB8EE)
    /// Encre : titres, chiffres, texte principal.
    static let encre = teinte(0x0E1A26, sombre: 0xE7EDF3)
    /// Orange du bouchon : alertes (orage, crue, espèce fermée), et rien d'autre.
    static let bouchon = teinte(0xE8571C, sombre: 0xFF7A45)

    // Les nuances de la marine.
    /// Marine appuyée (bouton pressé, texte sur fond marine doux).
    static let marineFonce = teinte(0x0B3D6B, sombre: 0xA9D0F5)
    /// Marine très doux : fond d'une pastille choisie, d'une tuile mise en avant.
    static let marineDoux = teinte(0xDCE8F5, sombre: 0x16314D)
    /// Bleu nuit : grands aplats sombres (révélation d'une carte, écran de session de nuit).
    static let nuit = teinte(0x082A4C, sombre: 0x071A2E)
    /// Texte posé sur la marine (bouton principal).
    static let surMarine = teinte(0xFFFFFF, sombre: 0x061A2C)

    // Les neutres.
    /// Texte secondaire : unités, sources, légendes.
    static let encreDouce = teinte(0x566576, sombre: 0x97A4B2)
    /// Fond des pages.
    static let fond = teinte(0xF2F5F9, sombre: 0x0D1218)
    /// Fond des cartes, tuiles et feuilles.
    static let surface = teinte(0xFFFFFF, sombre: 0x151C24)
    /// Fond d'une tuile posée sur une surface (deuxième niveau).
    static let tuile = teinte(0xE7EFF8, sombre: 0x1B2530)
    /// Filet de séparation, contour discret.
    static let filet = teinte(0xDCE3EB, sombre: 0x26303B)
    /// Silhouette d'un poisson pas encore trouvé dans le Pescedex.
    static let silhouette = teinte(0xB9C8D8, sombre: 0x2E3D4D)

    // L'eau de la carte (rivières, lacs).
    static let eau = teinte(0x9CC7EA, sombre: 0x17486A)
    static let eauClaire = teinte(0xC7DFF3, sombre: 0x123A57)

    // États.
    /// Ouvert aujourd'hui, prise confirmée.
    static let ouvert = teinte(0x13643B, sombre: 0x6FE0A4)
    static let ouvertDoux = teinte(0xE1F1E8, sombre: 0x0F3326)
    /// Alerte : même couleur que le bouchon.
    static let alerte = bouchon
    static let alerteDoux = teinte(0xFDE6DA, sombre: 0x3A1E12)

    // Les quatre raretés. La couleur aide, mais le niveau se lit sans elle :
    // forme du badge (rond, hexagone, losange, étoile), 1 à 4 points, et le mot.
    static let commun = teinte(0x6B7780, sombre: 0x9AA6AE)
    static let peuCommun = teinte(0x23885A, sombre: 0x4CC28A)
    static let rare = teinte(0x5B4FD0, sombre: 0x9C93F2)
    static let legendaire = teinte(0xB07A12, sombre: 0xE0AE45)
}

// MARK: - Polices

/// SF Pro Rounded en gras partout (Adem, 15 oct.). Les tailles suivent le texte agrandi d'iOS.
enum Police {
    /// Titre d'écran (« Pescedex », nom du poisson sur sa fiche).
    static let grandTitre = Font.system(.largeTitle, design: .rounded, weight: .heavy)
    /// Titre de bloc ou de feuille.
    static let titre = Font.system(.title2, design: .rounded, weight: .bold)
    /// Sous-titre, nom d'un poisson sur une tuile.
    static let sousTitre = Font.system(.headline, design: .rounded, weight: .bold)
    /// Texte courant et boutons.
    static let corps = Font.system(.body, design: .rounded, weight: .bold)
    /// Détail sous un chiffre (« 24 pêches sur 29 »).
    static let detail = Font.system(.subheadline, design: .rounded, weight: .bold)
    /// Source d'une règle, mention OFB, plus petit texte permis.
    static let legende = Font.system(.footnote, design: .rounded, weight: .bold)
    /// Gros chiffre (taille d'un poisson, compteur du Pescedex, température).
    static let chiffre = Font.system(.largeTitle, design: .rounded, weight: .heavy).monospacedDigit()
    /// Chiffre moyen (tuile météo, niveau de la rivière).
    static let chiffreMoyen = Font.system(.title, design: .rounded, weight: .heavy).monospacedDigit()

    /// Taille fixe, pour ce qui vit dans un cadre de taille fixe (la carte à collectionner).
    static func taille(_ points: CGFloat, _ graisse: Font.Weight = .bold) -> Font {
        .system(size: points, weight: graisse, design: .rounded)
    }
}

// MARK: - Espacements, rayons, tailles

/// Espacements, sur une grille de 4 points.
enum Espace {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    /// Marge d'un écran à gauche et à droite.
    static let bord: CGFloat = 16
}

/// Rayons des coins (toujours en forme `.continuous`, comme iOS).
enum Rayon {
    /// Pastille, petite vignette.
    static let s: CGFloat = 10
    /// Tuile, champ, bouton carré.
    static let m: CGFloat = 16
    /// Bloc, feuille, grande tuile.
    static let l: CGFloat = 22
}

/// Mesures fixes partagées par tous les écrans.
enum Gabarit {
    /// Hauteur et largeur minimales d'une zone touchable (règle d'Apple).
    static let zoneTactile: CGFloat = 44
    /// Hauteur d'un bouton principal.
    static let bouton: CGFloat = 54
    /// Carte à collectionner : une seule taille partout, largeur sur hauteur 69/100 (recto, verso, Pescedex).
    static let rapportCarte: CGFloat = 69.0 / 100.0
    /// Coin de la carte à collectionner, en part de sa largeur.
    static let coinCarte: CGFloat = 0.06
}

// MARK: - Boutons

/// Bouton principal : pleine largeur, marine, texte blanc, en pilule.
struct BoutonPrincipal: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Police.corps)
            .foregroundStyle(Palette.surMarine)
            .frame(maxWidth: .infinity, minHeight: Gabarit.bouton)
            .padding(.horizontal, Espace.l)
            .background(configuration.isPressed ? Palette.marineFonce : Palette.marine, in: Capsule())
            .contentShape(Capsule())
    }
}

/// Bouton secondaire : pleine largeur, surface claire, texte marine.
struct BoutonSecondaire: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Police.corps)
            .foregroundStyle(Palette.marine)
            .frame(maxWidth: .infinity, minHeight: Gabarit.bouton)
            .padding(.horizontal, Espace.l)
            .background(configuration.isPressed ? Palette.marineDoux : Palette.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.filet, lineWidth: 1))
            .contentShape(Capsule())
    }
}

extension ButtonStyle where Self == BoutonPrincipal {
    /// `.buttonStyle(.principal)`
    static var principal: BoutonPrincipal { BoutonPrincipal() }
}

extension ButtonStyle where Self == BoutonSecondaire {
    /// `.buttonStyle(.secondaire)`
    static var secondaire: BoutonSecondaire { BoutonSecondaire() }
}

// MARK: - Style de toute l'app

extension View {
    /// À poser une fois, sur la racine de l'app : police arrondie en gras, marine comme teinte,
    /// et aucune barre de défilement visible.
    func styleFishMe() -> some View {
        self
            .fontDesign(.rounded)
            .fontWeight(.bold)
            .tint(Palette.marine)
            .scrollIndicators(.hidden)
    }

    /// Fond d'une tuile ou d'un bloc : surface et coins arrondis.
    func tuileFishMe(rayon: CGFloat = Rayon.m) -> some View {
        background(Palette.surface, in: RoundedRectangle(cornerRadius: rayon, style: .continuous))
    }
}
