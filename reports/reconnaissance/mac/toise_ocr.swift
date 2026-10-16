// Lit les chiffres de 10 photos de toise avec Vision, comme ToiseLecteur dans l'app (RecognizeTextRequest, .accurate, sans correction).
// Usage : cp toise_ocr.swift /tmp/main.swift && swiftc -O /tmp/main.swift -o /tmp/toise_ocr && /tmp/toise_ocr toise10.csv > toise_ocr.json
// (lancé par « swift toise_ocr.swift », Vision plante : e5rtError 13)   (télécharge chaque image_url dans /tmp/toise/, n'envoie rien)
import Foundation
import Vision
import ImageIO

struct Texte: Codable { var texte: String; var x: Double; var y: Double; var w: Double; var h: Double; var confiance: Float }
struct Sortie: Codable { var n: String; var url: String; var largeur: Int; var hauteur: Int; var textes: [Texte] }

let lignes = try String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8).split(whereSeparator: \.isNewline).dropFirst()
try? FileManager.default.createDirectory(atPath: "/tmp/toise", withIntermediateDirectories: true)
var sorties: [Sortie] = []
for l in lignes {
    let c = l.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
    guard c.count > 1, let url = URL(string: c[1]) else { continue }
    let local = URL(fileURLWithPath: "/tmp/toise/\(c[0]).jpg")
    if !FileManager.default.fileExists(atPath: local.path) {
        guard let d = try? Data(contentsOf: url) else { FileHandle.standardError.write("échec \(c[0])\n".data(using: .utf8)!); continue }
        try d.write(to: local)
    }
    guard let src = CGImageSourceCreateWithURL(local as CFURL, nil),
          let img = CGImageSourceCreateImageAtIndex(src, 0, [kCGImageSourceShouldAllowFloat: false] as CFDictionary) else { continue }
    var req = RecognizeTextRequest()
    req.recognitionLevel = .accurate
    req.usesLanguageCorrection = false
    let obs = try await req.perform(on: img)
    let W = Double(img.width), H = Double(img.height)
    let t = obs.compactMap { o -> Texte? in
        guard let m = o.topCandidates(1).first else { return nil }
        let r = o.boundingBox.cgRect
        return Texte(texte: m.string, x: r.minX * W, y: (1 - r.maxY) * H, w: r.width * W, h: r.height * H, confiance: m.confidence)
    }
    sorties.append(Sortie(n: c[0], url: c[1], largeur: img.width, hauteur: img.height, textes: t))
}
let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
print(String(data: try enc.encode(sorties), encoding: .utf8)!)
