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
    nonisolated enum Erreur: Error, Equatable { case illisible, ecriture, export, lieuPresent }

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

    // MARK: Contrôle final « aucun lieu »

    /// Une métadonnée réduite à ce qui sert à reconnaître un lieu : son identifiant, sa clé commune et sa valeur texte.
    /// Sépare la lecture AVFoundation (⚠ non vérifiable ici) de la décision (testée sur des jeux simulés).
    nonisolated struct ElementMetadonnee: Sendable, Equatable {
        var identifiant: String
        var cleCommune: String
        var valeur: String
    }

    /// Les identifiants et clés qui portent un lieu : QuickTime (`com.apple.quicktime.location.ISO6709`, `©xyz`), ISO 6709, GPS.
    static func estBaliseLieu(_ e: ElementMetadonnee) -> Bool {
        let identifiant = e.identifiant.lowercased()
        let cle = e.cleCommune.lowercased()
        if identifiant.contains("location") || identifiant.contains("iso6709") || identifiant.contains("xyz") || identifiant.contains("gps") { return true }
        if cle == "location" || cle == "gps" { return true }
        return ressembleAISO6709(e.valeur)
    }

    /// « +48.8566+002.3522/ » : une latitude et une longitude collées, la forme ISO 6709 des vidéos de l'iPhone.
    static func ressembleAISO6709(_ valeur: String) -> Bool {
        valeur.range(of: "[+-][0-9]{1,3}[.][0-9]+[+-][0-9]{1,3}", options: .regularExpression) != nil
    }

    static func contientBaliseLieu(parmi elements: [ElementMetadonnee]) -> Bool {
        elements.contains(where: estBaliseLieu)
    }

    /// Filet de sécurité : les marques d'un lieu cherchées dans les octets du fichier (atome « ©xyz », clé ISO 6709, clé QuickTime).
    static func contientBaliseLieu(octets: Data) -> Bool {
        let marques: [Data] = [Data([0xA9, 0x78, 0x79, 0x7A]), Data("ISO6709".utf8), Data("quicktime.location".utf8)]
        return marques.contains { octets.range(of: $0) != nil }
    }

    /// Vrai si le fichier vidéo porte une balise de lieu : métadonnées du fichier, de TOUS ses formats (dont `keys` et `udta`),
    /// de chaque piste, puis les octets. ⚠ à vérifier sur le Mac : `load(.availableMetadataFormats)`, `loadMetadata(for:)`,
    /// `load(.tracks)` ; repli : les octets seuls restent testés.
    static func contientBaliseLieu(_ url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        var items: [AVMetadataItem] = []
        if let m = try? await asset.load(.metadata) { items += m }
        if let c = try? await asset.load(.commonMetadata) { items += c }
        if let formats = try? await asset.load(.availableMetadataFormats) {
            for format in formats {
                if let m = try? await asset.loadMetadata(for: format) { items += m }
            }
        }
        if let pistes = try? await asset.load(.tracks) {
            for piste in pistes {
                if let m = try? await piste.load(.metadata) { items += m }
                if let c = try? await piste.load(.commonMetadata) { items += c }
                if let formats = try? await piste.load(.availableMetadataFormats) {
                    for format in formats {
                        if let m = try? await piste.loadMetadata(for: format) { items += m }
                    }
                }
            }
        }
        var elements: [ElementMetadonnee] = []
        for item in items {
            let valeur = (try? await item.load(.stringValue)) ?? ""
            elements.append(ElementMetadonnee(identifiant: item.identifier?.rawValue ?? "", cleCommune: item.commonKey?.rawValue ?? "",
                                              valeur: valeur))
        }
        if contientBaliseLieu(parmi: elements) { return true }
        if let octets = try? Data(contentsOf: url, options: .mappedIfSafe), contientBaliseLieu(octets: octets) { return true }
        return false
    }
}
