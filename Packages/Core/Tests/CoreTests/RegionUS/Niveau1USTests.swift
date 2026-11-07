import Foundation
import Testing
@testable import Core

private func etatJSON(usps: String = "ZZ", verifie: Bool, qualite: String = "officiel", montantResident: String = "25", url: String = "https://agence.exemple.test/") -> String {
    """
    {"usps": "\(usps)", "nom": "État d'essai \(usps)", "agence": "Agence d'essai", "url_agence": "\(url)", "url_regles_eau_douce": "http://agence.exemple.test/regles",
     "url_permis": "http://agence.exemple.test/permis", "niveau_vise": 2, "verifie": \(verifie), "date_lecture": "2026-11-07",
     "prix_resident": {"montant": \(montantResident), "monnaie": "USD", "annee": 2026, "source": "https://agence.exemple.test/prix", "qualite": "\(qualite)", "note": null},
     "prix_non_resident": null, "champ_inconnu": [1]}
    """
}

private func fichier(_ etats: [String]) -> Data {
    Data("{\"version\": 1, \"date_lecture\": \"2026-11-07\", \"avertissement\": \"essai\", \"etats\": [\(etats.joined(separator: ","))]}".utf8)
}

@Suite("Région US : niveau 1 (permis, prix, liens)")
struct Niveau1USTests {
    @Test("État vérifié avec source officielle : prix présenté comme officiel, avec date")
    func etatVerifie() throws {
        let n1 = try Niveau1US.decoder(fichier([etatJSON(usps: "WI", verifie: true)]))
        let wi = try #require(n1[usEtat("WI")])
        let prix = try #require(wi.prixResident)
        #expect(wi.presentation(de: prix) == .officielVerifie)
        #expect(wi.texte(de: prix) == "25 $ (source officielle, lu le 2026-11-07)")
        #expect(wi.permisRequis == true && wi.niveauVise == .niveau2)
    }

