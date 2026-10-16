import SwiftUI
import UIKit

// Widget + app. Moteur d'animation continue : technique de Bryce Bostwick (MIT), voir `HorlogeAnimation.swift`.
// `Text(date, style: .timer)` est redessiné chaque seconde par le système, même dans un widget. Avec une police
// dont les chiffres pairs sont un carré plein et les impairs vides, on obtient une vue pleine 1 s sur 2 ;
// deux telles vues décalées servent de masques et ne laissent voir qu'une fenêtre de 1/8 s.

/// Une vue qui est pleine 1 s sur 2 : le chrono, réduit à son dernier chiffre, dessiné avec une police de masque.
/// `police` : `FishMeMasquePair-Regular` ou `FishMeMasqueImpair-Regular`. `decalage` en secondes.
struct MasqueClignotant: View {
    let police: String
    let decalage: TimeInterval

    var body: some View {
        GeometryReader { geo in
            let taille = max(geo.size.width, geo.size.height, 1)
            // Date fixe et passée (le chrono compte vers le haut) ; avance 1000/em 1000, ligne = 1 em.
            Text(HorlogeAnimation.dateReference + decalage, style: .timer)
                .font(Font.custom(police, fixedSize: taille))
                .lineLimit(1)
                // Jamais tronqué : depuis la date de référence, le chrono a plus de 9 caractères (« 25600:12:34 »).
                // Tronqué, il finirait par « … », un caractère vide de la police : le masque serait toujours vide
                // et aucun poisson ne serait dessiné (bug vu sur le simulateur le 16 oct.).
                .fixedSize()
                // Cadre de 24 caractères aligné à droite : le dernier chiffre est toujours au même endroit...
                .frame(width: taille * 24, height: taille, alignment: .trailing)
                // ... puis on le ramène dans le coin haut-gauche, sur la surface de la vue (23 em à gauche).
                .offset(x: -taille * 23)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// Empile `nombre` images d'animation (n° 0..<nombre). Chaque copie j n'est visible que 1/8 s par boucle de 2 s,
/// grâce à deux masques imbriqués : pair décalé de j/8, impair décalé de (j+1)/8. Une seule image est visible à la fois.
/// Le contenu doit être sobre (pas d'ombre floue) : il est dessiné `nombre` fois.
struct ImagesAnimees<Contenu: View>: View {
    private let nombre: Int
    private let image: (Int) -> Contenu

    init(nombre: Int = HorlogeAnimation.nombreImages, @ViewBuilder image: @escaping (Int) -> Contenu) {
        self.nombre = nombre
        self.image = image
    }

    var body: some View {
        if PolicesMasque.disponibles {
            copies
        } else {
            // Repli : sans les polices de masque, l'animation ne peut pas marcher ; on dessine l'image 0, fixe.
            image(0)
        }
    }

    private var copies: some View {
        ZStack {
            ForEach(0..<nombre, id: \.self) { j in
                image(j)
                    .mask(MasqueClignotant(police: "FishMeMasquePair-Regular",
                                           decalage: HorlogeAnimation.decalagePair(copie: j)))
                    .mask(MasqueClignotant(police: "FishMeMasqueImpair-Regular",
                                           decalage: HorlogeAnimation.decalageImpair(copie: j)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Les deux polices de masque sont-elles enregistrées dans ce processus (clé UIAppFonts de la cible) ?
enum PolicesMasque {
    static let disponibles: Bool =
        UIFont(name: "FishMeMasquePair-Regular", size: 12) != nil
        && UIFont(name: "FishMeMasqueImpair-Regular", size: 12) != nil
}
