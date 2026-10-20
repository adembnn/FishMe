import Foundation
import Testing
@testable import Core

// Tests écrits, non exécutés (pas de compilateur Swift sur la machine de B).

private let jour: TimeInterval = 86_400
private func date(_ j: Double) -> Date { Date(timeIntervalSince1970: j * jour) }

private func pechable(_ id: String, nom: String? = nil, statuts: Set<StatutEspece> = []) -> EspecePechable {
    EspecePechable(espece: Espece(id: id), nom: nom ?? id.capitalized, nomLatin: "Latinus \(id)", image: id, statuts: statuts)
}

private func carte(_ id: String, origine: OrigineCarte = .priseReelle, exemple: Bool = false) -> Prise {
    Prise(espece: Espece(id: id), origine: origine, date: date(5), exemple: exemple)
}

private let brochet = Espece(id: "brochet")
private let sandre = Espece(id: "sandre")
private let tanche = Espece(id: "tanche")

@Suite("Envies : la liste")
struct ListeEnviesTests {
    @Test("Ajouter deux fois la même espèce donne une seule envie active")
    func ajoutIdempotent() {
        var l = ListeEnvies()
        l.ajouter(brochet, le: date(1))
        l.ajouter(brochet, le: date(2))
        #expect(l.actives.count == 1)
        #expect(l.envies.count == 1)
        #expect(l.actives[0].ajoutee == date(1))
        #expect(l.contient(brochet))
    }

    @Test("Retirer puis ajouter réactive l'envie")
    func reactivation() {
        var l = ListeEnvies()
        l.ajouter(brochet, le: date(1))
        l.retirer(brochet, le: date(2))
        #expect(!l.contient(brochet))
        #expect(l.envies.count == 1)
        #expect(l.envies[0].motif == .retireeParLePecheur)
        l.ajouter(brochet, le: date(3))
        #expect(l.contient(brochet))
        #expect(l.envies.count == 1)
        #expect(l.envies[0].retiree == nil)
        #expect(l.envies[0].motif == nil)
    }

    @Test("Retirer une espèce absente ne crée rien")
    func retirerAbsente() {
        var l = ListeEnvies()
        l.retirer(brochet, le: date(2))
        #expect(l.envies.isEmpty)
    }

    @Test("Une vraie prise retire l'envie, avec son motif")
    func exauceeParPrise() {
        var l = ListeEnvies()
        l.ajouter(brochet, le: date(1))
        l.ajouter(sandre, le: date(1))
        let change = l.retirerLesExaucees(cartes: [carte("brochet", origine: .priseReelle)], le: date(9))
        #expect(change)
        #expect(!l.contient(brochet))
        #expect(l.contient(sandre))
        #expect(l.envies.first { $0.espece == "brochet" }?.motif == .pecheeLaCarteEstAuPescedex)
        #expect(l.envies.first { $0.espece == "brochet" }?.retiree == date(9))
    }

    @Test("Une carte déclarée retire aussi l'envie")
    func exauceeParDeclaration() {
        var l = ListeEnvies()
        l.ajouter(sandre, le: date(1))
        l.retirerLesExaucees(cartes: [carte("sandre", origine: .declaree)], le: date(9))
        #expect(!l.contient(sandre))
        #expect(l.envies[0].motif == .pecheeLaCarteEstAuPescedex)
    }

    @Test("La carte d'exemple ne retire pas l'envie")
    func exempleIgnoree() {
        var l = ListeEnvies()
        l.ajouter(brochet, le: date(1))
        let change = l.retirerLesExaucees(cartes: [carte("brochet", exemple: true)], le: date(9))
        #expect(!change)
        #expect(l.contient(brochet))
    }

    @Test("Aucune carte : rien ne change")
    func aucuneCarte() {
        var l = ListeEnvies()
        l.ajouter(brochet, le: date(1))
        let avant = l
        let retiree = l.retirerLesExaucees(cartes: [], le: date(9))
        #expect(!retiree)
        #expect(l == avant)
    }

    @Test("Une espèce protégée ne peut pas être marquée")
    func protegee() {
        #expect(!ListeEnvies.peutEtreMarquee(pechable("esturgeon-europeen", statuts: [.protegee]), cartes: []))
    }

    @Test("Une espèce toujours relâchée ne peut pas être marquée")
    func toujoursRelachee() {
        #expect(!ListeEnvies.peutEtreMarquee(pechable("x", statuts: [.toujoursRelachee]), cartes: []))
    }

    @Test("Une espèce dont le stade se demande ne peut pas être marquée")
    func stadeADemander() {
        #expect(!ListeEnvies.peutEtreMarquee(pechable("anguille-jaune", statuts: [.stadeADemander]), cartes: []))
    }

