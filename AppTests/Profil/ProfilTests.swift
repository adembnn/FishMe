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

/// Compte les mises à jour du titre du partage d'amis.
private actor TitresNotes {
    private(set) var appels = 0
    func noter() { appels += 1 }
}

@MainActor
struct ProfilTests {
    private func gestion(_ service: FauxServiceProfil, effaceurs: [any EffaceurContenu] = [],
                         memoire: MemoireFausse = MemoireFausse()) -> GestionProfil {
        let u = UUID().uuidString
        return GestionProfil(service: service, memoire: memoire,
                             blocages: ListeBlocages(cleBloques: "t.bl.\(u)", cleMasques: "t.ma.\(u)"),
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
        // Même non vérifié, un identifiant ne contient jamais autre chose que de l'ASCII.
        #expect(Surnom.identifiant(pour: "щука-brochet").unicodeScalars.allSatisfy { $0.isASCII })
    }

    @Test func leSurnomAfficheResteTelQuilEstEcrit() throws {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let record = try FabriqueProfil.record(surnom: "Œuf-de-Brochet", avatar: nil, creeLe: Date(), dossierTemp: dossier)
        #expect(record["surnomAffiche"] as? String == "Œuf-de-Brochet")
        #expect(record.recordID.recordName == "p-oeuf-de-brochet")
    }

    @Test func leFiltreRefuseLesMotsEntiersSeulement() {
        let filtre = FiltreParListe(mots: ["zut"])
        #expect(filtre.refuse("Zut"))
        #expect(filtre.refuse("zut-alors"))
        #expect(!filtre.refuse("zutique"))
        #expect(Surnom.verifier("zut-alors", filtre: filtre) == .motRefuse)
        #expect(Surnom.verifier("brochet", filtre: filtre) == nil)
    }

    // MARK: Rien de privé en base publique (juste un pseudonyme)

    @Test func leRecordProfilNePorteQueLesClesPrevues() throws {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let record = try FabriqueProfil.record(surnom: "Gros-Brochet", avatar: Data([1, 2, 3]), creeLe: Date(), dossierTemp: dossier)
        let cles = Set(record.allKeys())
        #expect(cles.isSubset(of: FabriqueProfil.cles))
        for interdit in ["prenom", "nom", "email", "mail", "lat", "lon", "gps", "lieu", "appleid"] {
            #expect(!cles.contains(interdit))
        }
        #expect(record.recordType == "ProfilPublic")
        #expect(record.recordID.recordName == "p-gros-brochet")
        #expect(record["surnomNorm"] as? String == "gros-brochet")
        #expect(record["surnomAffiche"] as? String == "Gros-Brochet")
        #expect(record["avatar"] is CKAsset)
    }

    @Test func leTypeCloudKitPublicSAppelleProfilPublic() {
        #expect(FabriqueProfil.typeProfil == "ProfilPublic")
    }

    @Test func aucunChampNomOuPrenomNExisteNullePart() {
        #expect(!FabriqueProfil.cles.contains("nom") && !FabriqueProfil.cles.contains("prenom"))
        // Les anciennes clés des versions de test sont effacées, jamais relues.
        for cle in AnciensChampsIdentite.cles { UserDefaults.standard.set("x", forKey: cle) }
        AnciensChampsIdentite.purger()
        #expect(AnciensChampsIdentite.cles.allSatisfy { UserDefaults.standard.object(forKey: $0) == nil })
    }

    // MARK: Créer

    @Test func creerUnProfilGardeSonIdentifiant() async {
        let service = FauxServiceProfil()
        let memoire = MemoireFausse()
        let g = gestion(service, memoire: memoire)
        let ok = await g.creer(surnom: "gros-brochet", avatar: Data([9]), aQuinzeAns: true, accepteLesConditions: true)
        #expect(ok)
        #expect(g.profil?.id == "p-gros-brochet")
        #expect(memoire.id == "p-gros-brochet")
        #expect(g.aUnProfil)
        #expect(await service.contient("p-gros-brochet"))
    }

    @Test func sansLaDeclarationDeQuinzeAnsRienNEstEcrit() async {
        let service = FauxServiceProfil()
        let g = gestion(service)
        let ok = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: false, accepteLesConditions: true)
        #expect(!ok)
        #expect(g.message == .ageRequis)
        #expect(g.profil == nil)
        #expect(await service.ecritures == 0)
    }

