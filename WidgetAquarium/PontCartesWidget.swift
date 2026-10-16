import Foundation
import UIKit
import WidgetKit

// Cible APP seulement. Le pont entre l'app et le widget « Ma carte » (A le branche dans RootView).
// À appeler :
//   - `enregistrerPhoto(_:id:)` puis `publier(cartes:)`, dans cet ordre, juste après la révélation d'une carte
//     (la prise est confirmée et entre au Pescedex) : la photo du verso d'abord, la liste ensuite ;
//   - `publier(cartes:)` aussi quand le Pescedex change autrement : carte supprimée (le pont range alors
//     la photo orpheline), rareté recalculée, nouvelle carte déclarée (sans photo : `aPhoto` à faux).
// Les cartes passées : les plus récentes d'abord, 60 au plus, sans carte d'exemple. Aucun lieu, aucune date.
// Le fichier partagé garde la face montrée de chaque carte : l'app relit toujours le fichier avant d'écrire
// et ne touche pas à ce que le widget a retourné.
// Tout est en `try?` : un App Group absent ou un disque plein ne font jamais planter l'app.

nonisolated enum PontCartesWidget {
    /// Largeur maximale de la photo du verso : assez pour le grand widget, assez léger pour la mémoire des widgets.
    static let largeurPhoto: CGFloat = 600
    static let qualiteJPEG: CGFloat = 0.8

    /// Remplace la liste des cartes ; garde la face (recto ou verso) déjà montrée de celles qui restent.
    static func publier(cartes: [InstantaneCartes.Carte]) {
        let actuel = DepotCartesWidget.lire()
        let neuf = InstantaneCartes(cartes: cartes, faceVisible: actuel.faceVisible)
        try? DepotCartesWidget.ecrire(neuf)
        // Une carte supprimée ne laisse pas sa photo dans le conteneur partagé.
        let gardees = Set(neuf.cartes.map(\.id))
        for id in DepotCartesWidget.idsDesPhotos() where !gardees.contains(id) {
            DepotCartesWidget.supprimerPhoto(id: id)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: DepotCartesWidget.genre)
    }

    /// Réduit la photo à 600 px de large puis la ré-encode en JPEG 0,8 SANS métadonnées : le rendu par
    /// `UIGraphicsImageRenderer` ne recopie ni EXIF ni GPS ni orientation (l'image sort déjà droite).
    /// Rend `false` si la photo n'a pas pu être écrite.
    @discardableResult
    static func enregistrerPhoto(_ image: UIImage, id: String) -> Bool {
        guard let jpeg = jpegSansMetadonnees(image) else { return false }
        do {
            try DepotCartesWidget.ecrirePhoto(jpeg, id: id)
            return true
        } catch {
            return false
        }
    }

    static func supprimerPhoto(id: String) {
        DepotCartesWidget.supprimerPhoto(id: id)
    }

    static func jpegSansMetadonnees(_ image: UIImage) -> Data? {
        let taille = image.size
        guard taille.width > 0, taille.height > 0 else { return nil }
        let echelle = min(1, largeurPhoto / taille.width)
        let cible = CGSize(width: (taille.width * echelle).rounded(), height: (taille.height * echelle).rounded())
        let format = UIGraphicsImageRendererFormat()
        // 1 point = 1 pixel : la largeur demandée est la largeur réelle du fichier.
        format.scale = 1
        format.opaque = true
        let rendu = UIGraphicsImageRenderer(size: cible, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: cible))
        }
        return rendu.jpegData(compressionQuality: qualiteJPEG)
    }
}
