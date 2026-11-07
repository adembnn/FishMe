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
    /// Code du département de la zone (« 94 ») et nom de la commune, s'ils sont connus ; sinon la rangée ne les montre pas.
    /// À brancher : RootView donne aujourd'hui le nom de la zone seulement.
    var codeZone: String?
    var commune: String?
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AnglaisFCarte.t("Ta zone", locale))
                        .font(Police.taille(34, .heavy))
                        .foregroundStyle(Palette.encre)
                        .accessibilityAddTraits(.isHeader)
                    Text(AnglaisFCarte.t("Choisie à la main, sans ta position.", locale))
                        .font(Police.taille(15))
                        .foregroundStyle(Palette.encreDouce)
                }

                groupe {
                    rangeeZone(zone ?? AnglaisFCarte.t("Choisir ma zone", locale), valeur: codeZone)
                    if let commune {
                        filet(84)
                        rangeeZone(commune, valeur: AnglaisFCarte.t("Commune", locale))
                    }
                }
                .padding(.top, 20)

                if ouvrirPescedex != nil || ouvrirAmis != nil || ouvrirConseils != nil {
                    titreGroupe(AnglaisFCarte.t("Toujours accessibles", locale))
                    groupe {
                        if let ouvrirPescedex { rangee("fish.circle", "Pescedex", valeur: compteurPescedex, action: ouvrirPescedex) }
                        if let ouvrirAmis {
                            if ouvrirPescedex != nil { filet(16) }
                            rangee("person.2", AnglaisFCarte.t("Amis", locale), valeur: compteurAmis, action: ouvrirAmis)
                        }
                        if let ouvrirConseils {
                            if ouvrirPescedex != nil || ouvrirAmis != nil { filet(16) }
                            rangee("doc.text", AnglaisFCarte.t("Conseils de pêche", locale), valeur: nil, action: ouvrirConseils)
                        }
                    }
                }

                titreGroupe(AnglaisFCarte.t("Position", locale))
                groupe {
                    HStack(spacing: Espace.m) {
                        Image(systemName: "location.slash")
                            .font(Police.taille(22))
                            .foregroundStyle(Palette.marine)
                            .frame(width: 26)
                            .accessibilityHidden(true)
                        Text(AnglaisFCarte.t("Utiliser ma position", locale))
                            .font(Police.corps)
                            .foregroundStyle(Palette.encre)
                        Spacer(minLength: Espace.s)
                        Text(AnglaisFCarte.t("Non", locale))
                            .font(Police.corps)
                            .foregroundStyle(Palette.encreDouce)
                    }
                    .padding(.horizontal, Espace.l)
                    .frame(minHeight: 56)
                    .accessibilityElement(children: .combine)
                    filet(16)
                    Button(action: autoriserPosition) {
                        HStack {
                            Text(AnglaisFCarte.t("Autoriser la position", locale))
                                .font(Police.corps)
                                .foregroundStyle(Palette.marine)
                            Spacer(minLength: Espace.s)
                            Image(systemName: "chevron.right")
                                .font(Police.taille(13))
                                .foregroundStyle(Palette.silhouette)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, Espace.l)
                        .frame(minHeight: 56)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                Text(AnglaisFCarte.t("Sans position, les règles, les relevés OFB et ton spot marchent pareil.", locale))
                    .font(Police.taille(13))
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.horizontal, Espace.l)
                    .padding(.top, 8)
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(AnglaisFCarte.t("Voir la carte", locale), action: voirLaCarte)
                .buttonStyle(.principal)
                .padding(.horizontal, Espace.bord)
                .padding(.bottom, Espace.s)
                .padding(.top, Espace.s)
        }
        .background(Palette.fond.ignoresSafeArea())
    }

    private func titreGroupe(_ texte: String) -> some View {
        Text(texte)
            .font(Police.taille(13, .heavy))
            .foregroundStyle(Palette.encreDouce)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, Espace.l)
            .padding(.top, 22)
            .padding(.bottom, Espace.s)
            .accessibilityAddTraits(.isHeader)
    }

    /// Filet du bas d'une rangée : de l'inset au bord droit, comme `.ligne+.ligne` de la maquette.
    private func filet(_ inset: CGFloat) -> some View {
        Divider().overlay(Palette.filet).padding(.leading, inset)
    }

    private func groupe<Contenu: View>(@ViewBuilder _ contenu: () -> Contenu) -> some View {
        VStack(spacing: 0) { contenu() }
            .tuileFishMe(rayon: Rayon.m)
    }

    /// Une zone : une petite vignette de carte (rivière sur fond clair), le nom, le code, le chevron.
    private func rangeeZone(_ titre: String, valeur: String?) -> some View {
        Button(action: changerDeZone) {
            HStack(spacing: Espace.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Palette.fond)
                    Capsule()
                        .fill(Palette.eau)
                        .frame(width: 10, height: 60)
                        .rotationEffect(.degrees(25))
                }
                .frame(width: 56, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                    .font(Police.taille(13))
                    .foregroundStyle(Palette.silhouette)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Espace.l)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rangee(_ symbole: String, _ titre: String, valeur: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Espace.m) {
                Image(systemName: symbole)
                    .font(Police.taille(22))
                    .foregroundStyle(Palette.marine)
                    .frame(width: 26)
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
                    .font(Police.taille(13))
                    .foregroundStyle(Palette.silhouette)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Espace.l)
            .frame(minHeight: 56)
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
