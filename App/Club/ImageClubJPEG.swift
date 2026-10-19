import Foundation
import ImageIO
import UniformTypeIdentifiers

/// La photo d'un club qui part en ligne : JPEG de 512 px au plus, SANS métadonnées (ni EXIF, ni GPS).
/// Piège de la fiche L22 : écrire la photo avec ses métadonnées. On ne passe aucune propriété à la destination : rien n'est recopié.
nonisolated enum ImageClubJPEG {
    static let cote = 512

    static func preparer(_ donnees: Data, cote: Int = ImageClubJPEG.cote) throws -> Data {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil) else { throw ErreurClub.imageRefusee }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: cote,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { throw ErreurClub.imageRefusee }
        let sortie = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(sortie, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw ErreurClub.imageRefusee }
        let reglages: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.8]
        CGImageDestinationAddImage(destination, image, reglages as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ErreurClub.imageRefusee }
        return sortie as Data
    }

    /// Vrai si l'image porte un dictionnaire GPS ou les marques de l'appareil (TIFF Make et Model), pour les tests.
    /// ⚠ ImageIO peut écrire un petit dictionnaire EXIF technique (dimensions) : on ne le compte pas, il ne dit rien du lieu ni de l'appareil.
    static func contientMetadonnees(_ donnees: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              let proprietes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return false }
        let tiff = proprietes[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        return proprietes[kCGImagePropertyGPSDictionary] != nil || tiff?[kCGImagePropertyTIFFMake] != nil
            || tiff?[kCGImagePropertyTIFFModel] != nil
    }
}
