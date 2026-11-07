import Foundation
import Testing
@testable import Core

/// Fichier d'essai (FIXTURE) modifiable champ par champ : les tests de rejet partent de la même base valide.
private func jsonFixture(fixture: Bool = true, source: String = "https://agence-wi.exemple.test/reglements", citation: String = "FIXTURE Walleye: minimum length 15 inches.",
                         statut: String? = "\"double_lecture_confirmee\"", etat: String = "WI", extraRegle: String = "") -> String {
    let st = statut.map { ", \"statut\": \($0)" } ?? ""
    return """
    {"format": 1, "fixture": \(fixture), "etat": "\(etat)", "nom_etat": "Wisconsin d'essai", "version": "2026-11-07.1", "genere_le": "2026-11-07",
     "couverture": 2, "champ_inconnu_ignore": 42,
     "regles": [{"id": "r1", "portee": "US-WI", "espece": "walleye", "tailles": {"minimale": {"pouces": 15}},
                 "source": {"url": "\(source)", "date": "2026-11-05", "citation": "\(citation)"}\(st)\(extraRegle)}]}
    """
}

private func charge(_ json: String, fixture: Bool = true) throws -> EtatReglesUS {
    try ChargementReglesUS.lire(Data(json.utf8), fichier: "WI.json", attendu: usEtat("WI"), autoriseFixture: fixture)
}

private func erreur(_ json: String, fixture: Bool = true) -> ErreurReglesUS? {
    do { _ = try charge(json, fixture: fixture); return nil } catch { return error as? ErreurReglesUS }
}

