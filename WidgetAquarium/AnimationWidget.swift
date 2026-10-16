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

    var body: some View {
        GeometryReader { geo in
            let taille = max(geo.size.width, geo.size.height, 1)
            Text(reference + decalage, style: .timer)
                .font(Font.custom("FishMeClignoteChiffre\(chiffre)-Regular", size: taille))
                .frame(width: taille * 9, height: taille)
                .multilineTextAlignment(.trailing)
                .offset(x: -taille * 8)
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
                image(0)
            }
        }
        .allowsHitTesting(false)
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
}
