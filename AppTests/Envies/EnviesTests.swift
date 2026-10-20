import Core
import Foundation
import Testing
@testable import BuildChallenge

// Tests écrits, non exécutés : à lancer sur Mac.

private final class StockageEnviesMemoire: StockageEnvies, @unchecked Sendable {
    private let verrou = NSLock()
    private var contenu: ListeEnvies
    private(set) var nbEcritures = 0

    init(_ contenu: ListeEnvies = ListeEnvies()) { self.contenu = contenu }

    func lire() -> ListeEnvies {
        verrou.lock(); defer { verrou.unlock() }
        return contenu
    }

    func ecrire(_ liste: ListeEnvies) {
        verrou.lock(); defer { verrou.unlock() }
        contenu = liste
        nbEcritures += 1
    }
}

@MainActor
struct EnviesAppTests {
    private func pechable(_ id: String, nom: String, statuts: Set<StatutEspece> = []) -> EspecePechable {
        EspecePechable(espece: Espece(id: id), nom: nom, nomLatin: "Latinus", image: id, statuts: statuts)
    }

    private var especes: [EspecePechable] {
        [pechable("brochet", nom: "Brochet"), pechable("sandre", nom: "Sandre"),
         pechable("esturgeon-europeen", nom: "Esturgeon européen", statuts: [.protegee])]
    }

    private func carte(_ id: String) -> Prise {
        Prise(espece: Espece(id: id), date: Date(timeIntervalSince1970: 1_000))
    }

    @Test func basculerAjouteEtRetire() {
        let stockage = StockageEnviesMemoire()
        let modele = EnviesModele(stockage: stockage, especes: especes)
        modele.basculer(especes[0])
        #expect(modele.contient(especes[0]))
        #expect(modele.nombre == 1)
        #expect(stockage.lire().contient(Espece(id: "brochet")))
        modele.basculer(especes[0])
        #expect(!modele.contient(especes[0]))
        #expect(modele.nombre == 0)
    }

    @Test func uneEspeceProtegeeNeSeMarquePas() {
        let stockage = StockageEnviesMemoire()
        let modele = EnviesModele(stockage: stockage, especes: especes)
        #expect(!modele.peutAfficherBouton(especes[2]))
        modele.basculer(especes[2])
        #expect(modele.nombre == 0)
        #expect(stockage.nbEcritures == 0)
    }

    @Test func chargerFaitSortirLesEspecesAvecUneCarte() {
        let stockage = StockageEnviesMemoire()
        let modele = EnviesModele(stockage: stockage, especes: especes)
        modele.basculer(especes[0])
        modele.basculer(especes[1])
        modele.charger(cartes: [carte("brochet")])
        #expect(!modele.contient(especes[0]))
        #expect(modele.contient(especes[1]))
        #expect(!modele.peutAfficherBouton(especes[0]))
        #expect(!stockage.lire().contient(Espece(id: "brochet")))
    }

    @Test func chargerSansChangementNEcritPas() {
        let stockage = StockageEnviesMemoire()
        let modele = EnviesModele(stockage: stockage, especes: especes)
        modele.basculer(especes[0])
        let avant = stockage.nbEcritures
        modele.charger(cartes: [carte("sandre")])
        #expect(stockage.nbEcritures == avant)
    }

    @Test func uneEnvieVersUneEspeceInconnueEstIgnoreeSansEtreEffacee() {
        var liste = ListeEnvies()
        liste.ajouter(Espece(id: "espece-retiree"), le: Date(timeIntervalSince1970: 10))
        liste.ajouter(Espece(id: "brochet"), le: Date(timeIntervalSince1970: 20))
        let stockage = StockageEnviesMemoire(liste)
        let modele = EnviesModele(stockage: stockage, especes: especes)
        #expect(modele.nombre == 1)
        #expect(modele.resumes(ordre: .recentes).map(\.espece.espece.id) == ["brochet"])
        #expect(modele.liste.actives.count == 2)
    }

    @Test func sansSpotLesResumesDisentSansSpot() {
        let modele = EnviesModele(stockage: StockageEnviesMemoire(), especes: especes)
        modele.basculer(especes[0])
        #expect(modele.resumes(ordre: .ouvertesDAbord).first?.ouverture == .sansSpot)
    }

    @Test func lesClosuresExternesAlimententLeResume() {
        let source = SourceRegle(titre: "Arrêté", url: nil)
        var externes = EnviesExternes()
        externes.controle = { _, _ in
            ResultatControle(lignes: [LigneControle(type: .periode, etat: .respectee, phrase: "ouverte", sources: [source]),
                                      LigneControle(type: .taille, etat: .information, phrase: "Taille minimale 60 cm", sources: [source])],
                             consigne: .verifieLArrete)
        }
        externes.conseil = { _ in Conseil(texte: "Texte", icone: "fish", source: source, gratuit: true) }
        let modele = EnviesModele(stockage: StockageEnviesMemoire(), especes: especes, externes: externes)
        modele.basculer(especes[0])
        let r = modele.resumes(ordre: .ouvertesDAbord)
        #expect(r.first?.ouverture == .ouverte(source))
        #expect(r.first?.taille == "Taille minimale 60 cm")
        #expect(r.first?.conseil?.texte == "Texte")
    }

    @Test func textesDOuverture() {
        let paris = TimeZone(identifier: "Europe/Paris")!
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = paris
        let avril = calendrier.date(from: DateComponents(year: 2027, month: 4, day: 25, hour: 12))!
        #expect(TextesEnvies.ouverture(.ouverte(nil)) == "Ouverte aujourd'hui")
        #expect(TextesEnvies.ouverture(.fermee(reouverture: avril, nil)) == "Fermée jusqu'au 25/04")
        #expect(TextesEnvies.ouverture(.fermee(reouverture: nil, nil)) == "Fermée ce jour")
        #expect(TextesEnvies.ouverture(.aVerifier) == "Vérifie l'arrêté")
        #expect(TextesEnvies.ouverture(.sansSpot) == "Choisis un spot pour voir l'ouverture")
    }

    @Test func ligneDuPescedex() {
        #expect(TextesEnvies.ligneDuPescedex(nombre: 3) == "Mes envies · 3")
    }

    @Test func aucunMotInterditDansLesTextes() {
        let textes = [TextesEnvies.titre, TextesEnvies.jeVeuxLaPecher, TextesEnvies.dansMesEnvies, TextesEnvies.choisirUnSpot,
                      TextesEnvies.videPhrase, TextesEnvies.conseilDuMois]
            + OrdreEnvies.allCases.map(TextesEnvies.libelle)
        let interdits = ["chance", "bon " + "spot", "meil" + "leur", "garanti", "coup sûr", "garder", "autorisé", "po" + "k"]
        for t in textes {
            for mot in interdits { #expect(!t.lowercased().contains(mot), "« \(t) » contient « \(mot) »") }
        }
    }
}
