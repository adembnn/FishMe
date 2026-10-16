import Foundation
import Core

// La couche « spots d'eau » du modèle de la carte : cours d'eau (hors ligne), coins publics, plans d'eau (MapKit, en ligne).
// Les propriétés vivent dans `ModeleCarte` (une extension ne peut pas en avoir) ; la logique est ici.

extension ModeleCarte {
    /// Nombre de plans d'eau gardés d'une vue à l'autre : le pêcheur qui revient en arrière les retrouve sans nouvelle recherche.
    static let plansDEauGardes = 500
    /// Délai avant de lancer la recherche en ligne : un geste continu n'en déclenche qu'une.
    static let delaiRechercheEau: Duration = .milliseconds(500)

    /// Lit les cours d'eau du fichier embarqué (une seule fois) puis dessine la couche.
    func chargerCoursDEau() async {
        let fournisseur = services.spotsEau
        let lus = await fournisseur.coursDEau()
        if Task.isCancelled { return }
        coursDEau = lus
        recalculerEau(regionVisible)
    }

    /// Un « fin de mouvement » dans les secondes qui suivent vient du code, pas du doigt.
    func marquerDeplacementProgramme(duree: TimeInterval = 2.5) {
        finDeplacementProgramme = Date().addingTimeInterval(duree)
    }

    /// Dessine l'eau de la zone visible. Rien tant qu'un filtre d'espèce est actif : une épingle d'eau n'a pas d'espèce relevée.
    func recalculerEau(_ region: ZoneCarte) {
        tacheEau?.cancel()
        guard filtre == nil else {
            if !elementsEau.isEmpty { elementsEau = [] }
            spotsEauAffiches = [:]
            return
        }
        let fournisseur = services.spotsEau
        let cours = coursDEau
        let enLigne = lieuxEnLigne
        tacheEau = Task {
            let publics = await fournisseur.lieuxPublics(dans: region)
            if Task.isCancelled { return }
            lieuxPublics = publics
            let couche = await calculerCoucheEau(spots: cours + publics + enLigne, region: region)
            if Task.isCancelled { return }
            elementsEau = couche.elements
            spotsEauAffiches = couche.spots
        }
    }

    /// La recherche MapKit part seulement après un geste du pêcheur, jamais pour l'affichage initial ni pour un déplacement du code.
    func declencherRechercheEnLigne(_ region: ZoneCarte, affichageInitial: Bool) {
        if affichageInitial { return }
        if !rechercheEnLigneAutorisee {
            if Date() < finDeplacementProgramme { return }
            rechercheEnLigneAutorisee = true
        }
        guard filtre == nil else { return }
        tacheRechercheEau?.cancel()
        let fournisseur = services.spotsEau
        tacheRechercheEau = Task {
            try? await Task.sleep(for: Self.delaiRechercheEau)
            if Task.isCancelled { return }
            let trouves = await fournisseur.plansDEau(dans: region)
            if Task.isCancelled || trouves.isEmpty { return }
            fusionnerEnLigne(trouves)
            recalculerEau(regionVisible)
        }
    }

    private func fusionnerEnLigne(_ nouveaux: [SpotEau]) {
        for s in nouveaux where idsEnLigne.insert(s.id).inserted {
            lieuxEnLigne.append(s)
        }
        let trop = lieuxEnLigne.count - Self.plansDEauGardes
        if trop > 0 {
            for s in lieuxEnLigne.prefix(trop) { idsEnLigne.remove(s.id) }
            lieuxEnLigne.removeFirst(trop)
        }
    }

    // MARK: Toucher

    /// Vrai juste après un toucher sur une épingle d'eau : le toucher de la carte, qui pose aussi le cercle, doit alors se taire.
    var toucherEauRecent: Bool {
        Date().timeIntervalSince(instantToucherEau) < 0.4
    }

    /// Un toucher sur une épingle d'eau pose le cercle de 1 km au même endroit. Rend le spot pour que A le garde.
    /// Quand le spot est déjà fixé (après la 1re session), l'épingle ouvre seulement sa fiche.
    func toucherEau(_ spot: SpotEau) -> Spot? {
        instantToucherEau = Date()
        if peutChangerDeSpot {
            guard let pose = poserSpot(en: spot.coordonnee) else { return nil }
            spotEauChoisi = spot
            return pose
        }
        let departement = services.geo.departement(de: spot.coordonnee)
        selection = CoinSelectionne(id: spot.id, coordonnee: spot.coordonnee, eau: spot.nom,
                                    departement: departement.estInconnu ? nil : departement, coin: nil)
        return nil
    }

    /// Un regroupement d'eau : la carte zoome dessus, comme pour les stations.
    func zoomerSurGroupeEau(_ element: ElementCarte) {
        instantToucherEau = Date()
        guard case .groupe(_, let c, _) = element else { return }
        rechercheEnLigneAutorisee = true
        centrer(Regroupeur.zoom(sur: c, depuis: regionVisible))
    }
}
