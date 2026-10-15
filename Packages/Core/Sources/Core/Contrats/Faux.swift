import Foundation

// Les faux : des valeurs écrites en dur, jamais un calcul. A ne les branche que sous `#if DEBUG`.

/// Le 15 oct. 2026, 12:00 UTC : date fixe des faux.
let dateFaux = Date(timeIntervalSince1970: 1_792_065_600)

let brochet = Espece(id: "brochet", codeSandre: "2151")
let sandre = Espece(id: "sandre", codeSandre: "2195")
let perche = Espece(id: "perche-commune", codeSandre: "2193")
let anguilleJaune = Espece(id: "anguille-jaune")
let ecrevissePattesBlanches = Espece(id: "ecrevisse-pattes-blanches")
let ecrevisseSignal = Espece(id: "ecrevisse-signal")

let marne = Eau(nom: "La Marne", cle: "marne", type: .riviere)
let mauldre = Eau(nom: "La Mauldre", cle: "mauldre", type: .riviere)
let stationCharenton = StationHydro(code: "F000TEST", nom: "La Marne à Charenton (code d'essai)", eau: "La Marne",
                                    coordonnee: Coordonnee(latitude: 48.82, longitude: 2.41))

public struct GeoFaux: ServiceGeo {
    public init() {}

    public func departement(de coordonnee: Coordonnee) -> Departement { Departement(code: "94") }

    public func lieu(de coordonnee: Coordonnee, choix: ChoixLieu?) -> Lieu {
        Lieu(departement: Departement(code: "94"), eau: marne, categorie: CategorieEau(valeur: .deuxieme, origine: .regleDeReste))
    }

    public func eauxProches(_ coordonnee: Coordonnee) -> [Eau] { [marne, mauldre] }

    public func lieuFlou(_ coordonnee: Coordonnee) -> String { "La Marne · 94" }
}

public struct ReglesFaux: ServiceRegles {
    public var resultat: ResultatControle

    /// Par défaut : brochet, taille respectée, aucune règle ne l'interdit. Passer un autre résultat pour jouer les autres consignes.
    public init(resultat: ResultatControle = ReglesFaux.resultatParDefaut) {
        self.resultat = resultat
    }

    public static let ligneTaille = LigneControle(
        type: .taille, etat: .respectee, phrase: "Brochet : 60 cm au moins",
        sources: [SourceRegle(titre: "Arrêté préfectoral (essai)"), SourceRegle(titre: "Avis annuel 2026 (essai)")],
        citation: "taille minimale de capture du brochet : 0,60 m", dateLecture: dateFaux)

    public static let resultatParDefaut = ResultatControle(lignes: [ligneTaille], consigne: .aucuneRegleSaisieNeLInterdit)

    public func controle(espece: Espece, tailleCm: Double?, mesure: MethodeMesure?, date: Date, lieu: Lieu,
                         prisesDuJour: [Prise]) -> ResultatControle { resultat }

    public func reglesDuJour(lieu: Lieu, date: Date) -> [LigneControle] { resultat.lignes }

    public func verdictTaille(longueurCm: Double, mesure: MethodeMesure, maille: Double) -> VerdictTaille {
        mesure == .estimee ? .sansVerdict : .respectee
    }

    public func departementsCouverts() -> [DepartementCouvert] {
        [DepartementCouvert(departement: Departement(code: "94"), niveau: .complet, reglesConfirmees: 40, lignesAVerifier: 2, dateLecture: dateFaux)]
    }

    public func credits() -> [Credit] { [Credit(nom: "OFB (essai)", url: "https://example.org", mention: "Licence ouverte")] }

    public func liensFederation(departement: Departement) -> LiensFederation {
        LiensFederation(siteFederation: "https://example.org/federation", pageCarteDePeche: "https://example.org/carte")
    }
}

public struct EspecesFaux: ServiceEspeces {
    public init() {}

    public func rarete(espece: Espece, departement: Departement) -> ResultatRarete {
        ResultatRarete(niveau: .commun, nPeches: 9, nTotal: 29, anneeDernierReleve: 2024, echelle: .departement)
    }

    public func especesProches(_ coordonnee: Coordonnee) -> [EspeceProche] {
        [EspeceProche(espece: brochet, nPeches: 9, annee: 2024, ouverture: .ouverte),
         EspeceProche(espece: perche, nPeches: 14, annee: 2024, ouverture: .ouverte)]
    }

    public func coins(ou espece: Espece, pres coordonnee: Coordonnee) -> [Coin] {
        [Coin(codeStation: "STATION-ESSAI", eau: "La Marne", departement: Departement(code: "94"),
              coordonnee: Coordonnee(latitude: 48.8, longitude: 2.4), distanceM: 1200, nPeches: 9, annee: 2024, ouverture: .ouverte)]
    }

