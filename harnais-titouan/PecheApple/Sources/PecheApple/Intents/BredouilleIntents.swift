// NON COMPILÉ : écrit sans compilateur Swift. Stub : signatures seulement.
import Foundation
#if canImport(AppIntents)
import AppIntents
#endif

// Raccourcis Siri / Bouton Action (lot L23, bonus) :
//   « Démarre une sortie » et « Ajoute une prise dans Bredouille ».
// Aucun intent n'est déclaré tant que le câblage n'existe pas : un stub AppIntents non compilé
// ferait échouer le build sur Mac. TODO(Adem) : déclarer les intents ci-dessous sous #if canImport(AppIntents).

#if canImport(AppIntents)
// TODO(Adem) :
// @available(iOS 26.0, *)
// struct StartTripIntent: AppIntent {
//     static var title: LocalizedStringResource = "Démarrer une sortie"
//     func perform() async throws -> some IntentResult { .result() }
// }
// @available(iOS 26.0, *)
// struct AddCatchIntent: AppIntent { /* ouvre l'app sur la caméra */ }
// @available(iOS 26.0, *)
// struct BredouilleShortcuts: AppShortcutsProvider { /* phrases en français */ }
#endif

/// Marqueur pour que le fichier ne soit pas vide et pour tracer le lot.
public enum BredouilleIntentsPlaceholder {
    public static let lot = "L23"
}
