// NON EXÉCUTÉ (nécessite macOS 27 avec Apple Intelligence activé en français ; API image à confirmer à la compilation).
// Usage : swift apple_ia.swift <jeu-prepare>/test <classes.json> <liste.csv> <journal-apple.csv>
//   liste.csv : une clé par ligne, "<classe>/<fichier>" (sortie de `comparer.py choisir`, 20 photos)
//   classes.json : classes gardées du modèle Create ML (sortie de entrainer.swift)
// Même journal que Create ML (fichier,vraie,p1,p2,p3) : python3 -I comparer.py compare ...
// Affiche contextSize : 4096 = modèle des iPhone 15 Pro/16 ; 8192 = score valable pour iPhone 17 Pro seulement.
import FoundationModels
import Foundation

let a = CommandLine.arguments
guard a.count == 5 else { print("Usage : swift apple_ia.swift <dossier-test> <classes.json> <liste.csv> <journal.csv>"); exit(2) }
let dossier = URL(fileURLWithPath: a[1])
let classes = try JSONDecoder().decode([String].self, from: Data(contentsOf: URL(fileURLWithPath: a[2]))).filter { $0 != "autre" }
let cles = try String(contentsOfFile: a[3], encoding: .utf8).split(separator: "\n").map(String.init).filter { $0 != "fichier" }

@Generable
struct Propositions {
    @Guide(description: "Les 3 identifiants d'espèce les plus probables, du plus au moins probable, choisis dans la liste fournie ; 'autre' si ce n'est pas un de ces poissons")
    var especes: [String]
}

let modele = SystemLanguageModel.default
guard case .available = modele.availability else { print("Apple Intelligence indisponible : non noté"); exit(1) }
print("contextSize : \(modele.contextSize)")

var lignes = ["fichier,vraie,p1,p2,p3"]
for cle in cles {
    let vraie = String(cle.split(separator: "/").first ?? "autre")
    let session = LanguageModelSession(instructions: "Tu identifies un poisson d'eau douce sur une photo. Identifiants permis : \(classes.joined(separator: ", ")), autre.")
    // TODO à confirmer à la compilation : forme exacte du prompt multimodal (image) dans Foundation Models, iOS/macOS 27.
    let image = dossier.appendingPathComponent(cle)
    let reponse = try await session.respond(to: Prompt { "Quelle espèce ? Photo jointe." ; image }, generating: Propositions.self, options: GenerationOptions(sampling: .greedy))
    var p = reponse.content.especes.map { classes.contains($0) ? $0 : "autre" }
    p = Array((p + ["-", "-", "-"]).prefix(3))
    lignes.append("\(cle),\(vraie),\(p[0]),\(p[1]),\(p[2])")
}
try lignes.joined(separator: "\n").appending("\n").write(toFile: a[4], atomically: true, encoding: .utf8)
print("journal Apple écrit : \(a[4])")
