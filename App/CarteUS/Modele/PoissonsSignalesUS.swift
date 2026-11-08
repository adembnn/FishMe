import Foundation
import UIKit
import Core

/// Tous les textes fixes de la section « Poissons signalés ici » (clé = texte français, traduction dans `AnglaisCarteUS.xcstrings`).
/// Aucun classement, aucun mot de permission : la section dit où une espèce a été signalée et par qui, jamais qu'on peut la pêcher.
nonisolated enum TextesPoissonsUS {
    static let titre = "Poissons signalés ici"
    static let entete = "Espèces signalées dans cette zone, d'après des listes d'agences et des relevés publics ; rien ne garantit de les trouver."
    static let niveauPlanEau = "Liste pour ce plan d'eau"
    static let niveauBassin = "Liste pour ce bassin versant"
    static let niveauEtat = "Liste pour tout l'État"
    static let confianceAgence = "Liste d'agence"
    static let confianceScientifique = "Relevé scientifique"
    static let confianceNonConfirme = "Signalement public non confirmé"
    static let imageAVenir = "Image à venir"
    static let aucuneListe = "Aucune liste d'espèces pour cette zone pour l'instant"
    static let titreSources = "Sources"
    static let ouvrirSource = "Ouvrir la source"
    static let licence = "Licence"
    static let date = "Date"
    static let licenceDomainePublic = "domaine public fédéral"
    static let licenceNonPrecisee = "non précisée"

    static func niveau(_ n: NiveauZoneUS) -> String {
        switch n {
        case .planEau: niveauPlanEau
        case .huc8: niveauBassin
        case .etat: niveauEtat
        }
    }

    static func confiance(_ c: NiveauConfianceEspeceUS) -> String {
        switch c {
        case .officielle: confianceAgence
        case .enregistrementScientifique: confianceScientifique
        case .nonConfirme: confianceNonConfirme
        }
    }

    /// Tous les textes affichés, pour la recherche des mots interdits.
    static var tous: [String] {
        [titre, entete, niveauPlanEau, niveauBassin, niveauEtat, confianceAgence, confianceScientifique, confianceNonConfirme,
         imageAVenir, aucuneListe, titreSources, ouvrirSource, licence, date, licenceDomainePublic, licenceNonPrecisee]
    }
}

/// Les poissons du catalogue d'images de l'app sont des espèces de France. Une espèce américaine n'emprunte l'image d'une espèce
/// de France que si la table des espèces (`especes-us.json`, `correspondance_fr.lien` = « = ») dit que c'est la même espèce.
/// Toute autre espèce, ou un `slug` nul, n'a pas d'image : la vignette neutre « image à venir » prend sa place.
nonisolated enum ImagesEspecesUS {
    static let memeEspece: [String: String] = [
        "largemouth-bass": "black-bass", "smallmouth-bass": "black-bass-petite-bouche", "pumpkinseed": "perche-soleil",
        "rock-bass": "crapet-de-roche", "wiper": "raye-hybride", "channel-catfish": "barbue-de-riviere",
        "black-bullhead": "poisson-chat", "northern-pike": "brochet", "rainbow-trout": "truite-arc-en-ciel",
        "brown-trout": "truite-fario", "brook-trout": "omble-de-fontaine", "lake-trout": "cristivomer",
        "arctic-char": "omble-chevalier", "atlantic-salmon": "saumon-atlantique", "common-carp": "carpe-commune",
        "grass-carp": "carpe-amour", "bighead-carp": "carpe-grosse-tete", "silver-carp": "carpe-argentee",
        "goldfish": "poisson-rouge", "burbot": "lotte",
    ]

    static func imageExiste(_ nom: String) -> Bool { UIImage(named: nom) != nil }

    /// Nom de l'image du catalogue, ou nil (jamais l'image d'une autre espèce).
    static func nomImage(slug: String?, existe: (String) -> Bool = imageExiste) -> String? {
        guard let slug, let nom = memeEspece[slug], existe(nom) else { return nil }
        return nom
    }
}

nonisolated struct VignetteEspeceUS: Sendable, Equatable, Identifiable {
    var id: String
    var nom: String
    var latin: String
    /// nil : « image à venir ».
    var nomImage: String?
    var confiance: String
    var sources: [SourceEspeceUS]
}

nonisolated struct SourceAfficheeUS: Sendable, Equatable, Hashable {
    var nom: String
    var lien: URL?
    var date: String
    var licence: String
}

/// Ce que montre la section pour une fiche : la liste en images, ou un message honnête avec le lien de l'agence.
nonisolated struct PoissonsSignalesUS: Sendable, Equatable {
    enum Contenu: Sendable, Equatable {
        case especes(niveau: String, vignettes: [VignetteEspeceUS], sources: [SourceAfficheeUS])
        case sansDonnee(texte: String, lienAgence: URL?, libelleLien: String)
    }
    var contenu: Contenu

    static func pour(fiche: FicheUS,
                     charger: (String, ZoneDemandeeUS) -> ResultatEspecesUS = { e, z in EspecesUS.signalees(etat: e, zone: z) },
                     imageExiste: (String) -> Bool = ImagesEspecesUS.imageExiste) -> PoissonsSignalesUS {
        let zone = ZoneDemandeeUS(planEau: fiche.planEau)
        return construire(resultat: charger(fiche.etat, zone), fiche: fiche, imageExiste: imageExiste)
    }

    static func construire(resultat: ResultatEspecesUS, fiche: FicheUS,
                           imageExiste: (String) -> Bool = ImagesEspecesUS.imageExiste) -> PoissonsSignalesUS {
        guard let niveau = resultat.niveau, !resultat.especes.isEmpty else {
            return PoissonsSignalesUS(contenu: .sansDonnee(texte: TextesPoissonsUS.aucuneListe, lienAgence: fiche.lienAgence,
                                                           libelleLien: fiche.libelleLien))
        }
        var vues: [SourceAfficheeUS] = []
        let vignettes = resultat.especes.enumerated().map { i, e in
            for s in e.sources {
                let a = SourceAfficheeUS(nom: s.nom, lien: lienHttpsCarteUS(s.url), date: s.date, licence: s.licence)
                if !vues.contains(a) { vues.append(a) }
            }
            return VignetteEspeceUS(id: "\(i)-" + (e.slug ?? e.latin), nom: e.nom, latin: e.latin,
                                    nomImage: ImagesEspecesUS.nomImage(slug: e.slug, existe: imageExiste),
                                    confiance: TextesPoissonsUS.confiance(e.confiance), sources: e.sources)
        }
        return PoissonsSignalesUS(contenu: .especes(niveau: TextesPoissonsUS.niveau(niveau), vignettes: vignettes, sources: vues))
    }

    /// Tous les textes de la section (clés), pour la recherche des mots interdits.
    var textes: [String] {
        switch contenu {
        case let .especes(niveau, vignettes, sources):
            [niveau] + vignettes.flatMap { [$0.nom, $0.confiance] } + sources.flatMap { [$0.nom, $0.date, $0.licence] }
        case let .sansDonnee(texte, _, libelle):
            [texte, libelle]
        }
    }
}