    @Test func sansLaCaseDesConditionsRienNEstEcrit() async {
        let service = FauxServiceProfil()
        let g = gestion(service)
        let ok = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true, accepteLesConditions: false)
        #expect(!ok)
        #expect(g.message == .conditionsRequises)
        #expect(g.profil == nil)
        #expect(await service.ecritures == 0)
    }

    @Test func unSurnomDejaPrisEstRefuseAvantTouteEcriture() async {
        let existant = ProfilModele(id: "p-gros-brochet", surnom: "gros-brochet", avatar: nil, creeLe: Date())
        let service = FauxServiceProfil(profils: [existant])
        let g = gestion(service)
        let ok = await g.creer(surnom: "Gros-Brochet", avatar: nil, aQuinzeAns: true, accepteLesConditions: true)
        #expect(!ok)
        #expect(g.message == .surnomPris)
        #expect(await service.ecritures == 0)
    }

    @Test func deuxCreationsEnMemeTempsUnSeulGagne() async {
        let service = FauxServiceProfil()
        await service.glisserConcurrent(surnom: "gros-brochet")
        let g = gestion(service)
        let ok = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true, accepteLesConditions: true)
        #expect(!ok)
        #expect(g.message == .surnomPris)
        #expect(g.profil == nil)
    }

    @Test func unSurnomInvalideNeVaPasJusquAuReseau() async {
        let service = FauxServiceProfil()
        let g = gestion(service)
        #expect(await g.creer(surnom: "ab", avatar: nil, aQuinzeAns: true, accepteLesConditions: true) == false)
        #expect(g.message == .surnomRefuse(.tropCourt))
        #expect(await service.ecritures == 0)
    }

    // MARK: Réponse perdue, réinstallation

    @Test func unSurnomDejaEcritParMoiEstRepris() async {
        let mien = ProfilModele(id: "p-gros-brochet", surnom: "Gros-Brochet", avatar: nil, creeLe: Date())
        let service = FauxServiceProfil()
        await service.glisserMonProfil(mien)
        let memoire = MemoireFausse()
        let g = gestion(service, memoire: memoire)
        let ok = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true, accepteLesConditions: true)
        #expect(ok)
        #expect(g.profil?.id == "p-gros-brochet")
        #expect(memoire.id == "p-gros-brochet")
        #expect(g.message == nil)
        #expect(await service.ecritures == 0)
    }

    @Test func unSurnomEcritParUnAutreResteRefuse() async {
        let autre = ProfilModele(id: "p-gros-brochet", surnom: "gros-brochet", avatar: nil, creeLe: Date())
        let service = FauxServiceProfil(profils: [autre])
        let g = gestion(service)
        #expect(await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true, accepteLesConditions: true) == false)
        #expect(g.message == .surnomPris)
        #expect(await g.retrouver(surnom: "gros-brochet") == false)
        #expect(g.message == .profilIntrouvable)
    }

    @Test func retrouverMonProfilSansSurnomApresReinstallation() async {
        let mien = ProfilModele(id: "p-gros-brochet", surnom: "Gros-Brochet", avatar: nil, creeLe: Date())
        let service = FauxServiceProfil()
        await service.glisserMonProfil(mien)
        let memoire = MemoireFausse()
        let g = gestion(service, memoire: memoire)
        #expect(!g.aUnProfil)
        #expect(await g.retrouver())
        #expect(g.profil?.surnom == "Gros-Brochet")
        #expect(g.aUnProfil && memoire.id == "p-gros-brochet")
    }

    @Test func supprimerMarcheSansIdentifiantGardeApresReinstallation() async {
        let mien = ProfilModele(id: "p-gros-brochet", surnom: "Gros-Brochet", avatar: nil, creeLe: Date())
        let service = FauxServiceProfil()
        await service.glisserMonProfil(mien)
        let effaceur = EffaceurFaux()
        let g = gestion(service, effaceurs: [effaceur])
        #expect(!g.aUnProfil)
        #expect(await g.supprimer())
        #expect(await service.contient("p-gros-brochet") == false)
        #expect(await effaceur.appels == ["p-gros-brochet"])
    }

    @Test func supprimerSansAucunProfilNeFaitRien() async {
        let service = FauxServiceProfil()
        let g = gestion(service)
        #expect(await g.supprimer())
        #expect(await service.suppressions == 0)
    }

    @Test func horsLigneMonProfilResteAffichableEtSupprimable() async {
        let service = FauxServiceProfil(horsLigne: true)
        let memoire = MemoireFausse()
        memoire.id = "p-gros-brochet"
        memoire.nom = "Gros-Brochet"
        let g = gestion(service, memoire: memoire)
        // `profil` est vide mais l'iPhone se souvient : la ligne « Mon profil » (SectionProfilAmis) lit ceci.
        #expect(g.profil == nil && g.aUnProfil)
        #expect(g.surnomMemorise == "Gros-Brochet")
        #expect(await g.supprimer() == false)
        #expect(g.message == .horsLigne)
        #expect(g.aUnProfil)
        await service.regler(horsLigne: false)
        await service.glisserMonProfil(ProfilModele(id: "p-gros-brochet", surnom: "Gros-Brochet", avatar: nil, creeLe: Date()))
        #expect(await g.supprimer())
        #expect(!g.aUnProfil)
    }

    // MARK: Titre du partage

    @Test func leTitreDuPartageSuitLeSurnomALaCreationEtALaSuppression() async {
        let titres = TitresNotes()
        let u = UUID().uuidString
        let g = GestionProfil(service: FauxServiceProfil(), memoire: MemoireFausse(),
                              blocages: ListeBlocages(cleBloques: "t.bl.\(u)", cleMasques: "t.ma.\(u)"),
                              apresChangementDeSurnom: { await titres.noter() })
        _ = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true, accepteLesConditions: true)
        #expect(await titres.appels == 1)
        _ = await g.supprimer()
        #expect(await titres.appels == 2)
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
        _ = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true, accepteLesConditions: true)
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
        let resultat = await g.signaler(cible, motif: .spam)
        #expect(resultat == .enregistre)
        #expect(g.estCache(cible.id))
        #expect(await service.signalements.count == 1)
        #expect(await service.signalements.first?.type == .profil)
    }

    @Test func unSignalementNonEnregistreNeDitJamaisSignale() async {
        let service = FauxServiceProfil(profils: profils())
        await service.regler(signalementEnEchec: true)
        let g = gestion(service)
        let cible = profils()[0]
        let resultat = await g.signaler(cible, motif: .harcelement)
        #expect(resultat == .nonEnregistre)
        #expect(resultat.titre == "Pas enregistré, réessaie")
        #expect(!resultat.titre.contains("signalé"))
        #expect(!resultat.message(masque: true).contains("est enregistré"))
        // Le masquage chez moi reste (règle 1.2) ; seul le texte est honnête.
        #expect(g.estCache(cible.id))
        #expect(await service.signalements.isEmpty)
    }

    @Test func unSignalementEnregistreLeDit() {
        #expect(ResultatSignalement.enregistre.titre == "Merci, c'est signalé")
    }

    @Test func signalerUneCarteOuUnAmiPasseParLesMemesMotifs() async {
        let service = FauxServiceProfil()
        let g = gestion(service)
        #expect(await g.signaler(cible: "carte-1", type: .carte, motif: .coinExact, masquer: false) == .enregistre)
        #expect(!g.estCache("carte-1"))
        #expect(await g.signaler(cible: "p-gros-brochet", type: .ami, motif: .autre, masquer: true) == .enregistre)
        #expect(g.estCache("p-gros-brochet"))
        #expect(await service.signalements.map(\.motif) == [.coinExact, .autre])
    }

    @Test func lesMotifsSontUneListeFermeeUnique() {
        #expect(MotifSignalement.allCases.count == 9)
        #expect(Set(MotifSignalement.allCases.map(\.rawValue)).count == 9)
        #expect(MotifSignalement(rawValue: "harcelement") == .harcelement)
        #expect(MotifSignalement.allCases.allSatisfy { !$0.titre.isEmpty && !$0.symbole.isEmpty })
    }

    // MARK: Blocage : une seule liste

    @Test func laListeDeBlocageEstLaMemePourTous() {
        let u = UUID().uuidString
        let liste = ListeBlocages(cleBloques: "t.bl.\(u)", cleMasques: "t.ma.\(u)")
        liste.bloquer("p-a")
        liste.masquer("p-b")
        let lecture: any LectureBlocages = liste
        #expect(lecture.estCache("p-a") && lecture.estCache("p-b") && !lecture.estCache("p-c"))
        #expect(lecture.profilsCaches() == ["p-a", "p-b"])
        liste.debloquer("p-a")
        #expect(!lecture.estCache("p-a"))
    }

    // MARK: Supprimer

    @Test func supprimerEffaceProfilEtContenu() async {
        let service = FauxServiceProfil()
        let effaceur = EffaceurFaux()
        let g = gestion(service, effaceurs: [effaceur])
        _ = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true, accepteLesConditions: true)
        let ok = await g.supprimer()
        #expect(ok)
        #expect(g.profil == nil && !g.aUnProfil)
        #expect(await service.contient("p-gros-brochet") == false)
        #expect(await effaceur.appels == ["p-gros-brochet"])
    }

    @Test func siUnEffaceurEchoueLeProfilEstGarde() async {
        let service = FauxServiceProfil()
        let g = gestion(service, effaceurs: [EffaceurFaux(echoue: true)])
        _ = await g.creer(surnom: "gros-brochet", avatar: nil, aQuinzeAns: true, accepteLesConditions: true)
        let ok = await g.supprimer()
        #expect(!ok)
        #expect(g.message == .suppressionIncomplete)
        #expect(await service.contient("p-gros-brochet"))
        #expect(g.aUnProfil)
    }

    @Test func laPhraseDeSuppressionNePrometQueCeQuiSeraEfface() {
        let avec = gestion(FauxServiceProfil(), effaceurs: [EffaceurFaux()])
        #expect(avec.effaceDuContenu)
        #expect(avec.phraseSuppression.contains("publications") && avec.phraseSuppression.contains("messages"))
        // Sans effaceur (registre partagé vide, ce qui est le cas tant que A ne l'a pas branché) : rien d'autre que le profil n'est promis.
        let sans = gestion(FauxServiceProfil())
        if !sans.effaceDuContenu {
            #expect(sans.phraseSuppression == "Seuls ton surnom et ton avatar seront effacés du réseau.")
            #expect(!sans.phraseSuppression.contains("publications"))
        }
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
        // Le titre d'un partage est écrit par l'ami : sans confirmation, jamais de surnom affiché.
        #expect(NomAmi.affiche(titre: "gros-brochet") == "Un ami")
        #expect(NomAmi.affiche(titre: "Pescedex") == "Un ami")
        #expect(NomAmi.affiche(titre: nil) == "Un ami")
        #expect(NomAmi.titre(surnom: nil) == "Pescedex")
        #expect(NomAmi.titre(surnom: "gros-brochet") == "gros-brochet")
    }

    @Test func unTitreNEstUnNomQueSiLeProfilEstDuProprietaire() {
        #expect(NomAmi.affiche(titre: "gros-brochet", auteurDuProfil: "_abc", proprietaire: "_abc") == "gros-brochet")
        // Usurpation : l'ami met le surnom d'un autre, dont le profil a un autre auteur.
        #expect(NomAmi.affiche(titre: "gros-brochet", auteurDuProfil: "_xyz", proprietaire: "_abc") == "Un ami")
        // Profil introuvable, ou propriétaire inconnu : « Un ami ».
        #expect(NomAmi.affiche(titre: "gros-brochet", auteurDuProfil: nil, proprietaire: "_abc") == "Un ami")
        #expect(NomAmi.affiche(titre: "gros-brochet", auteurDuProfil: "", proprietaire: "") == "Un ami")
        // Un titre qui n'a pas la forme d'un surnom ne passe jamais, même avec le bon auteur.
        #expect(NomAmi.affiche(titre: "Jean Dupont", auteurDuProfil: "_abc", proprietaire: "_abc") == "Un ami")
        #expect(NomAmi.affiche(titre: "Pescedex", auteurDuProfil: "_abc", proprietaire: "_abc") == "Un ami")
    }

    @Test func seulesLesZonesPescedexSontDesAmis() {
        #expect(ServiceAmisCloudKit.nomDeZone == "Pescedex")
        #expect("chat-p-a-p-b" != ServiceAmisCloudKit.nomDeZone)
        #expect("chatclub-1" != ServiceAmisCloudKit.nomDeZone)
    }

    @Test func lAuteurEstMoiOuLAliasDuProprietaire() {
        let moi = CKRecord.ID(recordName: "_moi")
        #expect(ServiceProfilCloudKit.estMoi(CKRecord.ID(recordName: "_moi"), moi: moi))
        #expect(ServiceProfilCloudKit.estMoi(CKRecord.ID(recordName: CKCurrentUserDefaultName), moi: moi))
        #expect(!ServiceProfilCloudKit.estMoi(CKRecord.ID(recordName: "_autre"), moi: moi))
        #expect(!ServiceProfilCloudKit.estMoi(nil, moi: moi))
    }

    @Test func leSignalementDeProfilNePorteQueLIdentifiantEtLeMotif() throws {
        let url = try #require(Signalement.url(contact: "contact@exemple.invalid", profilID: "p-gros-brochet", motif: .spam))
        let texte = url.absoluteString.removingPercentEncoding ?? ""
        #expect(texte.contains("p-gros-brochet"))
        #expect(texte.contains("Spam"))
    }

    @Test func leSignalementDUnAmiPorteLeMotif() throws {
        let ami = Ami(id: "ami-1", nom: "gros-brochet", sens: .recu)
        let url = try #require(Signalement.url(contact: "contact@exemple.invalid", ami: ami, motif: .harcelement))
        let texte = url.absoluteString.removingPercentEncoding ?? ""
        #expect(texte.contains("ami-1") && texte.contains("Haine ou harcèlement"))
    }
}
