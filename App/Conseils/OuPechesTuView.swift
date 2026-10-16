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

    /// Rond de 280 pt : une rivière dessinée (aucune carte de France), fond marine doux, point marine du pêcheur au centre.
    private var carteRonde: some View {
        Palette.marineDoux
            .overlay {
                Canvas { contexte, taille in
                    let l = taille.width, h = taille.height
                    var riviere = Path()
                    riviere.move(to: CGPoint(x: -10, y: h * 0.78))
                    riviere.addCurve(to: CGPoint(x: l * 0.5, y: h * 0.5),
                                     control1: CGPoint(x: l * 0.25, y: h * 0.9),
                                     control2: CGPoint(x: l * 0.3, y: h * 0.5))
                    riviere.addCurve(to: CGPoint(x: l + 10, y: h * 0.18),
                                     control1: CGPoint(x: l * 0.72, y: h * 0.5),
                                     control2: CGPoint(x: l * 0.8, y: h * 0.1))
                    contexte.stroke(riviere, with: .color(Palette.eau),
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
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
