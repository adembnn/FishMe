import SwiftUI
import Core

/// La fiche d'un plan d'eau ou d'un accès (Etats-Unis) : nom, État, source datée, lien vers l'agence, "Y aller" et, en dessous,
/// le bloc des règles de l'État (point d'insertion `blocRegles`, rempli par le lot US12). Jamais un verdict de pêche.
struct FicheUSView: View {
    let fiche: FicheUS
    let yAller: (Coordonnee, String) -> Void
    /// Point d'insertion facultatif, gardé pour compatibilité : la fiche montre déjà `BlocReglesUS` (voir `ReglesEtatUSView`).
    let blocRegles: (String) -> AnyView

    @Environment(RegionCourante.self) private var regionCourante: RegionCourante?
    private var t: TraducteurCarteUS { TraducteurCarteUS(locale: regionCourante?.locale ?? Locale(identifier: "en_US")) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                entete
                boutonYAller
                sourceEtDate
                lienAgence
                if !fiche.avis.isEmpty { avis }
                PoissonsSignalesUSView(fiche: fiche)
                ReglesEtatUSView(etat: fiche.etat)
                Text(t(fiche.mention))
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
            Text(sousTitre)
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var boutonYAller: some View {
        Button { yAller(fiche.coordonnee, fiche.titre) } label: {
            Label(t(TextesCarteUS.yAller), systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .font(Police.corps)
                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
        }
        .buttonStyle(.glassProminent)
        .tint(Palette.marine.opacity(0.5))
        .controlSize(.large)
    }

    private var sourceEtDate: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text(t(TextesCarteUS.titreSource))
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
            Text((fiche.debutSource.map { t($0) } ?? "") + t(fiche.source))
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
            Text(t("Donnée du ") + t(fiche.date))
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
                Label(t.libelleLien(fiche.libelleLien), systemImage: "arrow.up.right.square")
                    .font(Police.detail)
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
            }
        } else {
            Text(t.libelleLien(fiche.libelleLien) + " : " + t(TextesCarteUS.donneeAbsente))
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
        }
    }

    private var avis: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(t(TextesCarteUS.titreAvis))
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
            ForEach(Array(fiche.avis.enumerated()), id: \.offset) { _, a in
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text(a.texte)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encre)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(t(a.source) + ", " + a.date)
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                    if let lien = a.lien {
                        Link(t("Lire l'avis"), destination: lien)
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

    /// "Type · État" : le type est traduit, le nom de l'État reste tel quel.
    private var sousTitre: String {
        let morceaux = fiche.sousTitre.components(separatedBy: " · ")
        guard morceaux.count == 2 else { return fiche.sousTitre }
        return t(morceaux[0]) + " · " + morceaux[1]
    }
}

/// Le bloc des règles de l'État pour une espèce au choix (la fiche d'un lieu ne sait pas quel poisson on y cherche).
/// Le bloc lui-même (`BlocReglesUS`) donne l'un des trois verdicts, le lien de l'agence, la source et sa date.
struct ReglesEtatUSView: View {
    let etat: String

    private static let especes: [(id: String, nom: String)] = [
        ("walleye", "Walleye"), ("northern-pike", "Northern pike"), ("largemouth-bass", "Largemouth bass"),
        ("smallmouth-bass", "Smallmouth bass"), ("muskellunge", "Muskellunge"), ("black-crappie", "Black crappie"),
        ("bluegill", "Bluegill"), ("brown-trout", "Brown trout"), ("brook-trout", "Brook trout"),
    ]

    @Environment(RegionCourante.self) private var regionCourante: RegionCourante?
    @State private var espece = "walleye"
    private var t: TraducteurCarteUS { TraducteurCarteUS(locale: regionCourante?.locale ?? Locale(identifier: "en_US")) }
    private var nom: String { Self.especes.first { $0.id == espece }?.nom ?? espece }

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(t("Règles de l'État"))
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
            Picker(t("Espèce"), selection: $espece) {
                ForEach(Self.especes, id: \.id) { e in Text(e.nom).tag(e.id) }
            }
            .pickerStyle(.menu)
            .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
            BlocReglesUS(espece: espece, nomEspece: nom, etat: CodeEtat(rawValue: etat))
                .id(espece + etat)
        }
    }
}
