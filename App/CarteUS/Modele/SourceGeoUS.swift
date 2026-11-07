import Foundation
import Core

/// La source de données de la carte. Tant que Core.GeoUS (lot US11) n'est pas fusionné, aucune donnée : la carte dit
/// "Pas encore de données pour cet État" avec le lien de l'agence. Après la fusion de US11 : compiler avec le drapeau
/// FISHME_GEOUS (Active Compilation Conditions) ou retirer le #if ci-dessous ; AUCUN autre fichier ne change.
nonisolated enum SourceCarteUSParDefaut {
    static func creer() -> any SourceCarteUS {
        #if FISHME_GEOUS
        return AdaptateurGeoUS()
        #else
        return SourceCarteUSVide()
        #endif
    }
}

#if FISHME_GEOUS
/// L'adaptateur de Core.GeoUS vers le protocole de la carte. Écrit d'après le contrat convenu avec US11 :
///   PointAccesUS(id, nom, etat, latitude, longitude, type, source, date)
///   PlanEauUS(id, nom, etat, latitude, longitude, rayonMetres, source, date, lienAgence)
///   AvisSanteEauUS(planEauId, texte, date, source, lien)
///   GeoUS.etatsDisponibles, points(etat:), plansEau(etat:), avis(etat:), etat(pour:latitude:longitude:)
/// Si un type de date est un JourCivil et non un String, remplacer String(describing: x.date) par x.date.iso.
nonisolated struct AdaptateurGeoUS: SourceCarteUS {
    var etatsDisponibles: [String] { GeoUS.etatsDisponibles }

    func points(etat: String) -> [PointAccesCarteUS] {
        GeoUS.points(etat: etat).map { p in
            PointAccesCarteUS(id: p.id, nom: p.nom, etat: p.etat, latitude: p.latitude, longitude: p.longitude,
                              type: Self.type(p.type), source: p.source, date: String(describing: p.date))
        }
    }

    func plansEau(etat: String) -> [PlanEauCarteUS] {
        GeoUS.plansEau(etat: etat).map { e in
            PlanEauCarteUS(id: e.id, nom: e.nom, etat: e.etat, latitude: e.latitude, longitude: e.longitude,
                           rayonMetres: e.rayonMetres, source: e.source, date: String(describing: e.date), lienAgence: e.lienAgence)
        }
    }

    func avis(etat: String) -> [AvisSanteCarteUS] {
        GeoUS.avis(etat: etat).map { a in
            AvisSanteCarteUS(planEauId: a.planEauId, texte: a.texte, date: String(describing: a.date), source: a.source,
                             lien: a.lien)
        }
    }

    func etat(pour latitude: Double, longitude: Double) -> String? {
        GeoUS.etat(pour: latitude, longitude: longitude)
    }

    private static func type(_ t: TypeAccesUS) -> TypeAccesCarteUS {
        switch t {
        case .rampe: .rampe
        case .quai: .quai
        case .accesPublic: .accesPublic
        case .autre: .autre
        }
    }
}
#endif
