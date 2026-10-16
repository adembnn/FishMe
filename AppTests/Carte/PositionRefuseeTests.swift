import CoreLocation
import Foundation
import Testing
import Core
@testable import BuildChallenge

/// Position refusée : redemande unique, choix de zone sans GPS, spot proposé, rien de bloqué.
@MainActor
struct PositionRefuseeTests {

    private func reglagesVierges() -> UserDefaults {
        UserDefaults(suiteName: "position-tests-\(UUID().uuidString)")!
    }

    private let cleRedemande = "carte.redemandeFaite"

    // MARK: Redemande

    @Test func laRedemandeNaLieuQuUneFoisApresUnRefus() {
        let gestion = GestionPosition(reglages: reglagesVierges(), statutInitial: .denied)
        #expect(gestion.estRefusee)
        #expect(gestion.doitRedemanderUneFois())
        #expect(!gestion.doitRedemanderUneFois())
    }

    @Test func pasDeRedemandeSiLaQuestionDuSystemACompte() {
        let reglages = reglagesVierges()
        reglages.set(true, forKey: cleRedemande)  // posé par demanderAuPremierEcran() au premier lancement
        let gestion = GestionPosition(reglages: reglages, statutInitial: .denied)
        #expect(!gestion.doitRedemanderUneFois())
    }

    @Test func pasDeRedemandeSiLaPositionEstAccordeeOuPasDemandee() {
        let accordee = GestionPosition(reglages: reglagesVierges(), statutInitial: .authorizedWhenInUse)
        #expect(accordee.estAutorisee && !accordee.doitRedemanderUneFois())
        let neuve = GestionPosition(reglages: reglagesVierges(), statutInitial: .notDetermined)
        #expect(neuve.nAPasEteDemandee && !neuve.doitRedemanderUneFois())
    }

    @Test func restreinteCompteCommeRefusee() {
        let gestion = GestionPosition(reglages: reglagesVierges(), statutInitial: .restricted)
        #expect(gestion.estRefusee)
        #expect(gestion.position == nil)
    }

    // MARK: Choix de zone

    @Test func unRefusOuvreLeChoixDeZone() {
        let modele = ModeleCarte(services: .faux())
        modele.appliquer(position: nil, refusee: true)
        #expect(modele.depart == .choixDeZone)
        #expect(modele.afficherChoixDeZone)
    }

    @Test func laZoneChoisieDonneUnSpotSansGPS() async {
        let modele = ModeleCarte(services: .faux())
        modele.appliquer(position: nil, refusee: true)
        let zone = Coordonnee(latitude: 45.77, longitude: 3.08)
        modele.choisirZone(zone)
        #expect(modele.depart == .zoneChoisie(zone))
        #expect(!modele.afficherChoixDeZone)
        #expect(modele.pointDeReference == zone)
        for _ in 0..<50 where modele.spotAffiche == nil { try? await Task.sleep(for: .milliseconds(20)) }
        #expect(modele.spotAffiche != nil)
    }

    @Test func laZoneChoisieNeRouvrePasLeChoix() {
        let modele = ModeleCarte(services: .faux())
        modele.choisirZone(Coordonnee(latitude: 45.77, longitude: 3.08))
        modele.appliquer(position: nil, refusee: true)
        #expect(!modele.afficherChoixDeZone)
    }

    @Test func horsDeFranceLaCarteTombeSurParisSansRouvrirLeChoix() {
        var services = ServicesCarte.faux()
        services.geo = GeoHorsDeFrance()
        let modele = ModeleCarte(services: services)
        modele.choisirZone(Coordonnee(latitude: 51.5, longitude: -0.12))
        #expect(modele.depart == .horsDeFrance)
        #expect(modele.message != nil)
        modele.appliquer(position: nil, refusee: true)
        #expect(!modele.afficherChoixDeZone)
    }

    @Test func sansSpotProposeLePecheurPeutEnPoserUn() {
        let modele = ModeleCarte(services: .faux())
        modele.appliquer(position: nil, refusee: true)
        #expect(modele.spotAffiche == nil)
        #expect(modele.peutChangerDeSpot)
        let spot = modele.poserSpot(en: Coordonnee(latitude: 48.82, longitude: 2.41))
        #expect(spot != nil)
        #expect(modele.spotAffiche == spot)
    }
}

private struct GeoHorsDeFrance: ServiceGeo {
    func departement(de coordonnee: Coordonnee) -> Departement { .inconnu }
    func lieu(de coordonnee: Coordonnee, choix: ChoixLieu?) -> Lieu { Lieu(departement: .inconnu) }
    func eauxProches(_ coordonnee: Coordonnee) -> [Eau] { [] }
    func lieuFlou(_ coordonnee: Coordonnee) -> String { "" }
}
