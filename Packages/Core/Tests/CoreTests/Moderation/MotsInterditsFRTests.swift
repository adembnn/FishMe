import Testing
@testable import Core

@Suite("Mots interdits (français)")
struct MotsInterditsFRTests {
    @Test(arguments: ["connard", "Connard !", "C0nnard", "tu es un c o n n a r d", "c-o-n-n-a-r-d", "connaaard", "FDP", "ntm",
                      "sale pute", "Fils de pute", "nique ta mère", "trou du cul", "quel con", "BORDEL"])
    func refuseCesTextes(_ texte: String) {
        #expect(MotsInterditsFR.contient(texte), "« \(texte) » devrait être refusé")
    }

    /// Mots de pêche et de langage courant qui ne doivent JAMAIS être refusés.
    @Test(arguments: ["Une belle tanche de 40 cm", "Quelle bite ! Une touche franche", "il a la gueule ouverte", "l'eau coule doucement",
                      "une gerbe d'eau", "perche, sandre, brochet et carpe", "concours de pêche", "turlutte pour le calamar",
                      "pédale du kayak", "cul-de-sac au bord de l'étang", "classe", "Compote de pommes", "scunthorpe", "assis au bord",
                      "gros-brochet", "pecheur du dimanche", "Un grand merci", "mère et père", "la touche de Fabien"])
    func accepteCesTextes(_ texte: String) {
        #expect(!MotsInterditsFR.contient(texte), "« \(texte) » ne devrait pas être refusé")
    }

    @Test func coulerNEstPasCouille() {
        #expect(!MotsInterditsFR.contient("coule"))
        #expect(!MotsInterditsFR.contient("coules"))
        #expect(MotsInterditsFR.contient("couilles"))
    }

    @Test func laListeEstEnMinusculesSansAccents() {
        for mot in MotsInterditsFR.mots {
            #expect(mot == mot.lowercased(), "« \(mot) » doit être en minuscules")
            #expect(mot.allSatisfy { $0.isLetter && $0.isASCII }, "« \(mot) » doit être sans accent ni espace")
        }
        for expression in MotsInterditsFR.expressions {
            for mot in expression {
                #expect(mot == mot.lowercased() && mot.allSatisfy { $0.isLetter && $0.isASCII }, "« \(mot) » mal formé")
            }
        }
    }

    @Test func lesMotsDePecheSontAbsentsDeLaListe() {
        let faussesAlertes: Set<String> = ["tanche", "bite", "bitte", "gueule", "gerbe", "gerber", "suce", "pedale", "turlutte",
                                           "turlute", "cul", "folle", "bander", "pipi", "caca", "pisser", "peter", "etron", "baiser"]
        #expect(MotsInterditsFR.mots.isDisjoint(with: faussesAlertes))
    }

    @Test func etirementNeCasseQueLesSuitesDeTroisLettres() {
        #expect(MotsInterditsFR.etirement("connaaard") == "connard")
        #expect(MotsInterditsFR.etirement("couille") == "couille")
        #expect(MotsInterditsFR.etirement("coool") == "col")
        #expect(MotsInterditsFR.etirement("") == "")
    }
}
