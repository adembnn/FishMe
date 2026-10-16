import SwiftUI

/// P03 (direction C) : l'écran avant la demande de position. Un rond de carte avec le point du pêcheur,
/// « Où pêches-tu ? », trois poissons en images, « Utiliser ma position » (seul bouton principal), « Choisir sur la carte ».
/// Ne demande rien lui-même : `utiliserMaPosition` lance la demande système, `choisirSurLaCarte` ouvre le choix de zone sans GPS.
/// À brancher dans `RootView.swift` : le montrer au premier lancement avant la demande de position, par exemple
/// `OuPechesTuView(utiliserMaPosition: { /* demander la position */ }, choisirSurLaCarte: { app.choixDeZoneOuvert = true })`.
struct OuPechesTuView: View {
    let utiliserMaPosition: () -> Void
    let choisirSurLaCarte: () -> Void

    /// Les trois poissons de la maquette : des espèces communes, présentes dans toute la France.
    private let poissons: [(nom: String, libelle: String)] = [
        ("gardon", "Gardon"), ("brochet", "Brochet"), ("sandre", "Sandre"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                carteRonde
                VStack(spacing: Espace.m) {
                    Text("Où pêches-tu ?")
                        .font(Police.grandTitre)
                        .foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("Pour voir les poissons et les règles près de toi.")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 18) {
                        ForEach(poissons, id: \.nom) { poisson in
                            ImageEspece(nom: poisson.nom, libelle: poisson.libelle)
                                .frame(width: 96, height: 56)
                        }
                    }
                    .padding(.top, Espace.m)
                }
                .padding(.top, Espace.xl)
                Spacer(minLength: Espace.xl)
                Button(action: utiliserMaPosition) {
                    Label("Utiliser ma position", systemImage: "location.fill")
                }
                .buttonStyle(.principal)
                .padding(.top, Espace.xl)
                Button("Choisir sur la carte", action: choisirSurLaCarte)
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .padding(.top, Espace.xs)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, 96)
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
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
                Circle()
                    .fill(Palette.marine)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 3))
                    .shadow(color: Palette.encre.opacity(0.25), radius: 4, y: 2)
            }
            .accessibilityHidden(true)
    }
}
