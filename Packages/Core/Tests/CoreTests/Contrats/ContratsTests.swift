import Foundation
import Testing
@testable import Core

private let coord = Coordonnee(latitude: 48.82, longitude: 2.41)
private let unJour = Date(timeIntervalSince1970: 1_792_065_600)

@Suite("Faux de géographie, règles, espèces")
struct FauxDonneesTests {
    @Test func geo() {
        let faux = GeoFaux()
        #expect(faux.departement(de: coord).code == "94")
        let lieu = faux.lieu(de: coord, choix: nil)
        #expect(lieu.eau?.nom == "La Marne")
        #expect(lieu.categorie.valeur == .deuxieme)
        #expect(faux.eauxProches(coord).count == 2)
        #expect(faux.lieuFlou(coord) == "La Marne · 94")
    }

    @Test func departementInconnu() {
        #expect(Departement.inconnu.estInconnu)
        #expect(Lieu.inconnu.departement.estInconnu)
        #expect(Lieu.inconnu.categorie == .inconnue)
    }

    @Test func regles() {
        let faux = ReglesFaux()
        let r = faux.controle(espece: brochet, tailleCm: 60, mesure: .toise, date: unJour, lieu: .inconnu, prisesDuJour: [])
        #expect(r.consigne == .aucuneRegleSaisieNeLInterdit)
        #expect(r.lignes.first?.sources.count == 2)
        #expect(faux.reglesDuJour(lieu: .inconnu, date: unJour).count == 1)
        #expect(faux.verdictTaille(longueurCm: 55, mesure: .estimee, maille: 60) == .sansVerdict)
        #expect(faux.verdictTaille(longueurCm: 61, mesure: .toise, maille: 60) == .respectee)
        #expect(faux.departementsCouverts().count == 1)
        #expect(faux.credits().count == 1)
        #expect(faux.liensFederation(departement: Departement(code: "94")).siteFederation != nil)
    }

    @Test func reglesJouentChaqueConsigne() {
        for consigne in [Consigne.relacheLa, .mesureLaSurUneToise, .verifieLArrete] {
            let faux = ReglesFaux(resultat: ResultatControle(lignes: [], consigne: consigne))
            #expect(faux.controle(espece: brochet, tailleCm: nil, mesure: nil, date: unJour, lieu: .inconnu, prisesDuJour: []).consigne == consigne)
        }
    }

    @Test func especes() {
        let faux = EspecesFaux()
        let rarete = faux.rarete(espece: brochet, departement: Departement(code: "94"))
        #expect(rarete.nPeches == 9 && rarete.nTotal == 29 && rarete.echelle == .departement)
        #expect(faux.especesProches(coord).count == 2)
        #expect(faux.coins(ou: brochet, pres: coord).count == 1)
        #expect(faux.especesPechables().count == 6)
        #expect(faux.poidsEstime(espece: brochet, longueurCm: 60)?.kilos == 1.4)
    }

    @Test func stationsDansFiltreParRectangle() {
        let faux = EspecesFaux()
        let paris = RegionCarte(sudOuest: Coordonnee(latitude: 48.0, longitude: 2.0), nordEst: Coordonnee(latitude: 49.0, longitude: 3.0))
        let s = faux.stationsDans(paris)
        #expect(s.count == 1 && s[0].especes.count == 2 && s[0].especes[0].nPeches == 9)
        let large = RegionCarte(sudOuest: Coordonnee(latitude: 47.0, longitude: 1.0), nordEst: Coordonnee(latitude: 49.0, longitude: 3.0))
        #expect(faux.stationsDans(large).count == 2)
        let ailleurs = RegionCarte(sudOuest: Coordonnee(latitude: 10, longitude: 10), nordEst: Coordonnee(latitude: 11, longitude: 11))
        #expect(faux.stationsDans(ailleurs).isEmpty)
    }

    @Test func stationsDansParDefautVide() {
        struct Ancien: ServiceEspeces {
            func rarete(espece: Espece, departement: Departement) -> ResultatRarete { EspecesFaux().rarete(espece: espece, departement: departement) }
            func especesProches(_ c: Coordonnee) -> [EspeceProche] { [] }
            func coins(ou espece: Espece, pres c: Coordonnee) -> [Coin] { [] }
            func especesPechables() -> [EspecePechable] { [] }
            func classer(scores: [String: Double], especesProches: [Espece]) -> [Proposition] { [] }
            func poidsEstime(espece: Espece, longueurCm: Double) -> PoidsEstime? { nil }
        }
        let r = RegionCarte(sudOuest: Coordonnee(latitude: 0, longitude: 0), nordEst: Coordonnee(latitude: 1, longitude: 1))
        #expect(Ancien().stationsDans(r).isEmpty)
    }

