// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
import SwiftUI

@main
struct BredouilleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(Theme.current.forcedScheme)
        }
    }
}
