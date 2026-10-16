import SwiftUI
import Core

/// Une épingle d'eau sur la carte : cours d'eau (vagues), plan d'eau (goutte) ou coin public (pêcheur).
/// Ronde et aqua, plus petite que la station OFB (poisson marine) : on voit tout de suite qui est qui.
struct MarqueEauView: View {
    let spot: SpotEau
    /// Vrai avant la 1re session : le toucher pose le cercle de 1 km. Sinon il ouvre seulement la fiche.
    let poseLeSpot: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: spot.origine.symboleSF)
                .font(Police.taille(12, .semibold))
                .foregroundStyle(Palette.surMarine)
                .frame(width: 24, height: 24)
                .background(CouleursCarte.aqua, in: Circle())
                .overlay(Circle().stroke(Palette.surface, lineWidth: 1.5))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(spot.origine.libelle) : \(spot.nom)")
        .accessibilityHint(poseLeSpot ? "Pose ton spot ici" : "Ouvre la fiche du coin")
    }
}

/// Un regroupement de spots d'eau au dézoom : le nombre, un toucher zoome dessus.
struct MarqueGroupeEauView: View {
    let nombre: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: "water.waves")
                    .font(Police.taille(11, .semibold))
                    .accessibilityHidden(true)
                Text("\(nombre)")
                    .font(PolicesCarte.detail())
            }
            .foregroundStyle(Palette.surMarine)
            .padding(.horizontal, 8)
            .frame(minWidth: 36, minHeight: 28)
            .background(CouleursCarte.aqua, in: Capsule())
            .overlay(Capsule().stroke(Palette.surface, lineWidth: 1.5))
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(nombre) points d'eau")
        .accessibilityHint("Zoomer pour les voir")
    }
}
