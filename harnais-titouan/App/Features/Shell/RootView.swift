// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
import SwiftUI

/// Coque de l'app : 4 onglets. L'app s'ouvre sur « Prendre » (la caméra), sans écran avant (règle B9).
/// La barre d'onglets reçoit le Liquid Glass automatiquement avec le SDK 26 : ne rien ajouter.
struct RootView: View {
    enum Onglet: Hashable { case prendre, collection, preparer, profil }

    @State private var selection: Onglet = .prendre

    var body: some View {
        TabView(selection: $selection) {
            SwiftUI.Tab("Prendre", systemImage: "camera", value: Onglet.prendre) {
                CapturePlaceholderView()
            }
            SwiftUI.Tab("Collection", systemImage: "square.grid.2x2", value: Onglet.collection) {
                CollectionPlaceholderView()
            }
            SwiftUI.Tab("Préparer", systemImage: "list.bullet.clipboard", value: Onglet.preparer) {
                PreparePlaceholderView()
            }
            SwiftUI.Tab("Profil", systemImage: "person.crop.circle", value: Onglet.profil) {
                ProfilePlaceholderView()
            }
        }
    }
}

#Preview {
    RootView()
}
