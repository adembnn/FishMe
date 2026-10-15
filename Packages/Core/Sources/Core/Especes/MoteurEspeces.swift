import Foundation

/// Un coefficient de la relation longueur-poids W = a × L^b (`longueur-poids.json`, W en grammes, L longueur totale en cm).
struct CoefficientPoids: Sendable, Equatable {
    var espece: String
    var a: Double
    var b: Double
    var ltMinCm: Double
    var ltMaxCm: Double
    var n: Int?
    var region: String?
    var source: String

    static func decoder(_ donnees: Data) -> [CoefficientPoids] {
        guard let json = try? JSONSerialization.jsonObject(with: donnees) else { return [] }
        let liste: [[String: Any]]
        if let l = json as? [[String: Any]] { liste = l } else if let o = json as? [String: Any], let l = (o["especes"] ?? o["coefficients"]) as? [[String: Any]] { liste = l } else { return [] }
        return liste.compactMap { e in
            guard let id = (e["espece"] as? String) ?? (e["id"] as? String),
                  let a = (e["a"] as? NSNumber)?.doubleValue, let b = (e["b"] as? NSNumber)?.doubleValue,
                  let mn = (e["lt_min_cm"] as? NSNumber)?.doubleValue, let mx = (e["lt_max_cm"] as? NSNumber)?.doubleValue else { return nil }
            return CoefficientPoids(espece: id, a: a, b: b, ltMinCm: mn, ltMaxCm: mx, n: (e["n"] as? NSNumber)?.intValue,
                                    region: e["region"] as? String, source: (e["source"] as? String) ?? "source non indiquée")
        }
    }
}

extension EspecePechable {
    /// Lit `especes.json` (un tableau, ou un objet avec la clé `especes`). Une entrée illisible est sautée.
    static func decoder(_ donnees: Data) -> [EspecePechable] {
        guard let json = try? JSONSerialization.jsonObject(with: donnees) else { return [] }
        let liste: [[String: Any]]
        if let l = json as? [[String: Any]] { liste = l } else if let o = json as? [String: Any], let l = o["especes"] as? [[String: Any]] { liste = l } else { return [] }
        func sandre(_ v: Any?) -> String? { (v as? String) ?? (v as? NSNumber)?.stringValue }
        let codes: [String: String] = Dictionary(liste.compactMap { e in
            guard let id = e["id"] as? String, let c = sandre(e["code_sandre"]) else { return nil }
            return (id, c)
        }, uniquingKeysWith: { a, _ in a })
        return liste.compactMap { e in
            guard let id = e["id"] as? String, let nom = e["nom"] as? String else { return nil }
            var statuts: Set<StatutEspece> = []
            let bruts: [String] = (e["statut"] as? [String]) ?? (e["statut"] as? String).map { [$0] } ?? []
            for s in bruts {
                switch s {
                case "protegee": statuts.insert(.protegee)
                case "envahissante": statuts.insert(.envahissante)
                case "stade_a_demander": statuts.insert(.stadeADemander)
                case "toujours_relachee": statuts.insert(.toujoursRelachee)
                default: break
                }
            }
            let confusions: [Confusion] = ((e["confusions"] as? [[String: Any]]) ?? []).compactMap { c in
                guard let avec = c["avec"] as? String else { return nil }
                return Confusion(avec: Espece(id: avec, codeSandre: codes[avec]), critere: (c["critere"] as? String) ?? "",
                                 source: (c["source"] as? String) ?? "")
            }
            return EspecePechable(espece: Espece(id: id, codeSandre: codes[id]), nom: nom,
                                  nomLatin: (e["latin"] as? String) ?? (e["nom_latin"] as? String) ?? "",
                                  classeModele: e["classe_modele"] as? String, image: (e["image"] as? String) ?? id,
                                  statuts: statuts, confusions: confusions, suiviOFB: (e["suivi_ofb"] as? Bool) ?? true)
        }
    }
}

/// Espèces : liste, rareté, espèces d'un coin, reconnaissance, poids.
public struct MoteurEspeces: ServiceEspeces {
    /// Rayons successifs de recherche des stations OFB autour d'un coin : 10 km, puis 20, puis 30 s'il y en a moins de 2.
    public static let rayonsM: [Double] = [10_000, 20_000, 30_000]
    public static let stationsMinimum = 2
    /// Facteur d'une classe jamais relevée près du coin (par défaut, à confirmer par Adem ; R1 peut mesurer une autre valeur).
    public static let plancherAPriori = 0.3
    public static let nombreDePropositions = 3
    /// Fourchette de poids de part et d'autre (par défaut, à confirmer par Adem).
    public static let fourchettePoids = 0.2
    /// Nombre maximal de coins rendus par `coins(ou:pres:)`.
    public static let coinsMaximum = 200
    static let classesExclues: Set<String> = ["autre poisson", "pas un poisson"]

    let liste: [EspecePechable]
    let coefficients: [CoefficientPoids]
    let stations: [StationOFB]
    let raretes: DonneesRarete
    let regles: MoteurRegles
    let geo: MoteurGeo
    let horloge: @Sendable () -> Date

    init(especes: [EspecePechable], coefficients: [CoefficientPoids], stations: [StationOFB], raretes: DonneesRarete,
         regles: MoteurRegles, geo: MoteurGeo, horloge: @escaping @Sendable () -> Date = { Date() }) {
        self.liste = especes
        self.coefficients = coefficients
        self.stations = stations
        self.raretes = raretes
        self.regles = regles
        self.geo = geo
        self.horloge = horloge
    }

    // MARK: Liste et rareté

    public func especesPechables() -> [EspecePechable] { liste }

    private func entree(_ e: Espece) -> EspecePechable? { liste.first { $0.espece.id == e.id } }

