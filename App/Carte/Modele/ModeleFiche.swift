import Foundation
import Observation
import Core

/// Une espèce relevée près d'un coin, prête à afficher : l'image, la rareté de `Core`, « N pêches, dernier relevé AAAA ».
nonisolated struct LigneEspece: Sendable, Equatable, Identifiable {
    var espece: Espece
    var nPeches: Int
    var annee: Int
    var ouverture: OuvertureDuJour?
    var rarete: ResultatRarete?
    /// Faux pour la truite fario proposée en 1re catégorie sans relevé : nPeches et annee ne valent alors rien.
    var releve: Bool = true
    /// La taille minimale lue dans la règle de `Core` (« 50 »), `nil` si aucune phrase ne la donne.
    var tailleMiniCm: String? = nil
    var id: String { espece.id }
}

/// Ce que dit le bandeau de couverture, lu dans `departementsCouverts()` (jamais une liste écrite).
nonisolated enum CouvertureLocale: Sendable, Equatable {
    case complete
    /// « règles locales en partie » et le lien.
    case partielle(lien: String?)
    /// « règles locales non saisies » et le lien : le socle national seul s'applique.
    case nonSaisie(lien: String?)
}

nonisolated struct FicheCalculee: Sendable {
    var lieu: Lieu
    var lieuFlou: String
    var eaux: [Eau]
    var especes: [LigneEspece]
    var lignes: [LigneControle]
    var couverture: CouvertureLocale
}

/// Tout vient de `Core` ; rien n'est calculé ici.
@concurrent nonisolated func calculerFiche(services: ServicesCarte, coordonnee: Coordonnee, choix: ChoixLieu?, espece: Espece?, date: Date) async -> FicheCalculee {
    let lieu = services.geo.lieu(de: coordonnee, choix: choix)
    let proches = services.especes.especesProches(coordonnee)
    let especes = proches.map { p in
        LigneEspece(espece: p.espece, nPeches: p.nPeches, annee: p.annee, ouverture: p.ouverture,
                    rarete: services.especes.rarete(espece: p.espece, departement: lieu.departement))
    }
    // Les espèces ouvertes aujourd'hui d'abord (ordre gardé sinon), puis la taille minimale des 3 montrées sur la fiche.
    let completees = TruiteEnPremiere.completer(especes, categorie: lieu.categorie.valeur)
    let ouvertesDAbord = completees.enumerated().sorted { a, b in
        let oa = a.element.ouverture?.estOuverte ?? false
        let ob = b.element.ouverture?.estOuverte ?? false
        return oa != ob ? oa : a.offset < b.offset
    }.map(\.element)
    let especesAffichees = ouvertesDAbord.enumerated().map { i, ligne -> LigneEspece in
        guard i < 3 else { return ligne }
        var avecTaille = ligne
        let taille = services.regles.controle(espece: ligne.espece, tailleCm: nil, mesure: nil, date: date, lieu: lieu, prisesDuJour: [])
            .lignes.first { $0.type == .taille }
        avecTaille.tailleMiniCm = taille.flatMap { LectureRegle.nombre(avant: "cm", dans: $0.phrase) }
        return avecTaille
    }
    let lignes: [LigneControle]
    if let espece {
        lignes = OrdreRegles.trier(services.regles.controle(espece: espece, tailleCm: nil, mesure: nil, date: date, lieu: lieu, prisesDuJour: []).lignes)
    } else {
        lignes = OrdreRegles.trier(services.regles.reglesDuJour(lieu: lieu, date: date))
    }
    let couvert = services.regles.departementsCouverts().first { $0.departement == lieu.departement }
    let lien = services.regles.liensFederation(departement: lieu.departement).siteFederation
    let couverture: CouvertureLocale
    switch couvert?.niveau {
    case .complet: couverture = .complete
    case .partiel: couverture = .partielle(lien: lien)
    case nil: couverture = .nonSaisie(lien: lien)
    }
    return FicheCalculee(lieu: lieu, lieuFlou: services.geo.lieuFlou(coordonnee), eaux: services.geo.eauxProches(coordonnee),
                         especes: especesAffichees, lignes: lignes, couverture: couverture)
}

/// Le choix de l'eau, de la catégorie et des tronçons confirmés : gardé dans le spot, sur l'iPhone seulement.
nonisolated enum StockageChoixLieu {
    static func cle(_ id: String) -> String { "carte.choixLieu.\(id)" }

    static func lire(_ id: String, reglages: UserDefaults = .standard) -> ChoixLieu? {
        guard let donnees = reglages.data(forKey: cle(id)) else { return nil }
        return try? JSONDecoder().decode(ChoixLieu.self, from: donnees)
    }

    static func ecrire(_ choix: ChoixLieu, id: String, reglages: UserDefaults = .standard) {
        if let donnees = try? JSONEncoder().encode(choix) { reglages.set(donnees, forKey: cle(id)) }
    }
}

@MainActor
@Observable
final class ModeleFiche {
    let services: ServicesCarte
    let selection: CoinSelectionne
    let date: Date

    private(set) var fiche: FicheCalculee?
    var choix: ChoixLieu
    var especeTouchee: Espece?
    private(set) var pechables: [String: EspecePechable]

    init(services: ServicesCarte, selection: CoinSelectionne, pechables: [EspecePechable], date: Date = Date()) {
        self.services = services
        self.selection = selection
        self.date = date
        self.choix = StockageChoixLieu.lire(selection.id) ?? ChoixLieu()
        self.pechables = Dictionary(pechables.map { ($0.espece.id, $0) }, uniquingKeysWith: { premier, _ in premier })
    }

    func charger() async {
        fiche = await calculerFiche(services: services, coordonnee: selection.coordonnee, choix: choix, espece: especeTouchee, date: date)
    }

    func nom(_ espece: Espece) -> String { pechables[espece.id]?.nom ?? espece.id }
    func image(_ espece: Espece) -> String? { pechables[espece.id]?.image }

    // MARK: Choix du pêcheur, gardés dans le spot

    func choisirEau(_ eau: Eau) async {
        choix.eau = eau
        await enregistrerEtRecharger()
    }

    /// `nil` : « je ne sais pas ».
    func choisirCategorie(_ categorie: Categorie?) async {
        choix.categorie = categorie
        await enregistrerEtRecharger()
    }

    /// « j'y suis ? » : un toucher applique le tronçon au spot.
    func confirmerTroncon(_ libelle: String) async {
        if !choix.tronconsConfirmes.contains(libelle) { choix.tronconsConfirmes.append(libelle) }
        await enregistrerEtRecharger()
    }

    func toucherEspece(_ espece: Espece) async {
        especeTouchee = (especeTouchee == espece) ? nil : espece
        await charger()
    }

    private func enregistrerEtRecharger() async {
        StockageChoixLieu.ecrire(choix, id: selection.id)
        await charger()
    }

    /// Eaux à proposer : celles de `eauxProches`, puis « un plan d'eau » et « autre ».
    static let planDEau = Eau(nom: "un plan d'eau", cle: "plan-d-eau", type: .lac)
    static let autreEau = Eau(nom: "autre", cle: "autre", type: .autre)
}
