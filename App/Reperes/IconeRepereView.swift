import Core
import SwiftUI

// L'icône d'un repère privé : une épingle en goutte (la pointe marque l'endroit exact) et un pictogramme blanc.
// Dessin repris de la planche « reperes-fishme » (jeu B, pictogramme du poste pris au jeu C), en SwiftUI pur : aucune image,
// aucun SF Symbol. Les chemins SVG de la planche sont recopiés à la main en `Path`.
// ⚠ à vérifier sur Mac : rendu des chemins (arcs approchés par des courbes de Bézier), épaisseur du trait à 24 pt.

/// Convertit les coordonnées d'une boîte de dessin (largeur x hauteur) vers un rectangle.
private nonisolated struct BoiteDessin {
    let rect: CGRect
    let largeur: CGFloat
    let hauteur: CGFloat
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + x / largeur * rect.width, y: rect.minY + y / hauteur * rect.height)
    }
    func echelle(_ v: CGFloat) -> CGFloat { v / largeur * rect.width }
}

nonisolated extension Path {
    /// Demi-cercle SVG (`a r r 0 0 sens dx dy`, corde de longueur 2r) depuis le point courant, en deux quarts de Bézier.
    /// `horaire` = drapeau de balayage SVG 1 (sens des aiguilles d'une montre à l'écran).
    fileprivate mutating func demiCercle(vers fin: CGPoint, horaire: Bool) {
        let debut = currentPoint ?? fin
        let centre = CGPoint(x: (debut.x + fin.x) / 2, y: (debut.y + fin.y) / 2)
        let v0 = CGVector(dx: debut.x - centre.x, dy: debut.y - centre.y)
        func tourne(_ v: CGVector) -> CGVector { horaire ? CGVector(dx: -v.dy, dy: v.dx) : CGVector(dx: v.dy, dy: -v.dx) }
        let v1 = tourne(v0)
        let v2 = CGVector(dx: -v0.dx, dy: -v0.dy)
        let k: CGFloat = 0.5523
        func pt(_ v: CGVector) -> CGPoint { CGPoint(x: centre.x + v.dx, y: centre.y + v.dy) }
        func controle(_ v: CGVector, _ t: CGVector, _ signe: CGFloat) -> CGPoint {
            CGPoint(x: centre.x + v.dx + signe * k * t.dx, y: centre.y + v.dy + signe * k * t.dy)
        }
        let t0 = tourne(v0), t1 = tourne(v1), t2 = tourne(v2)
        addCurve(to: pt(v1), control1: controle(v0, t0, 1), control2: controle(v1, t1, -1))
        addCurve(to: pt(v2), control1: controle(v1, t1, 1), control2: controle(v2, t2, -1))
    }

    fileprivate mutating func cercle(_ centre: CGPoint, rayon: CGFloat) {
        move(to: CGPoint(x: centre.x - rayon, y: centre.y))
        demiCercle(vers: CGPoint(x: centre.x + rayon, y: centre.y), horaire: true)
        demiCercle(vers: CGPoint(x: centre.x - rayon, y: centre.y), horaire: true)
        closeSubpath()
    }
}

/// La silhouette : épingle goutte, boîte 32 x 41 (la pointe est exactement au bas du rectangle).
nonisolated struct EpingleGoutte: Shape {
    static let largeur: CGFloat = 32
    static let hauteur: CGFloat = 41

    func path(in rect: CGRect) -> Path {
        let b = BoiteDessin(rect: rect, largeur: Self.largeur, hauteur: Self.hauteur)
        var p = Path()
        // M16 41 C16 41 2 26.5 2 15.5 a14 14 0 0 1 28 0 C30 26.5 16 41 16 41 Z
        p.move(to: b.p(16, 41))
        p.addCurve(to: b.p(2, 15.5), control1: b.p(16, 41), control2: b.p(2, 26.5))
        p.demiCercle(vers: b.p(30, 15.5), horaire: true)
        p.addCurve(to: b.p(16, 41), control1: b.p(30, 26.5), control2: b.p(16, 41))
        p.closeSubpath()
        return p
    }
}

/// L'hameçon du jeu C (coordonnées d'origine : œil en (13 ; 4,6), hampe jusqu'à y = 15,8, courbe de rayon 4,9, barbes),
/// recentré dans la boîte 24 x 24 et agrandi de 8 % pour rester lisible à 24 pt dans la goutte.
private nonisolated struct Hamecon {
    let boite: BoiteDessin
    static let echelle: CGFloat = 1.08
    /// Centre du dessin d'origine : x de 1,4 à 13, y de 2,7 à 20,7.
    static let centre = CGPoint(x: 7.2, y: 11.7)
    let rayonOeil: CGFloat = 2.0

    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        boite.p(12 + (x - Self.centre.x) * Self.echelle, 12 + (y - Self.centre.y) * Self.echelle)
    }
    var oeil: CGPoint { pt(13, 4.6) }
}

