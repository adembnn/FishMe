import XCTest
import ImageIO
import UIKit
import UniformTypeIdentifiers
@testable import BuildChallenge

// Écrits sans compilateur Apple : non exécutés. Critère 14 de la fiche (la version sur appareil, avec une vraie photo HEIC de
// 12 Mo et exiftool, reste à faire sur iPhone).

@MainActor
final class PhotoRepereTests: XCTestCase {
    /// Une grande image bruitée, avec des balises GPS, EXIF et TIFF, en JPEG pleine qualité (donc lourde).
    private func photoLourdeAvecMetadonnees() throws -> Data {
        let taille = CGSize(width: 3_200, height: 2_400)
        let rendu = UIGraphicsImageRenderer(size: taille, format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f }())
        let image = rendu.image { contexte in
            var generateur = SystemRandomNumberGenerator()
            for _ in 0..<6_000 {
                UIColor(red: .random(in: 0...1, using: &generateur), green: .random(in: 0...1, using: &generateur),
                        blue: .random(in: 0...1, using: &generateur), alpha: 1).setFill()
                contexte.fill(CGRect(x: .random(in: 0..<3_200, using: &generateur), y: .random(in: 0..<2_400, using: &generateur),
                                     width: .random(in: 4...120, using: &generateur), height: .random(in: 4...120, using: &generateur)))
            }
        }
        let cg = try XCTUnwrap(image.cgImage)
        let sortie = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(sortie, UTType.jpeg.identifier as CFString, 1, nil))
        let proprietes: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 1.0,
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 48.85, kCGImagePropertyGPSLatitudeRef: "N",
                                            kCGImagePropertyGPSLongitude: 2.35, kCGImagePropertyGPSLongitudeRef: "E"],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:10:19 10:00:00"],
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFMake: "Apple", kCGImagePropertyTIFFModel: "iPhone"],
        ]
        CGImageDestinationAddImage(destination, cg, proprietes as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return sortie as Data
    }

    func testLaSourceDeTestPorteBienDesMetadonnees() throws {
        let source = try photoLourdeAvecMetadonnees()
        XCTAssertTrue(PhotoRepere.contientMetadonnees(source))
        XCTAssertGreaterThan(source.count, PhotoRepere.octetsMax)
    }

    func testPhotoReduiteSansMetadonneeEtSous400Ko() throws {
        let source = try photoLourdeAvecMetadonnees()
        let propre = try XCTUnwrap(PhotoRepere.preparer(source))
        XCTAssertLessThanOrEqual(propre.count, 400 * 1_024)
        XCTAssertFalse(PhotoRepere.contientMetadonnees(propre))
        let image = try XCTUnwrap(UIImage(data: propre)?.cgImage)
        XCTAssertLessThanOrEqual(max(image.width, image.height), PhotoRepere.grandCoteMax)
    }

    func testDonneesQuiNeSontPasUneImageDonnentNil() {
        XCTAssertNil(PhotoRepere.preparer(Data("pas une image".utf8)))
        XCTAssertNil(PhotoRepere.preparer(Data()))
    }
}
