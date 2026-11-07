import Foundation

/// Impérial (États-Unis) ou métrique. Les valeurs sont gardées en unités SI (mm, g, °C) : la conversion ne se fait qu'à l'affichage.
public enum SystemeUnites: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case imperial
    case metrique
}

/// Sens d'un arrondi à l'affichage.
public enum SensArrondi: Sendable, Equatable {
    case versLeHaut
    case versLeBas
    case auPlusProche
}

/// À quoi sert la valeur affichée. Le sens d'arrondi en découle : la valeur affichée ne doit jamais être plus souple que la règle réelle.
/// Une taille minimale convertie arrondit vers le haut (garder un poisson de la taille affichée n'est jamais sous le minimum réel) ;
/// une taille maximale vers le bas ; une fenêtre protégée s'élargit (début vers le bas, fin vers le haut).
public enum RoleValeur: Sendable, Equatable, CaseIterable {
    case tailleMinimale
    case tailleMaximale
    case debutFenetreProtegee
    case finFenetreProtegee
    /// Mesure neutre (poisson mesuré, température) : arrondi au plus proche.
    case mesure

    public var sens: SensArrondi {
        switch self {
        case .tailleMinimale, .finFenetreProtegee: .versLeHaut
        case .tailleMaximale, .debutFenetreProtegee: .versLeBas
        case .mesure: .auPlusProche
        }
    }
}

/// Un arrondi qui ne se trompe pas sur les valeurs exactes (15 po = 38,1 cm ne devient jamais 38,2 à cause d'un reste binaire).
enum Arrondi {
    static func appliquer(_ x: Double, pas: Double, sens: SensArrondi) -> Double {
        let q = x / pas
        let r = q.rounded()
        if abs(q - r) < 1e-7 { return r * pas }
        switch sens {
        case .versLeHaut: return q.rounded(.up) * pas
        case .versLeBas: return q.rounded(.down) * pas
        case .auPlusProche: return r * pas
        }
    }
}

public struct Longueur: Sendable, Equatable, Hashable, Codable, Comparable {
    public let millimetres: Double
    public init(millimetres: Double) { self.millimetres = millimetres }

    public static func pouces(_ v: Double) -> Longueur { Longueur(millimetres: v * 25.4) }
    public static func pieds(_ v: Double) -> Longueur { Longueur(millimetres: v * 304.8) }
    public static func centimetres(_ v: Double) -> Longueur { Longueur(millimetres: v * 10) }
    public static func metres(_ v: Double) -> Longueur { Longueur(millimetres: v * 1000) }

    public var pouces: Double { millimetres / 25.4 }
    public var pieds: Double { millimetres / 304.8 }
    public var centimetres: Double { millimetres / 10 }
    public var metres: Double { millimetres / 1000 }

    public static func < (a: Longueur, b: Longueur) -> Bool { a.millimetres < b.millimetres }

    /// Égalité à la tolérance de conversion près (1 µm).
    func memeValeur(que autre: Longueur) -> Bool { abs(millimetres - autre.millimetres) < 1e-3 }
}

public struct Masse: Sendable, Equatable, Hashable, Codable, Comparable {
    public let grammes: Double
    public init(grammes: Double) { self.grammes = grammes }

    public static func livres(_ v: Double) -> Masse { Masse(grammes: v * 453.592_37) }
    public static func kilogrammes(_ v: Double) -> Masse { Masse(grammes: v * 1000) }

    public var livres: Double { grammes / 453.592_37 }
    public var kilogrammes: Double { grammes / 1000 }

    public static func < (a: Masse, b: Masse) -> Bool { a.grammes < b.grammes }
}

public struct Temperature: Sendable, Equatable, Hashable, Codable, Comparable {
    public let celsius: Double
    public init(celsius: Double) { self.celsius = celsius }

    public static func fahrenheit(_ v: Double) -> Temperature { Temperature(celsius: (v - 32) * 5 / 9) }
    public static func degresCelsius(_ v: Double) -> Temperature { Temperature(celsius: v) }

    public var fahrenheit: Double { celsius * 9 / 5 + 32 }

    public static func < (a: Temperature, b: Temperature) -> Bool { a.celsius < b.celsius }
}

/// Ce que mesure une longueur : un poisson (po / cm) ou une profondeur et une distance (pi / m).
public enum GrandeurLongueur: Sendable, Equatable {
    case poisson
    case profondeur
}

/// Met en texte, sans arrondi trompeur : pas fin (1 mm, 0,1 po, 10 g…), zéros inutiles retirés, sens d'arrondi selon le rôle.
public struct FormatteurUnites: Sendable, Equatable {
    public let systeme: SystemeUnites
    public let separateurDecimal: Character

    public init(systeme: SystemeUnites, separateurDecimal: Character = ".") {
        self.systeme = systeme
        self.separateurDecimal = separateurDecimal
    }

    public func texte(_ longueur: Longueur, role: RoleValeur = .mesure, grandeur: GrandeurLongueur = .poisson) -> String {
        switch (systeme, grandeur) {
        case (.imperial, .poisson): nombre(longueur.pouces, pas: 0.1, decimales: 1, role: role) + " in"
        case (.imperial, .profondeur): nombre(longueur.pieds, pas: 0.1, decimales: 1, role: role) + " ft"
        case (.metrique, .poisson): nombre(longueur.centimetres, pas: 0.1, decimales: 1, role: role) + " cm"
        case (.metrique, .profondeur): nombre(longueur.metres, pas: 0.01, decimales: 2, role: role) + " m"
        }
    }

    public func texte(_ masse: Masse, role: RoleValeur = .mesure) -> String {
        switch systeme {
        case .imperial: nombre(masse.livres, pas: 0.1, decimales: 1, role: role) + " lb"
        case .metrique: nombre(masse.kilogrammes, pas: 0.01, decimales: 2, role: role) + " kg"
        }
    }

    public func texte(_ temperature: Temperature) -> String {
        switch systeme {
        case .imperial: nombre(temperature.fahrenheit, pas: 0.1, decimales: 1, role: .mesure) + " °F"
        case .metrique: nombre(temperature.celsius, pas: 0.1, decimales: 1, role: .mesure) + " °C"
        }
    }

    func nombre(_ valeur: Double, pas: Double, decimales: Int, role: RoleValeur) -> String {
        let arrondi = Arrondi.appliquer(valeur, pas: pas, sens: role.sens)
        var s = String(format: "%.\(decimales)f", arrondi)
        if s.contains(".") {
            while s.hasSuffix("0") { s.removeLast() }
            if s.hasSuffix(".") { s.removeLast() }
        }
        if s == "-0" { s = "0" }
        if separateurDecimal != "." { s = s.replacingOccurrences(of: ".", with: String(separateurDecimal)) }
        return s
    }
}
