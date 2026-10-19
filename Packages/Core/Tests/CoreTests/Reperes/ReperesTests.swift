import Foundation
import Testing
@testable import Core

// Critères 1, 3, 6, 7 et 8 de la fiche N6. Écrits sans compilateur : non exécutés.

private let metresParDegre = 6_371_008.8 * Double.pi / 180

private func repere(_ n: Int, nom: String = "Poste", lat: Double = 48.0, lon: Double = 2.0, supprime: Date? = nil,
                    modifie: Date? = nil) -> Repere {
    let id = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", n))!
    return Repere(id: id, nom: nom, position: Coordonnee(latitude: lat, longitude: lon),
                  cree: Date(timeIntervalSince1970: 1_000), modifie: modifie, supprime: supprime)
}

@Suite("Repères : offre et plafonds")
struct OffreReperesTests {
    @Test("Critère 1 : 3 gratuits, illimité en Pro jusqu'au plafond technique")
    func peutAjouter() {
        #expect(ReglesReperes.peutAjouter(actifs: 0, abonne: false) == .oui)
        #expect(ReglesReperes.peutAjouter(actifs: 2, abonne: false) == .oui)
        #expect(ReglesReperes.peutAjouter(actifs: 3, abonne: false) == .paywall)
        #expect(ReglesReperes.peutAjouter(actifs: 3, abonne: true) == .oui)
        #expect(ReglesReperes.peutAjouter(actifs: 300, abonne: true) == .plafond)
    }

    @Test("Critère 1 : les pierres tombales ne comptent pas")
    func pierresTombales() {
        let t = Date(timeIntervalSince1970: 5_000)
        let quatre = [repere(1), repere(2), repere(3, supprime: t), repere(4, supprime: t)]
        let actifs = ReglesReperes.actifs(dans: quatre)
        #expect(actifs == 2)
        #expect(ReglesReperes.peutAjouter(actifs: actifs, abonne: false) == .oui)
    }
}

@Suite("Repères : validation")
struct ValidationReperesTests {
    @Test("Critère 8 : nom vide ou d'espaces refusé")
    func nomVide() {
        #expect(throws: ErreurRepere.nomVide) { try Repere.valide(nom: "", note: "") }
        #expect(throws: ErreurRepere.nomVide) { try Repere.valide(nom: "   \n", note: "") }
        #expect(Repere.nomPropre("  ") == nil)
    }

    @Test("Critère 8 : 40 caractères acceptés, 41 refusés, jamais tronqués")
    func nomTropLong() throws {
        let quarante = String(repeating: "a", count: 40)
        #expect(try Repere.valide(nom: quarante, note: "").nom == quarante)
        #expect(throws: ErreurRepere.nomTropLong) { try Repere.valide(nom: quarante + "a", note: "") }
        #expect(Repere.nomPropre(quarante + "a") == nil)
    }

    @Test("Critère 8 : note de 500 acceptée, 501 refusée")
    func noteTropLongue() throws {
        _ = try Repere.valide(nom: "Poste", note: String(repeating: "n", count: 500))
        #expect(throws: ErreurRepere.noteTropLongue) { try Repere.valide(nom: "Poste", note: String(repeating: "n", count: 501)) }
    }

    @Test("Critère 8 : un émoji compte pour un caractère et il est accepté")
    func emoji() throws {
        let s = try Repere.valide(nom: "  Poste 🎣  ", note: "Fond vaseux 🐟")
        #expect(s.nom == "Poste 🎣")
        #expect(s.note == "Fond vaseux 🐟")
    }

    @Test("Le nom est rogné")
    func nomRogne() {
        #expect(Repere.nomPropre("  Poste  ") == "Poste")
    }
}

@Suite("Repères : proximité, passage, zone floue")
struct ProximiteReperesTests {
    private func decale(_ lat: Double, metres: Double) -> Double { lat + metres / metresParDegre }

    @Test("Critère 7 : 149 m trouvé, 151 m non")
    func rayon() {
        let r = repere(1, lat: 48.0, lon: 2.0)
        #expect(RepereProche.plusProche(de: Coordonnee(latitude: decale(48.0, metres: 149), longitude: 2.0), dans: [r])?.id == r.id)
        #expect(RepereProche.plusProche(de: Coordonnee(latitude: decale(48.0, metres: 151), longitude: 2.0), dans: [r]) == nil)
    }

