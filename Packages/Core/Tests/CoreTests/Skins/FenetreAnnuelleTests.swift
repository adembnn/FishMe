import Foundation
import Testing
@testable import Core

/// Outils communs aux tests des skins : calendriers et dates à midi (ou à l'heure voulue).
enum OutilsSkins {
    static func calendrier(_ zone: String = "Europe/Paris") -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: zone)!
        return c
    }

    static func date(_ annee: Int, _ mois: Int, _ jour: Int, heure: Int = 12, minute: Int = 0,
                     calendrier: Calendar = OutilsSkins.calendrier()) -> Date {
        calendrier.date(from: DateComponents(year: annee, month: mois, day: jour, hour: heure, minute: minute))!
    }

    static func contexte(_ date: Date, abonne: Bool = false, progression: ProgressionPecheur = ProgressionPecheur(),
                         defis: Set<IdentifiantSkin> = []) -> ContexteSkin {
        ContexteSkin(date: date, calendrier: calendrier(), abonne: abonne, progression: progression, defisTermines: defis)
    }
}

@Suite("Skins : fenêtre annuelle")
struct FenetreAnnuelleTests {
    let paris = OutilsSkins.calendrier()
    let halloween = FenetreAnnuelle(moisDebut: 10, jourDebut: 15, moisFin: 11, jourFin: 4)
    let noel = FenetreAnnuelle(moisDebut: 12, jourDebut: 1, moisFin: 1, jourFin: 6)

    @Test("Les bornes sont incluses")
    func bornes() {
        #expect(!halloween.contient(OutilsSkins.date(2026, 10, 14), calendrier: paris))
        #expect(halloween.contient(OutilsSkins.date(2026, 10, 15), calendrier: paris))
        #expect(halloween.contient(OutilsSkins.date(2026, 11, 4), calendrier: paris))
        #expect(!halloween.contient(OutilsSkins.date(2026, 11, 5), calendrier: paris))
    }

    @Test("Les bornes tiennent de minuit à 23 h 59")
    func bornesAuxHeuresLimites() {
        #expect(halloween.contient(OutilsSkins.date(2026, 10, 15, heure: 0, minute: 0), calendrier: paris))
        #expect(halloween.contient(OutilsSkins.date(2026, 11, 4, heure: 23, minute: 59), calendrier: paris))
        #expect(!halloween.contient(OutilsSkins.date(2026, 10, 14, heure: 23, minute: 59), calendrier: paris))
    }

    @Test("Noël traverse le 31 décembre")
    func traverseLAnnee() {
        #expect(noel.contient(OutilsSkins.date(2026, 12, 1), calendrier: paris))
        #expect(noel.contient(OutilsSkins.date(2026, 12, 31), calendrier: paris))
        #expect(noel.contient(OutilsSkins.date(2027, 1, 1), calendrier: paris))
        #expect(noel.contient(OutilsSkins.date(2027, 1, 2), calendrier: paris))
        #expect(noel.contient(OutilsSkins.date(2027, 1, 6), calendrier: paris))
        #expect(!noel.contient(OutilsSkins.date(2027, 1, 7), calendrier: paris))
        #expect(!noel.contient(OutilsSkins.date(2026, 11, 30), calendrier: paris))
    }

    @Test("Les thèmes reviennent chaque année : le même jour donne le même résultat")
    func memeJourChaqueAnnee() {
        for annee in 2026...2030 {
            #expect(halloween.contient(OutilsSkins.date(annee, 10, 20), calendrier: paris))
            #expect(!halloween.contient(OutilsSkins.date(annee, 9, 20), calendrier: paris))
            #expect(noel.contient(OutilsSkins.date(annee, 12, 25), calendrier: paris))
        }
    }