    @Test("Une espèce qui a déjà une carte ne peut pas être marquée ; la carte d'exemple n'y change rien")
    func dejaAuPescedex() {
        let b = pechable("brochet")
        #expect(!ListeEnvies.peutEtreMarquee(b, cartes: [carte("brochet")]))
        #expect(!ListeEnvies.peutEtreMarquee(b, cartes: [carte("brochet", origine: .declaree)]))
        #expect(ListeEnvies.peutEtreMarquee(b, cartes: [carte("brochet", exemple: true)]))
        #expect(ListeEnvies.peutEtreMarquee(b, cartes: [carte("sandre")]))
    }

    @Test("Une espèce envahissante peut être marquée")
    func envahissante() {
        #expect(ListeEnvies.peutEtreMarquee(pechable("silure-glane", statuts: [.envahissante]), cartes: []))
    }

    @Test("Deux entrées de la même espèce se réduisent à une seule à la construction")
    func dedoublonnage() {
        let l = ListeEnvies(envies: [Envie(espece: "brochet", ajoutee: date(1)),
                                     Envie(espece: "brochet", ajoutee: date(1), retiree: date(4), motif: .retireeParLePecheur)])
        #expect(l.envies.count == 1)
        #expect(!l.contient(brochet))
    }
}

@Suite("Envies : fusion entre deux iPhones")
struct FusionEnviesTests {
    @Test("Ajoutée sur l'un, retirée plus tard sur l'autre : elle reste retirée")
    func retireePlusTard() {
        var a = ListeEnvies(); a.ajouter(brochet, le: date(1))
        var b = a; b.retirer(brochet, le: date(3))
        let f = ListeEnvies.fusionner(a, b)
        #expect(!f.contient(brochet))
        #expect(ListeEnvies.fusionner(b, a) == f)
    }

    @Test("Retirée puis réajoutée plus tard : elle est active")
    func reajouteePlusTard() {
        var a = ListeEnvies(); a.ajouter(brochet, le: date(1)); a.retirer(brochet, le: date(2))
        var b = a; b.ajouter(brochet, le: date(5))
        let f = ListeEnvies.fusionner(a, b)
        #expect(f.contient(brochet))
        #expect(ListeEnvies.fusionner(b, a) == f)
    }

    @Test("Les envies des deux côtés sont réunies, sans doublon, dans un ordre qui ne dépend pas du côté")
    func union() {
        var a = ListeEnvies(); a.ajouter(brochet, le: date(1)); a.ajouter(tanche, le: date(3))
        var b = ListeEnvies(); b.ajouter(sandre, le: date(2)); b.ajouter(brochet, le: date(1))
        let f = ListeEnvies.fusionner(a, b)
        #expect(f.envies.map(\.espece) == ["brochet", "sandre", "tanche"])
        #expect(ListeEnvies.fusionner(b, a) == f)
    }

    @Test("À date égale, la sortie l'emporte")
    func egalite() {
        let active = Envie(espece: "brochet", ajoutee: date(2))
        let sortie = Envie(espece: "brochet", ajoutee: date(1), retiree: date(2), motif: .retireeParLePecheur)
        #expect(!ListeEnvies.fusionner([active], [sortie]).contient(brochet))
        #expect(!ListeEnvies.fusionner([sortie], [active]).contient(brochet))
    }

    @Test("Une liste fusionnée ne dépasse pas une entrée par espèce")
    func uneParEspece() {
        let ids = (0..<101).map { "espece-\($0)" }
        let a = ListeEnvies(envies: ids.map { Envie(espece: $0, ajoutee: date(1)) })
        let b = ListeEnvies(envies: ids.map { Envie(espece: $0, ajoutee: date(1), retiree: date(2), motif: .retireeParLePecheur) })
        #expect(ListeEnvies.fusionner(a, b).envies.count == 101)
    }
}

@Suite("Envies : stockage")
struct StockageEnviesTests {
    private func urlTemporaire() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("envies-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("envies.json")
    }

