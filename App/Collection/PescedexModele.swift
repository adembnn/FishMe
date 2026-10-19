import Core
import Observation
import SwiftUI

/// État du volet Pescedex : cartes enregistrées, emplacements du classeur, compteur de la zone.
@MainActor
@Observable
final class PescedexModele {
    private(set) var detaillees: [CarteDetaillee] = []
    private(set) var bredouilles: [CarteBredouille] = []
    private(set) var emplacements: [Emplacement] = []
    private(set) var compteur = CompteurPescedex(zone: nil, trouvees: 0, releveesDansLaZone: 0, legendairesEnPlus: 0)
    /// Le département de référence du pêcheur (celui de sa dernière prise, sinon de son spot) : sert aux cartes, à la fiche et au rang.
    private(set) var zone: Departement?
    /// L'étendue demandée par le menu de zone (L18). `charger()` la lit ; `choisir(_:)` la change et recharge.
    private(set) var portee: PorteePescedex = .monSpot
    /// L'étendue réellement montrée : « Ma région » sans table de régions revient sur « Mon spot ».
    private(set) var porteeMontree: PorteePescedex = .monSpot
    /// La région du département de référence, si `Core` en fournit la table.
    private(set) var region: RegionPescedex?
    private var especesRelevees: Set<String> = []

    let depot: DepotCartes
    let services: ServicesCollection
    /// Département à utiliser quand aucune carte n'a de lieu (par exemple celui du spot gratuit).
    let zoneDeRepli: Departement?
    private let especes: [EspecePechable]
    /// La région d'un département. À brancher : A, avec la table des régions de `Core` (demandée à B/L1). Tant que c'est `nil`,
    /// « Ma région » est grisé dans le menu : l'app n'invente jamais la table.
    private let regionDe: ((Departement) -> RegionPescedex?)?

    init(depot: DepotCartes, services: ServicesCollection, zoneDeRepli: Departement? = nil,
         regionDe: ((Departement) -> RegionPescedex?)? = nil) {
        self.depot = depot
        self.services = services
        self.zoneDeRepli = zoneDeRepli
        self.especes = services.especes.especesPechables()
        self.regionDe = regionDe
    }

    /// Vrai quand la région du pêcheur est connue : sinon « Ma région » est grisé.
    var regionDisponible: Bool { region != nil }

    /// Change l'étendue du Pescedex et recharge. Appelé par le menu de zone.
    func choisir(_ nouvelle: PorteePescedex) async {
        portee = nouvelle
        await charger()
    }

    /// Numéro du dernier chargement demandé : un chargement plus ancien qui finit après ne doit pas écraser le récent.
    private var generation = 0

    func charger() async {
        generation += 1
        let moi = generation
        let lues = await depot.detaillees()
        let sansPrise = await depot.bredouilles()
        guard moi == generation else { return }
        detaillees = lues
        bredouilles = sansPrise
        let cartes = detaillees.map(\.prise)
        let reference = CompteurPescedex.zoneParDefaut(cartes: cartes, repli: zoneDeRepli)
        zone = reference
        let services = self.services
        let rarete: (Espece, Departement) -> ResultatRarete = { e, d in services.especes.rarete(espece: e, departement: d) }
        // Les espèces relevées au département de référence : le rang d'une carte ne change pas avec le menu de zone.
        let dansLeDepartement = CompteurPescedex.emplacements(cartes: cartes, especes: especes, zone: reference, rarete: rarete)
        especesRelevees = Set(dansLeDepartement.filter(\.releveeDansLaZone).map(\.id))
        region = reference.flatMap { $0.estInconnu ? nil : regionDe?($0) }
        porteeMontree = (portee == .maRegion && region == nil) ? .monSpot : portee
        switch porteeMontree {
        case .monSpot:
            emplacements = dansLeDepartement
        case .maRegion:
            emplacements = CalculZonePescedex.emplacementsRegion(
                cartes: cartes, especes: especes, departements: region?.departements ?? [], rarete: rarete)
        case .france:
            emplacements = CalculZonePescedex.emplacementsFrance(cartes: cartes, especes: especes, reference: reference, rarete: rarete)
        }
        compteur = CompteurPescedex.compteur(emplacements: emplacements, zone: reference, portee: porteeMontree,
                                             locutionRegion: porteeMontree == .maRegion ? region?.phrase : nil)
    }

    /// Les espèces relevées au département de référence (rang des cartes), quel que soit le menu de zone.
    var especesDeLaZone: Set<String> { especesRelevees }

    func infos(pour emplacement: Emplacement) -> InfosCarte? {
        guard let carte = emplacement.carte,
              let detail = detaillees.first(where: { $0.prise.id == carte.id }) else { return nil }
        return InfosCarte.construire(detail: detail, espece: emplacement.espece, zone: zone,
                                     toutesLesCartes: detaillees.map(\.prise), especesDeLaZone: especesDeLaZone,
                                     services: services)
    }
}
