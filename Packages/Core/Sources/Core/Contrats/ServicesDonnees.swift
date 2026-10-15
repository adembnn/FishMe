import Foundation

// Contrats gelés au merge de C0 : ajouts seulement, jamais de renommage. Un contrat dit ce qui entre, ce qui sort et les cas d'échec.
// Aucun calcul ici : L1 remplit les contrats, chaque faux rend des valeurs écrites en dur.

/// Géographie : point, département, lieu.
public protocol ServiceGeo: Sendable {
    /// Code du département, ou « inconnu » (hors de France).
    func departement(de coordonnee: Coordonnee) -> Departement
    /// Le lieu d'un point, hors ligne. Cas d'échec : `Lieu.inconnu`.
    func lieu(de coordonnee: Coordonnee, choix: ChoixLieu?) -> Lieu
    /// Les eaux à proposer (« Tu pêches sur : La Marne | un plan d'eau | autre »). Vide si aucune.
    func eauxProches(_ coordonnee: Coordonnee) -> [Eau]
    /// « La Marne · 94 », jamais le point exact ; sans eau connue, le département seul.
    func lieuFlou(_ coordonnee: Coordonnee) -> String
}

/// Règles : liste de contrôle, fiche d'un coin, taille, couverture.
public protocol ServiceRegles: Sendable {
    /// La liste de contrôle puis une consigne globale. Jamais de valeur d'autorisation.
    /// Cas d'échec : consigne `.verifieLArrete`.
    func controle(espece: Espece, tailleCm: Double?, mesure: MethodeMesure?, date: Date, lieu: Lieu,
                  prisesDuJour: [Prise]) -> ResultatControle
    /// Les lignes de la fiche d'un coin (E2), même forme que `controle`.
    func reglesDuJour(lieu: Lieu, date: Date) -> [LigneControle]
    /// `.sansVerdict` pour une mesure estimée ; `.tropPres` à moins de 2 cm de la maille.
    func verdictTaille(longueurCm: Double, mesure: MethodeMesure, maille: Double) -> VerdictTaille
    /// Lit les fichiers présents, jamais une liste écrite.
    func departementsCouverts() -> [DepartementCouvert]
    func credits() -> [Credit]
    func liensFederation(departement: Departement) -> LiensFederation
}

/// Espèces : rareté, espèces d'un coin, reconnaissance, poids.
public protocol ServiceEspeces: Sendable {
    func rarete(espece: Espece, departement: Departement) -> ResultatRarete
    func especesProches(_ coordonnee: Coordonnee) -> [EspeceProche]
    func coins(ou espece: Espece, pres coordonnee: Coordonnee) -> [Coin]
    func especesPechables() -> [EspecePechable]
    /// Transforme les scores du modèle en 3 propositions, puis toujours « autre espèce » et « pas un poisson ».
    func classer(scores: [String: Double], especesProches: [Espece]) -> [Proposition]
    /// `nil` sans coefficient ou hors de la plage de l'étude.
    func poidsEstime(espece: Espece, longueurCm: Double) -> PoidsEstime?
}

/// Soleil et lune.
public protocol ServiceSoleil: Sendable {
    /// Coucher du soleil + 30 min, avec 1 min de marge. `nil` si le calcul est impossible.
    func finLegale(date: Date, coordonnee: Coordonnee) -> Date?
    func phaseLune(date: Date) -> PhaseLune
}

/// Session, spot gratuit, accès, offre.
public protocol ServiceSession: Sendable {
    /// Nombre de poissons gardés ce jour-là sur toutes les sessions, comparé au quota du département.
    func quota(prisesGardeesDuJour: [Prise], departement: Departement) -> QuotaDuJour
    /// Le coin le plus proche avec des relevés OFB récents et une espèce ouverte ce jour ; `nil` à plus de 30 km.
    func spotPropose(coordonnee: Coordonnee, date: Date) -> Spot?
    func acces(sessionsTerminees: Int, spot: Spot, spotGratuit: Spot?, abonne: Bool) -> DecisionAcces
    func peutUtiliser(_ fonction: FonctionPro, abonne: Bool, surSonSpot: Bool) -> Bool
    func offreAffichee(date: Date) -> OffreAffichee
}

/// Quota du jour : combien gardés, quel plafond (`nil` : aucun quota saisi).
public struct QuotaDuJour: Sendable, Equatable, Hashable, Codable {
    public var gardees: Int
    public var plafond: Int?
    public var source: SourceRegle?

    public init(gardees: Int, plafond: Int?, source: SourceRegle? = nil) {
        self.gardees = gardees
        self.plafond = plafond
        self.source = source
    }
}

/// Conditions : météo en nombres, alertes, stations.
public protocol ServiceConditions: Sendable {
    func lireConditions(meteo: MeteoBrute, eau: NiveauEau?, date: Date) -> Conditions
    /// Orage ou crue, sinon `nil`. Toujours gratuit.
    func alerte(meteo: MeteoBrute, eau: NiveauEau?) -> Alerte?
    /// La station à interroger, sur l'iPhone, dans `stations-hydro.json`. `nil` sans station.
    func stationHydro(pres coordonnee: Coordonnee) -> StationHydro?
    /// Le point envoyé à WeatherKit, jamais la position exacte.
    func pointMeteo(spot: Coordonnee) -> Coordonnee
    /// Après 10 sorties, des comptes ; `nil` avant.
    func tesConditions(sorties: [Sortie]) -> [Constat]?
}

/// Niveau de la rivière (Hub'Eau hydrométrie). Sans réseau ou sans station : `nil`.
public protocol NiveauEauService: Sendable {
    func niveau(station: StationHydro) async -> NiveauEau?
}

/// Conseils par espèce (D4).
public protocol ServiceConseils: Sendable {
    func conseils(espece: Espece, niveau: NiveauPecheur, mois: Int) -> [Conseil]
    /// Sans les conseils qu'une ligne du jour interdit sur ce lieu.
    func conseils(espece: Espece, niveau: NiveauPecheur, mois: Int, lieu: Lieu) -> [Conseil]
}

/// Contrats branchés côté app, chacun avec son faux.

/// Reconnaissance : des scores par classe du modèle, ou la grille de toutes les espèces avec la raison.
public protocol IdentifieEspece: Sendable {
    func identifier(photo: Data) async -> ResultatIdentification
}

/// Abonnement (StoreKit 2, rempli par L6).
public protocol Achats: Sendable {
    /// Dernier état vérifié.
    func etat() async -> EtatAchats
    /// Les changements d'état, `Transaction.updates` écouté dès le lancement.
    func modifications() -> AsyncStream<EtatAchats>
    func acheter(produit: String) async -> EtatAchats
    func restaurer() async -> EtatAchats
}

/// Mesure d'usage : les 6 événements de l'entonnoir, sans donnée personnelle.
public protocol Mesure: Sendable {
    func envoyer(_ evenement: EvenementMesure)
}

/// Les cartes du Pescedex (L4 la remplit ; L9 et L8 s'en servent sans importer `App/Collection/`).
/// Nommé `CollectionCartes` : `Collection` est déjà un protocole de Swift.
public protocol CollectionCartes: Sendable {
    /// Toutes les cartes, vraies prises et cartes déclarées (`Prise.origine`).
    func cartes() async -> [Prise]
    /// L'image PNG d'une carte, sans métadonnée GPS, prête à partager. `nil` si la carte n'existe pas.
    func imagePNG(de carte: Prise) async -> Data?
}
