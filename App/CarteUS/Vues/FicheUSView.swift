import SwiftUI
import Core

/// La fiche d'un plan d'eau ou d'un accès (Etats-Unis) : nom, État, source datée, lien vers l'agence, "Y aller" et, en dessous,
/// le bloc des règles de l'État (point d'insertion `blocRegles`, rempli par le lot US12). Jamais un verdict de pêche.
struct FicheUSView: View {
    let fiche: FicheUS
    let yAller: (Coordonnee, String) -> Void
    /// Le bloc des règles de l'État du lieu (code USPS). Vide tant que US12 n'est pas branché.
    let blocRegles: (String) -> AnyView

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                entete
                boutonYAller
                sourceEtDate
                lienAgence
                if !fiche.avis.isEmpty { avis }
                blocRegles(fiche.etat)
                Text(fiche.mention)
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Espace.bord)
        }
        .background(Palette.fond)
    }

    private var entete: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text(fiche.titre)
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(fiche.sousTitre)
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var boutonYAller: some View {
        Button { yAller(fiche.coordonnee, fiche.titre) } label: {
            Label(TextesCarteUS.yAller, systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .font(Police.corps)
                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
        }
        .buttonStyle(.glassProminent)
        .tint(Palette.marine.opacity(0.5))
        .controlSize(.large)
    }

    private var sourceEtDate: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text(TextesCarteUS.titreSource)
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
            Text(fiche.source)
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
            Text("Donnée du " + fiche.date)
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espace.m)
        .tuileFishMe(rayon: Rayon.m)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var lienAgence: some View {
        if let url = fiche.lienAgence {
            Link(destination: url) {
                Label(fiche.libelleLien, systemImage: "arrow.up.right.square")
                    .font(Police.detail)
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
            }
        } else {
            Text(fiche.libelleLien + " : " + TextesCarteUS.donneeAbsente)
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
        }
    }

    private var avis: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(TextesCarteUS.titreAvis)
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
            ForEach(Array(fiche.avis.enumerated()), id: \.offset) { _, a in
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text(a.texte)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encre)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(a.source + ", " + a.date)
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                    if let lien = a.lien {
                        Link("Lire l'avis", destination: lien)
                            .font(Police.legende)
                            .foregroundStyle(Palette.marine)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espace.m)
        .tuileFishMe(rayon: Rayon.m)
    }
}
