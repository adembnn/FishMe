import Core
import SwiftUI

/// Ce que les textes lus disent des réserves autour d'un repère. Orange quand une réserve est signalée, gris sinon : jamais vert,
/// jamais « hors réserve » (les règles ne contiennent aucun contour). La source et sa citation s'ouvrent d'un toucher.
struct AvertissementReserveView: View {
    @Environment(\.locale) private var locale
    let avertissement: AvertissementReserve
    var horsDeFrance = false
    @State private var sourcesOuvertes = false

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            if horsDeFrance {
                ligne(symbole: "info.circle.fill", texte: TextesReperes.t(TextesReperes.horsDeFrance, locale), alerte: false)
            } else {
                ligne(symbole: alerte ? "exclamationmark.triangle.fill" : "info.circle.fill", texte: phrase, alerte: alerte)
                if !sources.isEmpty { listeSources }
            }
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alerte ? Palette.alerteDoux : Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var alerte: Bool {
        switch avertissement {
        case .surCetteEau, .nonPlaceesDansLeDepartement: return !horsDeFrance
        case .aucuneConnue: return false
        }
    }

    private var phrase: String {
        switch avertissement {
        case .surCetteEau(let nom, _, _): return TextesReperes.reserveSurEau(nom, locale: locale)
        case .nonPlaceesDansLeDepartement(let n, _, _): return TextesReperes.reservesNonPlacees(n, locale: locale)
        case .aucuneConnue: return TextesReperes.t(TextesReperes.aucuneReserve, locale)
        }
    }

    private var sources: [SourceRegle] {
        switch avertissement {
        case .surCetteEau(_, let s, _), .nonPlaceesDansLeDepartement(_, let s, _): return s
        case .aucuneConnue: return []
        }
    }

    private var lueLe: Date? {
        switch avertissement {
        case .surCetteEau(_, _, let d), .nonPlaceesDansLeDepartement(_, _, let d): return d
        case .aucuneConnue: return nil
        }
    }

    private func ligne(symbole: String, texte: String, alerte: Bool) -> some View {
        HStack(alignment: .top, spacing: Espace.m) {
            Image(systemName: symbole)
                .font(Police.sousTitre)
                .foregroundStyle(alerte ? Palette.alerte : Palette.encreDouce)
                .accessibilityHidden(true)
            Text(texte)
                .font(Police.corps)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var listeSources: some View {
        DisclosureGroup(isExpanded: $sourcesOuvertes) {
            VStack(alignment: .leading, spacing: Espace.m) {
                ForEach(Array(sources.enumerated()), id: \.offset) { _, source in
                    VStack(alignment: .leading, spacing: Espace.xs) {
                        Text(source.titre)
                            .font(Police.detail)
                            .foregroundStyle(Palette.encre)
                        if let citation = source.citation, !citation.isEmpty {
                            Text("« \(citation) »")
                                .font(Police.legende)
                                .foregroundStyle(Palette.encreDouce)
                        }
                        if let url = source.url.flatMap(Self.lienSur) {
                            Link("Ouvrir le texte", destination: url)
                                .font(Police.legende)
                                .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let lueLe {
                    Text(AnglaisC.texte("Lu le %@", locale, TextesReperes.lueLe(lueLe, locale: locale)))
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                }
            }
            .padding(.top, Espace.s)
        } label: {
            Text(TextesReperes.t(TextesReperes.sourcesTitre, locale))
                .font(Police.detail)
                .foregroundStyle(Palette.marine)
                .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
        }
        .tint(Palette.marine)
    }

    /// Seuls les liens https s'ouvrent.
    static func lienSur(_ texte: String) -> URL? {
        guard let url = URL(string: texte), url.scheme?.lowercased() == "https" else { return nil }
        return url
    }
}
