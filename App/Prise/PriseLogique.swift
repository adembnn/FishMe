import Core
import Foundation

/// Logique de présentation, sans écran, testable sur Mac. Elle ne calcule ni a priori, ni seuil, ni consigne, ni poids : tout cela vient de Core.
enum PriseLogique {
    struct Groupe: Equatable {
        var famille: PriseFamille
        var especes: [EspecePechable]
        var duCoin: Set<String>
    }

    /// Toutes les espèces, groupées par famille ; dans chaque famille, celles du coin d'abord (les plus relevées en tête), puis l'ordre alphabétique.
    static func groupes(catalogue: [EspecePechable], proches: [EspeceProche], filtreClasse: String? = nil) -> [Groupe] {
        let releves = Dictionary(proches.map { ($0.espece.id, $0.nPeches) }, uniquingKeysWith: { max($0, $1) })
        var base = catalogue
        if let classe = filtreClasse {
            let filtre = catalogue.filter { $0.classeModele == classe }
            if !filtre.isEmpty { base = filtre }
        }
        return PriseFamille.allCases.compactMap { famille in
            let membres = base.filter { PriseFamille.de($0.espece.id) == famille }
            guard !membres.isEmpty else { return nil }
            let tries = membres.sorted { a, b in
                let na = releves[a.espece.id]
                let nb = releves[b.espece.id]
                if let x = na, let y = nb { return x != y ? x > y : a.nom < b.nom }
                if na != nil { return true }
                if nb != nil { return false }
                return a.nom < b.nom
            }
            return Groupe(famille: famille, especes: tries, duCoin: Set(membres.map { $0.espece.id }.filter { releves[$0] != nil }))
        }
    }

    /// Les sosies d'une espèce : l'entrée du catalogue, le critère et sa source, lus dans les données.
    static func sosies(de entree: EspecePechable, catalogue: [EspecePechable]) -> [(entree: EspecePechable, confusion: Confusion)] {
        entree.confusions.compactMap { c in
            guard let autre = catalogue.first(where: { $0.espece == c.avec }) else { return nil }
            return (entree: autre, confusion: c)
        }
    }

    static func estAnguille(_ espece: Espece) -> Bool {
        espece.id.hasPrefix("anguille") || espece.id == "civelle"
    }

    static func stade(de espece: Espece) -> StadeAnguille? {
        guard estAnguille(espece) else { return nil }
        if espece.id.contains("argent") { return .argentee }
        if espece.id == "civelle" { return .civelle }
        return .jaune
    }

    /// Les stades de l'anguille, avec le critère qui les sépare (lu dans le champ `confusions` des entrées).
    static func stades(catalogue: [EspecePechable]) -> [(entree: EspecePechable, critere: Confusion?)] {
        let anguilles = catalogue.filter { estAnguille($0.espece) }
        let toutes = anguilles.flatMap { $0.confusions }
        return anguilles.map { entree in
            let critere = toutes.first(where: { $0.avec == entree.espece }) ?? entree.confusions.first
            return (entree: entree, critere: critere)
        }
    }

    /// Une confirmation en deux gestes pour une entrée aux sosies coûteux.
    static func demandeSosies(_ entree: EspecePechable) -> Bool { !entree.confusions.isEmpty }

    /// Vrai si le pêcheur vient déjà de départager l'espèce et tous ses sosies dans un groupe du modèle
    /// (ex. « brochet ou brochet aquitain ») : on ne redemande pas la même distinction.
    static func sosiesDejaTranches(_ entree: EspecePechable, classe: String?, catalogue: [EspecePechable]) -> Bool {
        guard let classe, entree.classeModele == classe, !entree.confusions.isEmpty else { return false }
        return entree.confusions.allSatisfy { c in
            catalogue.first(where: { $0.espece == c.avec })?.classeModele == classe
        }
    }

    /// « Trop près de la maille » : lu dans les lignes que `controle` rend, jamais recalculé ici.
    static func tropPresDeLaMaille(_ resultat: ResultatControle) -> Bool {
        resultat.lignes.contains { $0.raison == .tropPresDeLaMaille }
    }

    /// Avant confirmation de l'espèce : seulement la consigne « relâche-la ».
    static let consigneAvantConfirmation = Consigne.relacheLa.texte
    /// Phrase imposée sous chaque verdict (docs/donnees.md).
    static let avertissement = "Information indicative : l'arrêté préfectoral fait foi. En cas de doute, relâche."

    /// « ≈ 1,4 kg estimé ».
    static func texteDuPoids(_ poids: PoidsEstime) -> String {
        "≈ \(kilos(poids.kilos)) kg estimé"
    }

    static func kilos(_ valeur: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: valeur)) ?? String(valeur)
    }

    static func texteDeLaFourchette(_ poids: PoidsEstime) -> String {
        "Entre \(kilos(poids.minKilos)) et \(kilos(poids.maxKilos)) kg"
    }

    static let calculePasPese = "Calculé, pas pesé"

    /// Limites du curseur de taille, en centimètres.
    static let plageTaille: ClosedRange<Double> = 5...150
}
