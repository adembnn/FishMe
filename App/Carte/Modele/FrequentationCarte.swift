import Foundation
import Core

/// Ce que la carte garde sur cet iPhone pour la fréquentation (docs/frequentation.md) : la graine du jeton du jour
/// et les passages. Rien ne quitte l'iPhone d'ici ; aucun lieu exact n'est écrit, seulement un id de station et un jour.
nonisolated enum ReglagesFrequentation {
    private static let cleGraine = "frequentation.graine"
    private static let clePassages = "frequentation.passages"
    /// Même clé que `ClesConseils.niveau` (App/Conseils) : un dossier de l'app n'importe pas un autre dossier.
    private static let cleNiveau = "conseils.niveauPecheur"

    /// Tirée une fois au hasard, puis gardée. À brancher : trousseau (aucun utilitaire générique n'existe encore).
    static func graine() -> UInt64 {
        let d = UserDefaults.standard
        if let texte = d.string(forKey: cleGraine), let valeur = UInt64(texte) { return valeur }
        let neuve = UInt64.random(in: UInt64.min...UInt64.max)
        d.set(String(neuve), forKey: cleGraine)
        return neuve
    }

    /// Le niveau du pêcheur choisi à la question du premier lancement ; `nil` si elle n'a pas été vue.
    static func niveauPecheur() -> NiveauPecheur? {
        UserDefaults.standard.string(forKey: cleNiveau).flatMap { NiveauPecheur(rawValue: $0) }
    }

    static func lirePassages() -> [Passage] {
        guard let donnees = UserDefaults.standard.data(forKey: clePassages) else { return [] }
        return (try? JSONDecoder().decode([Passage].self, from: donnees)) ?? []
    }

    static func ecrirePassages(_ passages: [Passage]) {
        guard let donnees = try? JSONEncoder().encode(passages) else { return }
        UserDefaults.standard.set(donnees, forKey: clePassages)
    }
}

/// `CompteurLocal` de `Core`, dont les passages survivent au relancement de l'app.
actor CompteurSauvegarde: CompteurFrequentation {
    private let local: CompteurLocal

    init() {
        local = CompteurLocal(passages: ReglagesFrequentation.lirePassages())
    }

    func enregistrer(_ p: Passage) async {
        await local.enregistrer(p)
        ReglagesFrequentation.ecrirePassages(await local.passages)
    }

    func niveau(troncon: String, aujourdhui: Date) async -> NiveauFrequentation? {
        await local.niveau(troncon: troncon, aujourdhui: aujourdhui)
    }
}

extension ServicesCarte {
    /// Le compteur par défaut : celui de l'iPhone en release, des niveaux fixés pour la démo en DEBUG.
    nonisolated static func compteurParDefaut() -> any CompteurFrequentation {
#if DEBUG
        // Station du faux `Core` : la démo du simulateur montre « Chargé » et le bouton « Coin plus calme ».
        return CompteurDemo(niveaux: ["STATION-ESSAI": .charge])
#else
        return CompteurSauvegarde()
#endif
    }
}
