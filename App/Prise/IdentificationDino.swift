import Core
import CoreImage
import CoreML
import Foundation
import ImageIO
import Vision

/// Reconnaissance sur l'appareil : PoissonsDino (DINOv2-small + régression logistique, int8), hors ligne.
/// Chaîne : masque de premier plan Vision → recadrage carré à bord neutre → `VNCoreMLRequest` en `scaleFit`.
/// Rend des scores par classe de `especes.json` (`classe_modele`), ou la grille quand le modèle n'est pas sûr.
nonisolated struct IdentificationDino: IdentifieEspece {
    /// Sous ce score de la meilleure étiquette, la grille s'ouvre.
    var seuil: Double = 0.4
    private let moteur: MoteurDino

    init(seuil: Double = 0.4, bundle: Bundle = .main) {
        self.seuil = seuil
        self.moteur = MoteurDino.partage(bundle: bundle)
    }

    func identifier(photo: Data) async -> ResultatIdentification {
        switch await moteur.classer(photo: photo) {
        case .indisponible: return .grille(raison: .aucunModele)
        case .echec: return .grille(raison: .erreur)
        case .etiquettes(let brut):
            guard let meilleur = brut.max(by: { $0.value < $1.value }),
                  meilleur.value >= seuil,
                  Self.classe(deEtiquette: meilleur.key) != nil else { return .grille(raison: .modeleSousLeSeuil) }
            var scores: [String: Double] = [:]
            for (etiquette, p) in brut {
                if let classe = Self.classe(deEtiquette: etiquette) { scores[classe, default: 0] += p }
            }
            return .scores(scores)
        }
    }

    /// Étiquette du modèle (labels.txt) → `classe_modele` de especes.json. nil : pas d'espèce correspondante
    /// (`autre-poisson`, `pas-un-poisson`, `gambusie` dont la classe est `autre_poisson`, que Core écarte).
    static func classe(deEtiquette e: String) -> String? {
        if let c = correspondances[e] { return c }
        if sansEquivalent.contains(e) { return nil }
        return e.replacingOccurrences(of: "-", with: "_")
    }

    static let sansEquivalent: Set<String> = ["autre-poisson", "pas-un-poisson", "gambusie"]

    /// Les étiquettes dont la classe n'est pas simplement l'étiquette avec des `_`.
    static let correspondances: [String: String] = [
        "able-heckel": "ablette", "breme-commune": "breme", "carassin-argente": "carassin",
        "carassin-commun": "carassin", "carpe-amour": "amour_blanc", "carpe-commune": "carpe",
        "coregones": "coregone", "hotu": "hotu_toxostome", "lamproie-planer": "lamproie",
        "loche-franche": "loche", "loche-riviere": "loche", "omble-fontaine": "omble_de_fontaine",
        "ombre": "ombre_commun", "saumon": "saumon_atlantique",
    ]
}

enum SortieDino: Sendable {
    case indisponible
    case echec
    case etiquettes([String: Double])
}