@Suite("Région US : format regles-us et chargeur")
struct FormatReglesUSTests {
    @Test("Décodage d'un État de test : juridictions, règles, exigences, unités")
    func decodageEtatDeTest() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("outils/us/format/fixtures/WI-FIXTURE.json")
        let donnees = try Data(contentsOf: url)
        let e = try ChargementReglesUS.lire(donnees, fichier: "WI-FIXTURE.json", attendu: usEtat("WI"), autoriseFixture: true)
        #expect(e.code == usEtat("WI") && e.couverture == .niveau3)
        #expect(e.juridictions.map(\.id.rawValue).sorted() == ["US-WI", "US-WI/lac-x", "US-WI/nord", "US-WI/reserve-z"])
        #expect(e.juridictions.first { $0.id == usReserve }?.alertes == [.reserveTribale])
        #expect(e.regles.count == 4 && e.exigences.count == 1)
        let taille = try #require(e.regles.first { $0.id == "WI-walleye-taille" })
        #expect(taille.tailles.minimale == .pouces(15) && taille.source.dateLecture == usJour(2026, 11, 5))
        #expect(taille.couverture == .niveau3)
        let pike = try #require(e.regles.first { $0.id == "WI-pike-saison" })
        #expect(pike.saison == usPeriode(12, 1, 3, 15))
        let fen = try #require(e.regles.first { $0.id == "WI-lacx-fenetre" })
        #expect(fen.tailles.fenetre == FenetreProtegee(basse: .pouces(14), haute: .pouces(18)) && fen.limites.prise == 3 && fen.statut == .relueParPersonne)
        #expect(e.exigences[0].prixDollars == Decimal(string: "20.5") && e.exigences[0].exempteMoinsDe == 16)
    }

    @Test("Les centimètres sont convertis en unités internes, une seule unité par valeur")
    func unites() throws {
        let e = try charge(jsonFixture().replacingOccurrences(of: "{\"pouces\": 15}", with: "{\"cm\": 38.1}"))
        #expect(e.regles[0].tailles.minimale?.memeValeur(que: .pouces(15)) == true)
        #expect(erreur(jsonFixture().replacingOccurrences(of: "{\"pouces\": 15}", with: "{\"cm\": 38, \"pouces\": 15}")) != nil)
    }

    @Test("Rejet : source en http")
    func sourceHttp() {
        let e = erreur(jsonFixture(source: "http://agence-wi.exemple.test/reglements"))
        #expect(e == .sourceNonHttps(fichier: "WI.json", contexte: "règle r1", url: "http://agence-wi.exemple.test/reglements"))
    }

    @Test("Rejet : citation de plus de 200 caractères ; 200 pile passe")
    func citationLongue() throws {
        #expect(erreur(jsonFixture(citation: String(repeating: "a", count: 201))) == .citationTropLongue(fichier: "WI.json", contexte: "règle r1", longueur: 201))
        let ok = try charge(jsonFixture(citation: String(repeating: "a", count: 200)))
        #expect(ok.regles[0].source.citation?.count == 200)
    }

    @Test("Rejet : citation absente, statut absent ou inconnu, date absente")
    func champsObligatoires() {
        #expect(erreur(jsonFixture(citation: "")) == .champManquant(fichier: "WI.json", contexte: "règle r1", champ: "source.citation"))
        #expect(erreur(jsonFixture(statut: nil)) == .statutManquant(fichier: "WI.json", contexte: "règle r1"))
        if case .valeurInvalide(_, _, let champ, _)? = erreur(jsonFixture(statut: "\"permis\"")) { #expect(champ == "statut") } else { Issue.record("statut inconnu accepté") }
        let sansDate = jsonFixture().replacingOccurrences(of: "\"date\": \"2026-11-05\", ", with: "")
        #expect(erreur(sansDate) == .champManquant(fichier: "WI.json", contexte: "règle r1", champ: "source.date"))
        let dateImpossible = jsonFixture().replacingOccurrences(of: "2026-11-05", with: "2026-02-30")
        if case .valeurInvalide(_, _, let champ, _)? = erreur(dateImpossible) { #expect(champ == "source.date") } else { Issue.record("date impossible acceptée") }
    }

    @Test("Rejet : fichier FIXTURE en production (chargeur public), accepté par le chargeur de test")
    func fixtureHorsTests() {
        let source = SourceMemoire(textes: ["WI": jsonFixture()])
        #expect(throws: ErreurReglesUS.fichierFixtureHorsTests(fichier: "WI.json")) { try ChargementReglesUS(source: source).etat(usEtat("WI")) }
        #expect((try? ChargementReglesUS(source: source, autoriseFixture: true).etat(usEtat("WI"))) != nil)
        let tout = ChargementReglesUS(source: source).tout()
        #expect(tout.regles.isEmpty && tout.erreurs[usEtat("WI")] == .fichierFixtureHorsTests(fichier: "WI.json"))
    }

    @Test("Rejet : mauvais État, version de format inconnue, portée absente, règle vide, doublon, JSON cassé")
    func autresRejets() {
        #expect(erreur(jsonFixture(etat: "MI")) == .etatInattendu(fichier: "WI.json", attendu: "WI", trouve: "MI"))
        #expect(erreur(jsonFixture().replacingOccurrences(of: "\"format\": 1", with: "\"format\": 2")) == .formatNonSupporte(fichier: "WI.json", trouve: 2))
        #expect(erreur(jsonFixture().replacingOccurrences(of: "\"portee\": \"US-WI\"", with: "\"portee\": \"US-WI/lac-fantome\""))
                == .porteeInconnue(fichier: "WI.json", contexte: "règle r1", portee: "US-WI/lac-fantome"))
        #expect(erreur(jsonFixture().replacingOccurrences(of: "\"tailles\": {\"minimale\": {\"pouces\": 15}}", with: "\"engins\": []"))
                == .regleSansContenu(fichier: "WI.json", regle: "r1"))
        let doublon = jsonFixture().replacingOccurrences(of: "}]}", with: "}, {\"id\": \"r1\"}]}")
        #expect(erreur(doublon) == .identifiantEnDouble(fichier: "WI.json", id: "r1"))
        if case .jsonIllisible(let f, _)? = erreur("{pas du json") { #expect(f == "WI.json") } else { Issue.record("JSON cassé accepté") }
        if case .jsonIllisible(_, let d)? = erreur(jsonFixture().replacingOccurrences(of: "\"format\": 1", with: "\"format\": \"un\"")) { #expect(d.contains("format")) } else { Issue.record("type faux accepté") }
    }

    @Test("Un fichier refusé n'empêche pas les autres États ; l'index fixe la liste et la somme de contrôle")
    func indexEtSomme() throws {
        let bon = jsonFixture(fixture: false)
        let sha = ChargementReglesUS.sha256Hex(Data(bon.utf8))
        let index = """
        {"format": 1, "version": "v1", "date": "2026-11-07", "etats": {"WI": {"niveau": 2, "regles": 1, "sha256": "\(sha)"}, "MI": {"niveau": 2}}}
        """
        let source = SourceMemoire(textes: ["index": index, "WI": bon, "MI": "{}"])
        let r = ChargementReglesUS(source: source).tout()
        #expect(r.etats.map(\.code) == [usEtat("WI")] && r.erreurs.keys.contains(usEtat("MI")))
        let falsifie = SourceMemoire(textes: ["index": index, "WI": bon.replacingOccurrences(of: "15", with: "16")])
        #expect(throws: ErreurReglesUS.sommeDeControleDifferente(fichier: "WI.json")) { try ChargementReglesUS(source: falsifie).etat(usEtat("WI")) }
        let faux = SourceMemoire(textes: ["index": index.replacingOccurrences(of: "\"WI\"", with: "\"XX\"")])
        #expect(throws: ErreurReglesUS.self) { try ChargementReglesUS(source: faux).index() }
    }

    @Test("Bout en bout : règles chargées, verdict du moteur, jamais permissif")
    func boutEnBout() throws {
        let chargeur = ChargementReglesUS(source: SourceMemoire(textes: ["WI": jsonFixture(fixture: true)]), autoriseFixture: true)
        let contenu = chargeur.tout()
        #expect(contenu.erreurs.isEmpty)
        let moteur = try contenu.moteur()
        let jour = usJour(2026, 11, 20)  // après la date de lecture de la fixture (5 nov.)
        let sous = moteur.evaluer(QuestionUS(espece: "walleye", juridiction: usWI, jour: jour, taille: .pouces(12)))
        #expect(sous.verdict == .interdit && sous.regles == ["r1"])
        #expect(sous.sources.first?.url.scheme == "https" && sous.lienAgence == nil)
        let assez = moteur.evaluer(QuestionUS(espece: "walleye", juridiction: usWI, jour: jour, taille: .pouces(20)))
        #expect(assez.verdict == .aVerifier)
        let autre = moteur.evaluer(QuestionUS(espece: "muskie", juridiction: usWI, jour: jour, taille: .pouces(20)))
        #expect(autre.verdict == .donneeAbsente)
        for m in sous.motifs + assez.motifs { for mot in usMotsInterdits { #expect(!m.libelle().lowercased().contains(mot)) } }
        // Règle non relue : ne fonde jamais « interdit ».
        let brouillon = jsonFixture(statut: "\"non_relue\"")
        let m2 = try ChargementReglesUS(source: SourceMemoire(textes: ["WI": brouillon]), autoriseFixture: true).tout().moteur()
        #expect(m2.evaluer(QuestionUS(espece: "walleye", juridiction: usWI, jour: jour, taille: .pouces(12))).verdict == .aVerifier)
    }

    @Test("L'index embarqué se lit et ne contient aucun fichier FIXTURE")
    func indexEmbarque() throws {
        let dossier = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("../Sources/Core/Resources/regles-us").standardized
        let chargeur = ChargementReglesUS(source: SourceDossier(dossier: dossier))
        let idx = try chargeur.index()
        #expect(idx.format == 1 && idx.niveau1?.fichier == "etats.json")
        let n1 = try Niveau1US.charger(source: SourceDossier(dossier: dossier))
        #expect(n1.etats.count == 51 && n1.etatDeLaDonnee?.contains("relus") == true)
        let tout = chargeur.tout()
        #expect(tout.erreurs.isEmpty)
        // Depuis le lot us-consensus (7 nov.), l'index liste les États confirmés par double lecture (WI, MN) : chacun se charge.
        #expect(tout.etats.count == idx.etats.count)
    }
}
