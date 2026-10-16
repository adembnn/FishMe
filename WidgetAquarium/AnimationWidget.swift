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
/// grâce à deux masques imbriqués (voir `HorlogeAnimation.masques`). Une seule image est visible à la fois.
/// `actif` faux, ou polices absentes : l'image 0, fixe (jamais rien).
struct ImagesAnimees<Contenu: View>: View {
    let reference: Date
    let actif: Bool
    @ViewBuilder let image: (Int) -> Contenu

    var body: some View {
        if actif && PolicesMasque.disponibles {
            ZStack {
                ForEach(0..<HorlogeAnimation.nombreImages, id: \.self) { j in
                    let m = HorlogeAnimation.masques(copie: j)
                    image(j)
                        .mask(MasqueClignotant(chiffre: m.a.chiffre, reference: reference, decalage: m.a.decalage))
                        .mask(MasqueClignotant(chiffre: m.b.chiffre, reference: reference, decalage: m.b.decalage))
                }
            }
            .allowsHitTesting(false)
        } else {
            image(0)
        }
    }
}

/// Les 10 polices de masque sont-elles enregistrées dans ce processus (clé UIAppFonts de la cible) ?
enum PolicesMasque {
    static let disponibles: Bool = (0..<10).allSatisfy {
        UIFont(name: "FishMeClignoteChiffre\($0)-Regular", size: 12) != nil
    }
}
