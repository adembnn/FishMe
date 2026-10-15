import Foundation
import ImageIO
import UniformTypeIdentifiers

/// L'image d'une carte partagée est ré-encodée sans aucune métadonnée : ni GPS, ni EXIF, ni date.
nonisolated enum ImageSansGPS {
    /// Vrai si l'image porte un bloc GPS.
    static func contientGPS(_ donnees: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              let proprietes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return false }
        return proprietes[kCGImagePropertyGPSDictionary] != nil
    }

    /// Un PNG neuf, fabriqué à partir des seuls pixels. `nil` si l'image est illisible.
    static func nettoyer(_ donnees: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        let sortie = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(sortie, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        let propre = sortie as Data
        return contientGPS(propre) ? nil : propre
    }
}
