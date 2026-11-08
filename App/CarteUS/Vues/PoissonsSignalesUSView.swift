import SwiftUI
import Core

/// « Poissons signalés ici » : une grille de pastilles (image + nom), le niveau d'où vient la liste, puis les sources.
/// Jamais une liste de noms seule. Sans donnée : un message honnête avec le lien de l'agence.
struct PoissonsSignalesUSView: View {
    let fiche: FicheUS

    @Environment(RegionCourante.self) private var regionCourante: RegionCourante?
    private var t: TraducteurCarteUS { TraducteurCarteUS(locale: regionCourante?.locale ?? Locale(identifier: "en_US")) }
    private var poissons: PoissonsSignalesUS { PoissonsSignalesUS.pour(fiche: fiche) }

    private let colonnes = [GridItem(.adaptive(minimum: 96), spacing: Espace.s, alignment: .top)]

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(t(TextesPoissonsUS.titre))
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            Text(t(TextesPoissonsUS.entete))
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
            switch poissons.contenu {
            case let .especes(niveau, vignettes, sources):
                Text(t(niveau))
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                LazyVGrid(columns: colonnes, alignment: .leading, spacing: Espace.s) {
                    ForEach(vignettes) { v in pastille(v) }
                }
                listeSources(sources)
            case let .sansDonnee(texte, lien, libelle):
                Text(t(texte))
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                    .fixedSize(horizontal: false, vertical: true)
                if let lien {
                    Link(destination: lien) {
                        Label(t.libelleLien(libelle), systemImage: "arrow.up.right.square")
                            .font(Police.detail)
                            .foregroundStyle(Palette.marine)
                            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espace.m)
        .tuileFishMe(rayon: Rayon.m)
    }

    private func pastille(_ v: VignetteEspeceUS) -> some View {
        VStack(spacing: Espace.xs) {
            if let nom = v.nomImage {
                Image(nom)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 56)
                    .accessibilityHidden(true)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "fish")
                        .font(.title3)
                    Text(t(TextesPoissonsUS.imageAVenir))
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(Palette.encreDouce)
                .frame(maxWidth: .infinity, minHeight: 56)
            }
            Text(v.nom)
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(t(v.confiance))
                .font(.caption2)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(Espace.xs)
        .accessibilityElement(children: .combine)
    }

    private func listeSources(_ sources: [SourceAfficheeUS]) -> some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text(t(TextesPoissonsUS.titreSources))
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
            ForEach(sources, id: \.self) { s in
                VStack(alignment: .leading, spacing: 2) {
                    if let lien = s.lien {
                        Link(s.nom, destination: lien)
                            .font(Police.legende)
                            .foregroundStyle(Palette.marine)
                    } else {
                        Text(s.nom).font(Police.legende).foregroundStyle(Palette.encre)
                    }
                    Text(t(TextesPoissonsUS.date) + " " + s.date + " · " + t(TextesPoissonsUS.licence) + " " + t(s.licence))
                        .font(.caption2)
                        .foregroundStyle(Palette.encreDouce)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
