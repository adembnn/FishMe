import Foundation
import Testing
@testable import Core

@Suite("Soleil et lune")
struct SoleilTests {
    let soleil = MoteurSoleil()

    /// Références de sunrise-sunset.org (UTC). Ce site donne un jour plus long de 2 min environ que l'US Naval Observatory
    /// (Paris, 15 oct. 2026 : lever 06:11 et coucher 17:01 chez l'USNO) : la tolérance est de 2,5 min, et le test suivant compare à l'USNO.
    @Test("Lever et coucher à 2,5 min près de sunrise-sunset.org sur 5 dates",
          arguments: [
            (paris, utc(2026, 10, 15, 12), utc(2026, 10, 15, 6, 9, 29), utc(2026, 10, 15, 17, 3, 14)),
            (paris, utc(2026, 6, 21, 12), utc(2026, 6, 21, 3, 44, 59), utc(2026, 6, 21, 19, 59, 51)),
            (paris, utc(2026, 12, 21, 12), utc(2026, 12, 21, 7, 39, 17), utc(2026, 12, 21, 15, 58, 1)),
            (Coordonnee(latitude: 43.2965, longitude: 5.3698), utc(2026, 3, 20, 12), utc(2026, 3, 20, 5, 40, 6), utc(2026, 3, 20, 17, 51, 51)),
            (Coordonnee(latitude: 50.6292, longitude: 3.0573), utc(2027, 1, 15, 12), utc(2027, 1, 15, 7, 40, 58), utc(2027, 1, 15, 16, 13, 11)),
          ])
    func leverEtCoucher(point: Coordonnee, date: Date, lever: Date, coucher: Date) throws {
        let r = try #require(soleil.leverEtCoucher(date: date, coordonnee: point))
        #expect(abs(r.lever.timeIntervalSince(lever)) <= 150)
        #expect(abs(r.coucher.timeIntervalSince(coucher)) <= 150)
    }

    @Test("Paris le 15/10/2026 : lever 06:11 et coucher 17:01 UTC, à la minute (US Naval Observatory)")
    func parisContreLUSNO() throws {
        let r = try #require(soleil.leverEtCoucher(date: quinzeOctobre, coordonnee: paris))
        #expect(abs(r.lever.timeIntervalSince(utc(2026, 10, 15, 6, 11))) <= 60)
        #expect(abs(r.coucher.timeIntervalSince(utc(2026, 10, 15, 17, 1))) <= 60)
    }

    @Test("Fin légale = coucher + 30 min, moins 1 min de marge")
    func finLegale() throws {
        let fin = try #require(soleil.finLegale(date: utc(2026, 10, 15, 16), coordonnee: paris))
        let attendue = utc(2026, 10, 15, 17, 3, 14).addingTimeInterval(29 * 60)
        #expect(abs(fin.timeIntervalSince(attendue)) <= 150)
    }

    @Test("Un départ à 18 h 30 (heure de Paris) un jour d'octobre : la fin légale du jour, à 2,5 min près")
    func departEnSoiree() throws {
        let fin = try #require(soleil.finLegale(date: utc(2026, 10, 15, 16, 30), coordonnee: paris))
        #expect(abs(fin.timeIntervalSince(utc(2026, 10, 15, 17, 32, 14))) <= 150)
    }

    @Test("Pas de coucher au pôle en été : nil")
    func polaire() {
        #expect(soleil.finLegale(date: utc(2026, 6, 21), coordonnee: Coordonnee(latitude: 80, longitude: 10)) == nil)
    }

    /// Phases du 3, 10, 18 et 26 octobre 2026 (US Naval Observatory).
    @Test("Lune juste sur 4 dates",
          arguments: [(utc(2026, 10, 3, 13, 25), PhaseLune.dernierQuartier), (utc(2026, 10, 10, 15, 50), .nouvelle),
                      (utc(2026, 10, 18, 16, 12), .premierQuartier), (utc(2026, 10, 26, 4, 12), .pleine)])
    func lune(date: Date, phase: PhaseLune) {
        #expect(soleil.phaseLune(date: date) == phase)
    }

    @Test("Toutes les phases se succèdent sur un mois")
    func cycle() {
        var vues: Set<PhaseLune> = []
        for j in 0..<30 { vues.insert(soleil.phaseLune(date: utc(2026, 10, 10, 15).addingTimeInterval(Double(j) * 86400))) }
        #expect(vues.count == 8)
    }
}

@Suite("Session : quota, accès, offre, spot proposé")
struct SessionTests {
    let moteur = moteurEssai()
    var session: MoteurSession { moteur.session }
    let quatreVingtQuatorze = Departement(code: "94")

