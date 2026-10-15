import Foundation

/// Quota du jour, accès gratuit, fonctions Pro, offre affichée, spot proposé.
public struct MoteurSession: ServiceSession {
    /// Le spot gratuit est un cercle de 1 km.
    public static let rayonSpotGratuitM = 1_000.0
    /// Un spot proposé se trouve à 30 km au plus.
    public static let rayonSpotProposeM = 30_000.0
    /// Fenêtre des relevés « récents » pour un spot proposé (par défaut, à confirmer par Adem).
    public static let fenetreReleveAnnees = 10
    /// Prix de lancement jusqu'au 31 décembre 2026 inclus (tarif fondateur), 49,99 ensuite.
    public static let finTarifFondateur = dateAAAAMMJJ("2027-01-01")!
    public static let produitFondateur = "ai.mwm.build.challenge.team.01.yearly.00.ft.34.99"
    public static let produitStandard = "ai.mwm.build.challenge.team.01.yearly.00.ft.49.99"
    public static let messageHorsDeFrance = "hors de France : aucune règle française"

    let regles: MoteurRegles
    let especes: MoteurEspeces

    init(regles: MoteurRegles, especes: MoteurEspeces) {
        self.regles = regles
        self.especes = especes
    }

    // MARK: Quota

    public func quota(prisesGardeesDuJour: [Prise], departement: Departement) -> QuotaDuJour {
        let gardees = prisesGardeesDuJour.filter { $0.gardee && !$0.estDeclaree && !$0.exemple }
        let nat = regles.chargeur.fichier("national")
        let loc = regles.chargeur.fichier(departement.code)
        struct Candidate { var regle: RegleDonnee; var fichier: FichierRegles; var local: Bool }
        func candidates(_ f: FichierRegles?, local: Bool) -> [Candidate] {
            (f?.regles ?? []).compactMap { r in
                guard r.type == "quota_jour", r.categorie != "1", (r.valeur["total"]?.nombre ?? r.valeur["nombre"]?.nombre) != nil else { return nil }
                let niveau = r.portee?.niveau ?? (local ? "departement" : "national")
                guard niveau == "national" || niveau == "departement" else { return nil }
                return Candidate(regle: r, fichier: f!, local: local)
            }
        }
        var toutes = candidates(loc, local: true) + candidates(nat, local: false)
        let remplacees = Set(toutes.compactMap { $0.regle.remplace })
        toutes = toutes.filter { !remplacees.contains($0.regle.id) }
        if toutes.contains(where: { $0.local }) { toutes = toutes.filter { $0.local } }

        func compte(_ c: Candidate) -> Int {
            gardees.filter { vise(c.regle.especes, regles.completer($0.espece)) }.count
        }
        let choisie = toutes.max { a, b in
            let ca = compte(a), cb = compte(b)
            if ca != cb { return ca < cb }
            if a.regle.especes.count != b.regle.especes.count { return (a.regle.especes.isEmpty ? Int.max : a.regle.especes.count) < (b.regle.especes.isEmpty ? Int.max : b.regle.especes.count) }
            return (a.regle.valeur["total"]?.nombre ?? a.regle.valeur["nombre"]?.nombre ?? 0) > (b.regle.valeur["total"]?.nombre ?? b.regle.valeur["nombre"]?.nombre ?? 0)
        }
        guard let c = choisie, let total = c.regle.valeur["total"]?.nombre ?? c.regle.valeur["nombre"]?.nombre else {
            return QuotaDuJour(gardees: gardees.count, plafond: nil)
        }
        let texte = c.regle.textes.first.flatMap { c.fichier.textes[$0] }
        let source = texte.map { SourceRegle(titre: $0.titre ?? c.regle.id, url: $0.url) } ?? c.regle.source.map { SourceRegle(titre: $0.texte ?? "Source", url: $0.url) }
        return QuotaDuJour(gardees: compte(c), plafond: Int(total), source: source)
    }

    private func vise(_ liste: [String], _ e: Espece) -> Bool {
        liste.isEmpty || liste.contains { $0 == e.id || (e.codeSandre != nil && $0 == e.codeSandre) }
    }

    // MARK: Accès

    public func acces(sessionsTerminees: Int, spot: Spot, spotGratuit: Spot?, abonne: Bool) -> DecisionAcces {
        let message = spot.departement.estInconnu ? Self.messageHorsDeFrance : nil
        if abonne { return DecisionAcces(sessionPermise: true, paywall: .aucun, spotGratuit: spotGratuit, message: message) }
        guard let gratuit = spotGratuit else {
            // La 1re session est toujours permise, et son lieu devient le spot gratuit (cercle de 1 km).
            var fixe = spot
            fixe.rayonM = Self.rayonSpotGratuitM
            return DecisionAcces(sessionPermise: true, paywall: .aucun, spotGratuit: fixe, message: message)
        }
        if surSpot(spot.centre, gratuit) {
            return DecisionAcces(sessionPermise: true, paywall: sessionsTerminees == 1 ? .quiSeFerme : .aucun, spotGratuit: gratuit, message: message)
        }
        return DecisionAcces(sessionPermise: false, paywall: .quiBloque, spotGratuit: gratuit, message: message)
    }

    /// « Dans le spot » : à moins de 1 km du centre du spot gratuit.
    func surSpot(_ c: Coordonnee, _ gratuit: Spot) -> Bool {
        Geodesie.distanceM(c, gratuit.centre) <= Self.rayonSpotGratuitM
    }

    public func peutUtiliser(_ fonction: FonctionPro, abonne: Bool, surSonSpot: Bool) -> Bool {
        if abonne { return true }
        switch fonction {
        case .meteoDuJour, .niveauEau: return surSonSpot
        case .septJours, .prevenirMoi, .courbeEtNormale, .conseilsComplets, .analyseConditions: return false
        }
    }

    public func offreAffichee(date: Date) -> OffreAffichee {
        if date < Self.finTarifFondateur { return OffreAffichee(produit: Self.produitFondateur, prixCentimes: 3499, tarifFondateur: true) }
        return OffreAffichee(produit: Self.produitStandard, prixCentimes: 4999, tarifFondateur: false)
    }

    // MARK: Spot proposé

    public func spotPropose(coordonnee: Coordonnee, date: Date) -> Spot? {
        let annee = Calendar.utcGregorien.component(.year, from: date)
        for (station, _) in especes.stationsProches(coordonnee, rayonM: Self.rayonSpotProposeM) {
            guard station.derniere >= annee - Self.fenetreReleveAnnees else { continue }
            let vues = especes.especesDeStations([station], date: date)
            if vues.contains(where: { $0.ouverture == .ouverte }) {
                return Spot(centre: station.coordonnee, rayonM: Self.rayonSpotGratuitM, departement: Departement(code: station.dep))
            }
        }
        return nil
    }
}
