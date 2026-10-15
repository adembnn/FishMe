import Foundation

public enum TypeCoinPublic: String, Sendable, Equatable, Hashable, Codable {
    case peche
    case ponton
    case acces
}

/// Accès public d'un coin. Un coin privé n'est jamais lu : il n'a pas de cas ici.
public enum AccesCoinPublic: String, Sendable, Equatable, Hashable, Codable {
    case libre
    case permis
}

/// Un coin de pêche public de `coins-osm.geojson` (© contributeurs OpenStreetMap, ODbL).
struct CoinOSM: Sendable, Equatable {
    var id: String
    var type: TypeCoinPublic
    var acces: AccesCoinPublic?
    var payant: Bool
    var nom: String?
    /// Code du département écrit dans le fichier ; `nil` : Core le calcule depuis la coordonnée.
    var dep: String?
    var coordonnee: Coordonnee

    /// Lit un `FeatureCollection` de points. Tolérant : données absentes, vides ou illisibles donnent `[]` ; un point sans identifiant,
    /// sans coordonnée valide, d'un type inconnu ou d'accès non public (privé, clients, interdit) est sauté ; un doublon d'identifiant aussi.
    static func decoder(_ donnees: Data?) -> [CoinOSM] {
        guard let donnees, !donnees.isEmpty,
              let racine = (try? JSONSerialization.jsonObject(with: donnees)) as? [String: Any],
              let features = racine["features"] as? [[String: Any]] else { return [] }
        var vus: Set<String> = []
        return features.compactMap { f -> CoinOSM? in
            guard let geo = f["geometry"] as? [String: Any], (geo["type"] as? String) == "Point",
                  let xy = geo["coordinates"] as? [Any], xy.count >= 2,
                  let lon = (xy[0] as? NSNumber)?.doubleValue, let lat = (xy[1] as? NSNumber)?.doubleValue,
                  abs(lat) <= 90, abs(lon) <= 180,
                  let p = f["properties"] as? [String: Any],
                  let id = (p["id"] as? String) ?? (f["id"] as? String), !id.isEmpty,
                  let type = (p["type"] as? String).flatMap(TypeCoinPublic.init(rawValue:)) else { return nil }
            var acces: AccesCoinPublic?
            if let brut = p["acces"] as? String {
                guard let a = AccesCoinPublic(rawValue: brut) else { return nil }
                acces = a
            } else if p["acces"] != nil && !(p["acces"] is NSNull) {
                return nil
            }
            guard vus.insert(id).inserted else { return nil }
            let nom = (p["nom"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return CoinOSM(id: id, type: type, acces: acces, payant: (p["payant"] as? Bool) ?? false,
                           nom: (nom?.isEmpty ?? true) ? nil : nom, dep: p["dep"] as? String,
                           coordonnee: Coordonnee(latitude: lat, longitude: lon))
        }
    }
}

/// Un coin public où l'espèce choisie a été relevée à proximité (E3, L7). `nPeches` et `annee` sont ceux de la station OFB reliée :
/// l'écran dit « relevée à proximité », jamais « relevée ici ». Aucun coin n'est classé par chance de prise : l'ordre est la distance.
public struct CoinProche: Sendable, Equatable, Hashable, Codable, Identifiable {
    public var id: String
    public var nom: String?
    public var type: TypeCoinPublic
    public var acces: AccesCoinPublic?
    public var payant: Bool
    public var departement: Departement
    public var coordonnee: Coordonnee
    /// Distance au point demandé.
    public var distanceM: Double
    public var codeStation: String
    public var eauStation: String?
    public var distanceStationM: Double
    public var nPeches: Int
    public var annee: Int
    public var ouverture: OuvertureDuJour

    public init(id: String, nom: String?, type: TypeCoinPublic, acces: AccesCoinPublic?, payant: Bool, departement: Departement,
                coordonnee: Coordonnee, distanceM: Double, codeStation: String, eauStation: String?, distanceStationM: Double,
                nPeches: Int, annee: Int, ouverture: OuvertureDuJour) {
        self.id = id
        self.nom = nom
        self.type = type
        self.acces = acces
        self.payant = payant
        self.departement = departement
        self.coordonnee = coordonnee
        self.distanceM = distanceM
        self.codeStation = codeStation
        self.eauStation = eauStation
        self.distanceStationM = distanceStationM
        self.nPeches = nPeches
        self.annee = annee
        self.ouverture = ouverture
    }
}

/// Un coin public pour la carte (L2, L7), relié à la station OFB la plus proche. Aucune espèce choisie.
public struct CoinPublic: Sendable, Equatable, Hashable, Codable {
    public var id: String
    public var nom: String?
    public var type: TypeCoinPublic
    public var acces: AccesCoinPublic?
    public var payant: Bool
    public var departement: Departement
    public var coordonnee: Coordonnee
    /// Station OFB la plus proche (à moins de `MoteurEspeces.rayonStationM`) ; `nil` : aucun relevé à proximité.
    public var codeStation: String?
    public var eauStation: String?
    public var distanceStationM: Double?
    /// Espèces relevées par cette station, par nombre de pêches décroissant, avec N et année du dernier relevé de la station.
    public var especes: [EspeceRelevee]

    public init(id: String, nom: String?, type: TypeCoinPublic, acces: AccesCoinPublic?, payant: Bool, departement: Departement,
                coordonnee: Coordonnee, codeStation: String? = nil, eauStation: String? = nil, distanceStationM: Double? = nil,
                especes: [EspeceRelevee] = []) {
        self.id = id
        self.nom = nom
        self.type = type
        self.acces = acces
        self.payant = payant
        self.departement = departement
        self.coordonnee = coordonnee
        self.codeStation = codeStation
        self.eauStation = eauStation
        self.distanceStationM = distanceStationM
        self.especes = especes
    }
}
