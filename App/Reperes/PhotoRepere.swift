import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Prépare une photo de repère : réduite à 1 600 px de grand côté, JPEG sans aucune métadonnée (ni GPS, ni date, ni appareil),
/// 400 Ko au plus. Même idée que `NettoyagePhoto` (App/Collection/, dossier d'un autre lot, donc pas importé).
nonisolated enum PhotoRepere {
    static let grandCoteMax = 1_600
    static let octetsMax = 400 * 1_024
    /// Qualités essayées dans l'ordre, puis une taille plus petite si 400 Ko ne suffisent pas.
    private static let qualites: [Double] = [0.7, 0.6, 0.5, 0.4, 0.3]
    private static let reductions: [Int] = [1_600, 1_300, 1_000, 800]

    /// `nil` si les données ne sont pas une image, ou si elles restent trop lourdes même très réduites.
    static func preparer(_ donnees: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil) else { return nil }
        for cote in reductions {
            // La miniature applique l'orientation : l'image écrite est droite et n'a plus besoin de balise.
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: cote,
            ]
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
            for qualite in qualites {
                guard let jpeg = encoder(image, qualite: qualite) else { return nil }
                if jpeg.count <= octetsMax { return jpeg }
            }
        }
        return nil
    }

    private static func encoder(_ image: CGImage, qualite: Double) -> Data? {
        let sortie = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(sortie, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        // Seule la qualité est passée : aucune propriété d'image n'est recopiée.
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: qualite] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return sortie as Data
    }

    /// Vrai si le fichier porte un GPS, une date de prise, ou la marque, le modèle ou la date de l'appareil : sert aux tests.
    /// ImageIO écrit lui-même des blocs {Exif} et {TIFF} techniques (taille, orientation) : seule la présence de ces champs compte.
    static func contientMetadonnees(_ donnees: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              let proprietes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return false }
        if proprietes[kCGImagePropertyGPSDictionary] != nil { return true }
        let exif = proprietes[kCGImagePropertyExifDictionary] as? [CFString: Any]
        if exif?[kCGImagePropertyExifDateTimeOriginal] != nil || exif?[kCGImagePropertyExifDateTimeDigitized] != nil { return true }
        let tiff = proprietes[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        return tiff?[kCGImagePropertyTIFFMake] != nil || tiff?[kCGImagePropertyTIFFModel] != nil
            || tiff?[kCGImagePropertyTIFFDateTime] != nil
    }
}
