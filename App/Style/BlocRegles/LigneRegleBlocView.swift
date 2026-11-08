import Core
import SwiftUI

/// Une ligne de règle du bloc : icône, phrase de Core, mot d'état ; un toucher ouvre la source, la citation et la date de lecture.
/// Ne prend qu'une `LigneControle` de `Core` : rien n'est filtré ni ajouté ici.
struct LigneRegleBlocView: View {
    var ligne: LigneControle
    /// Vrai pour que la source soit ouverte dès l'affichage (la raison de l'état de tête).
    var ouverteAuDepart = false
    /// Vrai si la catégorie piscicole du cours d'eau est inconnue : les deux valeurs par catégorie (si Core les donne) sont montrées.
    var categorieInconnue = false
    @State private var ouverte: Bool
    @Environment(\.locale) private var locale

    private var textes: TextesBlocRegles { TextesBlocRegles(locale: locale) }

    init(ligne: LigneControle, ouverteAuDepart: Bool = false, categorieInconnue: Bool = false) {
        self.ligne = ligne
        self.categorieInconnue = categorieInconnue
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
                        if let valeurs = BlocReglesLogique.valeursParCategorie(ligne, categorieInconnue: categorieInconnue, locale: locale) {
                            Text(valeurs).font(Police.detail).foregroundStyle(Palette.encre)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(textes.categorieInconnue).font(Police.legende).foregroundStyle(Palette.encreDouce)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if let mot = BlocReglesLogique.motDEtat(ligne.etat, locale: locale) {
                            // Texte en encre (contraste) ; la couleur d'état reste sur l'icône.
                            Text(mot).font(Police.legende)
                                .foregroundStyle(ligne.etat == .respectee || ligne.etat == .information ? Palette.encreDouce : Palette.encre)
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
            .accessibilityHint(ouverte ? textes.masquerSource : textes.voirSource)
            if ouverte { sources }
        }
        .padding(Espace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }

    @ViewBuilder private var sources: some View {
        if ligne.sources.isEmpty && ligne.citation == nil {
            Text(textes.sourceVoirArrete).font(Police.legende).foregroundStyle(Palette.encreDouce)
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
            Text(textes.lueLe(date))
                .font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
    }

    private var symbole: String {
        switch ligne.etat {
        case .nonRespectee: return "xmark.octagon.fill"
        case .aVerifierSurPlace: return "exclamationmark.circle.fill"
        // Pas de coche verte : une ligne lue n'est pas un feu vert.
        case .respectee: return ligne.type == .periode ? "calendar" : "doc.text"
        case .information: return "info.circle.fill"
        }
    }

    private var couleur: Color {
        switch ligne.etat {
        case .nonRespectee, .aVerifierSurPlace: return Palette.alerte
        case .respectee, .information: return Palette.encreDouce
        }
    }
}
