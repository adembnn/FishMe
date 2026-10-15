import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Ré-encode une photo en ne gardant que l'image et son orientation : aucune étiquette de lieu (GPS), de date ou d'appareil.
nonisolated enum NettoyagePhoto {
    /// JPEG sans métadonnée, sauf l'orientation. `nil` si les données ne sont pas une image.
    static func sansMetadonnees(_ donnees: Data, qualite: Double = 0.85) -> Data? {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        var orientation = 1
        if let proprietes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let o = proprietes[kCGImagePropertyOrientation] as? Int {
            orientation = o
        }
        let sortie = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(sortie, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImagePropertyOrientation: orientation,
            kCGImageDestinationLossyCompressionQuality: qualite,
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return sortie as Data
    }

    /// Vrai si le fichier porte un bloc GPS (sert aux tests).
    static func contientGPS(_ donnees: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              let proprietes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return false }
        return proprietes[kCGImagePropertyGPSDictionary] != nil
    }
}
