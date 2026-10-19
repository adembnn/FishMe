import Foundation
import Testing
import Core
@testable import BuildChallenge

/// Les 13 cas d'or de `cas-verdicts.json` passés dans la logique d'affichage du bloc de règles (L19) : l'état de tête doit suivre la consigne de Core.
/// Les lignes viennent du vrai moteur de `Core` (comme `CasVerdictsReelsTests`) ; ici on vérifie seulement ce que `BlocReglesLogique` en fait.
/// Écrit sans Mac, non exécuté : à lancer sur le Mac (`xcodebuild test`, filtre `AppTests/Prise`).
@MainActor
struct CasDOrAffichageTests {
    /// Le fichier se lit dans le dépôt, à côté de `Core` (le paquet n'expose pas ses ressources à l'app).
    private static let fichier = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Packages/Core/Sources/Core/Resources/cas-verdicts.json")

    private static let cas: [[String: Any]] = {
        guard let d = try? Data(contentsOf: fichier),
              let o = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { return [] }
        return o["cas"] as? [[String: Any]] ?? []
    }()

    private static let ids: [String] = cas.compactMap { $0["id"] as? String }

    private nonisolated static func date(_ s: String) -> Date {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let p = s.split(separator: "-").compactMap { Int($0) }
        return c.date(from: DateComponents(year: p[0], month: p[1], day: p[2], hour: 12)) ?? Date()
    }

    private static let moteur = MoteurCore(donnees: .embarque(dossierFabriques: Bundle.main.resourceURL),
                                           horloge: { date("2026-10-15") })

    private static func lieu(_ e: [String: Any]) -> Lieu {
        let l = e["lieu"] as? [String: Any] ?? [:]
        var eau: Eau?
        if let o = l["eau"] as? [String: Any], let nom = o["nom"] as? String, let cle = o["cle"] as? String {
            eau = Eau(nom: nom, cle: cle, type: .riviere)
        }
        let c = l["categorie"] as? [String: Any] ?? [:]
        let categorie = CategorieEau(valeur: Categorie(rawValue: c["valeur"] as? String ?? "inconnue") ?? .inconnue,
                                     origine: OrigineCategorie(rawValue: c["origine"] as? String ?? "aucune") ?? .aucune)
        return Lieu(departement: Departement(code: l["departement"] as? String ?? "inconnu"), eau: eau, categorie: categorie)
    }

    private static func controle(_ e: [String: Any]) -> ResultatControle {
        let esp = e["espece"] as? [String: Any] ?? [:]
        let taille = (e["tailleCm"] as? NSNumber)?.doubleValue
        let mesure = (e["mesure"] as? String).flatMap { MethodeMesure(rawValue: $0) }
        return moteur.regles.controle(espece: Espece(id: esp["id"] as? String ?? "", codeSandre: esp["codeSandre"] as? String),
                                      tailleCm: taille, mesure: mesure, date: date(e["date"] as? String ?? "2026-10-15"),
                                      lieu: lieu(e), prisesDuJour: [])
    }

    @Test func lesTreizeCasSontLus() { #expect(Self.cas.count == 13) }

    @Test("L'état de tête suit la consigne de Core, pour chacun des 13 cas", arguments: ids)
    func etatDeTete(id: String) throws {
        let c = try #require(Self.cas.first { $0["id"] as? String == id })
        let e = try #require(c["entree"] as? [String: Any])
        let a = try #require(c["attendu"] as? [String: Any])
        let r = Self.controle(e)
        let tete = BlocReglesLogique.tete(lignes: r.lignes, consigne: r.consigne, especeConfirmee: true)
        let attendue = a["consigne"] as? String ?? ""
        switch tete {
        case .relacher:
            #expect(attendue == "relacheLa", "\(id) : « Il faut relâcher le poisson » affiché, consigne attendue \(attendue)")
        case .reglementation(let aVerifier):
            #expect(attendue != "relacheLa", "\(id) : « Voir la réglementation » affiché, consigne attendue \(attendue)")
            // La pastille orange suit les lignes « à vérifier » du cas (sauf le cas hors de France, dont la ligne vient de Core).
            let lignesAttendues = a["lignes"] as? [[String: Any]] ?? []
            if id != "cas-12" {
                #expect(aVerifier == lignesAttendues.contains { $0["etat"] as? String == "aVerifierSurPlace" }, "\(id) : pastille")
            }
        }
    }

    @Test("Jamais d'autorisation dans ce que le bloc affiche, pour chacun des 13 cas", arguments: ids)
    func aucuneAutorisation(id: String) throws {
        let c = try #require(Self.cas.first { $0["id"] as? String == id })
        let r = Self.controle(try #require(c["entree"] as? [String: Any]))
        let tout = (r.lignes.map(\.phrase) + [r.consigne.texte]).joined(separator: " ").lowercased()
        #expect(!tout.contains("tu peux la garder"))
        #expect(!tout.contains("autorisé"))
    }

    // MARK: Les trois cas du brochet dans le 94

    @Test func brochet55EstARelacherAvecLaRaisonDeLaTaille() throws {
        let c = try #require(Self.cas.first { $0["id"] as? String == "cas-01" })
        let r = Self.controle(try #require(c["entree"] as? [String: Any]))
        guard case .relacher(let raison, let ligne) = BlocReglesLogique.tete(lignes: r.lignes, consigne: r.consigne, especeConfirmee: true) else {
            Issue.record("55 cm : « Il faut relâcher le poisson » attendu"); return
        }
        #expect(ligne?.type == .taille)
        #expect(raison == ligne?.phrase)
        #expect(ligne?.sources.isEmpty == false, "la raison ouvre sa source")
    }

    @Test func brochet65EstLaReglementationFermeeSansPastilleDeTaille() throws {
        let c = try #require(Self.cas.first { $0["id"] as? String == "cas-02" })
        let r = Self.controle(try #require(c["entree"] as? [String: Any]))
        guard case .reglementation = BlocReglesLogique.tete(lignes: r.lignes, consigne: r.consigne, especeConfirmee: true) else {
            Issue.record("65 cm : « Voir la réglementation » attendu"); return
        }
        let groupes = BlocReglesLogique.groupes(r.lignes).map(\.groupe)
        #expect(groupes.contains(.garderOuRelacher))
        #expect(groupes.contains(.materielEtPratique))
        #expect(r.lignes.first { $0.type == .taille }?.etat == .respectee)
    }

    @Test func brochet59ALaPastilleEtLaConsigneToise() throws {
        let c = try #require(Self.cas.first { $0["id"] as? String == "cas-03" })
        let r = Self.controle(try #require(c["entree"] as? [String: Any]))
        #expect(BlocReglesLogique.tete(lignes: r.lignes, consigne: r.consigne, especeConfirmee: true) == .reglementation(aVerifier: true))
        #expect(r.lignes.first { $0.type == .taille }?.etat == .aVerifierSurPlace)
        #expect(BlocReglesLogique.consigneSousLeTitre(lignes: r.lignes, consigne: r.consigne) == "Mesure-la sur une toise")
    }
}
