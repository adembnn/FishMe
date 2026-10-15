// Recadre chaque photo de brut/<train|test>/<classe>/ sur le sujet détecté par Apple Vision
// (détourage du premier plan, le même que sur l'iPhone) et l'écrit dans createml/<train|test>/<classe>/.
// Usage : swift recadrer_vision.swift   (depuis ~/FishMe-reco)
import Foundation
import Vision
import CoreImage
import ImageIO
import UniformTypeIdentifiers

let fm = FileManager.default
let ici = URL(fileURLWithPath: fm.currentDirectoryPath)
let brut = ici.appendingPathComponent("brut"), sortie = ici.appendingPathComponent("createml")
let ctx = CIContext()
var faites = 0, sansSujet = 0

func recadrer(_ src: URL, vers dst: URL) {
    guard let ci = CIImage(contentsOf: src, options: [.applyOrientationProperty: true]) else { return }
    let req = VNGenerateForegroundInstanceMaskRequest()
    let h = VNImageRequestHandler(ciImage: ci)
    var boite = ci.extent
    if (try? h.perform([req])) != nil, let obs = req.results?.first, !obs.allInstances.isEmpty,
       let masque = try? obs.generateScaledMaskForImage(forInstances: obs.allInstances, from: h) {
        // boîte englobante du masque
        let m = CIImage(cvPixelBuffer: masque)
        let w = CVPixelBufferGetWidth(masque), hh = CVPixelBufferGetHeight(masque)
        CVPixelBufferLockBaseAddress(masque, .readOnly)
        let base = CVPixelBufferGetBaseAddress(masque)!.assumingMemoryBound(to: Float32.self)
        let pas = CVPixelBufferGetBytesPerRow(masque) / 4
        var x0 = w, y0 = hh, x1 = 0, y1 = 0
        for y in stride(from: 0, to: hh, by: 2) { for x in stride(from: 0, to: w, by: 2) where base[y * pas + x] > 0.5 {
            x0 = min(x0, x); x1 = max(x1, x); y0 = min(y0, y); y1 = max(y1, y) } }
        CVPixelBufferUnlockBaseAddress(masque, .readOnly)
        _ = m
        if x1 > x0 && y1 > y0 {
            let mx = Double(x1 - x0) * 0.06, my = Double(y1 - y0) * 0.08
            // le tampon a son origine en haut à gauche, CIImage en bas à gauche
            let r = CGRect(x: Double(x0) - mx, y: Double(hh - y1) - my, width: Double(x1 - x0) + 2 * mx, height: Double(y1 - y0) + 2 * my)
            boite = r.intersection(ci.extent)
        } else { sansSujet += 1 }
    } else { sansSujet += 1 }
    let c = ci.cropped(to: boite)
    let s = min(1.0, 448.0 / max(c.extent.width, c.extent.height))
    let fin = c.transformed(by: CGAffineTransform(scaleX: s, y: s))
    try? fm.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
    // JPEG réencodé sans métadonnées : aucun EXIF, aucun GPS
    try? ctx.writeJPEGRepresentation(of: fin, to: dst, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.88])
    faites += 1
    if faites % 500 == 0 { print("\(faites) photos (\(sansSujet) sans sujet détecté)") }
}

let e = fm.enumerator(at: brut, includingPropertiesForKeys: nil)!
for case let u as URL in e where u.pathExtension.lowercased() == "jpg" {
    let rel = u.path.replacingOccurrences(of: brut.path + "/", with: "")
    let dst = sortie.appendingPathComponent(rel)
    if fm.fileExists(atPath: dst.path) { continue }
    autoreleasepool { recadrer(u, vers: dst) }
}
print("fini : \(faites) photos, \(sansSujet) sans sujet détecté (photo gardée entière)")
