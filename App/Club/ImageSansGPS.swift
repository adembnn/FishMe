import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Réécrit une image en PNG sans aucune métadonnée (ni GPS, ni EXIF).
enum ImageSansGPS {
    enum Erreur: Error { case illisible, ecriture }

    static func nettoyer(_ donnees: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { throw Erreur.illisible }
        let sortie = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(sortie, UTType.png.identifier as CFString, 1, nil)
        else { throw Erreur.ecriture }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw Erreur.ecriture }
        return sortie as Data
    }

    static func contientGPS(_ donnees: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              let proprietes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return false }
        return proprietes[kCGImagePropertyGPSDictionary] != nil
    }
}