    func gardee(_ e: Espece, _ heure: Int, jour: Int = 15) -> Prise { Prise(espece: e, date: utc(2026, 10, jour, heure), gardee: true) }

    @Test("Quota du jour au 3e carnassier, compté sur toutes les sessions du jour (2 puis 1 : atteint)")
    func quota() {
        let premiere = [gardee(brochetEssai, 8), gardee(sandreEssai, 9)]
        let deuxieme = [gardee(blackBassEssai, 17)]
        let apres2 = session.quota(prisesGardeesDuJour: premiere, departement: quatreVingtQuatorze)
        #expect(apres2.gardees == 2)
        #expect(apres2.plafond == 3)
        let apres3 = session.quota(prisesGardeesDuJour: premiere + deuxieme, departement: quatreVingtQuatorze)
        #expect(apres3.gardees == 3)
        #expect(apres3.plafond == 3)
        #expect(apres3.gardees >= (apres3.plafond ?? .max))
        #expect(apres3.source?.titre == "Avis annuel 2026 Val-de-Marne")
    }

    @Test("Le quota vient des fichiers, jamais écrit en dur : un autre fichier donne un autre plafond")
    func quotaDesFichiers() {
        let autre = fichierRegles(departement: "94", regles: [
            regle("94-car-quota", "quota_jour", especes: ["2151", "2195", "2053"], cat: "2", niveau: "departement", code: "94", valeur: ["total": 5], phrase: "Cinq carnassiers.", remplace: "nat-car-quota"),
        ])
        let m = moteurEssai(regles: chargeurEssai(extra: ["94": autre])).session
        #expect(m.quota(prisesGardeesDuJour: [gardee(brochetEssai, 8)], departement: quatreVingtQuatorze).plafond == 5)
        let sans = ChargeurRegles(sources: [SourceMemoire(fichiers: [:])])
        let vide = moteurEssai(regles: sans).session
        #expect(vide.quota(prisesGardeesDuJour: [gardee(brochetEssai, 8)], departement: quatreVingtQuatorze).plafond == nil)
    }

    @Test("Les cartes déclarées et les prises relâchées ne comptent pas")
    func quotaIgnoreLesCartesDeclarees() {
        let prises = [Prise.declaree(espece: brochetEssai, date: quinzeOctobre), Prise(espece: brochetEssai, date: quinzeOctobre, gardee: false)]
        #expect(session.quota(prisesGardeesDuJour: prises, departement: quatreVingtQuatorze).gardees == 0)
    }

    // MARK: acces

    let spotGratuit = Spot(centre: charenton, rayonM: 1000, departement: Departement(code: "94"))

    @Test("Fin de 1re session : paywall qui se ferme ; sessions illimitées dans le spot gratuit")
    func accesDansLeSpot() {
        let finPremiere = session.acces(sessionsTerminees: 1, spot: spotGratuit, spotGratuit: spotGratuit, abonne: false)
        #expect(finPremiere.sessionPermise)
        #expect(finPremiere.paywall == .quiSeFerme)
        for n in [0, 2, 3, 12, 100] {
            let d = session.acces(sessionsTerminees: n, spot: spotGratuit, spotGratuit: spotGratuit, abonne: false)
            #expect(d.sessionPermise)
            #expect(d.paywall == .aucun)
        }
        // À 900 m du centre : encore dans le spot ; à 1,2 km : dehors.
        let a900 = Spot(centre: Coordonnee(latitude: 48.822 + 0.0081, longitude: 2.413), departement: Departement(code: "94"))
        #expect(session.acces(sessionsTerminees: 4, spot: a900, spotGratuit: spotGratuit, abonne: false).sessionPermise)
        let a1200 = Spot(centre: Coordonnee(latitude: 48.822 + 0.0108, longitude: 2.413), departement: Departement(code: "94"))
        #expect(!session.acces(sessionsTerminees: 4, spot: a1200, spotGratuit: spotGratuit, abonne: false).sessionPermise)
    }

    @Test("Un autre spot : le paywall bloque")
    func accesAutreSpot() {
        let ailleurs = Spot(centre: meaux, departement: Departement(code: "77"))
        let d = session.acces(sessionsTerminees: 3, spot: ailleurs, spotGratuit: spotGratuit, abonne: false)
        #expect(!d.sessionPermise)
        #expect(d.paywall == .quiBloque)
        #expect(d.spotGratuit == spotGratuit)
        // Abonné : tout est permis.
        #expect(session.acces(sessionsTerminees: 3, spot: ailleurs, spotGratuit: spotGratuit, abonne: true).sessionPermise)
        #expect(session.acces(sessionsTerminees: 3, spot: ailleurs, spotGratuit: spotGratuit, abonne: true).paywall == .aucun)
    }

