import Core
import Foundation
import Testing
@testable import BuildChallenge

/// Collecteur de faux : note ce qui serait envoyé.
private final class CollecteEspion: ServiceCollecteEmail, @unchecked Sendable {
    private let verrou = NSLock()
    private var _envoyes: [String] = []
    private var _supprimes: [String] = []
    var envoyes: [String] { verrou.lock(); defer { verrou.unlock() }; return _envoyes }
    var supprimes: [String] { verrou.lock(); defer { verrou.unlock() }; return _supprimes }
    func envoyer(email: String, langue: String) async -> Bool { verrou.withLock { _envoyes.append(email) }; return true }
    func supprimer(email: String) async -> Bool { verrou.withLock { _supprimes.append(email) }; return true }
}

@MainActor
struct OnboardingTests {
    private func reglagesNeufs() -> UserDefaults {
        let nom = "test.onboarding.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: nom)!
        d.removePersistentDomain(forName: nom)
        return d
    }

    private func compte() -> (CompteOnboarding, CollecteEspion, StockageEmailMemoire, UserDefaults) {
        let d = reglagesNeufs()
        let espion = CollecteEspion()
        let stockage = StockageEmailMemoire()
        return (CompteOnboarding(defauts: d, stockage: stockage, collecte: espion, filtre: FiltreCore()), espion, stockage, d)
    }

    // MARK: Langue

    @Test func laLangueDuTelephoneSertDePreselection() {
        #expect(LangueApp.duTelephone(["fr-FR", "en-US"]) == .francais)
        #expect(LangueApp.duTelephone(["en-GB"]) == .anglais)
        #expect(LangueApp.duTelephone(["de-DE"]) == .anglais)
    }

    @Test func laLangueChoisieEstIndependanteDeLaRegion() {
        let d = reglagesNeufs()
        let r = RegionCourante(reglages: d)
        r.choix = .etatsUnis
        #expect(r.region == .etatsUnis)
        #expect(r.langue == .anglais)                // sans choix : la langue suit la région (comportement d'avant)
        r.langueChoisie = .francais
        #expect(r.region == .etatsUnis)              // la région ne bouge pas
        #expect(r.langue == .francais)               // un Français aux États-Unis garde le français
        #expect(r.locale.identifier == "fr_FR")
        #expect(r.systemeUnites == .imperial)        // les unités suivent la région
        #expect(LanguePersistee.choix(d) == .francais)
    }

    @Test func unAmericainPeutChoisirEnglishAvecUnTelephoneFrancais() {
        let r = RegionCourante(reglages: reglagesNeufs())
        r.choix = .france
        r.langueChoisie = .anglais
        #expect(r.region == .france)
        #expect(r.locale.identifier == "en_US")
    }

    @Test func leChoixDeLangueEstMemorise() {
        let d = reglagesNeufs()
        RegionCourante(reglages: d).langueChoisie = .anglais
        #expect(RegionCourante(reglages: d).langueChoisie == .anglais)
    }

    // MARK: Surnom et e-mail

    @Test func lesAdressesEmailSontValideesLocalement() {
        #expect(AdresseEmail.estValide("pecheur@exemple.fr"))
        #expect(!AdresseEmail.estValide("pecheur@exemple"))
        #expect(!AdresseEmail.estValide("pecheur exemple@x.fr"))
        #expect(!AdresseEmail.estValide("@x.fr"))
        #expect(!AdresseEmail.estValide("a@@x.fr"))
        #expect(!AdresseEmail.estValide(""))
    }

    @Test func leSurnomExigeTroisAVingtCaracteres() async {
        let (c, _, _, _) = compte()
        let court = await c.enregistrer(surnom: "ab", ageDeclare: true, email: "", consentement: false, langue: "fr")
        #expect(court == .surnom(.tropCourt))
        let long = await c.enregistrer(surnom: String(repeating: "a", count: 21), ageDeclare: true, email: "", consentement: false, langue: "fr")
        #expect(long == .surnom(.tropLong))
        #expect(c.surnom == nil)
        let bon = await c.enregistrer(surnom: "Gros-Brochet", ageDeclare: true, email: "", consentement: false, langue: "fr")
        #expect(bon == nil)
        #expect(c.surnom == "Gros-Brochet")
    }

    @Test func sansDeclarationDAgeAucunSurnom() async {
        let (c, _, _, _) = compte()
        let echec = await c.enregistrer(surnom: "Brochet", ageDeclare: false, email: "", consentement: false, langue: "fr")
        #expect(echec == .ageRequis)
        #expect(c.surnom == nil)
    }

    @Test func sansConsentementAucunEmailNEstGardeNiEnvoye() async {
        let (c, espion, stockage, d) = compte()
        let echec = await c.enregistrer(surnom: "Brochet", ageDeclare: true, email: "moi@exemple.fr", consentement: false, langue: "fr")
        #expect(echec == nil)
        #expect(c.surnom == "Brochet")
        #expect(c.email == nil)
        #expect(stockage.lire() == nil)
        #expect(espion.envoyes.isEmpty)
        #expect(CompteLocal.emailConsenti(d) == false)
    }

