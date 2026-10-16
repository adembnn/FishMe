import SwiftUI

/// P03 (direction C) et P37 (direction A) : l'écran avant la demande de position. La fenêtre de position est celle d'iOS
/// (texte de `NSLocationWhenInUseUsageDescription`, dans les clés Info, à A) : elle se pose par-dessus cet écran.
/// - `.pleinEcran` (P03-C) : un rond de carte avec le point du pêcheur, « Où pêches-tu ? », trois poissons en images,
///   « Utiliser ma position » (seul bouton principal), « Choisir sur la carte ».
/// - `.feuille` (P37-A) : la même question en feuille façon Plans sur la carte, trois poissons en tuiles.
/// Ne demande rien lui-même : `utiliserMaPosition` lance la demande système, `choisirSurLaCarte` ouvre le choix de zone sans GPS.
/// À brancher dans `RootView.swift` : le montrer au premier lancement avant la demande de position, par exemple
/// `OuPechesTuView(presentation: .feuille, utiliserMaPosition: { /* demander la position */ }, choisirSurLaCarte: { app.choixDeZoneOuvert = true })`.
struct OuPechesTuView: View {
    enum Presentation { case pleinEcran, feuille }

    var presentation: Presentation = .pleinEcran
    let utiliserMaPosition: () -> Void
    let choisirSurLaCarte: () -> Void

    /// Les trois poissons de la maquette : des espèces communes, présentes dans toute la France.
    private let poissons: [(nom: String, libelle: String)] = [
        ("gardon", "Gardon"), ("brochet", "Brochet"), ("sandre", "Sandre"),
    ]

    var body: some View {
        switch presentation {
        case .pleinEcran: pleinEcran
        case .feuille: feuille
        }
    }

    private var boutons: some View {
        VStack(spacing: Espace.xs) {
            Button(action: utiliserMaPosition) {
                Label("Utiliser ma position", systemImage: "location.fill")
            }
            .buttonStyle(.principal)
            Button("Choisir sur la carte", action: choisirSurLaCarte)
                .font(Police.corps)
                .foregroundStyle(Palette.marine)
                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
        }
    }

    /// P03-C : rond de 280 pt à 110 pt du haut, texte à 430 pt, boutons à 40 pt du bas (mesures de la maquette, 390 × 844).
    private var pleinEcran: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    carteRonde
                        .padding(.top, 51)
                    VStack(spacing: 0) {
                        Text("Où pêches-tu ?")
                            .font(Police.grandTitre)
                            .foregroundStyle(Palette.encre)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text("Pour voir les poissons et les règles près de toi.")
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)
                        HStack(spacing: 18) {
                            ForEach(poissons, id: \.nom) { poisson in
                                ImageEspece(nom: poisson.nom, libelle: poisson.libelle)
                                    .frame(width: 96, height: 56)
                            }
                        }
                        .padding(.top, 26)
                    }
                    .padding(.top, 40)
                    Spacer(minLength: Espace.xl)
                    boutons
                        .padding(.bottom, 6)
                }
                .padding(.horizontal, Espace.bord)
                .frame(minHeight: geo.size.height)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .accessibilityIdentifier("ou-peches-tu")
    }

    /// P37-A : feuille de coins 38 (poignée du système), titre de 22, phrase de 15, trois tuiles de 60 pt de haut
    /// (fond « tuile », coins 12, poisson à 86 % de la largeur sur 44 pt), « Utiliser ma position », « Choisir sur la carte ».
    private var feuille: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Où pêches-tu ?")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            Text("Ta position sert à montrer les poissons et les règles près de toi.")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            HStack(spacing: 10) {
                ForEach(poissons, id: \.nom) { poisson in
                    ImageEspece(nom: poisson.nom, libelle: poisson.libelle)
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .frame(height: 60)
                        .background(Palette.tuile, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 20)
            boutons
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.surface.ignoresSafeArea())
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(38)
        .accessibilityIdentifier("ou-peches-tu")
    }

    /// Rond de 280 pt : un plan clair dessiné (aucune carte de France), deux routes blanches, une large rivière bleue
    /// en diagonale, point « moi » au centre (maquette P03-C).
    private var carteRonde: some View {
        Color(red: 241 / 255, green: 244 / 255, blue: 248 / 255)
            .overlay {
                Canvas { contexte, taille in
                    let l = taille.width, h = taille.height
                    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: l * x, y: h * y) }
                    // Routes blanches.
                    var route1 = Path()
                    route1.move(to: pt(-0.05, 0.43))
                    route1.addCurve(to: pt(1.05, 0.56), control1: pt(0.3, 0.5), control2: pt(0.7, 0.5))
                    contexte.stroke(route1, with: .color(.white), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    var route2 = Path()
                    route2.move(to: pt(0.06, 0.4))
                    route2.addCurve(to: pt(0.08, 0.95), control1: pt(0.03, 0.55), control2: pt(0.1, 0.75))
                    contexte.stroke(route2, with: .color(.white), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    // Rivière : berges #C7DFF3 puis eau #9CC7EA, du haut vers le bas gauche.
                    var riviere = Path()
                    riviere.move(to: pt(0.4, -0.08))
                    riviere.addCurve(to: pt(0.58, 0.36), control1: pt(0.5, 0.1), control2: pt(0.62, 0.2))
                    riviere.addCurve(to: pt(0.3, 0.78), control1: pt(0.55, 0.52), control2: pt(0.42, 0.62))
                    riviere.addCurve(to: pt(0.14, 1.08), control1: pt(0.24, 0.86), control2: pt(0.18, 0.96))
                    contexte.stroke(riviere, with: .color(Color(red: 199 / 255, green: 223 / 255, blue: 243 / 255)),
                                    style: StrokeStyle(lineWidth: 66, lineCap: .butt, lineJoin: .round))
                    contexte.stroke(riviere, with: .color(Color(red: 156 / 255, green: 199 / 255, blue: 234 / 255)),
                                    style: StrokeStyle(lineWidth: 50, lineCap: .butt, lineJoin: .round))
                }
            }
            .frame(width: 280, height: 280)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Palette.filet, lineWidth: 1))
            .overlay {
                // Le point « moi » de la maquette : 20 pt bleu #2E7DE0, bord blanc de 3, halo de 8 à 18 %.
                let bleuMoi = Color(red: 46 / 255, green: 125 / 255, blue: 224 / 255)
                Circle()
                    .fill(bleuMoi)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    .background(Circle().fill(bleuMoi.opacity(0.18)).frame(width: 36, height: 36))
            }
            .accessibilityHidden(true)
    }
}
