// Entraîne un classifieur Create ML sur createml/train et le note sur createml/test (même jeu de test que le cloud).
// Usage : swift entrainer.swift   (dans le dossier qui contient createml/)
import CreateML
import CoreML
import Vision
import Foundation

let racine = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("createml")
let train = racine.appendingPathComponent("train"), test = racine.appendingPathComponent("test")

var params = MLImageClassifier.ModelParameters()
params.featureExtractor = .scenePrint(revision: 2)
params.maxIterations = 100
params.augmentationOptions = [.flip, .crop, .exposure, .rotation]
let debut = Date()
let modele = try MLImageClassifier(trainingData: .labeledDirectories(at: train), parameters: params)
print("entraînement : \(Int(Date().timeIntervalSince(debut))) s")
let sortie = racine.appendingPathComponent("Poissons.mlmodel")
try modele.write(to: sortie)

// Notation top-1 / top-3 par espèce, avec Vision comme dans l'app
let compile = try MLModel.compileModel(at: sortie)
let vn = try VNCoreMLModel(for: MLModel(contentsOf: compile))
var src = ["aff": (0, 0, 0), "gbif": (0, 0, 0)]
var n = [String: Int](), t1 = [String: Int](), t3 = [String: Int](), conf = [String: [String: Int]]()
for classe in try FileManager.default.contentsOfDirectory(atPath: test.path) where !classe.hasPrefix(".") {
    let dossier = test.appendingPathComponent(classe)
    for f in try FileManager.default.contentsOfDirectory(atPath: dossier.path) where f.hasSuffix(".jpg") {
        let req = VNCoreMLRequest(model: vn); req.imageCropAndScaleOption = .scaleFit
        try VNImageRequestHandler(url: dossier.appendingPathComponent(f)).perform([req])
        let top = (req.results as? [VNClassificationObservation] ?? []).prefix(3).map(\.identifier)
        n[classe, default: 0] += 1
        if top.first == classe { t1[classe, default: 0] += 1 } else if let p = top.first { conf[classe, default: [:]][p, default: 0] += 1 }
        if top.contains(classe) { t3[classe, default: 0] += 1 }
        let k = f.hasPrefix("aff-") ? "aff" : "gbif"; var v = src[k]!
        v.0 += 1; if top.first == classe { v.1 += 1 }; if top.contains(classe) { v.2 += 1 }; src[k] = v
    }
}
let total = n.values.reduce(0, +)
print(String(format: "TOUT : %d photos de test, top-1 %.1f %%, top-3 %.1f %%", total,
             100 * Double(t1.values.reduce(0, +)) / Double(total), 100 * Double(t3.values.reduce(0, +)) / Double(total)))
for (k, v) in src where v.0 > 0 {
    print(String(format: "%@ : %d photos, top-1 %.1f %%, top-3 %.1f %%", k == "aff" ? "PRISES (AFFiNe)" : "TERRAIN (GBIF)", v.0, 100 * Double(v.1) / Double(v.0), 100 * Double(v.2) / Double(v.0)))
}
for c in n.keys.sorted() {
    let pire = (conf[c] ?? [:]).sorted { $0.value > $1.value }.prefix(2).map { "\($0.key) (\($0.value))" }.joined(separator: ", ")
    print(String(format: "%@ ; n=%d ; top-1 %.0f %% ; top-3 %.0f %% ; %@", c, n[c]!, 100 * Double(t1[c] ?? 0) / Double(n[c]!), 100 * Double(t3[c] ?? 0) / Double(n[c]!), pire))
}