    @Test("État non vérifié : jamais officiel, même si la source se dit officielle ; « environ » et renvoi au site")
    func etatNonVerifie() throws {
        let n1 = try Niveau1US.decoder(fichier([etatJSON(usps: "WI", verifie: false, qualite: "officiel"), etatJSON(usps: "MI", verifie: false, qualite: "tiers", montantResident: "17.5")]))
        let wi = try #require(n1[usEtat("WI")]), mi = try #require(n1[usEtat("MI")])
        #expect(wi.presentation(de: try #require(wi.prixResident)) == .indicatifAVerifier(qualite: .officiel))
        let t = mi.texte(de: try #require(mi.prixResident))
        #expect(t.hasPrefix("environ 17,5 $") && t.contains("source tierce [?]") && t.contains("vérifie sur le site de l'agence"))
        #expect(!wi.texte(de: try #require(wi.prixResident)).contains("source officielle"))
        #expect(n1.verifies.isEmpty)
    }

    @Test("État vérifié mais prix d'un éditeur ou d'un tiers : pas officiel non plus")
    func verifieMaisPasOfficiel() throws {
        let n1 = try Niveau1US.decoder(fichier([etatJSON(usps: "WI", verifie: true, qualite: "editeur")]))
        let wi = try #require(n1[usEtat("WI")])
        #expect(wi.presentation(de: try #require(wi.prixResident)) == .indicatifAVerifier(qualite: .editeur))
    }

    @Test("Qualité inconnue ou absente : traitée comme tiers, jamais promue")
    func qualiteInconnue() throws {
        let n1 = try Niveau1US.decoder(fichier([etatJSON(usps: "WI", verifie: true, qualite: "gouvernement")]))
        let wi = try #require(n1[usEtat("WI")])
        #expect(try #require(wi.prixResident).qualite == .tiers)
    }

    @Test("Liens : seuls les https sont exposés ; le lien du permis passe avant celui de l'agence ; sans prix, permis « non lu »")
    func liens() throws {
        let sans = etatJSON(usps: "MI", verifie: false).replacingOccurrences(of: "\"prix_resident\"", with: "\"prix_resident_absent\"")
        let n1 = try Niveau1US.decoder(fichier([etatJSON(usps: "WI", verifie: false), sans]))
        let wi = try #require(n1[usEtat("WI")]), mi = try #require(n1[usEtat("MI")])
        #expect(wi.urlPermis == nil && wi.urlReglesEauDouce == nil)
        #expect(wi.lienOfficiel?.absoluteString == "https://agence.exemple.test/")
        #expect(mi.permisRequis == nil && mi.prixResident == nil)
    }

    @Test("Rejets : code USPS inconnu, État en double, date, montant négatif")
    func rejets() {
        #expect(throws: ErreurNiveau1US.self) { try Niveau1US.decoder(fichier([etatJSON(usps: "XX", verifie: false)])) }
        #expect(throws: ErreurNiveau1US.etatEnDouble("WI")) { try Niveau1US.decoder(fichier([etatJSON(usps: "WI", verifie: false), etatJSON(usps: "WI", verifie: false)])) }
        #expect(throws: ErreurNiveau1US.self) { try Niveau1US.decoder(fichier([etatJSON(usps: "WI", verifie: false, montantResident: "-3")])) }
        #expect(throws: ErreurNiveau1US.self) { try Niveau1US.decoder(Data("{\"etats\": []}".utf8)) }
        #expect(throws: ErreurNiveau1US.self) { try Niveau1US.decoder(Data("pas du json".utf8)) }
    }

    @Test("Copie embarquée de etats.json : 51 entrées, 3 États vérifiés, aucun prix d'un État non vérifié présenté comme officiel")
    func copieEmbarquee() throws {
        let dossier = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("../Sources/Core/Resources/regles-us").standardized
        let n1 = try Niveau1US.charger(source: SourceDossier(dossier: dossier))
        #expect(n1.etats.count == 51)
        #expect(Set(n1.verifies.map(\.code.rawValue)) == ["NY", "TX", "VA"])
        for e in n1.etats {
            for p in [e.prixResident, e.prixNonResident].compactMap({ $0 }) where !e.verifie {
                #expect(e.presentation(de: p) != .officielVerifie)
                #expect(e.texte(de: p).hasPrefix("environ"))
            }
        }
        #expect(n1.etatDeLaDonnee?.contains("non vérifiés") == true)
    }

    // MARK: Niveau 1 dans le moteur

    private func evaluateur(_ v: VerdictNiveau1US) throws -> EvaluateurUS {
        let n1 = try Niveau1US.decoder(fichier([etatJSON(usps: "WI", verifie: false), etatJSON(usps: "MI", verifie: false)]))
        let regle = Data("""
        {"format": 1, "fixture": true, "etat": "WI", "nom_etat": "Wisconsin d'essai", "version": "v", "genere_le": "2026-11-07", "couverture": 2,
         "regles": [{"id": "r1", "portee": "US-WI", "espece": "walleye", "tailles": {"minimale": {"pouces": 15}},
          "source": {"url": "https://agence.exemple.test/r", "date": "2026-11-05", "citation": "FIXTURE minimum 15 inches"}, "statut": "double_lecture_confirmee"}]}
        """.utf8)
        let contenu = ChargementReglesUS(source: SourceMemoire(fichiers: ["WI": regle]), autoriseFixture: true).tout()
        return try EvaluateurUS(contenu: contenu, niveau1: n1, verdictNiveau1: v)
    }

    @Test("État de niveau 1 sans règle par espèce : donnée absente par défaut, avec le lien de l'agence")
    func niveau1DonneeAbsente() throws {
        let ev = try evaluateur(.donneeAbsente)
        let r = ev.evaluer(QuestionUS(espece: "walleye", juridiction: .etat(usEtat("MI")), jour: usEte, taille: .pouces(10)))
        #expect(r.verdict == .donneeAbsente)
        #expect(r.lienAgence?.absoluteString == "https://agence.exemple.test/")
    }

    @Test("verdictNiveau1 = à vérifier : seul ce paramètre change ; un État avec règles et un État inconnu ne bougent pas")
    func niveau1AVerifier() throws {
        let ev = try evaluateur(.aVerifier)
        let mi = ev.evaluer(QuestionUS(espece: "walleye", juridiction: .etat(usEtat("MI")), jour: usEte, taille: .pouces(10)))
        #expect(mi.verdict == .aVerifier && mi.motifs.contains(.aucuneRegleLue))
        // WI a des règles : l'espèce sans règle reste « donnée absente » (c'est un État de niveau 2).
        let wi = ev.evaluer(QuestionUS(espece: "muskie", juridiction: usWI, jour: usEte))
        #expect(wi.verdict == .donneeAbsente)
        let inconnu = ev.evaluer(QuestionUS(espece: "walleye", juridiction: .etat(usEtat("TX")), jour: usEte))
        #expect(inconnu.verdict == .donneeAbsente)
        // Jamais « interdit » sans règle lue.
        #expect(mi.verdict != .interdit)
        // Les règles chargées continuent de jouer.
        #expect(ev.evaluer(QuestionUS(espece: "walleye", juridiction: usWI, jour: usEte, taille: .pouces(10))).verdict == .interdit)
    }
}
