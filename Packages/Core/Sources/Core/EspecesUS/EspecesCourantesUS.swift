import Foundation

/// Espèces courantes d'eau douce aux États-Unis, pour le tunnel des premières minutes en région US (US16).
/// `imageEspeceFrancaise` : slug d'une image du catalogue de l'app QUAND ET SEULEMENT QUAND c'est la même espèce
/// (lien « = » de `outils/us/especes/correspondance-fr.json`) ; sinon nil : l'app montre « image à venir », jamais l'image d'une autre espèce.
/// Les noms viennent de la table `outils/us/especes/especes-us.json` (nom anglais usuel, nom scientifique).
public struct EspeceCouranteUS: Sendable, Equatable, Identifiable {
    public let slug: String
    public let nomEn: String
    public let latin: String
    public let imageEspeceFrancaise: String?
    public var id: String { slug }
}

public enum EspecesCourantesUS {
    /// Ordre : les plus pêchées d'abord. Une espèce n'est jamais proposée « par zone » ici : c'est une liste nationale de départ.
    public static let liste: [EspeceCouranteUS] = [
        .init(slug: "largemouth-bass", nomEn: "Largemouth bass", latin: "Micropterus salmoides", imageEspeceFrancaise: "black-bass"),
        .init(slug: "bluegill", nomEn: "Bluegill", latin: "Lepomis macrochirus", imageEspeceFrancaise: nil),
        .init(slug: "channel-catfish", nomEn: "Channel catfish", latin: "Ictalurus punctatus", imageEspeceFrancaise: "barbue-de-riviere"),
        .init(slug: "walleye", nomEn: "Walleye", latin: "Sander vitreus", imageEspeceFrancaise: nil),
        .init(slug: "northern-pike", nomEn: "Northern pike", latin: "Esox lucius", imageEspeceFrancaise: "brochet"),
        .init(slug: "rainbow-trout", nomEn: "Rainbow trout", latin: "Oncorhynchus mykiss", imageEspeceFrancaise: "truite-arc-en-ciel"),
        .init(slug: "smallmouth-bass", nomEn: "Smallmouth bass", latin: "Micropterus dolomieu", imageEspeceFrancaise: "black-bass-petite-bouche"),
        .init(slug: "black-crappie", nomEn: "Black crappie", latin: "Pomoxis nigromaculatus", imageEspeceFrancaise: nil),
        .init(slug: "yellow-perch", nomEn: "Yellow perch", latin: "Perca flavescens", imageEspeceFrancaise: nil),
        .init(slug: "brown-trout", nomEn: "Brown trout", latin: "Salmo trutta", imageEspeceFrancaise: "truite-fario"),
        .init(slug: "brook-trout", nomEn: "Brook trout", latin: "Salvelinus fontinalis", imageEspeceFrancaise: "omble-de-fontaine"),
        .init(slug: "common-carp", nomEn: "Common carp", latin: "Cyprinus carpio", imageEspeceFrancaise: "carpe-commune"),
        .init(slug: "striped-bass", nomEn: "Striped bass", latin: "Morone saxatilis", imageEspeceFrancaise: nil),
        .init(slug: "flathead-catfish", nomEn: "Flathead catfish", latin: "Pylodictis olivaris", imageEspeceFrancaise: nil),
        .init(slug: "muskellunge", nomEn: "Muskellunge", latin: "Esox masquinongy", imageEspeceFrancaise: nil),
        .init(slug: "white-crappie", nomEn: "White crappie", latin: "Pomoxis annularis", imageEspeceFrancaise: nil),
    ]
}