/// Les parties pleines du pictogramme (boîte 24 x 24), à remplir en pair-impair (évidements).
/// Poste de pêche : seulement le rond de l'œil de l'hameçon (le reste est au trait, voir `GlypheRepereTrait`).
nonisolated struct GlypheRepereRempli: Shape {
    let type: IconeRepere

    func path(in rect: CGRect) -> Path {
        let b = BoiteDessin(rect: rect, largeur: 24, hauteur: 24)
        var p = Path()
        switch type {
        case .parking:
            // M7.3 3.4 h6.4 a5.3 5.3 0 0 1 0 10.6 h-3.1 v6.6 H7.3 Z  (la lettre P, pleine)
            p.move(to: b.p(7.3, 3.4))
            p.addLine(to: b.p(13.7, 3.4))
            p.demiCercle(vers: b.p(13.7, 14), horaire: true)
            p.addLine(to: b.p(10.6, 14))
            p.addLine(to: b.p(10.6, 20.6))
            p.addLine(to: b.p(7.3, 20.6))
            p.closeSubpath()
            // M10.6 6.6 v4.2 h2.9 a2.1 2.1 0 0 0 0 -4.2 Z  (le creux du P)
            p.move(to: b.p(10.6, 6.6))
            p.addLine(to: b.p(10.6, 10.8))
            p.addLine(to: b.p(13.5, 10.8))
            p.demiCercle(vers: b.p(13.5, 6.6), horaire: false)
            p.closeSubpath()
        case .poste:
            let h = Hamecon(boite: b)
            p.cercle(h.oeil, rayon: b.echelle(h.rayonOeil))
        case .danger:
            // Triangle aux coins arrondis.
            p.move(to: b.p(12, 3.2))
            p.addCurve(to: b.p(13.8, 4.3), control1: b.p(12.7, 3.2), control2: b.p(13.4, 3.6))
            p.addLine(to: b.p(21, 17.3))
            p.addCurve(to: b.p(19.2, 20.5), control1: b.p(21.8, 18.7), control2: b.p(20.8, 20.5))
            p.addLine(to: b.p(4.8, 20.5))
            p.addCurve(to: b.p(3, 17.3), control1: b.p(3.2, 20.5), control2: b.p(2.2, 18.7))
            p.addLine(to: b.p(10.2, 4.3))
            p.addCurve(to: b.p(12, 3.2), control1: b.p(10.6, 3.6), control2: b.p(11.3, 3.2))
            p.closeSubpath()
            // Barre du point d'exclamation (évidée) : M11 9.6 v4.6 a1 1 0 0 0 2 0 V9.6 a1 1 0 0 0 -2 0 Z
            p.move(to: b.p(11, 9.6))
            p.addLine(to: b.p(11, 14.2))
            p.demiCercle(vers: b.p(13, 14.2), horaire: false)
            p.addLine(to: b.p(13, 9.6))
            p.demiCercle(vers: b.p(11, 9.6), horaire: false)
            p.closeSubpath()
            // Point (évidé) : cercle de rayon 1,3 centré en (12 ; 18)
            p.cercle(b.p(12, 18), rayon: b.echelle(1.3))
        case .amorcage:
            // Seau : M4.4 9.8 h15.2 l-1.7 9.6 a2.1 2.1 0 0 1 -2.1 1.7 H8.2 a2.1 2.1 0 0 1 -2.1 -1.7 Z
            // (les deux petits arcs de 80 degrés sont approchés par une courbe de Bézier chacun)
            p.move(to: b.p(4.4, 9.8))
            p.addLine(to: b.p(19.6, 9.8))
            p.addLine(to: b.p(17.9, 19.4))
            p.addCurve(to: b.p(15.8, 21.1), control1: b.p(17.705, 20.401), control2: b.p(16.82, 21.117))
            p.addLine(to: b.p(8.2, 21.1))
            p.addCurve(to: b.p(6.1, 19.4), control1: b.p(7.18, 21.117), control2: b.p(6.295, 20.401))
            p.closeSubpath()
            // Bande évidée : M5.6 13.4 l.4 2.2 h12 l.4 -2.2 Z
            p.move(to: b.p(5.6, 13.4))
            p.addLine(to: b.p(6, 15.6))
            p.addLine(to: b.p(18, 15.6))
            p.addLine(to: b.p(18.4, 13.4))
            p.closeSubpath()
        }
        return p
    }
}

