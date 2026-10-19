import UIKit

/// Prépare l'avatar : carré recadré au centre, 256 px, JPEG. Le JPEG est réencodé : aucune métadonnée (EXIF, GPS) n'en sort.
nonisolated enum AvatarImage {
    static let cote: CGFloat = 256

    /// Les poissons proposés comme avatar (noms d'images de `Assets.xcassets/Especes`).
    static let poissons = ["brochet", "perche-commune", "sandre", "carpe-commune", "truite-fario", "black-bass", "gardon", "tanche"]

    /// Une photo de la galerie, recadrée au centre. `nil` si les données ne sont pas une image.
    static func preparer(_ donnees: Data) -> Data? {
        guard let image = UIImage(data: donnees), image.size.width > 0, image.size.height > 0 else { return nil }
        let echelle = cote / min(image.size.width, image.size.height)
        let taille = CGSize(width: image.size.width * echelle, height: image.size.height * echelle)
        let origine = CGPoint(x: (cote - taille.width) / 2, y: (cote - taille.height) / 2)
        return rendu().jpegData(withCompressionQuality: 0.8) { _ in
            image.draw(in: CGRect(origin: origine, size: taille))
        }
    }

    /// Un poisson de l'app sur fond clair. `nil` si l'image n'existe pas.
    static func depuisPoisson(_ nom: String) -> Data? {
        guard let poisson = UIImage(named: nom), poisson.size.width > 0, poisson.size.height > 0 else { return nil }
        let marge: CGFloat = 28
        let zone = cote - 2 * marge
        let echelle = min(zone / poisson.size.width, zone / poisson.size.height)
        let taille = CGSize(width: poisson.size.width * echelle, height: poisson.size.height * echelle)
        let origine = CGPoint(x: (cote - taille.width) / 2, y: (cote - taille.height) / 2)
        return rendu().jpegData(withCompressionQuality: 0.8) { contexte in
            UIColor(red: 0.86, green: 0.91, blue: 0.96, alpha: 1).setFill()
            contexte.fill(CGRect(x: 0, y: 0, width: cote, height: cote))
            poisson.draw(in: CGRect(origin: origine, size: taille))
        }
    }

    private static func rendu() -> UIGraphicsImageRenderer {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: cote, height: cote), format: format)
    }
}
