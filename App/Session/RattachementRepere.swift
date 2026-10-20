import Core
import Foundation
import SwiftUI

/// Après une prise : « Rattacher au repère X ? » (N6, accroche session). Le repère le plus proche (150 m) de la position du téléphone
/// au moment de la prise est proposé ; rien n'est rattaché sans un toucher. Une `Prise` ne reçoit jamais de coordonnée : seul le repère
/// garde l'identifiant de la prise (`ModeleReperes.rattacher`). Tout reste sur l'iPhone.
/// ⚠ à vérifier : écrit sans Mac ni compilateur.
struct PropositionRepere: Equatable, Identifiable {
    let id = UUID()
    let idPrise: UUID
    let idRepere: UUID
    let nomRepere: String
}

enum RattachementRepere {
    /// `position` : celle de l'iPhone au moment de la prise (jamais le centre du spot, qui n'est pas là où le poisson est sorti).
    /// `nil` : pas de proposition. Pas non plus de proposition si la prise est déjà rattachée à ce repère.
    static func proposer(prise: UUID, position: Coordonnee?, reperes: [Repere]) -> PropositionRepere? {
        guard let position, let proche = RepereProche.plusProche(de: position, dans: reperes),
              !proche.idsPrises.contains(prise) else { return nil }
        return PropositionRepere(idPrise: prise, idRepere: proche.id, nomRepere: proche.nom)
    }

    static func question(_ proposition: PropositionRepere) -> String { "Rattacher au repère \(proposition.nomRepere) ?" }
    static let rattacher = "Rattacher"
    static let pasMaintenant = "Pas maintenant"
}

/// La question, avec ses deux boutons de 44 pt. Posée dans le bandeau de session et dans l'écran de session.
struct PropositionRepereView: View {
    let proposition: PropositionRepere
    /// `true` : rattacher ; `false` : ignorer.
    let repondre: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(RattachementRepere.question(proposition))
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Espace.s) {
                Button { repondre(true) } label: {
                    Text(RattachementRepere.rattacher).frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                }
                .buttonStyle(.secondaire)
                Button { repondre(false) } label: {
                    Text(RattachementRepere.pasMaintenant).frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Palette.marine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }
}

/// Le bouton rond « Ajouter un repère ici » du bandeau de session.
struct BoutonRepereSession: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "signpost.right")
                .font(Police.taille(20, .heavy))
                .foregroundStyle(Palette.marine)
                .frame(width: 52, height: 52)
                .background(Palette.marine.opacity(0.12), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(TextesReperes.ajouterIci)
    }
}
