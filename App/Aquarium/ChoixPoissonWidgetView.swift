import SwiftUI

/// « Quel poisson dans ton widget ? » : la liste des poissons du Pescedex en images, un seul choix. Le choix est écrit
/// dans le fichier partagé (App Group) par `PontAquariumWidget.choisir(poissonId:)` et le widget se recharge : un seul
/// poisson y nage. Sans choix, c'est le plus rare. « Modifier le widget » (appui long) passe avant ce choix.
/// Aucun lieu : seulement des noms et des images d'espèces. Nouveau fichier du lot widget-fluide ; l'aquarium de l'app
/// n'est pas touché.
///
/// À brancher (hors lot) : une feuille `.sheet { ChoixPoissonWidgetView() }` ouverte depuis le Pescedex ou les réglages.
struct ChoixPoissonWidgetView: View {
    /// Fermeture : appelée par la croix (la feuille se ferme aussi d'elle-même par un geste vers le bas).
    var fermer: (() -> Void)? = nil
    /// Remplaçable dans les tests et les aperçus : le fichier partagé lu à l'ouverture, et l'écriture du choix.
    var lire: () -> InstantaneAquarium = { DepotAquariumWidget.lire() }
    var ecrire: (String?) -> Void = { PontAquariumWidget.choisir(poissonId: $0) }

    @State private var instantane = InstantaneAquarium.vide
    @Environment(\.dynamicTypeSize) private var tailleTexte

    private var colonnes: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Espace.m), count: tailleTexte.isAccessibilitySize ? 1 : 2)
    }

    /// Le poisson montré dans le widget : le choix s'il existe encore dans le Pescedex, sinon aucun (= le plus rare).
    private var choisi: String? {
        guard let id = instantane.choix, instantane.poissons.contains(where: { $0.id == id }) else { return nil }
        return id
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                HStack {
                    Text("Quel poisson dans ton widget ?")
                        .font(Police.titre)
                        .foregroundStyle(Palette.encre)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: Espace.m)
                    if let fermer { BoutonRond(role: .fermer, action: fermer) }
                }
                if instantane.poissons.isEmpty {
                    Text(Self.texteVide)
                        .font(Police.corps)
                        .foregroundStyle(Palette.encreDouce)
                } else {
                    automatique
                    LazyVGrid(columns: colonnes, spacing: Espace.m) {
                        ForEach(instantane.poissons) { tuile($0) }
                    }
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.l)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .onAppear { instantane = lire() }
    }

    private static let texteVide = "Ta première prise nagera ici"

    /// « Le plus rare » : pas de choix, le widget prend le poisson le plus rare du Pescedex.
    private var automatique: some View {
        Button {
            choisir(nil)
        } label: {
            HStack(spacing: Espace.m) {
                Image(systemName: "star.fill")
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.marine)
                Text("Le plus rare de ton Pescedex")
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.encre)
                Spacer(minLength: 0)
                if choisi == nil { coche }
            }
            .padding(Espace.m)
            .frame(minHeight: Gabarit.zoneTactile)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(choisi == nil ? .isSelected : [])
    }

    private var coche: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(Police.sousTitre)
            .foregroundStyle(Palette.ouvert)
            .accessibilityHidden(true)
    }

    private func tuile(_ poisson: InstantaneAquarium.Poisson) -> some View {
        let actuel = choisi == poisson.id
        let nom = poisson.nom ?? poisson.slug
        return Button {
            choisir(poisson.id)
        } label: {
            VStack(spacing: Espace.s) {
                // Le même dessin que dans l'aquarium de l'app (`ImagePoisson`, image fixe de l'espèce).
                ImagePoisson(slug: poisson.slug, image: nil, largeur: 110, sens: 1)
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .overlay(alignment: .topTrailing) { if actuel { coche } }
                Text(nom)
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Self.libelleRarete(poisson.rarete))
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
            }
            .padding(Espace.m)
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
            .background(actuel ? Palette.marineDoux : Palette.surface,
                        in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(nom), \(Self.libelleRarete(poisson.rarete))" + (actuel ? ", choisi" : ""))
        .accessibilityAddTraits(actuel ? .isSelected : [])
    }

    static func libelleRarete(_ rarete: Int) -> String {
        ["Commun", "Peu commun", "Rare", "Légendaire"][min(max(rarete, 0), 3)]
    }

    private func choisir(_ id: String?) {
        ecrire(id)
        instantane.choix = id
    }
}

#if DEBUG
#Preview("Quel poisson dans ton widget ?") {
    ChoixPoissonWidgetView(
        lire: { EntreeAquarium.exempleRendu(pro: true).instantane },
        ecrire: { _ in })
}
#endif
