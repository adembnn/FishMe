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
    private(set) var zone: Departement?

    let depot: DepotCartes
    let services: ServicesCollection
    /// Département à utiliser quand aucune carte n'a de lieu (par exemple celui du spot gratuit).
    let zoneDeRepli: Departement?
    private let especes: [EspecePechable]

    init(depot: DepotCartes, services: ServicesCollection, zoneDeRepli: Departement? = nil) {
        self.depot = depot
        self.services = services
        self.zoneDeRepli = zoneDeRepli
        self.especes = services.especes.especesPechables()
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
        zone = CompteurPescedex.zoneParDefaut(cartes: cartes, repli: zoneDeRepli)
        let services = self.services
        emplacements = CompteurPescedex.emplacements(cartes: cartes, especes: especes, zone: zone) { e, d in
            services.especes.rarete(espece: e, departement: d)
        }
        compteur = CompteurPescedex.compteur(emplacements: emplacements, zone: zone)
    }

    var especesDeLaZone: Set<String> {
        Set(emplacements.filter(\.releveeDansLaZone).map(\.id))
    }

    func infos(pour emplacement: Emplacement) -> InfosCarte? {
        guard let carte = emplacement.carte,
              let detail = detaillees.first(where: { $0.prise.id == carte.id }) else { return nil }
        return InfosCarte.construire(detail: detail, espece: emplacement.espece, zone: zone,
                                     toutesLesCartes: detaillees.map(\.prise), especesDeLaZone: especesDeLaZone,
                                     services: services)
    }
}
