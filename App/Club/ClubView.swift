import StoreKit
import SwiftUI

/// Volet droit : Mon club. Tout y est gratuit ; rien n'y vient d'un autre utilisateur.
struct ClubView<MarqueMeteo: View>: View {
    let liens: LiensClub
    let sources: [SourceClub]
    let cartes: [CarteAPartager]
    @Binding var mesureUsage: Bool
    let marqueMeteo: MarqueMeteo

    @AppStorage("club.cartePeche2026") private var aSaCarte = false
    @State private var gestionAbonnement = false

    init(liens: LiensClub, sources: [SourceClub], cartes: [CarteAPartager], mesureUsage: Binding<Bool>,
         @ViewBuilder marqueMeteo: () -> MarqueMeteo) {
        self.liens = liens
        self.sources = sources
        self.cartes = cartes
        _mesureUsage = mesureUsage
        self.marqueMeteo = marqueMeteo()
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Ma pêche") {
                    Link(destination: liens.federation ?? LiensOfficiels.federationNationale) {
                        Label("Ma fédération", systemImage: "building.columns")
                    }
                    Link(destination: liens.association ?? liens.carteDePeche) {
                        Label("Mon association", systemImage: "person.3")
                    }
                    Toggle(isOn: $aSaCarte) {
                        Label("J'ai ma carte de pêche 2026", systemImage: "checkmark.seal")
                    }
                    Link(destination: liens.carteDePeche) {
                        Label("Voir la carte de pêche sur le site officiel", systemImage: "safari")
                    }
                }

                Section("Partager") {
                    NavigationLink {
                        PartageCarteView(cartes: cartes)
                    } label: {
                        Label("Partager une carte en image", systemImage: "square.and.arrow.up")
                    }
                }

                Section {
                    NavigationLink {
                        SecuriteView()
                    } label: {
                        Label("Sécurité au bord de l'eau", systemImage: "exclamationmark.triangle")
                    }
                    NavigationLink {
                        SourcesView(sources: sources, marqueMeteo: marqueMeteo)
                    } label: {
                        Label("Sources des données", systemImage: "books.vertical")
                    }
                }

                Section("Confidentialité") {
                    if let page = liens.confidentialite {
                        Link(destination: page) {
                            Label("Politique de confidentialité", systemImage: "hand.raised")
                        }
                    }
                    Toggle(isOn: $mesureUsage) {
                        Label("Mesure d'usage", systemImage: "chart.bar")
                    }
                }

                Section {
                    Button {
                        gestionAbonnement = true
                    } label: {
                        Label("Mon abonnement", systemImage: "creditcard")
                    }
                    if let contact = ContactClub.contact {
                        Link(destination: contact) {
                            Label("Contact", systemImage: "envelope")
                        }
                    }
                    if let erreur = ContactClub.erreurDeRegle {
                        Link(destination: erreur) {
                            Label("Signaler une erreur de règle", systemImage: "flag")
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Mon club")
            .manageSubscriptionsSheet(isPresented: $gestionAbonnement)
        }
    }
}

extension ClubView where MarqueMeteo == EmptyView {
    init(liens: LiensClub, sources: [SourceClub], cartes: [CarteAPartager], mesureUsage: Binding<Bool>) {
        self.init(liens: liens, sources: sources, cartes: cartes, mesureUsage: mesureUsage) { EmptyView() }
    }
}

#if DEBUG
#Preview {
    ClubView(
        liens: LiensClub(),
        sources: [SourceClub(nom: "OpenStreetMap", mention: "© contributeurs OpenStreetMap",
                             lien: URL(string: "https://www.openstreetmap.org/copyright"))],
        cartes: [],
        mesureUsage: .constant(true)
    )
}
#endif
