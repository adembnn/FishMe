import SwiftUI

/// Le petit compte de la page Carte : initiale, nom de profil et badge, en haut à gauche. Un toucher ouvre le profil.
/// Aucun vrai compte : le nom et le badge restent sur l'iPhone (le badge vient du nombre de cartes).
struct ProfilPastille: View {
    @Environment(\.locale) private var locale
    let nom: String
    /// `nil` tant que les cartes ne sont pas lues : le badge de niveau n'est pas montré (jamais un niveau faux).
    let nombreDeCartes: Int?
    let ouvrir: () -> Void

    var body: some View {
        Button(action: ouvrir) {
            HStack(spacing: Espace.s) {
                AvatarProfil(nom: nom, taille: 32)
                VStack(alignment: .leading, spacing: 0) {
                    Text(nom).font(Police.detail).foregroundStyle(Palette.encre).lineLimit(1)
                    if let nombreDeCartes {
                        Label(BadgeProfil.niveau(cartes: nombreDeCartes, locale: locale).titre,
                              systemImage: BadgeProfil.niveau(cartes: nombreDeCartes).symbole)
                            .font(Police.legende)
                            .foregroundStyle(Palette.marine)
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
            .padding(.leading, 6)
            .padding(.trailing, Espace.m)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.filet, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(nombreDeCartes.map { AnglaisB.t("Mon profil, \(nom), \(BadgeProfil.niveau(cartes: $0, locale: locale).titre)", locale) } ?? AnglaisB.t("Mon profil, \(nom)", locale))
    }
}

/// Rond avec l'initiale du nom de profil.
struct AvatarProfil: View {
    let nom: String
    let taille: CGFloat

    var body: some View {
        Text(String(nom.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased())
            .font(Police.taille(taille * 0.5, .heavy))
            .foregroundStyle(Palette.surMarine)
            .frame(width: taille, height: taille)
            .background(Palette.marine, in: Circle())
            .accessibilityHidden(true)
    }
}

/// Le badge se gagne avec les cartes de son Pescedex, jamais avec la rareté ni la taille des prises.
enum BadgeProfil {
    static func niveau(cartes: Int, locale: Locale = AnglaisB.francais) -> (titre: String, symbole: String) {
        switch cartes {
        case ..<3: (AnglaisB.t("Débutant", locale), "leaf.fill")
        case ..<10: (AnglaisB.t("Pêcheur", locale), "fish.fill")
        case ..<25: (AnglaisB.t("Confirmé", locale), "star.fill")
        default: (AnglaisB.t("Expert", locale), "rosette")
        }
    }
}

#Preview {
    ProfilPastille(nom: "Titouan", nombreDeCartes: 12) {}
        .padding()
        .background(Palette.fond)
}
