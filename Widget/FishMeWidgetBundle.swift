import SwiftUI
import WidgetKit

// Point d'entrée de l'extension. À brancher par A : cible widget dans le projet (voir PilotageActivite.swift).
@main
struct FishMeWidgetBundle: WidgetBundle {
    var body: some Widget {
        SessionLiveActivity()
        AquariumWidget()
        CarteWidget()
        SessionWidget()
    }
}
