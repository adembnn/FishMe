import MapKit
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
        VStack(spacing: 0) {
            carteRonde
                .padding(.top, Espace.xxl * 2)
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
            Button("Choisir sur la carte", action: choisirSurLaCarte)
                .font(Police.corps)
                .foregroundStyle(Palette.marine)
                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                .padding(.top, Espace.xs)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, Espace.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .accessibilityIdentifier("ou-peches-tu")
    }

    /// Rond de 280 pt : un extrait de carte fixe (milieu de la France, sans GPS) et le point marine du pêcheur au centre.
    private var carteRonde: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5),
            span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6))))
            .allowsHitTesting(false)
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