    @Test("Le 29 février ne plante pas")
    func vingtNeufFevrier() {
        let truite = FenetreAnnuelle(moisDebut: 3, jourDebut: 1, moisFin: 4, jourFin: 30)
        let bissextile = OutilsSkins.date(2028, 2, 29)
        #expect(!truite.contient(bissextile, calendrier: paris))
        let ouverture = truite.prochaineOuverture(apres: bissextile, calendrier: paris)
        #expect(ouverture == OutilsSkins.date(2028, 3, 1, heure: 0))
        // Une fenêtre qui commence un 29 février : l'année non bissextile saute à la suivante.
        let rare = FenetreAnnuelle(moisDebut: 2, jourDebut: 29, moisFin: 3, jourFin: 5)
        let prochaine = rare.prochaineOuverture(apres: OutilsSkins.date(2026, 6, 1), calendrier: paris)
        #expect(prochaine == OutilsSkins.date(2028, 2, 29, heure: 0))
    }

    @Test("Changement d'heure du 25 octobre 2026 : aucun décalage d'un jour")
    func changementDHeure() {
        // Passage à l'heure d'hiver dans la nuit du 24 au 25 octobre 2026.
        #expect(halloween.contient(OutilsSkins.date(2026, 10, 25, heure: 0, minute: 30), calendrier: paris))
        #expect(halloween.contient(OutilsSkins.date(2026, 10, 25, heure: 23, minute: 30), calendrier: paris))
        let veille = OutilsSkins.date(2026, 10, 14, heure: 23, minute: 59)
        #expect(halloween.prochaineOuverture(apres: veille, calendrier: paris) == OutilsSkins.date(2026, 10, 15, heure: 0))
    }

    @Test("Passage à l'heure d'été du 29 mars 2026 : le 1er mars et le 1er avril restent des jours entiers")
    func changementDHeurePrintemps() {
        let truite = FenetreAnnuelle(moisDebut: 3, jourDebut: 1, moisFin: 4, jourFin: 30)
        #expect(truite.contient(OutilsSkins.date(2026, 3, 29, heure: 1, minute: 59), calendrier: paris))
        #expect(truite.contient(OutilsSkins.date(2026, 3, 29, heure: 3, minute: 0), calendrier: paris))
    }

    @Test("Paris et UTC : même jour calendaire à midi")
    func fuseaux() {
        let utc = OutilsSkins.calendrier("UTC")
        let midiParis = OutilsSkins.date(2026, 10, 15, heure: 12, calendrier: paris)
        let midiUTC = OutilsSkins.date(2026, 10, 15, heure: 12, calendrier: utc)
        #expect(halloween.contient(midiParis, calendrier: paris))
        #expect(halloween.contient(midiUTC, calendrier: utc))
        #expect(!halloween.contient(OutilsSkins.date(2026, 10, 14, heure: 12, calendrier: utc), calendrier: utc))
    }

    @Test("Prochaine ouverture avant la fenêtre")
    func prochaineAvant() {
        let r = halloween.prochaineOuverture(apres: OutilsSkins.date(2026, 10, 14), calendrier: paris)
        #expect(r == OutilsSkins.date(2026, 10, 15, heure: 0))
    }

    @Test("Prochaine ouverture dans la fenêtre : l'année suivante")
    func prochaineDedans() {
        let r = halloween.prochaineOuverture(apres: OutilsSkins.date(2026, 10, 20), calendrier: paris)
        #expect(r == OutilsSkins.date(2027, 10, 15, heure: 0))
        // Le jour même du début : la prochaine est celle de l'an prochain.
        let memeJour = halloween.prochaineOuverture(apres: OutilsSkins.date(2026, 10, 15), calendrier: paris)
        #expect(memeJour == OutilsSkins.date(2027, 10, 15, heure: 0))
    }

    @Test("Prochaine ouverture après la fenêtre")
    func prochaineApres() {
        let r = halloween.prochaineOuverture(apres: OutilsSkins.date(2026, 11, 5), calendrier: paris)
        #expect(r == OutilsSkins.date(2027, 10, 15, heure: 0))
        let n = noel.prochaineOuverture(apres: OutilsSkins.date(2027, 1, 7), calendrier: paris)
        #expect(n == OutilsSkins.date(2027, 12, 1, heure: 0))
    }

    @Test("Prochaine ouverture pendant le 1er janvier de Noël : décembre suivant")
    func prochaineNoelEnJanvier() {
        let n = noel.prochaineOuverture(apres: OutilsSkins.date(2027, 1, 2), calendrier: paris)
        #expect(n == OutilsSkins.date(2027, 12, 1, heure: 0))
    }
}
