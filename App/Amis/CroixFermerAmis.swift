import SwiftUI

/// Petite croix ronde pour quitter un écran présenté (feuille). Sans action donnée, elle ferme la feuille (`dismiss`).
struct CroixFermerAmis: View {
    var action: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            if let action { action() } else { dismiss() }
        } label: {
            Image(systemName: "xmark")
                .font(JetonAmis.police(17))
                .frame(width: JetonAmis.zoneTactile, height: JetonAmis.zoneTactile)
                .background(.regularMaterial, in: Circle())
                .foregroundStyle(JetonAmis.encre)
        }
        .accessibilityLabel("Fermer")
    }
}
