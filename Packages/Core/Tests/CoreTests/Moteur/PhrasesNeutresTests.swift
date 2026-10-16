import Foundation
import Testing
@testable import Core

@Suite("Phrases neutres (la loi, jamais une permission)")
struct PhrasesNeutresTests {
    @Test("Aisne (02) : taille minimale et mention du Code")
    func aisne() {
        #expect(PhrasesNeutres.neutre("En 2e catégorie, le sandre se garde à partir de 50 cm (le Code dit 40 cm).")
                == "En 2e catégorie, le sandre, taille minimale 50 cm (le Code dit 40 cm).")
        #expect(PhrasesNeutres.neutre("La truite fario se garde à partir de 25 cm (le Code dit 23 cm).")
                == "La truite fario, taille minimale 25 cm (le Code dit 23 cm).")
    }

    @Test("Moselle (57)")
    func moselle() {
        #expect(PhrasesNeutres.neutre("En 1re catégorie, le brochet se garde à partir de 50 cm.")
                == "En 1re catégorie, le brochet, taille minimale 50 cm.")
        #expect(PhrasesNeutres.neutre("En 2e catégorie, le black-bass se garde à partir de 30 cm.")
                == "En 2e catégorie, le black-bass, taille minimale 30 cm.")
    }

    @Test("Val-de-Marne (94) : la carpe non gardée la nuit garde son sens")
    func valDeMarne() {
        let p = "Carpe de nuit autorisée dans tous les cours d'eau du Val-de-Marne : 4 lignes, depuis la rive, carpe non gardée la nuit."
        #expect(PhrasesNeutres.neutre(p) == p)
    }

    @Test("Fenêtres de taille, quotas et formes en « gardée »")
    func formes() {
        #expect(PhrasesNeutres.neutre("Brochet : on ne garde que les brochets de 60 à 80 cm ; tout brochet de plus de 80 cm est remis à l'eau.")
                == "Brochet : taille encadrée : brochets de 60 à 80 cm seulement ; tout brochet de plus de 80 cm est remis à l'eau.")
        #expect(PhrasesNeutres.neutre("Sarre Blanche : truite fario gardée à partir de 20 cm.") == "Sarre Blanche : truite fario, taille minimale 20 cm.")
        #expect(PhrasesNeutres.neutre("Saint-Genou : brochet gardé seulement entre 60 et 80 cm.")
                == "Saint-Genou : brochet, taille encadrée : de 60 à 80 cm seulement.")
        #expect(PhrasesNeutres.neutre("Plan d'eau des Escoumes : 0 sandre à garder par jour.") == "Plan d'eau des Escoumes : quota 0 sandre par jour.")
        #expect(PhrasesNeutres.neutre("Brochet : 60 cm minimum pour le garder.") == "Brochet : taille minimale 60 cm.")
    }

    @Test("Les interdictions gardent leur sens, et la fonction est idempotente")
    func interdictions() {
        for p in ["En 2e catégorie, le black-bass ne se garde pas : remets-le à l'eau.",
                  "Sur toute la Bourbeuse, le brochet ne se garde jamais.",
                  "Une carpe prise ne peut être gardée en captivité ni transportée."] {
            #expect(PhrasesNeutres.neutre(p) == p)
        }
        let n = PhrasesNeutres.neutre("Le brochet se garde à partir de 60 cm.")
        #expect(PhrasesNeutres.neutre(n) == n)
    }

    @Test("Aucun fichier de règles n'affiche une permission de garder")
    func tousLesFichiers() throws {
        let dossier = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Core/Resources/regles")
        let fichiers = try FileManager.default.contentsOfDirectory(at: dossier, includingPropertiesForKeys: nil).filter { $0.pathExtension == "json" }
        #expect(fichiers.count > 50)
        var lues = 0
        for url in fichiers {
            guard let f = try? JSONDecoder().decode(FichierRegles.self, from: Data(contentsOf: url)) else { continue }
            for r in f.regles {
                lues += 1
                let p = r.phrase.lowercased()
                for interdit in ["tu peux la garder", "se garde à partir", "tu peux garder"] {
                    #expect(!p.contains(interdit), "\(url.lastPathComponent) \(r.id) : \(r.phrase)")
                }
            }
        }
        #expect(lues > 1000)
    }
}
