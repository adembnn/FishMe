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
                        LigneSortie(titre: "Ma fédération", sousTitre: liens.nomFederation, icone: "building.columns")
                    }
                    // Sans association connue, la ligne ouvre la page nationale : le libellé le dit.
                    Link(destination: liens.association ?? liens.carteDePeche) {
                        LigneSortie(titre: liens.association == nil ? "Trouver mon association (AAPPMA)" : "Mon association",
                                    sousTitre: nil, icone: "person.3")
                    }
                    Toggle(isOn: $aSaCarte) {
                        Label("J'ai ma carte de pêche 2026", systemImage: "checkmark.seal")
                    }
                    Link(destination: liens.carteDePeche) {
                        LigneSortie(titre: "Voir la carte de pêche sur le site officiel", sousTitre: nil, icone: "safari")
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
                            LigneSortie(titre: "Politique de confidentialité", sousTitre: nil, icone: "hand.raised")
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
                            LigneSortie(titre: "Contact", sousTitre: nil, icone: "envelope")
                        }
                    }
                    if let erreur = ContactClub.erreurDeRegle {
                        Link(destination: erreur) {
                            LigneSortie(titre: "Signaler une erreur de règle", sousTitre: nil, icone: "flag")
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

/// Une ligne qui ouvre Safari ou Mail : titre, sous-titre facultatif et petite flèche de sortie.
private struct LigneSortie: View {
    let titre: String
    let sousTitre: String?
    let icone: String

    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titre)
                    if let sousTitre {
                        Text(sousTitre).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: icone)
            }
            Spacer(minLength: 8)
            Image(systemName: "arrow.up.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
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
