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

/// La feuille du bas, posée sur la photo de la prise (voile marine) : poignée, flottante à `Espace.bord` des bords, coins arrondis, fond `surface`.
/// Le bouton de retour flotte en haut à gauche.
struct PriseFeuille<Contenu: View>: View {
    var photo: UIImage?
    var retour: (() -> Void)?
    var pleine = false
    /// Opacité du voile marine sur la photo (0,32 par défaut, 0,4 pour la grille).
    var voile: Double = 0.32
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
                .padding(.horizontal, 20)
                .padding(.top, Espace.s)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, maxHeight: pleine ? .infinity : nil)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, Espace.bord)
                .padding(.bottom, Espace.bord)
            }
        }
    }

    @ViewBuilder private var fond: some View {
        if let photo {
            Color.clear
                .overlay(Image(uiImage: photo).resizable().scaledToFill())
                .clipped()
                .overlay(Color(red: 8 / 255, green: 42 / 255, blue: 76 / 255).opacity(voile))
                .ignoresSafeArea()
                .accessibilityHidden(true)
        } else {
            Palette.nuit.ignoresSafeArea()
        }
    }
}
