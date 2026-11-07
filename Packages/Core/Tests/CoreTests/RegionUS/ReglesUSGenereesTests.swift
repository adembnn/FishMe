import Foundation
import Testing
@testable import Core

// Fichiers réels générés par outils/us/format/vers_regles_us.py à partir de la double lecture (lot us-consensus, 7 nov. 2026).
// Le dossier n'est pas encore déclaré dans Package.swift : on le lit dans le dépôt, à côté de ce fichier.
private let dossierReglesUS = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("../Sources/Core/Resources/regles-us").standardized

@Suite("Région US : règles réelles confirmées par double lecture (WI, MN)")
struct ReglesUSGenereesTests {
    private func moteur() throws -> (ContenuReglesUS, MoteurUS) {
        let contenu = ChargementReglesUS(source: SourceDossier(dossier: dossierReglesUS)).tout()
        return (contenu, try contenu.moteur())
    }

    @Test("WI et MN se chargent avec le chargeur de production, sommes sha256 de l'index comprises ; tout est « double lecture »")
    func chargement() throws {
        let (contenu, _) = try moteur()
        #expect(contenu.erreurs.isEmpty)
        let codes = Set(contenu.etats.map(\.code.rawValue))
        #expect(codes.isSuperset(of: ["WI", "MN"]))
        let index = try ChargementReglesUS(source: SourceDossier(dossier: dossierReglesUS)).index()
        for etat in contenu.etats {
            #expect(index.etats[etat.code]?.nombreRegles == etat.regles.count)
            #expect(!etat.regles.isEmpty)
            #expect(etat.regles.allSatisfy { $0.statut == .doubleLectureConfirmee && $0.source.url.scheme == "https" })
        }
    }

    @Test("Muskellunge au Minnesota (taille minimale 54 pouces, confirmée par A et B) : 40 pouces mesurés → interdit ; 54 pile → à vérifier")
    func muskieMinnesota() throws {
        let (_, m) = try moteur()
        let mn = usId("US-MN")
        let jour = usJour(2026, 11, 20)  // dans la saison lue (6 juin - 30 nov.), après la lecture du 7 nov.
        let sous = m.evaluer(QuestionUS(espece: "muskellunge", juridiction: mn, jour: jour, taille: .pouces(40)))
        #expect(sous.verdict == .interdit)
        #expect(sous.motifs.contains { if case .sousTailleMinimale = $0 { true } else { false } })
        #expect(sous.sources.allSatisfy { $0.url.host == "files.dnr.state.mn.us" })
        let limite = m.evaluer(QuestionUS(espece: "muskellunge", juridiction: mn, jour: jour, taille: .pouces(54)))
        #expect(limite.verdict == .aVerifier)
        #expect(limite.motifs.contains { if case .tailleALaLimite = $0 { true } else { false } })
        // Une taille estimée sur photo ne suffit jamais à dire « interdit ».
        let estimee = m.evaluer(QuestionUS(espece: "muskellunge", juridiction: mn, jour: jour, taille: .pouces(40), tailleEstimee: true))
        #expect(estimee.verdict == .aVerifier)
    }

    @Test("Brochet du Wisconsin, zone sud (26 pouces minimum) : 20 pouces → interdit ; dans l'État sans zone → pas de taille, à vérifier")
    func brochetWisconsin() throws {
        let (_, m) = try moteur()
        let jour = usJour(2026, 11, 20)
        let sud = m.evaluer(QuestionUS(espece: "northern-pike", juridiction: usId("US-WI/southern-zone"), jour: jour, taille: .pouces(20)))
        #expect(sud.verdict == .interdit)
        let etat = m.evaluer(QuestionUS(espece: "northern-pike", juridiction: usId("US-WI"), jour: jour, taille: .pouces(20)))
        #expect(etat.verdict != .interdit)
    }

    @Test("Hors saison lue (muskellunge du Minnesota en janvier) → interdit ; espèce sans règle confirmée → donnée absente")
    func saisonEtAbsence() throws {
        let (_, m) = try moteur()
        let mn = usId("US-MN")
        let janvier = m.evaluer(QuestionUS(espece: "muskellunge", juridiction: mn, jour: usJour(2027, 1, 15), taille: .pouces(60)))
        #expect(janvier.verdict == .interdit)
        let carpe = m.evaluer(QuestionUS(espece: "common-carp", juridiction: mn, jour: usJour(2026, 11, 20)))
        #expect(carpe.verdict == .donneeAbsente)
    }
}
