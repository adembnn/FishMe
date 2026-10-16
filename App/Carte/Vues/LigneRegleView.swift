import SwiftUI
import Core

/// Une ligne de la liste de contrôle : un symbole, une phrase courte, une couleur d'état.
/// Un toucher ouvre la source, la citation et la date de lecture. L'écran ne calcule rien : tout vient de `Core`.
struct LigneRegleView: View {
    let ligne: LigneControle
    let categorieInconnue: Bool
    let tronconConfirme: Bool
    let confirmerTroncon: (String) -> Void

    @State private var ouverte = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.snappy) { ouverte.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: symboleType)
                        .font(Police.corps)
                        .frame(width: 28)
                        .foregroundStyle(couleurEtat)
                        .accessibilityHidden(true)
                    Text(texte)
                        .font(PolicesCarte.corps())
                        .foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: ouverte ? "chevron.up" : "chevron.right")
                        .font(PolicesCarte.legende())
                        .foregroundStyle(Palette.silhouette)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(ouverte ? "Referme la source" : "Ouvre la source et la citation")

            if let libelle = ligne.libelleTroncon {
                HStack(spacing: 8) {
                    Text(libelle)
                        .font(PolicesCarte.detail())
                        .foregroundStyle(Palette.encreDouce)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    if tronconConfirme {
                        Label("appliqué", systemImage: "checkmark")
                            .font(PolicesCarte.legende())
                            .foregroundStyle(Palette.ouvert)
                    } else {
                        Button("j'y suis ?") { confirmerTroncon(libelle) }
                            .font(PolicesCarte.detail())
                            .buttonStyle(.bordered)
                            .tint(Palette.marine)
                    }
                }
                .padding(.leading, 40)
            }

            if ouverte {
                SourceCitationView(ligne: ligne)
                    .padding(.leading, 40)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
    }

    /// Catégorie inconnue : les deux valeurs (« 1re : fermée · 2e : ouverte »), jamais une seule devinée.
    private var texte: String {
        if categorieInconnue, !ligne.valeursParCategorie.isEmpty {
            let premiere = ligne.valeursParCategorie[.premiere].map { "1re : \($0)" }
            let deuxieme = ligne.valeursParCategorie[.deuxieme].map { "2e : \($0)" }
            return [premiere, deuxieme].compactMap { $0 }.joined(separator: " · ")
        }
        return ligne.phrase
    }

    private var symboleType: String {
        switch ligne.type {
        case .taille: return "ruler"
        case .periode: return "calendar"
        case .quota: return "number.circle"
        case .modeDePeche: return "figure.fishing"
        case .nuit: return "moon.stars"
        case .reserve: return "exclamationmark.triangle"
        case .consommation: return "fork.knife"
        case .transportVivant: return "shippingbox"
        case .autre: return "doc.text"
        }
    }

    private var couleurEtat: Color {
        // Une règle d'interdiction (consommation, mode de pêche, nuit) n'est jamais verte, quel que soit l'état.
        if [.consommation, .modeDePeche, .nuit].contains(ligne.type) && ligne.etat != .nonRespectee { return Palette.encreDouce }
        switch ligne.etat {
        case .respectee: return Palette.ouvert
        case .nonRespectee: return Palette.alerte
        case .aVerifierSurPlace: return Palette.encreDouce
        case .information: return Palette.encreDouce
        }
    }
}

/// Ce qui s'ouvre derrière un toucher : la citation, chaque source (un lien si elle en a un) et la date de lecture.
struct SourceCitationView: View {
    let ligne: LigneControle

    /// Vrai si les sources portent des citations différentes : chacune montre la sienne, sans la citation unique en plus.
    private var sourcesAvecCitation: Bool { Set(ligne.sources.compactMap(\.citation)).count > 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !sourcesAvecCitation, let citation = ligne.citation {
                Text("« \(citation) »")
                    .font(PolicesCarte.detail())
                    .foregroundStyle(Palette.encre)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(ligne.sources.enumerated()), id: \.offset) { _, source in
                VStack(alignment: .leading, spacing: 2) {
                    if let url = source.url.flatMap({ URL(string: $0) }) {
                        Link(destination: url) {
                            Label(source.titre, systemImage: "arrow.up.right.square")
                                .font(PolicesCarte.legende())
                                .foregroundStyle(Palette.marine)
                                .multilineTextAlignment(.leading)
                        }
                    } else {
                        Text(source.titre)
                            .font(PolicesCarte.legende())
                            .foregroundStyle(Palette.encreDouce)
                    }
                    if sourcesAvecCitation, let citation = source.citation {
                        Text("« \(citation) »")
                            .font(PolicesCarte.detail())
                            .foregroundStyle(Palette.encre)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if let date = ligne.dateLecture {
                Text("Lu le " + date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "fr_FR"))))
                    .font(PolicesCarte.legende())
                    .foregroundStyle(Palette.encreDouce)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
