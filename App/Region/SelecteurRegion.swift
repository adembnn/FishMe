import Core
import SwiftUI

/// La ligne « Région » des Réglages : Automatique / France / États-Unis. Le choix est gardé sur l'iPhone ;
/// en automatique, la région vient de la position, qui n'est jamais envoyée à l'extérieur.
struct SelecteurRegion: View {
    @Environment(RegionCourante.self) private var regionCourante

    var body: some View {
        @Bindable var regionCourante = regionCourante
        Menu {
            Picker("Région", selection: $regionCourante.choix) {
                ForEach(ChoixRegion.allCases) { choix in
                    Text(Self.nom(choix)).tag(choix)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text("Région")
                    .foregroundStyle(Palette.encre)
                    .frame(maxWidth: .infinity, alignment: .leading)
                valeur.foregroundStyle(Palette.encreDouce)
            }
            .font(Police.corps)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .frame(minHeight: 46)
        }
        .accessibilityIdentifier("reglages.region")
    }

    /// En automatique, la région en vigueur est rappelée : « Automatique · France ».
    private var valeur: Text {
        let choix = regionCourante.choix
        guard choix == .automatique else { return Text(Self.nom(choix)) }
        return Text(Self.nom(choix)) + Text(" · ") + Text(Self.nom(regionCourante.region))
    }

    private static func nom(_ choix: ChoixRegion) -> LocalizedStringKey {
        switch choix {
        case .automatique: "Automatique"
        case .france: "France"
        case .etatsUnis: "États-Unis"
        }
    }

    private static func nom(_ region: RegionApp) -> LocalizedStringKey {
        switch region {
        case .france: "France"
        case .etatsUnis: "États-Unis"
        }
    }
}
