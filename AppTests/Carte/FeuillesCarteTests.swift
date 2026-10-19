import Foundation
import Testing
import Core
@testable import BuildChallenge

/// L17 : « Y aller » à deux temps, feuilles à trois hauteurs, pastille de fréquentation, vignettes de ses propres prises,
/// « Règles du spot ». Écrit sans compiler (PC Windows) : à lancer sous Xcode.
struct FeuillesCarteTests {

    // MARK: « Y aller »

    private let station = Coordonnee(latitude: 48.8, longitude: 2.4)

    @Test func lesAdressesPartentDeLaCoordonneeDeLaStation() {
        #expect(ApplicationItineraire.waze.url(vers: station)?.absoluteString == "waze://?ll=48.80000,2.40000&navigate=yes")
        #expect(ApplicationItineraire.googleMaps.url(vers: station)?.absoluteString
                == "comgooglemaps://?daddr=48.80000,2.40000&directionsmode=driving")
        #expect(ApplicationItineraire.plans.url(vers: station) == nil)  // Plans s'ouvre par MapKit
    }

    @Test func laVirguleDecimaleNEntrePasDansLAdresse() {
        let c = Coordonnee(latitude: -4.5, longitude: 12.25)
        let waze = ApplicationItineraire.waze.url(vers: c)?.absoluteString ?? ""
        #expect(waze.contains("ll=-4.50000,12.25000"))
    }

    @Test func seulesLesApplicationsInstalleesSontProposees() {
        let tout = ApplicationItineraire.installees { _ in true }
        #expect(tout == [.plans, .waze, .googleMaps])
        let rien = ApplicationItineraire.installees { _ in false }
        #expect(rien == [.plans])
        let wazeSeul = ApplicationItineraire.installees { $0.scheme == "waze" }
        #expect(wazeSeul == [.plans, .waze])
    }

    @Test func premierToucherAvecWazeInstalleDemandeLaquelle() {
        let d = DecisionYAller.decider(installees: [.plans, .waze], preference: nil)
        #expect(d == .demander([.plans, .waze]))
    }

    @Test func deuxiemeToucherAvecToujoursUtiliserOuvreDirectement() {
        #expect(DecisionYAller.decider(installees: [.plans, .waze], preference: .waze) == .ouvrir(.waze))
        #expect(DecisionYAller.decider(installees: [.plans, .waze, .googleMaps], preference: .plans) == .ouvrir(.plans))
    }

    @Test func plansSeulOuvreDirectementSansDialogue() {
        #expect(DecisionYAller.decider(installees: [.plans], preference: nil) == .ouvrir(.plans))
        // Waze mémorisé mais désinstallé : Plans, sans mentir.
        #expect(DecisionYAller.decider(installees: [.plans], preference: .waze) == .ouvrir(.plans))
    }

    @Test func uneApplicationMemoriseeMaisDesinstalleeRedemande() {
        #expect(DecisionYAller.decider(installees: [.plans, .waze], preference: .googleMaps) == .demander([.plans, .waze]))
    }

    @Test func laPreferenceSeGardeSeChangeEtSEfface() {
        let reglages = UserDefaults(suiteName: "navigation-\(UUID().uuidString)")!
        #expect(PreferenceItineraire.lire(reglages) == nil)
        PreferenceItineraire.ecrire(.waze, reglages)
        #expect(PreferenceItineraire.lire(reglages) == .waze)
        PreferenceItineraire.ecrire(.googleMaps, reglages)
        #expect(PreferenceItineraire.lire(reglages) == .googleMaps)
        PreferenceItineraire.ecrire(nil, reglages)
        #expect(PreferenceItineraire.lire(reglages) == nil)
        reglages.set("application-inconnue", forKey: PreferenceItineraire.cle)
        #expect(PreferenceItineraire.lire(reglages) == nil)
    }

    // MARK: Les trois hauteurs

    @Test func lesTroisHauteursCroissentEtLePleinEcranPrendToutLEspace() {
        let total = 800.0
        let h = DetentPanneau.allCases.map { $0.hauteur(dans: total) }
        #expect(h[0] < h[1] && h[1] < h[2])
        #expect(DetentPanneau.pleinEcran.hauteur(dans: total) == total)
        #expect(DetentPanneau.moyen.hauteur(dans: -5) == 0)
    }

    @Test func laCarteReserveLaHauteurDeLaFeuilleSaufEnPleinEcran() {
        let total = 800.0
        #expect(DetentPanneau.moyen.reservation(dans: total) == DetentPanneau.moyen.hauteur(dans: total))
        #expect(DetentPanneau.grand.reservation(dans: total) == DetentPanneau.grand.hauteur(dans: total))
        // En plein écran la carte garde la réserve de « grand » : elle ne se redimensionne pas derrière la feuille.
        #expect(DetentPanneau.pleinEcran.reservation(dans: total) == DetentPanneau.grand.hauteur(dans: total))
    }

    @Test func laPoigneeParcourtLesTroisHauteurs() {
        #expect(DetentPanneau.moyen.suivantEnBoucle == .grand)
        #expect(DetentPanneau.grand.suivantEnBoucle == .pleinEcran)
        #expect(DetentPanneau.pleinEcran.suivantEnBoucle == .moyen)
        #expect(DetentPanneau.pleinEcran.plusHaut == .pleinEcran)
        #expect(DetentPanneau.moyen.plusBas == .moyen)
    }

    @Test func leGlissementChoisitLeCranLePlusProcheOuFerme() {
        let total = 800.0
        let grand = DetentPanneau.grand.hauteur(dans: total)
        #expect(RegleGlissement.fin(hauteur: grand + 10, total: total, depart: .moyen, vitesse: 0, fermable: true) == .rester(.grand))
        #expect(RegleGlissement.fin(hauteur: total, total: total, depart: .grand, vitesse: 0, fermable: true) == .rester(.pleinEcran))
        // Très bas : la fiche se ferme ; « Mon spot » aussi, une feuille non fermable revient au moyen.
        #expect(RegleGlissement.fin(hauteur: 40, total: total, depart: .moyen, vitesse: 0, fermable: true) == .fermer)
        #expect(RegleGlissement.fin(hauteur: 40, total: total, depart: .moyen, vitesse: 0, fermable: false) == .rester(.moyen))
        // Un geste vif vers le bas ferme depuis le moyen, descend d'un cran depuis les autres.
        #expect(RegleGlissement.fin(hauteur: 300, total: total, depart: .moyen, vitesse: 1500, fermable: true) == .fermer)
        #expect(RegleGlissement.fin(hauteur: 500, total: total, depart: .pleinEcran, vitesse: 1500, fermable: true) == .rester(.grand))
        // Un geste vif vers le haut monte d'un cran.
        #expect(RegleGlissement.fin(hauteur: 400, total: total, depart: .moyen, vitesse: -1500, fermable: true) == .rester(.grand))
    }

    // MARK: Pastille de fréquentation

    @Test func laPastilleEstVerteOrangeRougeOuGrise() {
        #expect(EtatPastille.pour(.calme) == .vert)
        #expect(EtatPastille.pour(.normal) == .orange)
        #expect(EtatPastille.pour(.charge) == .rouge)
        #expect(EtatPastille.pour(nil) == .gris)
    }

    @Test func laPastilleNeDitAucunePhraseEtChaqueEtatAUnSymboleDifferent() {
        let symboles = EtatPastille.allCases.map(\.symbole)
        #expect(Set(symboles).count == symboles.count)
        // Le mot ne sert qu'à VoiceOver : un seul mot, jamais une phrase.
        #expect(EtatPastille.allCases.allSatisfy { !$0.mot.contains(" ") })
    }

    // MARK: Vignettes de ses propres prises

    private func prise(_ lieu: String?, jour: Int, photo: String? = "photo.jpg", declaree: Bool = false, exemple: Bool = false) -> Prise {
        Prise(espece: Espece(id: "brochet", codeSandre: "BRO"), origine: declaree ? .declaree : .priseReelle,
              date: Date(timeIntervalSince1970: 1_790_000_000 + Double(jour) * 86_400), lieuFlou: lieu, cheminPhoto: photo, exemple: exemple)
    }

    @Test func seulesLesPrisesDeCeLieuAvecUnePhotoAppairent() {
        let toutes = [prise("La Marne · 94", jour: 1), prise("La Loire · 45", jour: 2), prise("La Marne · 94", jour: 3, photo: nil),
                      prise("La Marne · 94", jour: 4, declaree: true), prise("La Marne · 94", jour: 5, exemple: true),
                      prise(nil, jour: 6)]
        let trouvees = AppariementPrises.prises(toutes, lieuxFlous: ["La Marne · 94"])
        #expect(trouvees.count == 1)
        #expect(trouvees.first?.lieuFlou == "La Marne · 94")
    }

    @Test func lAppariementIgnoreAccentsMajusculesEtEspaces() {
        let toutes = [prise("la  marné  ·  94", jour: 1)]
        #expect(AppariementPrises.prises(toutes, lieuxFlous: ["La Marne · 94"]).count == 1)
        #expect(AppariementPrises.prises(toutes, lieuxFlous: ["La Marne · 75"]).isEmpty)
        #expect(AppariementPrises.prises(toutes, lieuxFlous: []).isEmpty)
    }

    @Test func lesVignettesSontRecentesDAbordEtLimitees() {
        let toutes = (1...10).map { prise("La Marne · 94", jour: $0) }
        let trouvees = AppariementPrises.prises(toutes, lieuxFlous: ["La Marne · 94"])
        #expect(trouvees.count == AppariementPrises.maximumVignettes)
        #expect(trouvees.first?.date == toutes.last?.date)
        #expect(trouvees.map(\.date) == trouvees.map(\.date).sorted(by: >))
    }

    @Test func leLieuFlouDUneStationNeContientJamaisDeCoordonnee() {
        #expect(AppariementPrises.lieuFlou(eau: "La Marne", departement: Departement(code: "94")) == "La Marne · 94")
        #expect(AppariementPrises.lieuFlou(eau: "La Marne", departement: nil) == "La Marne")
        #expect(AppariementPrises.lieuFlou(eau: nil, departement: Departement(code: "94")) == nil)
        #expect(AppariementPrises.lieuFlou(eau: "La Marne", departement: .inconnu) == "La Marne")
    }

    @Test func parDefautAucunePriseNEstLue() async {
        let lues = await PrisesDuPecheurCarte.aucune.lire()
        #expect(lues.isEmpty)
        #expect(PrisesDuPecheurCarte.aucune.photo(prise("La Marne · 94", jour: 1)) == nil)
    }

    // MARK: Règles du spot

    @Test func lesReglesDuSpotNOuvrentJamaisSurRelacheLePoisson() {
        let source = SourceRegle(titre: "Arrêté (essai)", url: nil, citation: "essai")
        let fermee = LigneControle(type: .periode, etat: .nonRespectee, phrase: "Brochet : fermé jusqu'au 25 avril.", sources: [source])
        let taille = LigneControle(type: .taille, etat: .respectee, phrase: "Brochet : 60 cm.", sources: [source])
        let aVerifier = LigneControle(type: .reserve, etat: .aVerifierSurPlace, raison: .reserve, phrase: "Regarde le panneau.", sources: [source])
        let lignes = ReglesDuSpot.lignesDuLieu([fermee, taille, aVerifier])
        #expect(lignes.map(\.etat) == [.information, .respectee, .aVerifierSurPlace])
        // Phrases, types et sources ne changent pas : rien n'est inventé ni filtré.
        #expect(lignes.map(\.phrase) == [fermee.phrase, taille.phrase, aVerifier.phrase])
        #expect(lignes.map(\.type) == [.periode, .taille, .reserve])
        #expect(lignes.allSatisfy { $0.sources == [source] })
        #expect(ReglesDuSpot.consigne != .relacheLa)
    }
}
