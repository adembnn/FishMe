import Foundation

/// Un point sur Terre. Structure maison : `CLLocationCoordinate2D` n'existe pas sous Linux.
public struct Coordonnee: Sendable, Equatable, Hashable, Codable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Code du département (« 94 », « 2A ») ou « inconnu » (hors de France, ou point hors de tout polygone).
public struct Departement: Sendable, Equatable, Hashable, Codable {
    public var code: String

    public init(code: String) {
        self.code = code
    }

    public static let inconnu = Departement(code: "inconnu")

    public var estInconnu: Bool { code == Departement.inconnu.code }
}
