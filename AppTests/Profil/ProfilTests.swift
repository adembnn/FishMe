import CloudKit
import Foundation
import Testing
@testable import BuildChallenge

/// Tests écrits sans Mac : non exécutés au moment de l'écriture (lot L21).
nonisolated private final class MemoireFausse: MemoireProfil, @unchecked Sendable {
    var id: String?
    var nom: String?
    func idProfil() -> String? { id }
    func surnom() -> String? { nom }
    func retenir(id: String, surnom: String) { self.id = id; self.nom = surnom }
    func oublier() { id = nil; nom = nil }
}

@MainActor
struct ProfilTests {
    private func gestion(_ service: FauxServiceProfil, effaceurs: [any EffaceurContenu] = [],
                         memoire: MemoireFausse = MemoireFausse()) -> GestionProfil {
        let u = UUID().uuidString
        return GestionProfil(service: service, memoire: memoire,
                             identite: IdentitePriveeLocale(cleNom: "t.nom.\(u)", clePrenom: "t.prenom.\(u)"),
                             blocages: BlocagesProfils(cleBloques: "t.bl.\(u)", cleMasques: "t.ma.\(u)"),
                             effaceurs: effaceurs)
    }

    // MARK: Surnom

    @Test func lesMajusculesEtAccentsNeChangentPasLUnicite() {
        #expect(Surnom.normaliser("Gros-Brochet") == "gros-brochet")
        #expect(Surnom.identifiant(pour: "Gros-Brochet") == Surnom.identifiant(pour: "gros-brochet"))
        #expect(Surnom.normaliser("Éloïse") == "eloise")
    }

    @Test func lesReglesDuSurnom() {
        #expect(Surnom.verifier("ab") == .tropCourt)
        #expect(Surnom.verifier(String(repeating: "a", count: 21)) == .tropLong)
        #expect(Surnom.verifier("gros brochet") == .caractereInterdit)
        #expect(Surnom.verifier("gros_brochet") == .caractereInterdit)
        #expect(Surnom.verifier("-brochet") == .tiretMalPlace)
        #expect(Surnom.verifier("gros--brochet") == .tiretMalPlace)
        #expect(Surnom.verifier("gros-brochet") == nil)
        #expect(Surnom.verifier("Perche42") == nil)
    }

    @Test func lIdentifiantEstToujoursEnASCII() {
        #expect(Surnom.verifier("œuf") == nil)
        #expect(Surnom.identifiant(pour: "Œuf") == "p-oeuf")
        #expect(Surnom.verifier("straße") == nil)
        #expect(Surnom.identifiant(pour: "Straße") == "p-strasse")
        #expect(Surnom.identifiant(pour: "Søren") == "p-soren")
        #expect(Surnom.identifiant(pour: "Łukasz") == "p-lukasz")
        #expect(Surnom.identifiant(pour: "Æsir") == "p-aesir")
        for surnom in ["œuf", "straße", "Éloïse", "Søren", "Łukasz", "gros-brochet", "Perche42"] {
            let id = Surnom.identifiant(pour: surnom)
            #expect(id.unicodeScalars.allSatisfy { $0.isASCII })
        }
    }

    @Test func lesAlphabetsNonLatinsSontRefuses() {
        #expect(Surnom.verifier("Ωμέγα") == .caractereInterdit)
        #expect(Surnom.verifier("щукаа") == .caractereInterdit)
        #expect(Surnom.verifier("魚釣り人") == .caractereInterdit)
        #expect(Surnom.verifier("poisson٣٤") == .caractereInterdit)
        // Même non vérifié, un identifiant ne contient jamais autre chose que a-z, 0-9 et tiret après « p- ».
        let id = Surnom.identifiant(pour: "щука-brochet")
        #expect(id == "p--brochet" || id.unicodeScalars.allSatisfy { $0.isASCII })
        #expect(id.unicodeScalars.allSatisfy { $0.isASCII })
    }

    @Test func leSurnomAfficheResteTelQuilEstEcrit() {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let record = try? FabriqueProfil.record(surnom: "Œuf-de-Brochet", avatar: nil, creeLe: Date(), dossierTemp: dossier)
        #expect(record?["surnomAffiche"] as? String == "Œuf-de-Brochet")
        #expect(record?.recordID.recordName == "p-oeuf-de-brochet")
    }

    @Test func leFiltreRefuseLesMotsEntiersSeulement() {
        let filtre = FiltreParListe(mots: ["zut"])
        #expect(filtre.refuse("Zut"))
        #expect(filtre.refuse("zut-alors"))
        #expect(!filtre.refuse("zutique"))
        #expect(Surnom.verifier("zut-alors", filtre: filtre) == .motRefuse)
        #expect(Surnom.verifier("brochet", filtre: filtre) == nil)
    }

