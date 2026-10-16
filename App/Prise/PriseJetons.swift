import SwiftUI

/// Les jetons de l'écran Prise pointent vers `App/Style/Style.swift` (Palette, Police, Espace, Rayon) :
/// pour retoucher une couleur ou une police, on change ce fichier-là, jamais les écrans.
enum PriseJetons {
    static let encre = Palette.encre
    static let accent = Palette.marine
    static let papier = Palette.surface
    static let fond = Palette.fond
    static let discret = Palette.encreDouce
    static let mise = Palette.marine

    static let rayon: CGFloat = Rayon.l
    static let cibleMin: CGFloat = Gabarit.zoneTactile

    static func titre() -> Font { Police.titre }
    static func corps() -> Font { Police.corps }
    static func legende() -> Font { Police.legende }
    static func chiffre() -> Font { Police.chiffre }
}

/// Bouton principal : celui de `Style` (marine, pilule, pleine largeur).
struct PriseBoutonPrincipal: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        BoutonPrincipal().makeBody(configuration: configuration)
    }
}

/// Bouton secondaire : celui de `Style`.
struct PriseBoutonSecondaire: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        BoutonSecondaire().makeBody(configuration: configuration)
    }
}

/// Bouton rond de 44 points posé sur une photo (retour, fermer).
struct PriseBoutonRond: View {
    var symbole: String
    var etiquette: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbole)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.encre)
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(etiquette)
    }
}

/// La feuille du bas, posée sur la photo de la prise : poignée, coins hauts arrondis, fond `surface`.
/// Le bouton de retour flotte en haut à gauche.
struct PriseFeuille<Contenu: View>: View {
    var photo: UIImage?
    var retour: (() -> Void)?
    var pleine = false
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        ZStack {
            fond
            VStack(spacing: 0) {
                if let retour {
                    HStack {
                        BoutonRond(role: .retour, rendu: .verre, action: retour)
                        Spacer()
                    }
                    .padding(Espace.bord)
                }
                Spacer(minLength: 0)
                VStack(spacing: Espace.l) {
                    Capsule().fill(Palette.filet).frame(width: 36, height: 5)
                        .accessibilityHidden(true)
                    contenu()
                }
                .padding(.horizontal, Espace.bord)
                .padding(.top, Espace.s)
                .padding(.bottom, Espace.l)
                .frame(maxWidth: .infinity, maxHeight: pleine ? .infinity : nil)
                .background(Palette.surface, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous))
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    @ViewBuilder private var fond: some View {
        if let photo {
            Color.clear
                .overlay(Image(uiImage: photo).resizable().scaledToFill())
                .clipped()
                .ignoresSafeArea()
                .accessibilityHidden(true)
        } else {
            Palette.nuit.ignoresSafeArea()
        }
    }
}
