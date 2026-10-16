import SwiftUI
import Core

/// P42 « Ta zone » : l'écran quand la position est refusée. Tout reste accessible, rien ne bloque.
/// Les trois rangées « Toujours accessibles » mènent vers les autres volets : A branche les fermetures
/// (chaque rangée n'apparaît que si sa fermeture est donnée). Aucune donnée inventée : les compteurs sont optionnels.
struct SansPositionView: View {
    /// Nom de la zone choisie à la main (département ou commune) ; `nil` tant qu'elle n'est pas posée.
    let zone: String?
    let changerDeZone: () -> Void
    let autoriserPosition: () -> Void
    let voirLaCarte: () -> Void
    var ouvrirPescedex: (() -> Void)?
    var ouvrirAmis: (() -> Void)?
    var ouvrirConseils: (() -> Void)?
    /// À brancher : « 3 espèces » et « 3 amis » viennent du Pescedex et des amis (L7/L8) ; vides par défaut.
    var compteurPescedex: String?
    var compteurAmis: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text("Ta zone")
                        .font(Police.grandTitre)
                        .foregroundStyle(Palette.encre)
                        .accessibilityAddTraits(.isHeader)
                    Text("Choisie à la main, sans ta position.")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }

                groupe {
                    rangee("mappin.and.ellipse", zone ?? "Choisir ma zone", valeur: nil, action: changerDeZone)
                }

                if ouvrirPescedex != nil || ouvrirAmis != nil || ouvrirConseils != nil {
                    titreGroupe("Toujours accessibles")
                    groupe {
                        if let ouvrirPescedex { rangee("square.grid.2x2", "Pescedex", valeur: compteurPescedex, action: ouvrirPescedex) }
                        if let ouvrirAmis { rangee("person.2", "Amis", valeur: compteurAmis, action: ouvrirAmis) }
                        if let ouvrirConseils { rangee("doc.text", "Conseils de pêche", valeur: nil, action: ouvrirConseils) }
                    }
                }

                titreGroupe("Position")
                groupe {
                    HStack(spacing: Espace.m) {
                        Image(systemName: "location.slash")
                            .foregroundStyle(Palette.marine)
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text("Utiliser ma position")
                            .font(Police.corps)
                            .foregroundStyle(Palette.encre)
                        Spacer(minLength: Espace.s)
                        Text("Non")
                            .font(Police.corps)
                            .foregroundStyle(Palette.encreDouce)
                    }
                    .frame(minHeight: Gabarit.zoneTactile)
                    .accessibilityElement(children: .combine)
                    Divider().overlay(Palette.filet)
                    Button(action: autoriserPosition) {
                        HStack {
                            Text("Autoriser la position")
                                .font(Police.corps)
                                .foregroundStyle(Palette.marine)
                            Spacer(minLength: Espace.s)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Palette.silhouette)
                                .accessibilityHidden(true)
                        }
                        .frame(minHeight: Gabarit.zoneTactile)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Text("Sans position, les règles, les relevés de l'Office français de la biodiversité (OFB) et ton spot marchent pareil.")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.horizontal, Espace.s)

                Button("Voir la carte", action: voirLaCarte)
                    .buttonStyle(.principal)
                    .padding(.top, Espace.xl)
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
    }

    private func titreGroupe(_ texte: String) -> some View {
        Text(texte)
            .font(Police.legende)
            .foregroundStyle(Palette.encreDouce)
            .textCase(.uppercase)
            .padding(.horizontal, Espace.s)
            .accessibilityAddTraits(.isHeader)
    }

    private func groupe<Contenu: View>(@ViewBuilder _ contenu: () -> Contenu) -> some View {
        VStack(spacing: 0) { contenu() }
            .padding(.horizontal, Espace.l)
            .tuileFishMe(rayon: Rayon.l)
    }

    private func rangee(_ symbole: String, _ titre: String, valeur: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Espace.m) {
                Image(systemName: symbole)
                    .foregroundStyle(Palette.marine)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                Text(titre)
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: Espace.s)
                if let valeur {
                    Text(valeur)
                        .font(Police.corps)
                        .foregroundStyle(Palette.encreDouce)
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(Palette.silhouette)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Gabarit.zoneTactile)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    SansPositionView(zone: nil, changerDeZone: {}, autoriserPosition: {}, voirLaCarte: {})
}
#endif
