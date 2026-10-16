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

/// La feuille du bas façon Plans (maquettes P19 à P22) : posée sur la photo de la prise (voile marine), à 8 points des bords gauche, droit et bas de l'écran,
/// coins de 38 points, fond `surface`, ombre douce, poignée de 36 × 5 (7 points au-dessus, 12 en dessous), 20 points de marge à gauche et à droite, 24 en bas.
/// Le bouton de retour flotte en haut à gauche, dans la zone sûre (59 points du haut sur un iPhone à Dynamic Island), 16 points du bord.
struct PriseFeuille<Contenu: View>: View {
    var photo: UIImage?
    var retour: (() -> Void)?
    /// La feuille prend toute la hauteur qui reste.
    var pleine = false
    /// Distance entre le haut de l'écran et le haut de la feuille (P20 : 128, P22 : 116). Donnée, la feuille est haute.
    var haut: CGFloat? = nil
    /// Opacité du voile marine sur la photo (0,32 par défaut ; P20 et P22 : 0,4).
    var voile: Double = 0.32
    /// P21 : la photo floutée et assombrie (flou 16, luminosité 0,55, saturation 0,8, agrandie de 20 %) à la place du voile marine.
    var floute = false
    /// Ce qui se pose entre la photo et la feuille (P21 : le poisson posé à plat et la ligne de mesure), en coordonnées d'écran.
    var arriere: AnyView? = nil
    /// Un second bouton rond en haut à droite (P21 : « Remesurer »).
    var actionHaute: (symbole: String, etiquette: String, action: () -> Void)? = nil
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        ZStack(alignment: .top) {
            fond
            if let arriere { arriere.ignoresSafeArea() }
            VStack(spacing: 0) {
                if let haut { Color.clear.frame(height: haut) } else { Spacer(minLength: 0) }
                VStack(spacing: 0) {
                    Capsule().fill(Palette.filet).frame(width: 36, height: 5)
                        .padding(.top, 7).padding(.bottom, 12)
                        .accessibilityHidden(true)
                    contenu()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, maxHeight: (pleine || haut != nil) ? .infinity : nil, alignment: .top)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
                .shadow(color: Palette.encre.opacity(0.16), radius: 15, y: -2)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .ignoresSafeArea(.container)
            if retour != nil || actionHaute != nil {
                HStack {
                    if let retour { BoutonRond(role: .retour, rendu: .verre, action: retour) }
                    Spacer()
                    if let actionHaute { PriseBoutonRond(symbole: actionHaute.symbole, etiquette: actionHaute.etiquette, action: actionHaute.action) }
                }
                .padding(.horizontal, Espace.bord)
            }
        }
    }

    @ViewBuilder private var fond: some View {
        if let photo {
            if floute {
                Color(red: 14 / 255, green: 26 / 255, blue: 38 / 255)
                    .overlay(Image(uiImage: photo).resizable().scaledToFill()
                        .blur(radius: 16).brightness(-0.45).saturation(0.8).scaleEffect(1.2))
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            } else {
                Color.clear
                    .overlay(Image(uiImage: photo).resizable().scaledToFill())
                    .clipped()
                    .overlay(Color(red: 8 / 255, green: 42 / 255, blue: 76 / 255).opacity(voile))
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
        } else {
            Palette.nuit.ignoresSafeArea()
        }
    }
}
