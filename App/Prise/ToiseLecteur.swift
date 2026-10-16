import CoreGraphics
import Foundation
import UIKit
import Vision

/// Lit les chiffres de la toise avec `RecognizeTextRequest` (Vision, iOS 18 et plus).
/// Le bout de la queue n'est pas détecté : le pêcheur le touche sur la photo (aucune fonction de Vision inventée pour cela).
enum ToiseLecteur {
    /// `image` doit être déjà redressée (`UIImage.priseRedressee()`), pour que les coordonnées collent à ce que le pêcheur voit.
    static func calibrer(image: UIImage) async -> ToiseCalibrage? {
        guard let cg = image.cgImage else { return nil }
        var requete = RecognizeTextRequest()
        requete.recognitionLevel = .accurate
        requete.usesLanguageCorrection = false
        do {
            let observations = try await requete.perform(on: cg)
            let largeur = CGFloat(cg.width)
            let hauteur = CGFloat(cg.height)
            var textes: [TexteLu] = []
            for obs in observations {
                guard let meilleur = obs.topCandidates(1).first else { continue }
                // Vision : origine en bas à gauche, valeurs de 0 à 1. On passe en pixels, origine en haut à gauche.
                let n = obs.boundingBox.cgRect
                let rect = CGRect(x: n.minX * largeur, y: (1 - n.maxY) * hauteur, width: n.width * largeur, height: n.height * hauteur)
                textes.append(TexteLu(texte: meilleur.string, rect: rect))
            }
            return ToiseCalibrage.lire(textes, taille: CGSize(width: largeur, height: hauteur))
        } catch {
            return nil
        }
    }
}

extension UIImage {
    /// Une copie à l'endroit (orientation appliquée), sans métadonnées : pas de GPS.
    func priseRedressee() -> UIImage {
        if imageOrientation == .up { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let rendu = UIGraphicsImageRenderer(size: size, format: format)
        return rendu.image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }
}
