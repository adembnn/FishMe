import SwiftUI

/// Sécurité au bord de l'eau : gratuite, jamais derrière le paywall, rien n'y est calculé.
struct SecuriteView: View {
    var body: some View {
        List {
            Section {
                Label("Orage : range la canne en carbone, éloigne-toi de l'eau.", systemImage: "cloud.bolt")
                Label("Crue : ne pêche pas au bord d'une rivière en crue.", systemImage: "water.waves")
            } footer: {
                Text("L'alerte officielle fait foi.")
            }
            Section("Alertes officielles") {
                Link(destination: LiensOfficiels.vigilanceMeteoFrance) {
                    Label("Vigilance Météo-France", systemImage: "cloud.sun")
                }
                Link(destination: LiensOfficiels.vigicrues) {
                    Label("Vigicrues", systemImage: "drop.triangle")
                }
            }
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Sécurité")
    }
}
