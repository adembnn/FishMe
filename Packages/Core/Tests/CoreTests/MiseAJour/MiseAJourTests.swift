import Foundation
import Testing
@testable import Core

// Réseau simulé : `TelechargeFichierFaux` répond avec des fichiers fabriqués ici, rien n'est téléchargé.
// Les fichiers d'essai ont la forme de `donnees.md` ; leur contenu est inventé pour l'essai, ce ne sont pas des règles.

// MARK: - Outils d'essai

private func dossierTemporaire() -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("miseajour-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func json(_ objet: Any) -> Data {
    (try? JSONSerialization.data(withJSONObject: objet, options: [.sortedKeys])) ?? Data()
}

/// Un fichier de règles d'essai, valide.
private func fichier(_ code: String, version: String = "2026-10-15.1", niveau: String = "complet",
                     expireLe: String? = "2026-12-31", especes: [String] = ["2151"],
                     citation: String = "texte cité pour l'essai", type: String = "ouverture",
                     aVerifier: Int = 0) -> Data {
    let regle: [String: Any] = [
        "id": "\(code)-essai-1", "portee": ["niveau": "departement", "code": code, "eau": NSNull(), "lieu": NSNull(), "geometrie": NSNull()],
        "especes": especes, "categorie": "2", "type": type, "valeur": ["texte": "essai"], "du": NSNull(), "au": NSNull(),
        "remplace": NSNull(), "phrase": "Phrase d'essai du \(code).", "textes": ["t1"], "citation": citation,
        "expire_le": expireLe as Any? ?? NSNull(), "statut": "brouillon", "verifie_par": NSNull(),
    ]
    let racine: [String: Any] = [
        "version": version, "departement": code, "niveau": niveau,
        "textes": [["id": "t1", "titre": "Texte d'essai \(code)", "url": "https://exemple.invalid/\(code)", "signe_le": NSNull(),
                    "lu_le": "2026-10-15", "version": "essai"]],
        "eaux": [], "regles": [regle], "a_verifier": Array(repeating: ["id": "x"], count: aVerifier),
    ]
    return json(racine)
}

private func index(_ fichiers: [String: Data], nationalPresent: Bool = false) -> Data {
    var departements: [String: Any] = [:]
    var national: [String: Any]?
    for (code, data) in fichiers {
        let entree: [String: Any] = ["niveau": "complet", "confirmees": 1, "a_verifier": 0, "sha256": Sha256.hex(data), "expire_min": "2026-12-31"]
        if code == "national" { national = ["sha256": Sha256.hex(data), "expire_min": "2026-12-31"] } else { departements[code] = entree }
    }
    var racine: [String: Any] = ["version": "2026-10-16.1", "date": "2026-10-16", "departements": departements]
    if let national { racine["national"] = national }
    return json(racine)
}

private struct Banc {
    let embarque = dossierTemporaire()
    let copies = dossierTemporaire()
    let reseau = TelechargeFichierFaux()

    func embarquer(_ code: String, _ data: Data) {
        try? data.write(to: embarque.appendingPathComponent("\(code).json"))
    }

    /// Publie ces fichiers sur le faux serveur, avec leur index.
    func publier(_ fichiers: [String: Data], indexEgalA: [String: Data]? = nil) {
        reseau.definir("index.json", index(indexEgalA ?? fichiers))
        for (code, data) in fichiers { reseau.definir("\(code).json", data) }
    }

    var miseAJour: MiseAJourRegles { MiseAJourRegles(telechargeur: reseau, embarque: embarque, copies: copies) }
    var catalogue: CatalogueRegles { CatalogueRegles(embarque: embarque, copies: copies) }
}

private func jour(_ iso: String) -> Date { Jours.date(iso: iso)! }

// MARK: - Outils de base

@Suite("SHA-256 et versions")
struct BasesTests {
    @Test func sha256ConnuVecteurs() {
        #expect(Sha256.hex(Data()) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        #expect(Sha256.hex(Data("abc".utf8)) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        #expect(Sha256.hex(Data("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".utf8))
                == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
        #expect(Sha256.hex(Data(repeating: UInt8(ascii: "a"), count: 1_000_000))
                == "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
    }