/// Les parties au trait du pictogramme (boîte 24 x 24) : l'hameçon du poste et l'anse du seau. Vide pour les autres types.
nonisolated struct GlypheRepereTrait: Shape {
    let type: IconeRepere

    func path(in rect: CGRect) -> Path {
        let b = BoiteDessin(rect: rect, largeur: 24, hauteur: 24)
        var p = Path()
        switch type {
        case .poste:
            // Dessin du jeu C : hampe, courbe en bas (demi-cercle de rayon 4,9), puis les deux barbes.
            let h = Hamecon(boite: b)
            p.move(to: h.pt(13, 6.6))
            p.addLine(to: h.pt(13, 15.8))
            p.demiCercle(vers: h.pt(3.2, 15.8), horaire: true)
            p.move(to: h.pt(3.2, 15.8))
            p.addLine(to: h.pt(1.4, 13.2))
            p.move(to: h.pt(3.2, 15.8))
            p.addLine(to: h.pt(5.8, 14.2))
        case .amorcage:
            // Anse : M8.2 9.4 V7.6 a3.8 3.8 0 0 1 7.6 0 v1.8
            p.move(to: b.p(8.2, 9.4))
            p.addLine(to: b.p(8.2, 7.6))
            p.demiCercle(vers: b.p(15.8, 7.6), horaire: true)
            p.addLine(to: b.p(15.8, 9.4))
        case .parking, .danger:
            break
        }
        return p
    }
}

/// La couleur de chaque type (variantes claire et sombre de la planche : `--t-parking`, `--t-poste`, `--t-danger`,
/// `--t-amorcage`). Chaque type se distingue aussi par la forme de son pictogramme (daltonisme).
enum CouleursRepere {
    static func couleur(_ type: IconeRepere) -> Color {
        switch type {
        case .parking: return Palette.encreDouce                   // gris ardoise
        case .poste: return Palette.marine                         // marine
        case .danger: return Palette.alerte                        // orange : la seule couleur d'alerte
        case .amorcage: return CouleursCarte.frequentationMoyenne  // ambre #B97A0A (clair) / #E0AE45 (sombre)
        }
    }
}

/// L'icône d'un repère : épingle goutte de largeur `taille` (hauteur = taille x 41 / 32) et pictogramme blanc.
/// Le bas du rectangle est la pointe de la goutte : c'est lui qui marque l'endroit.
/// - `suitLeTexte` : la taille grandit avec le texte (fiche, liste, choix du type). Faux pour l'épingle de la carte.
/// - `decoratif` : caché de VoiceOver quand le parent porte déjà le libellé.
/// Le nom `IconeRepere` est pris par l'énumération du type de repère (Core) : la vue s'appelle donc `IconeRepereView`.
struct IconeRepereView: View {
    @Environment(\.locale) private var locale
    let type: IconeRepere
    let taille: CGFloat
    var suitLeTexte = false
    var decoratif = false

    @ScaledMetric(relativeTo: .body) private var facteur: CGFloat = 1

    private var largeur: CGFloat { suitLeTexte ? taille * facteur : taille }
    private var hauteur: CGFloat { largeur * EpingleGoutte.hauteur / EpingleGoutte.largeur }
    /// Le pictogramme occupe un carré de 18/32 de la largeur, posé comme dans la planche (décalage 7 ; 6,5 sur 32).
    private var cotePicto: CGFloat { largeur * 18 / 32 }
    /// Épaisseur du trait en part de la boîte 24 : 3,0 pour l'hameçon (assez épais à 24 pt), 2,0 pour l'anse du seau.
    private var traitRelatif: CGFloat { (type == .poste ? 3.0 : 2.0) / 24 }

    var body: some View {
        let picto = Palette.surMarine
        ZStack(alignment: .topLeading) {
            EpingleGoutte().fill(CouleursRepere.couleur(type))
            EpingleGoutte().stroke(Palette.surface, style: StrokeStyle(lineWidth: largeur * 2 / 32, lineJoin: .round))
            ZStack {
                GlypheRepereRempli(type: type).fill(picto, style: FillStyle(eoFill: true))
                GlypheRepereTrait(type: type)
                    .stroke(picto, style: StrokeStyle(lineWidth: cotePicto * traitRelatif, lineCap: .round, lineJoin: .round))
            }
            .frame(width: cotePicto, height: cotePicto)
            .offset(x: largeur * 7 / 32, y: largeur * 6.5 / 32)
        }
        .frame(width: largeur, height: hauteur, alignment: .topLeading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TextesReperes.libelleVocal(type, locale: locale))
        .accessibilityAddTraits(.isImage)
        .accessibilityHidden(decoratif)
    }
}
