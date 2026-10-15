import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import BuildChallenge

struct ClubTests {
    private func jpegAvecGPS() throws -> Data {
        let contexte = try #require(CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8, bytesPerRow: 0,
                                              space: CGColorSpaceCreateDeviceRGB(),
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        contexte.setFillColor(red: 0, green: 0.4, blue: 0.8, alpha: 1)
        contexte.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        let image = try #require(contexte.makeImage())
        let sortie = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(sortie, UTType.jpeg.identifier as CFString, 1, nil))
        let gps: [CFString: Any] = [kCGImagePropertyGPSLatitude: 48.82, kCGImagePropertyGPSLatitudeRef: "N",
                                    kCGImagePropertyGPSLongitude: 2.41, kCGImagePropertyGPSLongitudeRef: "E"]
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyGPSDictionary: gps] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return sortie as Data
    }

    @Test func lImagePartageeNaAucuneCleGPS() throws {
        let originale = try jpegAvecGPS()
        #expect(ImageSansGPS.contientGPS(originale))
        let partagee = try ImageSansGPS.nettoyer(originale)
        #expect(!ImageSansGPS.contientGPS(partagee))
        let source = try #require(CGImageSourceCreateWithData(partagee as CFData, nil))
        let proprietes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
        #expect(proprietes[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test func leContactEstUneVraieAdresse() {
        #expect(!ContactClub.adresse.isEmpty, "Adresse de contact à fournir par Adem ou MWM (CLAUDE.md), jamais inventée")
        #expect(ContactClub.adresse.contains("@"))
    }

    @Test func leSignalementDitErreurDeRegleSansCoordonnee() throws {
        guard !ContactClub.adresse.isEmpty else { return }
        let lien = try #require(ContactClub.erreurDeRegle)
        let composants = try #require(URLComponents(url: lien, resolvingAgainstBaseURL: false))
        #expect(composants.scheme == "mailto")
        #expect(composants.queryItems?.first { $0.name == "subject" }?.value == "Erreur de règle")
        #expect(composants.queryItems?.contains { $0.name == "body" } != true)
    }

    @Test func lesLiensDeSecuriteSontOfficiels() {
        #expect(LiensOfficiels.vigilanceMeteoFrance.host == "vigilance.meteofrance.fr")
        #expect(LiensOfficiels.vigicrues.host == "www.vigicrues.gouv.fr")
        #expect(LiensOfficiels.carteDePeche.host == "www.cartedepeche.fr")
    }
}