    @Test("Critère 7 : le plus proche de deux candidats")
    func plusProche() {
        let loin = repere(1, lat: decale(48.0, metres: 100), lon: 2.0)
        let pres = repere(2, lat: decale(48.0, metres: 20), lon: 2.0)
        #expect(RepereProche.plusProche(de: Coordonnee(latitude: 48.0, longitude: 2.0), dans: [loin, pres])?.id == pres.id)
    }

    @Test("Critère 7 : ignore les pierres tombales")
    func ignoreSupprimes() {
        let mort = repere(1, supprime: Date(timeIntervalSince1970: 5_000))
        #expect(RepereProche.plusProche(de: Coordonnee(latitude: 48.0, longitude: 2.0), dans: [mort]) == nil)
    }

    @Test("Dernier passage : le plus récent entre le passage noté et les prises rattachées")
    func dernierPassage() {
        let prise = Prise(espece: Espece(id: "brochet", codeSandre: nil), date: Date(timeIntervalSince1970: 3_000))
        let autre = Prise(espece: Espece(id: "perche", codeSandre: nil), date: Date(timeIntervalSince1970: 9_000))
        var r = repere(1)
        #expect(r.dernierPassage(prises: [prise]) == nil)
        r.idsPrises = [prise.id]
        #expect(r.dernierPassage(prises: [prise, autre]) == Date(timeIntervalSince1970: 3_000))
        r.passageManuel = Date(timeIntervalSince1970: 4_000)
        #expect(r.dernierPassage(prises: [prise, autre]) == Date(timeIntervalSince1970: 4_000))
    }

    @Test("Critère 6 : zone floue idempotente, au plus 2 décimales, 2 valeurs pour 2 points à moins de 500 m")
    func zoneFloue() {
        let a = Coordonnee(latitude: 48.8566, longitude: 2.3522)
        let r = ZoneFloue.arrondi(a)
        #expect(ZoneFloue.arrondi(r) == r)
        for v in [r.latitude, r.longitude] {
            #expect(abs(v * 100 - (v * 100).rounded()) < 1e-9)
        }
        var valeurs = Set<Double>()
        for pas in stride(from: 0.0, through: 500.0, by: 25.0) {
            valeurs.insert(ZoneFloue.arrondi(Coordonnee(latitude: 48.8540 + pas / metresParDegre, longitude: 2.3522)).latitude)
        }
        #expect(valeurs.count <= 2)
    }
}

@Suite("Repères : fichier")
struct CodecReperesTests {
    @Test("Critère 3 : aller-retour exact sur 50 repères")
    func allerRetour() throws {
        var liste: [Repere] = []
        for n in 1...50 {
            var r = repere(n, nom: "Poste \(n) 🎣", lat: 45.0 + Double(n) / 1000, lon: 1.5 - Double(n) / 777)
            r.note = "Note \(n)"
            r.icone = IconeRepere.allCases[n % IconeRepere.allCases.count]
            r.photos = ["\(n).jpg"]
            r.idsPrises = [UUID()]
            r.passageManuel = n % 2 == 0 ? Date(timeIntervalSince1970: 2_000 + Double(n)) : nil
            r.supprime = n % 10 == 0 ? Date(timeIntervalSince1970: 7_000) : nil
            liste.append(r)
        }
        let relu = try CodecReperes.decoder(CodecReperes.encoder(liste))
        #expect(relu == liste)
    }

    @Test("Critère 3 : un fichier d'une version future est refusé, pas lu comme vide")
    func versionFuture() {
        let json = #"{"version": 99, "reperes": [], "autre": true}"#
        #expect(throws: ErreurCodecReperes.versionFuture(99)) { try CodecReperes.decoder(Data(json.utf8)) }
    }

    @Test("Critère 3 : un JSON tronqué donne une erreur, pas un tableau vide")
    func tronque() {
        let complet = CodecReperes.encoder([repere(1), repere(2)])
        let coupe = complet.prefix(complet.count / 2)
        #expect(throws: ErreurCodecReperes.illisible) { try CodecReperes.decoder(Data(coupe)) }
        #expect(throws: ErreurCodecReperes.illisible) { try CodecReperes.decoder(Data()) }
    }

    @Test("Liste vide : relue vide, sans erreur")
    func vide() throws {
        #expect(try CodecReperes.decoder(CodecReperes.encoder([])).isEmpty)
    }

    @Test("Les clés sont triées : deux encodages donnent les mêmes octets")
    func stable() {
        let liste = [repere(1), repere(2)]
        #expect(CodecReperes.encoder(liste) == CodecReperes.encoder(liste))
    }
}
