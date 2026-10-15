import Foundation

/// Du point au `Lieu`, hors ligne : département par polygone, eau par lac ou station OFB, catégorie par les règles.
/// Aucun appel réseau, aucun géocodage d'Apple.
public struct MoteurGeo: ServiceGeo {
    /// À moins de cette distance d'une limite, le département d'en face compte aussi (par défaut, à confirmer par Adem).
    public static let distanceLimiteM = 500.0
    /// Rayon de recherche de la station OFB qui donne le cours d'eau (seuil à tester).
    public static let rayonEauM = 5_000.0
    /// Un lac proche de si peu est proposé dans `eauxProches`.
    static let rayonLacProposeM = 300.0

    let departements: [Contour]
    let lacs: [Contour]
    let stations: [StationBrute]
    let chargeur: ChargeurRegles?

    init(departements: [Contour], lacs: [Contour], stations: [StationBrute], regles: ChargeurRegles?) {
        self.departements = departements
        self.lacs = lacs
        self.stations = stations
        self.chargeur = regles
    }

    public init(departementsGeoJSON: Data, lacsGeoJSON: Data? = nil, stationsOFB: Data? = nil, regles: ChargeurRegles? = nil) {
        self.init(departements: Contour.decoder(departementsGeoJSON), lacs: lacsGeoJSON.map(Contour.decoder) ?? [],
                  stations: stationsOFB.map(StationBrute.decoder) ?? [], regles: regles)
    }

    /// Un point par département (centre de son contour), pour l'heure du soleil de `MoteurRegles`.
    public func centresDepartements() -> [String: Coordonnee] {
        var sortie: [String: Coordonnee] = [:]
        for d in departements { if let code = d.code, let c = d.centre { sortie[code] = c } }
        return sortie
    }

    // MARK: Contrat

    public func departement(de coordonnee: Coordonnee) -> Departement {
        for d in departements where d.contient(coordonnee) {
            if let code = d.code { return Departement(code: code) }
        }
        return .inconnu
    }

    func departementVoisin(de coordonnee: Coordonnee, dans actuel: Departement) -> Departement? {
        var meilleur: (Departement, Double)?
        for d in departements {
            guard let code = d.code, code != actuel.code else { continue }
            let dist = d.distanceAuBordM(coordonnee, rayonM: Self.distanceLimiteM)
            if dist <= Self.distanceLimiteM, dist < (meilleur?.1 ?? .infinity) { meilleur = (Departement(code: code), dist) }
        }
        return meilleur?.0
    }

    public func lieu(de coordonnee: Coordonnee, choix: ChoixLieu?) -> Lieu {
        let dep = departement(de: coordonnee)
        if dep.estInconnu { return .inconnu }
        let voisin = departementVoisin(de: coordonnee, dans: dep)
        let eau = choix?.eau ?? eauAutomatique(coordonnee)
        let categorie: CategorieEau
        if let c = choix?.categorie {
            categorie = CategorieEau(valeur: c, origine: .choixDuPecheur)
        } else {
            categorie = categorieDeLEau(dep: dep, eau: eau)
        }
        return Lieu(departement: dep, departementVoisin: voisin, eau: eau, categorie: categorie,
                    tronconsConfirmes: choix?.tronconsConfirmes ?? [])
    }

    /// Un lieu à partir d'une station OFB (son département est déjà rangé par D2).
    func lieu(station: StationBrute) -> Lieu {
        let dep = Departement(code: station.dep)
        let eau = station.eau.map { Eau(nom: $0, cle: cleEau($0), codeSandre: station.codeEau, type: .riviere) }
        return Lieu(departement: dep, eau: eau, categorie: categorieDeLEau(dep: dep, eau: eau))
    }