    private func codeSandre(_ e: Espece) -> String? { e.codeSandre ?? entree(e)?.espece.codeSandre }

    public func rarete(espece: Espece, departement: Departement) -> ResultatRarete {
        CalculRarete.calculer(code: codeSandre(espece), suiviOFB: entree(espece)?.suiviOFB ?? true, departement: departement, donnees: raretes)
    }

    // MARK: Stations proches

    func stationsProches(_ c: Coordonnee, rayonM: Double) -> [(station: StationOFB, distanceM: Double)] {
        let dLat = rayonM / 111_000 + 0.01
        return stations.compactMap { s in
            if abs(s.coordonnee.latitude - c.latitude) > dLat { return nil }
            let d = Geodesie.distanceM(c, s.coordonnee)
            return d <= rayonM ? (s, d) : nil
        }.sorted { $0.1 < $1.1 }
    }

    /// Les stations du premier rayon qui en compte assez ; à défaut, tout ce qui se trouve à moins de 30 km.
    private func stationsDuCoin(_ c: Coordonnee) -> [StationOFB] {
        for r in Self.rayonsM {
            let s = stationsProches(c, rayonM: r)
            if s.count >= Self.stationsMinimum { return s.map(\.station) }
        }
        return stationsProches(c, rayonM: Self.rayonsM.last ?? 30_000).map(\.station)
    }

    private func especeDuCode(_ code: String) -> Espece? { liste.first { $0.espece.codeSandre == code }?.espece }

    func especesDeStations(_ stations: [StationOFB], date: Date) -> [EspeceProche] {
        var parEspece: [String: (n: Int, annee: Int, station: StationOFB)] = [:]
        for s in stations {
            for (code, n) in s.vues where n > 0 {
                let courant = parEspece[code]
                parEspece[code] = ((courant?.n ?? 0) + n, max(courant?.annee ?? 0, s.derniere), courant?.station ?? s)
            }
        }
        let premiere = stations.first
        return parEspece.compactMap { code, v -> EspeceProche? in
            guard let esp = especeDuCode(code) else { return nil }
            let lieu = geo.lieu(station: premiere ?? v.station)
            return EspeceProche(espece: esp, nPeches: v.n, annee: v.annee, ouverture: regles.ouverture(espece: esp, lieu: lieu, date: date))
        }.sorted { ($0.nPeches, $1.espece.id) > ($1.nPeches, $0.espece.id) }
    }

    public func especesProches(_ coordonnee: Coordonnee) -> [EspeceProche] {
        especesDeStations(stationsDuCoin(coordonnee), date: horloge())
    }

    public func coins(ou espece: Espece, pres coordonnee: Coordonnee) -> [Coin] {
        guard let code = codeSandre(espece) else { return [] }
        let date = horloge()
        let candidats = stations.filter { ($0.vues[code] ?? 0) > 0 }
        let tries = candidats.map { ($0, Geodesie.distanceM(coordonnee, $0.coordonnee)) }.sorted { $0.1 < $1.1 }.prefix(Self.coinsMaximum)
        return tries.map { s, d in
            let lieu = geo.lieu(station: s)
            return Coin(codeStation: s.id, eau: s.eau, departement: Departement(code: s.dep), coordonnee: s.coordonnee, distanceM: d,
                        nPeches: s.vues[code] ?? 0, annee: s.derniere, ouverture: regles.ouverture(espece: espece, lieu: lieu, date: date))
        }
    }

    // MARK: Reconnaissance

    private static func normaliser(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
            .replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    public func classer(scores: [String: Double], especesProches: [Espece]) -> [Proposition] {
        let relevees = Set(especesProches.compactMap { entree($0)?.classeModele })
        var classes: [String: [EspecePechable]] = [:]
        for e in liste { if let c = e.classeModele { classes[c, default: []].append(e) } }
        struct Candidat { var classe: String; var note: Double; var relevee: Bool }
        let candidats: [Candidat] = scores.compactMap { classe, score in
            guard !Self.classesExclues.contains(Self.normaliser(classe)), classes[classe] != nil else { return nil }
            let relevee = relevees.contains(classe)
            return Candidat(classe: classe, note: score * (relevee ? 1 : Self.plancherAPriori), relevee: relevee)
        }.sorted {
            if $0.note != $1.note { return $0.note > $1.note }
            if $0.relevee != $1.relevee { return $0.relevee }
            return $0.classe < $1.classe
        }
        var propositions: [Proposition] = candidats.prefix(Self.nombreDePropositions).map { c in
            let membres = classes[c.classe] ?? []
            if membres.count == 1, let e = membres.first { return Proposition(type: .espece(e.espece)) }
            return Proposition(type: .classe(c.classe))
        }
        propositions.append(Proposition(type: .autreEspece))
        propositions.append(Proposition(type: .pasUnPoisson))
        return propositions
    }

    // MARK: Poids

    public func poidsEstime(espece: Espece, longueurCm: Double) -> PoidsEstime? {
        guard let c = coefficients.first(where: { $0.espece == espece.id }),
              longueurCm >= c.ltMinCm, longueurCm <= c.ltMaxCm, longueurCm > 0 else { return nil }
        let kilos = c.a * pow(longueurCm, c.b) / 1000
        var source = c.source
        let details = [c.region, c.n.map { "n = \($0)" }].compactMap { $0 }
        if !details.isEmpty { source += " (\(details.joined(separator: ", ")))" }
        return PoidsEstime(kilos: kilos.arrondi(3), minKilos: (kilos * (1 - Self.fourchettePoids)).arrondi(3),
                           maxKilos: (kilos * (1 + Self.fourchettePoids)).arrondi(3), source: source)
    }
}