    // MARK: Rien de privé en base publique

    @Test func leRecordProfilNePorteQueLesClesPrevues() throws {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let record = try FabriqueProfil.record(surnom: "Gros-Brochet", avatar: Data([1, 2, 3]), creeLe: Date(), dossierTemp: dossier)
        let cles = Set(record.allKeys())
        #expect(cles.isSubset(of: FabriqueProfil.cles))
        for interdit in ["prenom", "nom", "email", "mail", "lat", "lon", "gps", "lieu", "appleid"] {
            #expect(!cles.contains(interdit))
        }
        #expect(record.recordID.recordName == "p-gros-brochet")
        #expect(record["surnomNorm"] as? String == "gros-brochet")
        #expect(record["surnomAffiche"] as? String == "Gros-Brochet")
        #expect(record["avatar"] is CKAsset)
    }

    // MARK: Créer

    @Test func creerUnProfilGardeSonIdentifiant() async {
        let service = FauxServiceProfil()
        let memoire = MemoireFausse()
        let g = gestion(service, memoire: memoire)
        let ok = await g.creer(surnom: "gros-brochet", avatar: Data([9]), aQuinzeAns: true)
        #expect(ok)
        #expect(g.profil?.id == "p-gros-brochet")
        #expect(memoire.id == "p-gros-brochet")
        #expect(g.aUnProfil)
        #expect(await service.contient("p-gros-brochet"))
    }

