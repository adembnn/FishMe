import Foundation

/// Les trois tailles de fond : l'aquarium plein écran, le widget en grand, en moyen et en petit.
public enum FormatFond: String, Sendable, CaseIterable {
    case petit
    case moyen
    case grand
}

/// Une teinte d'éclairage posée sur le fond (rouge, vert, bleu, opacité : de 0 à 1). `Core` n'importe pas SwiftUI.
public struct TeinteEclairage: Sendable, Equatable {
    public let rouge: Double
    public let vert: Double
    public let bleu: Double
    public let opacite: Double

    public init(rouge: Double, vert: Double, bleu: Double, opacite: Double) {
        func borne(_ x: Double) -> Double { min(max(x, 0), 1) }
        self.rouge = borne(rouge)
        self.vert = borne(vert)
        self.bleu = borne(bleu)
        self.opacite = borne(opacite)
    }
}

/// Un habillage d'aquarium. Un skin décide de trois choses seulement : l'image de fond, une teinte d'éclairage,
/// de 0 à 3 petits objets posés. Il ne touche ni aux poissons, ni à leur taille, ni à leur nage.
public struct Skin: Sendable, Equatable, Identifiable {
    public let id: IdentifiantSkin
    public let nom: String
    public let origine: OrigineSkin
    /// Ordre d'affichage dans la galerie, stable d'une version à l'autre.
    public let ordre: Int
    /// Poids approximatif des images du skin, pour tenir le budget de l'app et du widget.
    public let poidsApproxOctets: Int
    public let teinte: TeinteEclairage?
    /// Noms des images des petits objets (0 à 3), dans le jeu d'images de l'app.
    public let objets: [String]

    public init(id: IdentifiantSkin, nom: String, origine: OrigineSkin, ordre: Int, poidsApproxOctets: Int,
                teinte: TeinteEclairage? = nil, objets: [String] = []) {
        self.id = id
        self.nom = nom
        self.origine = origine
        self.ordre = ordre
        self.poidsApproxOctets = poidsApproxOctets
        self.teinte = teinte
        self.objets = Array(objets.prefix(3))
    }

    /// Nom du jeu d'images du fond. Le décor de départ garde les fonds déjà dans l'app (`fond-grand`…) ;
    /// les autres ont `fond-<skin>-<format>`. Le widget et l'app se replient sur `fond-<format>` si l'image manque.
    public func nomImageFond(_ format: FormatFond) -> String {
        id == .parDefaut ? Self.nomImageRepli(format) : "fond-\(id.valeur)-\(format.rawValue)"
    }

    public static func nomImageRepli(_ format: FormatFond) -> String { "fond-\(format.rawValue)" }
}