    @Test("Écrire puis relire rend la même liste, retirées comprises")
    func allerRetour() {
        let url = urlTemporaire()
        var l = ListeEnvies()
        l.ajouter(brochet, le: date(1))
        l.ajouter(sandre, le: date(2))
        l.retirer(sandre, le: date(3))
        let stockage = StockageEnviesFichier(url: url)
        stockage.ecrire(l)
        #expect(stockage.lire() == l)
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    @Test("Fichier absent : liste vide")
    func absent() {
        #expect(StockageEnviesFichier(url: urlTemporaire()).lire() == ListeEnvies())
    }

    @Test("Fichier vide : liste vide")
    func vide() throws {
        let url = urlTemporaire()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data().write(to: url)
        #expect(StockageEnviesFichier(url: url).lire() == ListeEnvies())
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    @Test("Fichier corrompu : liste vide, sans plantage")
    func corrompu() throws {
        let url = urlTemporaire()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{ pas du json".utf8).write(to: url)
        #expect(StockageEnviesFichier(url: url).lire() == ListeEnvies())
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    @Test("Un motif inconnu n'empêche pas de lire la liste")
    func motifInconnu() throws {
        let json = #"{"envies":[{"espece":"brochet","ajoutee":"1970-01-02T00:00:00Z","retiree":"1970-01-03T00:00:00Z","motif":"autreChose"}]}"#
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        let l = try d.decode(ListeEnvies.self, from: Data(json.utf8))
        #expect(l.envies.count == 1)
        #expect(l.envies[0].motif == nil)
        #expect(!l.contient(brochet))
    }

    @Test("Un JSON sans le champ envies se lit comme une liste vide")
    func sansChamp() throws {
        let l = try JSONDecoder().decode(ListeEnvies.self, from: Data("{}".utf8))
        #expect(l == ListeEnvies())
    }
}

@Suite("Envies : résumé d'une envie")
struct ResumeEnvieTests {
    private let source = SourceRegle(titre: "Arrêté préfectoral 2026", url: "https://exemple.invalid/arrete")
    private let autre = SourceRegle(titre: "Code de l'environnement")

    private func ligne(_ type: TypeRegle, _ etat: EtatLigne, _ phrase: String = "phrase", sources: [SourceRegle] = []) -> LigneControle {
        LigneControle(type: type, etat: etat, phrase: phrase, sources: sources)
    }

    private func controle(_ lignes: [LigneControle]) -> ResultatControle {
        ResultatControle(lignes: lignes, consigne: .verifieLArrete)
    }

    private let e = pechable("brochet", nom: "Brochet")

    @Test("Ligne période respectée : ouverte, avec sa source")
    func ouverte() {
        let r = ResumeEnvie.construire(espece: e, controle: controle([ligne(.periode, .respectee, sources: [source])]), conseil: nil)
        #expect(r.ouverture == .ouverte(source))
    }

    @Test("Ligne période non respectée : fermée, avec la date de réouverture donnée")
    func fermee() {
        let r = ResumeEnvie.construire(espece: e, controle: controle([ligne(.periode, .nonRespectee, sources: [source])]),
                                       conseil: nil, reouverture: date(100))
        #expect(r.ouverture == .fermee(reouverture: date(100), source))
    }

    @Test("Ligne période à vérifier sur place : à vérifier")
    func aVerifier() {
        let r = ResumeEnvie.construire(espece: e, controle: controle([ligne(.periode, .aVerifierSurPlace)]), conseil: nil)
        #expect(r.ouverture == .aVerifier)
    }

    @Test("Aucune ligne période, ou une ligne d'information : à vérifier")
    func aucuneLignePeriode() {
        #expect(ResumeEnvie.construire(espece: e, controle: controle([]), conseil: nil).ouverture == .aVerifier)
        #expect(ResumeEnvie.construire(espece: e, controle: controle([ligne(.periode, .information)]), conseil: nil).ouverture == .aVerifier)
        #expect(ResumeEnvie.construire(espece: e, controle: controle([ligne(.taille, .respectee)]), conseil: nil).ouverture == .aVerifier)
    }

    @Test("Sans contrôle : sans spot, et le conseil est gardé")
    func sansSpot() {
        let conseil = Conseil(texte: "Texte", icone: "fish", source: source, gratuit: true)
        let r = ResumeEnvie.construire(espece: e, controle: nil, conseil: conseil)
        #expect(r.ouverture == .sansSpot)
        #expect(r.taille == nil)
        #expect(r.conseil == conseil)
    }

    @Test("Des lignes qui se contredisent : la plus prudente gagne")
    func prudence() {
        let r1 = ResumeEnvie.construire(espece: e, controle: controle([ligne(.periode, .respectee), ligne(.periode, .aVerifierSurPlace)]), conseil: nil)
        #expect(r1.ouverture == .aVerifier)
        let r2 = ResumeEnvie.construire(espece: e, controle: controle([ligne(.periode, .respectee), ligne(.periode, .nonRespectee)]), conseil: nil)
        if case .fermee = r2.ouverture {} else { Issue.record("attendu : fermée") }
    }

    @Test("La phrase de la ligne taille est reprise caractère pour caractère, avec ses sources")
    func taille() {
        let phrase = "Taille minimale 60 cm (arrêté préfectoral) \u{00B7} mesure-la sur une toise"
        let r = ResumeEnvie.construire(
            espece: e, controle: controle([ligne(.periode, .respectee), ligne(.taille, .information, phrase, sources: [source, autre])]),
            conseil: nil)
        #expect(r.taille == phrase)
        #expect(r.sourceTaille == source)
        #expect(r.sourcesTaille == [source, autre])
    }

    @Test("Pas de ligne taille : rien n'est inventé")
    func pasDeTaille() {
        let r = ResumeEnvie.construire(espece: e, controle: controle([ligne(.periode, .respectee)]), conseil: nil)
        #expect(r.taille == nil)
        #expect(r.sourceTaille == nil)
        #expect(r.sourcesTaille.isEmpty)
    }
}

@Suite("Envies : tri")
struct TriEnviesTests {
    private func resume(_ id: String, nom: String, _ ouverture: StatutOuverture) -> ResumeEnvie {
        ResumeEnvie(espece: pechable(id, nom: nom), ouverture: ouverture)
    }

    private func liste(_ paires: [(String, Double)]) -> ListeEnvies {
        ListeEnvies(envies: paires.map { Envie(espece: $0.0, ajoutee: date($0.1)) })
    }

    private let ouverte = StatutOuverture.ouverte(nil)
    private let fermee = StatutOuverture.fermee(reouverture: nil, nil)

    @Test("Ouvertes d'abord : ouvertes, à vérifier, fermées ; à égalité la plus récente, puis A à Z")
    func ouvertesDAbord() {
        let l = liste([("a", 1), ("b", 2), ("c", 3), ("d", 3), ("e", 4)])
        let rs = [resume("a", nom: "Anguille", fermee), resume("b", nom: "Brochet", ouverte), resume("c", nom: "Carpe", ouverte),
                  resume("d", nom: "Black-bass", ouverte), resume("e", nom: "Esox", .aVerifier)]
        let t = ResumeEnvie.trier(rs, ordre: .ouvertesDAbord, liste: l)
        #expect(t.map(\.espece.espece.id) == ["d", "c", "b", "e", "a"])
    }

    @Test("Récentes : la dernière ajoutée en tête")
    func recentes() {
        let l = liste([("a", 1), ("b", 3), ("c", 2)])
        let rs = [resume("a", nom: "A", ouverte), resume("b", nom: "B", fermee), resume("c", nom: "C", ouverte)]
        #expect(ResumeEnvie.trier(rs, ordre: .recentes, liste: l).map(\.espece.espece.id) == ["b", "c", "a"])
    }

    @Test("A à Z : sans tenir compte des accents ni de la casse")
    func alphabetique() {
        let l = liste([("a", 1), ("b", 2), ("c", 3)])
        let rs = [resume("a", nom: "tanche", ouverte), resume("b", nom: "Écrevisse", ouverte), resume("c", nom: "Brochet", ouverte)]
        #expect(ResumeEnvie.trier(rs, ordre: .alphabetique, liste: l).map(\.espece.espece.id) == ["c", "b", "a"])
    }

    @Test("Le tri est stable : deux noms identiques restent dans l'ordre d'entrée")
    func stable() {
        let l = liste([("a", 1), ("b", 1)])
        let rs = [resume("a", nom: "Même", ouverte), resume("b", nom: "Même", ouverte)]
        for ordre in OrdreEnvies.allCases {
            #expect(ResumeEnvie.trier(rs, ordre: ordre, liste: l).map(\.espece.espece.id) == ["a", "b"])
        }
    }

    @Test("Aucun tri ne dépend de la rareté ni d'une probabilité : les sources de Core/Envies n'y touchent pas")
    func pasDeRarete() throws {
        let dossier = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/Core/Envies")
        let fichiers = try FileManager.default.contentsOfDirectory(at: dossier, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        #expect(!fichiers.isEmpty)
        for f in fichiers {
            let texte = try String(contentsOf: f, encoding: .utf8).lowercased()
            #expect(!texte.contains("rarete"), "\(f.lastPathComponent) cite la rareté")
            #expect(!texte.contains("niveauraret"), "\(f.lastPathComponent) cite un niveau de rareté")
        }
    }
}

@Suite("Envies : mots interdits")
struct MotsEnviesTests {
    @Test("Aucun mot interdit dans Core/Envies")
    func motsInterdits() throws {
        let dossier = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/Core/Envies")
        let interdits = ["chance", "bon " + "spot", "meil" + "leur spot", "garanti", "coup sûr", "tu peux la " + "garder", "autorisé", "po" + "k"]
        let fichiers = try FileManager.default.contentsOfDirectory(at: dossier, includingPropertiesForKeys: nil)
        for f in fichiers where f.pathExtension == "swift" {
            let texte = try String(contentsOf: f, encoding: .utf8).lowercased()
            for mot in interdits {
                #expect(!texte.contains(mot), "\(f.lastPathComponent) contient « \(mot) »")
            }
        }
    }
}
