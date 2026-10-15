import Core
import Foundation
import Observation

// Logique de « Choisir un autre spot » (E3, lot L7). Tout vient de Core : ici on ne calcule ni distance de saison,
// ni rareté, ni consigne. On met seulement en phrases ce que Core rend.

/// Un coin prêt à être affiché : des textes déjà composés, rien d'autre.
nonisolated struct CoinAffiche: Identifiable, Equatable {
    let id: String
    /// Nom du coin public (OpenStreetMap), à défaut son genre : « Ponton », « Accès à l'eau », « Coin de pêche ».
    let titre: String
    let distance: String
    /// « 9 pêches, dernier relevé 2024 »
    let releve: String
    /// « Ouverte aujourd'hui » ou « Fermée jusqu'au 15 mars »
    let ouverture: String
    let estOuvert: Bool
    /// « Accès libre », « Sur permis », « Accès payant » ; `nil` quand OpenStreetMap ne le dit pas.
    let acces: String?
    /// « Station OFB à proximité : La Marne, à 450 m » : d'où viennent le nombre de pêches et l'année.
    let station: String
    /// Phrase lue par VoiceOver, d'un seul tenant.
    let phraseVoixOff: String
}

nonisolated enum OuChercherTextes {
    static let sansRelevePres = "Aucun relevé OFB à proximité"
    static let explicationOrdre = "Du plus proche au plus loin. Relevée à proximité : la station OFB est un point de mesure, pas toujours un accès public."
    static let creditOSM = "© contributeurs OpenStreetMap"
    static let titreEcran = "Choisir un autre spot"
    static let invite = "Quel poisson cherches-tu ?"
}

/// Composition des phrases d'un coin. Pure, testable sans écran.
nonisolated struct CompositeurCoins {
    var locale = Locale(identifier: "fr_FR")
    var fuseau = TimeZone(identifier: "Europe/Paris") ?? .current

    /// Les coins à montrer : au plus 3, dans l'ordre de Core (déjà du plus proche au plus loin). Jamais complétés.
    func afficher(_ coins: [CoinProche]) -> [CoinAffiche] {
        coins.prefix(3).map(coin)
    }

    func coin(_ c: CoinProche) -> CoinAffiche {
        let titre = titreTexte(c)
        let distance = distanceTexte(metres: c.distanceM)
        let releve = releveTexte(n: c.nPeches, annee: c.annee)
        let (ouverture, ouvert) = ouvertureTexte(c.ouverture)
        let acces = accesTexte(c)
        let station = stationTexte(c)
        var voix = "\(titre), à \(distance). "
        if let acces { voix += "\(acces). " }
        voix += "Relevée à proximité : \(releve). \(station). \(ouverture)."
        return CoinAffiche(id: c.id, titre: titre, distance: distance, releve: releve, ouverture: ouverture, estOuvert: ouvert,
                           acces: acces, station: station, phraseVoixOff: voix)
    }

    func titreTexte(_ c: CoinProche) -> String {
        if let nom = c.nom { return nom }
        switch c.type {
        case .ponton: return "Ponton"
        case .acces: return "Accès à l'eau"
        case .peche: return "Coin de pêche"
        }
    }

    func accesTexte(_ c: CoinProche) -> String? {
        if c.payant { return "Accès payant" }
        switch c.acces {
        case .libre: return "Accès libre"
        case .permis: return "Sur permis"
        case nil: return nil
        }
    }

    func stationTexte(_ c: CoinProche) -> String {
        let eau = c.eauStation.map { ": \($0)" } ?? ""
        return "Station OFB à proximité\(eau), à \(distanceTexte(metres: c.distanceStationM))"
    }

    func releveTexte(n: Int, annee: Int) -> String {
        let pluriel = n > 1 ? "pêches" : "pêche"
        return "\(n) \(pluriel), dernier relevé \(annee)"
    }

    /// Distance arrondie (jamais de coordonnée) : « 450 m » sous 1 km, « 1,2 km » ensuite.
    func distanceTexte(metres: Double) -> String {
        if metres < 1000 {
            let arrondi = max(50, Int((metres / 50).rounded()) * 50)
            return "\(arrondi) m"
        }
        let km = (metres / 100).rounded() / 10
        let f = NumberFormatter()
        f.locale = locale
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return "\(f.string(from: NSNumber(value: km)) ?? "\(km)") km"
    }

    func ouvertureTexte(_ o: OuvertureDuJour) -> (String, Bool) {
        switch o {
        case .ouverte:
            return ("Ouverte aujourd'hui", true)
        case .fermee(let reouverture):
            guard let date = reouverture else { return ("Fermée", false) }
            let f = DateFormatter()
            f.locale = locale
            f.timeZone = fuseau
            f.setLocalizedDateFormatFromTemplate("d MMMM")
            return ("Fermée jusqu'au \(f.string(from: date))", false)
        }
    }
}

/// Une espèce de la grille d'images.
nonisolated struct EspeceChoix: Identifiable, Equatable {
    let id: String
    let espece: Espece
    let nom: String
    let image: String
    /// Relevée près d'ici (vient de `especesProches`).
    let pres: Bool
}

nonisolated enum EtatListe: Equatable {
    case choixEspece
    case resultats(espece: EspeceChoix, coins: [CoinAffiche])
    /// Aucun coin : « Aucun relevé OFB à proximité ».
    case aucunReleve(espece: EspeceChoix)
}

/// État de l'écran. La position (ou le centre du département choisi) lui est donnée : il ne la demande pas.
@MainActor
@Observable
final class OuChercherModele {
    private let especes: any ServiceEspeces & ServiceCoinsPublics
    private let position: Coordonnee
    private let compositeur: CompositeurCoins

    private(set) var grille: [EspeceChoix] = []
    private(set) var etat: EtatListe = .choixEspece

    init(especes: any ServiceEspeces & ServiceCoinsPublics, position: Coordonnee, compositeur: CompositeurCoins = CompositeurCoins()) {
        self.especes = especes
        self.position = position
        self.compositeur = compositeur
        self.grille = construireGrille()
    }

    /// Toutes les espèces pêchables en images ; celles relevées près d'ici d'abord, puis le reste dans l'ordre de Core.
    private func construireGrille() -> [EspeceChoix] {
        let proches = Set(especes.especesProches(position).map(\.espece))
        let toutes = especes.especesPechables().map {
            EspeceChoix(id: $0.espece.id, espece: $0.espece, nom: $0.nom, image: $0.image, pres: proches.contains($0.espece))
        }
        return toutes.filter(\.pres) + toutes.filter { !$0.pres }
    }

    func choisir(_ choix: EspeceChoix) {
        let coins = compositeur.afficher(especes.coinsProches(ou: choix.espece, pres: position))
        etat = coins.isEmpty ? .aucunReleve(espece: choix) : .resultats(espece: choix, coins: coins)
    }

    func changerEspece() {
        etat = .choixEspece
    }
}
