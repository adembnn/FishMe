import Core
import SwiftUI

/// « Je veux la pêcher » / « Dans mes envies » : un toucher bascule. Absent si l'espèce ne peut pas être marquée
/// (protégée, toujours relâchée, stade à demander, ou déjà au Pescedex) et qu'elle n'est pas déjà dans la liste.
struct BoutonEnvieView: View {
    let espece: EspecePechable
    let modele: EnviesModele
    @State private var retour = false
    @Environment(\.locale) private var locale

    var body: some View {
        if modele.peutAfficherBouton(espece) {
            let active = modele.contient(espece)
            Button {
                modele.basculer(espece)
                retour.toggle()
            } label: {
                HStack(spacing: Espace.s) {
                    Image(systemName: active ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .accessibilityHidden(true)
                    Text(AnglaisE.t(active ? TextesEnvies.dansMesEnvies : TextesEnvies.jeVeuxLaPecher, locale))
                        .font(Police.corps)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Palette.marine)
                .padding(.horizontal, Espace.l)
                .padding(.vertical, Espace.s)
                .frame(minHeight: Gabarit.zoneTactile)
                .background(active ? Palette.marineDoux : Palette.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.filet, lineWidth: 1))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .light), trigger: retour)
            .accessibilityLabel(TextesEnvies.libelleAccessibilite(ajouter: !active, nom: espece.nom, locale: locale))
            .accessibilityIdentifier("envies.bouton")
        }
    }
}

extension View {
    /// Appui long sur un emplacement vide du classeur : « Je veux la pêcher » (ou « Retirer de mes envies »).
    /// Sans modèle, ou pour une espèce qui ne peut pas être marquée, la vue reste telle quelle.
    func menuEnvie(espece: EspecePechable?, modele: EnviesModele?) -> some View {
        modifier(MenuEnvieModifier(espece: espece, modele: modele))
    }
}

private struct MenuEnvieModifier: ViewModifier {
    let espece: EspecePechable?
    let modele: EnviesModele?
    @Environment(\.locale) private var locale

    @ViewBuilder
    func body(content: Content) -> some View {
        if let espece, let modele, modele.peutAfficherBouton(espece) {
            let active = modele.contient(espece)
            content.contextMenu {
                Button {
                    modele.basculer(espece)
                } label: {
                    Label(AnglaisE.t(active ? "Retirer de mes envies" : TextesEnvies.jeVeuxLaPecher, locale),
                          systemImage: active ? "heart.slash" : "heart")
                }
            }
        } else {
            content
        }
    }
}
