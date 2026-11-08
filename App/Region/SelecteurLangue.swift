import SwiftUI

/// La ligne « Langue » des Réglages : Français / English. Indépendante de la région (règles, unités).
/// Le choix est gardé sur l'iPhone ; sans choix, la langue suit la région.
struct SelecteurLangue: View {
    @Environment(RegionCourante.self) private var regionCourante

    var body: some View {
        let textes = TextesOnboarding(langue: regionCourante.langue)
        Menu {
            Picker(textes.langueReglage, selection: Binding(get: { regionCourante.langue }, set: { regionCourante.langueChoisie = $0 })) {
                ForEach(LangueApp.allCases) { langue in
                    Text(langue.nomPropre).tag(langue)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text(textes.langueReglage)
                    .foregroundStyle(Palette.encre)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(regionCourante.langue.nomPropre).foregroundStyle(Palette.encreDouce)
            }
            .font(Police.corps)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .frame(minHeight: 46)
        }
        .accessibilityIdentifier("reglages.langue")
    }
}