    @Test func classerRendTroisPropositionsPuisAutreEtPasUnPoisson() {
        let p = EspecesFaux().classer(scores: [:], especesProches: [])
        #expect(p.count == 5)
        #expect(Array(p.suffix(2)) == [Proposition(type: .autreEspece), Proposition(type: .pasUnPoisson)])
    }

    @Test func lesFauxUtilisentDesIdentifiantsDeLaListeNationale() {
        #expect(Espece.identifiantsNationaux.count == 77)
        for e in EspecesFaux().especesPechables() {
            #expect(e.espece.estDansLaListeNationale, "\(e.espece.id) absent de la liste nationale")
        }
    }

    @Test func soleil() {
        let faux = SoleilFaux()
        #expect(faux.finLegale(date: unJour, coordonnee: coord) != nil)
        #expect(faux.phaseLune(date: unJour) == .pleine)
    }
}

@Suite("Faux de session, conditions, conseils")
struct FauxSessionTests {
    @Test func session() {
        let faux = SessionFaux()
        let spot = Spot(centre: coord, departement: Departement(code: "94"))
        #expect(faux.spotPropose(coordonnee: coord, date: unJour)?.rayonM == 1000)
        #expect(faux.acces(sessionsTerminees: 0, spot: spot, spotGratuit: nil, abonne: false).sessionPermise)
        #expect(faux.quota(prisesGardeesDuJour: [], departement: Departement(code: "94")).plafond == 3)
        #expect(faux.offreAffichee(date: unJour).prixCentimes == 3499)
    }

    @Test func peutUtiliserToujoursOuvertOuFerme() {
        for f in FonctionPro.allCases {
            #expect(SessionFaux(toutOuvert: true).peutUtiliser(f, abonne: false, surSonSpot: false))
            #expect(!SessionFaux(toutOuvert: false).peutUtiliser(f, abonne: true, surSonSpot: true))
        }
    }

    @Test func conditions() {
        let faux = ConditionsFaux()
        let meteo = MeteoBrute(heures: [])
        #expect(faux.lireConditions(meteo: meteo, eau: nil, date: unJour).tendancePressionHPa6h == -3)
        #expect(faux.alerte(meteo: meteo, eau: nil) == nil)
        #expect(AlerteOrageFaux.alerte.type == .orage)
        #expect(AlerteCrueFaux.alerte.type == .crue)
        #expect(faux.stationHydro(pres: coord)?.code == "F000TEST")
        #expect(faux.pointMeteo(spot: coord) != coord)
        #expect(faux.tesConditions(sorties: [])?.count == 2)
    }

    @Test func niveauEauFauxQuatreEtatsSansReseau() async {
        let station = stationCharenton
        let normal = await NiveauEauFaux(scenario: .normal).niveau(station: station)
        let haut = await NiveauEauFaux(scenario: .haut).niveau(station: station)
        let hausse = await NiveauEauFaux(scenario: .forteHausse).niveau(station: station)
        let rien = await NiveauEauFaux(scenario: .sansReseau).niveau(station: station)
        #expect(normal?.vigilance == .vert)
        #expect((haut?.debitM3s ?? 0) > 2 * (haut?.normaleDebitM3s ?? .infinity))
        #expect(hausse?.serie48h.count == 2)
        #expect(rien == nil)
    }

    @Test func conseils() {
        let faux = ConseilsFaux()
        let c = faux.conseils(espece: brochet, niveau: .debutant, mois: 10)
        #expect(c.count == 2 && c[0].gratuit && !c[1].gratuit)
        #expect(faux.conseils(espece: brochet, niveau: .confirme, mois: 10, lieu: .inconnu).count == 2)
        #expect(NiveauPecheur.debutant.rawValue == "debutant")
    }
}

