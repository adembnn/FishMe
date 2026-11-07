import CoreText
import SwiftUI
import UIKit

// Widget + app. Moteur d'animation continue, calqué sur l'exemple de Bryce Bostwick (MIT,
// github.com/brycebostwick/WidgetAnimation) qui tourne dans un vrai widget : `Text(date, style: .timer)` est
// redessiné par le système chaque seconde. Les polices `FishMeClignoteChiffreK` (faites à partir de SA police,
// voir Polices/) remplacent les secondes du chrono par un carré plein quand leur chiffre des unités vaut K.
// La logique (quelle copie est visible quand) est dans HorlogeAnimation.swift, testée sous Linux.

/// Une vue pleine 1 s toutes les 10 s : un chrono dont seul le dernier caractère (la ligature des secondes) se voit.
/// Même mise en page que `SimpleBlinkingView` de l'exemple : cadre de 9 caractères, texte aligné à droite,
/// décalé de 8 caractères vers la gauche. Le chrono reste court (« 1:00 ») : la référence est 60 s avant l'entrée.
struct MasqueClignotant: View {
    let chiffre: Int
    let reference: Date
    let decalage: TimeInterval
    /// Nom PostScript de la police ; nil : `FishMeClignoteChiffre<chiffre>` (plein si le chiffre des unités vaut `chiffre`).
    var police: String? = nil
    /// Taille de police réelle du chrono, en points (voir `body`).
    static let petit: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let taille = max(geo.size.width, geo.size.height, 1)
            // Le chrono est dessiné en petit (`MasqueClignotant.petit` points) puis agrandi : en police géante
            // (taille du widget, cadre de 9 caractères), chaque masque se rastérisait sur ~9 fois la largeur du
            // widget et l'extension montait à 60 Mo pour 16 copies (mesuré le 7 nov.). Le carré plein agrandi
            // reste un aplat : seul son bord est flou, hors cadre.
            let p = Self.petit
            Text(reference + decalage, style: .timer)
                .font(Font.custom(police ?? "FishMeClignoteChiffre\(chiffre)-Regular", size: p))
                .frame(width: p * 9, height: p)
                .multilineTextAlignment(.trailing)
                .offset(x: -p * 8)
                .frame(width: p, height: p, alignment: .topLeading)
                .clipped()
                .scaleEffect(taille / p, anchor: .topLeading)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Empile les 80 images d'une boucle de 10 s (n° 0..<80). Chaque copie j n'est visible que 1/8 s par boucle,
/// grâce à deux masques imbriqués (voir `HorlogeAnimation.masques`). Une seule copie est visible à la fois.
///
/// Sous les copies, une couche de base fixe : l'image 0, toujours dessinée. Si l'hôte ne dessine pas les masques
/// (ou `ImageRenderer`, qui rend les chronos vides), on voit au moins les poissons à leur place de départ.
/// Chaque copie porte `fond` derrière son image : la copie visible recouvre ainsi la couche de base, et l'on ne
/// voit jamais deux fois le même poisson. `actif` faux, ou polices absentes : la couche de base seule.
struct ImagesAnimees<Contenu: View, Fond: View>: View {
    let reference: Date
    let actif: Bool
    @ViewBuilder let fond: () -> Fond
    @ViewBuilder let image: (Int) -> Contenu

