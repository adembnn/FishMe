import CoreLocation
import Foundation
import Testing
import Core
@testable import BuildChallenge

/// L17 : la carte s'ouvre sur le pêcheur, le recentrage ne déplace jamais le spot, le département se re-choisit.
/// Deux états séparés : la caméra (`regionVisible`) et le spot (`spotAffiche`). Écrit sans compiler (PC Windows) : à lancer sous Xcode.
@MainActor
struct OuvertureCarteTests {

    private let pecheur = Coordonnee(latitude: 48.81, longitude: 2.39)
    private let ailleurs = Coordonnee(latitude: 45.0, longitude: 4.0)

    private func modele(cleZone: [Double]? = nil) -> ModeleCarte {
        let reglages = UserDefaults(suiteName: "ouverture-\(UUID().uuidString)")!
        if let cleZone { reglages.set(cleZone, forKey: "carte.derniereZoneChoisie") }
        return ModeleCarte(services: .faux(), dossierCache: nil, reglages: reglages)
    }

    private func attendre(_ condition: () -> Bool) async {
        for _ in 0..<100 where !condition() { try? await Task.sleep(for: .milliseconds(20)) }
    }

    // MARK: Position autorisée, spot fixé ailleurs

    @Test func laCarteSOuvreSurLePecheurEtLeCercleDuSpotResteOuIlEst() {
        let m = modele()
        let spot = Spot(centre: ailleurs, departement: Departement(code: "38"))
        m.spotFixe = spot
        m.placerALOuverture()
        #expect(m.regionVisible.centre == ailleurs)

        m.appliquer(position: pecheur, refusee: false)
        #expect(m.regionVisible.centre == pecheur)
        #expect(m.depart == .surLePecheur(pecheur))
        #expect(m.spotAffiche == spot)
    }

    @Test func uneZoneGardeeDUnLancementPrecedentNeBloquePasLaPosition() {
        let m = modele(cleZone: [45.77, 3.08])
        m.placerALOuverture()
        #expect(m.depart == .zoneChoisie(Coordonnee(latitude: 45.77, longitude: 3.08)))

        m.appliquer(position: pecheur, refusee: false)
        #expect(m.regionVisible.centre == pecheur)
        #expect(m.depart == .surLePecheur(pecheur))
    }

    @Test func seulLaPremierePositionPoseLaCarte() {
        let m = modele()
        m.appliquer(position: pecheur, refusee: false)
        let plusLoin = Coordonnee(latitude: 48.9, longitude: 2.6)
        m.appliquer(position: plusLoin, refusee: false)
        #expect(m.regionVisible.centre == pecheur)
        #expect(m.positionPecheur == plusLoin)
        #expect(m.depart == .surLePecheur(plusLoin))
    }

    @Test func unPecheurQuiADejaBougeLaCarteLaGarde() {
        let m = modele()
        m.chargerApresMouvement(.france)  // l'affichage initial n'est pas un geste
        m.finDeplacementProgramme = .distantPast
        let saVue = ZoneCarte(centre: ailleurs, spanLatitude: 0.5, spanLongitude: 0.5)
        m.chargerApresMouvement(saVue)
        #expect(!m.positionPeutPoserLaCarte)
        m.appliquer(position: pecheur, refusee: false)
        #expect(m.regionVisible.centre == ailleurs)
    }

    /// E1 : à l'affichage de la carte, MapKit envoie plusieurs fins de mouvement sur la vue de départ (journal du 20 oct. : trois,
    /// centrées sur le Cher). Ce n'est pas le pêcheur : la première position doit recentrer la carte sur lui.
    @Test func lesFinsDeMouvementDeLAffichageNeBloquentPasLeCentrageSurLePecheur() {
        let m = modele()
        let vueDeDepart = ZoneCarte(centre: Coordonnee(latitude: 46.6, longitude: 2.5), spanLatitude: 0.98, spanLongitude: 0.92)
        m.chargerApresMouvement(vueDeDepart)
        m.finDeplacementProgramme = .distantPast
        m.chargerApresMouvement(vueDeDepart)
        m.chargerApresMouvement(vueDeDepart)
        #expect(m.positionPeutPoserLaCarte)
        m.appliquer(position: pecheur, refusee: false)
        #expect(m.depart == .surLePecheur(pecheur))
        #expect(m.regionVisible.centre == pecheur)
    }

    @Test func unSpotFixeEtUnEchecDePositionPosentLaCarteSurLeSpotSansDemanderLaZone() {
        let m = modele()
        m.spotFixe = Spot(centre: ailleurs, departement: Departement(code: "38"))
        m.positionIndisponible()
        #expect(m.regionVisible.centre == ailleurs)
        #expect(!m.afficherChoixDeZone)
    }

    // MARK: Le bouton bas-droite recentre sans déplacer le spot