    @Test func versionsSeComparentParJourPuisNumero() {
        let a = VersionRegles("2026-10-15.1")!
        #expect(a < VersionRegles("2026-10-15.2")!)
        #expect(a < VersionRegles("2026-10-16.0")!)
        #expect(VersionRegles("2026-10-15.10")! > VersionRegles("2026-10-15.9")!)
        #expect(VersionRegles("n'importe quoi") == nil)
        #expect(VersionRegles("2026-02-31.1") == nil)
    }
}

// MARK: - Mise à jour

@Suite("Mise à jour des règles")
struct MiseAJourTests {
    @Test func prendTousLesFichiersChangesEtSeulementEux() async {
        let banc = Banc()
        let ancien75 = fichier("75")
        banc.embarquer("75", ancien75)
        banc.embarquer("94", fichier("94", version: "2026-10-15.1"))
        let neuf94 = fichier("94", version: "2026-10-16.1")
        let neuf01 = fichier("01", version: "2026-10-16.1")
        banc.publier(["75": ancien75, "94": neuf94, "01": neuf01])

        let rapport = await banc.miseAJour.mettreAJour()

        #expect(rapport.indexLu)
        #expect(Set(rapport.adoptes) == ["94", "01"])
        #expect(rapport.inchanges == ["75"])
        #expect(rapport.refuses.isEmpty)
        // Le 94 et le 01 sont demandés même si le pêcheur est dans le 75 : la mise à jour n'a aucune idée d'où il pêche.
        #expect(banc.reseau.chemins == ["index.json", "01.json", "94.json"])
        #expect(banc.catalogue.contenu(departement: "94") == neuf94)
        #expect(banc.catalogue.contenu(departement: "01") == neuf01)
    }

    @Test func copiesGardeesSansReseau() async {
        let banc = Banc()
        banc.embarquer("94", fichier("94"))
        let neuf94 = fichier("94", version: "2026-10-16.1")
        banc.publier(["94": neuf94])
        await banc.miseAJour.mettreAJour()

        banc.reseau.coupeLeReseau(true)
        let rapport = await banc.miseAJour.mettreAJour()

        #expect(!rapport.indexLu)
        #expect(rapport.adoptes.isEmpty)
        #expect(banc.catalogue.contenu(departement: "94") == neuf94)
        #expect(banc.catalogue.version(de: "94") == "2026-10-16.1")
    }

    @Test func reseauCoupeDepuisLeDebutLaCopieEmbarqueeSert() async {
        let banc = Banc()
        let embarque = fichier("94")
        banc.embarquer("94", embarque)
        banc.reseau.coupeLeReseau(true)

        let rapport = await banc.miseAJour.mettreAJour()

        #expect(!rapport.indexLu)
        #expect(banc.catalogue.contenu(departement: "94") == embarque)
        #expect(banc.catalogue.departementsCouverts().map(\.departement.code) == ["94"])
    }