    public func eauxProches(_ coordonnee: Coordonnee) -> [Eau] {
        var sortie: [Eau] = []
        func ajouter(_ e: Eau) { if !sortie.contains(where: { $0.cle == e.cle }) { sortie.append(e) } }
        for lac in lacs {
            if lac.contient(coordonnee) || lac.distanceAuBordM(coordonnee, rayonM: Self.rayonLacProposeM) <= Self.rayonLacProposeM {
                ajouter(eau(deLac: lac))
            }
        }
        let proches = stations.compactMap { s -> (StationBrute, Double)? in
            guard s.eau != nil else { return nil }
            let d = Geodesie.distanceM(coordonnee, s.coordonnee)
            return d <= Self.rayonEauM ? (s, d) : nil
        }.sorted { $0.1 < $1.1 }
        for (s, _) in proches {
            if let nom = s.eau { ajouter(Eau(nom: nom, cle: cleEau(nom), codeSandre: s.codeEau, type: .riviere)) }
        }
        return sortie
    }

    public func lieuFlou(_ coordonnee: Coordonnee) -> String {
        let l = lieu(de: coordonnee, choix: nil)
        if l.departement.estInconnu { return "Hors de France" }
        guard let eau = l.eau else { return "Département \(l.departement.code)" }
        return "\(eau.nom) · \(l.departement.code)"
    }

    // MARK: Eau et catégorie

    private func eau(deLac lac: Contour) -> Eau {
        let nom = lac.nom ?? "Plan d'eau"
        return Eau(nom: nom, cle: cleEau(nom), codeSandre: lac.proprietes["code_sandre"] ?? lac.proprietes["code"], type: .lac)
    }

    private func eauAutomatique(_ p: Coordonnee) -> Eau? {
        if let lac = lacs.first(where: { $0.contient(p) }) { return eau(deLac: lac) }
        var meilleure: (StationBrute, Double)?
        for s in stations where s.eau != nil {
            let d = Geodesie.distanceM(p, s.coordonnee)
            if d <= Self.rayonEauM, d < (meilleure?.1 ?? .infinity) { meilleure = (s, d) }
        }
        guard let (s, _) = meilleure, let nom = s.eau else { return nil }
        return Eau(nom: nom, cle: cleEau(nom), codeSandre: s.codeEau, type: .riviere)
    }

    /// Le premier qui répond gagne : une règle `categorie` qui vise l'eau entière, puis la règle de reste du département
    /// (seulement si aucune règle de 1re catégorie ne nomme cette eau), sinon inconnue. Le choix du pêcheur passe avant, dans `lieu(de:choix:)`.
    func categorieDeLEau(dep: Departement, eau: Eau?) -> CategorieEau {
        guard let f = chargeur?.fichier(dep.code) else { return .inconnue }
        let regles = f.regles.filter { $0.type == "categorie" }
        func classe(_ r: RegleDonnee) -> Categorie {
            switch r.valeur["classe"]?.texte ?? r.categorie {
            case "1": return .premiere
            case "2": return .deuxieme
            default: return .inconnue
            }
        }
        func vise(_ r: RegleDonnee) -> Bool {
            guard let eau, let cle = r.portee?.eau else { return false }
            let k = cleEau(cle)
            if k == cleEau(eau.cle) || k == cleEau(eau.nom) { return true }
            if let code = eau.codeSandre, let e = f.eaux.first(where: { cleEau($0.cle) == k }), e.code == code { return true }
            return false
        }
        if eau != nil {
            if let r = regles.first(where: { ["cours_eau", "plan_eau"].contains($0.portee?.niveau ?? "") && vise($0) }), classe(r) != .inconnue {
                return CategorieEau(valeur: classe(r), origine: .regleDeLEau)
            }
            if regles.contains(where: { classe($0) == .premiere && vise($0) }) { return .inconnue }
        }
        if let r = regles.first(where: { ($0.portee?.niveau ?? "departement") == "departement" && $0.portee?.eau == nil }), classe(r) != .inconnue {
            return CategorieEau(valeur: classe(r), origine: .regleDeReste)
        }
        return .inconnue
    }
}
