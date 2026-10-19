import SwiftUI

// Guide « Mesurer un poisson » : un dessin et trois étapes. Aucune taille chiffrée, aucun verdict.
//
// ⚠ à vérifier : le geste « du museau à l'extrémité de la queue » est donné par Adem et n'est pas confirmé
// à un texte officiel (Code de l'environnement ou arrêté). Avant la fusion, B cite le texte ici et dans une
// ligne « Source » sous le dessin ; sans source, le guide reste un « repère pratique » (texte actuel).
// Écrevisses et grenouilles : hors guide en v1 (façon légale de les mesurer non vérifiée).

struct MesureGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                Text(TextesMaFederation.mesureTitre)
                    .font(Police.grandTitre).foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)

                DessinMesurePoisson()
                    .padding(Espace.l)
                    .tuileFishMe()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(TextesMaFederation.mesureDessin)

                VStack(alignment: .leading, spacing: Espace.m) {
                    ForEach(Array(TextesMaFederation.mesureEtapes.enumerated()), id: \.offset) { index, texte in
                        HStack(alignment: .firstTextBaseline, spacing: Espace.m) {
                            Text("\(index + 1)")
                                .font(Police.chiffreMoyen).foregroundStyle(Palette.marine)
                                .frame(minWidth: Gabarit.zoneTactile * 0.6, alignment: .leading)
                                .accessibilityHidden(true)
                            Text(texte)
                                .font(Police.corps).foregroundStyle(Palette.encre)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Étape \(index + 1). \(texte)")
                    }
                }

                VStack(alignment: .leading, spacing: Espace.s) {
                    Text(TextesMaFederation.mesureLegende)
                    Text(TextesMaFederation.mesureRepere)
                    Text(TextesMaFederation.reglesLocales)
                    Text(TextesMaFederation.renseigneToi)
                }
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .navigationTitle(TextesMaFederation.mesureTitre)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("mesure-guide")
    }
}

/// Le poisson de profil, museau à gauche, et la flèche de mesure dessous.
private struct DessinMesurePoisson: View {
    var body: some View {
        ZStack {
            PoissonDeProfil()
                .fill(Palette.marineDoux)
            PoissonDeProfil()
                .stroke(Palette.marine, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            FlecheDeMesure()
                .stroke(Palette.bouchon, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        }
        .aspectRatio(2.4, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

/// Le contour d'un poisson de profil : museau à 4 % de la largeur, bout de la queue à 96 %.
/// Les abscisses sont partagées avec `FlecheDeMesure` pour que la flèche touche le museau et la queue.
private enum GeometrieDessin {
    static let museau: CGFloat = 0.04
    static let boutQueue: CGFloat = 0.96
    static let axe: CGFloat = 0.42
    static let fleche: CGFloat = 0.9
}

private struct PoissonDeProfil: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        var chemin = Path()
        chemin.move(to: p(GeometrieDessin.museau, GeometrieDessin.axe))
        // Dos, jusqu'au pied de la queue.
        chemin.addCurve(to: p(0.40, 0.12), control1: p(0.10, 0.20), control2: p(0.24, 0.10))
        chemin.addCurve(to: p(0.74, GeometrieDessin.axe - 0.04), control1: p(0.54, 0.14), control2: p(0.66, 0.30))
        // Queue (nageoire caudale comprise).
        chemin.addLine(to: p(GeometrieDessin.boutQueue, 0.14))
        chemin.addQuadCurve(to: p(GeometrieDessin.boutQueue, 0.72), control: p(0.86, GeometrieDessin.axe))
        chemin.addLine(to: p(0.74, GeometrieDessin.axe + 0.04))
        // Ventre, retour au museau.
        chemin.addCurve(to: p(0.40, 0.70), control1: p(0.66, 0.56), control2: p(0.54, 0.70))
        chemin.addCurve(to: p(GeometrieDessin.museau, GeometrieDessin.axe), control1: p(0.24, 0.72), control2: p(0.10, 0.64))
        chemin.closeSubpath()
        // Œil.
        chemin.addEllipse(in: CGRect(x: r.minX + 0.12 * r.width, y: r.minY + 0.34 * r.height,
                                     width: 0.03 * r.width, height: 0.03 * r.width))
        // Nageoire dorsale.
        chemin.move(to: p(0.34, 0.16))
        chemin.addQuadCurve(to: p(0.52, 0.04), control: p(0.40, 0.04))
        chemin.addQuadCurve(to: p(0.58, 0.20), control: p(0.56, 0.10))
        return chemin
    }
}

/// Flèche à deux pointes sous le poisson, du museau au bout de la queue, avec un trait de repère à chaque bout.
private struct FlecheDeMesure: Shape {
    func path(in r: CGRect) -> Path {
        let gauche = r.minX + GeometrieDessin.museau * r.width
        let droite = r.minX + GeometrieDessin.boutQueue * r.width
        let y = r.minY + GeometrieDessin.fleche * r.height
        let pointe = min(r.width, r.height) * 0.06
        var chemin = Path()
        chemin.move(to: CGPoint(x: gauche, y: y))
        chemin.addLine(to: CGPoint(x: droite, y: y))
        // Pointe de gauche.
        chemin.move(to: CGPoint(x: gauche + pointe, y: y - pointe))
        chemin.addLine(to: CGPoint(x: gauche, y: y))
        chemin.addLine(to: CGPoint(x: gauche + pointe, y: y + pointe))
        // Pointe de droite.
        chemin.move(to: CGPoint(x: droite - pointe, y: y - pointe))
        chemin.addLine(to: CGPoint(x: droite, y: y))
        chemin.addLine(to: CGPoint(x: droite - pointe, y: y + pointe))
        // Traits de repère : du bord du dessin à la flèche, sous le museau et sous le bout de la queue.
        let hautRepere = r.minY + 0.76 * r.height
        chemin.move(to: CGPoint(x: gauche, y: hautRepere))
        chemin.addLine(to: CGPoint(x: gauche, y: y + pointe))
        chemin.move(to: CGPoint(x: droite, y: hautRepere))
        chemin.addLine(to: CGPoint(x: droite, y: y + pointe))
        return chemin
    }
}
