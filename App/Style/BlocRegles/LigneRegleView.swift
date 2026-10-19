import Core
import SwiftUI

/// Une ligne de règle du bloc : icône, phrase de Core, mot d'état ; un toucher ouvre la source, la citation et la date de lecture.
/// Ne prend qu'une `LigneControle` de `Core` : rien n'est filtré ni ajouté ici.
struct LigneRegleView: View {
    var ligne: LigneControle
    /// Vrai pour que la source soit ouverte dès l'affichage (la raison de l'état de tête).
    var ouverteAuDepart = false
    @State private var ouverte: Bool

    init(ligne: LigneControle, ouverteAuDepart: Bool = false) {
        self.ligne = ligne
        self.ouverteAuDepart = ouverteAuDepart
        _ouverte = State(initialValue: ouverteAuDepart)
    }

    /// Vrai si les sources portent des citations différentes : chacune montre la sienne, sans la citation unique en plus.
    private var sourcesAvecCitation: Bool { Set(ligne.sources.compactMap(\.citation)).count > 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Button { withAnimation { ouverte.toggle() } } label: {
                HStack(alignment: .top, spacing: Espace.m) {
                    Image(systemName: symbole).foregroundStyle(couleur).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ligne.phrase).font(Police.corps).foregroundStyle(Palette.encre)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if let mot = BlocReglesLogique.motDEtat(ligne.etat) {
                            Text(mot).font(Police.legende).foregroundStyle(ligne.etat == .respectee ? Palette.encreDouce : couleur)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: ouverte ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.encreDouce).accessibilityHidden(true)
                }
                .frame(minHeight: Gabarit.zoneTactile, alignment: .top)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(ouverte ? "Masquer la source" : "Voir la source")
            if ouverte { sources }
        }
        .padding(Espace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }

    @ViewBuilder private var sources: some View {
        if ligne.sources.isEmpty && ligne.citation == nil {
            Text("Source : voir l'arrêté préfectoral.").font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
        ForEach(Array(ligne.sources.enumerated()), id: \.offset) { _, s in
            VStack(alignment: .leading, spacing: 2) {
                if let url = s.url.flatMap({ URL(string: $0) }) {
                    Link(destination: url) {
                        Label(s.titre, systemImage: "arrow.up.right.square")
                            .font(Police.legende).multilineTextAlignment(.leading)
                            .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                    }
                } else {
                    Text(s.titre).font(Police.legende).foregroundStyle(Palette.encreDouce)
                }
                if sourcesAvecCitation, let citation = s.citation {
                    Text(citation).font(Police.legende).foregroundStyle(Palette.encreDouce)
                }
            }
        }
        if !sourcesAvecCitation, let citation = ligne.citation {
            Text(citation).font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
        if let date = ligne.dateLecture {
            Text("Lue le \(date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "fr_FR"))))")
                .font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
    }

    private var symbole: String {
        switch ligne.etat {
        case .nonRespectee: return "xmark.octagon.fill"
        case .aVerifierSurPlace: return "exclamationmark.circle.fill"
        case .respectee: return ligne.type == .periode ? "calendar" : "checkmark.circle.fill"
        case .information: return "info.circle.fill"
        }
    }

    private var couleur: Color {
        switch ligne.etat {
        case .nonRespectee, .aVerifierSurPlace: return Palette.alerte
        case .respectee: return Palette.ouvert
        case .information: return Palette.encreDouce
        }
    }
}
