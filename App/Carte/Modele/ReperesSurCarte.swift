import Core
import Foundation

/// Les repères privés (N6) posés sur la carte. Calcul pur, sans réseau : ce qui s'affiche, jamais ce qui est enregistré.
/// Les repères sont HORS du plafond de 60 éléments de `Regroupeur` : ils ne sont jamais regroupés en grappes, ne passent pas par
/// `Regroupeur.elements` et ne réduisent pas le budget des stations (`Regroupeur.maximum`, `maximumStations`). Leur nombre est borné
/// à part (`LimitesReperes.plafondTechnique`, 300) et à la zone visible. Une coordonnée de repère n'entre jamais dans
/// `PrisesDuPecheurCarte`, `CacheCarte` ni le lieu flou.
/// ⚠ à vérifier : écrit sans Mac ni compilateur.
enum ReperesSurCarte {
    /// Les repères à dessiner : aucun si le calque est éteint ou si la carte est dézoomée (`CalqueReperes.visible`), sinon ceux de la
    /// zone visible (marge de `ZoneCarte.contient`). Les pierres tombales ne sortent jamais.
    static func visibles(_ reperes: [Repere], region: ZoneCarte, calqueAllume: Bool) -> [Repere] {
        guard calqueAllume, CalqueReperes.visible(spanLatitude: region.spanLatitude) else { return [] }
        return reperes.filter { !$0.estSupprime && region.contient($0.position) }
    }

    /// L'appui long ne pose un repère que sur une carte assez zoomée : dézoomée, le point serait trop imprécis et le repère
    /// resterait caché (même seuil que le calque).
    static func peutPoser(region: ZoneCarte, modeChoixDuSpot: Bool) -> Bool {
        !modeChoixDuSpot && CalqueReperes.visible(spanLatitude: region.spanLatitude)
    }

    /// Un doigt qui a glissé de plus de ce nombre de points pendant l'appui long déplaçait la carte : rien n'est posé.
    static let glissementMaxPoints: Double = 12

    static func gestePoseUnRepere(glissement: Double) -> Bool { glissement <= glissementMaxPoints }
}
