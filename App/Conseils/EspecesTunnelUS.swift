import Core
import Foundation

/// Le tunnel des premières minutes en région US : les espèces courantes américaines dont on a une vraie image (la même espèce que
/// dans le catalogue de l'app), avec leur nom anglais. Les autres (bluegill, walleye, crappies…) attendent leur image : on ne montre
/// jamais l'image d'une espèce voisine.
nonisolated extension EspecesDuTunnel {
    static func choisirUS(pechables: [EspecePechable], nombre: Int = EspecesDuTunnel.nombre) -> [EspecePechable] {
        var choisies: [EspecePechable] = []
        for courante in EspecesCourantesUS.liste {
            guard choisies.count < nombre, let slug = courante.imageEspeceFrancaise,
                  var base = pechables.first(where: { $0.image == slug || $0.espece.id == slug }) else { continue }
            base.nom = courante.nomEn
            base.nomLatin = courante.latin
            choisies.append(base)
        }
        return choisies
    }
}