    @Test func sansAdresseLaCopieEmbarqueeSert() async {
        let banc = Banc()
        let embarque = fichier("94")
        banc.embarquer("94", embarque)
        let miseAJour = MiseAJourRegles(telechargeur: TelechargeFichierSansAdresse(), embarque: banc.embarque, copies: banc.copies)

        let rapport = await miseAJour.mettreAJour()

        #expect(!rapport.indexLu)
        #expect(await miseAJour.catalogue.contenu(departement: "94") == embarque)
        await #expect(throws: ErreurTelechargement.aucuneAdresse) {
            _ = try await TelechargeFichierHTTP(base: nil).telecharger(chemin: "index.json")
        }
    }

    @Test func sha256FauxRefuseSansBloquerLesAutres() async {
        let banc = Banc()
        let ancien94 = fichier("94")
        banc.embarquer("94", ancien94)
        let neuf94 = fichier("94", version: "2026-10-16.1")
        let neuf01 = fichier("01", version: "2026-10-16.1")
        // L'index annonce l'empreinte de neuf94, mais le serveur sert autre chose.
        banc.publier(["94": neuf94, "01": neuf01])
        banc.reseau.definir("94.json", fichier("94", version: "2026-10-16.1", citation: "texte modifié en route"))

        let rapport = await banc.miseAJour.mettreAJour()

        #expect(rapport.refuses["94"] == .sha256Different)
        #expect(rapport.adoptes == ["01"])
        #expect(banc.catalogue.contenu(departement: "94") == ancien94)
        #expect(banc.catalogue.contenu(departement: "01") == neuf01)
    }

    @Test func fichierPlusAncienRefuse() async {
        let banc = Banc()
        let recent = fichier("94", version: "2026-10-16.1")
        banc.embarquer("94", recent)
        let vieux = fichier("94", version: "2026-10-15.1")
        banc.publier(["94": vieux, "01": fichier("01")])

        let rapport = await banc.miseAJour.mettreAJour()

        #expect(rapport.refuses["94"] == .pasPlusRecent)
        #expect(rapport.adoptes == ["01"])
        #expect(banc.catalogue.contenu(departement: "94") == recent)
    }

    @Test func memeVersionAvecAutreContenuRefuse() async {
        let banc = Banc()
        banc.embarquer("94", fichier("94"))
        banc.publier(["94": fichier("94", citation: "autre citation, même version")])
        let rapport = await banc.miseAJour.mettreAJour()
        #expect(rapport.refuses["94"] == .pasPlusRecent)
    }

    @Test func fichierCoupeEnRouteRefuse() async {
        let banc = Banc()
        let ancien = fichier("94")
        banc.embarquer("94", ancien)
        let complet = fichier("94", version: "2026-10-16.1")
        let coupe = complet.prefix(complet.count / 2)
        // Cas 1 : l'index annonce l'empreinte du fichier entier, le serveur n'en rend que la moitié.
        banc.publier(["94": complet, "01": fichier("01")])
        banc.reseau.definir("94.json", Data(coupe))
        let rapport = await banc.miseAJour.mettreAJour()
        #expect(rapport.refuses["94"] == .sha256Different)
        #expect(rapport.adoptes == ["01"])
        #expect(banc.catalogue.contenu(departement: "94") == ancien)

        // Cas 2 : l'empreinte est celle de la moitié (index coupé aussi) : le JSON est illisible.
        let banc2 = Banc()
        banc2.embarquer("94", ancien)
        banc2.publier(["94": Data(coupe)])
        let rapport2 = await banc2.miseAJour.mettreAJour()
        #expect(rapport2.refuses["94"] == .illisible)
        #expect(banc2.catalogue.contenu(departement: "94") == ancien)
    }

    @Test func formeInvalideRefusee() async {
        let banc = Banc()
        banc.embarquer("94", fichier("94"))
        banc.publier(["94": fichier("94", version: "2026-10-16.1", citation: "  ")])
        let rapport = await banc.miseAJour.mettreAJour()
        guard case .formeInvalide = rapport.refuses["94"] else {
            Issue.record("attendu : forme invalide, obtenu \(String(describing: rapport.refuses["94"]))")
            return
        }
    }

    @Test func fichierQuiAnnonceUnAutreDepartementRefuse() async {
        let banc = Banc()
        banc.publier(["94": fichier("75", version: "2026-10-16.1")])
        let rapport = await banc.miseAJour.mettreAJour()
        #expect(rapport.refuses["94"] == .autreDepartement)
        #expect(banc.catalogue.departementsCouverts().isEmpty)
    }

    @Test func departementNouveauVisibleAussitotDansDepartementsCouverts() async {
        let banc = Banc()
        banc.embarquer("94", fichier("94"))
        #expect(banc.catalogue.departementsCouverts().map(\.departement.code) == ["94"])

        banc.publier(["94": fichier("94"), "2A": fichier("2A", niveau: "partiel", aVerifier: 3)])
        let rapport = await banc.miseAJour.mettreAJour()

        #expect(rapport.adoptes == ["2A"])
        let couverts = banc.catalogue.departementsCouverts()
        #expect(couverts.map(\.departement.code) == ["2A", "94"])
        let corse = couverts.first { $0.departement.code == "2A" }
        #expect(corse?.niveau == .partiel)
        #expect(corse?.lignesAVerifier == 3)
        #expect(corse?.reglesConfirmees == 1)
        #expect(corse?.dateLecture == jour("2026-10-15"))
        #expect(corse?.expireMin == jour("2026-12-31"))
        #expect(banc.catalogue.datesDesRegles()["2A"] == jour("2026-10-15"))
    }

    @Test func nationalEstMisAJourCommeLesAutres() async {
        let banc = Banc()
        banc.embarquer("national", fichier("national"))
        let neuf = fichier("national", version: "2026-10-16.1")
        banc.publier(["national": neuf])
        let rapport = await banc.miseAJour.mettreAJour()
        #expect(rapport.adoptes == ["national"])
        #expect(banc.catalogue.contenuNational() == neuf)
        #expect(banc.catalogue.departementsCouverts().isEmpty)
    }

    @Test func copieTelechargeeIllisibleLaCopieEmbarqueeSert() async {
        let banc = Banc()
        let embarque = fichier("94")
        banc.embarquer("94", embarque)
        try? FileManager.default.createDirectory(at: banc.copies, withIntermediateDirectories: true)
        try? Data("{ pas du json".utf8).write(to: banc.copies.appendingPathComponent("94.json"))
        #expect(banc.catalogue.contenu(departement: "94") == embarque)
    }

    @Test func indexIllisibleOuMalfaisantNeChangeRien() async {
        let banc = Banc()
        let embarque = fichier("94")
        banc.embarquer("94", embarque)
        banc.reseau.definir("index.json", Data("pas du json".utf8))
        #expect(await banc.miseAJour.mettreAJour().indexLu == false)

        // Un code qui servirait à sortir du dossier est ignoré, jamais demandé.
        let neuf = fichier("94", version: "2026-10-16.1")
        banc.reseau.definir("index.json", json([
            "version": "2026-10-16.1", "date": "2026-10-16",
            "departements": ["../evil": ["sha256": Sha256.hex(neuf)], "94": ["sha256": "pas une empreinte"]],
        ]))
        let rapport = await banc.miseAJour.mettreAJour()
        #expect(rapport.indexLu)
        #expect(rapport.adoptes.isEmpty)
        #expect(banc.reseau.chemins.filter { $0 != "index.json" }.isEmpty)
        #expect(banc.catalogue.contenu(departement: "94") == embarque)
    }

    @Test func aucunFichierADemiEcritNiResidu() async {
        let banc = Banc()
        banc.publier(["94": fichier("94"), "01": fichier("01")])
        await banc.miseAJour.mettreAJour()
        let noms = ((try? FileManager.default.contentsOfDirectory(atPath: banc.copies.path)) ?? []).sorted()
        #expect(noms == ["01.json", "94.json"])
    }
}

