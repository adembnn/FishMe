import Core
import SwiftUI
import UIKit

/// Le bandeau doux quand une prise dépasse le souvenir de son espèce. Il n'affiche rien pour `.aucun` ni `.premiereTaille`.
/// Il disparaît seul après 4 s ou d'un toucher. Une vibration légère, sans son ni animation de fête (supprimée avec
/// « Réduire les animations »). `nomEspece` complète la fiche : le texte nomme le poisson.
///
/// À brancher par A, avec les cartes d'AVANT l'insertion de la nouvelle :
/// `MoteurRecords.evenement(pour: nouvelle, parmi: cartesAvant)`.
/// ⚠ à vérifier : écrit sans compilateur Swift ; vibration et durée à juger sur un iPhone.
struct BandeauRecordView: View {
    let evenement: EvenementRecord
    let nomEspece: String
    var duree: Duration = TextesRecords.dureeBandeau

    @State private var visible = true
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @Environment(\.locale) private var locale

    var body: some View {
        if let texte = TextesRecords.bandeau(evenement, nomEspece: nomEspece, locale: locale), visible {
            Button {
                masquer()
            } label: {
                Text(texte)
                    .font(Police.corps)
                    .foregroundStyle(Palette.marineFonce)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
                    .padding(Espace.l)
                    .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(texte)
            .accessibilityHint(Text("Touche pour fermer", tableName: AnglaisE.table))
            .transition(reduireAnimations ? .identity : .opacity)
            .task {
                if !reduireAnimations { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                try? await Task.sleep(for: duree)
                masquer()
            }
        }
    }

    private func masquer() {
        if reduireAnimations { visible = false } else { withAnimation(.easeOut(duration: 0.25)) { visible = false } }
    }
}