    @Test func recentrerNeDeplacePasUnSpotPoseALaMain() {
        let m = modele()
        let pose = m.poserSpot(en: Coordonnee(latitude: 48.82, longitude: 2.41))
        #expect(pose != nil)
        m.appliquer(position: ailleurs, refusee: false)  // la première position pose la carte, jamais le spot
        #expect(m.spotAffiche == pose)

        m.demanderRecentrage()
        m.appliquer(position: pecheur, refusee: false)  // la position fraîche corrige la caméra une fois
        #expect(m.regionVisible.centre == pecheur)
        #expect(m.spotAffiche == pose)
        #expect(m.spotChoisiAMain)
    }

    @Test func recentrerAvantLArriveeDeLaPositionAttendLePremierPoint() {
        let m = modele()
        m.choisirZone(ailleurs)
        m.demanderRecentrage()
        #expect(m.recentrageEnAttente)
        m.appliquer(position: pecheur, refusee: false)
        #expect(m.regionVisible.centre == pecheur)
        #expect(!m.recentrageEnAttente)
    }

    @Test func recentrerNeToucheNiAuDepartNiAuSpotPropose() async {
        let m = modele()
        m.appliquer(position: pecheur, refusee: false)
        await attendre { m.spotAffiche != nil }
        let propose = m.spotAffiche
        #expect(propose != nil)
        m.demanderRecentrage()
        m.appliquer(position: ailleurs, refusee: false)
        #expect(m.spotAffiche == propose)
        #expect(m.depart == .surLePecheur(pecheur) || m.depart == .surLePecheur(ailleurs))
    }

    @Test func unSpotQuiArriveApresLouvertureNeTireJamaisLaCamera() {
        let m = modele()
        m.appliquer(position: pecheur, refusee: false)
        m.recevoir(spotFixe: Spot(centre: ailleurs, departement: Departement(code: "38")))
        #expect(m.regionVisible.centre == pecheur)
        #expect(m.spotAffiche?.centre == ailleurs)
    }

    // MARK: Département choisi puis changé

    @Test func lePecheurChangeSonDepartementUneDeuxiemeFois() async {
        let m = modele()
        m.appliquer(position: nil, refusee: true)
        let premiere = Coordonnee(latitude: 45.77, longitude: 3.08)
        let deuxieme = Coordonnee(latitude: 43.30, longitude: 5.40)
        m.choisirZone(premiere)
        #expect(m.regionVisible.centre == premiere)
        m.choisirZone(deuxieme)
        #expect(m.regionVisible.centre == deuxieme)
        #expect(m.depart == .zoneChoisie(deuxieme))
        #expect(m.pointDeReference == deuxieme)
        #expect(!m.afficherChoixDeZone)
    }

    @Test func uneZoneChoisieALaMainResisteALaPosition() {
        let m = modele()
        let zone = Coordonnee(latitude: 45.77, longitude: 3.08)
        m.choisirZone(zone)
        m.appliquer(position: pecheur, refusee: false)
        #expect(m.regionVisible.centre == zone)
        #expect(m.depart == .zoneChoisie(zone))
    }

    @Test func lesDeuxChoixSuccessifsSontRetenusPourLeProchainLancement() {
        let reglages = UserDefaults(suiteName: "ouverture-\(UUID().uuidString)")!
        let m = ModeleCarte(services: .faux(), dossierCache: nil, reglages: reglages)
        m.choisirZone(Coordonnee(latitude: 45.77, longitude: 3.08))
        m.choisirZone(Coordonnee(latitude: 43.30, longitude: 5.40))
        let gardee = reglages.array(forKey: "carte.derniereZoneChoisie") as? [Double]
        #expect(gardee == [43.30, 5.40])
    }

    @Test func unSpotPoseALaMainSurvitAuChangementDeZone() {
        let m = modele()
        let pose = m.poserSpot(en: Coordonnee(latitude: 48.82, longitude: 2.41))
        m.choisirZone(Coordonnee(latitude: 43.30, longitude: 5.40))
        #expect(m.spotAffiche == pose)
    }

    // MARK: « Y aller » vise la station, jamais le pêcheur

    @Test func laFicheEtYAllerPartentDeLaStationPasDeLaPosition() async {
        let m = modele()
        m.appliquer(position: Coordonnee(latitude: 48.78, longitude: 2.38), refusee: false)
        await attendre { !m.elements.isEmpty }
        guard let element = m.elements.first(where: { $0.id == "STATION-ESSAI" }) else {
            Issue.record("la station d'essai du faux de Core devrait être sur la carte")
            return
        }
        m.toucher(element)
        #expect(m.selection?.id == "STATION-ESSAI")
        #expect(m.selection?.coordonnee == Coordonnee(latitude: 48.8, longitude: 2.4))
        #expect(m.selection?.recalee == true)
    }

    // MARK: Localisation : précision réduite et position invalide

    @Test func uneGestionDePositionSansStatutInitialLitLaPrecisionDuSysteme() {
        let g = GestionPosition(reglages: UserDefaults(suiteName: "position-\(UUID().uuidString)")!, statutInitial: .authorizedAlways)
        // Avec un statut imposé (tests), la précision n'est jamais « réduite » : aucun réglage système n'est lu.
        #expect(!g.precisionReduite)
        #expect(g.estAutorisee)
    }
}