// MARK: - Périmées, expiration, signalement

@Suite("Règles périmées, expiration, signalement")
struct PeremptionTests {
    @Test func reglePerimeeVenueDuFichierTelechargeJamaisFeuVert() async {
        let banc = Banc()
        banc.embarquer("94", fichier("94", expireLe: "2026-12-31"))
        banc.publier(["94": fichier("94", version: "2026-10-16.1", expireLe: "2026-12-31")])
        await banc.miseAJour.mettreAJour()
        let catalogue = banc.catalogue
        let brochet = Espece(id: "brochet", codeSandre: "2151")
        let sandre = Espece(id: "sandre", codeSandre: "2195")
        let lieu = Departement(code: "94")

        // La veille de l'échéance et le jour même : valable.
        #expect(catalogue.lignesPerimees(departement: lieu, espece: brochet, date: jour("2026-12-31")).isEmpty)

        // Le 15 janvier 2027 : « vérifie l'arrêté 2027 », jamais un feu vert.
        let lignes = catalogue.lignesPerimees(departement: lieu, espece: brochet, date: jour("2027-01-15"))
        #expect(lignes.count == 1)
        #expect(lignes[0].etat == .aVerifierSurPlace)
        #expect(lignes[0].raison == .perimee)
        #expect(lignes[0].phrase.contains("arrêté 2027"))
        #expect(lignes[0].phrase.contains("31/12/2026"))
        #expect(lignes[0].citation == "texte cité pour l'essai")
        #expect(lignes[0].sources.first?.url == "https://exemple.invalid/94")

        // Une règle d'une autre espèce n'est pas concernée.
        #expect(catalogue.lignesPerimees(departement: lieu, espece: sandre, date: jour("2027-01-15")).isEmpty)

        // Un contrôle qui disait « aucune règle saisie ne l'interdit » devient « vérifie l'arrêté ».
        let vert = ResultatControle(lignes: [], consigne: .aucuneRegleSaisieNeLInterdit)
        #expect(Peremption.durcir(vert, avec: lignes).consigne == .verifieLArrete)
        #expect(Peremption.durcir(vert, avec: lignes).lignes.count == 1)
        // Plus strict, ça reste ; sans règle périmée, rien ne change.
        #expect(Peremption.durcir(ResultatControle(lignes: [], consigne: .relacheLa), avec: lignes).consigne == .relacheLa)
        #expect(Peremption.durcir(vert, avec: []) == vert)
    }

