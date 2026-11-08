import SwiftUI

// Guide « Mesurer un poisson » : un dessin et trois étapes. Aucune taille chiffrée, aucun verdict.
//
// ⚠ à vérifier : le geste « du museau à l'extrémité de la queue » est donné par Adem et n'est pas confirmé
// à un texte officiel (Code de l'environnement ou arrêté). Avant la fusion, B cite le texte ici et dans une
// ligne « Source » sous le dessin ; sans source, le guide reste un « repère pratique » (texte actuel).
// Écrevisses et grenouilles : hors guide en v1 (façon légale de les mesurer non vérifiée).

struct MesureGuideView: View {
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                Text(AnglaisE.t(TextesMaFederation.mesureTitre, locale))
                    .font(Police.grandTitre).foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)

                DessinMesurePoisson()
                    .padding(Espace.l)
                    .tuileFishMe()
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(AnglaisE.t(TextesMaFederation.mesureDessin, locale))

                VStack(alignment: .leading, spacing: Espace.m) {
                    ForEach(Array(TextesMaFederation.mesureEtapes.enumerated()), id: \.offset) { index, texte in
                        HStack(alignment: .firstTextBaseline, spacing: Espace.m) {
                            Text("\(index + 1)")
                                .font(Police.chiffreMoyen).foregroundStyle(Palette.marine)
                                .frame(minWidth: Gabarit.zoneTactile * 0.6, alignment: .leading)
                                .accessibilityHidden(true)
                            Text(AnglaisE.t(texte, locale))
                                .font(Police.corps).foregroundStyle(Palette.encre)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(AnglaisE.f("Étape %lld. %@", locale, index + 1, AnglaisE.t(texte, locale)))
                    }
                }

                VStack(alignment: .leading, spacing: Espace.s) {
                    Text(AnglaisE.t(TextesMaFederation.mesureLegende, locale))
                    Text(AnglaisE.t(TextesMaFederation.mesureRepere, locale))
                    Text(AnglaisE.t(TextesMaFederation.reglesLocales, locale))
                    Text(AnglaisE.t(TextesMaFederation.renseigneToi, locale))
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
        .navigationTitle(AnglaisE.t(TextesMaFederation.mesureTitre, locale))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("mesure-guide")
    }
}


/// Dessin naturaliste du poisson de profil (museau à gauche), avec la flèche de mesure sous lui.
/// Repère : une boîte de 200 x 92 ; tout est tracé en SwiftUI, sans image.
/// Réduire les animations : le dessin est fixe, rien ne bouge.
// ⚠ à vérifier sur Mac : rendu des clips et des couleurs en mode sombre.
private struct DessinMesurePoisson: View {
    var body: some View {
        ZStack {
            NageoireDeProfil(forme: .dorsale).fill(CouleursDessin.dosFonce)
            NageoireDeProfil(forme: .ventrale).fill(CouleursDessin.dosFonce)
            CorpsDuPoisson().fill(CouleursDessin.dos)
            // Ventre clair, bout de la queue foncé, taches et ligne latérale : découpés dans le corps.
            ZStack {
                VentreDuPoisson().fill(CouleursDessin.ventre)
                BoutDeQueue().fill(CouleursDessin.dosFonce)
                LigneLaterale()
                    .stroke(CouleursDessin.tache.opacity(0.5),
                            style: StrokeStyle(lineWidth: 0.8, dash: [2, 2]))
                TachesDuPoisson().fill(CouleursDessin.tache)
            }
            .clipShape(CorpsDuPoisson())
            Opercule().stroke(CouleursDessin.tache.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            OeilDuPoisson().fill(Color.white)
            OeilDuPoisson(rayon: 1.8).fill(CouleursDessin.tache)
            ReperesDeMesure().stroke(Palette.marine, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
            FlecheDeMesure().stroke(Palette.marine, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
            PointsDeMesure().fill(Palette.marine)
            PointesDeFleche().fill(Palette.marine)
        }
        .aspectRatio(GeometrieDessin.largeur / GeometrieDessin.hauteur, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

/// Couleurs du dessin : vert-gris du dos, ventre clair, taches sombres ; une variante pour le mode sombre.
private enum CouleursDessin {
    static let dos = couleur(0x7E9A8E, sombre: 0x5C7A70)
    static let dosFonce = couleur(0x52726A, sombre: 0x3E5A52)
    static let ventre = couleur(0xE3EAE4, sombre: 0xB8C9BE)
    static let tache = couleur(0x2B3D38, sombre: 0x18262A)

    private static func couleur(_ clair: UInt32, sombre: UInt32) -> Color {
        func ui(_ v: UInt32) -> UIColor {
            UIColor(red: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                    blue: CGFloat(v & 0xFF) / 255, alpha: 1)
        }
        return Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? ui(sombre) : ui(clair) })
    }
}

/// Repère de 200 x 92 ; museau en x = 20, bout de la queue en x = 180. La flèche partage ces abscisses.
private nonisolated enum GeometrieDessin {
    static let largeur: CGFloat = 200
    static let hauteur: CGFloat = 92
    static let museau: CGFloat = 20
    static let boutQueue: CGFloat = 180
    static let axe: CGFloat = 40
    static let fleche: CGFloat = 78

    /// Convertit un point du repère 200 x 92 en point du rectangle.
    static func point(_ x: CGFloat, _ y: CGFloat, _ r: CGRect) -> CGPoint {
        CGPoint(x: r.minX + x / largeur * r.width, y: r.minY + y / hauteur * r.height)
    }
}

private nonisolated struct CorpsDuPoisson: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { GeometrieDessin.point(x, y, r) }
        var c = Path()
        c.move(to: p(20, 40))
        c.addCurve(to: p(140, 35), control1: p(38, 22), control2: p(92, 16))
        c.addLine(to: p(180, 21))
        c.addQuadCurve(to: p(180, 59), control: p(170, 40))
        c.addLine(to: p(140, 45))
        c.addCurve(to: p(20, 40), control1: p(92, 64), control2: p(38, 58))
        c.closeSubpath()
        return c
    }
}

private nonisolated struct NageoireDeProfil: Shape {
    enum Forme { case dorsale, ventrale }
    let forme: Forme
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { GeometrieDessin.point(x, y, r) }
        var c = Path()
        switch forme {
        case .dorsale:
            c.move(to: p(72, 24))
            c.addQuadCurve(to: p(110, 27), control: p(88, 8))
        case .ventrale:
            c.move(to: p(82, 56))
            c.addQuadCurve(to: p(108, 52), control: p(94, 70))
        }
        c.closeSubpath()
        return c
    }
}

private nonisolated struct VentreDuPoisson: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { GeometrieDessin.point(x, y, r) }
        var c = Path()
        c.move(to: p(0, 49))
        c.addCurve(to: p(150, 45), control1: p(40, 52), control2: p(92, 54))
        c.addLine(to: p(150, 92))
        c.addLine(to: p(0, 92))
        c.closeSubpath()
        return c
    }
}