    @Test func avecConsentementLEmailVaAuTrousseauEtAuServiceSeulement() async {
        let (c, espion, stockage, d) = compte()
        let echec = await c.enregistrer(surnom: "Brochet", ageDeclare: true, email: " moi@exemple.fr ", consentement: true, langue: "en")
        #expect(echec == nil)
        #expect(stockage.lire() == "moi@exemple.fr")
        #expect(espion.envoyes == ["moi@exemple.fr"])
        #expect(CompteLocal.emailConsenti(d))
        // L'e-mail n'est pas dans les réglages en clair.
        #expect(d.dictionaryRepresentation().values.compactMap { $0 as? String }.contains("moi@exemple.fr") == false)
    }

    @Test func unEmailInvalideAvecConsentementEstRefuse() async {
        let (c, espion, _, _) = compte()
        let echec = await c.enregistrer(surnom: "Brochet", ageDeclare: true, email: "pas-un-email", consentement: true, langue: "fr")
        #expect(echec == .emailInvalide)
        #expect(c.surnom == nil)
        #expect(espion.envoyes.isEmpty)
    }

    @Test func supprimerLEmailEffaceLeTrousseauEtDemandeLEffacement() async {
        let (c, espion, stockage, d) = compte()
        _ = await c.enregistrer(surnom: "Brochet", ageDeclare: true, email: "moi@exemple.fr", consentement: true, langue: "fr")
        await c.supprimerEmail()
        #expect(c.email == nil)
        #expect(stockage.lire() == nil)
        #expect(espion.supprimes == ["moi@exemple.fr"])
        #expect(CompteLocal.emailConsenti(d) == false)
        #expect(c.surnom == "Brochet")
    }

    @Test func supprimerLeCompteEffaceSurnomEtEmail() async {
        let (c, _, stockage, d) = compte()
        _ = await c.enregistrer(surnom: "Brochet", ageDeclare: true, email: "moi@exemple.fr", consentement: true, langue: "fr")
        await c.supprimerCompte()
        #expect(c.surnom == nil)
        #expect(c.email == nil)
        #expect(stockage.lire() == nil)
        #expect(CompteLocal.surnom(d) == nil)
        #expect(c.aUnCompte == false)
    }

    // MARK: Point de terminaison

    @Test func sansCleInfoRienNEstEnvoye() async {
        #expect(ConfigCollecteEmail.url(brute: nil) == nil)
        #expect(ConfigCollecteEmail.url(brute: "") == nil)
        #expect(ConfigCollecteEmail.url(brute: "   ") == nil)
        let appels = Compteur()
        let service = CollecteEmailHTTP(url: nil, envoyeur: { _ in await appels.ajouter(); return true })
        #expect(await service.envoyer(email: "a@b.fr", langue: "fr") == false)
        #expect(await service.supprimer(email: "a@b.fr") == false)
        #expect(await appels.valeur == 0)
    }

    @Test func seulHttpsEstAccepte() {
        #expect(ConfigCollecteEmail.url(brute: "http://exemple.org/c") == nil)
        #expect(ConfigCollecteEmail.url(brute: "https://exemple.org/c")?.host == "exemple.org")
    }

    @Test func lEnvoiEstUnPostJSONAvecEmailEtLangueSeulement() async throws {
        let derniere = Capture()
        let service = CollecteEmailHTTP(url: URL(string: "https://exemple.org/c"), envoyeur: { requete in
            await derniere.poser(requete); return true
        })
        #expect(await service.envoyer(email: "a@b.fr", langue: "en"))
        let requete = try #require(await derniere.valeur)
        #expect(requete.httpMethod == "POST")
        let corps = try #require(requete.httpBody)
        let json = try #require(try JSONSerialization.jsonObject(with: corps) as? [String: String])
        #expect(json == ["action": "inscription", "email": "a@b.fr", "langue": "en"])
    }

    // MARK: Textes

    @Test func lesTextesDeLOnboardingEvitentLesMotsInterdits() {
        for langue in LangueApp.allCases {
            let t = TextesOnboarding(langue: langue, ageMinimum: 15)
            let tout = [t.replique1, t.replique2, t.replique3, t.replique4, t.aideEmail, t.consentement, t.aideZone, t.aideLangue]
                .joined(separator: " ").lowercased()
            for mot in ["autoris", "allowed", "legal", "légal", "poké"] { #expect(!tout.contains(mot), "« \(mot) » dans \(langue)") }
        }
    }

    @Test func lAgeMinimumSuitLaRegion() {
        #expect(TextesOnboarding(langue: .francais, ageMinimum: 15).age == "J'ai 15 ans ou plus")
        #expect(TextesOnboarding(langue: .anglais, ageMinimum: 13).age == "I am 13 or older")
    }

    // MARK: Noms d'espèces

    @Test func lesNomsDEspecesSuiventLaLangueChoisie() {
        let brochet = EspecePechable(espece: Espece(id: "brochet"), nom: "Brochet", nomLatin: "Esox lucius", image: "brochet")
        LangueNoms.courante = .en
        #expect(brochet.nom == "Northern pike")
        LangueNoms.courante = .fr
        #expect(brochet.nom == "Brochet")
    }
}

private actor Compteur {
    private(set) var valeur = 0
    func ajouter() { valeur += 1 }
}

private actor Capture {
    private(set) var valeur: URLRequest?
    func poser(_ r: URLRequest) { valeur = r }
}