    @Test("La 1re session est permise sans spot fixé, et son lieu devient le spot gratuit")
    func premiereSession() {
        let spot = Spot(centre: meaux, rayonM: 5000, departement: Departement(code: "77"))
        let d = session.acces(sessionsTerminees: 0, spot: spot, spotGratuit: nil, abonne: false)
        #expect(d.sessionPermise)
        #expect(d.paywall == .aucun)
        #expect(d.spotGratuit?.centre == meaux)
        #expect(d.spotGratuit?.rayonM == 1000)
    }

    @Test("Un point de Cupertino : session permise avec « hors de France : aucune règle française »")
    func horsDeFrance() {
        let spot = Spot(centre: cupertino, departement: moteur.geo.departement(de: cupertino))
        let d = session.acces(sessionsTerminees: 0, spot: spot, spotGratuit: nil, abonne: false)
        #expect(d.sessionPermise)
        #expect(d.message == "hors de France : aucune règle française")
        #expect(session.acces(sessionsTerminees: 0, spot: spotGratuit, spotGratuit: nil, abonne: false).message == nil)
    }

    // MARK: peutUtiliser et offre

    @Test("peutUtiliser : sans abonnement sur son spot, météo du jour et niveau ouverts, 7 jours fermé ; hors de son spot, tout fermé ; abonné, tout ouvert")
    func peutUtiliser() {
        #expect(session.peutUtiliser(.meteoDuJour, abonne: false, surSonSpot: true))
        #expect(session.peutUtiliser(.niveauEau, abonne: false, surSonSpot: true))
        #expect(!session.peutUtiliser(.septJours, abonne: false, surSonSpot: true))
        for f in FonctionPro.allCases {
            #expect(!session.peutUtiliser(f, abonne: false, surSonSpot: false))
            #expect(session.peutUtiliser(f, abonne: true, surSonSpot: false))
            #expect(session.peutUtiliser(f, abonne: true, surSonSpot: true))
            if f != .meteoDuJour && f != .niveauEau { #expect(!session.peutUtiliser(f, abonne: false, surSonSpot: true)) }
        }
    }

    @Test("offreAffichee : 34,99 jusqu'au 31/12/2026, 49,99 ensuite")
    func offre() {
        let avant = session.offreAffichee(date: utc(2026, 12, 31, 12))
        #expect(avant.prixCentimes == 3499)
        #expect(avant.tarifFondateur)
        let apres = session.offreAffichee(date: utc(2027, 1, 1, 12))
        #expect(apres.prixCentimes == 4999)
        #expect(!apres.tarifFondateur)
        #expect(avant.produit != apres.produit)
        #expect(session.offreAffichee(date: utc(2026, 10, 15)).prixCentimes == 3499)
    }

    // MARK: spotPropose

    @Test("spotPropose près de Charenton : un coin aux relevés récents et à l'espèce ouverte ce jour")
    func spotProposeProcheDeCharenton() throws {
        let spot = try #require(session.spotPropose(coordonnee: charenton, date: quinzeOctobre))
        #expect(spot.centre == Coordonnee(latitude: 48.8235, longitude: 2.4160))
        #expect(spot.rayonM == 1000)
        #expect(spot.departement.code == "94")
    }

    @Test("spotPropose saute un coin aux relevés de 2009 et un coin où seule une espèce fermée est relevée")
    func spotProposeSauteLesMauvaisCoins() throws {
        // Depuis le Morbras (S3, truite fario fermée), le coin le plus proche qui convient est S2 ou S1, jamais S3 ni S4 (2009).
        let depuisS3 = try #require(session.spotPropose(coordonnee: Coordonnee(latitude: 48.7600, longitude: 2.4000), date: quinzeOctobre))
        #expect(depuisS3.centre != Coordonnee(latitude: 48.7600, longitude: 2.4000))
        let depuisS4 = try #require(session.spotPropose(coordonnee: Coordonnee(latitude: 48.8300, longitude: 2.3800), date: quinzeOctobre))
        #expect(depuisS4.centre != Coordonnee(latitude: 48.8300, longitude: 2.3800))
    }

    @Test("spotPropose : aucun coin qui convient à moins de 30 km, pas de proposition")
    func spotProposeAucun() {
        #expect(session.spotPropose(coordonnee: Coordonnee(latitude: 47.0, longitude: 5.0), date: quinzeOctobre) == nil)
        #expect(session.spotPropose(coordonnee: cupertino, date: quinzeOctobre) == nil)
        let sansStations = MoteurCore(donnees: donneesEssai(stations: nil), horloge: { quinzeOctobre }).session
        #expect(sansStations.spotPropose(coordonnee: charenton, date: quinzeOctobre) == nil)
    }
}
