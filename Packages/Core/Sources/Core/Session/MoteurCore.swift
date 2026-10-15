import Foundation

/// Les octets des fichiers de données que les moteurs lisent. Un fichier absent donne un moteur plus pauvre, jamais un plantage.
public struct DonneesMoteur: Sendable {
    public var departements: Data?
    public var lacs: Data?
    public var especes: Data?
    public var longueurPoids: Data?
    public var stationsEspeces: Data?
    public var rareteDepartements: Data?
    public var stationsHydro: Data?
    public var credits: Data?
    public var liensFederations: Data?
    public var regles: ChargeurRegles

    public init(departements: Data? = nil, lacs: Data? = nil, especes: Data? = nil, longueurPoids: Data? = nil,
                stationsEspeces: Data? = nil, rareteDepartements: Data? = nil, stationsHydro: Data? = nil,
                credits: Data? = nil, liensFederations: Data? = nil, regles: ChargeurRegles) {
        self.departements = departements
        self.lacs = lacs
        self.especes = especes
        self.longueurPoids = longueurPoids
        self.stationsEspeces = stationsEspeces
        self.rareteDepartements = rareteDepartements
        self.stationsHydro = stationsHydro
        self.credits = credits
        self.liensFederations = liensFederations
        self.regles = regles
    }

    /// Les fichiers embarqués dans le paquet. `dossierFabriques` : où `scripts/donnees.sh` a téléchargé `stations-especes.json`
    /// et `rarete-departements.json` (jamais commités, donc absents du paquet) ; `reglesTelechargees` : la copie de L11.
    public static func embarque(dossierFabriques: URL? = nil, reglesTelechargees: URL? = nil) -> DonneesMoteur {
        func fabrique(_ nom: String) -> Data? {
            if let d = dossierFabriques, let donnees = try? Data(contentsOf: d.appendingPathComponent(nom)) { return donnees }
            return Ressources.donnees(String(nom.dropLast(5)))
        }
        return DonneesMoteur(
            departements: Ressources.donnees("departements", extension: "geojson"), lacs: Ressources.donnees("lacs", extension: "geojson"),
            especes: Ressources.donnees("especes"), longueurPoids: Ressources.donnees("longueur-poids"),
            stationsEspeces: fabrique("stations-especes.json"), rareteDepartements: fabrique("rarete-departements.json"),
            stationsHydro: Ressources.donnees("stations-hydro"), credits: Ressources.donnees("credits"),
            liensFederations: Ressources.donnees("liens-federations"), regles: .embarque(telechargees: reglesTelechargees))
    }
}

/// Tous les moteurs de `Core`, assemblés à partir des mêmes données. Chaque moteur remplit un contrat de `Contrats/`.
public struct MoteurCore: Sendable {
    public let geo: MoteurGeo
    public let regles: MoteurRegles
    public let especes: MoteurEspeces
    public let soleil: MoteurSoleil
    public let session: MoteurSession
    public let conditions: MoteurConditions
    public let niveauEau: HubEauNiveauService

    public init(donnees: DonneesMoteur, horloge: @escaping @Sendable () -> Date = { Date() },
                transportHubEau: @escaping HubEauNiveauService.Transport = HubEauNiveauService.transportReseau) {
        let stationsOFB = donnees.stationsEspeces.map(StationOFB.decoder) ?? []
        let listeEspeces = donnees.especes.map(EspecePechable.decoder) ?? []
        let geo = MoteurGeo(departementsGeoJSON: donnees.departements ?? Data(), lacsGeoJSON: donnees.lacs, regles: donnees.regles)
        let geoAvecStations = MoteurGeo(departements: geo.departements, lacs: geo.lacs, stations: stationsOFB, regles: donnees.regles)
        let soleil = MoteurSoleil()
        let regles = MoteurRegles(chargeur: donnees.regles, especes: listeEspeces, centresDepartements: geoAvecStations.centresDepartements(),
                                  credits: donnees.credits.map(MoteurCore.lireCredits) ?? [],
                                  liens: donnees.liensFederations.map(MoteurCore.lireLiens) ?? [:], soleil: soleil)
        let especes = MoteurEspeces(especes: listeEspeces, coefficients: donnees.longueurPoids.map(CoefficientPoids.decoder) ?? [],
                                    stations: stationsOFB, raretes: donnees.rareteDepartements.map(DonneesRarete.decoder) ?? .vide,
                                    regles: regles, geo: geoAvecStations, horloge: horloge)
        self.geo = geoAvecStations
        self.regles = regles
        self.especes = especes
        self.soleil = soleil
        self.session = MoteurSession(regles: regles, especes: especes)
        self.conditions = MoteurConditions(soleil: soleil, geo: geoAvecStations, stationsHydro: donnees.stationsHydro.map(StationHydroDonnee.decoder) ?? [],
                                           stationsOFB: stationsOFB, horloge: horloge)
        self.niveauEau = HubEauNiveauService(transport: transportHubEau, horloge: horloge)
    }

    /// `credits.json` : un tableau, ou un objet avec la clé `credits`. Clés lues : `nom` (ou `titre`), `url` (ou `lien`), `mention` (ou `licence`).
    static func lireCredits(_ donnees: Data) -> [Credit] {
        guard let json = try? JSONSerialization.jsonObject(with: donnees) else { return [] }
        let liste = (json as? [[String: Any]]) ?? ((json as? [String: Any])?["credits"] as? [[String: Any]]) ?? []
        return liste.compactMap { c in
            guard let nom = (c["nom"] as? String) ?? (c["titre"] as? String) else { return nil }
            return Credit(nom: nom, url: (c["url"] as? String) ?? (c["lien"] as? String), mention: (c["mention"] as? String) ?? (c["licence"] as? String))
        }
    }

    /// `liens-federations.json` : un objet par code de département, ou un tableau d'objets avec `departement`.
    /// Clés lues : `federation` (ou `site`, `site_federation`) et `carte` (ou `carte_de_peche`, `page_carte_de_peche`).
    static func lireLiens(_ donnees: Data) -> [String: LiensFederation] {
        guard let json = try? JSONSerialization.jsonObject(with: donnees) else { return [:] }
        func lien(_ o: [String: Any]) -> LiensFederation {
            LiensFederation(siteFederation: (o["federation"] as? String) ?? (o["site"] as? String) ?? (o["site_federation"] as? String),
                            pageCarteDePeche: (o["carte"] as? String) ?? (o["carte_de_peche"] as? String) ?? (o["page_carte_de_peche"] as? String))
        }
        var sortie: [String: LiensFederation] = [:]
        if let o = json as? [String: Any] {
            let source = (o["departements"] as? [String: Any]) ?? o
            for (code, v) in source { if let d = v as? [String: Any] { sortie[code] = lien(d) } }
        } else if let l = json as? [[String: Any]] {
            for d in l { if let code = (d["departement"] as? String) ?? (d["code"] as? String) { sortie[code] = lien(d) } }
        }
        return sortie
    }
}

// Les moteurs rendent les contrats de `Contrats/`.
extension MoteurCore {
    public var servicesGeo: any ServiceGeo { geo }
    public var servicesRegles: any ServiceRegles { regles }
    public var servicesEspeces: any ServiceEspeces { especes }
    public var servicesSoleil: any ServiceSoleil { soleil }
    public var servicesSession: any ServiceSession { session }
    public var servicesConditions: any ServiceConditions { conditions }
}
