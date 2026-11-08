import SwiftUI

/// La politique de confidentialité de FishMe, embarquée dans l'app pour se lire hors ligne (relecture App Store, 16 oct.).
/// Ne dit que ce que fait le build soumis : aucun coin exact ne quitte l'iPhone, photos sans GPS, pas de compte.
struct ConfidentialiteFeuille: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale

    private static let blocs: [(titre: String, texte: String)] = [
        ("Ta position", "Ta position sert à te montrer la carte, les règles et les relevés autour de toi. Elle reste sur ton iPhone : aucun coin de pêche exact n'est envoyé."),
        ("Tes prises et tes photos", "Ta collection et tes photos restent sur ton iPhone. Les photos enregistrées par FishMe n'ont pas de position GPS."),
        ("Météo et rivières", "Pour la météo (Apple Weather) et le niveau des rivières (Hub'Eau), l'app envoie seulement un point public : une station de relevés ou un point arrondi, jamais ta position exacte."),
        ("Abonnement", "Les achats passent par Apple. FishMe ne voit ni ton nom ni tes moyens de paiement."),
        ("Mesure d'audience", "Avec ton accord seulement, l'app mesure son usage de façon anonyme pour s'améliorer. Tu peux refuser sans rien perdre."),
        ("Contact", "Une question ou une demande sur tes données : fishme.app@gmail.com."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.l) {
                    ForEach(Self.blocs, id: \.titre) { bloc in
                        VStack(alignment: .leading, spacing: Espace.xs) {
                            Text(AnglaisE.t(bloc.titre, locale))
                                .font(Police.sousTitre)
                                .foregroundStyle(Palette.encre)
                            Text(AnglaisE.t(bloc.texte, locale))
                                .font(Police.corps)
                                .foregroundStyle(Palette.encreDouce)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(Espace.bord)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .background(Palette.fond.ignoresSafeArea())
            .navigationTitle(Text("Confidentialité", tableName: AnglaisE.table))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}
