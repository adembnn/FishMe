import SwiftUI

/// Une carte d'exemple du fil « Découvrir ». Tout est inventé : aucune vraie prise, aucun vrai pêcheur.
private struct CarteExemple: Identifiable {
    let id: Int
    /// Nom de l'image dans les ressources (dossier Especes).
    let image: String
    let espece: String
    let tailleCm: Int
    /// Département, jamais un lieu exact.
    let departement: String
    let prenom: String
    let rarete: StyleRarete
    /// J'aime d'exemple, sert au classement « du mois ».
    let jaimeDeBase: Int
    /// Ancienneté en jours, sert à l'ordre « Récentes ».
    let ilYAJours: Int

    static let exemples: [CarteExemple] = [
        CarteExemple(id: 1, image: "brochet", espece: "Brochet", tailleCm: 82, departement: "Seine-et-Marne (77)", prenom: "Léa", rarete: .peuCommun, jaimeDeBase: 128, ilYAJours: 3),
        CarteExemple(id: 2, image: "truite-fario", espece: "Truite fario", tailleCm: 34, departement: "Haute-Savoie (74)", prenom: "Mathis", rarete: .commun, jaimeDeBase: 214, ilYAJours: 9),
        CarteExemple(id: 3, image: "sandre", espece: "Sandre", tailleCm: 67, departement: "Val-de-Marne (94)", prenom: "Camille", rarete: .rare, jaimeDeBase: 96, ilYAJours: 1),
        CarteExemple(id: 4, image: "perche-commune", espece: "Perche commune", tailleCm: 29, departement: "Loire-Atlantique (44)", prenom: "Hugo", rarete: .commun, jaimeDeBase: 57, ilYAJours: 5),
        CarteExemple(id: 5, image: "carpe-commune", espece: "Carpe commune", tailleCm: 71, departement: "Seine-Saint-Denis (93)", prenom: "Inès", rarete: .peuCommun, jaimeDeBase: 175, ilYAJours: 12),
        CarteExemple(id: 6, image: "silure-glane", espece: "Silure glane", tailleCm: 148, departement: "Hauts-de-Seine (92)", prenom: "Noah", rarete: .rare, jaimeDeBase: 241, ilYAJours: 7),
        CarteExemple(id: 7, image: "ombre-commun", espece: "Ombre commun", tailleCm: 38, departement: "Doubs (25)", prenom: "Zoé", rarete: .legendaire, jaimeDeBase: 83, ilYAJours: 2),
        CarteExemple(id: 8, image: "black-bass", espece: "Black-bass", tailleCm: 41, departement: "Gironde (33)", prenom: "Lucas", rarete: .peuCommun, jaimeDeBase: 142, ilYAJours: 15),
        CarteExemple(id: 9, image: "chevesne", espece: "Chevesne", tailleCm: 33, departement: "Paris (75)", prenom: "Manon", rarete: .commun, jaimeDeBase: 41, ilYAJours: 4),
        CarteExemple(id: 10, image: "tanche", espece: "Tanche", tailleCm: 36, departement: "Essonne (91)", prenom: "Jules", rarete: .peuCommun, jaimeDeBase: 108, ilYAJours: 20)
    ]
}

/// Page « Découvrir » : un aperçu du futur fil de cartes, avec des cartes d'exemple seulement.
/// Rien n'est envoyé, rien n'est publié : les « j'aime » restent sur cet écran.
/// Le classement « Cartes du mois » compte les j'aime d'exemple, jamais la rareté.
struct DecouvrirView: View {
    private enum Tri: String, CaseIterable, Identifiable {
        case mois = "Cartes du mois"
        case recentes = "Récentes"
        var id: String { rawValue }
    }

    @State private var tri: Tri = .mois
    @State private var aimees: Set<Int> = []

    init() {}

    private var cartes: [CarteExemple] {
        switch tri {
        case .mois: return CarteExemple.exemples.sorted { $0.jaimeDeBase > $1.jaimeDeBase }
        case .recentes: return CarteExemple.exemples.sorted { $0.ilYAJours < $1.ilYAJours }
        }
    }

    var body: some View {
        VStack(spacing: Espace.m) {
            bandeau
            Picker("Classement", selection: $tri) {
                ForEach(Tri.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Espace.bord)

            ScrollView(.vertical) {
                LazyVStack(spacing: Espace.m) {
                    ForEach(cartes) { carte in
                        carteGrande(carte)
                            .containerRelativeFrame(.vertical)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .id(tri)
        }
        .padding(.top, Espace.s)
        .background(Palette.fond)
        .navigationTitle("Découvrir")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bandeau: some View {
        HStack(alignment: .top, spacing: Espace.s) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Palette.marine)
                .accessibilityHidden(true)
            Text("Aperçu avec des cartes d'exemple. Le partage public arrive dans une prochaine version.")
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Espace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .padding(.horizontal, Espace.bord)
    }

    private func carteGrande(_ carte: CarteExemple) -> some View {
        let aime = aimees.contains(carte.id)
        let total = carte.jaimeDeBase + (aime ? 1 : 0)
        return VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                LinearGradient(colors: carte.rarete.fond, startPoint: .top, endPoint: .bottom)
                Image(carte.image)
                    .resizable()
                    .scaledToFit()
                    .padding(Espace.xl)
                    .accessibilityHidden(true)
                Text("Exemple")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encre)
                    .padding(.horizontal, Espace.m)
                    .padding(.vertical, Espace.xs)
                    .background(Palette.surface, in: Capsule())
                    .padding(Espace.m)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(alignment: .leading, spacing: Espace.s) {
                HStack(alignment: .firstTextBaseline) {
                    Text(carte.espece)
                        .font(Police.titre)
                        .foregroundStyle(Palette.encre)
                    Spacer(minLength: Espace.s)
                    Text("\(carte.tailleCm) cm")
                        .font(Police.chiffreMoyen)
                        .foregroundStyle(Palette.encre)
                }
                Text("\(carte.departement) · \(carte.prenom) (exemple)")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                HStack {
                    Text(carte.rarete.mot.capitalized)
                        .font(Police.legende)
                        .foregroundStyle(carte.rarete.couleur)
                        .padding(.horizontal, Espace.m)
                        .padding(.vertical, Espace.xs)
                        .background(carte.rarete.couleur.opacity(0.15), in: Capsule())
                    Spacer()
                    Button {
                        if aime { aimees.remove(carte.id) } else { aimees.insert(carte.id) }
                    } label: {
                        Label("\(total)", systemImage: aime ? "heart.fill" : "heart")
                            .font(Police.corps)
                            .foregroundStyle(aime ? Palette.bouchon : Palette.encre)
                            .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(aime ? "Je n'aime plus cette carte d'exemple" : "J'aime cette carte d'exemple")
                    .accessibilityValue("\(total) j'aime")
                }
            }
            .padding(Espace.l)
        }
        .tuileFishMe(rayon: Rayon.l)
        .clipShape(RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, Espace.s)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    NavigationStack { DecouvrirView() }
}
