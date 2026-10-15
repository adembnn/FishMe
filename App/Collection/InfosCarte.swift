import Core
import Foundation

/// Tout ce qu'une carte affiche, calculé par Core (rareté, poids, lune, consigne) et jamais ici.
struct InfosCarte {
    var detail: CarteDetaillee
    var espece: EspecePechable
    var rarete: ResultatRarete
    var departement: Departement?
    var rangDansLaZone: Int?
    var poids: PoidsEstime?
    var lune: PhaseLune
    /// Consigne de la liste de contrôle (question 1 de README.md), avec sa source. `nil` pour une carte déclarée.
    var consigne: String?
    var sourceConsigne: String?

    var prise: Prise { detail.prise }
    var style: StyleRarete { StyleRarete(rarete.niveau) }

    /// Un seul texte lu par carte : « Brochet, rare dans le 94, 62 cm ».
    var texteVoixOff: String {
        var morceaux = [espece.nom]
        if prise.estDeclaree {
            morceaux.append("carte déclarée, sans photo")
        } else if style == .nonMesuree {
            morceaux.append("rareté non mesurée")
        } else if let d = departement {
            morceaux.append("\(style.mot) dans le \(d.code)")
        } else {
            morceaux.append(style.mot)
        }
        if let t = Formats.taille(prise) { morceaux.append(t) }
        if prise.exemple { morceaux.append("exemple") }
        return morceaux.joined(separator: ", ")
    }

    static func construire(detail: CarteDetaillee, espece: EspecePechable, zone: Departement?, toutesLesCartes: [Prise],
                           especesDeLaZone: Set<String>, services: ServicesCollection) -> InfosCarte {
        let prise = detail.prise
        let dept = Formats.departement(depuisLieuFlou: prise.lieuFlou) ?? zone
        let rarete = dept.map { services.especes.rarete(espece: prise.espece, departement: $0) }
            ?? ResultatRarete(niveau: .nonMesuree, nPeches: 0, nTotal: 0, anneeDernierReleve: nil, echelle: .departement)
        let poids = prise.longueurCm.flatMap { services.especes.poidsEstime(espece: prise.espece, longueurCm: $0) }
        var consigne: String?
        var source: String?
        if !prise.estDeclaree, let d = dept {
            let resultat = services.regles.controle(espece: prise.espece, tailleCm: prise.longueurCm, mesure: prise.mesure,
                                                    date: prise.date, lieu: Lieu(departement: d), prisesDuJour: [])
            consigne = resultat.consigne.texte
            source = resultat.lignes.first?.sources.first?.titre
        }
        return InfosCarte(detail: detail, espece: espece, rarete: rarete, departement: dept,
                          rangDansLaZone: CompteurPescedex.rang(de: prise, parmi: toutesLesCartes, zone: zone,
                                                                especesDeLaZone: especesDeLaZone),
                          poids: poids, lune: services.soleil.phaseLune(date: prise.date), consigne: consigne,
                          sourceConsigne: source)
    }
}