    var body: some View {
        ZStack {
            if actif && PolicesMasque.disponibles {
                ForEach(0..<HorlogeAnimation.nombreImages, id: \.self) { j in
                    let m = HorlogeAnimation.masques(copie: j)
                    ZStack {
                        fond()
                        image(j)
                    }
                    .mask(MasqueClignotant(chiffre: m.a.chiffre, reference: reference, decalage: m.a.decalage))
                    .mask(MasqueClignotant(chiffre: m.b.chiffre, reference: reference, decalage: m.b.decalage))
                }
            } else {
                // Couche de base seulement sans animation : animée, une copie est toujours visible, et la base
                // obligeait chaque copie à porter son propre fond (160 fonds pleine taille : widget noir sur iPhone).
                // Appelée avec -1 : « pose de repos », que l'appelant choisit visible (la pose 0 d'une traversée
                // part hors du cadre : avec « Réduire les animations », le widget montrait 0 poisson).
                image(-1)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Boucle courte (vrai widget) : `boucle.copies` copies (16 pour 2 s à 8 images/s), une seule visible à la fois.
/// Le masque de chaque copie est l'union de `10 / duree` chronos (voir `HorlogeAnimation.masques(copie:boucle:)`).
/// Pas de couche de base ni de fond dans les copies : le décor reste en `containerBackground`, hors des copies.
/// `actif` faux, ou polices absentes : `image(-1)`, la pose fixe.
struct BoucleAnimee<Contenu: View>: View {
    let reference: Date
    let actif: Bool
    var boucle: HorlogeAnimation.Boucle = .battement
    /// Boucle de 2 s : un seul chrono par masque, en police de parité (`FishMeClignotePairK`), au lieu de l'union
    /// de 5 chronos. Repli sur l'union si ces polices manquent.
    var parite: Bool = false
    @ViewBuilder let image: (Int) -> Contenu

    var body: some View {
        ZStack {
            if actif && PolicesMasque.disponibles {
                let pairs = parite && boucle.duree == 2 && PolicesMasque.pairesDisponibles
                ForEach(0..<boucle.copies, id: \.self) { k in
                    let m = HorlogeAnimation.masques(copie: k, boucle: boucle)
                    if pairs {
                        let p = HorlogeAnimation.masquesParite(copie: k, boucle: boucle)
                        image(k)
                            .mask(MasqueClignotant(chiffre: 0, reference: reference, decalage: p.a.decalage,
                                                   police: PolicesMasque.pair(p.a.parite)))
                            .mask(MasqueClignotant(chiffre: 0, reference: reference, decalage: p.b.decalage,
                                                   police: PolicesMasque.pair(p.b.parite)))
                    } else {
                        image(k)
                            .mask(UnionMasques(chiffres: m.a.chiffres, reference: reference, decalage: m.a.decalage))
                            .mask(UnionMasques(chiffres: m.b.chiffres, reference: reference, decalage: m.b.decalage))
                    }
                }
            } else {
                image(-1)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Plein quand le chiffre des unités du chrono (décalé) est l'un de `chiffres`.
private struct UnionMasques: View {
    let chiffres: [Int]
    let reference: Date
    let decalage: TimeInterval

    var body: some View {
        ZStack {
            ForEach(chiffres, id: \.self) { c in
                MasqueClignotant(chiffre: c, reference: reference, decalage: decalage)
            }
        }
    }
}

extension ImagesAnimees where Fond == EmptyView {
    /// Sans fond : la copie visible ne cache pas la couche de base (à réserver aux images sans déplacement).
    init(reference: Date, actif: Bool, @ViewBuilder image: @escaping (Int) -> Contenu) {
        self.init(reference: reference, actif: actif, fond: { EmptyView() }, image: image)
    }
}

/// Les 10 polices de masque sont-elles enregistrées dans ce processus (clé UIAppFonts de la cible) ?
enum PolicesMasque {
    static let disponibles: Bool = (0..<10).allSatisfy {
        UIFont(name: "FishMeClignoteChiffre\($0)-Regular", size: 12) != nil
    }

    /// Police de parité : pleine quand le chiffre des unités a la parité de `chiffre`.
    static func pair(_ chiffre: Int) -> String { "FishMeClignotePair\(chiffre % 2)-Regular" }

    /// Les 2 polices de parité. Absentes de `UIAppFonts` (Info.plist hors du dossier du lot) : enregistrées ici,
    /// pour ce processus, depuis le paquet de la cible (le dossier synchronisé les y copie).
    static let pairesDisponibles: Bool = {
        for k in 0..<2 where UIFont(name: pair(k), size: 12) == nil {
            if let url = Bundle.main.url(forResource: "FishMeClignotePair\(k)", withExtension: "otf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        return (0..<2).allSatisfy { UIFont(name: pair($0), size: 12) != nil }
    }()
}