/// Porte le modèle chargé et fait tourner Vision hors du thread principal.
actor MoteurDino {
    private static let nom = "PoissonsDino-int8"
    private let bundle: Bundle
    private var modele: VNCoreMLModel?
    private var charge = false

    private init(bundle: Bundle) { self.bundle = bundle }

    private static let cache = Cache()
    private final class Cache: @unchecked Sendable {
        private let verrou = NSLock()
        private var moteurs: [URL: MoteurDino] = [:]
        func moteur(bundle: Bundle) -> MoteurDino {
            verrou.lock(); defer { verrou.unlock() }
            if let m = moteurs[bundle.bundleURL] { return m }
            let m = MoteurDino(bundle: bundle)
            moteurs[bundle.bundleURL] = m
            return m
        }
    }

    static func partage(bundle: Bundle) -> MoteurDino { cache.moteur(bundle: bundle) }

    private func chargerModele() -> VNCoreMLModel? {
        if charge { return modele }
        charge = true
        guard let url = bundle.url(forResource: Self.nom, withExtension: "mlmodelc") else { return nil }
        let config = MLModelConfiguration()
        config.computeUnits = .all
        guard let ml = try? MLModel(contentsOf: url, configuration: config) else { return nil }
        modele = try? VNCoreMLModel(for: ml)
        return modele
    }

    func classer(photo: Data) -> SortieDino {
        guard let vnModele = chargerModele() else { return .indisponible }
        guard let image = Self.decoder(photo, cote: 1280) else { return .echec }
        let carre = Self.recadrerSurLePoisson(image) ?? Self.carre(image, zone: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let carre else { return .echec }
        let requete = VNCoreMLRequest(model: vnModele)
        requete.imageCropAndScaleOption = .scaleFit
        do {
            try VNImageRequestHandler(cgImage: carre, options: [:]).perform([requete])
        } catch { return .echec }
        guard let obs = requete.results as? [VNClassificationObservation], !obs.isEmpty else { return .echec }
        var sortie: [String: Double] = [:]
        for o in obs { sortie[o.identifier] = Double(o.confidence) }
        return .etiquettes(sortie)
    }

    // MARK: Image

    /// Décode en appliquant l'orientation EXIF, côté long limité à `cote`.
    private static func decoder(_ data: Data, cote: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: cote,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    /// Boîte du premier plan (masque Vision), un peu élargie, puis carré à bord neutre. nil si Vision ne trouve rien.
    private static func recadrerSurLePoisson(_ image: CGImage) -> CGImage? {
        let requete = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        guard (try? handler.perform([requete])) != nil,
              let resultat = requete.results?.first,
              let masque = try? resultat.generateScaledMaskForImage(forInstances: resultat.allInstances, from: handler),
              let boite = boiteDuMasque(masque, largeur: image.width, hauteur: image.height) else { return nil }
        let marge = 0.06 * Double(max(boite.width, boite.height))
        let zone = boite.insetBy(dx: -marge, dy: -marge)
            .intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard zone.width > 8, zone.height > 8 else { return nil }
        return carre(image, zone: zone)
    }

    /// Boîte englobante des pixels du masque (origine en haut à gauche).
    private static func boiteDuMasque(_ masque: CVPixelBuffer, largeur: Int, hauteur: Int) -> CGRect? {
        CVPixelBufferLockBaseAddress(masque, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(masque, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(masque) else { return nil }
        let w = CVPixelBufferGetWidth(masque), h = CVPixelBufferGetHeight(masque)
        let ligne = CVPixelBufferGetBytesPerRow(masque)
        let format = CVPixelBufferGetPixelFormatType(masque)
        func actif(_ x: Int, _ y: Int) -> Bool {
            let rang = base.advanced(by: y * ligne)
            if format == kCVPixelFormatType_OneComponent32Float {
                return rang.assumingMemoryBound(to: Float.self)[x] > 0.5
            }
            return rang.assumingMemoryBound(to: UInt8.self)[x] > 127
        }
        let pas = max(1, max(w, h) / 320)
        var minX = w, minY = h, maxX = -1, maxY = -1
        for y in stride(from: 0, to: h, by: pas) {
            for x in stride(from: 0, to: w, by: pas) where actif(x, y) {
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        let ex = Double(largeur) / Double(w), ey = Double(hauteur) / Double(h)
        return CGRect(x: Double(minX) * ex, y: Double(minY) * ey,
                      width: Double(maxX - minX + pas) * ex, height: Double(maxY - minY + pas) * ey)
    }

    /// Recadre `zone`, la pose au centre d'un carré rempli de la couleur neutre de l'entraînement (124,116,104).
    private static func carre(_ image: CGImage, zone: CGRect) -> CGImage? {
        guard let morceau = image.cropping(to: zone.integral) else { return nil }
        let cote = max(morceau.width, morceau.height)
        guard let ctx = CGContext(data: nil, width: cote, height: cote, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        ctx.setFillColor(red: 124.0 / 255, green: 116.0 / 255, blue: 104.0 / 255, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: cote, height: cote))
        ctx.draw(morceau, in: CGRect(x: (cote - morceau.width) / 2, y: (cote - morceau.height) / 2,
                                     width: morceau.width, height: morceau.height))
        return ctx.makeImage()
    }
}
