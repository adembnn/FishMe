// NON EXÉCUTÉ (écrit sans Mac, à lancer sur un Mac : macOS 14 ou plus, Xcode installé).
// Usage : swift entrainer.swift <jeu-prepare> <sortie> [maxIterations]
//   <jeu-prepare> contient train/<classe>/*.jpg, val/<classe>/*.jpg, test/<classe>/*.jpg (voir preparer_jeu.py)
// Sorties dans <sortie> : Poissons.mlmodel, journal-createml.csv (fichier,vraie,p1,p2,p3), classes.json
// Le journal se note avec : python3 -I examen.py --journal journal-createml.csv --modele Poissons.mlmodel
import CreateML
import CoreML
import Vision
import Foundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("Usage : swift entrainer.swift <jeu-prepare> <sortie> [maxIterations]")
    exit(2)
}
let racine = URL(fileURLWithPath: args[1])
let sortie = URL(fileURLWithPath: args[2])
let iterations = args.count > 3 ? Int(args[3]) ?? 25 : 25
try FileManager.default.createDirectory(at: sortie, withIntermediateDirectories: true)

// 1. Entraînement : extracteur d'Apple (ScenePrint) + augmentations ; validation = lot val (jamais le test).
let params = MLImageClassifier.ModelParameters(
    featureExtractor: .scenePrint(revision: 2),
    validation: .dataSource(.labeledDirectories(at: racine.appendingPathComponent("val"))),
    maxIterations: iterations,
    augmentation: [.crop, .rotation, .exposure, .blur, .noise, .flip]
)
let classifieur = try MLImageClassifier(
    trainingData: .labeledDirectories(at: racine.appendingPathComponent("train")),
    parameters: params)
let modeleURL = sortie.appendingPathComponent("Poissons.mlmodel")
try classifieur.write(to: modeleURL, metadata: MLModelMetadata(author: "FishMe R1", shortDescription: "Espèces de poissons d'eau douce de France", version: "1"))
print("modèle écrit : \(modeleURL.path)")

// 2. Journal sur le lot test : 3 meilleures propositions par photo, via Vision (comme dans l'app).
let compile = try MLModel.compileModel(at: modeleURL)
let vn = try VNCoreMLModel(for: try MLModel(contentsOf: compile))
let test = racine.appendingPathComponent("test")
let fm = FileManager.default
var lignes = ["fichier,vraie,p1,p2,p3"]
var classes = Set<String>()
for classe in try fm.contentsOfDirectory(atPath: test.path).sorted() where !classe.hasPrefix(".") {
    classes.insert(classe)
    for nom in try fm.contentsOfDirectory(atPath: test.appendingPathComponent(classe).path).sorted() where !nom.hasPrefix(".") {
        let url = test.appendingPathComponent(classe).appendingPathComponent(nom)
        let requete = VNCoreMLRequest(model: vn)
        requete.imageCropAndScaleOption = .centerCrop
        try VNImageRequestHandler(url: url).perform([requete])
        let top = (requete.results as? [VNClassificationObservation] ?? [])
            .sorted { $0.confidence > $1.confidence }.prefix(3).map { $0.identifier }
        let p = top + Array(repeating: "-", count: max(0, 3 - top.count))
        lignes.append("\(classe)/\(nom),\(classe),\(p[0]),\(p[1]),\(p[2])")
    }
}
try lignes.joined(separator: "\n").appending("\n").write(to: sortie.appendingPathComponent("journal-createml.csv"), atomically: true, encoding: .utf8)
let json = try JSONSerialization.data(withJSONObject: classes.sorted(), options: [.prettyPrinted])
try json.write(to: sortie.appendingPathComponent("classes.json"))
print("journal écrit (\(lignes.count - 1) photos de test). Suite : python3 -I examen.py --journal \(sortie.path)/journal-createml.csv --modele \(modeleURL.path)")
