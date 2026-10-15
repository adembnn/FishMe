import Core
import SwiftUI

/// Une ligne de conseil : icône, texte court, et sa source d'un toucher.
struct ConseilLigneView: View {
    let conseil: Conseil
    @State private var sourceOuverte = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { sourceOuverte.toggle() } label: {
                HStack(spacing: 12) {
                    IconeConseil(nom: conseil.icone)
                    Text(conseil.texte)
                        .font(JetonsConseils.police(.body))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: sourceOuverte ? "chevron.up" : "info.circle")
                        .foregroundStyle(.secondary)
                        .frame(width: JetonsConseils.tailleToucher, height: JetonsConseils.tailleToucher)
                }
                .frame(minHeight: JetonsConseils.tailleToucher)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Montre la source")
            if sourceOuverte {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text").accessibilityHidden(true)
                    if let url = conseil.source.url.flatMap({ URL(string: $0) }) {
                        Link(conseil.source.titre, destination: url)
                    } else {
                        Text(conseil.source.titre)
                    }
                }
                .font(JetonsConseils.police(.footnote))
                .foregroundStyle(.secondary)
                .padding(.leading, 56)
            }
        }
    }
}

/// E2 (le 1er conseil sur la fiche d'un coin), E4 (carte « à essayer ») et E6 (« comment la pêcher ») montrent la même liste :
/// celle que `Core` rend pour le niveau gardé sur l'iPhone. Rien n'est choisi ni réécrit ici.
/// Sans abonnement : le 1er conseil (marqué gratuit par Core) puis la ligne « tout le kit » (E7).
struct ConseilsEspeceView: View {
    let espece: Espece
    let contexte: ContexteConseils
    @AppStorage(ClesConseils.niveau) private var niveauBrut = NiveauPecheur.parDefaut.rawValue

    var body: some View {
        let a = contexte.affiches(espece: espece, niveau: .depuis(niveauBrut))
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(a.visibles.enumerated()), id: \.offset) { _, conseil in
                ConseilLigneView(conseil: conseil)
            }
            if a.visibles.isEmpty && !a.toutLeKit {
                Label("Pas encore de conseil", systemImage: "tray")
                    .font(JetonsConseils.police(.body))
                    .foregroundStyle(.secondary)
                    .frame(minHeight: JetonsConseils.tailleToucher)
            }
            if a.toutLeKit {
                Button { contexte.toutLeKit(.conseilsComplets) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .frame(width: JetonsConseils.tailleToucher, height: JetonsConseils.tailleToucher)
                        Text("Tout le kit")
                        Spacer(minLength: 0)
                        Text("+\(a.nbCaches)")
                    }
                    .font(JetonsConseils.police(.body))
                    .foregroundStyle(JetonsConseils.accent)
                    .padding(.trailing, 12)
                    .frame(minHeight: JetonsConseils.tailleToucher)
                    .background(JetonsConseils.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tout le kit, \(a.nbCaches) conseils de plus")
            }
        }
    }
}

/// E2 : la vue « 1er conseil » d'une espèce touchée sur la fiche d'un coin. A la place dans l'emplacement que L2 laisse.
struct PremierConseilView: View {
    let espece: Espece
    let contexte: ContexteConseils

    var body: some View {
        ConseilsEspeceView(espece: espece, contexte: contexte)
            .accessibilityIdentifier("premier-conseil")
    }
}

/// E6 : « comment la pêcher », au dos de chaque espèce du Pescedex, prise ou non. A la place dans l'emplacement que L4 laisse.
struct CommentLaPecherView: View {
    let espece: Espece
    let contexte: ContexteConseils

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Comment la pêcher", systemImage: "fish")
                .font(JetonsConseils.police(.headline))
            ConseilsEspeceView(espece: espece, contexte: contexte)
        }
        .accessibilityIdentifier("comment-la-pecher")
    }
}
