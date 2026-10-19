import Core
import Foundation
import SwiftUI
import Testing
import UIKit
@testable import BuildChallenge

/// Critères 19 à 21 de la fiche N4. ⚠ à vérifier : écrits sans compilateur Swift, non exécutés ; à juger par S sur Mac.
@MainActor
struct RecordsVuesTests {
    private let brochet = Espece(id: "brochet")

    private func prise(_ espece: Espece, _ cm: Double?, jour: Int = 1) -> Prise {
        Prise(espece: espece, longueurCm: cm, mesure: .saisie, date: Date(timeIntervalSince1970: 1_790_000_000 + Double(jour) * 86_400),
              lieuFlou: "La Marne · 94")
    }

    private func modele(_ cartes: [Prise]) -> ModeleRecords {
        let defauts = UserDefaults(suiteName: "records.tests.\(UUID().uuidString)")
        return ModeleRecords(cartes: cartes, sorties: [], especes: [], seuilTropheeCm: { _ in nil }, defauts: defauts)
    }

    private func affiche<V: View>(_ vue: V) {
        let hote = UIHostingController(rootView: NavigationStack { vue })
        hote.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        hote.view.layoutIfNeeded()
        #expect(hote.view.bounds.width == 390)
    }

    // MARK: 19. La vue s'affiche

    @Test func vueSansRecord() { affiche(MesRecordsView(modele: modele([]))) }

    @Test func vueAvecUnRecord() { affiche(MesRecordsView(modele: modele([prise(brochet, 62)]))) }

    @Test func vueAvecTrenteRecords() {
        let cartes = (0..<30).map { prise(Espece(id: "espece-\($0)"), Double(20 + $0), jour: $0) }
        let m = modele(cartes)
        #expect(m.bilan.records.count == 30)
        affiche(MesRecordsView(modele: m))
    }

    @Test func compteursAZeroEtPhraseSansPrise() {
        let m = modele([])
        #expect(m.bilan.compteurs == CompteursPersonnels())
        #expect(m.estVide)
        #expect(TextesRecords.phraseVide == "Tes souvenirs de pêche se rangeront ici.")
    }

    @Test func rubanNouveauSeulementApresLaPremiereOuverture() {
        let defauts = UserDefaults(suiteName: "records.tests.\(UUID().uuidString)")
        let premiere = ModeleRecords(cartes: [prise(brochet, 60)], sorties: [], especes: [], seuilTropheeCm: { _ in nil }, defauts: defauts)
        #expect(premiere.nouveaux.isEmpty)
        let plusGrand = ModeleRecords(cartes: [prise(brochet, 60), prise(brochet, 72, jour: 2)], sorties: [], especes: [],
                                      seuilTropheeCm: { _ in nil }, defauts: defauts)
        #expect(plusGrand.nouveaux == ["brochet"])
        plusGrand.marquerVus()
        #expect(plusGrand.nouveaux.isEmpty)
    }

    // MARK: 20. Le bandeau

    @Test func bandeauMuetSauNouveauSouvenir() {
        #expect(TextesRecords.bandeau(.aucun, nomEspece: "Brochet") == nil)
        #expect(TextesRecords.bandeau(.premiereTaille, nomEspece: "Brochet") == nil)
        #expect(TextesRecords.bandeau(.nouveauSouvenir(ancienCm: 60, nouveauCm: 78), nomEspece: "Brochet")
                == "Ton plus grand brochet jusqu'ici : 78 cm. Joli souvenir.")
    }

    @Test func bandeauDureQuatreSecondes() {
        #expect(TextesRecords.dureeBandeau == .seconds(4))
    }

    @Test func bandeauSAffiche() {
        affiche(BandeauRecordView(evenement: .nouveauSouvenir(ancienCm: 60, nouveauCm: 72), nomEspece: "Brochet", duree: .milliseconds(50)))
        affiche(BandeauRecordView(evenement: .aucun, nomEspece: "Brochet"))
        affiche(BandeauRecordView(evenement: .premiereTaille, nomEspece: "Brochet"))
    }

    @Test func textesDeLaCarte() {
        let r = RecordEspece(espece: brochet, priseID: UUID(), longueurCm: 72.5, mesure: .estimee,
                             date: Date(timeIntervalSince1970: 1_790_000_000), lieuFlou: "La Marne · 94", nombreDePrises: 2, estTrophee: true)
        #expect(TextesRecords.longueur(72.5) == "72,5 cm")
        #expect(TextesRecords.longueur(78) == "78 cm")
        #expect(TextesRecords.lieu("La Marne · 94") == "La Marne")
        let voix = TextesRecords.phraseVoixOff(r, nom: "Brochet")
        #expect(voix.contains("72,5 centimètres"))
        #expect(voix.hasSuffix("trophée"))
    }

    // MARK: 21. Les mots interdits

    private static var racine: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    private func fichiersSwift(_ chemin: String) -> [URL] {
        let dossier = Self.racine.appendingPathComponent(chemin)
        guard let it = FileManager.default.enumerator(at: dossier, includingPropertiesForKeys: nil) else { return [] }
        return it.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
    }

    @Test func aucunMotInterdit() throws {
        let motifs = try NSRegularExpression(pattern: "\\bxp\\b|score|classement|défi|récompense|meilleur|battu|\\bbats\\b",
                                             options: [.caseInsensitive])
        let fichiers = fichiersSwift("App/Records") + fichiersSwift("Packages/Core/Sources/Core/Records")
        #expect(!fichiers.isEmpty)
        for f in fichiers {
            let texte = try String(contentsOf: f, encoding: .utf8)
            let trouve = motifs.firstMatch(in: texte, range: NSRange(texte.startIndex..., in: texte))
            #expect(trouve == nil, "mot interdit dans \(f.lastPathComponent)")
        }
    }

    @Test func aucunLienAvecLeProfilNiLeVerrou() throws {
        let motifs = try NSRegularExpression(pattern: "BadgeProfil|autorise|paywall")
        for f in fichiersSwift("App/Records") {
            let texte = try String(contentsOf: f, encoding: .utf8)
            #expect(motifs.firstMatch(in: texte, range: NSRange(texte.startIndex..., in: texte)) == nil, "\(f.lastPathComponent)")
        }
    }
}
