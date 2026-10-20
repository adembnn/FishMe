import Core
import Foundation
import Observation
import SwiftUI

/// Les photos nettoyées des prises, lues dans le dépôt de `App/Collection/`. N6 ne l'importe pas : L25 branche un protocole
/// de ce nom entre les deux dossiers (demande 5 de la fiche). Sans lui, la fiche d'un repère n'affiche que ses propres photos.
nonisolated protocol PhotosDesPrises: Sendable {
    func photos(de ids: [UUID]) async -> [PhotoDePrise]
}

nonisolated struct PhotoDePrise: Sendable, Equatable, Identifiable {
    let id: UUID
    let donnees: Data
}

/// Ce que les vues des repères reçoivent du reste de l'app. Rien n'est requis : sans réglage, la fiche ne montre pas
/// d'avertissement de réserve et les boutons « Règles ici » et « Voir Pro » sont cachés.
/// À régler une fois au lancement (accroche 8 de la fiche) : `ContexteReperes.courant.configurer(...)`.
@MainActor @Observable
final class ContexteReperes {
    static let courant = ContexteReperes()

    @ObservationIgnored private(set) var geo: (any ServiceGeo)?
    @ObservationIgnored private(set) var chargeur: ChargeurRegles = .embarque()
    @ObservationIgnored private(set) var prises: () -> [Prise] = { [] }
    @ObservationIgnored private(set) var photosDesPrises: (any PhotosDesPrises)?
    /// Point d'entrée « règles à cette coordonnée » de L17. `nil` : le bouton « Règles ici » est caché.
    @ObservationIgnored private(set) var reglesIci: ((Coordonnee) -> Void)?
    @ObservationIgnored private(set) var ouvrirPaywall: (() -> Void)?
    /// Le paywall présenté PAR la feuille « Nouveau repère » elle-même (câblage L25 : une feuille déjà ouverte ne peut pas en
    /// laisser la racine présenter une autre). Reçoit la fermeture à appeler pour le refermer. `nil` : repli sur `ouvrirPaywall`.
    @ObservationIgnored private(set) var vuePaywall: ((@escaping () -> Void) -> AnyView)?
    /// À mettre à jour à chaque changement d'abonnement (`SuiviAbonnement.abonne`).
    var abonne = false

    func configurer(geo: any ServiceGeo, chargeur: ChargeurRegles, prises: @escaping () -> [Prise],
                    photosDesPrises: (any PhotosDesPrises)? = nil, reglesIci: ((Coordonnee) -> Void)? = nil,
                    ouvrirPaywall: (() -> Void)? = nil, vuePaywall: ((@escaping () -> Void) -> AnyView)? = nil) {
        self.geo = geo
        self.chargeur = chargeur
        self.prises = prises
        self.photosDesPrises = photosDesPrises
        self.reglesIci = reglesIci
        self.ouvrirPaywall = ouvrirPaywall
        self.vuePaywall = vuePaywall
    }
}

/// Ce que la fiche d'un repère affiche sur son lieu.
nonisolated struct LieuDuRepere: Sendable, Equatable {
    var avertissement: AvertissementReserve
    var lieuFlou: String
    var horsDeFrance: Bool
}

nonisolated enum EvaluationReserve {
    /// Lit les règles du département sur le disque : à appeler hors du fil principal. Recalculé à chaque ouverture de la fiche,
    /// jamais stocké (un verdict stocké se périmerait).
    static func evaluer(position: Coordonnee, geo: any ServiceGeo, chargeur: ChargeurRegles) -> LieuDuRepere {
        let departement = geo.departement(de: position)
        let lieuFlou = geo.lieuFlou(position)
        if departement.estInconnu {
            return LieuDuRepere(avertissement: .aucuneConnue, lieuFlou: lieuFlou, horsDeFrance: true)
        }
        let reserves = ReservesDuDepartement.charger(departement: departement, chargeur: chargeur)
        let avertissement = DetecteurReserve.evaluer(eauxProches: geo.eauxProches(position), departement: departement,
                                                     reserves: reserves)
        return LieuDuRepere(avertissement: avertissement, lieuFlou: lieuFlou, horsDeFrance: false)
    }
}
