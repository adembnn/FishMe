import Foundation

/// Une vignette de la galerie : le skin et son statut à la date du contexte.
public struct EntreeGalerie: Sendable, Equatable, Identifiable {
    public let skin: Skin
    public let statut: StatutSkin
    public var id: IdentifiantSkin { skin.id }

    public init(skin: Skin, statut: StatutSkin) {
        self.skin = skin
        self.statut = statut
    }
}

/// Les trois rangées de la galerie « Décors ».
public struct RangeesGalerie: Sendable, Equatable {
    /// Les décors gagnés en pêchant (avec « À gagner : … » pour ceux qui ne le sont pas encore) et ce qu'un défi a offert.
    public let mesDecors: [EntreeGalerie]
    /// Les thèmes de saison ouverts, et les skins Pro de toute l'année.
    public let enCeMoment: [EntreeGalerie]
    /// Les saisons closes, avec le mois de leur retour.
    public let reviennentChaqueAnnee: [EntreeGalerie]

    public init(mesDecors: [EntreeGalerie], enCeMoment: [EntreeGalerie], reviennentChaqueAnnee: [EntreeGalerie]) {
        self.mesDecors = mesDecors
        self.enCeMoment = enCeMoment
        self.reviennentChaqueAnnee = reviennentChaqueAnnee
    }
}

/// Range le catalogue dans les trois rangées. `afficher` écarte un skin sans fond (voir `skinAffichable`)
/// (jamais de vignette vide) ; le décor de départ doit toujours passer.
public func rangeesGalerie(catalogue: [Skin] = CatalogueSkins.tous, dans contexte: ContexteSkin,
                           afficher: (Skin) -> Bool = { _ in true }) -> RangeesGalerie {
    var mes: [EntreeGalerie] = []
    var maintenant: [EntreeGalerie] = []
    var plusTard: [EntreeGalerie] = []
    for skin in catalogue.sorted(by: { $0.ordre < $1.ordre }) where afficher(skin) {
        let s = statut(skin, dans: contexte)
        let entree = EntreeGalerie(skin: skin, statut: s)
        switch (skin.origine, s) {
        case (.gagne, _):
            mes.append(entree)
        case (_, .horsSaison):
            plusTard.append(entree)
        case (.offertParDefi, .disponible):
            mes.append(entree)
        default:
            maintenant.append(entree)
        }
    }
    return RangeesGalerie(mesDecors: mes, enCeMoment: maintenant, reviennentChaqueAnnee: plusTard)
}

/// D'où vient le fond d'un skin : l'illustration du skin, le fond dessiné en code, ou le fond d'avant les skins.
public enum SourceFond: Sendable, Equatable {
    case image(String)
    case dessine
    case repli(String)
}

/// Règle du fond : l'illustration du skin si elle existe, sinon le fond dessiné en code, sinon le fond d'avant les skins.
/// `imageExiste` et `fondDessine` sont injectés : Core ne lit ni jeu d'images ni SwiftUI.
public func sourceFond(_ skin: Skin?, format: FormatFond, imageExiste: (String) -> Bool,
                       fondDessine: (IdentifiantSkin) -> Bool) -> SourceFond {
    let repli = Skin.nomImageRepli(format)
    guard let skin else { return .repli(repli) }
    let nom = skin.nomImageFond(format)
    if imageExiste(nom) { return .image(nom) }
    if fondDessine(skin.id) { return .dessine }
    return .repli(repli)
}

/// Un skin se montre dans la galerie dès qu'il a un fond : illustration du skin ou fond dessiné en code.
/// Le décor de départ passe toujours. Un skin sans aucun des deux est écarté (jamais de vignette vide).
public func skinAffichable(_ skin: Skin, imageExiste: (String) -> Bool, fondDessine: (IdentifiantSkin) -> Bool) -> Bool {
    skin.id == .parDefaut || fondDessine(skin.id) || imageExiste(skin.nomImageFond(.grand))
}

/// Les textes de la galerie, écrits ici pour être testés sans l'interface.
public enum LibellesSkins {
    private static let mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
                               "septembre", "octobre", "novembre", "décembre"]

    /// « Revient en octobre » : le mois seulement, jamais un nombre de jours.
    public static func revient(le date: Date, calendrier: Calendar) -> String {
        let numero = calendrier.component(.month, from: date)
        guard (1...12).contains(numero) else { return "Revient chaque année" }
        return "Revient en \(mois[numero - 1])"
    }

    /// « À gagner : 5 espèces différentes ».
    public static func aGagner(_ critere: CritereDecor) -> String {
        switch critere {
        case .especesDifferentes(let n): return "À gagner : \(n) \(n > 1 ? "espèces différentes" : "espèce")"
        case .sessions(let n): return "À gagner : \(n) \(n > 1 ? "sessions de pêche" : "session de pêche")"
        case .unLegendaire: return "À gagner : un poisson légendaire"
        }
    }

    /// La ligne sous le nom de la vignette.
    public static func ligneStatut(_ statut: StatutSkin, calendrier: Calendar) -> String {
        switch statut {
        case .disponible: return "Disponible"
        case .apercuSeulement: return "Inclus avec Pro"
        case .horsSaison(let revientLe): return revient(le: revientLe, calendrier: calendrier)
        case .aGagner(let critere): return aGagner(critere)
        }
    }

    /// Pour VoiceOver : « Halloween, inclus avec Pro, aperçu seulement ».
    public static func accessibilite(_ skin: Skin, statut: StatutSkin, calendrier: Calendar) -> String {
        let origine: String
        switch skin.origine {
        case .gagne: origine = "décor gagné en pêchant"
        case .pro, .saison: origine = "inclus avec Pro"
        case .offertParDefi: origine = "récompense de défi"
        }
        let etat: String
        switch statut {
        case .disponible: etat = "disponible"
        case .apercuSeulement: etat = "aperçu seulement, Pro requis pour l'appliquer"
        case .horsSaison, .aGagner: etat = ligneStatut(statut, calendrier: calendrier)
        }
        return "\(skin.nom), \(origine), \(etat)"
    }

    /// Libellé du bouton du bandeau d'aperçu.
    public static func boutonAppliquer(_ statut: StatutSkin) -> String? {
        switch statut {
        case .disponible: return "Appliquer"
        case .apercuSeulement: return "Appliquer avec Pro"
        case .horsSaison, .aGagner: return nil
        }
    }
}
