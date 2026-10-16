import Core
import Foundation

/// Logique de présentation, sans écran, testable sur Mac. Elle ne calcule ni a priori, ni seuil, ni consigne, ni poids : tout cela vient de Core.
enum PriseLogique {
    /// Noms des groupes de sosies (classes du modèle qui regroupent plusieurs espèces de `especes.json`).
    static let nomsDeGroupe: [String: String] = [
        "truite_commune": "Truite fario ou de mer", "carpe": "Carpe commune ou koï", "carassin": "Carassin ou poisson rouge",
        "ablette": "Ablette ou able de Heckel", "loche": "Loche", "anguille": "Anguille", "alose": "Alose",
        "lamproie": "Lamproie", "esturgeon": "Esturgeon", "black_bass": "Black-bass", "poisson_chat": "Poisson-chat ou barbue",
        "hotu_toxostome": "Hotu ou toxostome", "vandoise": "Vandoise", "gobie_invasif": "Gobie ou goujon de l'Amour",
        "epinoche": "Épinoche ou épinochette", "brochet": "Brochet", "ecrevisse_protegee": "Écrevisse protégée",
        "ecrevisse_invasive_autre": "Écrevisse invasive", "grenouille_verte": "Grenouille verte",
    ]

    /// Nom de la tuile d'un groupe : le nom du groupe, jamais le nom brut de sa 1re espèce (« Poisson-chat (Ameiurus…) »).
    static func nomDeGroupe(classe: String, membres: [EspecePechable]) -> String {
        if let nom = nomsDeGroupe[classe] { return nom }
        if let premier = membres.first { return nomCourt(premier.nom) }
        let brut = classe.replacingOccurrences(of: "_", with: " ")
        return brut.prefix(1).uppercased() + brut.dropFirst()
    }

    /// Le nom sans ses précisions : « Huchon (huchen) » → « Huchon », « Anguille européenne, stade jaune » → « Anguille européenne ».
    static func nomCourt(_ nom: String) -> String {
        var court = nom
        for marque in [" (", ", ", " / "] {
            if let r = court.range(of: marque) { court = String(court[..<r.lowerBound]) }
        }
        return court.trimmingCharacters(in: .whitespaces)
    }

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

    /// Le verdict affiché en haut de la carte (P23). Il vient de la table sourcée de `Core`, jamais de l'IA.
    enum VerdictAffiche: Equatable {
        /// Taille au-dessus de la taille minimale, sur toute la fourchette.
        case tailleLegale
        /// Taille au-dessus de la maille, mais une ligne pertinente reste « à vérifier » (tronçon, réserve…) ou la
        /// consommation est interdite : titre neutre, jamais de coche verte.
        case tailleRespecteeAVerifier
        /// Taille sous la taille minimale, sur toute la fourchette.
        case sousLaMaille
        /// Une autre règle n'est pas respectée (période, quota, réserve…) : « Relâche-la ».
        case regleNonRespectee
        /// Les bornes ne s'accordent pas, trop près de la maille, ou règle à vérifier : mesure sur une toise / vérifie l'arrêté.
        case aVerifier
        /// Aucune règle de taille saisie : on montre seulement la consigne de `Core`.
        case sansRegleDeTaille
    }

    /// Un résultat de `Core` par borne de la fourchette (un seul sans fourchette).
    static func verdict(resultats: [ResultatControle]) -> VerdictAffiche? {
        guard !resultats.isEmpty else { return nil }
        let autres = resultats.flatMap { $0.lignes }.filter { $0.type != .taille }
        if autres.contains(where: { $0.etat == .nonRespectee }) { return .regleNonRespectee }
        let tailles = resultats.map { r in r.lignes.first(where: { $0.type == .taille }) }
        guard tailles.allSatisfy({ $0 != nil }) else { return .sansRegleDeTaille }
        let etats = tailles.compactMap { $0?.etat }
        if etats.allSatisfy({ $0 == .respectee }) {
            return lignesQuiBloquentLeVert(resultats).isEmpty ? .tailleLegale : .tailleRespecteeAVerifier
        }
        if etats.allSatisfy({ $0 == .nonRespectee }) { return .sousLaMaille }
        return .aVerifier
    }

    /// Types de règles qui interdisent ou encadrent : jamais une coche verte, toujours une ligne visible.
    static func estUneInterdiction(_ type: TypeRegle) -> Bool {
        type == .consommation || type == .modeDePeche || type == .nuit
    }

    /// Lignes (hors taille) qui empêchent la coche verte : « à vérifier » quelle que soit la raison, ou consommation interdite.
    static func lignesQuiBloquentLeVert(_ resultats: [ResultatControle]) -> [LigneControle] {
        sansDoublon(resultats.flatMap { $0.lignes }.filter { l in
            l.type != .taille && (l.etat == .aVerifierSurPlace || l.type == .consommation)
        })
    }

    /// Lignes montrées sous le titre, hors du bloc replié : celles qui bloquent le vert et les règles d'interdiction.
    static func lignesVisibles(_ resultats: [ResultatControle]) -> [LigneControle] {
        sansDoublon(resultats.flatMap { $0.lignes }.filter { l in
            l.type != .taille && (l.etat == .aVerifierSurPlace || estUneInterdiction(l.type))
        })
    }

    private static func sansDoublon(_ lignes: [LigneControle]) -> [LigneControle] {
        var vues = Set<LigneControle>()
        return lignes.filter { vues.insert($0).inserted }
    }

    /// Présentation d'une ligne : décidée sur le type, pas seulement sur l'état.
    enum StyleLigne: Equatable {
        case coche, calendrier, info, aVerifier, alerte
    }

    static func styleDeLigne(type: TypeRegle, etat: EtatLigne) -> StyleLigne {
        if etat == .nonRespectee { return .alerte }
        if estUneInterdiction(type) { return etat == .aVerifierSurPlace ? .aVerifier : .info }
        switch etat {
        case .respectee: return type == .periode ? .calendrier : .coche
        case .aVerifierSurPlace: return .aVerifier
        case .nonRespectee: return .alerte
        case .information: return .info
        }
    }

    /// Le choix de lieu (tronçons confirmés) enregistré pour le coin de la prise : la station la plus proche, à 1,5 km au plus,
    /// qui a un choix gardé. `nil` sinon : la prise garde alors le lieu calculé sans choix.
    static func choixEnregistre(pres c: Coordonnee, stations: [StationOFB], lire: (String) -> ChoixLieu?) -> ChoixLieu? {
        stations
            .map { ($0, distanceMetres($0.coordonnee, c)) }
            .filter { $0.1 <= 1500 }
            .sorted { $0.1 < $1.1 }
            .lazy.compactMap { lire($0.0.codeStation) }
            .first
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

    /// Départ du curseur : le milieu de la plage, sans taille typique par espèce dans le code. Le pêcheur doit le bouger.
    static let tailleDeDepart: Double = ((plageTaille.lowerBound + plageTaille.upperBound) / 2).rounded(.up)

    /// Catégorie piscicole inconnue : une ligne neutre, jamais une alerte.
    static let categorieInconnue = "Catégorie du cours d'eau inconnue : vérifie l'arrêté"
}