    /// 6 entrées : brochet, sandre, perche, anguille jaune, écrevisse à pattes blanches, écrevisse signal.
    public func especesPechables() -> [EspecePechable] {
        [
            EspecePechable(espece: brochet, nom: "Brochet", nomLatin: "Esox lucius", classeModele: "brochet", image: "brochet"),
            EspecePechable(espece: sandre, nom: "Sandre", nomLatin: "Sander lucioperca", classeModele: "sandre", image: "sandre"),
            EspecePechable(espece: perche, nom: "Perche commune", nomLatin: "Perca fluviatilis", classeModele: "perche", image: "perche"),
            EspecePechable(espece: anguilleJaune, nom: "Anguille européenne, stade jaune", nomLatin: "Anguilla anguilla",
                           image: "anguille", statuts: [.stadeADemander]),
            EspecePechable(espece: ecrevissePattesBlanches, nom: "Écrevisse à pattes blanches", nomLatin: "Austropotamobius pallipes",
                           image: "ecrevisse-pattes-blanches", statuts: [.protegee, .toujoursRelachee]),
            EspecePechable(espece: ecrevisseSignal, nom: "Écrevisse signal", nomLatin: "Pacifastacus leniusculus",
                           image: "ecrevisse-signal", statuts: [.envahissante],
                           confusions: [Confusion(avec: ecrevissePattesBlanches, critere: "Tache blanche à la jonction des pinces (essai)", source: "essai")]),
        ]
    }

    public func classer(scores: [String: Double], especesProches: [Espece]) -> [Proposition] {
        [Proposition(type: .espece(brochet)), Proposition(type: .espece(sandre)), Proposition(type: .espece(perche)),
         Proposition(type: .autreEspece), Proposition(type: .pasUnPoisson)]
    }

    public func poidsEstime(espece: Espece, longueurCm: Double) -> PoidsEstime? {
        PoidsEstime(kilos: 1.4, minKilos: 1.2, maxKilos: 1.6, source: "Formule longueur-poids (essai)")
    }
}

public struct SoleilFaux: ServiceSoleil {
    public init() {}

    public func finLegale(date: Date, coordonnee: Coordonnee) -> Date? { dateFaux.addingTimeInterval(6 * 3600) }

    public func phaseLune(date: Date) -> PhaseLune { .pleine }
}

public struct SessionFaux: ServiceSession {
    /// Valeur de `peutUtiliser` : toujours ouvert (par défaut) ou toujours fermé.
    public var toutOuvert: Bool

    public init(toutOuvert: Bool = true) {
        self.toutOuvert = toutOuvert
    }

    public func quota(prisesGardeesDuJour: [Prise], departement: Departement) -> QuotaDuJour {
        QuotaDuJour(gardees: 2, plafond: 3, source: SourceRegle(titre: "Quota carnassiers (essai)"))
    }

    public func spotPropose(coordonnee: Coordonnee, date: Date) -> Spot? {
        Spot(centre: Coordonnee(latitude: 48.82, longitude: 2.41), departement: Departement(code: "94"))
    }

    public func acces(sessionsTerminees: Int, spot: Spot, spotGratuit: Spot?, abonne: Bool) -> DecisionAcces {
        DecisionAcces(sessionPermise: true, paywall: .aucun, spotGratuit: spotGratuit ?? spot)
    }

    public func peutUtiliser(_ fonction: FonctionPro, abonne: Bool, surSonSpot: Bool) -> Bool { toutOuvert }

    public func offreAffichee(date: Date) -> OffreAffichee {
        OffreAffichee(produit: "annuel", prixCentimes: 3499, tarifFondateur: true)
    }
}

public struct ConditionsFaux: ServiceConditions {
    public init() {}

    public func lireConditions(meteo: MeteoBrute, eau: NiveauEau?, date: Date) -> Conditions {
        Conditions(heure: dateFaux, ventKmh: 14, pluieMm: 0, pressionHPa: 1016, tendancePressionHPa6h: -3,
                   aube: dateFaux.addingTimeInterval(-4 * 3600), crepuscule: dateFaux.addingTimeInterval(5 * 3600),
                   finLegale: dateFaux.addingTimeInterval(6 * 3600), etatRiviere: .normal,
                   sources: ["Apple Weather (essai)", "Hub'Eau (essai)"])
    }

    public func alerte(meteo: MeteoBrute, eau: NiveauEau?) -> Alerte? { nil }

    public func stationHydro(pres coordonnee: Coordonnee) -> StationHydro? { stationCharenton }

    public func pointMeteo(spot: Coordonnee) -> Coordonnee { Coordonnee(latitude: 48.8, longitude: 2.4) }

    public func tesConditions(sorties: [Sortie]) -> [Constat]? {
        [Constat(texte: "4 perches sur 6 par vent d'ouest", nPeches: 4, surSorties: 6),
         Constat(texte: "2 brochets sur 3 sous pression en baisse", nPeches: 2, surSorties: 3)]
    }
}

/// Alerte « orage » en dur, pour tester la bannière.
public struct AlerteOrageFaux: Sendable {
    public static let alerte = Alerte(type: .orage, mesure: "Orage prévu dans 2 h (essai)", source: "Apple Weather (essai)", heure: dateFaux)
}

/// Alerte « crue » en dur, pour tester la bannière.
public struct AlerteCrueFaux: Sendable {
    public static let alerte = Alerte(type: .crue, mesure: "+60 cm en 24 h (essai)", source: "Hub'Eau (essai)", heure: dateFaux)
}

