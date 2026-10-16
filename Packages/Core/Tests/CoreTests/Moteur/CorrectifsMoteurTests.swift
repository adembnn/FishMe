import Foundation
import Testing
@testable import Core

/// Défauts trouvés par le banc de faux utilisateurs (garde-pêche, truitiste, carpiste), rejoués sur les vrais fichiers de `Resources/regles/`.
@Suite("Correctifs du moteur de règles (vrais fichiers)")
struct CorrectifsMoteurTests {
    static let m = CasVerdictsReelsTests.moteur
    static let enSaison = utc(2026, 6, 15, 12, 0, 0)

    static func controle(_ id: String, _ code: String?, _ taille: Double?, lat: Double, lon: Double, date: Date = enSaison,
                         eau: Eau? = nil, tronconsConfirmes: [String] = [], prises: [Prise] = []) -> ResultatControle {
        var l = m.geo.lieu(de: Coordonnee(latitude: lat, longitude: lon), choix: nil)
        if let eau { l.eau = eau }
        l.tronconsConfirmes = tronconsConfirmes
        return m.regles.controle(espece: Espece(id: id, codeSandre: code), tailleCm: taille, mesure: .saisie, date: date, lieu: l, prisesDuJour: prises)
    }

    static func texte(_ r: ResultatControle) -> String { r.lignes.map(\.phrase).joined(separator: "\n") }

    // MARK: 1. Espèces génériques

    @Test("Divonne (01) : la maille de la truite fario sort")
    func divonneFario() {
        let r = Self.controle("truite-fario", "2221", 28, lat: 46.357, lon: 6.138)
        let tailles = r.lignes.filter { $0.type == .taille }
        #expect(tailles.contains { $0.phrase.contains("25 cm") }, "lignes : \(Self.texte(r))")
    }

    @Test("77 : le quota de salmonidés sort pour la truite fario")
    func quotaSalmonides77() {
        let r = Self.controle("truite-fario", "2221", 30, lat: 48.96, lon: 2.88)
        #expect(r.lignes.contains { $0.type == .quota && $0.phrase.contains("Salmonidés : 6 captures par jour") }, "lignes : \(Self.texte(r))")
    }

    @Test("Les groupes couvrent les bonnes espèces, et pas les autres")
    func groupes() {
        func vise(_ mot: String, _ id: String) -> Bool { GroupesEspeces.vise(mot, espece: Espece(id: id), nom: nil) }
        #expect(vise("salmonides", "ombre-commun"))
        #expect(vise("salmonides", "coregones"))
        #expect(!vise("salmonides", "brochet"))
        #expect(vise("carnassiers", "sandre"))
        #expect(!vise("carnassiers", "perche-commune"))
        #expect(vise("truite", "truite-arc-en-ciel"))
        #expect(!vise("truite", "omble-de-fontaine"))
        #expect(vise("autre:carnassiers", "brochet"))
        #expect(vise("omble-fontaine", "omble-de-fontaine"))
        #expect(vise("ecrevisse-louisiane", "ecrevisse-de-louisiane"))
        #expect(!vise("mot-inconnu", "brochet"))
    }

    // MARK: 2. Consommation interdite

    @Test("Brochet 65 cm sur la Marne à Charenton (94) : consommation interdite")
    func consommationMarne94() {
        let r = Self.controle("brochet", "2151", 65, lat: 48.812, lon: 2.416, eau: Eau(nom: "La Marne", cle: "marne", type: .riviere))
        #expect(r.lignes.contains { $0.type == .consommation }, "lignes : \(Self.texte(r))")
    }

    @Test("Brochet 65 cm sur la Seine à Paris (75) : consommation interdite")
    func consommationSeine75() {
        let r = Self.controle("brochet", "2151", 65, lat: 48.842, lon: 2.275, eau: Eau(nom: "La Seine", cle: "seine", type: .riviere))
        #expect(r.lignes.contains { $0.type == .consommation }, "lignes : \(Self.texte(r))")
    }

    @Test("Un canal de Paris qui n'est pas dans la règle Seine et Ourcq n'a pas cette ligne")
    func pasDeFauxPositif() {
        let r = Self.controle("brochet", "2151", 65, lat: 48.851, lon: 2.369,
                              eau: Eau(nom: "Bassin de l'Arsenal (canal Saint-Martin)", cle: "bassin-de-l-arsenal-canal-saint-martin", type: .lac))
        #expect(!r.lignes.contains { $0.type == .consommation && $0.phrase.contains("Ourcq") }, "lignes : \(Self.texte(r))")
    }

    // MARK: 3. Dates de l'ouverture de la fario

    @Test("nat-fario-ouv : les dates machine suivent la phrase (14 mars au 20 septembre)")
    func datesFarioNational() throws {
        let url = CasVerdictsReelsTests.dossier.appendingPathComponent("regles/national.json")
        let racine = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let regles = try #require(racine["regles"] as? [[String: Any]])
        let r = try #require(regles.first { ($0["id"] as? String) == "nat-fario-ouv" })
        #expect(r["du"] as? String == "2026-03-14")
        #expect(r["au"] as? String == "2026-09-20")
    }

    @Test("Fario en pleine fermeture d'hiver (février) : la période n'est pas « respectée »")
    func farioHiver() {
        let r = Self.controle("truite-fario", "2221", 30, lat: 50.276, lon: 2.288, date: utc(2026, 2, 10, 12, 0, 0))
        #expect(r.consigne == .relacheLa, "lignes : \(Self.texte(r))")
    }

    // MARK: 4. « J'y suis ? » : libellé ou id