@Suite("Faux d'app : identification, achats, mesure, collection")
struct FauxAppTests {
    @Test func identification() async {
        let scores = await IdentifieEspeceFaux().identifier(photo: Data())
        if case .scores(let s) = scores { #expect(s["brochet"] != nil) } else { Issue.record("scores attendus") }
        let grille = await IdentifieEspeceFaux(resultat: .grille(raison: .aucunModele)).identifier(photo: Data())
        #expect(grille == .grille(raison: .aucunModele))
    }

    @Test func achatsJoueChaqueEtat() async {
        #expect(await AchatsFaux().etat() == .nonAbonne)
        #expect(await AchatsFaux().acheter(produit: "annuel") == .abonne)
        #expect(await AchatsFaux.remboursement.etat() == .rembourse)
        #expect(await AchatsFaux.revocation.etat() == .revoque)
        #expect(await AchatsFaux.sansReseau.etat().donneAcces)
        #expect(await AchatsFaux.delaiDeGrace.restaurer() == .expire)
        var vus: [EtatAchats] = []
        for await e in AchatsFaux.delaiDeGrace.modifications() { vus.append(e) }
        #expect(vus.count == 4)
        let grace = vus.first { if case .delaiDeGrace = $0 { return true } else { return false } }
        #expect(grace?.donneAcces == true)
        #expect(!EtatAchats.relancePaiement.donneAcces)
        #expect(!EtatAchats.rembourse.donneAcces && !EtatAchats.revoque.donneAcces && !EtatAchats.expire.donneAcces)
    }

    @Test func mesure() {
        let faux = MesureFaux()
        for e in EvenementMesure.allCases { faux.envoyer(e) }
        #expect(faux.evenements.count == 6)
    }

    @Test func carteDeclareeDistincteDUneVraiePrise() async {
        let cartes = await CollectionFaux().cartes()
        #expect(cartes.filter(\.estDeclaree).count == 1)
        let declaree = Prise.declaree(espece: perche, date: unJour)
        #expect(declaree.origine == .declaree)
        #expect(declaree.cheminPhoto == nil && declaree.longueurCm == nil && !declaree.gardee)
        #expect(Prise(espece: brochet, date: unJour).origine == .priseReelle)
        #expect(await CollectionFaux().imagePNG(de: declaree) == nil)
        #expect(await CollectionFaux().imagePNG(de: cartes[0]) != nil)
    }

    @Test func prisesSeCodentEtSeDecodent() throws {
        let p = Prise.declaree(espece: perche, date: unJour)
        let data = try JSONEncoder().encode(p)
        #expect(try JSONDecoder().decode(Prise.self, from: data) == p)
    }
}

@Suite("Ressources déclarées par Package.swift")
struct RessourcesTests {
    private func lire(_ nom: String, _ ext: String, _ sousDossier: String? = nil) -> Data? {
        guard let url = Bundle.module.url(forResource: nom, withExtension: ext, subdirectory: sousDossier) else { return nil }
        return try? Data(contentsOf: url)
    }

    @Test func fichiersTrouvesEtJSONValide() throws {
        let fichiers: [(String, String, String?)] = [
            ("index", "json", "regles"), ("especes", "json", nil), ("longueur-poids", "json", nil), ("conseils", "json", nil),
            ("cas-verdicts", "json", nil), ("credits", "json", nil), ("liens-federations", "json", nil),
            ("coins-maison", "json", nil),
            ("stations-hydro", "json", nil), ("departements", "geojson", nil), ("lacs", "geojson", nil), ("coins-osm", "geojson", nil),
        ]
        for (nom, ext, dossier) in fichiers {
            let data = try #require(lire(nom, ext, dossier), "\(nom).\(ext) introuvable dans Bundle.module")
            _ = try JSONSerialization.jsonObject(with: data)
        }
    }

    /// La page Sources lit `nom`, `url` et `mention` de `credits.json` : les mentions de licence de N3 (Hub'Eau / Naïades) et de la liste LDNOOBW y sont. ⚠ à vérifier (jamais compilé)
    @Test func creditsContiennentLesMentionsDeLicence() throws {
        let data = try #require(lire("credits", "json"))
        let credits = MoteurCore.lireCredits(data)
        let eau = try #require(credits.first { $0.nom.contains("Naïades") })
        #expect(eau.mention == "Données : Hub'Eau / Naïades, Licence Ouverte (Etalab)")
        let mots = try #require(credits.first { $0.nom.contains("LDNOOBW") })
        #expect(mots.mention?.contains("CC BY 4.0") == true)
        #expect(mots.url != nil)
    }
}
