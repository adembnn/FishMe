import Core
import SwiftUI
import UIKit

/// Le verso de la carte « Eau calme » : la photo de la sortie seule, plein cadre, sans aucun texte (décision d'Adem) ;
/// sans photo, le décor d'eau calme. La météo, la lune et la durée restent sous la carte (`BredouillePleinEcranView`).
struct CarteBredouilleVersoView: View {
    let carte: CarteBredouille
    let services: ServicesCollection
    var photo: UIImage? = nil

    @State private var photoChargee: UIImage?

    private var image: UIImage? { photo ?? photoChargee }

    var body: some View {
        CarteCadre(style: .commun, declaree: false, fond: Color(carte: 0xE9EDEB)) {
            GeometryReader { geo in
                fond
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        }
        .task(id: carte.photoURL) { if photo == nil { photoChargee = await PhotoSortie.charger(carte.photoURL) } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(image == nil ? "Verso de la carte Eau calme" : "Photo de la sortie")
    }

    @ViewBuilder
    private var fond: some View {
        if let image {
            Color.clear.overlay { Image(uiImage: image).resizable().scaledToFill() }
                .clipped()
        } else {
            EauCalmeFond(avecBouchon: true)
        }
    }
}
