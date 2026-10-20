import SwiftUI

/// « Commencer une session » en Liquid Glass teinté marine, avec l'icône play. Grisé (et dit comme tel) tant qu'aucun spot n'est posé.
struct BoutonCommencerVerre: View {
    let actif: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Commencer une session", systemImage: "play.fill")
                .font(Police.corps)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Espace.s)
                .frame(minHeight: Gabarit.zoneTactile)
        }
        .buttonStyle(.glassProminent)
        .tint(Palette.marine.opacity(0.5))
        .controlSize(.large)
        .frame(maxWidth: 300)
        .disabled(!actif)
        .accessibilityHint(actif ? "" : "Pose d'abord ton spot en touchant la carte")
    }
}

/// Un bouton de la colonne de droite : l'icône ET son libellé écrit dessous (une icône seule ne se comprend pas, retour des testeurs).
/// 44 pt au moins dans les deux sens ; le libellé suit la taille du texte (jusqu'à AX5) et passe sur deux lignes au besoin.
struct BoutonLibelleCarte: View {
    let symbole: String
    let libelle: String
    var teinte: Color = Palette.encre
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ContenuBoutonCarte(symbole: symbole, libelle: libelle, teinte: teinte)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(libelle)
    }
}

/// L'aspect commun des boutons de la colonne : icône, libellé dessous, verre arrondi (aussi pour le menu « Plus »).
struct ContenuBoutonCarte: View {
    let symbole: String
    let libelle: String
    var teinte: Color = Palette.encre

    var body: some View {
        VStack(spacing: 1) {
            Image(systemName: symbole)
                .font(Police.taille(18))
                .foregroundStyle(teinte)
                .frame(height: 22)
                .accessibilityHidden(true)
            Text(libelle)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(minWidth: 64, minHeight: Gabarit.zoneTactile + 6)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// La colonne de 4 boutons en verre (5 avec « Repères », N6), à droite au-dessus de la barre d'onglets, chacun avec son libellé :
/// météo, ma position (recentre la caméra sans déplacer le spot), filtre par espèce, réglages.
struct ColonneBoutonsCarte: View {
    /// Faux (position refusée) : le bouton s'appelle « Ma zone » et rouvre le choix du département ou de la commune.
    var positionAutorisee = true
    let teinteFiltre: Color
    /// Le nom de l'espèce filtrée : il remplace le mot « Espèces » sur le bouton. `nil` : aucun filtre.
    var nomFiltre: String? = nil
    /// Efface le filtre d'un toucher (croix ronde dans le coin du bouton « Espèces »).
    var effacerFiltre: (() -> Void)? = nil
    let meteo: () -> Void
    let autourDeMoi: () -> Void
    let filtre: () -> Void
    let reglages: () -> Void
    /// N6 : la 5e rangée « Repères » (interrupteur du calque, éteint au premier lancement). `nil` : pas de rangée.
    var reperes: (() -> Void)? = nil
    var reperesAllumes = false

    var body: some View {
        GlassEffectContainer(spacing: 4) {
            VStack(spacing: 4) {
                BoutonLibelleCarte(symbole: "cloud.sun", libelle: "Météo", action: meteo)
                BoutonLibelleCarte(symbole: positionAutorisee ? "location.fill" : "mappin.and.ellipse",
                                   libelle: positionAutorisee ? "Ma position" : "Ma zone",
                                   teinte: Palette.marine, action: autourDeMoi)
                BoutonLibelleCarte(symbole: "line.3.horizontal.decrease", libelle: nomFiltre ?? "Espèces", teinte: teinteFiltre, action: filtre)
                    .overlay(alignment: .topTrailing) {
                        if nomFiltre != nil, let effacerFiltre {
                            // Dans les limites du bouton (un décalage vers l'extérieur la faisait couper par la colonne),
                            // au-dessus des boutons voisins (zIndex).
                            Button(action: effacerFiltre) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Palette.surMarine)
                                    .frame(width: 22, height: 22)
                                    .background(Palette.marine, in: Circle())
                                    .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile, alignment: .topTrailing)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Effacer le filtre d'espèce")
                        }
                    }
                    .zIndex(2)
                // « Plus » : Réglages et Repères dans un seul menu, pour libérer la carte.
                Menu {
                    Button { reglages() } label: { Label("Réglages", systemImage: "gearshape") }
                    if let reperes {
                        Button { reperes() } label: {
                            Label(reperesAllumes ? "Masquer les repères" : "Afficher les repères",
                                  systemImage: reperesAllumes ? "signpost.right.fill" : "signpost.right")
                        }
                    }
                } label: {
                    ContenuBoutonCarte(symbole: "ellipsis", libelle: "Plus")
                }
                .accessibilityLabel("Plus : réglages et repères")
            }
        }
    }
}
