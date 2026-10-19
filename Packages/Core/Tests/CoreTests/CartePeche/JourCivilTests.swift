import Foundation
import Testing
@testable import Core

@Suite("Carte de pêche : JourCivil")
struct JourCivilTests {
    private func jour(_ a: Int, _ m: Int, _ j: Int) throws -> JourCivil {
        try #require(JourCivil(annee: a, mois: m, jour: j))
    }

    @Test("Un jour qui n'existe pas est refusé")
    func jourInexistant() {
        #expect(JourCivil(annee: 2026, mois: 2, jour: 30) == nil)
        #expect(JourCivil(annee: 2027, mois: 2, jour: 29) == nil)
        #expect(JourCivil(annee: 2026, mois: 13, jour: 1) == nil)
        #expect(JourCivil(annee: 2026, mois: 4, jour: 31) == nil)
        #expect(JourCivil(annee: 2026, mois: 1, jour: 0) == nil)
    }

    @Test("29 février : seulement les années bissextiles")
    func bissextile() {
        #expect(JourCivil(annee: 2028, mois: 2, jour: 29) != nil)
        #expect(JourCivil(annee: 2100, mois: 2, jour: 29) == nil)
        #expect(JourCivil(annee: 2000, mois: 2, jour: 29) != nil)
    }

    @Test("Ajouter 30 jours au 31 janvier")
    func ajouterDepuisJanvier() throws {
        #expect(try jour(2026, 1, 31).ajouter(jours: 30) == jour(2026, 3, 2))
        #expect(try jour(2028, 1, 31).ajouter(jours: 30) == jour(2028, 3, 1))
    }

    @Test("Ajouter 30 jours au 31 décembre passe l'année")
    func ajouterDepuisDecembre() throws {
        #expect(try jour(2026, 12, 31).ajouter(jours: 30) == jour(2027, 1, 30))
    }

    @Test("Retirer des jours")
    func retirer() throws {
        #expect(try jour(2027, 3, 15).ajouter(jours: -30) == jour(2027, 2, 13))
        #expect(try jour(2028, 3, 1).ajouter(jours: -1) == jour(2028, 2, 29))
        #expect(try jour(2026, 1, 1).ajouter(jours: -1) == jour(2025, 12, 31))
    }

    @Test("Jours entre deux dates, dans les deux sens")
    func joursEntre() throws {
        let a = try jour(2026, 10, 19)
        let b = try jour(2026, 12, 31)
        #expect(a.jours(jusqua: b) == 73)
        #expect(b.jours(jusqua: a) == -73)
        #expect(a.jours(jusqua: a) == 0)
        #expect(try jour(2028, 2, 28).jours(jusqua: jour(2028, 3, 1)) == 2)
    }

    @Test("Le 1er janvier 1970 est le jour zéro")
    func origine() throws {
        let zero = try jour(1970, 1, 1)
        #expect(zero.numeroDeJour == 0)
        #expect(JourCivil.depuisNumero(0) == zero)
    }

    @Test("Aller-retour sur plusieurs années")
    func allerRetour() throws {
        var courant = try jour(2024, 1, 1)
        for _ in 0..<2_000 {
            let suivant = courant.ajouter(jours: 1)
            #expect(courant.jours(jusqua: suivant) == 1)
            #expect(suivant > courant)
            courant = suivant
        }
    }

    @Test("Ordre")
    func ordre() throws {
        #expect(try jour(2026, 12, 31) < jour(2027, 1, 1))
        #expect(try jour(2026, 5, 2) > jour(2026, 5, 1))
    }

    @Test("Texte et ISO")
    func texte() throws {
        let j = try jour(2026, 3, 2)
        #expect(j.texte == "02/03/2026")
        #expect(j.iso == "2026-03-02")
        #expect(JourCivil(iso: "2026-03-02") == j)
        #expect(JourCivil(iso: "2026-3-2") == nil)
        #expect(JourCivil(iso: "2026-02-30") == nil)
        #expect(JourCivil(iso: "n'importe quoi") == nil)
    }

    @Test("Codable : aller-retour, et un jour inexistant est refusé")
    func codable() throws {
        let j = try jour(2026, 12, 31)
        let donnees = try JSONEncoder().encode(j)
        #expect(try JSONDecoder().decode(JourCivil.self, from: donnees) == j)
        let faux = Data(#"{"annee":2026,"mois":2,"jour":30}"#.utf8)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(JourCivil.self, from: faux) }
    }

    @Test("Depuis une Date, dans le calendrier donné")
    func depuisDate() throws {
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = try #require(TimeZone(identifier: "Europe/Paris"))
        // 31/12/2026 23:30 à Paris = 22:30 UTC : le jour civil à Paris reste le 31.
        let date = try #require(calendrier.date(from: DateComponents(year: 2026, month: 12, day: 31, hour: 23, minute: 30)))
        let attendu = try jour(2026, 12, 31)
        #expect(JourCivil(date: date, calendrier: calendrier) == attendu)
        let midi = try #require(jour(2026, 12, 31).date(calendrier: calendrier))
        #expect(JourCivil(date: midi, calendrier: calendrier) == attendu)
    }
}
