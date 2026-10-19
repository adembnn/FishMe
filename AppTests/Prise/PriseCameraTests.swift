import Foundation
import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import BuildChallenge

/// La photo qui sort de la vue de capture n'a aucune métadonnée de lieu (L19). Écrit sans Mac, non exécuté.
@MainActor
struct PriseCameraTests {
    /// Un JPEG qui porte un dictionnaire GPS, comme en produirait un appareil dont la localisation est donnée.
    private func jpegAvecGPS() throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 30)).image { ctx in
            UIColor.blue.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 40, height: 30))
        }
        let cg = try #require(image.cgImage)
        let donnees = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(donnees, UTType.jpeg.identifier as CFString, 1, nil))
        let gps: [CFString: Any] = [kCGImagePropertyGPSLatitude: 48.82, kCGImagePropertyGPSLatitudeRef: "N",
                                    kCGImagePropertyGPSLongitude: 2.41, kCGImagePropertyGPSLongitudeRef: "E"]
        CGImageDestinationAddImage(destination, cg, [kCGImagePropertyGPSDictionary: gps] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return donnees as Data
    }

    private func aUnDictionnaireGPS(_ donnees: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              let proprietes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return false }
        return proprietes[kCGImagePropertyGPSDictionary] != nil
    }

    @Test func lEntreeDeTestPorteBienUnGPS() throws {
        #expect(aUnDictionnaireGPS(try jpegAvecGPS()))
    }

    @Test func lImageRendueParLaCameraNAPlusDeGPS() throws {
        let sortie = try #require(PriseCamera.jpegSansGPS(try jpegAvecGPS()))
        #expect(!aUnDictionnaireGPS(sortie))
    }

    @Test func desDonneesIllisiblesNeDonnentAucuneImage() {
        #expect(PriseCamera.imageSansGPS(Data([0, 1, 2])) == nil)
    }

    @Test func sansCameraLaVueDeCaptureNEstPasDisponible() {
        // Sur le simulateur il n'y a pas d'appareil arrière ; sur un iPhone, il y en a un. Le test dit seulement que les deux réponses coïncident.
        #expect(PriseCamera.disponible == PriseCapture.disponible)
    }
}