/// Faux de `NiveauEauService` : aucun appel réseau. Quatre états écrits en dur.
public struct NiveauEauFaux: NiveauEauService {
    public enum Scenario: String, Sendable, Equatable, Hashable, CaseIterable {
        case normal
        case haut
        case forteHausse
        case sansReseau
    }

    public var scenario: Scenario

    public init(scenario: Scenario = .normal) {
        self.scenario = scenario
    }

    public func niveau(station: StationHydro) async -> NiveauEau? {
        switch scenario {
        case .sansReseau:
            return nil
        case .normal:
            return NiveauEau(station: station, hauteurM: 1.2, debitM3s: 40, normaleDebitM3s: 45, vigilance: .vert, heureMesure: dateFaux)
        case .haut:
            return NiveauEau(station: station, hauteurM: 2.4, debitM3s: 100, normaleDebitM3s: 45, vigilance: .jaune, heureMesure: dateFaux)
        case .forteHausse:
            return NiveauEau(station: station, hauteurM: 3.1, debitM3s: 180, serie48h: [
                MesureNiveau(heure: dateFaux.addingTimeInterval(-86_400), hauteurM: 2.5, debitM3s: 110),
                MesureNiveau(heure: dateFaux, hauteurM: 3.1, debitM3s: 180),
            ], normaleDebitM3s: 45, vigilance: .orange, heureMesure: dateFaux)
        }
    }
}

public struct ConseilsFaux: ServiceConseils {
    public init() {}

    public func conseils(espece: Espece, niveau: NiveauPecheur, mois: Int) -> [Conseil] {
        [Conseil(texte: "Un leurre souple de 10 cm, lentement", icone: "fish", source: SourceRegle(titre: "Fédération (essai)"), gratuit: true),
         Conseil(texte: "Pêche les bordures près des herbiers", icone: "leaf", source: SourceRegle(titre: "Fédération (essai)"), gratuit: false)]
    }

    public func conseils(espece: Espece, niveau: NiveauPecheur, mois: Int, lieu: Lieu) -> [Conseil] {
        conseils(espece: espece, niveau: niveau, mois: mois)
    }
}

/// Faux de `IdentifieEspece` : des scores en dur, ou la grille avec sa raison.
public struct IdentifieEspeceFaux: IdentifieEspece {
    public var resultat: ResultatIdentification

    public init(resultat: ResultatIdentification = .scores(["brochet": 0.6, "sandre": 0.25, "perche": 0.1])) {
        self.resultat = resultat
    }

    public func identifier(photo: Data) async -> ResultatIdentification { resultat }
}

/// Faux de `Achats` : rejoue un scénario d'états écrit à l'avance (essai, délai de grâce, remboursement, révocation, sans réseau).
public struct AchatsFaux: Achats {
    public var scenario: [EtatAchats]

    public init(scenario: [EtatAchats] = [.nonAbonne]) {
        self.scenario = scenario
    }

    public static let delaiDeGrace = AchatsFaux(scenario: [.abonne, .relancePaiement, .delaiDeGrace(fin: dateFaux.addingTimeInterval(16 * 86_400)), .expire])
    public static let remboursement = AchatsFaux(scenario: [.abonne, .rembourse])
    public static let revocation = AchatsFaux(scenario: [.abonne, .revoque])
    public static let sansReseau = AchatsFaux(scenario: [.sansReseau(dernierEtatAbonne: true)])

    public func etat() async -> EtatAchats { scenario.last ?? .nonAbonne }

    public func modifications() -> AsyncStream<EtatAchats> {
        let etats = scenario
        return AsyncStream { continuation in
            for etat in etats { continuation.yield(etat) }
            continuation.finish()
        }
    }

    public func acheter(produit: String) async -> EtatAchats { .abonne }

    public func restaurer() async -> EtatAchats { scenario.last ?? .nonAbonne }
}

/// Faux de `Mesure` : retient les événements reçus, n'envoie rien.
public final class MesureFaux: Mesure, @unchecked Sendable {
    private let verrou = NSLock()
    private var recus: [EvenementMesure] = []

    public init() {}

    public func envoyer(_ evenement: EvenementMesure) {
        verrou.lock()
        recus.append(evenement)
        verrou.unlock()
    }

    public var evenements: [EvenementMesure] {
        verrou.lock()
        defer { verrou.unlock() }
        return recus
    }
}

/// Faux de `CollectionCartes` : une vraie prise et une carte déclarée.
public struct CollectionFaux: CollectionCartes {
    public init() {}

    public func cartes() async -> [Prise] {
        [Prise(espece: brochet, longueurCm: 60, mesure: .toise, date: dateFaux, lieuFlou: "La Marne · 94", cheminPhoto: "photos/essai.jpg"),
         Prise.declaree(espece: perche, date: dateFaux)]
    }

    public func imagePNG(de carte: Prise) async -> Data? {
        carte.estDeclaree ? nil : Data([0x89, 0x50, 0x4E, 0x47])
    }
}
