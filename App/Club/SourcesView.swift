import SwiftUI

/// Page Sources : les lignes viennent de `credits.json` (via RootView), jamais d'un texte écrit ici.
/// La ligne Apple Weather est la vue de L12, placée par RootView ; elle n'est jamais redessinée ici.
struct SourcesView<MarqueMeteo: View>: View {
    let sources: [SourceClub]
    let marqueMeteo: MarqueMeteo

    var body: some View {
        List {
            Section {
                ForEach(sources) { source in
                    if let lien = source.lien {
                        Link(destination: lien) { ligne(source) }
                    } else {
                        ligne(source)
                    }
                }
            }
            Section {
                marqueMeteo
            }
        }
        .scrollIndicators(.hidden)
        .font(Police.corps)
        .scrollContentBackground(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .navigationTitle("Sources")
    }

    private func ligne(_ source: SourceClub) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(source.nom)
            Text(source.mention)
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
        }
    }
}
