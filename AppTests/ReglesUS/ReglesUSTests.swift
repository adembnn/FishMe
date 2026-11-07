import Core
import Foundation
import Testing
@testable import BuildChallenge

/// Lot US12 : le bloc de règles américaines. Trois verdicts exactement, aucun mot de permission, unités de la région,
/// lien de l'agence, source et date toujours là.
@MainActor
struct ReglesUSTests {
    private let us = FormatRegion(region: .etatsUnis)
    private let fr = FormatRegion(region: .france)
    private static let mots = ["autoris", "allowed", "legal", "tu peux la garder", "you can keep"]

    private func jour(_ a: Int, _ m: Int, _ j: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: a, month: m, day: j, hour: 12)) ?? Date()
    }

    private func evaluateur() throws -> EvaluateurUS {
        try #require(ServiceReglesUS.evaluateur)
    }

    private func presenter(_ espece: String, _ code: String, taille: Double? = nil, estimee: Bool = false, format: FormatRegion? = nil,
                           juridiction: IdJuridiction? = nil) throws -> PresentationReglesUS {
        let etat = try #require(CodeEtat(rawValue: code))
        let q = PresentationReglesUS.question(espece: espece, etat: etat, juridiction: juridiction, date: jour(2026, 11, 8), tailleCm: taille,
                                              tailleEstimee: estimee)
        return PresentationReglesUS.construire(question: q, etat: etat, evaluateur: try evaluateur(), format: format ?? us)
    }

    /// Tous les textes qu'un pêcheur peut lire pour une présentation.
    private func textes(_ p: PresentationReglesUS) -> [String] {
        [p.etiquette, p.phrase, p.mention, p.texteSource ?? ""] + p.raisons + p.groupes.flatMap { g in [g.portee] + g.lignes.flatMap { [$0.titre, $0.valeur] } }
    }

    private func scenarios(_ format: FormatRegion) throws -> [PresentationReglesUS] {
        [try presenter("muskellunge", "WI", taille: 50, format: format),
         try presenter("muskellunge", "WI", taille: 150, format: format),
         try presenter("walleye", "MN", taille: 30, format: format),
         try presenter("walleye", "NY", format: format),
         try presenter("espece-inconnue", "WI", format: format),
         PresentationReglesUS.sansEtat(format: format)]
    }

    // MARK: Trois verdicts exactement

    @Test func leVerdictADeuxTroisValeursEtPasUneDePlus() {
        #expect(VerdictUS.allCases.count == 3)
        #expect(Set(VerdictUS.allCases) == [.interdit, .aVerifier, .donneeAbsente])
    }

    @Test func lesTroisEtiquettesSontCellesDeLaDecision() {
        let f = TextesReglesUS(locale: fr.locale), e = TextesReglesUS(locale: us.locale)
        #expect(VerdictUS.allCases.map(f.etiquette) == ["Interdit", "À vérifier", "Donnée absente"])
        #expect(VerdictUS.allCases.map(e.etiquette) == ["Prohibited", "Check with the agency", "No data"])
        #expect(Set(VerdictUS.allCases.map(f.phrase)).count == 3)
        #expect(Set(VerdictUS.allCases.map(e.phrase)).count == 3)
    }

    @Test func uneTailleSousLeMinimumDonneInterdit() throws {
        let p = try presenter("muskellunge", "WI", taille: 50)
        #expect(p.verdict == .interdit)
        #expect(!p.raisons.isEmpty)
        #expect(p.etiquette == "Prohibited")
    }

    @Test func sansTailleOuAvecTailleEstimeeJamaisInterdit() throws {
        #expect(try presenter("muskellunge", "WI").verdict == .aVerifier)
        #expect(try presenter("muskellunge", "WI", taille: 50, estimee: true).verdict == .aVerifier)
    }

    @Test func niveauUnSansRegleParEspeceDonneDonneeAbsenteEtLeLien() throws {
        let p = try presenter("walleye", "OH")
        #expect(p.verdict == .donneeAbsente)
        #expect(p.groupes.isEmpty)
        #expect(p.lienAgence != nil)
    }

    @Test func niveauDeuxEtTroisDonnentLesReglesEtLeVerdictDuMoteur() throws {
        for code in ["WI", "MN"] {
            let e = try evaluateur()
            let regle = try #require(e.moteur.regles.first { $0.espece != nil && $0.portee == .etat(CodeEtat(rawValue: code)!) && $0.tailles.minimale != nil })
            let p = try presenter(try #require(regle.espece), code)
            #expect(!p.groupes.isEmpty)
            #expect(p.verdict != .donneeAbsente)
        }
    }

    // MARK: Aucun mot interdit

    @Test func aucunTexteRenduNeContientUnMotInterdit() throws {
        for format in [us, fr] {
            for p in try scenarios(format) {
                for t in textes(p) {
                    let bas = t.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
                    for mot in Self.mots { #expect(!bas.contains(mot), "« \(t) » contient « \(mot) »") }
                }
            }
        }
    }

    @Test func lesTextesFixesNeContiennentAucunMotInterdit() {
        for l in [fr.locale, us.locale] {
            let t = TextesReglesUS(locale: l)
            let tous = VerdictUS.allCases.flatMap { [t.etiquette($0), t.phrase($0)] } + [
                t.titreDepliant, t.aucuneLigne, t.lienAgence, t.lienSource, t.mention, t.etatInconnu, t.choisirEtat, t.titreBloc,
                t.boutonRegles, t.tailleMinimale, t.tailleMaximale, t.fenetreProtegee, t.limiteJour, t.limitePossession, t.saison,
                t.fermeture, t.materiel, t.appats, t.touteLAnnee, t.source(nom: "x", date: "y"), t.sourceSansNom(date: "y"),
            ] + [TypeFermeture.pecheInterdite, .remiseAEauSeulement, .especeProtegee].map(t.type)
            for s in tous {
                let bas = s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
                for mot in Self.mots { #expect(!bas.contains(mot), "« \(s) » contient « \(mot) »") }
                #expect(!s.isEmpty)
            }
        }
    }

    /// Le même contrôle que le grep du lot, sur les sources de `App/ReglesUS` (ignoré si les sources ne sont pas lisibles depuis le test).
    @Test func lesSourcesDuLotNeContiennentAucunMotInterdit() throws {
        let dossier = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/ReglesUS")
        guard let fichiers = FileManager.default.enumerator(at: dossier, includingPropertiesForKeys: nil) else { return }
        for case let url as URL in fichiers {
            guard let texte = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let bas = texte.lowercased()
            for mot in Self.mots { #expect(!bas.contains(mot), "\(url.lastPathComponent) contient « \(mot) »") }
        }
    }

    // MARK: Unités

    @Test func lesTaillesSontEnPoucesAuxEtatsUnisEtLeVerdictNeChangePas() throws {
        let imperial = try presenter("muskellunge", "WI", taille: 50, format: us)
        let metrique = try presenter("muskellunge", "WI", taille: 50, format: fr)
        #expect(imperial.verdict == metrique.verdict)
        let mini = try #require(imperial.groupes.flatMap(\.lignes).first { $0.titre == TextesReglesUS(locale: us.locale).tailleMinimale })
        #expect(mini.valeur == "40 in")
        let miniFr = try #require(metrique.groupes.flatMap(\.lignes).first { $0.titre == TextesReglesUS(locale: fr.locale).tailleMinimale })
        #expect(miniFr.valeur == "101,6 cm")
        #expect(!imperial.groupes.flatMap(\.lignes).contains { $0.valeur.contains("cm") })
    }

    // MARK: Lien, source et date toujours là

    @Test func lienSourceEtDateSontToujoursPresents() throws {
        for p in [try presenter("muskellunge", "WI", taille: 50), try presenter("muskellunge", "WI"), try presenter("espece-inconnue", "MN"),
                  try presenter("walleye", "NY"), try presenter("walleye", "TX")] {
            #expect(p.lienAgence != nil)
            #expect(p.sourceURL != nil)
            let source = try #require(p.texteSource)
            #expect(source.contains("2026"))
        }
    }

    @Test func lesCinquanteEtatsOntLeLienDeLeurAgence() throws {
        let e = try evaluateur()
        let etats = try #require(e.niveau1).etats
        #expect(etats.count >= 50)
        for n in etats where n.lienOfficiel != nil {
            let p = try presenter("walleye", n.code.rawValue)
            #expect(p.lienAgence != nil, "\(n.code)")
            #expect(p.texteSource != nil, "\(n.code)")
        }
    }

    @Test func etatInconnuDonneDonneeAbsenteSansInventerDeLien() {
        let p = PresentationReglesUS.sansEtat(format: us)
        #expect(p.verdict == .donneeAbsente)
        #expect(p.etatInconnu)
        #expect(p.lienAgence == nil)
    }

    // MARK: Où est le pêcheur

    @Test func lEtatSeDevineSeulementDansLesEtatsDesDonneesGeographiques() {
        #expect(EtatUSDepuisLieu.etat(pour: Coordonnee(latitude: 43.07, longitude: -89.40))?.rawValue == "WI")
        #expect(EtatUSDepuisLieu.etat(pour: Coordonnee(latitude: 45.56, longitude: -94.16))?.rawValue == "MN")
        #expect(EtatUSDepuisLieu.etat(pour: Coordonnee(latitude: 48.85, longitude: 2.35)) == nil)
        #expect(EtatUSDepuisLieu.etat(pour: Coordonnee(latitude: 44.31, longitude: -85.60))?.rawValue == "MI")
        #expect(EtatUSDepuisLieu.etat(pour: Coordonnee(latitude: 40.0, longitude: -83.0)) == nil)
    }

    @Test func lEtatSeLitDansLeLieuFlou() {
        let noms: [(code: CodeEtat, nom: String)] = [(CodeEtat(rawValue: "WI")!, "Wisconsin"), (CodeEtat(rawValue: "MN")!, "Minnesota")]
        #expect(EtatUSDepuisLieu.etat(depuisLieuFlou: "Lake Mendota · WI", noms: noms)?.rawValue == "WI")
        #expect(EtatUSDepuisLieu.etat(depuisLieuFlou: "Minnesota", noms: noms)?.rawValue == "MN")
        #expect(EtatUSDepuisLieu.etat(depuisLieuFlou: "La Marne · 94", noms: noms) == nil)
        #expect(EtatUSDepuisLieu.etat(depuisLieuFlou: "WI / MN", noms: noms) == nil)
        #expect(EtatUSDepuisLieu.etat(depuisLieuFlou: nil, noms: noms) == nil)
    }
}