    @Test func regleSansExpirationNePerimeJamais() async {
        let banc = Banc()
        banc.embarquer("94", fichier("94", expireLe: nil))
        let lignes = banc.catalogue.lignesPerimees(departement: Departement(code: "94"), espece: Espece(id: "brochet", codeSandre: "2151"),
                                                   date: jour("2040-01-01"))
        #expect(lignes.isEmpty)
        #expect(banc.catalogue.departementsCouverts().first?.expireMin == nil)
    }

    @Test func regleSansEspeceViseeToucheToutesLesEspeces() {
        let banc = Banc()
        banc.embarquer("94", fichier("94", expireLe: "2026-12-31", especes: []))
        let lignes = banc.catalogue.lignesPerimees(departement: Departement(code: "94"), espece: Espece(id: "perche-commune", codeSandre: "2193"),
                                                   date: jour("2027-02-01"))
        #expect(lignes.count == 1)
    }

    @Test func alerteAMoinsDeTrenteJoursDExpireMin() {
        let banc = Banc()
        banc.embarquer("94", fichier("94", expireLe: "2026-12-31"))
        banc.embarquer("75", fichier("75", expireLe: "2027-06-30"))
        banc.embarquer("national", fichier("national", expireLe: nil))
        let catalogue = banc.catalogue

        // 31 jours avant : rien. 30 jours avant : rien (il faut moins de 30 jours). 29 jours avant : le 94.
        #expect(catalogue.fichiersQuiExpirent(le: jour("2026-11-30")).isEmpty)
        #expect(catalogue.fichiersQuiExpirent(le: jour("2026-12-01")).isEmpty)
        let alertes = catalogue.fichiersQuiExpirent(le: jour("2026-12-02"))
        #expect(alertes.map(\.code) == ["94"])
        #expect(alertes.first?.joursRestants == 29)
        // Une échéance déjà passée alerte aussi.
        #expect(catalogue.fichiersQuiExpirent(le: jour("2027-01-10")).map(\.code) == ["94"])
    }

    @Test func signalementPorteRegleDepartementEtVersion() {
        let banc = Banc()
        banc.embarquer("94", fichier("94", version: "2026-10-15.3"))
        let signalement = banc.catalogue.signalement(regleId: "94-essai-1", departement: Departement(code: "94"))
        #expect(signalement == SignalementRegle(regleId: "94-essai-1", departement: "94", versionFichier: "2026-10-15.3"))
        #expect(signalement?.texte == "Erreur de règle signalée · regle=94-essai-1 · departement=94 · fichier=2026-10-15.3")
        #expect(SignalementRegle(texte: signalement!.texte) == signalement)
        #expect(banc.catalogue.signalement(regleId: "inconnue", departement: Departement(code: "94")) == nil)
        #expect(SignalementRegle(texte: "bonjour") == nil)
    }
}
