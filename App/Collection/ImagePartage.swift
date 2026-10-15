import Core
import SwiftUI
import UIKit

/// L'image rendue pour le partage : le recto seulement. Ni bloc météo, ni marque Apple à recopier, aucune coordonnée,
/// et un PNG fabriqué par UIKit, sans métadonnée.
enum ImagePartage {
    @MainActor
    static func png(de prise: Prise, services: ServicesCollection, largeur: CGFloat = 360) -> Data? {
        guard let espece = services.especes.especesPechables().first(where: { $0.espece == prise.espece }) else { return nil }
        let dept = Formats.departement(depuisLieuFlou: prise.lieuFlou)
        // Pas de conditions, pas de durée : le partage ne porte jamais d'indice de plus pour retrouver le coin.
        let detail = CarteDetaillee(prise: prise, conditions: nil, dureeSecondes: nil)
        let infos = InfosCarte.construire(detail: detail, espece: espece, zone: dept, toutesLesCartes: [prise],
                                          especesDeLaZone: [], services: services)
        let vue = CarteRectoView(infos: infos, anime: false, inclinaison: .zero, refletFixe: true)
            .frame(width: largeur, height: largeur / Jeton.rapportCarte)
            .padding(16)
            .background(Jeton.fondPage)
        let rendu = ImageRenderer(content: vue)
        rendu.scale = 3
        return rendu.uiImage?.pngData()
    }
}
