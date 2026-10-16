import Foundation

/// Répartition des spots proposés (`docs/frequentation.md`, règles 1 à 4 et 7). L'app la lit par `(session as? any ServiceRepartition)`.
public protocol ServiceRepartition: Sendable {
    /// Un spot tiré parmi les 5 meilleures stations proches (graine propre à l'iPhone), adapté au niveau du pêcheur.
    func spotPropose(coordonnee: Coordonnee, date: Date, niveau: NiveauPecheur?, graine: UInt64) -> Spot?
    /// Id de la station OFB la plus proche du spot (5 km au plus), en attendant les vrais tronçons.
    func troncon(de spot: Spot) -> String?
    /// Un coin plus calme : même cours d'eau si possible, sinon à 15 km au plus ; `nil` si rien.
    func coinCalme(depuis spot: Spot, date: Date, niveau: NiveauPecheur?, estCharge: (String) -> Bool) -> Spot?
}

extension MoteurSession: ServiceRepartition {
    /// Nombre de stations les plus proches parmi lesquelles le spot est tiré (par défaut, à confirmer par Adem).
    public static let stationsRepartition = 5
    /// Rayon de recherche d'un débutant : 15 km.
    public static let rayonSpotDebutantM = 15_000.0
    /// Le tronçon d'un spot est la station OFB la plus proche, à 5 km au plus.
    public static let rayonTronconM = 5_000.0
    /// Un coin calme sur un autre cours d'eau se trouve à 15 km au plus.
    public static let rayonCoinCalmeM = 15_000.0

    /// Même graine, même spot. Sans candidate : l'ancien `spotPropose(coordonnee:date:)`.
    public func spotPropose(coordonnee: Coordonnee, date: Date, niveau: NiveauPecheur?, graine: UInt64) -> Spot? {
        let choix = Array(stationsEligibles(coordonnee: coordonnee, date: date, niveau: niveau).prefix(Self.stationsRepartition))
        guard !choix.isEmpty else { return spotPropose(coordonnee: coordonnee, date: date) }
        return spotDe(choix[Int(graine % UInt64(choix.count))].station)
    }

    public func troncon(de spot: Spot) -> String? {
        especes.stationsProches(spot.centre, rayonM: Self.rayonTronconM).first?.station.id
    }

    public func coinCalme(depuis spot: Spot, date: Date, niveau: NiveauPecheur?, estCharge: (String) -> Bool) -> Spot? {
        let actuelle = especes.stationsProches(spot.centre, rayonM: Self.rayonTronconM).first?.station
        let libres = stationsEligibles(coordonnee: spot.centre, date: date, niveau: niveau)
            .filter { $0.station.id != actuelle?.id && !estCharge($0.station.id) }
        func memeCours(_ s: StationBrute) -> Bool {
            guard let a = actuelle else { return false }
            if let c = a.codeEau, c == s.codeEau { return true }
            if let e = a.eau, e == s.eau { return true }
            return false
        }
        let choisie = libres.first { memeCours($0.station) } ?? libres.first { $0.distanceM <= Self.rayonCoinCalmeM }
        return choisie.map { spotDe($0.station) }
    }

    // MARK: Filtres communs

    private func spotDe(_ station: StationBrute) -> Spot {
        Spot(centre: station.coordonnee, rayonM: Self.rayonSpotGratuitM, departement: Departement(code: station.dep))
    }

    /// Stations éligibles, du plus proche au plus loin. La rareté ne classe jamais.
    func stationsEligibles(coordonnee: Coordonnee, date: Date, niveau: NiveauPecheur?)
        -> [(station: StationBrute, distanceM: Double)] {
        let debutant = niveau == .debutant
        let annee = Calendar.utcGregorien.component(.year, from: date)
        let rayon = debutant ? Self.rayonSpotDebutantM : Self.rayonSpotProposeM
        var liste = especes.stationsProches(coordonnee, rayonM: rayon).filter { s, _ in
            s.derniere >= annee - Self.fenetreReleveAnnees
                && especes.especesDeStations([s], date: date).contains { $0.ouverture == .ouverte }
        }
        if debutant {
            let robustes = liste.filter { especeDominanteCommune($0.station) }
            if !robustes.isEmpty { liste = robustes }
        }
        let sansReserve = liste.filter { !reserveSurLEau($0.station) }
        return sansReserve.isEmpty ? liste : sansReserve
    }

    /// L'espèce la plus vue de la station est-elle « commune » dans son département ?
    private func especeDominanteCommune(_ s: StationBrute) -> Bool {
        guard let code = s.vues.filter({ $0.value > 0 }).max(by: { ($0.value, $1.key) < ($1.value, $0.key) })?.key else { return false }
        let espece = especes.liste.first { $0.espece.codeSandre == code }?.espece ?? Espece(id: code, codeSandre: code)
        return especes.rarete(espece: espece, departement: Departement(code: s.dep)).niveau == .commun
    }

    /// Une règle `reserve` du fichier local vise-t-elle l'eau de la station ? Seules les réserves rattachées à un cours d'eau,
    /// un plan d'eau ou un tronçon comptent (comparaison par `cleEau`, ou par code de l'eau déclarée dans le fichier).
    private func reserveSurLEau(_ s: StationBrute) -> Bool {
        guard let fichier = regles.chargeur.fichier(s.dep) else { return false }
        let cleStation = s.eau.map(cleEau)
        return fichier.regles.contains { r in
            guard r.type == "reserve", ["cours_eau", "plan_eau", "troncon"].contains(r.portee?.niveau ?? ""),
                  let eau = r.portee?.eau, !eau.isEmpty else { return false }
            let k = cleEau(eau)
            if k == cleStation { return true }
            guard let declaree = fichier.eaux.first(where: { cleEau($0.cle) == k }) else { return false }
            if let c = declaree.code, c == s.codeEau { return true }
            return declaree.nom.map(cleEau) == cleStation && cleStation != nil
        }
    }
}
