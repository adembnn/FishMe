import SwiftUI

/// Petite croix ronde pour quitter un écran présenté. Sans action donnée, elle ferme la feuille (`dismiss`).
struct CroixFermer: View {
    var action: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            if let action { action() } else { dismiss() }
        } label: {
            Image(systemName: "xmark")
                .font(Police.sousTitre)
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .background(.regularMaterial, in: Circle())
                .foregroundStyle(Palette.encre)
        }
        .accessibilityLabel("Fermer")
    }
}

extension View {
    /// Pose la croix en haut à droite de l'écran.
    func avecCroixFermer(_ action: (() -> Void)? = nil) -> some View {
        overlay(alignment: .topTrailing) {
            CroixFermer(action: action).padding(Espace.m)
        }
    }
}