    @Test func sansLaDeclarationDeQuinzeAnsRienNEstEcrit() async {
        let service = FauxServiceProfil()
        let g = gestion(service)
        let ok = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: false)
        #expect(!ok)
        #expect(g.message == .ageRequis)
        #expect(g.profil == nil)
        #expect(await service.ecritures == 0)
    }

    @Test func unSurnomDejaPrisEstRefuseAvantTouteEcriture() async {
        let existant = ProfilModele(id: "p-gros-brochet", surnom: "gros-brochet", avatar: nil, creeLe: Date())
        let service = FauxServiceProfil(profils: [existant])
        let g = gestion(service)
        let ok = await g.creer(surnom: "Gros-Brochet", avatar: nil, aQuinzeAns: true)
        #expect(!ok)
        #expect(g.message == .surnomPris)
        #expect(await service.ecritures == 0)
    }

    @Test func deuxCreationsEnMemeTempsUnSeulGagne() async {
        let service = FauxServiceProfil()
        await service.glisserConcurrent(surnom: "gros-brochet")
        let g = gestion(service)
        let ok = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true)
        #expect(!ok)
        #expect(g.message == .surnomPris)
        #expect(g.profil == nil)
    }

    @Test func unSurnomInvalideNeVaPasJusquAuReseau() async {
        let service = FauxServiceProfil()
        let g = gestion(service)
        #expect(await g.creer(surnom: "ab", avatar: nil, aQuinzeAns: true) == false)
        #expect(g.message == .surnomRefuse(.tropCourt))
        #expect(await service.ecritures == 0)
    }

    // MARK: Rappel « Finis ton profil »

    @Test func laFeuilleSeMontreUneFoisPuisSeptJoursPlusTard() {
        let t0 = Date(timeIntervalSince1970: 1_760_000_000)
        #expect(RappelProfil.doitAfficher(prochain: 0, profilExiste: false, maintenant: t0))
        let prochain = RappelProfil.prochain(apres: t0)
        #expect(!RappelProfil.doitAfficher(prochain: prochain, profilExiste: false, maintenant: t0.addingTimeInterval(6 * 86_400)))
        #expect(RappelProfil.doitAfficher(prochain: prochain, profilExiste: false, maintenant: t0.addingTimeInterval(7 * 86_400 + 1)))
    }

    @Test func jamaisDeFeuilleSiLeProfilExiste() {
        #expect(!RappelProfil.doitAfficher(prochain: 0, profilExiste: true, maintenant: Date()))
    }

    // MARK: Recherche

    private func profils() -> [ProfilModele] {
        ["gros-brochet", "grosse-perche", "sandre42"].map { ProfilModele(id: "p-\($0)", surnom: $0, avatar: nil, creeLe: Date()) }
    }

    @Test func troisLettresTrouventLesSurnomsQuiCommencentPareil() async {
        let service = FauxServiceProfil(profils: profils())
        let g = gestion(service)
        let r = RechercheProfils(service: service, profil: g, attente: .zero)
        r.saisir("gro")
        await r.chercher()
        #expect(r.resultats.map(\.id) == ["p-gros-brochet", "p-grosse-perche"])
        #expect(r.etat == .resultats)
    }

    @Test func deuxLettresNeLancentRien() async {
        let service = FauxServiceProfil(profils: profils())
        let r = RechercheProfils(service: service, profil: gestion(service), attente: .zero)
        r.saisir("gr")
        await r.chercher()
        #expect(r.resultats.isEmpty)
        #expect(r.etat == .repos)
    }

    @Test func unProfilBloqueDisparaitDeLaRecherche() async {
        let service = FauxServiceProfil(profils: profils())
        let g = gestion(service)
        g.bloquer("p-gros-brochet")
        let r = RechercheProfils(service: service, profil: g, attente: .zero)
        r.saisir("gro")
        await r.chercher()
        #expect(r.resultats.map(\.id) == ["p-grosse-perche"])
    }

    @Test func monProfilNApparaitPasDansLaRecherche() async {
        let service = FauxServiceProfil()
        let g = gestion(service)
        _ = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true)
        let r = RechercheProfils(service: service, profil: g, attente: .zero)
        r.saisir("gro")
        await r.chercher()
        #expect(r.resultats.isEmpty)
    }

    // MARK: Signaler

    @Test func signalerMasqueToutDeSuiteEtLaisseUneTrace() async {
        let service = FauxServiceProfil(profils: profils())
        let g = gestion(service)
        let cible = profils()[0]
        await g.signaler(cible, motif: .spam)
        #expect(g.estCache(cible.id))
        #expect(await service.signalements.count == 1)
    }

    // MARK: Supprimer

    @Test func supprimerEffaceProfilContenuEtIdentitePrivee() async {
        let service = FauxServiceProfil()
        let effaceur = EffaceurFaux()
        let g = gestion(service, effaceurs: [effaceur])
        _ = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true)
        g.enregistrerIdentitePrivee(nom: "Dupont", prenom: "Léa")
        let ok = await g.supprimer()
        #expect(ok)
        #expect(g.profil == nil && !g.aUnProfil)
        #expect(await service.contient("p-gros-brochet") == false)
        #expect(await effaceur.appels == ["p-gros-brochet"])
        #expect(g.identitePrivee().nom.isEmpty && g.identitePrivee().prenom.isEmpty)
    }

    @Test func siUnEffaceurEchoueLeProfilEstGarde() async {
        let service = FauxServiceProfil()
        let g = gestion(service, effaceurs: [EffaceurFaux(echoue: true)])
        _ = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true)
        let ok = await g.supprimer()
        #expect(!ok)
        #expect(g.message == .suppressionIncomplete)
        #expect(await service.contient("p-gros-brochet"))
        #expect(g.aUnProfil)
    }

    // MARK: Lien et noms

    @Test func leLienAmiFaitLAllerRetour() throws {
        let url = try #require(LienAmi.url(profilID: "p-gros-brochet"))
        #expect(url.absoluteString == "fishme://ami/p-gros-brochet")
        #expect(LienAmi.profilID(depuis: url) == "p-gros-brochet")
        #expect(LienAmi.profilID(depuis: try #require(URL(string: "fishme://club/p-gros-brochet"))) == nil)
        #expect(LienAmi.profilID(depuis: try #require(URL(string: "fishme://ami/abc"))) == nil)
        #expect(LienAmi.profilID(depuis: try #require(URL(string: "https://ami/p-gros-brochet"))) == nil)
    }

    @Test func leRelaisGardeLeLienJusquAuSolde() throws {
        let relais = RelaisLienAmi()
        #expect(relais.recevoir(try #require(URL(string: "fishme://ami/p-gros-brochet"))))
        #expect(relais.enAttente == "p-gros-brochet")
        relais.solder()
        #expect(relais.enAttente == nil)
        #expect(!relais.recevoir(try #require(URL(string: "fishme://pro"))))
    }

    @Test func lAmiPorteSonSurnomJamaisUnNomReel() {
        #expect(NomAmi.affiche(titre: "gros-brochet") == "gros-brochet")
        #expect(NomAmi.affiche(titre: "Pescedex") == "Un ami")
        #expect(NomAmi.affiche(titre: nil) == "Un ami")
        #expect(NomAmi.affiche(titre: "Jean Dupont") == "Un ami")
        #expect(NomAmi.titre(surnom: nil) == "Pescedex")
        #expect(NomAmi.titre(surnom: "gros-brochet") == "gros-brochet")
    }

    @Test func leSignalementDeProfilNePorteQueLIdentifiantEtLeMotif() throws {
        let url = try #require(Signalement.url(contact: "contact@exemple.invalid", profilID: "p-gros-brochet", motif: .spam))
        let texte = url.absoluteString.removingPercentEncoding ?? ""
        #expect(texte.contains("p-gros-brochet"))
        #expect(texte.contains("Spam"))
    }
}
