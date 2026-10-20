import Foundation
import Testing
@testable import WidgetAquariumLogique

@Suite("FondWidget et décor de l'instantané")
struct FondWidgetTests {
    private let encodeur: JSONEncoder = .aquarium
    private let decodeur: JSONDecoder = .aquarium

    @Test func ancienFichierSansSkinSeLitEtDonneRiviere() throws {
        let json = #"{"poissons":[],"especes":2,"rations":1,"estPro":true,"misAJour":"2026-10-20T10:00:00Z"}"#
        let lu = try decodeur.decode(InstantaneAquarium.self, from: Data(json.utf8))
        #expect(lu.skin == nil)
        #expect(lu.skinEffectif == "riviere")
        #expect(lu.especes == 2)
    }

    @Test func skinSeRelitApresEcriture() throws {
        let s = InstantaneAquarium(poissons: [], especes: 0, rations: 0, estPro: true, skin: "halloween")
        let relu = try decodeur.decode(InstantaneAquarium.self, from: try encodeur.encode(s))
        #expect(relu.skin == "halloween")
        #expect(relu.skinEffectif == "halloween")
    }

    @Test func nomsParDecorEtFormat() {
        #expect(FondWidget.nomVoulu(skin: "halloween", format: .petit) == "fond-halloween-petit")
        #expect(FondWidget.nomVoulu(skin: "ouverture-truite", format: .grand) == "fond-ouverture-truite-grand")
        #expect(FondWidget.nomVoulu(skin: "riviere", format: .moyen) == "fond-moyen")
        #expect(FondWidget.nomVoulu(skin: nil, format: .moyen) == "fond-moyen")
    }

    @Test func imageDuSkinAbsenteRepliSurLeFondParDefaut() {
        for f in FondWidget.Format.allCases {
            #expect(FondWidget.nomImage(skin: "noel", format: f, existe: { _ in false }) == "fond-\(f.rawValue)")
            #expect(FondWidget.nomImage(skin: "noel", format: f, existe: { $0 == "fond-noel-\(f.rawValue)" })
                    == "fond-noel-\(f.rawValue)")
        }
    }

    @Test func identifiantDouteuxDonneLeFondParDefaut() {
        for brut in ["", "   ", "../x", "Noel", "a b", String(repeating: "a", count: 80)] {
            #expect(FondWidget.nomVoulu(skin: brut, format: .grand) == "fond-grand")
        }
    }

    // MARK: Le dessin des décors (le widget dessine le même décor que l'aquarium)

    private let dessines = ["sous-bois", "etang", "grotte", "halloween", "noel", "ouverture-truite"]

    @Test func chaqueDecorDessineChoisitLeDessinQuandIlNyAPasDImage() {
        for id in dessines {
            for f in FondWidget.Format.allCases {
                #expect(FondWidget.source(skin: id, format: f, existe: { _ in false }) == .dessin(id))
            }
        }
    }

    @Test func uneIllustrationDuDecorResteLaPremiere() {
        for id in dessines {
            for f in FondWidget.Format.allCases {
                let nom = "fond-\(id)-\(f.rawValue)"
                #expect(FondWidget.source(skin: id, format: f, existe: { $0 == nom }) == .image(nom))
            }
        }
    }

    @Test func eteNAPasDeDessinEtRepliSurLeFondDOrigine() {
        for id in ["ete"] {
            #expect(!FondWidget.aUnDessin(id))
            for f in FondWidget.Format.allCases {
                #expect(FondWidget.source(skin: id, format: f, existe: { _ in false }) == .repli("fond-\(f.rawValue)"))
            }
        }
    }

    @Test func leDecorDeDepartEtLesIdentifiantsDouteuxNeDessinentRien() {
        for brut in [nil, "", "riviere", "../x", "Etang", "inconnu-d-une-version-future"] as [String?] {
            #expect(!FondWidget.aUnDessin(brut))
            #expect(FondWidget.source(skin: brut, format: .moyen, existe: { _ in false }) == .repli("fond-moyen"))
        }
        // Même si une image `fond-riviere-…` existait, le décor de départ garde le fond d'origine.
        #expect(FondWidget.source(skin: "riviere", format: .grand, existe: { _ in true }) == .repli("fond-grand"))
    }

    @Test func lEnsembleDesDecorsDessinesEstCelDeLaListe() {
        #expect(FondWidget.decorsDessines == Set(dessines))
        for id in dessines { #expect(FondWidget.aUnDessin(id)) }
    }
}
