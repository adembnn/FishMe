import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Ce qui part vers CloudKit : un fichier sans métadonnée de lieu, et sa vignette.
nonisolated struct MediaPret: Sendable, Equatable {
    var genre: GenreMedia
    var fichier: URL
    var vignette: URL
    var dureeS: Int
}

/// Prépare la photo ou la vidéo d'une publication : recompression, aucune balise GPS ni de lieu, jamais.
///
/// ⚠ à vérifier sur le Mac : `AVAssetExportSession.export(to:as:)` (async, iOS 18), `metadataItemFilter`,
/// `AVAssetImageGenerator.image(at:)` (async). Repli si `export(to:as:)` manque : `exportAsynchronously` (déprécié).
nonisolated enum PreparationMedia {
    enum Erreur: Error, Equatable { case illisible, ecriture, export, lieuPresent }

    static let coteMax = 1600
    static let coteVignette = 640
    static let dureeMaxS = 15

    // MARK: Photo

    /// Un JPEG neuf, 1 600 px au plus, fabriqué à partir des seuls pixels : ni EXIF, ni GPS, ni date. `Erreur.illisible` sinon.
    static func jpegSansMetadonnee(_ donnees: Data, cote: Int = coteMax, qualite: Double = 0.8) throws -> Data {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil) else { throw Erreur.illisible }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: cote,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { throw Erreur.illisible }
        let sortie = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(sortie, UTType.jpeg.identifier as CFString, 1, nil) else { throw Erreur.ecriture }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: qualite] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw Erreur.ecriture }
        let propre = sortie as Data
        if contientGPS(propre) { throw Erreur.lieuPresent }
        return propre
    }

    static func contientGPS(_ donnees: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              let proprietes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return false }
        return proprietes[kCGImagePropertyGPSDictionary] != nil
    }

    static func preparerPhoto(_ donnees: Data, dossier: URL) throws -> MediaPret {
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        let nom = UUID().uuidString
        let fichier = dossier.appendingPathComponent("\(nom).jpg")
        let vignette = dossier.appendingPathComponent("\(nom)-v.jpg")
        try jpegSansMetadonnee(donnees).write(to: fichier, options: .atomic)
        try jpegSansMetadonnee(donnees, cote: coteVignette, qualite: 0.7).write(to: vignette, options: .atomic)
        return MediaPret(genre: .photo, fichier: fichier, vignette: vignette, dureeS: 0)
    }

    // MARK: Vidéo

    /// 15 s au plus, 720p, MP4, métadonnées retirées. Contrôle final : aucune balise de lieu dans le fichier.
    static func preparerVideo(depuis source: URL, dossier: URL) async throws -> MediaPret {
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        let nom = UUID().uuidString
        let fichier = dossier.appendingPathComponent("\(nom).mp4")
        let vignette = dossier.appendingPathComponent("\(nom)-v.jpg")

        let asset = AVURLAsset(url: source)
        let duree = try await asset.load(.duration)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else { throw Erreur.export }
        let fin = CMTimeMinimum(duree, CMTime(seconds: Double(dureeMaxS), preferredTimescale: 600))
        session.timeRange = CMTimeRange(start: .zero, duration: fin)
        session.metadata = []
        session.metadataItemFilter = AVMetadataItemFilter.forSharing()
        session.shouldOptimizeForNetworkUse = true
        try? FileManager.default.removeItem(at: fichier)
        do {
            try await session.export(to: fichier, as: .mp4)
        } catch {
            throw Erreur.export
        }
        if await contientBaliseLieu(fichier) { throw Erreur.lieuPresent }

        let generateur = AVAssetImageGenerator(asset: AVURLAsset(url: fichier))
        generateur.appliesPreferredTrackTransform = true
        generateur.maximumSize = CGSize(width: coteVignette, height: coteVignette)
        let image = try await generateur.image(at: .zero).image
        let jpeg = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(jpeg, UTType.jpeg.identifier as CFString, 1, nil) else { throw Erreur.ecriture }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.7] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw Erreur.ecriture }
        try (jpeg as Data).write(to: vignette, options: .atomic)

        let secondes = Int((fin.seconds).rounded(.up))
        return MediaPret(genre: .video, fichier: fichier, vignette: vignette, dureeS: min(max(secondes, 1), dureeMaxS))
    }

    /// Vrai si le fichier vidéo porte une balise de lieu (métadonnée d'emplacement QuickTime ou ISO 6709).
    static func contientBaliseLieu(_ url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        var elements: [AVMetadataItem] = []
        if let m = try? await asset.load(.metadata) { elements += m }
        if let c = try? await asset.load(.commonMetadata) { elements += c }
        for element in elements {
            let identifiant = element.identifier?.rawValue.lowercased() ?? ""
            let cle = element.commonKey?.rawValue.lowercased() ?? ""
            if identifiant.contains("location") || identifiant.contains("iso6709") || cle == "location" { return true }
        }
        // Filet de sécurité : l'atome « ©xyz » (emplacement QuickTime) cherché dans les octets du fichier.
        if let octets = try? Data(contentsOf: url, options: .mappedIfSafe), octets.range(of: Data([0xA9, 0x78, 0x79, 0x7A])) != nil {
            return true
        }
        return false
    }
}