private nonisolated struct BoutDeQueue: Shape {
    func path(in r: CGRect) -> Path {
        Path(CGRect(x: GeometrieDessin.point(140, 0, r).x, y: r.minY,
                    width: r.width * 60 / GeometrieDessin.largeur, height: r.height))
    }
}

private nonisolated struct LigneLaterale: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { GeometrieDessin.point(x, y, r) }
        var c = Path()
        c.move(to: p(20, 40))
        c.addCurve(to: p(150, 40), control1: p(60, 44), control2: p(110, 44))
        return c
    }
}

private nonisolated struct TachesDuPoisson: Shape {
    func path(in r: CGRect) -> Path {
        let rayon = 1.7 / GeometrieDessin.largeur * r.width
        let centres: [(CGFloat, CGFloat)] = [(70, 32), (86, 30), (100, 34), (78, 39), (112, 36), (94, 40), (124, 38)]
        var c = Path()
        for (x, y) in centres {
            let centre = GeometrieDessin.point(x, y, r)
            c.addEllipse(in: CGRect(x: centre.x - rayon, y: centre.y - rayon, width: 2 * rayon, height: 2 * rayon))
        }
        return c
    }
}

private nonisolated struct Opercule: Shape {
    func path(in r: CGRect) -> Path {
        var c = Path()
        c.move(to: GeometrieDessin.point(50, 30, r))
        c.addQuadCurve(to: GeometrieDessin.point(50, 50, r), control: GeometrieDessin.point(57, 40, r))
        return c
    }
}

private nonisolated struct OeilDuPoisson: Shape {
    var rayon: CGFloat = 3.4
    func path(in r: CGRect) -> Path {
        let centre = GeometrieDessin.point(35, 37, r)
        let ray = rayon / GeometrieDessin.largeur * r.width
        return Path(ellipseIn: CGRect(x: centre.x - ray, y: centre.y - ray, width: 2 * ray, height: 2 * ray))
    }
}

/// Deux traits pointillés verticaux : sous le museau et sous le bout de la queue.
private nonisolated struct ReperesDeMesure: Shape {
    func path(in r: CGRect) -> Path {
        var c = Path()
        c.move(to: GeometrieDessin.point(GeometrieDessin.museau, 22, r))
        c.addLine(to: GeometrieDessin.point(GeometrieDessin.museau, 84, r))
        c.move(to: GeometrieDessin.point(GeometrieDessin.boutQueue, 12, r))
        c.addLine(to: GeometrieDessin.point(GeometrieDessin.boutQueue, 84, r))
        return c
    }
}

/// Le trait de la flèche, du museau au bout de la queue.
private nonisolated struct FlecheDeMesure: Shape {
    func path(in r: CGRect) -> Path {
        var c = Path()
        c.move(to: GeometrieDessin.point(GeometrieDessin.museau + 6, GeometrieDessin.fleche, r))
        c.addLine(to: GeometrieDessin.point(GeometrieDessin.boutQueue - 6, GeometrieDessin.fleche, r))
        return c
    }
}

/// Les deux pointes pleines de la flèche, posées sur les repères.
private nonisolated struct PointesDeFleche: Shape {
    func path(in r: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { GeometrieDessin.point(x, y, r) }
        let y = GeometrieDessin.fleche
        var c = Path()
        c.move(to: p(GeometrieDessin.museau, y))
        c.addLine(to: p(GeometrieDessin.museau + 11, y - 7))
        c.addLine(to: p(GeometrieDessin.museau + 11, y + 7))
        c.closeSubpath()
        c.move(to: p(GeometrieDessin.boutQueue, y))
        c.addLine(to: p(GeometrieDessin.boutQueue - 11, y - 7))
        c.addLine(to: p(GeometrieDessin.boutQueue - 11, y + 7))
        c.closeSubpath()
        return c
    }
}

/// Un point plein sur le museau et un sur le bout de la queue.
private nonisolated struct PointsDeMesure: Shape {
    func path(in r: CGRect) -> Path {
        let ray = 4 / GeometrieDessin.largeur * r.width
        var c = Path()
        for x in [GeometrieDessin.museau, GeometrieDessin.boutQueue] {
            let centre = GeometrieDessin.point(x, GeometrieDessin.axe, r)
            c.addEllipse(in: CGRect(x: centre.x - ray, y: centre.y - ray, width: 2 * ray, height: 2 * ray))
        }
        return c
    }
}
