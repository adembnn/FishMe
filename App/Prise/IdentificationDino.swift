import Core
import CoreImage
import CoreML
import Foundation
import ImageIO
import Vision

/// Reconnaissance sur l'appareil : PoissonsDino (DINOv2-small + régression logistique, int8), hors ligne.
/// Chaîne vérifiée : photo entière (orientation EXIF appliquée) → carré à bord neutre → `VNCoreMLRequest` en `scaleFit`.
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
        if horsExamen.contains(e) { return nil }
        if let c = correspondances[e] { return c }
        if sansEquivalent.contains(e) { return nil }
        return e.replacingOccurrences(of: "-", with: "_")
    }

    static let sansEquivalent: Set<String> = ["autre-poisson", "pas-un-poisson", "gambusie"]

    /// Classes recalées à l'examen du modèle v2 (bonne espèce dans les 3 propositions moins de 80 % du temps,
    /// `reports/reconnaissance/examen-v2.md`) : jamais proposées, la grille s'ouvre à la place.
    static let horsExamen: Set<String> = ["chabot", "grande-alose", "mulet", "omble-chevalier"]

    /// Les étiquettes dont la classe n'est pas simplement l'étiquette avec des `_`.
    static let correspondances: [String: String] = [
        "able-heckel": "ablette", "breme-commune": "breme", "carassin-argente": "carassin",
        "carassin-commun": "carassin", "carpe-amour": "amour_blanc", "carpe-commune": "carpe",
        "coregones": "coregone", "hotu": "hotu_toxostome", "lamproie-planer": "lamproie",
        "loche-franche": "loche", "loche-riviere": "loche", "omble-fontaine": "omble_de_fontaine",
        "ombre": "ombre_commun", "saumon": "saumon_atlantique",
        // Modèle v2 (55 classes) : grande alose et lamproie fluviatile partagent la classe de leurs sosies.
        "grande-alose": "alose", "lamproie-fluviatile": "lamproie",
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
        #if targetEnvironment(simulator)
        config.computeUnits = .cpuOnly // le simulateur n'a pas le moteur MPSGraph
        #else
        config.computeUnits = .all
        #endif
        guard let ml = try? MLModel(contentsOf: url, configuration: config) else { return nil }
        modele = try? VNCoreMLModel(for: ml)
        return modele
    }

    func classer(photo: Data) -> SortieDino {
        guard let vnModele = chargerModele() else { return .indisponible }
        guard let image = Self.decoder(photo, cote: 1280) else { return .echec }
        // Photo entière, sans masque : c'est ce qui a été vérifié (86 % sur 1 851 prises). Le masque de premier plan
        // Vision recadrait sur autre chose que le poisson (le pêcheur, un morceau) et faussait la réponse.
        guard let carre = Self.carre(image, zone: CGRect(x: 0, y: 0, width: image.width, height: image.height)) else { return .echec }
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
