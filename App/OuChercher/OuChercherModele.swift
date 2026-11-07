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
    static func recherche(_ nom: String, locale: Locale = Locale(identifier: "fr_FR")) -> String { AnglaisE.f("Je cherche les coins pour %@…", locale, nom) }
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
        var voix = AnglaisE.f("%@, à %@. ", locale, titre, distance)
        if let acces { voix += "\(acces). " }
        voix += AnglaisE.f("Relevée à proximité : %@. %@. %@.", locale, releve, station, ouverture)
        return CoinAffiche(id: c.id, titre: titre, distance: distance, releve: releve, ouverture: ouverture, estOuvert: ouvert,
                           acces: acces, station: station, phraseVoixOff: voix)
    }

    func titreTexte(_ c: CoinProche) -> String {
        if let nom = c.nom { return nom }
        switch c.type {
        case .ponton: return AnglaisE.t("Ponton", locale)
        case .acces: return AnglaisE.t("Accès à l'eau", locale)
        case .peche: return AnglaisE.t("Coin de pêche", locale)
        }
    }

    func accesTexte(_ c: CoinProche) -> String? {
        if c.payant { return AnglaisE.t("Accès payant", locale) }
        switch c.acces {
        case .libre: return AnglaisE.t("Accès libre", locale)
        case .permis: return AnglaisE.t("Sur permis", locale)
        case nil: return nil
        }
    }

    func stationTexte(_ c: CoinProche) -> String {
        let distance = distanceTexte(metres: c.distanceStationM)
        if let eau = c.eauStation { return AnglaisE.f("Station OFB à proximité : %@, à %@", locale, eau, distance) }
        return AnglaisE.f("Station OFB à proximité, à %@", locale, distance)
    }

    func releveTexte(n: Int, annee: Int) -> String {
        if n > 1 { return AnglaisE.f("%lld pêches, dernier relevé %lld", locale, n, annee) }
        return AnglaisE.f("%lld pêche, dernier relevé %lld", locale, n, annee)
    }

    /// Distance arrondie (jamais de coordonnée) : « 450 m » sous 1 km, « 1,2 km » ensuite.
    func distanceTexte(metres: Double) -> String {
        if locale.language.languageCode?.identifier != "fr" {
            // États-Unis : pieds sous 1 000 ft, puis miles.
            if metres < 304.8 {
                return "\(max(50, Int((metres * 3.28084 / 50).rounded()) * 50)) ft"
            }
            let miles = (metres / 1609.344 * 10).rounded() / 10
            let g = NumberFormatter()
            g.locale = locale
            g.minimumFractionDigits = 0
            g.maximumFractionDigits = 1
            return "\(g.string(from: NSNumber(value: miles)) ?? "\(miles)") mi"
        }
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
            return (AnglaisE.t("Ouverte aujourd'hui", locale), true)
        case .fermee(let reouverture):
            guard let date = reouverture else { return (AnglaisE.t("Fermée", locale), false) }
            let f = DateFormatter()
            f.locale = locale
            f.timeZone = fuseau
            f.setLocalizedDateFormatFromTemplate("d MMMM")
            return (AnglaisE.f("Fermée jusqu'au %@", locale, f.string(from: date)), false)
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
    /// Les coins se cherchent hors de l'écran : la vue montre un indicateur d'attente.
    case chargement(espece: EspeceChoix)
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
    @ObservationIgnored private var recherche: Task<Void, Never>?

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

    /// La recherche (lecture des coins, liaison aux stations, règles) tourne hors du fil principal : l'écran passe à `.chargement`
    /// puis à `.resultats` ou `.aucunReleve`. Un nouveau choix, ou « Changer d'espèce », abandonne la recherche en cours.
    func choisir(_ choix: EspeceChoix, locale: Locale? = nil) {
        recherche?.cancel()
        etat = .chargement(espece: choix)
        var compositeur = compositeur
        if let locale { compositeur.locale = locale }
        let service = especes, point = position
        let composeur = compositeur
        recherche = Task { [weak self] in
            let coins = await Task.detached(priority: .userInitiated) {
                // L'écran n'en montre que 3 : Core ne calcule pas les 200 autres.
                composeur.afficher(service.coinsProches(ou: choix.espece, pres: point, limite: 3))
            }.value
            guard !Task.isCancelled, let self else { return }
            self.etat = coins.isEmpty ? .aucunReleve(espece: choix) : .resultats(espece: choix, coins: coins)
        }
    }

    /// Attend la fin de la recherche en cours (tests).
    func attendreRecherche() async {
        await recherche?.value
    }

    func changerEspece() {
        recherche?.cancel()
        recherche = nil
        etat = .choixEspece
    }
}
