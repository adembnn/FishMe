import SwiftUI
import Core

/// La session réduite (16 oct., « plein écran réductible ») : un bandeau posé sur la carte avec le chrono
/// et le bouton appareil photo « Ajouter une prise ». Toucher le bandeau rouvre P14 en plein écran.
///
/// À brancher par A dans `RootView` : quand la session est réduite, `VueCarte(bandeauSession: AnyView(BandeauSessionView(…)))`
/// (le bandeau se pose au-dessus de la feuille ou de la barre d'onglets) ; `rouvrir` remet `sessionReduite = false`.
struct BandeauSessionView: View {
    let moteur: SuiviSession
    let ajouterPrise: () -> Void
    /// Rouvre `SessionEnCoursView` en plein écran.
    let rouvrir: () -> Void
    /// N6 : « Ajouter un repère ici ». `nil` : pas de bouton.
    var ajouterRepere: (() -> Void)? = nil
    /// N6 : « Rattacher au repère X ? » après une prise, avec la réponse (`true` : rattacher). `nil` : pas de question.
    var proposition: PropositionRepere? = nil
    var repondreProposition: ((Bool) -> Void)? = nil

    var body: some View {
        if moteur.enCours != nil {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                contenu(maintenant: moteur.maintenant())
            }
        }
    }

    private func contenu(maintenant: Date) -> some View {
        VStack(spacing: Espace.s) {
            if let proposition, let repondreProposition {
                PropositionRepereView(proposition: proposition, repondre: repondreProposition)
                    .padding(.trailing, Espace.s)
            }
            rangee(maintenant: maintenant)
        }
        .padding(.leading, Espace.l)
        .padding(.trailing, Espace.s)
        .padding(.vertical, Espace.s)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Palette.encre.opacity(0.16), radius: 15, y: -2)
        .accessibilityElement(children: .contain)
        .onChange(of: maintenant) { _, _ in moteur.verifierFin() }
    }

    private func rangee(maintenant: Date) -> some View {
        HStack(spacing: Espace.s) {
            Button(action: rouvrir) {
                HStack(spacing: Espace.s) {
                    Circle().fill(Palette.ouvert).frame(width: 10, height: 10).accessibilityHidden(true)
                    Text(BandeauSession<EmptyView>.formater(moteur.duree(a: maintenant)))
                        .font(Police.taille(28, .heavy).monospacedDigit())
                        .foregroundStyle(Palette.encre)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up")
                        .font(Police.taille(16, .heavy))
                        .foregroundStyle(Palette.encreDouce)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: Gabarit.zoneTactile)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Session en cours, \(BandeauSession<EmptyView>.formater(moteur.duree(a: maintenant)))")
            .accessibilityHint("Rouvre la session en plein écran")
            if let ajouterRepere { BoutonRepereSession(action: ajouterRepere) }
            Button(action: ajouterPrise) {
                Image(systemName: "camera.fill")
                    .font(Police.taille(20, .heavy))
                    .foregroundStyle(Palette.surMarine)
                    .frame(width: 52, height: 52)
                    .background(Palette.marine, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ajouter une prise")
        }
    }
}
