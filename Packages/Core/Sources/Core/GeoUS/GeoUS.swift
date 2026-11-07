import Foundation

/// Données géographiques américaines embarquées (lot US11) : accès publics listés par les agences, plans d'eau nommés,
/// lignes d'eau, avis de consommation de poisson. Rien ici ne dit qu'on a le droit de pêcher quelque part : un point est un
/// { accès public listé par <agence>, source, date }, et l'agence de l'État fait foi.
public enum GeoUS {
    /// Codes USPS des États dont les points d'accès sont embarqués, triés (par exemple ["MI", "MN", "WI"]).
    public static var etatsDisponibles: [String] { DonneesGeoUS.embarque.etats }

    /// Accès publics listés pour un État (code USPS, majuscules ou minuscules). Liste vide si l'État n'est pas embarqué.
    public static func points(etat: String) -> [PointAccesUS] { DonneesGeoUS.embarque.points(etat: etat) }

    /// Plans d'eau nommés d'un État, triés par nom : centre et rayon, pas de contour.
    public static func plansEau(etat: String) -> [PlanEauUS] { DonneesGeoUS.embarque.plansEau(etat: etat) }

    /// Avis de consommation de poisson connus pour un État, avec date et lien. Un avis sans `planEauId` vaut pour l'État entier.
    public static func avis(etat: String) -> [AvisSanteEauUS] { DonneesGeoUS.embarque.avis(etat: etat) }

    /// Lignes d'eau nommées très simplifiées d'un État (repère visuel pour la carte).
    public static func lignesEau(etat: String) -> [LigneEauUS] { DonneesGeoUS.embarque.lignesEau(etat: etat) }

    /// L'État couvert qui contient la position : contour très simplifié, ou boîte englobante en repli. nil hors des États couverts.
    public static func etat(pour latitude: Double, longitude: Double) -> String? {
        DonneesGeoUS.embarque.etat(latitude: latitude, longitude: longitude)
    }

    /// Les accès publics listés dans le rayon, du plus proche au plus loin, au plus `limite`. Tous les États embarqués sont cherchés.
    public static func points(autour latitude: Double, longitude: Double, rayonKm: Double, limite: Int) -> [PointAccesUS] {
        guard latitude.isFinite, longitude.isFinite, rayonKm.isFinite, rayonKm >= 0, limite > 0 else { return [] }
        let centre = Coordonnee(latitude: latitude, longitude: longitude)
        let dLat = rayonKm / 111.0
        let dLon = rayonKm / (111.0 * max(0.01, cos(latitude * .pi / 180)))
        var trouves: [(distance: Double, point: PointAccesUS)] = []
        for etat in etatsDisponibles {
            for p in points(etat: etat) where abs(p.latitude - latitude) <= dLat && abs(p.longitude - longitude) <= dLon {
                let d = Geodesie.distanceM(centre, Coordonnee(latitude: p.latitude, longitude: p.longitude))
                if d <= rayonKm * 1000 { trouves.append((d, p)) }
            }
        }
        trouves.sort { $0.distance != $1.distance ? $0.distance < $1.distance : $0.point.id < $1.point.id }
        return trouves.prefix(limite).map(\.point)
    }
}