    @Test("Frévent (62) : fario 40 cm sur le tronçon confirmé par son libellé, « Relâche-la »")
    func tronconParLibelle() throws {
        let url = CasVerdictsReelsTests.dossier.appendingPathComponent("regles/62.json")
        let f = try #require(ChargeurRegles(sources: [SourceDossier(dossier: url.deletingLastPathComponent())]).fichier("62"))
        let noKill = try #require(f.regles.first { $0.portee?.niveau == "troncon" && $0.type == "no_kill" && $0.especes.contains("2221") })
        let eau = Eau(nom: noKill.portee?.eau ?? "", cle: noKill.portee?.eau ?? "", type: .riviere)
        let sans = Self.controle("truite-fario", "2221", 40, lat: 50.276, lon: 2.288, eau: eau)
        let ligneTroncon = try #require(sans.lignes.first { $0.libelleTroncon != nil && $0.raison == .troncon },
                                        "aucune ligne de tronçon : \(Self.texte(sans))")
        let libelle = try #require(ligneTroncon.libelleTroncon)
        let avecLibelle = Self.controle("truite-fario", "2221", 40, lat: 50.276, lon: 2.288, eau: eau, tronconsConfirmes: [libelle])
        let avecId = Self.controle("truite-fario", "2221", 40, lat: 50.276, lon: 2.288, eau: eau, tronconsConfirmes: [noKill.id])
        #expect(sans.consigne != .relacheLa, "non confirmé, le tronçon reste « à vérifier » : \(Self.texte(sans))")
        #expect(avecLibelle.consigne == .relacheLa, "lignes : \(Self.texte(avecLibelle))")
        #expect(avecId.consigne == .relacheLa)
    }

    // MARK: 5. Réserve du 94

    @Test("94 : la réserve « y compris à la ligne » est affichée à vérifier sur place, avec sa source")
    func reserve94() {
        let r = Self.controle("brochet", "2151", 65, lat: 48.812, lon: 2.416)
        let l = r.lignes.first { $0.type == .reserve && $0.phrase.contains("y compris à la ligne") }
        #expect(l != nil, "lignes : \(Self.texte(r))")
        #expect(l?.etat == .aVerifierSurPlace)
        #expect(l?.sources.isEmpty == false)
    }

    // MARK: 6. Libellés

    @Test("« Règle locale possible (réserve de pêche) » : chaque type a son libellé français, jamais le type brut",
          arguments: [("reserve", "réserve de pêche"), ("consommation", "consommation du poisson"), ("no_kill", "parcours no-kill"),
                      ("categorie", "catégorie de l'eau"), ("remise_eau", "remise à l'eau"), ("transport_vivant", "transport du poisson vivant"), ("limite_eau_douce", "limite eau douce, eau salée"), ("autre", "autre règle")])
    func libelles(type: String, attendu: String) {
        let dep = fichierRegles(departement: "94", regles: [
            regle("94-cat-reste", "categorie", cat: "2", niveau: "departement", code: "94", valeur: ["classe": "2"], phrase: "2e catégorie."),
        ], aVerifier: [["type": type, "especes": [], "categorie": "toutes", "eau": NSNull(), "textes": ["t1"]]])
        let chargeur = ChargeurRegles(sources: [SourceMemoire(fichiers: ["national": nationalEssai, "94": dep])])
        let lieu = Lieu(departement: Departement(code: "94"), categorie: CategorieEau(valeur: .deuxieme, origine: .regleDeReste))
        let r = MoteurRegles(chargeur: chargeur).controle(espece: brochetEssai, tailleCm: 70, mesure: .saisie, date: quinzeOctobre,
                                                          lieu: lieu, prisesDuJour: [])
        let phrase = "Règle locale possible (\(attendu)) : vérifie l'arrêté."
        #expect(r.lignes.contains { $0.phrase == phrase }, "attendu « \(phrase) » dans : \(Self.texte(r))")
        #expect(!Self.texte(r).contains("Une règle de ce type existe peut-être"))
        #expect(!Self.texte(r).contains("(\(type))"))
    }

    // MARK: 7. Interdiction générale

    @Test("Carpe 45 cm à Frévent, perche 25 cm à Nantes, gardon 20 cm à Limoges, en saison : jamais « Relâche-la »")
    func interdictionGenerale() {
        let cas: [(String, String, Double, Double, Double)] = [
            ("carpe-commune", "2110", 50.276, 2.288, 45), ("perche-commune", "2193", 47.218, -1.553, 25), ("gardon", "2137", 45.833, 1.262, 20),
        ]
        for (id, code, lat, lon, taille) in cas {
            let r = Self.controle(id, code, taille, lat: lat, lon: lon, date: utc(2026, 6, 15, 12, 0, 0))
            #expect(r.consigne != .relacheLa, "\(id) : \(Self.texte(r))")
        }
    }

    // MARK: 8. « Tu peux garder »

    @Test("Aucune phrase des 97 fichiers ne dit « peux garder », « pouvez garder » ou « peut garder »")
    func pasDeTuPeuxGarder() throws {
        let dossier = CasVerdictsReelsTests.dossier.appendingPathComponent("regles")
        let noms = try FileManager.default.contentsOfDirectory(atPath: dossier.path).filter { $0.hasSuffix(".json") && $0 != "index.json" }
        #expect(noms.count >= 90)
        let motif = try Regex("(?i)(peux|peut|pouvez)( ne)?( la| le| les| en)? garder")
        var fautes: [String] = []
        for nom in noms {
            let racine = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: dossier.appendingPathComponent(nom))) as? [String: Any])
            for r in racine["regles"] as? [[String: Any]] ?? [] {
                let phrase = r["phrase"] as? String ?? ""
                if phrase.contains(motif) { fautes.append("\(nom) \(r["id"] ?? "") : \(phrase)") }
            }
        }
        #expect(fautes.isEmpty, "\(fautes)")
    }
}
